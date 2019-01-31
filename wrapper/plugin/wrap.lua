-- function reference
local setmetatable = setmetatable
local rawget = rawget
local unpack = unpack
-- include

return function(wrapper, originalObject, ...)
    wrapper.prepare(originalObject, ...)
    return setmetatable({ }, { __index = function(_, index)
        return function(...)
            wrapper:entry(originalObject, index, ...)
            local rets = { rawget(originalObject, index)(...) }
            wrapper:leave(originalObject, index, ...)
            return unpack(rets)
        end
    end})
end