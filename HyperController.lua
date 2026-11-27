-- INCREDIBLY ADVANCED HYPER
-- https://gist.github.com/amonks/d271f618cf0c52515e0b5b71a5dcf8ca
local Class = require('_ClassSingleton')()
function Class:constructor()
  self.definedActionKey = 'ESCAPE'
  self.hyperCombo = require('keys').hyper
  self.active = false -- true while the Hyper (Escape/Caps Lock) key is held
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
        if isdown then self:showCombo(key) end
        local event = hs.eventtap.event.newKeyEvent(self.hyperCombo, key, isdown)
        event:post()
      end
    end
  end

  local hyperDown = hyper(true)
  local hyperUp = hyper(false)

  -- actually bind a key
  local hyperBind = function(key)
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
        return self:releasedActionKey()
    elseif keyPressed == self.definedActionKey:lower() then
      -- ignore following HyperKey Presses
      -- print('ignore')
      return true 
    end
    -- print('outside')
    return false
  end)
  self.eventtap:start()
end

-- Glyphs for the alert, in Apple's modifier order (⌃⌥⇧⌘)
local modifierGlyphs = { {"control", "⌃"}, {"option", "⌥"}, {"shift", "⇧"}, {"cmd", "⌘"} }
local keyGlyphs = {
  ["return"] = "↩", tab = "⇥", space = "Space", delete = "⌫", forwarddelete = "⌦",
  escape = "⎋", left = "←", right = "→", up = "↑", down = "↓",
  home = "↖", ["end"] = "↘", pageup = "⇞", pagedown = "⇟", help = "Help",
  padenter = "⌤", padclear = "⌧",
}

function Class:comboGlyphs()
  if not self.comboPrefix then
    local mods = {}
    for _, m in ipairs(self.hyperCombo) do mods[m] = true end
    local glyphs = ""
    for _, pair in ipairs(modifierGlyphs) do
      if mods[pair[1]] then glyphs = glyphs .. pair[2] end
    end
    self.comboPrefix = glyphs
  end
  return self.comboPrefix
end

-- Show which shortcut the Hyper press sent, e.g. "⌃⌥⌘ K"
function Class:showCombo(key)
  local label = keyGlyphs[key] or (key:match("^pad") and "Num " .. key:sub(4):upper()) or key:upper()
  if self.comboAlert then hs.alert.closeSpecific(self.comboAlert, 0) end
  self.comboAlert = hs.alert(self:comboGlyphs() .. " " .. label, self.hyperAlertStyle, 1)
end

-- Enter Hyper Mode when Escape (Caps Lock) is pressed
function Class:pressedActionKey()
  self.active = true
  self.triggered = false
  self.modal:enter()
  self.alert = hs.alert('HYPER ' .. self:comboGlyphs(), self.hyperAlertStyle, 'indefinite')
  -- NOTE (2024-07-19): changed the `false` to `true` which means the previous event should be deleted and not propagated.
  -- This is an experiment if it affects Photoshop at all in handling this better (Firstly, a boolean, true if the event should be deleted, false if it should propagate to any other applications watching for that event. Secondly, a table of events to post.)
  return true
end

-- Leave Hyper Mode when Escape (Caps Lock) is released,
--   send ESCAPE if no other keys are pressed.
function Class:releasedActionKey()
  self.active = false
  self.modal:exit()
  hs.alert.closeSpecific(self.alert)
  if not self.triggered then
    -- hs.eventtap.keyStroke({}, 'ESCAPE')
    hs.alert('⎋ ESCAPE', self.hyperAlertStyle, 1)
    -- NOTE (2024-07-19): changed the `false` to `true` which means the previous event should be deleted and not propagated.
    -- This is an experiment if it affects Photoshop at all in handling this better (Firstly, a boolean, true if the event should be deleted, false if it should propagate to any other applications watching for that event. Secondly, a table of events to post.)
    return true, { -- using the surrounding eventtap is more reliable to send these keys than with the `doKeystroke` or simple `eventtap.keystroke`
      hs.eventtap.event.newKeyEvent({}, 'escape', true),
      hs.eventtap.event.newKeyEvent({}, 'escape', false),
    }
    -- One could just return true (if and only if the escape key is the action key!)
    -- However: then it does not work reliably because one of the key directions was blocked from happening. Not good!
    -- return true
  end
end

return Class
