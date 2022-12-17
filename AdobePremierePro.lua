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
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
function Class:constructor()
  print('AdobePremierePro:Constructor')
  self.bundleId = 'com.adobe.PremierePro'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.modal = nil
  self.hotkeys = nil

  self.timelineColor = {
    ['external - timeline above tracks'] = {
      alpha = 1.0,
      blue = 0.097136348485947,
      green = 0.097157157957554,
      red = 0.097141906619072
    },
    ['external - timeline empty track line'] = {
      alpha = 1.0,
      blue = 0.093614183366299,
      green = 0.093634232878685,
      red = 0.093619525432587
    },
    ['external - dark color in/out video tracks'] = {
      alpha = 1.0,
      blue = 0.083114176988602,
      green = 0.08313199877739,
      red = 0.083118915557861
    },
    ['external - light color in/out audio tracks'] = {
      alpha = 1.0,
      blue = 0.19546456634998,
      green = 0.19550649821758,
      red = 0.19547574222088
    },
    ['external - line between tracks'] = {
      alpha = 1.0,
      blue = 0.14378486573696,
      green = 0.14381568133831,
      red = 0.14379307627678
    },

    ['XDR - timeline above tracks'] = {
      alpha = 1.0,
      blue = 0.094971939921379,
      green = 0.094971939921379,
      red = 0.094971939921379
    },
    ['XDR - timeline empty track line'] = {
      alpha = 1.0,
      blue = 0.09775497764349,
      green = 0.097364522516727,
      red = 0.097376674413681
    },
    ['XDR - dark color in/out video tracks'] = {
      alpha = 1.0,
      blue = 0.083114176988602,
      green = 0.08313199877739,
      red = 0.083118915557861
    },
    ['XDR - light color in/out audio tracks'] = {
      alpha = 1.0,
      blue = 0.19546456634998,
      green = 0.19550649821758,
      red = 0.19547574222088
    },
    ['XDR - line between tracks'] = {
      alpha = 1.0,
      blue = 0.14444163441658,
      green = 0.14401108026505,
      red = 0.1440244615078
    },
    ['XDR - selected between tracks'] = {
      alpha = 1.0,
      blue = 0.84463649988174,
      green = 0.84463655948639,
      red = 0.84463655948639
    },

    ['interenal - main timeline color'] = {
      alpha = 1.0,
      blue = 0.094983614981174,
      green = 0.094594456255436,
      red = 0.095025971531868
    },
    ['interenal - dark color in/out'] = {
      alpha = 1.0,
      blue = 0.081531174480915,
      green = 0.0812017172575,
      red = 0.081616684794426
    },
    ['interenal - light color in/out'] = {
      alpha = 1.0,
      blue = 0.19525930285454,
      green = 0.19483198225498,
      red = 0.19481739401817
    },
    ['interenal - line between tracks'] = {
      alpha = 1.0,
      blue = 0.173,
      green = 0.173,
      red = 0.173
    },

  }

  self:buildSingleKeys()
  self:buildHotKeys()
  self:buildModal()
end

function Class:start(watcher)
  print('AdobePremierePro:start')
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  print('AdobePremierePro:stop')
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  print('AdobePremierePro:launched')
  -- util.printAlert('Premiere: Launched')
end

function Class:terminated()
  print('AdobePremierePro:terminated')
  -- util.printAlert('Premiere: Terminated')
end

