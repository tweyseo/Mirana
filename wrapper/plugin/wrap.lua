-- function reference
local type = type
local pairs = pairs
local setmetatable = setmetatable
-- include
local newTable = require("toolkit.common").newTable
-- const
local defaultTableLen = 5

-- optimize: original object reflection and function copy
local function filter(wrapper, originalObject)
    -- skip invalid originalObject
    if not originalObject then
        return true
    end

    local except = wrapper.except
    local inverse = wrapper.inverse or false
    local reflection = originalObject.reflection
    if not except or not reflection then
        return
    end

    local details = except[reflection]
    if details == nil then
        return
    end
    -- skip whole originalObject
    if details == true then
        -- inverse
        return not inverse and true or false
    end
    -- skip functions in originalObject
    if type(details) == "table" then
        local newObject
        if not inverse then
            newObject = newTable(0, #details)
            for k, _ in pairs(details) do
                newObject[k] = originalObject[k]
            end
        else
            -- inverse
            newObject = newTable(0, defaultTableLen)
            for k, v in pairs(originalObject) do
                if details[k] ~= true then
                    newObject[k] = v
                end
            end
        end

        return false, newObject
    end
end

return function(wrapper, originalObject, opt)
    local skip, newObject = filter(wrapper, originalObject)
    if skip == true then
        return originalObject
    end
    -- newObject return by filter include functions that escape from wrapping
    newObject = newObject or {}
    wrapper:prepare(newObject, opt)
    return setmetatable(newObject, { __index = function(self, index)
        local property = originalObject[index]
        if type(property) ~= "function" then
            return property
        end

        return function(...)
            wrapper:entry(self, index, ...)
            return wrapper:leave(self, index, originalObject[index](...))
        end
    end})
end