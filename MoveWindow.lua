-- Load undocumented module for moving between spaces
local spaces = require("hs._asm.undocumented.spaces")

local util = require('./util')

-- Set global duration of all window moving transitions
hs.window.animationDuration = 0

local moveWindow = {}

-- Move Window either by Pixel or Percentages
function moveWindow.move(x, y, w, h)
  -- Adjusting for percentages and those percentages for the inclusion of the menu bar
  local window = util.getGoodFocusedWindow(true, true)
  if (not window) then return util.flashScreen([[Can't move this window!]]) end
  local screen = window:screen()
  local screenFrame = screen:absoluteToLocal(screen:frame())
  print(x,y,w,h)
  print(screenFrame)
  if util.ends_with(x, '%') then x = screenFrame.w / 100 * tonumber(x:sub(1, #x - 1)) end
  if util.ends_with(y, '%') then y = screenFrame.y + (screenFrame.h / 100 * tonumber(y:sub(1, #y - 1)))
  else y = screenFrame.y + y
  end
  if util.ends_with(w, '%') then w = screenFrame.w / 100 * tonumber(w:sub(1, #w - 1)) end
  if util.ends_with(h, '%') then h = screenFrame.h / 100 * tonumber(h:sub(1, #h - 1)) end
  -- Actually moving the window the it's place
  print(x,y,w,h)
  window:move(screen:localToAbsolute(x, y, w, h), false)
end

-- Move the Current Window to the next Screen (loops at the end)
function moveWindow.toNextScreen()
  local window = util.getGoodFocusedWindow(true, true)
  if (not window) then return util.flashScreen([[Can't move this window to the next screen.]]) end
  window:moveToScreen(hs.screen.mainScreen():next()):maximize()
end

-- Maximize the Current Window
function moveWindow.maximize()
  local window = util.getGoodFocusedWindow(true, true)
  if (not window) then return util.flashScreen([[Can't maximize this window!]]) end
  window:maximize()
end

-- Center the Current Window
function moveWindow.center(w, h)
  local window = util.getGoodFocusedWindow(true, true)
  if (not window) then return util.flashScreen([[Can't center this window!]]) end
  local screen = window:screen()
  local screenFrame = screen:absoluteToLocal(screen:fullFrame())
  local windowFrame = window:frame()
  if util.ends_with(w, '%') then w = screenFrame.w / 100 * tonumber(w:sub(1, #w - 1)) end
  if util.ends_with(h, '%') then h = screenFrame.h / 100 * tonumber(h:sub(1, #h - 1)) end
  local x = screenFrame.w / 2 - w / 2
  local y = screenFrame.h / 2 - h / 2
  window:move(screen:localToAbsolute(x, y, w, h), false)
end

-- Switch Between Spaces
function moveWindow.switchSpace(skip,dir)
  for i=1, skip do hs.eventtap.keyStroke({ "ctrl" }, dir) end
end

-- Move the Current Window to the next Sppace in dir(ection)
-- Based on ISSUE: https://github.com/Hammerspoon/hammerspoon/issues/235
function moveWindow.oneSpace(dir, switch)
  local win = util.getGoodFocusedWindow(true, true)
  if not win then return end
  local screen = win:screen()
  local uuid = screen:spacesUUID()
  local userSpaces = spaces.layout()[uuid]
  local thisSpace = win:spaces() -- first space win appears on
  if not thisSpace then return else thisSpace=thisSpace[1] end
  local last = nil
  local skipSpaces = 0
  for _, spc in ipairs(userSpaces) do
    if spaces.spaceType(spc) ~= spaces.types.user then -- skippable space
      skipSpaces = skipSpaces+1
    else -- A good user space, check it
      if last and (dir == "left" and spc == thisSpace) or (dir == "right" and last == thisSpace) then
        win:spacesMoveTo(dir == "left" and last or spc)
        if switch then
          moveWindow.switchSpace(skipSpaces + 1, dir)
          win:focus()
        end
        return
      end
      last = spc -- Haven't found it yet…
      skipSpaces = 0
    end
  end
  -- No Spaces Found in Direction => Flash Alert
  util.flashScreen([[No space in direction found.]])
end

return moveWindow