function Class:activated()
  print('AdobePremierePro:activated')
  self.frontApp = util.frontAppIs(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
end

function Class:deactivated()
  print('AdobePremierePro:deactivated')
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
end

function Class:buildAppWatcher()
  print('AdobePremierePro:buildAppWatcher')
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
  print('AdobePremierePro:enableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  print('AdobePremierePro:disableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  print('AdobePremierePro:enableSingleKeys')
  self.eventtap:start() -- enable normal key tracking (when premiere is in focus)
end

function Class:disableSingleKeys()
  print('AdobePremierePro:disableSingleKeys')
  self.eventtap:stop() -- disable normal key tracking (upon premiere losing focus)
end

-- Click anywhere in the timeline to move the playhead there
-- Must configur the `s` key to be the "Move Playhead to Mouse Pointer" shortcut
-- Colors are calibrated.
function Class:timelineMovePlayheadToMouse()
  print('AdobePremierePro:timelineMovePlayheadToMouse')
  local colorAtPointer = util.getColorAtMousePointer()
  if (not colorAtPointer) then
    return false
  end
  print(hs.inspect(colorAtPointer))

  if util.findEqualColorInTable(colorAtPointer, self.timelineColor) ~= false then
    hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
    -- self:focusPanel('timeline')
    hs.eventtap.middleClick(hs.mouse.absolutePosition()) -- MIDDLE CLICK TO FOCUS TIMELINE WINDOW
    hs.eventtap.keyStroke(shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
    -- return true
  end
  return false
end

function Class:buildHotKeys()
  print('AdobePremierePro:buildHotKeys')
  self.hotkeys = {
    ['testing'] = hs.hotkey.new({'option'}, 'e', function()
      util.printAlert("TESTING CURRENTLY EMPTY")
    end),
    -- ['cut and speedup'] = hs.hotkey.new({'option'}, 'c', function()
    --   self:focusPanel('timeline')
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "c", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
    --   self:shuttleFaster()
    -- end),
    ['ripple to left with speedup'] = hs.hotkey.new({'option'}, 'q', function()
      self:focusPanel('timeline')
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "q", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      self:shuttleFaster()
    end),
    ['ripple to right with speedup'] = hs.hotkey.new({'option'}, 'w', function()
      self:focusPanel('timeline')
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      hs.eventtap.keyStroke(shift_hyp, "w", 200, self.frontApp) -- RIPPLE DELETE TO RIGHT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
      self:shuttleFaster()
    end),
  }
end

-- Build Eventtapp to listen for Single Keys & Mouse Events
function Class:buildSingleKeys()
  print('AdobePremierePro:buildSingleKeys')
  local keyEventsForSingleKeys = {
    ['s'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Move Playhead")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
        return true
      end
      return false
    end,
    ['d'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Move Playhead & Speedup")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
        -- self:focusPanel('timeline')
        hs.eventtap.keyStroke(shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
        self:shuttleFaster()
        return true
      end
      return false
    end,
    ['m'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Add Marker")
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "m", 200, self.frontApp) -- ADD MARKER
        return true
      end
      return false
    end,
    ['z'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Double Time 2x")
        self:focusPanel('timeline')
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
    elseif event:getType() == hs.eventtap.event.types.leftMouseDown then
      if next(currentModifiers) ~= nil then -- ignore input when modifiers are held
        return false
      end
      return self:timelineMovePlayheadToMouse()
    end
  end)
end


function Class:buildModal()
  print('AdobePremierePro:buildModal')
  self.modal = spoon.RecursiveBinderModified.recursiveBind({
    [singleKey('u', 'Unfocus Endcard')] = function()
      self:applyPreset('Unfocus Endcard v3') end,
    [singleKey('w', 'Warp Stabilizer')] = function()
      self:applyPreset('Warp Stabilizer') end,
    [singleKey('r', '200% to 220%')] = function()
      self:applyPreset('Zoom: 200% to 220%') end,
    [singleKey('t', '100% to 110%')] = function()
      self:applyPreset('Zoom: 100% to 110%') end,
    [singleKey('n', 'Nest Clip')] = function()
      hs.eventtap.keyStroke(shift_hyp, "n", 200, self.frontApp) end,
    [singleKey('d', 'Delete Empty Tracks')] = function()
      hs.eventtap.keyStroke(shift_hyp, "d", 200, self.frontApp) end,
    [singleKey('o', 'Make Offline')] = function()
      hs.eventtap.keyStroke(shift_hyp, "o", 200, self.frontApp) end,
    [singleKey('l', 'Link Media')] = function()
      hs.eventtap.keyStroke(shift_hyp, "i", 200, self.frontApp) end,
    [singleKey('p', 'Panels+')] = {
      [singleKey('p', 'Projects')] = function() self:focusPanel('projects') end,
      [singleKey('t', 'Timeline')] = function() self:focusPanel('timeline') end,
      [singleKey('l', 'Lumetri')] = function() self:focusPanel('lumetri') end,
      [singleKey('c', 'Effects Control')] = function() self:focusPanel('effectsControl') end,
      [singleKey('a', 'Audio Mixer')] = function() self:focusPanel('audioMixer') end,
      [singleKey('e', 'Effects')] = function() self:focusPanel('effects') end,
    },
    [singleKey('e', 'Export+')] = {
      [singleKey('m', 'Markers')] = function()
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "h", 200, self.frontApp) -- EXPORT MARKERS
      end,
      [singleKey('e', 'Media')] = function()
        self:focusPanel('timeline')
        hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "g", 200, self.frontApp) -- EXPORT MEDIA
        self:enableSingleKeys()
      end,
    },
  }, function() self:closeModal() end)
end

function Class:openModal()
  print('AdobePremierePro:openModal')
  self:disableSingleKeys()
  return self.modal()
end

function Class:closeModal()
  print('AdobePremierePro:closeModal')
  self:enableSingleKeys()
end

-- Premiere Pro Apply Preset by Name
-- Mouse must hover over clip in timeline.
-- Clip can be selected but does not have to.
-- Applying the preset to a group of clips, all clips have to be selected and the mouse must hover at least one of the clips that should get the preset applied.
function Class:applyPreset(presetName)
  print('AdobePremierePro:applyPreset')
  if not presetName then
    util.printAlert("Premiere:applyPreset: Must provide a Preset Name!")
    return
  end

  local timerStartFunction = util.timerStart()
  local mouseBefore = hs.mouse.absolutePosition()
  hs.eventtap.middleClick(mouseBefore) -- MIDDLE CLICK TO FOCUS TIMELINE WINDOW
  hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE self.STOP
  hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE self.STOP
  self:focusPanel('effects') -- Auto Switch to Effects Panel
  hs.eventtap.keyStroke(shift_hyp, "b", 15, self.frontApp) -- SELECT FIND self.BOX

  -- SOURCE FOR WORKING WITH AXUI ELEMENTS: https://balatero.com/writings/hammerspoon/retrieving-input-field-values-and-cursor-position-with-hammerspoon/
  local currentElement = nil
  local hadToWait = 0
  local timerWaitingForFocus = util.timerStart()

  hs.timer.doAfter(.1, function()
    -- TODO: can be improved with hs.timer.doUntil / doWhile? Something like that…
    -- TODO: but it still needs a timer limit or something similar so that it does not keep on going invinitely.
    currentElement = util.currentElementRoleIsTextFied()
    if not currentElement then
      util.printAlert('FOCUS ON PRESET SEARCH NOT FOUND')
      return
    end

    hs.eventtap.keyStroke({'cmd'}, "a", 20) -- SELECT ALL
    hs.eventtap.keyStroke({'shift'}, "delete", 20) -- SELECT FIND BOX
    hs.eventtap.keyStrokes(presetName) -- TYPE EFFECT NAME

    hs.timer.doAfter(.1, function()
      if not util.currentElementValue(currentElement) == presetName then
        util.printAlert('Could not fill Preset Search with "' .. presetName .. '"')
      end
      local positionPresetTextElement = util.currentElementPosition(currentElement) -- Get Screen Position of Selected Element
      -- local scalingFactor = hs.screen.mainScreen():currentMode().scale -- Get Activve Monitor Scaling Factor
      -- util.printAlert(scalingFactor)
      local offsetPresetTextElementToIcon = {x= 17, y= 55} -- Devide Offset by Screen Scaling Factor
      local positionPresetIcon = {x= positionPresetTextElement.x + offsetPresetTextElementToIcon.x, y= positionPresetTextElement.y + offsetPresetTextElementToIcon.y} -- Calculate Position of Preset Icon
      hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, positionPresetIcon):post() -- START DRAGING THE PRESET
      hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, mouseBefore):post() -- DROP THE PRESET ONTO SAVED MOUSE POSITION
      self:focusPanel('effectsControl') -- Auto Switch to Effects Panel
      self:focusPanel('timeline') -- Auto Switch to Effects Panel
      hs.eventtap.keyStroke(nil, "v", 200) -- RETURN TO MAIN EDITING MODE
      util.printAlert('Applied Preset {'.. util.timerStop(timerStartFunction) .. 'ms}')
    end)
  end)
end

-- Focus Premiere Panel
-- This needs to always start from one common place (Effects Panel)
function Class:focusPanel(panel)
  print('AdobePremierePro:focusPanel')
  panel = panel or 'program'
  local panelSwitches = {
    ['projects'] = function()
      hs.eventtap.keyStroke(shift_hyp, "1", 200, self.frontApp)
    end,
    ['program'] = function()
      hs.eventtap.keyStroke(shift_hyp, "2", 200, self.frontApp)
    end,
    ['timeline'] = function()
      hs.eventtap.keyStroke(shift_hyp, "3", 200, self.frontApp)
    end,
    ['lumetri'] = function()
      hs.eventtap.keyStroke(shift_hyp, "4", 200, self.frontApp)
    end,
    ['effectsControl'] = function()
      hs.eventtap.keyStroke(shift_hyp, "5", 200, self.frontApp)
    end,
    ['audioMixer'] = function()
      hs.eventtap.keyStroke(shift_hyp, "6", 200, self.frontApp)
    end,
    ['effects'] = function()
      hs.eventtap.keyStroke(shift_hyp, "7", 200, self.frontApp)
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
  print('AdobePremierePro:shuttleFaster')

  hs.eventtap.keyStroke(shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
  hs.timer.doAfter(.1, function()
    hs.eventtap.keyStroke(shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
    hs.timer.doAfter(.01, function()
      hs.eventtap.keyStroke({}, "space", 2000, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
        hs.timer.doAfter(.01, function()
          hs.eventtap.keyStroke(shift_hyp, "l", 2000, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
        end)
    end)
  end)

  -- hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
  -- hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
  -- -- hs.eventtap.keyStroke(shift_hyp, "l", 200, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
  -- hs.eventtap.keyStroke({}, "space", 200, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
  -- hs.eventtap.keyStroke(shift_hyp, "l", 200, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
end

return Class
