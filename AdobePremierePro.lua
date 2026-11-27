-- Adobe Premiere Pro (release and Beta)
--
-- Single keys (only while Premiere is frontmost, no modifiers held, not typing in a text field, Hyper not held):
--   S = Move playhead to the mouse pointer
--   D = Move playhead to the mouse pointer + continue playback at double speed
--   M = Add marker to the timeline (deselects everything first)
--   Z = Playback at double speed
--   B = Open the action menu:  N Nest Clip, D Delete Empty Tracks, O Make Offline, L Link Media,
--                              E > M Export Markers, E > E Export Media
-- Hyper + X = Toggle the single keys on/off (the "PR" menubar item shows the state and toggles on click)
--
-- These Premiere shortcuts must be assigned (Control Shift Alt = ⌃⌥⇧, they are what this module sends):
--   1 Projects, 2 Program Monitor, 3 Timelines, 4 Lumetri Color, 5 Effects Control, 6 Audio Track Mixer, 7 Effects
--   S Move Playhead to Cursor, K Shuttle Stop, L Shuttle Right
--   A Deselect All, M Add Marker, N Clip > Nest, D Delete Empty Tracks, O Make Offline, I Link Media
--   G Export Media, H Export Markers
-- The plain keys S, D, M, Z, B must be unassigned in Premiere (this module takes them over).

local util = require('util')
local AppWatcher = require('AppWatcher')
local keys = require('keys')
local singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('_ClassSingleton')()
function Class:constructor()
  if DEBUG then print('AdobePremierePro:Constructor') end
  -- Watcher prefix: matches release (`com.adobe.PremierePro`) and Beta (`com.adobe.PremierePro…`).
  self.bundleId = 'com.adobe.PremierePro'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.modal = nil
  self.hotkeys = nil
  self.menubar = nil
  self.isActive = false -- Premiere is the frontmost app
  self.offAlert = nil -- indefinite alert shown while single keys are off and Premiere is active
  self.hyper = require('HyperController'):new() -- singleton; `.active` is true while Hyper is held

  self:buildMenubar()
  self:buildSingleKeys()
  self:buildHotKeys()
  self:buildModal()
end

function Class:start(watcher)
  if DEBUG then print('AdobePremierePro:start') end
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  if DEBUG then print('AdobePremierePro:stop') end
  self:deactivated()
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  if DEBUG then print('AdobePremierePro:launched') end
end

function Class:terminated()
  if DEBUG then print('AdobePremierePro:terminated') end
  self:deactivated()
end

function Class:activated()
  if DEBUG then print('AdobePremierePro:activated') end
  self.frontApp = util.frontAppStartsWithBundleId(self.bundleId)
  self:enableSingleKeys()
  self.isActive = true
  self:enableHotKeys()
  self:showMenubar()
  self:syncOffAlert()
end

function Class:deactivated()
  if DEBUG then print('AdobePremierePro:deactivated') end
  self.frontApp = nil
  self.isActive = false
  spoon.RecursiveBinderModified.exitActive() -- close the `b` menu when switching away
  self:disableSingleKeys()
  self:disableHotKeys()
  self:hideMenubar()
  self:syncOffAlert()
end

-- Menu bar indicator for the single-key state. Created once, only shown while Premiere is active. Click toggles.
function Class:buildMenubar()
  self.menubar = hs.menubar.new(false)
  if not self.menubar then return end
  self.menubar:setClickCallback(function() self:toggleSingleKeyShortcuts() end)
  self:updateMenubar()
end

function Class:updateMenubar()
  if not self.menubar then return end
  self.menubar:setTitle(util.singleKeyShortcutsActive and 'PR ●' or 'PR ○')
  self.menubar:setTooltip(util.singleKeyShortcutsActive and 'Premiere single keys: ON (⌃⌥⌘X toggles)' or 'Premiere single keys: OFF (⌃⌥⌘X toggles)')
end

function Class:showMenubar()
  if not self.menubar then return end
  self:updateMenubar()
  self.menubar:returnToMenuBar()
end

function Class:hideMenubar()
  if self.menubar then self.menubar:removeFromMenuBar() end
end

-- Indefinite alert while single keys are off. Only exists while Premiere is the active app.
function Class:syncOffAlert()
  if self.offAlert then
    hs.alert.closeSpecific(self.offAlert, 0)
    self.offAlert = nil
  end
  if self.isActive and not util.singleKeyShortcutsActive then
    self.offAlert = hs.alert('Premiere single keys OFF (⌃⌥⌘X)', {
      radius = 0,
      atScreenEdge = 2,
      strokeColor = { white = 1, alpha = 0 },
      fadeInDuration = 0,
      fadeOutDuration = 0,
      strokeWidth = 0,
      textSize = 12,
    }, 'indefinite')
  end
end

function Class:toggleSingleKeyShortcuts()
  util.toggleSingleKeyShortcuts()
  self:updateMenubar()
  self:syncOffAlert()
end

function Class:buildAppWatcher()
  if DEBUG then print('AdobePremierePro:buildAppWatcher') end
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
  if DEBUG then print('AdobePremierePro:enableHotKeys') end
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  if DEBUG then print('AdobePremierePro:disableHotKeys') end
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  if DEBUG then print('AdobePremierePro:enableSingleKeys') end
  self.eventtap:start() -- enable normal key tracking (when premiere is in focus)
end

function Class:disableSingleKeys()
  if DEBUG then print('AdobePremierePro:disableSingleKeys') end
  self.eventtap:stop() -- disable normal key tracking (upon premiere losing focus)
