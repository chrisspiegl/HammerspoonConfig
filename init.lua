-- Got first config from: https://github.com/skrypka/hammerspoon_config/blob/master/init.lua
-- Hammerspoon Configuration and Precheck

hs.logger.defaultLogLevel="info"
print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
print("Is Hammerspoon in the Accessibility Privacy settings activated?")
print(hs.accessibilityState() and "\tYes, all good." or "\tNo, you have to add Hammerspoon there!")
local reload_watcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

if hs.keycodes.setLayout('U.S.') then
  print("Successfully set Layout to U.S.")
else
  print("You have to set the layout to U.S. yourself!")
end
if hs.keycodes.currentLayout() == 'U.S.' then
  hs.alert('U.S. Keyboard Layout Selected')
else
  hs.alert('ACTIVATE U.S. KEYBOARD LAYOUT AND RESTART HAMMERSPOON', 10)
end

-- Load and Install Helper Spoon
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.repos.skrypka = {
  url = "https://github.com/skrypka/Spoons",
  desc = "Skrypka's spoon repository",
}
spoon.SpoonInstall.use_syncinstall = true

-- Custom Configuration from here down…

local util = require("./util")
local HyperController = require("./HyperController"):new()

-- Preset Keyboard Combinations
hyper = HyperController.hyperCombo
shift_hyper = {"cmd", "option", "control", "shift"}
shift_hyp = {"control", "option", "shift"}
control_cmd = {"cmd", "control"}
option_cmd = {"cmd", "option"}
shift_cmd = {"cmd", "shift"}
control_option = {"control", "option"}
cmd = {"cmd"}
comand = {"cmd"}
shift = {"shift"}
option = {"option"}
control = {"control"}

local applicationHotkeys = {
  -- a = 'Audition',
  -- b = 'Brave',
  -- d = 'Dynalist',
  -- e = 'Sublime Text',
  -- n = 'Notion',
  -- s = 'Telegram',
  -- t = 'iTerm',
  -- f = 'Clockify',
  -- q = 'Premiere',
  -- w = 'iA Writer',
}

-- local KeyboardAsMidi = require("./KeyboardAsMidi"):new()

local AppWatcher = require('./AppWatcher'):new()
AppWatcher:enable()

local premiere = require('./AdobePremierePro'):new()
premiere:start(AppWatcher)

local audition = require('./AdobeAudition'):new()
audition:start(AppWatcher)

local lightroom = require('./AdobeLightroomClassic'):new()
lightroom:start(AppWatcher)

-- local davinciresolve = require('./DaVinciResolve'):new()
-- davinciresolve:start(AppWatcher)

local iawriter = require('./IaWriter'):new()
iawriter:start(AppWatcher)

local dynalist = require('./Dynalist'):new()
dynalist:start(AppWatcher)

-- Moving Windows Around on Screen, onto other Screens, and to Spaces (left/right)
local moveWindow = require("./moveWindow")

hs.hotkey.bind({ 'control', 'option' }, "up", function() moveWindow.maximize() end) -- Maximise to full screen
-- hs.hotkey.bind({ 'control', 'option' }, "down", function() hs.window.frontmostWindow():minimize() end)
hs.hotkey.bind({ 'control', 'option' }, "down", function() moveWindow.toNextScreen() end) -- Move to Next Screen
hs.hotkey.bind({ 'control', 'option' }, "left", function() moveWindow.move(0, 0, '50%', '100%') end) -- Left Half
hs.hotkey.bind({ 'control', 'option' }, "right", function() moveWindow.move('50%', 0, '50%', '100%') end) -- Right Half

hs.hotkey.bind({ 'control', 'option' }, "1", function() moveWindow.move(0, 0, 960, '100%') end) -- Ultrawide - Left
hs.hotkey.bind({ 'control', 'option' }, "2", function() moveWindow.move(960, 0, 1920, '100%') end) -- Ultrawide - Center
hs.hotkey.bind({ 'control', 'option' }, "3", function() moveWindow.move(2880, 0, 960, '100%') end) -- Ultrawide - Right

hs.hotkey.bind({ 'control', 'option', 'command' }, "up", function() moveWindow.center('90%', '90%') end) -- Center 90%
hs.hotkey.bind({ 'control', 'option', 'command' }, "down", function() moveWindow.center(1920, 1080) end) -- Center Full-HD
hs.hotkey.bind({ 'control', 'option', 'command' }, "left", function() moveWindow.move(0, '50%', '50%', '50%') end) -- Bottom Left Quarter
hs.hotkey.bind({ 'control', 'option', 'command' }, "right", function() moveWindow.move('50%', '50%', '50%', '50%') end) -- Bottom Right Quarter

