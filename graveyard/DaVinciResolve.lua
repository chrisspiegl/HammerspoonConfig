-- Control Option I = Clear In
-- Control Option O = Clear Out

-- Z = Fast Forward
-- Control Shift Option Z = Fast Forward
-- Arrow up = Playback > Previous > Clip
-- Arrow down = Playback > Previous > Next

-- Control Shift Option A = Deselect All
-- Control Shift Option M = Add Marker - Blue
-- Control Shift Option X = Add Marker - Green

-- Control Shift Option J = Play Reverse
-- Control Shift Option K = Stop
-- Control Shift Option L = Play Forward
-- Control Shift Option Q = Trim > Ripple > Start to Playhead
-- Control Shift Option W = Trim > Ripple > End to Playhead
-- Control Shift Option C = Razor

-- Q = *Must be Empty*
-- W = *Must be Empty*
-- C = *Must be Empty*
-- X = *Must be Empty*
-- M = *Must be Empty*
-- B = *Must be Empty*
-- S = *Must be Empty*
-- Option Left = *Must be Empty*
-- Option Right = *Must be Empty*

-- Command Right = Nudge > One Frame Right
-- Command Left = Nudge > One Frame Left

-- # NOTES FROM PREMIERE PRO

--Control Shift Option B = Select Find Box (in Effects Panel)

-- Control Shift Option I = Link Media
-- Control Shift Option O = Make Offline
-- Control Shift Option N = Clip -> Nest

-- Control Shift Option G = Export Media
-- Control Shift Option H = Export Markers…

-- D = *Must be Empty*

local util = require('./util')
local AppWatcher = require('./AppWatcher')
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
function Class:constructor()
  print('DaVinciResolve:Constructor')
  self.bundleId = 'com.blackmagic-design.DaVinciResolve'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.modal = nil
  self.hotkeys = nil

  self.timelineColor = {
    ['internal - color 1'] = {
      alpha = 1.0,
      blue = 0.19974145293236,
      green = 0.18496330082417,
      red = 0.18543644249439
    },
    ['internal - color 3'] = {
      alpha = 1.0,
      blue = 0.13692550361156,
      green = 0.11698284745216,
      red = 0.11764259636402
    },
    ['external - default timeline color'] = {
      alpha = 1.0,
      blue = 0.15593829751015,
      green = 0.13202676177025,
      red = 0.13290430605412
    },
    ['external - selected timeline color'] = {
      alpha = 1.0,
      blue = 0.23018452525139,
      green = 0.21366016566753,
      red = 0.21424441039562
    }
  }

  self.lastWindowFrame = nil
  self.targetPositions = {
    ['davinci-resolve-timeline-icon.png'] = {
      x = 0, y = 0
    }
  }

  self:buildSingleKeys()
  self:buildHotKeys()
  self:buildModal()
end

function Class:start(watcher)
  print('DaVinciResolve:start')
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  print('DaVinciResolve:stop')
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  print('DaVinciResolve:launched')
  -- util.printAlert('DaVinciResolve: Launched')
end

function Class:terminated()
  print('DaVinciResolve:terminated')
  -- util.printAlert('DaVinciResolve: Terminated')
end

function Class:activated()
  print('DaVinciResolve:activated')
  -- util.printAlert('DaVinciResolve:activated')
  self.frontApp = util.frontAppIs(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
  self:getTargetPositions()
end

function Class:deactivated()
  print('DaVinciResolve:deactivated')
  -- util.printAlert('DaVinciResolve:deactivated')
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
end

function Class:buildAppWatcher()
  print('DaVinciResolve:buildAppWatcher')
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

function Class:getTargetPositions(forced)
  local currentWindowFrame = hs.window.frontmostWindow():frame()
  print(hs.inspect(currentWindowFrame))
  print(hs.inspect(self.lastWindowFrame))
  print(hs.inspect(self.lastWindowFrame == currentWindowFrame))
  if (not forced and self.lastWindowFrame and currentWindowFrame and currentWindowFrame == self.lastWindowFrame) then
    return
  else
    -- only process if the window frame changed
    self.lastWindowFrame = currentWindowFrame
    util.printAlert('Processing Image Target Positions')
    hs.timer.doAfter(0.01, function()
      for target in pairs(self.targetPositions) do
        self.targetPositions[target] = util.findOnScreen(target)
        print(hs.inspect(self.targetPositions))
      end
      util.printAlert('Finished Image Target Processing')
    end)
  end
end

function Class:enableHotKeys()
  print('DaVinciResolve:enableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  print('DaVinciResolve:disableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  print('DaVinciResolve:enableSingleKeys')
  self.eventtap:start() -- enable normal key tracking (when premiere is in focus)
end

function Class:disableSingleKeys()
  print('DaVinciResolve:disableSingleKeys')
  self.eventtap:stop() -- disable normal key tracking (upon premiere losing focus)
end

-- Click anywhere in the timeline to move the playhead there
-- Must configur the `s` key to be the "Move Playhead to Mouse Pointer" shortcut
-- Colors are calibrated.
function Class:timelineMovePlayheadToMouseStart()
  print('DaVinciResolve:timelineMovePlayheadToMouse')
  local colorAtPointer = util.getColorAtMousePointer()
  if (not colorAtPointer) then
    print('no color found at mouse pointer position')
    return false
  end
  if util.findEqualColorInTable(colorAtPointer, self.timelineColor) == false then
    print('the color was not found in the color match table, it actually was:')
    print(hs.inspect(colorAtPointer))
    return false
  end
  if (not self.targetPositions['davinci-resolve-timeline-icon.png'] or not self.targetPositions['davinci-resolve-timeline-icon.png'].found) then return false end
  local targetPosition = self.targetPositions['davinci-resolve-timeline-icon.png']
  local mouseBefore = hs.mouse.absolutePosition()
  if (mouseBefore.y <= targetPosition.y / targetPosition.pixelDensity) then return false end
  self.mouseDragEventTap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseUp }, function(event)
    -- print('up it goes')
    self.eventtap:start()
    self.mouseDragEventTap:stop()
  end)
  self.eventtap:stop()
  self.mouseDragEventTap:start()

  local posClick = {
    x = mouseBefore.x,
    y = targetPosition.y / targetPosition.pixelDensity + 27 * targetPosition.pixelDensity
  }

  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, posClick):post() -- START DRAGING THE PRESET
  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, mouseBefore):post() -- START DRAGING THE PRESET
  return true
