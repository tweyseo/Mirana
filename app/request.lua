-- function reference
local get_headers = ngx.req.get_headers
local read_body = ngx.req.read_body
local type = type
local concat = table.concat
local find = string.find
local get_post_args = ngx.req.get_post_args
local get_body_data = ngx.req.get_body_data
local setmetatable = setmetatable
local get_method = ngx.req.get_method
local get_uri_args = ngx.req.get_uri_args
-- include
local reqConf = require("app.conf").request
local utils = require("toolkit.utils")
local common = require("toolkit.common")

local Request = common.newTable(0, 3)

function Request:new()
    local headers = get_headers(reqConf.maxHeaders)
    read_body()
    local body, rawBody = {}, ""
    --[[
        you are recommended to cache ngx.var.content_type in ngx.ctx['Content-Type'] before the
        stage of content_by_lua*, because the ngx.var.HEADER API call, which uses core $http_HEADER
        variables, may be more preferable for reading individual request headers, and cache common
        $http_HEADER in ngx.ctx.* will performance better.
    ]]
    local ct = ngx.ctx['Content-Type'] or headers['Content-Type']
    if type(ct) == "table" then ct = concat(ct, "; ") end
    if ct then
        if find(ct, reqConf.contentType[1], 1, true) then
            body = get_post_args()
        elseif find(ct, reqConf.contentType[2], 1, true) then
            rawBody = get_body_data()
            body = utils.json_decode(rawBody)
        end
    else
        -- header without Content-Type will be treated as x-www-form-urlencoded by default.
        body = get_post_args()
    end

    local instance = {
        uri = ngx.var.request_uri, -- full uri

        path = ngx.var.uri, -- path in uri
        method = get_method(),
        query = get_uri_args(), -- on x-www-form-urlencoded mode, and it's a table

        headers = headers,
        body = body,
        rawBody = rawBody, -- raw body of post on application/json

        found = false
    }

    setmetatable(instance, { __index = self })

    return instance
end

function Request:hasFound()
    return self.found
end

function Request:setFound(found)
    self.found = found
end

return Request