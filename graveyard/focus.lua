-- focus.lua
-- Caret / Text-Input Focus Diagnostic & Monitor for Hammerspoon
-- Built specifically to handle apps (like Adobe Premiere Pro / Premiere Pro Beta)
-- where the standard Accessibility (AX) API is unreliable.
--
-- This version is a DIAGNOSTIC TOOL FIRST: it collects multiple independent
-- signals about "is the user currently typing into something" and lets you
-- correlate them against ground truth (you manually marking "yes I'm typing"
-- / "no I'm not") so you can see which signal(s) actually work in Premiere,
-- panel by panel.
--
-- Default hotkeys (see CONFIG below to change):
--   Cmd+Alt+Ctrl+Y  -> Mark ground truth: CARET ACTIVE   (logs a labeled row)
--   Cmd+Alt+Ctrl+N  -> Mark ground truth: CARET INACTIVE (logs a labeled row)
--   Cmd+Alt+Ctrl+I  -> Instant inspect: dump all current signals to an alert
--                      + Hammerspoon console (no label attached)
--
-- A CSV log is written to ~/.hammerspoon/caret_log.csv so you can pull it
-- into a spreadsheet / pandas and see which columns actually predict your
-- ground-truth label inside Premiere.
--
-- WORKFLOW TO LEARN PREMIERE'S BEHAVIOR:
--   1. Open Premiere / Premiere Beta.
--   2. Click into a timecode field, type something. Press Cmd+Alt+Ctrl+Y.
--   3. Click outside, away from any field. Press Cmd+Alt+Ctrl+N.
--   4. Repeat for: clip rename in Project panel, clip rename in timeline,
--      search boxes, Effect Controls numeric fields, Essential Graphics
--      text fields, Lumetri panel fields, etc.
--   5. Open the menubar dropdown (or the CSV) and look at which of
--      undoState / sysFocus / appFocus / clickInfo actually flips
--      correctly and consistently for each panel.
--   6. Once you know which signal(s) work for which panel, simplify
--      CaretMonitor.collectSignals()'s "guess" formula (or write a
--      per-bundle-ID / per-panel override) and drop the rest.

local ax = require("hs.axuielement")

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------

local CONFIG = {
    checkInterval        = 2,        -- seconds between background menubar refresh
    logPath              = os.getenv("HOME") .. "/.hammerspoon/caret_log.csv",
    menubarIconActive    = "📝",
    menubarIconInactive  = "▪️",
    menubarIconUnknown   = "❔",

    hotkeyMods           = {"cmd", "alt", "ctrl"},
    hotkeyMarkActive     = "y",
    hotkeyMarkInactive   = "n",
    hotkeyInspect        = "i",

    -- Bundle IDs this tool pays special attention to. Not required for the
    -- diagnostics to work (they work in any app), just used to decide when
    -- to apply the AXManualAccessibility nudge. Verify the Beta bundle ID
    -- on your machine with:
    --   osascript -e 'id of app "Adobe Premiere Pro Beta"'
    targetBundleIDs = {
        -- ["com.adobe.PremierePro"] = true,
        ["com.adobe.PremiereProBeta.26"] = true,
    },
}

----------------------------------------------------------------------
-- SAFE LOGGING (kept from original, slightly extended)
----------------------------------------------------------------------

local function safeLoggerW(message)
    if hs and hs.logger and type(hs.logger.w) == "function" then
        hs.logger.w(message)
    else
        print("WARN: " .. tostring(message))
    end
end

local function safeLoggerE(message)
    if hs and hs.logger and type(hs.logger.e) == "function" then
        hs.logger.e(message)
    else
        print("ERROR: " .. tostring(message))
    end
end

local function safeInspect(value)
    if hs and hs.inspect and type(hs.inspect) == "function" then
        return hs.inspect(value)
    end
    local valueType = type(value)
    if valueType == "table" or valueType == "userdata" then
        return valueType .. " (hs.inspect unavailable)"
    end
    return tostring(value)
