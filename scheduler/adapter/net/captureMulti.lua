-- function reference
local captureMulti = ngx.location.capture_multi
-- include

--[[
    Note that subrequests issued by ngx.location.capture_multi inherit all the request headers of
    the current request by default and that this may have unexpected side effects on the
    subrequests.
    You are always recommended to use scheduler.HTTP + flowCtrl.parallel to  instead of
    scheduler.CAPTURE_MULTI.
]]

return function(requests)
    return captureMulti(requests)
end