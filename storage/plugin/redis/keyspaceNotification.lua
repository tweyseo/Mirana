-- function reference
local exiting = ngx.worker.exiting
-- include
local Redis = require("resty.redis")
local defaultConf = require("storage.conf").KEYSPACENOTIFICATION
local errTimeout = require("storage.conf").PUBLIC.ERROR.Timeout
local mergeConf = require("toolkit.utils").mergeConf
local log = require("log.index")

-- set notify-keyspace-events to "Esx" to set key event + set + expired
return function()
    -- conf see storage.conf.KEYSPACENOTIFICATION
    --[[
        handler(recvData)  and errHandler(pattern, err) are both return true or false to continue
        recv loop or not.
    ]]
    return function(conf, pattern, handler, errHandler)
        -- init
        conf = mergeConf(conf, defaultConf)
        local rc, err, ok
        rc, err = Redis:new()
        if not rc then
            return nil, err
        end
        rc:set_timeout(conf.timeout)

        -- connect
        ok, err = rc:connect(conf.addr, conf.port)
        if not ok then
            return nil, err
        end

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
                return nil, err
            end
        end

        -- psubscribe
        rc:psubscribe(pattern or conf.pattern)

        -- read
        rc:set_timeout(conf.readInterval)
        local recvData
        repeat
            ::rcvLoop::
            if exiting() == true then
                return
            end
            recvData, err = rc:read_reply()
            if not recvData then
                if err == errTimeout then
                    goto rcvLoop
                else
                    errHandler = errHandler or function(key, error)
                            log.warn("read "..key.." reply error: ", error)
                            return false
                        end
                    -- recoverable
                    if errHandler(pattern, err) == true then
                        goto rcvLoop
                    end

                    ok, err = rc:close()
                    if not ok then
                        log.warn("close redis error: ", err)
                    end

                    return
                end
            else
                if handler(recvData) == false then
                    ok, err = rc:close()
                    if not ok then
                        log.warn("close redis error: ", err)
                    end

                    return
                end
            end
        until(false)
    end
end