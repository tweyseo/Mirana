-- function reference
-- include
local defaultLogger = require("log.plugin.default")

local index  = {
    DEFAULT = defaultLogger
}

--[[
    logger interface：

    @logger.debug(...)

    @logger.info(...)

    @logger.notice(...)

    @logger.warn(...)

    @logger.err(...)

    @logger.add(level, ...)

    @logger.fetchLog() --> log:string

    @logger.fetchTrace() --> trace:string

    @logger.overview(...)
]]

return index.DEFAULT