end

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local CaretMonitor = {}
CaretMonitor._menubar = nil
CaretMonitor._timer = nil
CaretMonitor._clickWatcher = nil
CaretMonitor._lastClickElement = nil   -- raw axuielement at last mouse click
CaretMonitor._lastClickInfo = nil      -- summarized info table
CaretMonitor._lastSignals = nil
CaretMonitor._nudgedBundleIDs = {}     -- bundles we've already sent AXManualAccessibility to

----------------------------------------------------------------------
-- SIGNAL 1: "Undo" menu item enabled state
-- (Original technique from focus.lua - kept, cleaned up)
----------------------------------------------------------------------

local function getUndoState(app)
    if not app then return false, "no app" end

    local editMenuElement = app:findMenuItem({"Edit"})
    if not editMenuElement then return false, "no Edit menu" end

    if type(editMenuElement) ~= "userdata" or type(editMenuElement.children) ~= "function" then
        return false, "Edit menu element has no :children()"
    end

    local childrenElements = editMenuElement:children()
    if type(childrenElements) ~= "table" then
        return false, "children() did not return a table"
    end

    for _, childElement in ipairs(childrenElements) do
        if type(childElement) == "userdata"
            and type(childElement.title) == "function"
            and type(childElement.isEnabled) == "function" then
            local title = childElement:title()
            if title and type(title) == "string" and string.match(title, "^Undo") then
                return childElement:isEnabled(), "ok"
            end
        end
    end
    return false, "no Undo item found"
end

----------------------------------------------------------------------
-- SIGNAL 2: AX focused element (system-wide AND app-level)
----------------------------------------------------------------------

local TEXT_ROLES = {
    AXTextField = true,
    AXTextArea  = true,
    AXComboBox  = true,
}

-- Summarize an axuielement into a small plain table (safe to print/log).
-- Every attribute read is pcall-wrapped because Premiere's custom widgets
-- can throw/return nil unpredictably for attributes that "should" exist.
local function summarizeElement(el)
    if not el then
        return { present = false }
    end

    local ok,  role      = pcall(function() return el:attributeValue("AXRole") end)
    local ok2, subrole   = pcall(function() return el:attributeValue("AXSubrole") end)
    local ok3, editable  = pcall(function() return el:attributeValue("AXEditable") end)
    local ok4, selRange  = pcall(function() return el:attributeValue("AXSelectedTextRange") end)
    local ok5, numChars  = pcall(function() return el:attributeValue("AXNumberOfCharacters") end)
    local ok6, focused   = pcall(function() return el:attributeValue("AXFocused") end)
    local ok7, valueAttr = pcall(function() return el:attributeValue("AXValue") end)

    role     = ok  and role  or nil
    subrole  = ok2 and subrole or nil
    editable = ok3 and editable or nil
    selRange = ok4 and selRange or nil
    numChars = ok5 and numChars or nil
    focused  = ok6 and focused or nil

    local valueType = ok7 and type(valueAttr) or "n/a"
    local valuePreview = nil
    if ok7 and type(valueAttr) == "string" then
        valuePreview = valueAttr:sub(1, 24)
    end

    local looksLikeTextRole = (role ~= nil and TEXT_ROLES[role]) or subrole == "AXSearchField"

    local heuristicEditable =
        looksLikeTextRole == true
        or editable == true
        or selRange ~= nil
        or numChars ~= nil
        or (valueType == "string" and focused == true)

    return {
        present           = true,
        role              = role,
        subrole           = subrole,
        editable          = editable,
        hasSelectedRange  = selRange ~= nil,
        numChars          = numChars,
        focused           = focused,
        valueType         = valueType,
        valuePreview      = valuePreview,
        heuristicEditable = heuristicEditable and true or false,
    }
end

local function getSystemWideFocusInfo()
    local ok, sys = pcall(ax.systemWideElement)
    if not ok or not sys then return { present = false, error = "no systemWideElement" } end
    local ok2, focused = pcall(function() return sys:attributeValue("AXFocusedUIElement") end)
    if not ok2 or not focused then return { present = false, error = "no AXFocusedUIElement" } end
    return summarizeElement(focused)
end

