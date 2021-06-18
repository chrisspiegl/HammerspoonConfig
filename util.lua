local systemElement = hs.axuielement.systemWideElement() -- Select System ELement

local util = {
  appDirectory = {
    ['premiere'] = 'com.adobe.PremierePro',
    ['audition'] = 'com.adobe.Audition',
    ['finder'] = 'com.apple.finder',
    ['brave'] = 'com.brave.Browser',
    ['iterm'] = 'com.googlecode.iterm2',
    ['sublimetext'] = 'com.sublimetext.4',
    ['dynalist'] = 'io.dynalist',
    ['iawriter'] = 'pro.writer.mac',
    ['telegram'] = 'ru.keepcoder.Telegram',
    ['notion'] = 'notion.id',
    ['clockify'] = 'coing.ClockifyDesktop',
  }
}

-- Easier Debugging (know that it happened by showing an alert and priting it to the console)
function util.printAlert(text)
  print(text)
  hs.alert(text, {
    radius = 0,
    fadeInDuration = 0,
    fadeOutDuration = 0,
    strokeWidth = 0,
    textSize = 12,
    strokeColor =  { white = 1, alpha = 0 },
    textStyle = {
      paragraphStyle = {
        alignment = 'center',
        paragraphSpacing = 0,
        paragraphSpacingBefore = 0,
      }
    }
  })
end

-- Debug Timer
-- START TIMER (aka return the current absolute time)
function util.timerStart()
  return hs.timer.absoluteTime()
end
-- STOP TIMERR by giving it the start time and you'll get the difference in milliseconds returned
function util.timerStop(timer)
  local endTime = hs.timer.absoluteTime()
  local diffNs = endTime - timer
  local diffMs = diffNs / 1000000
  return diffMs
end

-- Do Keystroke
-- Emulates a full Keystroke Event with Down and Up
-- SOURCE: https://github.com/Hammerspoon/hammerspoon/issues/1984#issuecomment-455317739
function util.doKeyStroke(modifiers, character)
  if type(modifiers) == 'table' then
    local event = hs.eventtap.event

    for _, modifier in pairs(modifiers) do
      event.newKeyEvent(modifier, true):post()
    end

    event.newKeyEvent(character, true):post()
    event.newKeyEvent(character, false):post()

    for i = #modifiers, 1, -1 do
      event.newKeyEvent(modifiers[i], false):post()
    end
  else
    util.printAlert('the modifiers must be a type of table like {} or {"cmd"}')
  end
end

-- Get BundleID by App Name
function util.getBundleIdByName(appName)
  -- app name is transformed to lower case and spaces are removed
  return util.appDirectory[(appName:gsub("%s+", ""):lower())]
end

-- Sort Pairs by Key
-- Use in for loop:
-- ```for name, line in pairsByKeys(lines) do
--   print(name, line)
-- end```
function util.pairsSortedByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

-- Check if the Frontmost Application is `appName` (based on `appDirectory`)
-- `appName` is easier to remember than the bundleIDs which are stored in a directory in the function.
-- Returns `false` if the app is not selected.
-- Returns `frontmostApplication` object if it is selected.
function util.frontAppIs(appName)
  local bundleId = util.getBundleIdByName(appName) or appName
  return util.frontAppStartsWithBundleId(bundleId)
end

-- Check if the Frontmost Application has a certain `bundleID`
-- Returns the `frontmostApplication` or `false`
function util.frontAppStartsWithBundleId(bundleID)
  local bundleID = bundleID or "XXXXXXXXXXX"
  local frontMostApp = hs.application.frontmostApplication()
  local frontAppBundleID = frontMostApp:bundleID()
  if frontAppBundleID:find("^"..bundleID) then
    return frontMostApp
  end
  return false
end

-- Check if a specific app is running
function util.appIsRunning(appName)
  -- Get the Bundle ID from the database or just take the appName if it is a bundle id.
  local bundleID = util.getBundleIdByName(appName) or appName
  -- Get all open applications with the requested bundleId
  local runningWithBundleId = hs.application.applicationsForBundleID(bundleID)
  -- If there are any…
  if next(runningWithBundleId) ~= nil then
    -- Return the first one in the list
    for i, app in pairs(runningWithBundleId) do return app end
  end
  return false
end

-- Open or Focus Last Window by AppName
function util.openOrFocusLastWindow(appName)
  local appIsRunning = util.appIsRunning(appName)
  if appIsRunning and appIsRunning:focusedWindow() then
    util.printAlert('Focusing: '..appName)
    appIsRunning:focusedWindow():focus()
  else
    util.printAlert('Opening: '..appName)
    hs.application.launchOrFocusByBundleID(util.getBundleIdByName(appName))
  end
