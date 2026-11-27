-- Graveyard: was util.findOnScreen in util.lua, used only by DaVinciResolve.lua.
-- Runs graveyard/imagefind (Node + OpenCV) to locate an image on screen.
-- When bringing it back: fix the path below and switch hs.execute to hs.task,
-- because hs.execute blocks all hotkeys (Hyper too) while Node runs.

local util = require('./util')

function util.findOnScreen(target)
  local resultJson = hs.execute('./graveyard/imagefind/node_modules/.bin/run-node ./graveyard/imagefind/index.js --target '..target, true)
  local result = hs.json.decode(resultJson)
  if (result and result.found) then
    print('image was found on screen at x:'..result.x..' and y:'..result.y)

    -- local circle = hs.drawing.circle(hs.geometry.rect(
    --         result.x / result.pixelDensity-(30 / 2),
    --         result.y / result.pixelDensity-(30 / 2),
    --         30,
    --         30))
    --     circle:setStrokeColor(color)
    --     circle:setFill(false)
    --     circle:setStrokeWidth(5)
    --     circle:bringToFront(true)
    --     circle:show()

    return result
  else
    print('image was not found on screen')
    return false
  end
end

return util
