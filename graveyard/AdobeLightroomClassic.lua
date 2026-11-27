
local util = require('./util')
local AppWatcher = require('./AppWatcher')
spoon.SpoonInstall:andUse("RecursiveBinderModified")
singleKey = spoon.RecursiveBinderModified.singleKey

local Class = require('./_ClassSingleton')()
function Class:constructor()
  print('AdomeLightroomClassic:Constructor')
  self.bundleId = 'com.adobe.LightroomClassic'
  self.watcher = nil
  self.frontApp = nil
  self.eventtap = nil
  self.modal = nil
  self.hotkeys = nil

  self.auxwindowAspectRatio = nil

  self:buildSingleKeys()
  self:buildHotKeys()
  self:buildModal()
end

function Class:start(watcher)
  print('AdomeLightroomClassic:start')
  self.watcher = watcher or self.watcher or nil
  self:buildAppWatcher()
  self.watcher:enable()
end

function Class:stop()
  print('AdomeLightroomClassic:stop')
  self.watcher:unwatch(self.bundleId)
end

function Class:launched()
  print('AdomeLightroomClassic:launched')
  -- util.printAlert('Premiere: Launched')
end

function Class:terminated()
  print('AdomeLightroomClassic:terminated')
  -- util.printAlert('Premiere: Terminated')
end

function Class:activated()
  print('AdomeLightroomClassic:activated')
  self.frontApp = util.frontAppIs(self.bundleId)
  self:enableSingleKeys()
  self:enableHotKeys()
end

function Class:deactivated()
  print('AdomeLightroomClassic:deactivated')
  self.frontApp = nil
  self:disableSingleKeys()
  self:disableHotKeys()
end