end

-- Get current UI Focused Element
function util.currentElement()
  return systemElement:attributeValue("AXFocusedUIElement") -- Select Focused Element
end

-- Get the curreent UI Element Role
-- False if no role found or no element has focus.
function util.currentElementValue(currentElement)
  currentElement = currentElement or util.currentElement()
  if currentElement then
    local AXValue = currentElement:attributeValue("AXValue")
    if AXValue then
      return AXValue
    end
  end
  return false
end

-- Get the curreent UI Element Role
-- False if no role found or no element has focus.
function util.currentElementRole(currentElement)
  currentElement = currentElement or util.currentElement()
  if currentElement then
    local AXRole = currentElement:attributeValue("AXRole")
    if AXRole then
      return AXRole
    end
  end
  return false
end

-- Check if the current element role is text field.
-- Returns `false` if no element is focused or other error.
-- Returns `Focused UI Element` if it is a text field.
function util.currentElementRoleIsTextFied(currentElement)
  currentElement = currentElement or util.currentElement()
  if currentElement then
    local AXRole = currentElement:attributeValue("AXRole")
    if AXRole == 'AXTextField' then
      return currentElement
    end
  end
  return false
end

-- Get current focused element position
function util.currentElementPosition(currentElement)
  currentElement = currentElement or util.currentElement()
  return currentElement:attributeValue("AXPosition")
end

-- Get Color At Mouse Pointer
function util.getColorAtMousePointer()
  local currentScreen = hs.screen.mainScreen()
  -- local screenMode = currentScreen:currentMode()
  -- local scalingFactor = screenMode.scale
  local currentRelative = hs.mouse.getRelativePosition()
  local image = currentScreen:snapshot(hs.geometry.rect(currentRelative.x, currentRelative.y, 1, 1))
  if (image ~= nil) then
    local colorAtPointer = image:colorAt({x=1,y=1})
    print(hs.inspect(colorAtPointer))
    -- Make a big square with the color inside to the top right of the primary screen. Red border around.
    -- This way we can actually know what color was clicked.
    -- local test = hs.drawing.rectangle(hs.geometry.rect(0, 0, 200, 200))
    --       test:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    --       test:setFillColor(colorAtPointer)
    --       test:setFill(true)
    --       test:setStrokeWidth(5)
    --       test:bringToFront(true)
    --       test:show()
    return hs.drawing.color.asRGB(colorAtPointer)
  end
  return false
end

-- Math Round to Number of Decimals
function util.round(number, decimals)
  local power = 10^decimals
  return math.floor(number * power) / power
end

-- Is Color Equal to other Color? (3 decimal accuracy)
function util.isEqualColor(colorA, colorB)
  local foundEqual =  true
  for k, cA in pairs(colorA) do
    if util.round(colorB[k], 2) - util.round(cA, 2) ~= 0 then
      -- not equal, break, don't have to check other keys.
      foundEqual = false
      break
    end
    -- if I end up here, it's still equal => keep checking until end is reached
  end
  return foundEqual
end

-- Check if the colorAtPointer is equal to any of the ones in the colorDirectory
function util.findEqualColorInTable(colorAtPointer, colorDirectory)
  for key, colorCheck in pairs(colorDirectory) do
    -- if I end up here and the `foundEqual` is true then the color was found!
    if util.isEqualColor(colorCheck, colorAtPointer) then
      return colorCheck -- return the found color!
    end -- don't have to check other colors since I already found my color
  end
  return false
end

function util.starts_with(str, start)
   return type(str) == 'string' and str:sub(1, #start) == start
end

function util.ends_with(str, ending)
   return type(str) == 'string' and (ending == "" or str:sub(-#ending) == ending)
end

-- Open Path with Finder
function util.openWithFinder(path)
  os.execute('open -R '..path..'')
  hs.application.launchOrFocus('Finder')
end

-- Select focused window and check if it's standard or fullscreen
function util.getGoodFocusedWindow(noFullScreen, allowNonStandard)
   local win = hs.window.focusedWindow()
   if not win or (not win:isStandard() and not allowNonStandard) then return end
   if noFullScreen and win:isFullScreen() then return end
   return win
end

-- Flash screen for actions that are not possible
function util.flashScreen(message, screen)
  if (not screen) then screen = hs.screen.mainScreen() end
  local flash = hs.canvas.new(screen:fullFrame()):appendElements({
    action = "fill",
    fillColor = { alpha = 0.25, red=1 },
    type = "rectangle"
  })
  if (message) then util.printAlert(message)
  else util.printAlert('Impossible Action')
  end
  flash:show()
  hs.timer.doAfter(.15, function() flash:delete() end)
end

return util