local function getAppFocusInfo(app)
    if not app then return { present = false, error = "no app" } end
    local ok, axApp = pcall(ax.applicationElement, app)
    if not ok or not axApp then return { present = false, error = "no applicationElement" } end
    local ok2, focused = pcall(function() return axApp:attributeValue("AXFocusedUIElement") end)
    if not ok2 or not focused then return { present = false, error = "no app AXFocusedUIElement" } end
    return summarizeElement(focused)
end

-- Some apps (Premiere's CEP/CEF-based panels especially) only expose a
-- real AX tree once AXManualAccessibility / AXEnhancedUserInterface are
-- toggled on. Do this once per app per session, harmlessly. It will not
-- do anything for the natively-drawn (non-CEF) parts of Premiere, e.g.
-- the timeline itself.
local function nudgeAccessibilityIfNeeded(app)
    if not app then return end
    local bundleID = app:bundleID()
    if not bundleID or not CONFIG.targetBundleIDs[bundleID] then return end
    if CaretMonitor._nudgedBundleIDs[bundleID] then return end

    local ok, axApp = pcall(ax.applicationElement, app)
    if ok and axApp then
        pcall(function() axApp:setAttributeValue("AXManualAccessibility", true) end)
        pcall(function() axApp:setAttributeValue("AXEnhancedUserInterface", true) end)
        safeLoggerW("CaretCheck: sent AXManualAccessibility nudge to " .. bundleID)
    end
    CaretMonitor._nudgedBundleIDs[bundleID] = true
end

----------------------------------------------------------------------
-- SIGNAL 3: AX element under the mouse at the moment of last click.
-- This is the fallback for apps whose AX tree doesn't update
-- AXFocusedUIElement correctly (common in custom-drawn UIs like
-- Premiere's timeline / Effect Controls / timecode fields). In practice
-- this tends to be the MOST reliable signal in Premiere's native panels.
----------------------------------------------------------------------

local function startClickWatcher()
    if CaretMonitor._clickWatcher then return end

    CaretMonitor._clickWatcher = hs.eventtap.new(
        { hs.eventtap.event.types.leftMouseDown },
        function(e)
            local pos = hs.mouse.absolutePosition()
            local ok, el = pcall(ax.systemElementAtPosition, pos.x, pos.y)
            if ok and el then
                CaretMonitor._lastClickElement = el
                CaretMonitor._lastClickInfo = summarizeElement(el)
                CaretMonitor._lastClickInfo.clickedAt = os.time()
                CaretMonitor._lastClickInfo.clickPos = { x = pos.x, y = pos.y }
            else
                CaretMonitor._lastClickElement = nil
                CaretMonitor._lastClickInfo = { present = false, error = "systemElementAtPosition failed" }
            end
            return false -- never swallow the click
        end
    )
    CaretMonitor._clickWatcher:start()
end

----------------------------------------------------------------------
-- COMBINE ALL SIGNALS
----------------------------------------------------------------------

function CaretMonitor.collectSignals()
    local frontApp = hs.application.frontmostApplication()
    local appName = frontApp and frontApp:title() or "[none]"
    local bundleID = frontApp and frontApp:bundleID() or "[none]"

    nudgeAccessibilityIfNeeded(frontApp)

    local undoState, undoErr = getUndoState(frontApp)
    local sysFocus = getSystemWideFocusInfo()
    local appFocus = getAppFocusInfo(frontApp)
    local clickInfo = CaretMonitor._lastClickInfo or { present = false }

    -- Naive combined guess: true if ANY signal thinks we're in text input.
    -- This is intentionally loose for the diagnostic phase. Once you know
    -- which signal(s) are trustworthy for which Premiere panel, replace
    -- this with a tighter, panel-aware rule.
    local guess = undoState
        or (sysFocus.present and sysFocus.heuristicEditable)
        or (appFocus.present and appFocus.heuristicEditable)
        or (clickInfo.present and clickInfo.heuristicEditable)

    return {
        timestamp  = os.date("%Y-%m-%d %H:%M:%S"),
        appName    = appName,
        bundleID   = bundleID,
        undoState  = undoState,
        undoErr    = undoErr,
        sysFocus   = sysFocus,
        appFocus   = appFocus,
        clickInfo  = clickInfo,
        guess      = guess and true or false,
    }
end

----------------------------------------------------------------------
-- LOGGING (CSV for later analysis / correlation with ground truth)
----------------------------------------------------------------------

local CSV_HEADER = "timestamp,label,app,bundleID,undoState,sysFocusPresent,sysFocusRole,sysFocusSubrole,sysFocusHeuristic,appFocusPresent,appFocusRole,appFocusSubrole,appFocusHeuristic,clickPresent,clickRole,clickSubrole,clickHeuristic,combinedGuess\n"

local function ensureLogFile()
    local f = io.open(CONFIG.logPath, "r")
    if f then f:close(); return end
    local fw = io.open(CONFIG.logPath, "w")
    if fw then
        fw:write(CSV_HEADER)
        fw:close()
    else
        safeLoggerE("CaretCheck: could not create log file at " .. CONFIG.logPath)
    end
end

local function csvField(v)
    if v == nil then return "" end
    if type(v) == "boolean" then return v and "1" or "0" end
    return tostring(v):gsub(",", ";")
end

local function logSignals(signals, label)
    ensureLogFile()
    local f = io.open(CONFIG.logPath, "a")
    if not f then
        safeLoggerE("CaretCheck: could not open log file for append")
        return
    end

    local row = table.concat({
        csvField(signals.timestamp),
        csvField(label),
        csvField(signals.appName),
        csvField(signals.bundleID),
        csvField(signals.undoState),
        csvField(signals.sysFocus.present),
        csvField(signals.sysFocus.role),
        csvField(signals.sysFocus.subrole),
        csvField(signals.sysFocus.heuristicEditable),
        csvField(signals.appFocus.present),
        csvField(signals.appFocus.role),
        csvField(signals.appFocus.subrole),
        csvField(signals.appFocus.heuristicEditable),
        csvField(signals.clickInfo.present),
        csvField(signals.clickInfo.role),
        csvField(signals.clickInfo.subrole),
        csvField(signals.clickInfo.heuristicEditable),
        csvField(signals.guess),
    }, ",")

    f:write(row .. "\n")
    f:close()
end

----------------------------------------------------------------------
-- MENUBAR (live status + dropdown with raw signal values)
----------------------------------------------------------------------

local function buildMenuTable(signals)
    local function line(text) return { title = text, disabled = true } end

    return {
        line("App: " .. signals.appName),
        line("Bundle: " .. signals.bundleID),
        { title = "-" },
        line("Undo enabled: " .. tostring(signals.undoState) .. "  (" .. tostring(signals.undoErr) .. ")"),
        { title = "-" },
        line("SysFocus: " .. (signals.sysFocus.present
            and (tostring(signals.sysFocus.role) .. " / " .. tostring(signals.sysFocus.subrole)
                .. "  -> editable=" .. tostring(signals.sysFocus.heuristicEditable))
            or "n/a (" .. tostring(signals.sysFocus.error) .. ")")),
        line("AppFocus: " .. (signals.appFocus.present
            and (tostring(signals.appFocus.role) .. " / " .. tostring(signals.appFocus.subrole)
                .. "  -> editable=" .. tostring(signals.appFocus.heuristicEditable))
            or "n/a (" .. tostring(signals.appFocus.error) .. ")")),
        line("LastClick: " .. (signals.clickInfo.present
            and (tostring(signals.clickInfo.role) .. " / " .. tostring(signals.clickInfo.subrole)
                .. "  -> editable=" .. tostring(signals.clickInfo.heuristicEditable))
            or "n/a")),
        { title = "-" },
        line("Combined guess: " .. tostring(signals.guess)),
        { title = "-" },
        { title = "Mark ACTIVE now    (⌘⌥⌃Y)", fn = function() CaretMonitor.markGroundTruth(true) end },
        { title = "Mark INACTIVE now  (⌘⌥⌃N)", fn = function() CaretMonitor.markGroundTruth(false) end },
        { title = "Inspect now        (⌘⌥⌃I)", fn = function() CaretMonitor.inspect() end },
        { title = "-" },
        { title = "Open log file", fn = function() hs.execute('open "' .. CONFIG.logPath .. '"') end },
    }
end

local function updateMenubar()
    local signals = CaretMonitor.collectSignals()
    CaretMonitor._lastSignals = signals

    if CaretMonitor._menubar then
        local icon = CONFIG.menubarIconUnknown
        if signals.guess then
            icon = CONFIG.menubarIconActive
        else
            icon = CONFIG.menubarIconInactive
        end
        CaretMonitor._menubar:setTitle(icon)
        CaretMonitor._menubar:setMenu(function() return buildMenuTable(signals) end)
    end
end

----------------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------------

-- Mark ground truth and log a labeled row. Call this (via hotkey, the
-- menubar dropdown, or the console) at the exact moment you know whether
-- the caret is/isn't active in Premiere, so you build a labeled dataset.
function CaretMonitor.markGroundTruth(isActive)
    local signals = CaretMonitor.collectSignals()
    logSignals(signals, isActive and "ACTIVE" or "INACTIVE")
    if hs.alert and hs.alert.show then
        hs.alert.show("Caret logged as " .. (isActive and "ACTIVE" or "INACTIVE")
            .. "\nguess=" .. tostring(signals.guess), 1.2)
    end
end

-- Dump full current signal state to console + alert, no label attached.
-- Use this while hovering/clicked in different Premiere fields to see
-- raw role/subrole values and build better per-panel heuristics.
function CaretMonitor.inspect()
    local signals = CaretMonitor.collectSignals()
    print("==== CaretCheck inspect @ " .. signals.timestamp .. " ====")
    print(safeInspect(signals))
    if hs.alert and hs.alert.show then
        local summary = string.format(
            "%s\nundo=%s  sys=%s/%s  app=%s/%s  click=%s/%s\nguess=%s",
            signals.appName,
            tostring(signals.undoState),
            tostring(signals.sysFocus.role), tostring(signals.sysFocus.heuristicEditable),
            tostring(signals.appFocus.role), tostring(signals.appFocus.heuristicEditable),
            tostring(signals.clickInfo.role), tostring(signals.clickInfo.heuristicEditable),
            tostring(signals.guess)
        )
        hs.alert.show(summary, 2.5)
    end
    return signals
end

-- Programmatic check for use elsewhere in your config, e.g.:
--   if not CaretMonitor.isLikelyTextInput() then myHotkey:enable() end
-- Uses the last cached signal read (refreshed every CONFIG.checkInterval
-- seconds, or instantly via .collectSignals() if you need a live read).
function CaretMonitor.isLikelyTextInput()
    local signals = CaretMonitor._lastSignals or CaretMonitor.collectSignals()
    return signals.guess
end

----------------------------------------------------------------------
-- STARTUP
----------------------------------------------------------------------

local function startMonitor()
    if CaretMonitor._menubar then return end -- already started

    CaretMonitor._menubar = hs.menubar.new()
    if not CaretMonitor._menubar then
        safeLoggerE("CaretCheck: Failed to create menubar item.")
        return
    end
    CaretMonitor._menubar:setTitle(CONFIG.menubarIconInactive)
    CaretMonitor._menubar:setTooltip("Caret / Text-Input Focus Diagnostic")

    startClickWatcher()
    ensureLogFile()

    updateMenubar()
    CaretMonitor._timer = hs.timer.doEvery(CONFIG.checkInterval, updateMenubar)

    hs.hotkey.bind(CONFIG.hotkeyMods, CONFIG.hotkeyMarkActive,   function() CaretMonitor.markGroundTruth(true) end)
    hs.hotkey.bind(CONFIG.hotkeyMods, CONFIG.hotkeyMarkInactive, function() CaretMonitor.markGroundTruth(false) end)
    hs.hotkey.bind(CONFIG.hotkeyMods, CONFIG.hotkeyInspect,      function() CaretMonitor.inspect() end)

    if hs.alert and hs.alert.show then
        hs.alert.show("Caret Monitor (diagnostic) started")
    else
        print("INFO: Caret Monitor (diagnostic) started\n")
    end
end

startMonitor()

-- Expose globally so you can call it from the Hammerspoon Console, e.g.:
--   CaretMonitor.inspect()
--   CaretMonitor.markGroundTruth(true)
_G.CaretMonitor = CaretMonitor

return CaretMonitor