function Class:buildAppWatcher()
  print('AdomeLightroomClassic:buildAppWatcher')
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
  print('AdomeLightroomClassic:enableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:enable()
  end
end

function Class:disableHotKeys()
  print('AdomeLightroomClassic:disableHotKeys')
  for key, hotkey in pairs(self.hotkeys) do
    hotkey:disable()
  end
end

function Class:enableSingleKeys()
  print('AdomeLightroomClassic:enableSingleKeys')
  self.eventtap:start() -- enable normal key tracking (when premiere is in focus)
end

function Class:disableSingleKeys()
  print('AdomeLightroomClassic:disableSingleKeys')
  self.eventtap:stop() -- disable normal key tracking (upon premiere losing focus)
end

function Class:buildHotKeys()
  print('AdomeLightroomClassic:buildHotKeys')
  self.hotkeys = {
    ['testing'] = hs.hotkey.new({'command', 'control'}, 'r', function()
      util.printAlert("TESTING CURRENTLY EMPTY")
      self.auxwindowAspectRatio = self.auxwindowAspectRatio or hs.axuielement.applicationElement(self.frontApp)

      function triggerAspectRatioChange(aspectRatio) -- currently only supports the ones already in the list
        aspectRatio = aspectRatio or '4 x 5'

        function innerAspectRatioChange()
          self.auxwindowAspectRatio:elementSearch(function (msg, popUpElement, count) 
            -- print(hs.inspect(msg))
            -- print(hs.inspect(popUpElement))
            -- print(hs.inspect(count))
            for k,popUpElements in pairs(popUpElement) do
              -- print(hs.inspect(popUpElements:actionNames()))
              -- print(hs.inspect(popUpElements:allAttributeValues()))
              self.auxwindowAspectRatio = popUpElements:attributeValue('AXWindow')
              popUpElements:performAction('AXShowMenu')
              hs.timer.doAfter(.1, function ()
                for i,popUpChildren in ipairs(popUpElements) do
                  -- print(hs.inspect(i))
                  -- print(hs.inspect(popUpChildren))
                  -- print(hs.inspect(popUpChildren:actionNames()))
                  -- print(hs.inspect(popUpChildren:allAttributeValues()))
                  for i,menuChildren in ipairs(popUpChildren) do
                    -- print(hs.inspect(i))
                    -- print(hs.inspect(menuChildren))
                    -- print(hs.inspect(menuChildren:actionNames()))
                    -- print(hs.inspect(menuChildren:allAttributeValues()))
                    -- print(hs.inspect(menuChildren:attributeValue('AXTitle')))
                    -- print(util.startsWith(menuChildren:attributeValue('AXTitle'), '4 x 5'))
                    if (util.startsWith(menuChildren:attributeValue('AXTitle'), aspectRatio)) then
                      print('FOUND IT')
                      menuChildren:performAction('AXPress')
                      break
                    end
                  end
                end
              end)
            end
          end, hs.axuielement.searchCriteriaFunction({
            attribute = {
              'AXRole',
              'AXValue',
            },
            value = {
              'AXPopUpButton',
              'Original',
              'As Shot',
              'Custom',
            },
          }))
        end

        -- find the pop up element with the aspect ratios
        self.auxwindowAspectRatio:elementSearch(function (msg, result, count)
          if (count <= 0) then
            print('CROP WAS NOT OPEN')
            hs.eventtap.keyStroke({}, "r", 0, self.frontApp) -- SWITCH TO CROP MODE            
            hs.timer.doAfter(.2, function () innerAspectRatioChange() end)
            return
          end
          innerAspectRatioChange()
        end, hs.axuielement.searchCriteriaFunction({
          attribute = {
            'AXRole',
            'AXValue',
          },
          value = {
            'AXStaticText',
            'Crop & Straighten',
          },
        }))
        
      end
      triggerAspectRatioChange()

      -- hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp)
    end),
    -- ['cut and speedup'] = hs.hotkey.new({'option'}, 'c', function()
    --   self:focusPanel('timeline')
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --   hs.eventtap.keyStroke(shift_hyp, "c", 200, self.frontApp) -- RIPPLE DELETE TO LEFT
    --   self:shuttleFaster()
    -- end),
    -- ['ripple to left with speedup'] = hs.hotkey.new({'option'}, 'q', function()
    --   self:focusPanel('timeline')
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
    --   self:focusPanel('timeline')
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
  print('AdomeLightroomClassic:buildSingleKeys')
  local keyEventsForSingleKeys = {
  --   ['s'] = function()
  --     if not util.currentElementRoleIsTextFied() then
  --       util.printAlert("Move Playhead")
  --       hs.eventtap.keyStroke(nil, "escape", 200, self.frontApp) -- ESCAPE
  --       self:focusPanel('timeline')
  --       hs.eventtap.keyStroke(shift_hyp, "s", 200, self.frontApp) -- MOVE PLAYHEAD TO CURSOR
  --       return true
  --     end
  --     return false
  --   end,
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
    -- elseif event:getType() == hs.eventtap.event.types.leftMouseDown then
    --   if next(currentModifiers) ~= nil then -- ignore input when modifiers are held
    --     return false
    --   end
    --   return self:timelineMovePlayheadToMouse()
    end
  end)
end


function Class:buildModal()
  print('AdomeLightroomClassic:buildModal')
  self.modal = spoon.RecursiveBinderModified.recursiveBind({
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
    -- [singleKey('d', 'Delete Empty Tracks')] = function()
    --   hs.eventtap.keyStroke(shift_hyp, "d", 200, self.frontApp) end,
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
    --     hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
    --     hs.eventtap.keyStroke(shift_hyp, "h", 200, self.frontApp) -- EXPORT MARKERS
    --   end,
    --   [singleKey('e', 'Media')] = function()
    --     self:focusPanel('timeline')
    --     hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --     hs.eventtap.keyStroke(shift_hyp, "k", 200, self.frontApp) -- SHUTTLE STOP
    --     hs.eventtap.keyStroke(shift_hyp, "a", 200, self.frontApp) -- DESELECT ALL
    --     hs.eventtap.keyStroke(shift_hyp, "g", 200, self.frontApp) -- EXPORT MEDIA
    --     self:enableSingleKeys()
    --   end,
    -- },
  }, function() self:closeModal() end)
end

function Class:openModal()
  print('AdomeLightroomClassic:openModal')
  self:disableSingleKeys()
  return self.modal()
end

function Class:closeModal()
  print('AdomeLightroomClassic:closeModal')
  self:enableSingleKeys()
end

-- Premiere Pro Apply Preset by Name
-- Mouse must hover over clip in timeline.
-- Clip can be selected but does not have to.
-- Applying the preset to a group of clips, all clips have to be selected and the mouse must hover at least one of the clips that should get the preset applied.
function Class:applyPreset(presetName)
  print('AdomeLightroomClassic:applyPreset')
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

return Class