end

function Class:movePlayheadToMouse()
  local eventtapStatus = self.eventtap:isEnabled()
  self.eventtap:stop()
  if (self.targetPositions['davinci-resolve-timeline-icon.png'] and self.targetPositions['davinci-resolve-timeline-icon.png'].found) then
    local targetPosition = self.targetPositions['davinci-resolve-timeline-icon.png']
    local mouseBefore = hs.mouse.absolutePosition()

    local posClick = {
      x = mouseBefore.x,
      y = targetPosition.y / targetPosition.pixelDensity + 27 * targetPosition.pixelDensity
    }

    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, posClick):post() -- START DRAGING THE PRESET
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, mouseBefore):post() -- DROP THE PRESET ONTO SAVED MOUSE POSITION
  end
  if eventtapStatus then self.eventtap:start() end
end

function Class:buildHotKeys()
  print('DaVinciResolve:buildHotKeys')
  self.hotkeys = {
    -- ['cut and speedup'] = hs.hotkey.new({'option'}, 'c', function()
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "c", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
    --   self:shuttleFaster()
    -- end),
    ['10 Frames Forward'] = hs.hotkey.new({'option'}, 'left', function()
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      for i = 0, 10 do hs.eventtap.keyStroke({}, "left", 200, self.frontApp) end
    end),
    ['10 Frames Backward'] = hs.hotkey.new({'option'}, 'right', function()
      hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
      for i = 0, 10 do hs.eventtap.keyStroke({}, "right", 200, self.frontApp) end
    end),
    -- ['ripple to left with speedup'] = hs.hotkey.new({'option'}, 'q', function()
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "q", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   self:shuttleFaster()
    -- end),
    -- ['ripple to right with speedup'] = hs.hotkey.new({'option'}, 'w', function()
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "w", 200, self.frontApp) -- RIPPLE DELETE TO RIGHT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   hs.eventtap.keyStroke(shift, "left", 200, self.frontApp) -- MOVE PAYHEAD _X_ FRAMES LEFT
    --   self:shuttleFaster()
    -- end),
  }
end

-- Build Eventtapp to listen for Single Keys & Mouse Events
function Class:buildSingleKeys()
  print('DaVinciResolve:buildSingleKeys')
  local keyEventsForSingleKeys = {
    ['s'] = function()
      if not util.currentElementRoleIsTextFied() then
        -- util.printAlert("Move Playhead")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
        self:movePlayheadToMouse()
        return true
      else return false end
    end,
    ['q'] = function()
      if not util.currentElementRoleIsTextFied() then
        -- util.printAlert("Deslect All & Ripple Delete to Start")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, "q", 200, self.frontApp)
        return true
      else return false end
    end,
    ['w'] = function()
      if not util.currentElementRoleIsTextFied() then
        -- util.printAlert("Deslect All & Ripple Delete to Start")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp)
        hs.eventtap.keyStroke(shift_hyp, "w", 200, self.frontApp)
        return true
      else return false end
    end,
    ['d'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Move Playhead & Speedup")
        hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
        hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- FAST FORWARD
        hs.timer.doAfter(0.1, function()
          self:movePlayheadToMouse()
          hs.timer.doAfter(0.1, function()
            hs.eventtap.keyStroke(shift_hyp, "z", 200, self.frontApp) -- FAST FORWARD
          end)
        end)
        return true
      else return false end
    end,
    ['m'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Add Marker")
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "m", 200, self.frontApp) -- ADD MARKER
        return true
      else return false end
    end,
    ['x'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Add Chapter Marker")
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "x", 200, self.frontApp) -- ADD MARKER
        return true
      else return false end
    end,
    ['c'] = function()
      if not util.currentElementRoleIsTextFied() then
        util.printAlert("Cut Through All Tracks")
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
        hs.eventtap.keyStroke(shift_hyp, "c", 200, self.frontApp) -- ADD MARKER
        return true
      else return false end
    end,
    -- ['z'] = function()
    --   if not util.currentElementRoleIsTextFied() then
    --     util.printAlert("Double Time 2x")
    --     self:focusPanel('timeline')
    --     self:shuttleFaster()
    --     return true -- prevent default
    --   end
    --   return false -- propagate key
    -- end,
    ['b'] = function()
      if not util.currentElementRoleIsTextFied() then
        self:openModal()
        return true -- prevent default
      end
      return false -- propagate key
    end,
  }
  self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.leftMouseUp }, function(event)
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
      return self:timelineMovePlayheadToMouseStart()
    end
  end)
