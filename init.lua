-- Got first config from: https://github.com/skrypka/hammerspoon_config/blob/master/init.lua
-- Hammerspoon Configuration and Precheck

-- Set to true for verbose prints (app switching, enable/disable of app modules).
DEBUG = false

hs.logger.defaultLogLevel = 'warning'

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

-- Only touch the layout when it is not already U.S.
if hs.keycodes.currentLayout() ~= 'U.S.' then
  if not hs.keycodes.setLayout('U.S.') then
    hs.alert('ACTIVATE U.S. KEYBOARD LAYOUT AND RESTART HAMMERSPOON', 10)
  end
end

-- Load Helper Spoon
hs.loadSpoon("RecursiveBinderModified")

-- Custom Configuration from here down…

-- Caps Lock -> F18 (HID level), re-applied on wake/unlock/USB changes. HyperController listens for F18.
require("./hidmap").start()

local util = require("./util")
local HyperController = require("./HyperController"):new()

local AppWatcher = require('./AppWatcher'):new()
AppWatcher:enable()

local premiere = require('./AdobePremierePro'):new()
premiere:start(AppWatcher)

-- DaVinci Resolve, imagefind, Audition, Lightroom, iA Writer, focus and axbrowse are parked in graveyard/ (not loaded).

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

print('Hammerspoon config loaded')
