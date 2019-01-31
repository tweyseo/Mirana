-- function reference
local select = select
local DEBUG, INFO, NOTICE, WARN, ERR = ngx.DEBUG, ngx.INFO, ngx.NOTICE, ngx.WARN, ngx.ERR
local setmetatable = setmetatable
-- include
local common = require("toolkit.common")
local conf = require("wrapper.conf").TRACER
local log = require("log.index")
local errlog = require("ngx.errlog")

local Tracer = common.newTable(0, 9)

local function add(source, functionName, elapsedTime)
    if not ngx.ctx.trace then
        ngx.ctx.trace = common.newTable(conf.queueCount, 0)
    end

    local content = ngx.ctx.trace
    --[[
        after comparison, i found '..' performance better than table.concat when
        the string is not to long but to much operation of string concatenation,
        oppositely, table.concat performance better than '..' when the string is
        a little long but not too much operation of string concatenation.
        so i use '..' to concatenate string here and add them to the queue, because
        trace queue count may be huge, and use table.concat concatenate them at
        log_by_lua stage later.
    ]]
    content[#content + 1] = conf.prefix..source..":"..functionName.."(), elapsed:"..elapsedTime
end

function Tracer:new(level)
    local sysLevel = errlog.get_sys_filter_level()
    if not level or level > sysLevel then
        log.warn("invalid log level: ", level, ", but system log level: ", sysLevel)
        return
    end

    local instance = {}

    setmetatable(instance, {  __index = self  })

    return instance
end

function Tracer.prepare(obj, ...)
    if obj.source ~= nil then
        return
    end

    local ext
    for i = 1, select('#', ...) do
        ext = select(i, ...)
        if ext.source then
            obj.source = ext.source
            return
        end
    end
end

function Tracer:entry()
    self.startTime = common.curTime()
end

function Tracer:leave(obj, index)
    if not self.startTime then
        log.warn("startTime is nil")
    end

    add(obj.source, index, common.elapsedTime(self.startTime))
    self.startTime = nil
end

Tracer.DEBUG = DEBUG
Tracer.INFO = INFO
Tracer.NOTICE = NOTICE
Tracer.WARN = WARN
Tracer.ERR = ERR

return setmetatable(Tracer, { __index = { wrap = require("wrapper.plugin.wrap") } })