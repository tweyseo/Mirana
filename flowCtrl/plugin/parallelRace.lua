-- function reference
local select = select
local unpack = unpack
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
-- include
local log = require("log.index")
local newTable = require("toolkit.common").newTable

-- taskGroup { handler, { param1, param2, ... } }, ...
return function()
    return function(...)
        local count = select('#', ...)
        local threads, i = newTable(count, 0), 1
        local task, params, thread, err, ok, resp
        for idx = 1, count do
            task = select(idx, ...)
            params = task[2]
            thread, err = spawn(task[1], unpack(params or {}))
            if not thread then
                log.warn("spawn thread failed, err: ", err)
            else
                threads[i] = thread
                i = i + 1
            end
        end

        ok, resp = wait(unpack(threads))
        if not ok then
            return nil, "wait thread failed, err: "..resp
        end

        return  resp
    end
end