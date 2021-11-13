local util = require('./util')
local AppWatcher = require('./AppWatcher')
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
function Class:constructor()
  print('iAWriter:constructor')
  self.bundleId = 'pro.writer.mac'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.modal = nil
  self.hotkeys = nil

  self:buildSingleKeys()
  self:buildHotKeys()
end

function Class:start(watcher)
  print('iAWriter:start')
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  print('iAWriter:stop')
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  print('iAWriter:launched')
end

function Class:terminated()
  print('iAWriter:terminated')
end

function Class:activated()
  print('iAWriter:activated')
  self.frontApp = util.frontAppIs(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
end

function Class:deactivated()
  print('iAWriter:deactivated')
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
end

function Class:buildAppWatcher()
  print('iAWriter:buildAppWatcher')
  if (not self.watcher) then
    self.watcher = AppWatcher:new()
  end
  self.watcher:watch(self.bundleId, {
    ['launched'] = function() self:launched() end,
    ['terminated'] = function() self:terminated() end,
    ['activated'] = function() self:activated() end,
    ['deactivated'] = function() self:deactivated() end,
  }, {
    checkFirst = true,
  })
end

function Class:enableHotKeys()
  print('iAWriter:enableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  print('iAWriter:disableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  print('iAWriter:enableSingleKeys')
  self.eventtap:start() -- enable normal key tracking (when iawriter is in focus)
end

function Class:disableSingleKeys()
  print('iAWriter:disableSingleKeys')
  self.eventtap:stop() -- disable normal key tracking (upon iawriter losing focus)
end

function Class:buildHotKeys()
  print('iAWriter:buildHotKeys')
  self.hotkeys = {
    ['copy formatted'] = hs.hotkey.new(hyper, 'c', function() hs.eventtap.keyStroke(option_cmd, "c", 200, self.frontApp) end),
    ['move line up'] = hs.hotkey.new(control_cmd, 'up', function() print('move line up'); hs.eventtap.keyStroke(option_cmd, "up", 200, self.frontApp) end),
    ['move line down'] = hs.hotkey.new(control_cmd, 'down', function() hs.eventtap.keyStroke(option_cmd, "down", 200, self.frontApp) end),
    ['open dialog'] = hs.hotkey.new(comand, 'o', nil, function() hs.eventtap.keyStroke(shift_cmd, "o", 200, self.frontApp) end)
  }
end

function Class:buildSingleKeys()
  print('iAWriter:buildSingleKeys')
  local keyEventsForSingleKeys = {
    -- ['d'] = function()
    --   if not util.currentElementRoleIsTextFied() then
    --     util.printAlert("Move Playhead & Speedup")
    --     self:focusPanel('timeline')
    --     hs.eventtap.keyStroke(nil, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
    --     self:shuttleFaster()
    --     return true
    --   end
    --   return false
    -- end,
  }
  self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown }, function(event)
    local currentModifiers = event:getFlags()
    local keyPressed = hs.keycodes.map[event:getKeyCode()]
    if event:getType() == hs.eventtap.event.types.keyDown then
      if next(currentModifiers) ~= nil then -- ignore input when modifiers are held
        return false
      end
      local keyFunction = keyEventsForSingleKeys[keyPressed]
      if keyFunction then
        return keyFunction()
      end
      return false
    end
  end)
end

return Class