end


function Class:buildModal()
  print('DaVinciResolve:buildModal')
  self.modal = spoon.RecursiveBinderModified.recursiveBind({
    [singleKey('w', 'Recheck Timline Position')] = function()
      self:getTargetPositions(true) end,
    -- [singleKey('u', 'Unfocus Endcard')] = function()
    --   self:applyPreset('Unfocus Endcard v3') end,
    -- [singleKey('w', 'Warp Stabilizer')] = function()
    --   self:applyPreset('Warp Stabilizer') end,
    -- [singleKey('r', '200% to 220%')] = function()
    --   self:applyPreset('Zoom: 200% to 220%') end,
    -- [singleKey('t', '100% to 110%')] = function()
    --   self:applyPreset('Zoom: 100% to 110%') end,
    -- [singleKey('n', 'Nest Clip')] = function()
    --   hs.eventtap.keyStroke(shift_hyp, "n", 200, self.frontApp) end,
    -- [singleKey('o', 'Make Offline')] = function()
    --   hs.eventtap.keyStroke(shift_hyp, "o", 200, self.frontApp) end,
    -- [singleKey('l', 'Link Media')] = function()
    --   hs.eventtap.keyStroke(shift_hyp, "i", 200, self.frontApp) end,
    -- [singleKey('p', 'Panels+')] = {
    --   [singleKey('p', 'Projects')] = function() self:focusPanel('projects') end,
    --   [singleKey('t', 'Timeline')] = function() self:focusPanel('timeline') end,
    --   [singleKey('l', 'Lumetri')] = function() self:focusPanel('lumetri') end,
    --   [singleKey('c', 'Effects Control')] = function() self:focusPanel('effectsControl') end,
    --   [singleKey('a', 'Audio Mixer')] = function() self:focusPanel('audioMixer') end,
    --   [singleKey('e', 'Effects')] = function() self:focusPanel('effects') end,
    -- },
    -- [singleKey('e', 'Export+')] = {
    --   [singleKey('m', 'Markers')] = function()
    --     self:focusPanel('timeline')
    --     hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --     hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --     hs.eventtap.keyStroke({'shift', 'cmd'}, "a", 200, self.frontApp) -- DESELECT ALL
    --     hs.eventtap.keyStroke(shift_hyp, "m", 200, self.frontApp) -- EXPORT MARKERS
    --   end,
    --   [singleKey('e', 'Media')] = function()
    --     self:focusPanel('timeline')
    --     hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --     hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --     hs.eventtap.keyStroke({'shift', 'cmd'}, "a", 200, self.frontApp) -- DESELECT ALL
    --     hs.eventtap.keyStroke(shift_hyp, "e", 200, self.frontApp) -- EXPORT MEDIA
    --   end,
    -- },
  }, function() self:closeModal() end)
end

function Class:openModal()
  print('DaVinciResolve:openModal')
  self:disableSingleKeys()
  return self.modal()
end

function Class:closeModal()
  print('DaVinciResolve:closeModal')
  self:enableSingleKeys()
end

-- Premiere Pro Apply Preset by Name
-- Mouse must hover over clip in timeline.
-- Clip can be selected but does not have to.
-- Applying the preset to a group of clips, all clips have to be selected and the mouse must hover at least one of the clips that should get the preset applied.
function Class:applyPreset(presetName)
  print('DaVinciResolve:applyPreset')
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
  print('DaVinciResolve:focusPanel')
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

-- function Class:shuttleFaster()
--   print('DaVinciResolve:shuttleFaster')

--   hs.eventtap.keyStroke(shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
--   hs.timer.doAfter(.1, function()
--     hs.eventtap.keyStroke(shift_hyp, "k", 2000, self.frontApp) -- SHUTTLE STOP
--     hs.timer.doAfter(.01, function()
--       hs.eventtap.keyStroke({}, "space", 2000, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
--         hs.timer.doAfter(.01, function()
--           hs.eventtap.keyStroke(shift_hyp, "l", 2000, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
--         end)
--     end)
--   end)

--   -- hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
--   -- hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
--   -- -- hs.eventtap.keyStroke(shift_hyp, "l", 200, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
--   -- hs.eventtap.keyStroke({}, "space", 200, self.frontApp) -- SHUTTLE FORWARD 1x self.Speed
--   -- hs.eventtap.keyStroke(shift_hyp, "l", 200, self.frontApp) -- SHUTTLE FORWARD 2x self.Speed
-- end

return Class
