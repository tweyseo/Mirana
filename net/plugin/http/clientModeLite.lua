-- function reference
local type = type
local concat = table.concat
local find = string.find
-- include
local defaultConf = require("net.conf").HTTP_CLIENT
local mergeConf = require("toolkit.utils").mergeConf
local newTable = require("toolkit.common").newTable
local Http = require("resty.http")
local helper = require("net.plugin.helper")
local log = require("log.index")

local reqHandle = function(req, conf)
    if not req.body then return req end

    if not req.headers then
        req.headers = newTable(0, 1)
    end
    local headers = req.headers
    if headers["Content-Type"] == nil then
        headers["Content-Type"] = conf.defaultContentType
    end
    if  find(headers["Content-Type"], conf.defaultContentType, 1, true) then
        req.body = helper.jsonSerialize(req.body)
    end

    -- "Content-Length" will be calculated before send the request out in resty-http's send_request.
    return req
end

local respHandle = function(resp, conf)
    local rawBody
    if resp.body then
        rawBody = resp.body
        local contentType = resp.headers and resp.headers["Content-Type"]
        -- for multiple instances of request headers, the value of key will be a Lua (array) table
        if type(contentType) == "table" then contentType = concat(contentType, "; ") end
        if contentType and find(contentType, conf.defaultContentType, 1, true) then
            resp.body = helper.jsonDerialize(resp.body)
        end
    end

    return { status = resp.status, headers = resp.headers, body = resp.body, rawBody = rawBody }
end

--[[
    you are recommended to use body replace query. body will be serialized in json as default
    and set "Content-Type" to "application/json", if "Content-Type" not be set yet. for response,
    if set "Content-Type" to "application/json", body will be derialize in lua table. in general,
    it's recommended that treat request body and response body as lua table.
]]

return function()
    -- conf see net.conf.HTTP_CLIENT
    -- req.method(opt)
    -- req.path(opt)
    -- req.query(opt and can be a table)
    -- req.headers(opt)
    -- req.body(opt and recommended to a table)
    -- todo: support ssl
    return function(conf, req)
        -- create
        local httpClient, err
        httpClient, err = Http.new()
        if not httpClient then
            return nil, err
        end
        conf = mergeConf(conf, defaultConf)
        httpClient:set_timeouts(conf.connectTimeout, conf.sendTimeout, conf.readTimeout)
        -- connect
        local ok
        ok, err = httpClient:connect(conf.addr, conf.port)
        if not ok then
            return nil, err
        end
        -- send
        local resp
        resp, err = httpClient:request(reqHandle(req, conf))
        if not resp then
            -- recv status and headers in httpClient:request
            --[[
                Fatal errors in cosocket operations always automatically close the current
                connection (note that, read timeout error is the only error that is not fatal), and
                if you call close on a closed connection, you will get the "closed" error.
            ]]
            if err == "timeout" then
                ok, err = httpClient:close()
                if not ok then
                    log.warn("close socket error: ", err)
                end

                err = "timeout"
            end

            return nil, err
        end
        -- recv body
        local body
        body, err = resp:read_body()
        if not body then
            --[[
                Fatal errors in cosocket operations always automatically close the current
                connection (note that, read timeout error is the only error that is not fatal), and
                if you call close on a closed connection, you will get the "closed" error.
            ]]
            if err == "timeout" then
                ok, err = httpClient:close()
                if not ok then
                    log.warn("close socket error: ", err)
                end

                err = "timeout"
            end

            return nil, err
        end
        resp.body = body
        -- keep alive
        ok, err = httpClient:set_keepalive(conf.maxIdleTimeout, conf.poolSize)
        if not ok then
            log.warn("keep alive failed: ", err)
        end

        return respHandle(resp, conf)
    end
end