-- function reference
local pairs = pairs
local DEBUG, INFO, NOTICE, WARN, ERR = ngx.DEBUG, ngx.INFO, ngx.NOTICE, ngx.WARN, ngx.ERR
local upper = string.upper
local getinfo = debug.getinfo
local log = ngx.log
local select = select
local concat = table.concat
-- include
local common = require("toolkit.common")
local conf = require("log.conf")
local state, errlog = pcall(require, "ngx.errlog")
if not state then
    errlog = { get_sys_filter_level = function() return WARN end }
end

local logger = common.newTable(0, 14)

for k, level in pairs({ debug = DEBUG, info = INFO, notice = NOTICE, warn = WARN, err = ERR }) do
    logger[upper(k)] = level
    logger[k] = function(...)
        if level > errlog.get_sys_filter_level() then
            return
        end

        local info = getinfo(2, "Sl")
        log(level, info.short_src, ":", info.currentline, " ", ...)
    end
end

function logger.add(level, ...)
    if level > errlog.get_sys_filter_level() then
        return
    end

    if not ngx.ctx.log then
        ngx.ctx.log = common.newTable(conf.queueCount, 0)
    end

    local content = ngx.ctx.log

    -- select is faster than temp table on ...
    local dst = select('#', ...) == 1 and select(1, ...) or concat({ ... })
    --[[
        after comparison, i found '..' performance better than table.concat when the string is not
        to long but to much operation of string concatenation, oppositely, table.concat performance
        better than '..' when the string is a little long but not too much operation of string
        concatenation.
        so i use '..' to concatenate string here and add them to the queue, because log queue count
        may be huge, and use table.concat concatenate them at log_by_lua stage later.
    ]]
    -- optimize: if the length of content is more than 10000, consider cache the length.
    content[#content + 1] = conf.prefix..dst..", time:"..common.curTime()
end

local function format(content)
    return content and (#content == 1 and content[1] or concat(content, "\n"))
end

function logger.fetchLog()
    return format(ngx.ctx.log)
end

function logger.fetchTrace()
    return format(ngx.ctx.trace)
end

function logger.overview(...)
    log(conf.overviewLevel, ...)
end

return logger