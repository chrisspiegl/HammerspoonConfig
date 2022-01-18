-- INCREDIBLY ADVANCED HYPER
-- https://gist.github.com/amonks/d271f618cf0c52515e0b5b71a5dcf8ca
local INTRO = [[
HYPER
## install
- install hammerspoon
- save this file as `~/.hammerspoon/hyper.lua`
- add `require('hyper'):new()` to `~/.hammerspoon/init.lua`
## use
- press capslock by itself to send escape.
- or use it as a modifier:
- It acts like `command+option+ctrl`. All the modifiers at once.
- It's hard to type all the modifiers at once, so app keyboard shortcuts almost never require you to.
- But it's still allowed in set-your-own-shortcut fields!
- You now have an extra modifier key _and_ an extra escape key. Go nuts.
]]

local Class = require('./_ClassSingleton')()
function Class:constructor()
  self.definedActionKey = 'ESCAPE'
  self.hyperCombo = {"cmd","option","control"}
  -- self.hyperCombo = {"cmd","option","control","shift"}
  self.hyperAlertStyle = {
    radius = 0,
    atScreenEdge = 2,
    strokeColor = { white = 1, alpha = 0 },
    fadeInDuration = 0,
    fadeOutDuration = 0,
    strokeWidth = 0,
    textSize = 12,
  }

  -- All of the keys, from here:
  -- https://github.com/Hammerspoon/hammerspoon/blob/f3446073f3e58bba0539ff8b2017a65b446954f7/extensions/keycodes/internal.m
  -- except with ' instead of " (not sure why but it didn't work otherwise)
  -- and the function keys greater than F12 removed.
  self.keys = {
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "`",
    "=",
    "-",
    "]",
    "[",
    "\'",
    ";",
    "\\",
    ",",
    "/",
    ".",
    "§",
    "f1",
    "f2",
    "f3",
    "f4",
    "f5",
    "f6",
    "f7",
    "f8",
    "f9",
    "f10",
    "f11",
    "f12",
    "pad.",
    "pad*",
    "pad+",
    "pad/",
    "pad-",
    "pad=",
    "pad0",
    "pad1",
    "pad2",
    "pad3",
    "pad4",
    "pad5",
    "pad6",
    "pad7",
    "pad8",
    "pad9",
    "padclear",
    "padenter",
    "return",
    "tab",
    "space",
    "delete",
    "help",
    "home",
    "pageup",
    "forwarddelete",
    "end",
    "pagedown",
    "left",
    "right",
    "down",
    "up"
  }
  self.modal = hs.hotkey.modal.new({}, nil)

  self:buildHyper()
  self:buildEventtap()
end

-- sends a key event with all modifiers
-- bool -> string -> void -> side effect

function Class:buildHyper()
  local hyper = function(isdown)
    return function(key)
      return function()
        self.triggered = true
        local event = hs.eventtap.event.newKeyEvent(self.hyperCombo, key, isdown)
        event:post()
      end
    end
  end

  hyperDown = hyper(true)
  hyperUp = hyper(false)

  -- actually bind a key
  hyperBind = function(key)
    self.modal:bind('', key, nil, hyperDown(key), hyperUp(key), nil)
  end

  -- bind all the keys in the huge keys table
  for index, key in pairs(self.keys) do hyperBind(key) end
end

function Class:buildEventtap()
  -- Binding Hyper Key
  -- with the Eventtap is actually more reliable.
  -- This way we can send the ESCAPE keys more quickly.
  self.eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(event)
    local currentModifiers = event:getFlags()
    local keyPressed = hs.keycodes.map[event:getKeyCode()]
    -- print(currentModifiers)
    -- print(keyPressed)
    if event:getType() == hs.eventtap.event.types.keyDown
      and keyPressed == self.definedActionKey:lower()
      and self.previousKey ~= self.definedActionKey:lower()
       then
      -- print('down')
      self.previousKey = keyPressed
      return self:pressedActionKey()
    elseif event:getType() == hs.eventtap.event.types.keyUp
      and keyPressed == self.definedActionKey:lower()
      and self.previousKey == self.definedActionKey:lower() then
        -- print('up')
        self.previousKey = nil
        self.definedActionKey:lower()
        return self:releasedActionKey()
    end
    return false
  end)
  self.eventtap:start()
end

-- Enter Hyper Mode when F18 (Hyper/Capslock) is pressed
function Class:pressedActionKey()
  self.triggered = false
  self.modal:enter()
  self.alert = hs.alert('HYPER ACTIVE', self.hyperAlertStyle, 'indefinite')
  return false
end

-- Leave Hyper Mode when F18 (Hyper/Capslock) is pressed,
--   send ESCAPE if no other keys are pressed.
function Class:releasedActionKey()
  self.modal:exit()
  hs.alert.closeSpecific(self.alert)
  if not self.triggered then
    -- hs.eventtap.keyStroke({}, 'ESCAPE')
    hs.alert('ESCAPE', self.hyperAlertStyle, 1)
    return false , { -- using the surrounding eventtap is more reliable to send these keys than with the `doKeystroke` or simple `eventtap.keystroke`
      hs.eventtap.event.newKeyEvent({}, 'escape', true),
      hs.eventtap.event.newKeyEvent({}, 'escape', false),
    }
    -- One could just return true (if and only if the escape key is the action key!)
    -- However: then it does not work reliably because one of the key directions was blocked from happening. Not good!
    -- return true
  end
end

return Class
