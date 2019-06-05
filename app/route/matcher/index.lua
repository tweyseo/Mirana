-- function reference
-- include
local routerConf = require("app.conf").router
local hash = require("app.route.matcher.plugin.hash")
local trie = require("app.route.matcher.plugin.trie")
local common = require("toolkit.common")

local pluginMap = {
    [routerConf.mode.hash] = hash,
    [routerConf.mode.trie] = trie
}

local Matcher = common.newTable(0, 1)  -- interface

function Matcher.new(mode)
    return pluginMap[mode or routerConf.mode.hash]:new()
end

--[[
    Plugin interface：

    @Plugin:addMiddlewares(path:string, func:function)

    @Plugin:addErrHandlers(path:string, func:function)

    @Plugin:addHandler(method:string, path:string, func:function)

    @Plugin:dumpCache() --> { key:string, count:number }:table

    @Plugin:rootErrHandlers() --> { errHandler1:function, errHandler2:function, ... }:table

    @Plugin:capture(path, method) --> {
        "handlers" = { handler1:function, handler2:function, ... }:table
        , "errHandlers" = { errHandler1:function, errHandler2:function, ... }:table
]]

return Matcher
