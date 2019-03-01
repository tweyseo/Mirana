-- function reference
local pcall = pcall
local type = type
-- include

local ok, newTab = pcall(require, "table.new")
if not ok or type(newTab) ~= "function" then
    newTab = function() return {} end
end

local common = newTab(0, 7)

function common.newTable(narr, nrec)
    return newTab(narr, nrec)
end

function common.uuid()
    -- can not cache in lua var
    return ngx.var.request_id
end

--[[
    ngx.var.request_id offered different unique id at every access, even if in the same request, so
    set ngx.var.request_id to ngx.ctx.reqId at access_by_lua stage only, and use ngx.ctx.reqId as
    current request id, ngx.var.request_id as uuid generator.
]]
function common.reqId()
    -- can not cache in lua var
    return ngx.ctx.reqId
end

common.curTime = ngx.now

function common.reqTime()
    -- can not cache in lua var
    return ngx.var.request_time
end

function common.elapsedTime(t)
    return common.curTime() - (t or 0)
end

function common.status()
    -- can not cache in lua var
    return ngx.var.status
end

--[[
    ngx.var.content_type will be read repeatedly like in scheduler-capture, so cache it in
    ngx.ctx.contentType at the stage of access_by_lua for better performance.
]]
function common.contentType()
    return ngx.ctx.contentType
end

return common