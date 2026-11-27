-- SecondKeyboard as Midi Controller
-- Author: Chris Spiegl
-- Website: https://ChrisSpiegl.com

-- https://github.com/jwetzell/sendosc

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

local buttonDirectory = {
  [126] = { -- up
    down = function() end,
    up = nil,
  },
  [125] = { -- down
    down = function() end,
    up = nil,
  },
  [123] = { -- left
    down = function() sendKeyCodeToPreview('left') end,
    up = nil,
  },
  [124] = { -- right
    down = function() sendKeyCodeToPreview('right') end,
    up = nil,
  },
  [36] = { -- ok
    down = function() end,
    up = nil,
  },
  [53] = { -- back
    down = function() end,
    up = nil,
  },
}

-- local buttonDirectory = {
--   [126] = { -- up
--     press = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/2/pres') end, -- Slide Previous,
--     down = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/2/down') end, -- Slide Previous,
--     up = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/2/up') end, -- Slide Previous
--     upDelay = nil,
--   },
--   [125] = { -- down
--     press = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/2/2/pres') end, -- Slide Next,
--     down = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/2/2/down') end, -- Slide Next,
--     up = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/2/2/up') end, -- Slide Next
--     upDelay = nil,
--   },
--   [123] = { -- left
--     press = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/4/pres') end, -- OBS: Slide Right,
--     down = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/4/down') end, -- OBS: Slide Right,
--     up = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/4/up') end, -- OBS: Slide Right
--     upDelay = nil,
--   },
--   [124] = { -- right
--     press = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/6/pres') end, -- PiP 1,
--     down = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/6/down') end, -- PiP 1,
--     up = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/6/up') end, -- PiP 1
--     upDelay = nil,
--   },
--   [36] = { -- ok
--     press = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/7/pres') end, -- Main,
--     down = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/7/down') end, -- Main,
--     up = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/3/7/up') end, -- Main
--     upDelay = nil,
--   },
--   [53] = { -- back
--     press = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/2/1/pres') end, -- Clear Chat,
--     down = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/2/1/down') end, -- Clear Chat,
--     up = function() os.execute('/Users/chrisspiegl/Library/pnpm/sendosc 127.0.0.1 12321 /location/1/2/1/up') end, -- Clear Chat
--     upDelay = function() print('longstuff') end,
--   },
-- }

local lastKeyPressed = nil
local Class = require('./_ClassSingleton')()

function Class:constructor()
  self.keyboardIdentifier = 40
  -- self.midi = hs.midi.newVirtualSource('Hammerspoon')
  self:buildEventtap()
end

function Class:buildEventtap()
  -- Binding the secondary keyboard to actually send MIDI notes upon key press.
  self.eventtap = hs.eventtap.new({
    hs.eventtap.event.types.keyUp,
    hs.eventtap.event.types.keyDown
  }, function(event)
    local currentModifiers = event:getFlags()
    local keyboardIdentifier = event:getProperty(hs.eventtap.event.properties.keyboardEventKeyboardType)
    local keyCode = event:getKeyCode()
    local rawEventData = event:getRawEventData()
    local eventTime = event:timestamp() / 1000000
    local keyPressed = hs.keycodes.map[event:getKeyCode()]
    local keyIsUp = (event:getType() == hs.eventtap.event.types.keyUp)
    local keyIsDown = (event:getType() == hs.eventtap.event.types.keyDown)

    if self.keyboardIdentifier == 0 then
      print('Unknown Keyboard with Identifier: ' .. tostring(keyboardIdentifier))
      print(rawEventData)
    elseif self.keyboardIdentifier and keyboardIdentifier == self.keyboardIdentifier then

      if (lastKeyPressed and keyIsDown) then
        print(lastKeyPressed .. ' prevent further key down ' .. keyCode)
        return true
      end


      local keyActions = buttonDirectory[keyCode]
      if (keyActions) then
        if keyIsDown and keyActions['down'] then
          print(keyCode .. ' down')
          keyActions['down']()
          lastKeyPressed = keyCode -- set lastKeyPressed to prevent further down triggers
        elseif keyIsUp and keyActions['up'] then
          print(keyCode .. ' up')
          keyActions['up']()
          lastKeyPressed = nil -- reset lastKeyPressed
        end
      end
      return true -- prevent default
    end
    return false -- pass the event through unchanged
  end)
  self.eventtap:start()
end



return Class
