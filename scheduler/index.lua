-- function reference
local pairs = pairs
local type = type
local setmetatable = setmetatable
-- include
local newTable = require("toolkit.common").newTable
local AutoRequire = require("toolkit.autoRequire")
local bit = require("bit")
-- const
local regex = [[(?<path>\/\w+\/\w+\/\w+\/(?<objectName>\w+))\.]]
local requirePath = "/app/share/scheduler/adapter"
local adapterIdx, pluginIdx = 1, 2

-- auto require
local requireTable = newTable(0, 16)
local regexInfo = { regex, "path", "objectName" }
local autoRequire = AutoRequire:new(regexInfo)
autoRequire(requirePath, requireTable)
-- manual require which not in adapter
requireTable.tcp = require("net.index").TCP_CLIENT_LITE
requireTable.redis = require("storage.index").REDIS_LITE
requireTable.rediscluster = require("storage.index").REDISCLUSTER_LITE
requireTable.keyspaceNotification = require("storage.index").KEYSPACENOTIFICATION

local scheduler = {
    -- net
    HTTP = 1,       -- client mode only
    CAPTURE = 2,
    CAPTURE_MULTI = 3,
    TCP = 4,        -- client mode only
    -- storage
    REDIS = 11,
    REDISCLUSTER = 12,
    KEYSPACENOTIFICATION = 13,

    plugin = {
        CODE_ESCAPE = 2^0,
        BREAKER = 2^1
    }
}

local adapters = {
    [scheduler.HTTP] = requireTable.http,
    [scheduler.CAPTURE] = requireTable.capture,
    [scheduler.CAPTURE_MULTI] = requireTable.captureMulti,
    [scheduler.TCP] = requireTable.tcp,
    [scheduler.REDIS] = requireTable.redis,
    [scheduler.REDISCLUSTER] = requireTable.rediscluster,
    [scheduler.KEYSPACENOTIFICATION] =  requireTable.keyspaceNotification
}

local plugins = {
    [scheduler.plugin.CODE_ESCAPE] = "implement it later",
    [scheduler.plugin.BREAKER] = "implement it later"
}

local function resolve(mode)
    local a, p = mode, nil
    if type(mode) == "table" then
        a = mode[adapterIdx]
        p = mode[pluginIdx]
    end

    return a, p
end

--[[
    mode should be scheduler.HTTP or { scheduler.HTTP }
        or { scheduler.HTTP, scheduler.plugin.BREAKER + scheduler.plugin.BREAKER + ... }
]]
local attr = { __call = function(_, mode, ...)
        local a, p = resolve(mode)

        local adp = adapters[a]
        if adp == nil then
            return nil, "invalid adapter mode"
        end

        if p ~= nil then
            local plg
            for _, v in pairs(scheduler.plugin) do
                if bit.band(p, v) ~= 0 then
                    plg = plugins[v]
                    if plg == nil then
                        return nil, "invalid plugin mode"
                    end
                    adp = plg:wrap(adp)
                end
            end
        end

        return adp(...)
    end }

setmetatable(scheduler, attr)

return scheduler