hs.hotkey.bind({ 'control', 'option', 'command' }, "1", function() moveWindow.move(0, '50%', 960, '50%') end) -- Ultrawide - Top Left 50%
hs.hotkey.bind({ 'control', 'option', 'command' }, "2", function() moveWindow.move(960, '50%', 1920, '50%') end) -- Ultrawide - Top Center 50%
hs.hotkey.bind({ 'control', 'option', 'command' }, "3", function() moveWindow.move(2880, '50%', 960, '50%') end) -- Ultrawide - Top Right 50%

hs.hotkey.bind({ 'control', 'option', 'shift' }, "1", function() moveWindow.move(0, 0, 960, '50%') end) -- Ultrawide - Bottom Left 50%
hs.hotkey.bind({ 'control', 'option', 'shift' }, "2", function() moveWindow.move(960, 0, 1920, '50%') end) -- Ultrawide - Bottom Center 50%
hs.hotkey.bind({ 'control', 'option', 'shift' }, "3", function() moveWindow.move(2880, 0, 960, '50%') end) -- Ultrawide - Bottom Right 50%
-- hs.hotkey.bind({ 'control', 'option', 'shift' }, "up", function() moveWindow.move(0, 0, '100%', '50%') end) -- Top Half
-- hs.hotkey.bind({ 'control', 'option', 'shift' }, "down", function() moveWindow.move(0, '50%', '100%', '50%') end) -- Bottom Half
hs.hotkey.bind({ 'control', 'option', 'shift' }, "left", function() moveWindow.move(0, 0, '50%', '50%') end) -- Top Left Quarter
hs.hotkey.bind({ 'control', 'option', 'shift' }, "right", function() moveWindow.move('50%', 0, '50%', '50%') end) -- Top Right Quarter

-- hs.hotkey.bind({ 'option', 'command' }, "up", function() moveWindow.maximize() end) -- Maximise to full screen
hs.hotkey.bind({ 'option', 'command' }, "up", function() moveWindow.move(0, 0, '100%', '50%') end) -- Top Half
-- hs.hotkey.bind({ 'option', 'command' }, "down", function() moveWindow.toNextScreen() end) -- Move to Next Screen
hs.hotkey.bind({ 'option', 'command' }, "down", function() moveWindow.move(0, '50%', '100%', '50%') end) -- Bottom Half
hs.hotkey.bind({ 'option', 'command' }, "left", function() moveWindow.move(0, 0, '30%', '100%') end) -- Left 1/3
hs.hotkey.bind({ 'option', 'command' }, "right", function() moveWindow.move('30%', 0, '70%', '100%') end) -- Right 2/3

-- hs.hotkey.bind({ 'control', 'option', 'command', 'shift' }, "Up", function() moveWindow.maximize() end)
-- hs.hotkey.bind({ 'control', 'option', 'command', 'shift' }, "Down", function() moveWindow.toNextScreen() end)
-- hs.hotkey.bind({ 'control', 'option', 'command', 'shift' }, "Left", function() moveWindow.move(0, 0, '50%', '50%') end)
-- hs.hotkey.bind({ 'control', 'option', 'command', 'shift' }, "Right", function() moveWindow.move('50%', 0, '50%', '50%') end)

-- hs.hotkey.bind({ 'control', 'command' }, "up", function() moveWindow.maximize() end)
-- hs.hotkey.bind({ 'control', 'command' }, "down", function() moveWindow.toNextScreen() end)
hs.hotkey.bind({ 'control', 'command' }, "left", function() moveWindow.oneSpace("left", true) end)
hs.hotkey.bind({ 'control', 'command' }, "right", function() moveWindow.oneSpace("right", true) end)


-- Color Presets
col = hs.drawing.color.x11
-- util.printAlert(hs.inspect(col))

