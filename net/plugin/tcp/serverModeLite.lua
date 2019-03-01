-- function reference
local tcpServer = ngx.req.socket
-- include
local defaultConf = require("net.conf").TCP_SERVER
local helper = require("net.plugin.helper")
local mergeConf = require("toolkit.utils").mergeConf
local log = require("log.index")

return function()
    -- conf see net.conf.TCP_SERVER
    --[[
        router(req) return resp to send if needed and true or false to continue recv loop or not.
        errHandler(req, err) return true to continue recv loop or false to stop recv loop when the
        error is recoverable for socket.
    ]]
    return function(conf, router, errHandler)
        -- create
        local sck, err
        sck, err = tcpServer(true)
        if not sck then
            -- unrecoverable
            errHandler(nil, err)
            return
        end
        conf = mergeConf(conf, defaultConf)
        sck:settimeouts(conf.connectTimeout, conf.sendTimeout, conf.readTimeout)
        -- receive
        local pattern = conf.pattern
        local recv
        recv, err = sck:receiveuntil(pattern)
        if not recv then
            -- unrecoverable
            errHandler(nil, err)
            return
        end

        local recvData, req, resp, sendData, bytes, ok, continue
        repeat
            ::rcvLoop::
            recvData, err = recv()
            if not recvData then
                --[[
                    Fatal errors in cosocket operations always automatically close the current
                    connection (note that, read timeout error is the only error that is not fatal),
                    and if you call close on a closed connection, you will get the "closed" error.
                ]]
                if err == "timeout" then
                    -- recoverable
                    if errHandler(nil, err) == true then
                        goto rcvLoop
                    end

                    ok, err = sck:close()
                    if not ok then
                        log.warn("close socket error: ", err)
                    end

                    return
                else
                    -- unrecoverable
                    errHandler(nil, err)
                    return
                end
            end
            -- derialize
            req = helper.jsonDerialize(recvData)
            if not req then
                -- recoverable
                -- note the recvData is raw data
                if errHandler(recvData, "derialize failed") == true then
                    goto rcvLoop
                end

                ok, err = sck:close()
                if not ok then
                    log.warn("close socket error: ", err)
                end

                return
            end
            resp, continue = router(req)
            if resp then
                -- serialize
                sendData = helper.jsonSerialize(resp, pattern)
                if not sendData then
                    -- recoverable
                    if errHandler(req, "serialize failed") == true then
                        goto rcvLoop
                    end

                    ok, err = sck:close()
                    if not ok then
                        log.warn("close socket error: ", err)
                    end

                    return
                end
                -- send
                bytes, err = sck:send(sendData)
                if not bytes or bytes ~= #sendData then
                    -- unrecoverable
                    errHandler(req, err)
                    return
                end
            end

            if not continue then
                ok, err = sck:close()
                if not ok then
                    log.warn("close socket error: ", err)
                end

                return
            end
        until(false)
    end
end
