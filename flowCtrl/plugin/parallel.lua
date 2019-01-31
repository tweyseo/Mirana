-- function reference
local select = select
local ipairs = ipairs
local unpack = unpack
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
-- include
local newTable = require("toolkit.common").newTable

-- taskGroup { handler1, { param1, param2, ... }, ...
return function()
    return function(...)
        local count = select('#', ...)
        local threads, resps = newTable(count, 0), newTable(count, 0)
        local task, params, thread, err, ok, resp
        for i = 1, count do
            task = select(i, ...)
            params = task[2]
            thread, err = spawn(task[1], unpack(params or {}))
            if not thread then
                threads[i] = { nil, "spawn thread failed, err: "..err }
            else
                threads[i] = { thread }
            end
        end

        for i, t in ipairs(threads) do
            thread = t[1]
            if not thread then
                resps[i] = { nil, t[2] }
                goto loopEnd
            end

            ok, resp = wait(thread)
            if not ok then
                resps[i] = { nil, "wait thread failed, err: "..resp }
            else
                resps[i] = { resp }
            end

            ::loopEnd::
        end

        return resps
    end
end