-- function reference
-- include
local tracer = require("wrapper.plugin.tracer")
local checker = require("wrapper.plugin.checker")

--[[
    wrapper plugin interface：

    @Plugin:new(level:number, except:table, inverse:bool) --> :table

    @Plugin:prepare(obj:table, opt:table) --> :bool

    @Plugin:entry(obj:table?, index:string?) --> context:table

    @Plugin:leave(obj:table, index:string, context:table, ...) --> ...
]]

return {
    TRACER = tracer,
    CHECKER = checker
}
