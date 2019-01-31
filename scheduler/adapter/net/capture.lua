-- function reference
local capture = ngx.location.capture
local getHeaders = ngx.req.get_headers
local clearHeader = ngx.req.clear_header
local setHeader = ngx.req.set_header
local find = string.find
local pairs = pairs
local type = type
local concat = table.concat
-- include
local utils = require("toolkit.utils")
local conf = require("scheduler.conf").NET.HTTP

--[[
    Note that subrequests issued by ngx.location.capture inherit all the request  headers of the
    current request by default and that this may have unexpected side effects on the subrequest
    responses. so clear all headers before send subrequest, and restore them after got reponse of
    the subrequest.
]]
local function changeHeaders(headers)
    local temp = getHeaders(nil, true)
    local oldHeaders = {}
    -- clear old
    for k, v in pairs(temp) do
        oldHeaders[k] = v
        clearHeader(k)
    end
    -- set new
    if type(headers) == "table" then
        for k, v in pairs(headers) do
            setHeader(k, v)
        end
    end

    return oldHeaders
end

local function reqHandle(params)
    local oldHeaders = changeHeaders(params and params.headers)
    if params and params.body then
        local contentType = params.headers and params.headers["Content-Type"]
        if contentType == nil then
            setHeader("Content-Type", conf.defaultContentType)
        end
        if find(ngx.var.content_type, conf.defaultContentType, 1, true) then
            params.body = utils.json_encode(params.body)
        end
        --Content-Length will automatic calculate later
    end

    return oldHeaders, params
end

local function respHandle(oldHeaders, resp)
    if resp.body then
        local contentType = resp.header and resp.header["Content-Type"]
        -- for multiple instances of request headers, the value of key will be a Lua (array) table
        if type(contentType) == "table" then contentType = concat(contentType, "; ") end
        if contentType and find(contentType, conf.defaultContentType, 1, true) then
            resp.body = utils.json_decode(resp.body)
        end
    end

    changeHeaders(oldHeaders)

    return resp
end

-- params.headers(opt and as new headers)
-- params.method(opt and constants like ngx.HTTP_POST)
-- params.body(opt and recommended to a table)
-- params.query(opt and can be a table)
return function(uri, params)
    local oldHeaders, req = reqHandle(params)
    return respHandle(oldHeaders, capture(uri, req))
end