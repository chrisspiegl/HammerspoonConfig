-- Control Shift Alt B = Select Find Box (in Effects Panel)

-- Control Shift Alt 1 = Projects
-- Control Shift Alt 2 = Program Monitor
-- Control Shift Alt 3 = Timelines
-- Control Shift Alt 4 = Lumetri Color
-- Control Shift Alt 5 = Effects Control
-- Control Shift Alt 6 = Audio Track Mixer
-- Control Shift Alt 7 = Effects

-- Control Shift Alt I = Link Media
-- Control Shift Alt O = Make Offline
-- Control Shift Alt S = Move Playhead to Cursor
-- Control Shift Alt N = Clip -> Nest

-- Control Shift Alt D = Delete Empty Tracks
-- Control Shift Alt G = Export Media
-- Control Shift Alt H = Export Markers…
-- Control Shift Alt M = Add Marker
-- Control Shift Alt A = Deselect All
-- Control Shift Alt J = Shuttle Left
-- Control Shift Alt K = Shuttle Stop
-- Control Shift Alt L = Shuttle Right
-- Control Shift Alt Q = Ripple Trim Previous Edit to Playhead
-- Control Shift Alt W = Ripple Trim Next Edit to Playhead

-- X = Add Chapter Marker
-- Control Shift Alt C = Add Edit to All Tracks
-- C = Add Edit to All Tracks

-- B = *Must be Empty*
-- D = *Must be Empty*
-- M = *Must be Empty*
-- S = *Must be Empty*
-- Z = *Must be Empty*

local util = require('./util')
local AppWatcher = require('./AppWatcher')
local keys = require('./keys')
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
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

  self.timelineColor = {
    -- ['internal M1 Max - timeline above tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.11372549019608,
    --   green = 0.11372549019608,
    --   red = 0.11372549019608
    -- },
    -- ['internal M1 Max - timeline empty track line'] = {
    --   alpha = 1.0,
    --   blue = 0.12549019607843,
    --   green = 0.12549019607843,
    --   red = 0.12549019607843
    -- },
    -- ['internal M1 Max - dark color in/out video tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.10588235294118,
    --   green = 0.10588235294118,
    --   red = 0.10980392156863
    -- },
    -- ['internal M1 Max - light color in/out audio tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.25882352941176,
    --   green = 0.25490196078431,
    --   red = 0.25882352941176
    -- },
    -- ['internal M1 Max - line between tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.1921568627451,
    --   green = 0.1921568627451,
    --   red = 0.1921568627451
    -- },
    -- ['external - timeline above tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.097136348485947,
    --   green = 0.097157157957554,
    --   red = 0.097141906619072
    -- },
    -- ['external - timeline empty track line'] = {
    --   alpha = 1.0,
    --   blue = 0.093614183366299,
    --   green = 0.093634232878685,
    --   red = 0.093619525432587
    -- },
    -- ['external - dark color in/out video tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.083114176988602,
    --   green = 0.08313199877739,
    --   red = 0.083118915557861
    -- },
    -- ['external - light color in/out audio tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.19546456634998,
    --   green = 0.19550649821758,
    --   red = 0.19547574222088
    -- },
    -- ['external - line between tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.14378486573696,
    --   green = 0.14381568133831,
    --   red = 0.14379307627678
    -- },

    -- ['XDR - timeline above tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.094971939921379,
    --   green = 0.094971939921379,
    --   red = 0.094971939921379
    -- },
    -- ['XDR - timeline empty track line'] = {
    --   alpha = 1.0,
    --   blue = 0.09775497764349,
    --   green = 0.097364522516727,
    --   red = 0.097376674413681
    -- },
    -- ['XDR - dark color in/out video tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.083114176988602,
    --   green = 0.08313199877739,
    --   red = 0.083118915557861
    -- },
    -- ['XDR - light color in/out audio tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.19546456634998,
    --   green = 0.19550649821758,
    --   red = 0.19547574222088
    -- },
    -- ['XDR - line between tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.14444163441658,
    --   green = 0.14401108026505,
    --   red = 0.1440244615078
    -- },
    -- ['XDR - selected between tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.84463649988174,
    --   green = 0.84463655948639,
    --   red = 0.84463655948639
    -- },

    -- ['interenal - main timeline color'] = {
    --   alpha = 1.0,
    --   blue = 0.094983614981174,
    --   green = 0.094594456255436,
    --   red = 0.095025971531868
    -- },
    -- ['interenal - dark color in/out'] = {
    --   alpha = 1.0,
    --   blue = 0.081531174480915,
    --   green = 0.0812017172575,
    --   red = 0.081616684794426
    -- },
    -- ['interenal - light color in/out'] = {
    --   alpha = 1.0,
    --   blue = 0.19525930285454,
    --   green = 0.19483198225498,
    --   red = 0.19481739401817
    -- },
    -- ['interenal - line between tracks'] = {
    --   alpha = 1.0,
    --   blue = 0.173,
    --   green = 0.173,
    --   red = 0.173
    -- },
  }

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
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  if DEBUG then print('AdobePremierePro:launched') end
  -- util.printAlert('Premiere: Launched')
