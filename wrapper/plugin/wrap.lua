-- function reference
local type = type
local pairs = pairs
local setmetatable = setmetatable
-- include
local newTable = require("toolkit.common").newTable
-- const
local defaultTableLen = 5
local defaultSkip = true

-- optimize: original object reflection and function copy
local function filter(wrapper, originalObject)
    -- skip invalid originalObject, even if wrapper.inverse is true
    if type(originalObject) ~= "table" then
        return true
    end

    -- skip(or not, see value of defaultSkip) originalObject by default
    local reflection = originalObject.reflection
    if reflection == nil then
        return defaultSkip
    end

    local except, skip, inverse, details = wrapper.except, false, wrapper.inverse or false
    if except == nil then
        skip = false
        goto rtn
    end

    details = except[reflection]
    if details == nil then
        skip = false
        goto rtn
    end
    -- skip whole originalObject
    if details == true then
        skip = true
        goto rtn
    end

    if type(details) == "table" then
        local newObject
        if not inverse then
            newObject = newTable(0, #details)
            for k, _ in pairs(details) do
                newObject[k] = originalObject[k]
            end
        else
            newObject = newTable(0, defaultTableLen)
            for k, v in pairs(originalObject) do
                if details[k] ~= true then
                    newObject[k] = v
                end
            end
        end

        return false, newObject
    end

    ::rtn::
    return (not inverse and skip) or (inverse and not skip)
end

return function(wrapper, originalObject, opt)
    local skip, newObject = filter(wrapper, originalObject)
    if skip == true then
        return originalObject
    end
    -- newObject return by filter include functions that escape from wrapping
    newObject = newObject or {}
    if wrapper:prepare(newObject, opt) == false then
        return originalObject
    end

    return setmetatable(newObject, { __index = function(self, index)
        local property = originalObject[index]
        if type(property) ~= "function" then
            return property
        end

        return function(...)
            return wrapper:leave(self, index, wrapper:entry(self, ...), property(...))
        end
    end})
end