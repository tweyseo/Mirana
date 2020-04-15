-- function reference
local ipairs = ipairs
local type = type
local tostring = tostring
local DEBUG, INFO, NOTICE, WARN, ERR = ngx.DEBUG, ngx.INFO, ngx.NOTICE, ngx.WARN, ngx.ERR
local setmetatable = setmetatable
-- include
local common = require("toolkit.common")
local conf = require("wrapper.conf").TRACER
local log = require("log.index")
local errlog = require("ngx.errlog")
local utils = require("toolkit.utils")

local Tracer = common.newTable(0, 9)

local function formatElement(element)
    local tp = type(element)
    if tp == "table" then
        return utils.json_encode(element) or "[type: table]"
    else
        return tostring(element) or "[type: "..tp.."]"
    end
end

local function dumpElements(elements)
    local count, str = #elements, ""
    for i, element in ipairs(elements) do
        str = str..formatElement(element)
        if i < count then
            str = str..", "
        end
    end

    return str
end

local function add(source, functionName, elapsedTime, params, results)
    if ngx.ctx.trace ==nil then
        ngx.ctx.trace = common.newTable(conf.queueCount, 0)
    end

    local content = ngx.ctx.trace

    -- process params dump
    local paramsStr = ""
    if conf.dumpParams == true then
        -- remove first param - self(caller) and last param - self(Chain, see router.lua)
        -- todo:make it configurable
        --remove(params, 1)
        --remove(params)

        paramsStr = dumpElements(params)
    end

    -- process results dump
    local resultsStr = ""
    if conf.dumpResults == true then
        resultsStr = dumpElements(results)
    end

    --[[
        after comparison, i found '..' performance better than table.concat when the string is not
        to long but to much operation of string concatenation, oppositely, table.concat performance
        better than '..' when the string is a little long but not too much operation of string
        concatenation.
        so i use '..' to concatenate string here and add them to the queue, because log queue count
        may be huge, and use table.concat concatenate them at log_by_lua stage later.
    ]]
    -- optimize: if the length of content is more than 10000, consider cache the length.
    content[#content + 1] = conf.prefix..source..":"..functionName.."("..(paramsStr or "")..")"
        .." -> ("..(resultsStr or "").."), elapsed:"..elapsedTime
end

-- except?, inverse?
function Tracer:new(level, except, inverse)
    local sysLevel = errlog.get_sys_filter_level()
    if not level or level > sysLevel then
        log.warn("invalid log level: ", level, ", but system log level: ", sysLevel)
        return
    end

    local instance = {}
    instance.except = except
    instance.inverse = inverse

    setmetatable(instance, {  __index = self  })

    return instance
end

function Tracer:prepare(obj, opt)
    local _, source = self, opt and opt.source
    if type(source) ~= "string" then
        log.warn("invalid source")
        return false
    end

    obj.source = source

    return true
end

function Tracer:entry(obj, ...)
    local _ = self
    return { common.curTime(), { ... } }
end

function Tracer:leave(obj, index, context, ...)
    local _ = self
    add(obj.source, index, common.elapsedTime(context[1]), context[2], { ... })

    return ...
end

Tracer.DEBUG = DEBUG
Tracer.INFO = INFO
Tracer.NOTICE = NOTICE
Tracer.WARN = WARN
Tracer.ERR = ERR

return setmetatable(Tracer, { __index = { wrap = require("wrapper.plugin.wrap") } })