-- defeat paste blocking (by typing the password, but then keyloggers can get that stuff)
-- hs.hotkey.bind({"option", "cmd"}, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- push-to-talk in Skype and Zoom
-- Hold `fn` key to switch mute/talk
-- spoon.SpoonInstall:andUse("PushToTalk", {
--   start = true,
--   config = {
--     detect_on_start = true,
--     app_switcher = {
--       ['zoom.us'] = 'push-to-talk',
--       ['Skype'] = 'push-to-talk'
--     }
--   }
-- })

-- Redirect URLS to different Browseres
chromeBrowserApp = "com.google.Chrome"
edgeBrowserApp = "com.microsoft.edgemac"
braveBrowserApp = "com.brave.Browser"
safariBrowserApp = "com.apple.safari"
DefaultBrowser = safariBrowserApp
WorkBrowser = braveBrowserApp
-- spoon.SpoonInstall:andUse("URLDispatcher", {
--   config = {
--     url_patterns = {
--       { "https?://(.*).accounts.google.com", braveBrowserApp },
--       { "https?://(.*).dropbox.com",  braveBrowserApp },
--       { "https?://(.*).zoom.us", braveBrowserApp },
--       { "https?://(.*).youtube.com", braveBrowserApp },
--       { "https?://(.*).youtube.de", braveBrowserApp },
--       { "https?://(.*).drive.google.com", braveBrowserApp },
--       { "https?://(.*).docs.google.com", braveBrowserApp },
--       { "https?://(.*)chaptered.app", braveBrowserApp },
--       { "https?://(.*).google.com", braveBrowserApp },
--       { "https?://(.*).gmail.com", braveBrowserApp },
--     },
--     default_handler = safariBrowserApp
--   },
--   start = true,
--   -- Enable debug logging if you get unexpected behavior
--   -- loglevel = 'debug'
-- })

-- Translate Selected Directly
-- local wm = hs.webview.windowMasks
-- spoon.SpoonInstall:andUse("DeepLTranslate", {
--   disable = false,
--   config = {
--     popup_style = wm.utility|wm.HUD|wm.titled|wm.closable|wm.resizable,
--   },
--   hotkeys = {
--     translate = { hyper, "z" },
--   }
-- })

-- Show shorcut cheat sheet
spoon.SpoonInstall:andUse("KSheet", {})

-- Circle Around Mouse for Demo Purpose
spoon.SpoonInstall:andUse("MouseCircle", {
  repo = 'skrypka',
  svn = true,
  config = {
    circleRadius = 100
  }
})

-- Menu Bar Flags
-- spoon.SpoonInstall:andUse("MenubarFlag", {
--   config = {
--     colors = {
--       ["U.S."] = { },
--       German = { col.black, col.red, col.yellow },
--     }
--   },
--   start = true
-- })

-- Show element browser to get to know stuff about it…
-- local axbrowse = require("axbrowse")
-- local lastApp
-- hs.hotkey.bind({"cmd", "option", "control"}, "b", function()
--    local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
--    if currentApp == lastApp then
--        axbrowse.browse() -- try to continue from where we left off
--    else
--        lastApp = currentApp
--        axbrowse.browse(currentApp) -- new app, so start over
--    end
-- end)

-- Toggle Capslock on and off.
function toggleCaps()
  if hs.hid.capslock.get() then
    hs.hid.capslock.set(false)
    hs.alert.closeAll(0)
    hs.alert.show('↓ caps off',1)
  else
    hs.hid.capslock.set(true)
    hs.alert.closeAll(0)
    hs.alert.show('↑ CAPS ON',1)
  end
  return
end

-- Toggle Full Screen Menu Bar on and off.
function toggleFullScreenMenuBar()
  hs.osascript.applescriptFromFile('./AppleScriptToggleFullScreenMenuBar.applescript')
end

-- Prevent Strange Space (` `) to be entered after using a `<alt>+…` shortcut.
hs.hotkey.bind({'alt'}, 'space', function() hs.eventtap.keyStrokes(' ') end) -- an empty space is more reliably typed via keys since it is text we want to enter.
hs.hotkey.bind({'alt', 'shift'}, 'space', function() hs.eventtap.keyStrokes(' ') end) -- an empty space is more reliably typed via keys since it is text we want to enter.

-- Recursive Bindings for the purpose of having key combos types one after the other
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey
function buildModalAppHotkeys(keys)
  local bindings = {}
  for key, app in pairs(keys) do
    bindings[singleKey(key, app)] = function() util.openOrFocusLastWindow(app) end
  end
  return bindings
end
modalAppsHotkeys = buildModalAppHotkeys(applicationHotkeys)
globalModal = spoon.RecursiveBinderModified.recursiveBind({
  -- [singleKey('x', 'Application')] = function() getColorAtMousPointer() end,
  [singleKey('w', 'Application Details')] = function()
    local frontMostApp = hs.application.frontmostApplication()
    local frontAppBundleID = frontMostApp:bundleID()
    util.printAlert(frontAppBundleID)
    local currentElement = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement") -- Select Focused Element
    if currentElement then
      print(hs.inspect(currentElement:allAttributeValues()))
    end
  end,
  -- [singleKey('space', 'Hints')] = hs.hints.windowHints,
  -- [singleKey('.', 'Mic Toggle')] = function() spoon.PushToTalk:toggleStates({'push-to-talk', 'release-to-talk'}) end,
  [singleKey('/', 'CheatSheet')] = function() spoon.KSheet:toggle() end,
  [singleKey('f', 'file+')] = {
     [singleKey('d', 'Downloads')] = function() util.openWithFinder('~/Downloads') end,
     [singleKey('s', 'Sites')] = function() util.openWithFinder('~/Sites') end,
     [singleKey('h', 'Home')] = function() util.openWithFinder('~/') end,
     [singleKey('y', 'YouTube')] = function() util.openWithFinder("~/ContentProduction/YouTube/") end,
     [singleKey('c', 'MacherCafe')] = function() util.openWithFinder("~/ContentProduction/Macher.Cafe/") end,
     [singleKey('t', 'ThatMakerLife')] = function() util.openWithFinder("~/ContentProduction/ThatMaker.Life/") end,
     [singleKey('m', 'Machmermal')] = function() util.openWithFinder("~/ContentProduction/Machmermal/") end,
  },
  [singleKey('p', 'project+')] = {
    [singleKey('f', 'foxi.link')] = function() hs.execute("subl '~/Sites/fl-foxi.link/foxi.link.sublime-project'", true) end,
    [singleKey('w', 'ChrisSpiegl.com')] = function() hs.execute("subl '~/Sites/chrisspiegl.com - 11ty/cs-11ty-chrisspiegl.com.sublime-project'", true) end,
    [singleKey('a', 'Chaptered.app')] = function() hs.execute("subl '~/Sites/chaptered-server'", true) end,
    [singleKey('p', 'PushNotice.chat')] = function() hs.execute("subl '~/Sites/pn-pushnotice.chat'", true) end,
    [singleKey('n', 'Foxi.Network')] = function() hs.execute("subl '~/Sites/fn-foxi.network'", true) end,
    [singleKey('h', 'Hammerspoon')] = function() hs.execute("subl '~/.hammerspoon'", true) end,
    [singleKey('d', 'Dotfiles')] = function() hs.execute("subl '~/Sites/dotfiles'", true) end,
  },
  [singleKey('t', 'toggle+')] = {
    [singleKey('m', 'MouseCircle')] = function() spoon.MouseCircle:toggle() end,
    [singleKey('/', 'Mic Toggle')] = function() spoon.PushToTalk:toggleStates({'push-to-talk', 'release-to-talk'}) end,
    [singleKey('c', 'Caps Lock')] = function() toggleCaps() end,
    [singleKey('b', 'FS Menu Bar')] = function() toggleFullScreenMenuBar() end,
  },
  [singleKey('a', 'app+')] = modalAppsHotkeys,
  [singleKey('h', 'hammerspoon+')] = {
     [singleKey('c', 'Console')] = function() hs.console.hswindow():focus() end,
     [singleKey('r', 'Reload config')] = hs.reload,
     [singleKey('e', 'Edit config')] = function() hs.execute("subl ~/.hammerspoon", true) end,
  }
}, function() closeModal() end)

function openModal()
  globalModal()
end

function closeModal()
  -- util.printAlert('closeModal')
  -- Disable single key shortcuts here.
end

-- Activate Modal Area with `hyper` + `spacebar`
hs.hotkey.bind(hyper, 'space', function() openModal() end)

-- Register Hotkeys to fire with `hyper` and specified hotkeys
function bindAppLauncherHotkeys(keys)
  for key, app in pairs(keys) do
    hs.hotkey.bind(hyper, key, function()
      util.openOrFocusLastWindow(app)
    end)
  end
end
bindAppLauncherHotkeys(applicationHotkeys)

-- Ping DNS Server for Network Round Trip Result
-- function pingResult(object, message, seqnum, error)
--     if message == "didFinish" then
--         avg = tonumber(string.match(object:summary(), '/(%d+.%d+)/'))
--         if avg == 0.0 then
--             hs.alert.show("No network")
--         elseif avg < 200.0 then
--             hs.alert.show("Network good (" .. avg .. "ms)")
--         elseif avg < 500.0 then
--             hs.alert.show("Network poor(" .. avg .. "ms)")
--         else
--             hs.alert.show("Network bad(" .. avg .. "ms)")
--         end
--     end
-- end
-- hs.hotkey.bind(hyper, "p", function()
--     hs.network.ping.ping("8.8.8.8", 1, 0.01, 1.0, "any", pingResult)
-- end)


-- Helper to get new colors from Premiere Pro

-- hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown }, function(event)
--   local currentModifiers = event:getFlags()
--   local keyPressed = hs.keycodes.map[event:getKeyCode()]
--   if event:getType() == hs.eventtap.event.types.leftMouseDown then
--     print("\n\n\n --- NEW COLOR")
--     local colorAtPointer = util.getColorAtMousePointer()
--     if (not colorAtPointer) then
--       return false
--     end
--     -- print(hs.inspect(colorAtPointer))
--     print("\n\n\n")
--   end
-- end):start()
