-- function reference
-- include
local newTable = require("toolkit.common").newTable
local utils = require("toolkit.utils")

local helper = newTable(0, 2)

helper.jsonSerialize = function(lData, pattern)
    return pattern and (utils.json_encode(lData)..pattern) or utils.json_encode(lData)
end

helper.jsonDerialize = function(jData)
    return utils.json_decode(jData)
end

return helper