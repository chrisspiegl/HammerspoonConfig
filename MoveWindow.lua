local util = require('./util')

-- Set global duration of all window moving transitions
hs.window.animationDuration = 0

local moveWindow = {}

-- Move the Current Window to the next Screen (loops at the end)
function moveWindow.toNextScreen()
  local window = util.getGoodFocusedWindow(true, true)
  if (not window) then return util.flashScreen([[Can't move this window to the next screen.]]) end
  window:moveToScreen(hs.screen.mainScreen():next()):maximize()
end

-- Center the Current Window with 9:16 aspect ratio, filling screen vertically
function moveWindow.centerPortrait()
  local window = util.getGoodFocusedWindow(true, true)
  if (not window) then return util.flashScreen([[Can't center this window!]]) end
  local screen = window:screen()
  -- Use screen:frame() to get usable area excluding menu bar
  local screenFrame = screen:absoluteToLocal(screen:frame())

  -- Ensure perfect 9:16 aspect ratio with whole numbers
  -- Find the largest height divisible by 16 that fits in the screen
  local baseHeight = math.floor(screenFrame.h)
  local h = baseHeight - (baseHeight % 16)
  -- Calculate width with exact 9:16 ratio (height:width)
  local w = (h / 16) * 9

  -- Center horizontally, rounded to whole pixels
  local x = math.floor(screenFrame.w / 2 - w / 2)
  -- Y position is already adjusted in screenFrame to account for menu bar
  -- Add offset to center the slightly reduced height window
  local yOffset = math.floor((baseHeight - h) / 2)
  local y = math.floor(screenFrame.y) + yOffset

  window:move(screen:localToAbsolute(x, y, w, h), false)
end

return moveWindow
