-- function reference
local capture = ngx.location.capture
-- include

--[[
    Note that subrequests issued by ngx.location.capture inherit all the request headers of the
    current request by default and that this may have unexpected side effects on the subrequests.
    You are always recommended to use scheduler.HTTP to instead of scheduler.CAPTURE.
]]

return function(uri, params)
    return capture(uri,  params)
end