end

function Class:terminated()
  if DEBUG then print('AdobePremierePro:terminated') end
  -- util.printAlert('Premiere: Terminated')
end

function Class:activated()
  if DEBUG then print('AdobePremierePro:activated') end
  self.frontApp = util.frontAppStartsWithBundleId(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
  self:createMenubar()
end

function Class:deactivated()
  if DEBUG then print('AdobePremierePro:deactivated') end
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
  self:deleteMenubar()
end

-- Menu bar indicator for the single-key state; only exists while Premiere is active. Click toggles.
function Class:updateMenubar()
  if not self.menubar then return end
  self.menubar:setTitle(util.singleKeyShortcutsActive and 'PR ●' or 'PR ○')
  self.menubar:setTooltip(util.singleKeyShortcutsActive and 'Premiere single keys: ON (⌃⌥⌘X toggles)' or 'Premiere single keys: OFF (⌃⌥⌘X toggles)')
end

function Class:createMenubar()
  if self.menubar then return end
  self.menubar = hs.menubar.new()
  if not self.menubar then return end
  self.menubar:setClickCallback(function() self:toggleSingleKeyShortcuts() end)
  self:updateMenubar()
end

function Class:deleteMenubar()
  if self.menubar then
    self.menubar:delete()
    self.menubar = nil
  end
end

function Class:toggleSingleKeyShortcuts()
  util.toggleSingleKeyShortcuts()
  self:updateMenubar()
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

-- Click anywhere in the timeline to move the playhead there
-- Must configur the `s` key to be the "Move Playhead to Mouse Pointer" shortcut
-- Colors are calibrated.
function Class:timelineMovePlayheadToMouse()
  if DEBUG then print('AdobePremierePro:timelineMovePlayheadToMouse') end
  local colorAtPointer = util.getColorAtMousePointer()
  if (not colorAtPointer) then
    return false
  end
  -- print(hs.inspect(colorAtPointer))

  -- if util.findEqualColorInTable(colorAtPointer, self.timelineColor) ~= false then
  --   hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
  --   -- self:focusPanel('timeline')
  --   hs.eventtap.middleClick(hs.mouse.absolutePosition()) -- MIDDLE CLICK TO FOCUS TIMELINE WINDOW
  --   hs.eventtap.keyStroke(keys.shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
  --   -- return true
  -- end
  return false
end

function Class:buildHotKeys()
  if DEBUG then print('AdobePremierePro:buildHotKeys') end
  self.hotkeys = {
    -- ['testing'] = hs.hotkey.new({'option'}, 'e', function()
    --   util.printAlert("TESTING CURRENTLY EMPTY")
    -- end),
    -- ['cut and speedup'] = hs.hotkey.new({'option'}, 'c', function()
    --   self:focusPanel('timeline')
    --   hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(keys.shift_hyp, "c", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
    --   self:shuttleFaster()
    -- end),
    -- ['ripple to left with speedup'] = hs.hotkey.new({'option'}, 'q', function()
    --   self:focusPanel('timeline')
    --   hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(keys.shift_hyp, "q", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   self:shuttleFaster()
    -- end),
    -- ['ripple to right with speedup'] = hs.hotkey.new({'option'}, 'w', function()
    --   self:focusPanel('timeline')
    --   hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(keys.shift_hyp, "w", 200, self.frontApp) -- RIPPLE DELETE TO RIGHT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   self:shuttleFaster()
    -- end),
    ['toggle single key shortcuts'] = hs.hotkey.new(keys.hyper, 'x', function()
      util.printAlert("Toggle SingleKeyShortcuts")
      self:toggleSingleKeyShortcuts()
    end),
  }
end

-- Build Eventtap to listen for Single Keys
function Class:buildSingleKeys()
  if DEBUG then print('AdobePremierePro:buildSingleKeys') end
  local keyEventsForSingleKeys = {
    ['s'] = function()
      -- if not util.currentElementRoleIsTextFied() then
      -- if nil == util.currentElement() then
      if util.singleKeyShortcutsActive and not util.focusedElementIsTextField() then
        util.printAlert("Move Playhead")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(keys.shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
        return true
      end
      return false
    end,
    ['d'] = function()
      if util.singleKeyShortcutsActive and not util.focusedElementIsTextField() then
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
      end
      return false
    end,
    ['m'] = function()
      -- if not util.currentElementRoleIsTextFied() then
      -- if nil == util.currentElement() then
      if util.singleKeyShortcutsActive and not util.focusedElementIsTextField() then
        util.printAlert("Add Marker")
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(keys.shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(keys.shift_hyp, "m", 200, self.frontApp) -- ADD MARKER
        return true
      end
      return false
    end,
    ['z'] = function()
      -- if not util.currentElementRoleIsTextFied() then
      -- if nil == util.currentElement() then
      if util.singleKeyShortcutsActive and not util.focusedElementIsTextField() then
        util.printAlert("Double Time 2x")
        self:focusPanel('timeline')
        self:shuttleFaster()
        return true -- prevent default
      end
      return false -- propagate key
    end,
    ['b'] = function()
      -- if not util.currentElementRoleIsTextFied() then
      -- if nil == util.currentElement() then
      if util.singleKeyShortcutsActive and not util.focusedElementIsTextField() then
        self:openModal()
        return true -- prevent default
      end
      return false -- propagate key
    end,
  }
  self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if next(event:getFlags()) ~= nil then -- ignore input when modifiers are held
      return false
    end
    local keyFunction = keyEventsForSingleKeys[hs.keycodes.map[event:getKeyCode()]]
    if not keyFunction then
      return false
    end
    local targetPremiere = util.frontAppStartsWithBundleId(self.bundleId)
    if not targetPremiere then
      return false
    end
    self.frontApp = targetPremiere
    if util.focusedElementIsTextField() then -- let typing in search fields through
      return false
    end
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
    -- [singleKey('p', 'Panels+')] = {
    --   [singleKey('p', 'Projects')] = function() self:focusPanel('projects') end,
    --   [singleKey('t', 'Timeline')] = function() self:focusPanel('timeline') end,
    --   [singleKey('l', 'Lumetri')] = function() self:focusPanel('lumetri') end,
    --   [singleKey('c', 'Effects Control')] = function() self:focusPanel('effectsControl') end,
    --   [singleKey('a', 'Audio Mixer')] = function() self:focusPanel('audioMixer') end,
    --   [singleKey('e', 'Effects')] = function() self:focusPanel('effects') end,
    -- },
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
        self:enableSingleKeys()
      end,
    },
  }, function() self:closeModal() end)
end

function Class:openModal()
  if DEBUG then print('AdobePremierePro:openModal') end
  self:disableSingleKeys()
  return self.modal()
end

function Class:closeModal()
  if DEBUG then print('AdobePremierePro:closeModal') end
  self:enableSingleKeys()
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

function Class:shuttleFaster(double)
  if DEBUG then print('AdobePremierePro:shuttleFaster') end

  hs.eventtap.keyStroke(keys.shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
  hs.timer.doAfter(.1, function()
    hs.eventtap.keyStroke(keys.shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
    hs.timer.doAfter(.01, function()
      hs.eventtap.keyStroke({}, "space", 2000, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
        hs.timer.doAfter(.01, function()
          hs.eventtap.keyStroke(keys.shift_hyp, "l", 2000, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
          if double then
            hs.timer.doAfter(.01, function()
              hs.eventtap.keyStroke(keys.shift_hyp, "l", 2000, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
            end)
          end
        end)
    end)
  end)

  -- hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
  -- hs.eventtap.keyStroke(keys.shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
  -- -- hs.eventtap.keyStroke(keys.shift_hyp, "l", 200, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
  -- hs.eventtap.keyStroke({}, "space", 200, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
  -- hs.eventtap.keyStroke(keys.shift_hyp, "l", 200, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
end

return Class