end

function Class:buildHotKeys()
  if DEBUG then print('AdobePremierePro:buildHotKeys') end
  self.hotkeys = {
    ['toggle single key shortcuts'] = hs.hotkey.new(keys.hyper, 'x', function()
      self:toggleSingleKeyShortcuts()
    end),
  }
end

-- Build Eventtap to listen for Single Keys
-- The tap has already checked (Premiere frontmost, single keys on, no modifiers, Hyper not held, not typing)
-- before one of these runs.
function Class:buildSingleKeys()
  if DEBUG then print('AdobePremierePro:buildSingleKeys') end
  local keyEventsForSingleKeys = {
    ['s'] = function()
      util.printAlert("Move Playhead")
      hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
      self:focusPanel('timeline')
      hs.eventtap.keyStroke(keys.shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
      return true
    end,
    ['d'] = function()
      util.printAlert("Move Playhead & Speedup")
      hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
      self:focusPanel('timeline')
      hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.timer.doAfter(.1, function()
        hs.eventtap.keyStroke(keys.shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
        hs.timer.doAfter(.1, function()
          self:shuttleFaster()
        end)
      end)
      return true
    end,
    ['m'] = function()
      util.printAlert("Add Marker")
      self:focusPanel('timeline')
      hs.eventtap.keyStroke(keys.shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
      hs.eventtap.keyStroke(keys.shift_hyp, "m", 200, self.frontApp) -- ADD MARKER
      return true
    end,
    ['z'] = function()
      util.printAlert("Double Time 2x")
      self:focusPanel('timeline')
      self:shuttleFaster()
      return true -- prevent default
    end,
    ['b'] = function()
      self:openModal()
      return true -- prevent default
    end,
  }
  self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if not util.singleKeyShortcutsActive then -- toggled off
      return false
    end
    local targetPremiere = util.frontAppStartsWithBundleId(self.bundleId)
    if not targetPremiere then
      return false
    end
    if next(event:getFlags()) ~= nil then -- ignore input when modifiers are held
      return false
    end
    local keyFunction = keyEventsForSingleKeys[hs.keycodes.map[event:getKeyCode()]]
    if not keyFunction then
      return false
    end
    if self.hyper.active then -- Hyper is held: those keys belong to Hyper combos, not single keys
      return false
    end
    if util.focusedElementIsTextField() then -- let typing in search fields through
      return false
    end
    self.frontApp = targetPremiere
    return keyFunction()
  end)
end


function Class:buildModal()
  if DEBUG then print('AdobePremierePro:buildModal') end
  self.modal = spoon.RecursiveBinderModified.recursiveBind({
    [singleKey('n', 'Nest Clip')] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "n", 200, self.frontApp) end,
    [singleKey('d', 'Delete Empty Tracks')] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "d", 200, self.frontApp) end,
    [singleKey('o', 'Make Offline')] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "o", 200, self.frontApp) end,
    [singleKey('l', 'Link Media')] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "i", 200, self.frontApp) end,
    [singleKey('e', 'Export+')] = {
      [singleKey('m', 'Markers')] = function()
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(keys.shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(keys.shift_hyp, "h", 200, self.frontApp) -- EXPORT MARKERS
      end,
      [singleKey('e', 'Media')] = function()
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(keys.shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(keys.shift_hyp, "g", 200, self.frontApp) -- EXPORT MEDIA
      end,
    },
  }, function() self:closeModal() end)
end

function Class:openModal()
  if DEBUG then print('AdobePremierePro:openModal') end
  self:disableSingleKeys()
  return self.modal()
end

-- Runs when the menu closes by a choice or Escape (not when deactivated() force-closes it).
-- Only re-arms the single keys while Premiere is still the active app.
function Class:closeModal()
  if DEBUG then print('AdobePremierePro:closeModal') end
  if self.frontApp then self:enableSingleKeys() end
end

-- Focus Premiere Panel
-- This needs to always start from one common place (Effects Panel)
function Class:focusPanel(panel)
  if DEBUG then print('AdobePremierePro:focusPanel') end
  panel = panel or 'program'
  local panelSwitches = {
    ['projects'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "1", 200, self.frontApp)
    end,
    ['program'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "2", 200, self.frontApp)
    end,
    ['timeline'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "3", 200, self.frontApp)
    end,
    ['lumetri'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "4", 200, self.frontApp)
    end,
    ['effectsControl'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "5", 200, self.frontApp)
    end,
    ['audioMixer'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "6", 200, self.frontApp)
    end,
    ['effects'] = function()
      hs.eventtap.keyStroke(keys.shift_hyp, "7", 200, self.frontApp)
    end,
  }
  panelSwitches['effects']()
  local panelNext = panelSwitches[panel]
  if panelNext then
    panelNext()
    return true
  end
  return false
end

function Class:shuttleFaster()
  if DEBUG then print('AdobePremierePro:shuttleFaster') end

  hs.eventtap.keyStroke(keys.shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
  hs.timer.doAfter(.1, function()
    hs.eventtap.keyStroke(keys.shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
    hs.timer.doAfter(.01, function()
      hs.eventtap.keyStroke({}, "space", 2000, self.frontApp) -- SHUTTLE FORWARD 1x
      hs.timer.doAfter(.01, function()
        hs.eventtap.keyStroke(keys.shift_hyp, "l", 2000, self.frontApp) -- SHUTTLE FORWARD 2x
      end)
    end)
  end)
end

return Class
