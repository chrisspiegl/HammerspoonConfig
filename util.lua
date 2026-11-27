local systemElement = hs.axuielement.systemWideElement() -- Select System ELement

-- Fail fast when an app does not answer accessibility queries (applies to all AX queries).
systemElement:setTimeout(0.25)

local util = {}

-- Easier Debugging (know that it happened by showing an alert and priting it to the console)
function util.printAlert(text)
  print(text)
  hs.alert(text, {
    radius = 0,
    fadeInDuration = 0,
    fadeOutDuration = 0,
    strokeWidth = 0,
    textSize = 12,
    strokeColor =  { white = 1, alpha = 0 },
    textStyle = {
      paragraphStyle = {
        alignment = 'center',
        paragraphSpacing = 0,
        paragraphSpacingBefore = 0,
      }
    }
  })
end

-- State of the Premiere single key shortcuts (shown by the PR menubar item).
util.singleKeyShortcutsActive = true
function util.toggleSingleKeyShortcuts()
  util.singleKeyShortcutsActive = not util.singleKeyShortcutsActive
end

-- Sort Pairs by Key
-- Use in for loop:
-- ```for name, line in pairsByKeys(lines) do
--   print(name, line)
-- end```
function util.pairsSortedByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

-- True if bundleId begins with prefix (release + Beta builds; case-insensitive for the prefix match).
function util.bundleIdHasPrefix(bundleId, prefix)
  if type(bundleId) ~= 'string' or type(prefix) ~= 'string' then return false end
  local prefixLower = prefix:lower()
  return bundleId:lower():sub(1, #prefixLower) == prefixLower
end

-- Check if the Frontmost Application has a certain `bundleID`
-- Returns the `frontmostApplication` or `false`
function util.frontAppStartsWithBundleId(bundleID)
  local bundleID = bundleID or "XXXXXXXXXXX"
  local frontMostApp = hs.application.frontmostApplication()
  if not frontMostApp then return false end
  local frontAppBundleID = frontMostApp:bundleID()
  if util.bundleIdHasPrefix(frontAppBundleID, bundleID) then
    return frontMostApp
  end
  return false
end

-- Get current UI Focused Element
function util.currentElement()
  return systemElement:attributeValue("AXFocusedUIElement") -- Select Focused Element
end

-- True when focus is in a text/search field (typing). Many apps (e.g. Premiere Beta) still report a
-- non-nil AXFocusedUIElement for the timeline or panels, so "nil == currentElement()" is too strict.
function util.focusedElementIsTextField()
  local el = util.currentElement()
  if not el then return false end
  local role = el:attributeValue("AXRole")
  return role == "AXTextField" or role == "AXTextArea" or role == "AXSearchField"
end

-- Select focused window and check if it's standard or fullscreen
function util.getGoodFocusedWindow(noFullScreen, allowNonStandard)
   local win = hs.window.focusedWindow()
   if not win or (not win:isStandard() and not allowNonStandard) then return end
   if noFullScreen and win:isFullScreen() then return end
   return win
end

-- Flash screen for actions that are not possible
function util.flashScreen(message, screen)
  if (not screen) then screen = hs.screen.mainScreen() end
  local flash = hs.canvas.new(screen:fullFrame()):appendElements({
    action = "fill",
    fillColor = { alpha = 0.25, red=1 },
    type = "rectangle"
  })
  if (message) then util.printAlert(message)
  else util.printAlert('Impossible Action')
  end
  flash:show()
  hs.timer.doAfter(.15, function() flash:delete() end)
end

return util
