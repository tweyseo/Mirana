-- function reference
local pcall = pcall
local error = error
local type = type
local pairs = pairs
local ipairs = ipairs
local concat = table.concat
local tostring = tostring
local setmetatable = setmetatable
local getmetatable = getmetatable
-- include
local log = require("log.index")
local json = require("cjson")
local ok, jd = pcall(require, "json_decoder")
local decode
if ok then
    decode = function(json_value)
        local jd_ins = jd.new()
        local lua_value, err = jd_ins:decode(json_value)
        if not lua_value then
            error(err)
        end

        return lua_value
    end
else
    decode = function(json_value)
        return json.decode(json_value)
    end
end
local newTable = require("toolkit.common").newTable

-- wrappers for third party libraries

local utils = newTable(0, 8)

function utils.json_encode(lua_value, empty_table_as_object)
    local json_value
    if json.encode_empty_table_as_object then
        -- empty table encoded as array default
        json.encode_empty_table_as_object(empty_table_as_object or true)
    end
    -- prevent from excessively sparse array
    json.encode_sparse_array(true)
    pcall(function(v) json_value = json.encode(v) end, lua_value)
    return json_value
end

function utils.json_decode(json_value)
    local lua_value
    pcall(function(v) lua_value = decode(v) end, json_value)
    return lua_value
end

function utils.print_array(arr)
    if type(arr) ~= "table" then
        log.err("not an array")
        return
    end

    log.err(tostring(arr) and tostring(arr)..": " or "array: ", concat(arr, ", ")
        , " [len = ", #arr, "]")
end

function utils.print_table(t, content, layer)
    if type(t) ~= "table" then
        log.err("not an table")
        return
    end

    if not content then content = (tostring(t) and tostring(t)..": " or "table: ") end
    if not layer then layer = 1 else layer = layer + 1 end

    content = content.."{ "

    local begin, tp = true
    for k, v in pairs(t) do
        tp = type(v)
        local comma = ", "
        if begin then
            begin = false
            comma = ""
        end
        if tp == "table" then
            content = content..comma..k..": "
            content = utils.print_table(v, content, layer)
        else
            content = content..comma..k..": "..tostring(v)
        end
    end

    content = content.." }"

    if layer == 1 then
        log.err(content)
    else
        return content
    end
end

function utils.deepCopy(src)
    local dst
    if type(src) == "table" then
        dst = {}
        for k, v in pairs(src) do
            dst[k] = v
        end
        setmetatable(dst, utils.deepCopy(getmetatable(src)))
    else
        dst = src
    end

    return dst
end

-- fast way to deep copy array table
function utils.deepCopyArray(src)
    local dst
    if type(src) == "table" then
        dst = newTable(#src, 0)
        for i, v in ipairs(src) do
            dst[i] = v
        end
    else
        dst = src
    end

    return dst
end

function utils.mergeConf(customConf, defaultConf)
    if not customConf then return defaultConf end

    for k, v in pairs(defaultConf) do
        if customConf[k] == nil then
            customConf[k] = v
        end
    end

    return customConf
end

return utils