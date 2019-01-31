-- function reference
local captureMulti = ngx.location.capture_multi
-- include

--[[
    Note that subrequests issued by ngx.location.capture inherit all the
    request headers of the current request by default and that this may
    have unexpected side effects on the subrequest responses.
    For ngx.location.capture_multi, you can only modify the ngx conf to
    set different headers for each subrequest unless they use the same
    headers setting as the current request.
    You are always recommended to use scheduler.HTTP + flowCtrl.parallel
    instead of scheduler.CAPTURE_MULTI
]]

return function(requests)
    return captureMulti(requests)
end