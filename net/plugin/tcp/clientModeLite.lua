-- function reference
--to use settimeouts
--local connect = ngx.socket.connect
local tcpClient = ngx.socket.tcp
-- include
local log = require("log.index")
local defaultConf = require("net.conf")
local helper = require("net.plugin.helper")
local mergeConf = require("toolkit.utils").mergeConf

return function()
    -- conf see net.conf.TCP_CLIENT
    -- req(recommended to a table)
    return function(conf, req)
        -- create
        local sck = tcpClient()
        conf = mergeConf(conf, defaultConf.TCP_CLIENT)
        sck:settimeouts(conf.connectTimeout, conf.sendTimeout, conf.readTimeout)
        local ok, err
        -- connect
        ok, err = sck:connect(conf.addr, conf.port)
        if not ok then
            return nil, err
        end
        -- serialize
        local pattern = conf.pattern
        local sendData = helper.jsonSerialize(req, pattern)
        if not sendData then
            ok, err = sck:close()
            if not ok then
                log.warn("close socket error: ", err)
            end

            return nil, "serialize failed"
        end
        -- send
        local bytes
        bytes, err = sck:send(sendData)
        if not bytes or bytes ~= #sendData then
            return nil, err
        end
        -- receive
        local recv
        recv, err = sck:receiveuntil(pattern)
        if not recv then
            return nil, err
        end
        local errTimeout, recvData = defaultConf.PUBLIC.ERROR.Timeout
        recvData, err = recv()
        if not recvData then
            --[[
                Fatal errors in cosocket operations always automatically close the current
                connection (note that, read timeout error is the only error that is not fatal),
                and if you call close on a closed connection, you will get the "closed" error.
            ]]
            if err == errTimeout then
                ok, err = sck:close()
                if not ok then
                    log.warn("close socket error: ", err)
                end

                err = errTimeout
            end

            return nil, err
        end
        -- derialize
        local resp = helper.jsonDerialize(recvData)
        if not resp then
            ok, err = sck:close()
            if not ok then
                log.warn("close socket error: ", err)
            end

            return nil, "derialize failed"
        end
        -- keep alive
        ok, err = sck:setkeepalive()
        if not ok then
            log.warn("keep alive failed: ", err)
        end

        return resp
    end
end