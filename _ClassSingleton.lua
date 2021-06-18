-- Singleton Class
-- Source: https://github.com/floydawong/lua-patterns/blob/master/singleton.lua
local function ClassSingleton(super)
  local obj = {}
  obj.__index = obj
  setmetatable(obj, super)

  function obj.new(...)
    if obj._instance then
      return obj._instance
    end

    local instance = setmetatable({}, obj)
    if instance.constructor then
      instance:constructor(...)
    end

    obj._instance = instance
    return obj._instance
  end

  return obj
end

return ClassSingleton