-- SecondKeyboard as Midi Controller
-- Author: Chris Spiegl
-- Website: https://ChrisSpiegl.com

local INTRO = [[
SecondKeyboard for MIDI Controls
## install
- It is easiest to follow the video instructions here: https://youtu.be/mpbMfbL3vxU
- install hammerspoon
- save this file as `~/.hammerspoon/SecondKeyboard.lua`
- add `local SecondKeyboard = require("./SecondKeyboard"):new()` to `~/.hammerspoon/init.lua`
- open the `Audio MIDI Setup.app` and activate IAC Device
- setup a virtual MIDI bus named `Hammerspoon`
## use
- open the hammerspoon log console
- reload hammerspoon configuration via log console
- press any key on the second keyboard you want to use as your midi keyboard
- look for the log message telling you the Keyboard Identifier
- replace the `0` in the line `self.keyboardIdentifier = 0` with the Keyboard Identifier
- reload the hammerspoon configuration via log console
- if all went well, you are all set and the keyboard now sends midi notes based on the keycode
]]

local Class = require('./_ClassSingleton')()

function Class:constructor()
  self.keyboardIdentifier = 40
  self.midi = hs.midi.newVirtualSource('Hammerspoon')
  self:buildEventtap()
end

function Class:buildEventtap()
  -- Binding the secondary keyboard to actually send MIDI notes upon key press.
  self.eventtap = hs.eventtap.new({hs.eventtap.event.types.keyUp, hs.eventtap.event.types.keyDown}, function(event)
    local currentModifiers = event:getFlags()
    local keyboardIdentifier = event:getProperty(hs.eventtap.event.properties.keyboardEventKeyboardType)
    local keyCode = event:getKeyCode()
    local rawEventData = event:getRawEventData()
    local keyPressed = hs.keycodes.map[event:getKeyCode()]

    if self.keyboardIdentifier == 0 then
      print('Unknown Keyboard with Identifier: ' .. tostring(keyboardIdentifier))
    elseif self.keyboardIdentifier and keyboardIdentifier == self.keyboardIdentifier then
      if event:getType() == hs.eventtap.event.types.keyDown then
        -- prevent all the keyDown events on this keyboard
        return true -- prevent default
      elseif event:getType() == hs.eventtap.event.types.keyUp then
        -- send midi notes for all the keyUp events based on the keyCode
        self.midi:sendCommand("noteOn", {
          ['note'] = keyCode,
          ["velocity"] = 50,
          ["channel"] = 0,
        })
      end
      return true -- prevent default
    end
    return false -- pass the event through unchanged
  end)
  self.eventtap:start()
end

return Class
