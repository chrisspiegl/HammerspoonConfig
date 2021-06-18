local util = require('./util')
local AppWatcher = require('./AppWatcher')
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
function Class:constructor()
  print('Dynalist:constructor')
  self.bundleId = 'io.dynalist'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.modal = nil
  self.hotkeys = nil

  self:buildSingleKeys()
  self:buildHotKeys()
end

function Class:start(watcher)
  print('Dynalist:start')
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  print('Dynalist:stop')
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  print('Dynalist:launched')
end

function Class:terminated()
  print('Dynalist:terminated')
end

function Class:activated()
  print('Dynalist:activated')
  self.frontApp = util.frontAppIs(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
end

function Class:deactivated()
  print('Dynalist:deactivated')
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
end

function Class:buildAppWatcher()
  print('Dynalist:buildAppWatcher')
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
  print('Dynalist:enableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  print('Dynalist:disableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  print('Dynalist:enableSingleKeys')
  self.eventtap:start() -- enable normal key tracking (when iawriter is in focus)
end

function Class:disableSingleKeys()
  print('Dynalist:disableSingleKeys')
  self.eventtap:stop() -- disable normal key tracking (upon iawriter losing focus)
end

function Class:buildHotKeys()
  print('Dynalist:buildHotKeys')
  self.hotkeys = {
    ['open/close list item up'] = hs.hotkey.new({ 'command', 'control' }, 'up', function() hs.eventtap.keyStroke({ 'command' }, ".", 200, self.frontApp) end),
    ['open/close list item down'] = hs.hotkey.new({ 'command', 'control' }, 'down', function() hs.eventtap.keyStroke({ 'command' }, ".", 200, self.frontApp) end),
    -- ['open dialog'] = hs.hotkey.new(comand, 'o', nil, function() hs.eventtap.keyStroke(shift_cmd, "o", 200, self.frontApp) end)
  }
end

function Class:buildSingleKeys()
  print('Dynalist:buildSingleKeys')
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
