-- function reference
local exiting = ngx.worker.exiting
-- include
local Redis = require("resty.redis")
local defaultConf = require("storage.conf").KEYSPACENOTIFICATION
local errTimeout = require("storage.conf").PUBLIC.ERROR.Timeout
local mergeConf = require("toolkit.utils").mergeConf
local log = require("log.index")

local function close(rc)
    local ok, err = rc:close()
    if not ok then
        -- just log warn
        log.warn("close redis error: ", err)
    end
end

--[[
    set notify-keyspace-events to "Esx" to set key event + set + expired
    or
    set notify-keyspace-events to "Ex" to set key event + expired
]]
return function()
    -- conf see storage.conf.KEYSPACENOTIFICATION
    -- handler return true or false to continue recv loop or not
    -- errHandler was to handle(e.g. to reconnect) the unrecoverable error
    return function(conf, pattern, handler, errHandler)
        -- init
        conf = mergeConf(conf, defaultConf)
        local rc, err, ok
        rc, err = Redis:new()
        if not rc then
            return errHandler("create redis client failed, error: "..err)
        end
        rc:set_timeout(conf.timeout)

        -- connect
        ok, err = rc:connect(conf.addr, conf.port)
        if not ok then
            return errHandler("connect redis server failed, error: "..err)
        end

        log.warn("connect redis server successfully")

        -- auth
        local auth = conf.auth
        if auth and auth ~= "" then
            local count
            count, err = rc:get_reused_times()
            if count == 0 then
                ok, err = rc:auth(auth)
            elseif err then
                ok = false
            else
                ok = true
            end
            if not ok then
                close(rc)
                return errHandler("redis auth failed, error: "..err)
            end
        end

        -- psubscribe
        --[[
            Although subscribe has better performance than psubscribe, but psubscribe support
            wildcard.
        ]]
        pattern = pattern or conf.pattern
        ok, err = rc:psubscribe(pattern)
        if not ok then
            close(rc)
            return errHandler("redis psubscribe failed, error: "..err)
        end

        log.warn("redis psubscribe successfully and start to read reply")
        -- recv loop
        rc:set_timeout(conf.readInterval)
        local recvData
        repeat
            ::rcvLoop::
            if exiting() == true then
                -- auto gc
                return true
            end
            recvData, err = rc:read_reply()
            if recvData == nil then
                if err == errTimeout then
                    goto rcvLoop
                else
                    close(rc)
                    return errHandler("read ["..pattern.."] reply failed, error: "..err)
                end
            else
                if handler(recvData) == false then
                    close(rc)
                    return errHandler("data error was unrecoverable")
                end
            end
        until(false)
    end
end