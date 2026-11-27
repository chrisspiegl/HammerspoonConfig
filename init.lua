
-- Got first config from: https://github.com/skrypka/hammerspoon_config/blob/master/init.lua
-- Hammerspoon Configuration and Precheck

hs.logger.defaultLogLevel="info"
print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
print("Is Hammerspoon in the Accessibility Privacy settings activated?")
print(hs.accessibilityState() and "\tYes, all good." or "\tNo, you have to add Hammerspoon there!")
-- Reload only when a .lua file changes (not on .git, graveyard, .DS_Store or logs).
-- The short delay folds a burst of saves into one reload.
local reloadTimer
reload_watcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in ipairs(files) do
    if file:match("%.lua$") and not file:match("/%.git/") and not file:match("/graveyard/") then
      if reloadTimer then reloadTimer:stop() end
      reloadTimer = hs.timer.doAfter(0.3, hs.reload)
      return
    end
  end
end):start()

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

local AppWatcher = require('./AppWatcher'):new()
AppWatcher:enable()

local premiere = require('./AdobePremierePro'):new()
premiere:start(AppWatcher)

-- local audition = require('./AdobeAudition'):new()
-- audition:start(AppWatcher)

-- local lightroom = require('./AdobeLightroomClassic'):new()
-- lightroom:start(AppWatcher)

-- DaVinci Resolve and imagefind are parked in graveyard/ (not loaded).

-- local iawriter = require('./IaWriter'):new()
-- iawriter:start(AppWatcher)

-- local dynalist = require('./Dynalist'):new()
-- dynalist:start(AppWatcher)

-- Moving windows (more layouts are in graveyard/init-2026-11-27.lua)
local moveWindow = require("./moveWindow")
hs.hotkey.bind({ 'control', 'option' }, "down", function() moveWindow.toNextScreen() end) -- Move to Next Screen
hs.hotkey.bind({ 'control', 'option' }, "v", function() moveWindow.centerPortrait() end) -- Move to Next Screen

-- Color presets
col = hs.drawing.color.x11

-- Swallow Option+Space and Shift+Option+Space (they type a non-breaking space)
hs.hotkey.bind({'alt'}, 'space', function() return nil end) -- an empty space is more reliably typed via keys since it is text we want to enter.
hs.hotkey.bind({'alt', 'shift'}, 'space', function() return nil end) -- an empty space is more reliably typed via keys since it is text we want to enter.

-- Everything else that was commented out here (Spoons, modal launcher, caps toggle,
-- ping, color picker, focus monitor) lives in graveyard/init-2026-11-27.lua.
