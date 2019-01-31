-- function reference
local match = ngx.re.match
local tonumber = tonumber
-- include
local httpClient = require("net.index").HTTP_CLIENT_LITE
local conf = require("scheduler.conf").NET.HTTP

local function parseUri(uri)
    local ret, err = match(uri, conf.defaultURLRegex, "jo")
    if not ret then
        return nil, err and ("match uri: "..uri..", err: "..err) or ("bad uri: "..uri)
    end

    return ret[1], tonumber(ret[2] or 80), ret[3] or "/", ret[4]
end

-- uri(string, like:http://192.25.106.105:29527/ping)
-- params.method(opt)
-- params.path(opt)
-- params.query(opt and can be a table)
-- params.headers(opt)
-- params.body(opt and recommended to a table)
return function(uri, params)
    local host, port, path, query = parseUri(uri)
    if not host then
        -- if host is nil, port will capture err
        return nil, port
    end

    params = params or {}
    if not params.path then params.path = path end
    if not params.query then params.query = query end

    return httpClient({ addr = host, port = port }, params)
end