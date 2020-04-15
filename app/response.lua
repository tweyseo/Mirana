-- function reference
local setmetatable = setmetatable
local print = ngx.print
local flush = ngx.flush
-- include
local add_header = require("ngx.resp").add_header
local utils = require("toolkit.utils")
local common = require("toolkit.common")

local Response = common.newTable(0, 6)

function Response:new()
    local instance = {
        _status = 200,
        _chunk = false
    }

    setmetatable(instance, { __index = self })

    return instance
end

-- append
function Response:addHeader(key, value)
    local  _ = self
    add_header(key, value)
end

function Response:setStatus(code)
    self._status = code
    return self
end

function Response:setChunk(flag)
    self._chunk = flag
    return self
end

function Response:send(content, f)
    ngx.status = self._status
    if self._chunk ~= true then
        self:addHeader('Content-Length', content and #content or 0)
    end
    print(content)
    if f == true then
        flush()
        return ngx.status, ngx.resp.get_headers(), content, "flush"
    end

    -- for wrapper-tracer dump results
    return ngx.status, ngx.resp.get_headers(), content
end

function Response:json(data, f)
    self:addHeader('Content-Type', 'application/json')
    return self:send(utils.json_encode(data), f)
end

return Response
