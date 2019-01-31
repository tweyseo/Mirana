-- function reference
local pcall = pcall
local type = type
-- include

local ok, newTab = pcall(require, "table.new")
if not ok or type(newTab) ~= "function" then
    newTab = function() return {} end
end

local common = newTab(0, 6)

function common.newTable(narr, nrec)
    return newTab(narr, nrec)
end

function common.reqId()
    -- can not cache in lua var
    return ngx.var.request_id
end

common.curTime = ngx.now

function common.reqTime()
    -- can not cache in lua var
    return ngx.var.request_time
end

function  common.elapsedTime(t)
    return common.curTime() - t
end

function common.status()
    -- can not cache in lua var
    return ngx.var.status
end

return common