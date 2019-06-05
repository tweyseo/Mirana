-- function reference
local ipairs = ipairs
local type = type
local setmetatable = setmetatable
-- include
local newTable = require("toolkit.common").newTable
local AutoRequire = require("toolkit.autoRequire")
-- const
local regex = [[(?<path>\/\w+\/\w+\/\w+\/(?<objectName>\w+))\.]]
local requirePath = "/app/share/scheduler/adapter"

-- auto require
local requireTable = newTable(0, 16)
local regexInfo = { regex, "path", "objectName" }
local autoRequire = AutoRequire:new(regexInfo)
autoRequire(requirePath, requireTable)
-- manual require which not in adapter
requireTable.tcp = require("net.index").TCP_CLIENT_LITE
requireTable.redis = require("storage.index").REDIS_LITE
requireTable.rediscluste = require("storage.index").REDISCLUSTER_LITE

local scheduler = {
    -- net
    HTTP = 1,       -- client mode only
    CAPTURE = 2,
    CAPTURE_MULTI = 3,
    TCP = 4,        -- client mode only
    -- storage
    REDIS = 11,
    REDISCLUSTER = 12,

    plugin = {
        BREAKER = 2^0
    }
}

local adapters = {
    [scheduler.HTTP] = requireTable.http,
    [scheduler.CAPTURE] = requireTable.capture,
    [scheduler.CAPTURE_MULTI] = requireTable.captureMulti,
    [scheduler.TCP] = requireTable.tcp,
    [scheduler.REDIS] = requireTable.redis,
    [scheduler.REDISCLUSTER] = requireTable.rediscluster
}

local plugins = {
    [scheduler.plugin.BREAKER] = "implement it later",
}

local function resolve(mode)
    local m, p = mode, nil
    if type(mode) == "table" then
        m = mode[1]
        p = mode[2]
    end

    return m, p
end

--[[
    mode should be scheduler.HTTP or { scheduler.HTTP }
        or { scheduler.HTTP, { scheduler.plugin.BREAKER, ... } }
]]
local attr = { __call = function(_, mode, ...)
        local m, p = resolve(mode)

        local adp = adapters[m]
        if adp == nil then
            return nil, "invalid adapter mode"
        end

        if type(p) == "table" then
            local plg
            for _, index in ipairs(p) do
                plg = plugins[index]
                if plg == nil then
                    return nil, "invalid plugin mode"
                end
                adp = plg:wrap(adp)
            end
        end

        return adp(...)
    end }

setmetatable(scheduler, attr)

return scheduler