-- Class
-- Source: https://github.com/floydawong/lua-patterns/blob/master/singleton.lua
local function Class(super)
  local obj = {}
  obj.__index = obj
  setmetatable(obj, super)

  function obj.new(...)
    local instance = setmetatable({}, obj)
    if instance.constructor then
      instance:constructor(...)
    end
    return instance
  end

  return obj
end

return Class