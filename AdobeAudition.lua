local INTRO = [[
Audition

Must set keyboard shortcuts in Adobe Audition:

c = Spit All Clips under Playhead
x = Ripple Delete Time Selection in All Tracks

q = Remove Shortcuts (Will be replaced by Ripple Delete to Last Clip)
w = Remove Shortcuts (Will be replaced by Ripple Delete to Next Clip)

control + option + shift + c = Spit All Clips under Playhead
control + option + shift + x = Ripple Delete Time Selection in All Tracks
control + option + shift + k = Shuttle Stop
control + option + shift + l = Shuttle Right
control + option + shift + j = Shuttle Left
control + option + shift + g = Clear Time Selection
control + option + shift + u = Heal
control + option + shift + m = Export Selected Markers
control + option + shift + , = Import Markers
control + option + shift + e = Export Mixdown

1 = Toggle Editor (Toggle Multitrack / Waveform)
f = Effect for Reduce Volume

Note:

Export all Markers (b + m) only works when the marker menu is already part of the interface as it hides and shows it to select all


]]

local util = require('./util')
local AppWatcher = require('./AppWatcher')
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
function Class:constructor()
  print('AdobeAudition:constructor')
  self.bundleId = 'com.adobe.Audition'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.hotkeys = nil

  self:buildSingleKeys()
  self:buildHotKeys()
  self:buildModal()
end

function Class:start(watcher)
  print('AdobeAudition:start')
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  print('AdobeAudition:stop')
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  print('AdobeAudition:launched')
end

function Class:terminated()
  print('AdobeAudition:terminated')
end

function Class:activated()
  print('AdobeAudition:activated')
  self.frontApp = util.frontAppIs(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
end

function Class:deactivated()
  print('AdobeAudition:deactivated')
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
end

function Class:buildAppWatcher()
  print('AdobeAudition:buildAppWatcher')
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
  print('AdobeAudition:enableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  print('AdobeAudition:disableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  print('AdobeAudition:enableSingleKeys')
  self.eventtap:start() -- enable normal key tracking (when Audition is in focus)
end

function Class:disableSingleKeys()
  print('AdobeAudition:disableSingleKeys')
  self.eventtap:stop() -- disable normal key tracking (upon Audition losing focus)
end

function Class:buildHotKeys()
  print('AdobeAudition:buildHotKeys')
  self.hotkeys = {
    ['more silent section'] = hs.hotkey.new({'cmd'}, 'f', function()
      hs.eventtap.keyStroke(nil, '1', 20000, self.frontApp)
      hs.eventtap.keyStroke(shift_hyp, 'f', 20000, self.frontApp)
      hs.eventtap.keyStroke(nil, '1', 20000, self.frontApp)
    end),
    ['cut and shuttle'] = hs.hotkey.new(hyper, 'c', function()
      hs.eventtap.keyStroke(shift_hyp, 'k', 20000, self.frontApp)
      hs.eventtap.keyStroke(shift_hyp, 'c', 20000, self.frontApp)
      self:shuttleFaster()
    end),
    ['ripple cut and shuttle'] = hs.hotkey.new(hyper, 'x', function()
      hs.eventtap.keyStroke(shift_hyp, 'k', 20000, self.frontApp)
      hs.eventtap.keyStroke(shift_hyp, 'x', 20000, self.frontApp)
      self:shuttleFaster()
    end),
    ['heal and back'] = hs.hotkey.new(hyper, '1', function()
      hs.eventtap.keyStroke(nil, '1', 20000, self.frontApp)
      hs.eventtap.keyStroke(shift_hyp, 'u', 20000, self.frontApp)
      hs.eventtap.keyStroke(nil, '1', 20000, self.frontApp)
      hs.eventtap.keyStroke(shift_hyp, 'g', 20000, self.frontApp)
    end),
  }
end

function Class:buildSingleKeys()
  print('AdobeAudition:buildSingleKeys')
  local keyEventsForSingleKeys = {
    ['q'] = function()
      if not util.currentElementRoleIsTextFied() then
        -- Ripple Trim Previous Edit to Playhead
        hs.eventtap.keyStroke(shift_hyp, 'k', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'c', 20000, self.frontApp)
        hs.eventtap.keyStroke({'option'}, 'left', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'i', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'right', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'o', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'x', 20000, self.frontApp)
        return true -- prevent default
      end
      return false -- propagate key
    end,
    ['w'] = function()
      if not util.currentElementRoleIsTextFied() then
        -- Ripple Trim Next Edit to Playhead
        hs.eventtap.keyStroke(shift_hyp, 'k', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'c', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'i', 25000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'right', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'o', 20000, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, 'x', 20000, self.frontApp)
        return true -- prevent default
      end
      return false -- propagate key
    end,
    ['z'] = function()
      -- Double Time / Shuttle Faster
      if not util.currentElementRoleIsTextFied() then
        self:shuttleFaster()
        return true -- prevent default
      end
      return false -- propagate key
    end,
    ['b'] = function()
      if not util.currentElementRoleIsTextFied() then
        self:openModal()
        return true -- prevent default
      end
      return false -- propagate key
    end,
  }
  self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown }, function(event)
    if event:getType() == hs.eventtap.event.types.keyDown then
      local keyPressed = hs.keycodes.map[event:getKeyCode()]
      local currentModifiers = event:getFlags()
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

function Class:buildModal()
  print('AdobeAudition:buildModal')
  self.modal = spoon.RecursiveBinderModified.recursiveBind({
    [singleKey('e', 'Mixdown')] = function()
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "e", 200, self.frontApp) -- EXPORT MEDIA
    end,
    [singleKey('m', 'Export Markers')] = function()
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke({ 'option' }, "8", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke({ 'option' }, "8", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke({ 'command' }, "a", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "m", 200, self.frontApp) -- EXPORT MARKERS
    end,
    [singleKey('i', 'Import Markers')] = function()
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, ",", 200, self.frontApp) -- EXPORT MEDIA
    end,
  }, function() self:closeModal() end)
end

function Class:openModal()
  print('AdobeAudition:openModal')
  self:disableSingleKeys()
  return self.modal()
end

function Class:closeModal()
  print('AdobeAudition:closeModal')
  self:enableSingleKeys()
end

function Class:shuttleFaster()
  print('AdobeAudition:shuttleFaster')
  hs.eventtap.keyStroke(shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
  hs.timer.doAfter(.1, function()
    hs.eventtap.keyStroke({}, "space", 2000, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
    hs.timer.doAfter(.01, function()
      hs.eventtap.keyStroke(shift_hyp, "l", 2000, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
    end)
  end)
end


return Class
