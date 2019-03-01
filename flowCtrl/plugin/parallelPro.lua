-- function reference
local select = select
local ipairs = ipairs
local unpack = unpack
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
-- include
local log = require("log.index")
local newTable = require("toolkit.common").newTable

-- taskGroup { h1, { param1, param2, ... }, ignore(true/false), cb1 }, ...
-- note, empty params use {}, not nil
--[[
    optional ignore means you don't care about the task result,  but you can use optional cb handle
    this task result.
]]
return function()
    return function(...)
        local count = select('#', ...)
        local threads, i = newTable(count, 0), 1
        local task, params, ignore, cb, thread, err, content, ok, resp
        for idx = 1, count do
            task = select(idx, ...)
            params, ignore, cb = task[2], task[3], task[4]
            if ignore and cb then
                local handler = task[1]
                task[1] = function(...)
                    cb(handler(...))
                end
            end
            thread, err = spawn(task[1], unpack(params))
            if not thread then
                content = "spawn thread failed, err: "..err
                if ignore then
                    log.warn(content)
                else
                    thread[i] = { false, content }
                    i = i + 1
                end
            else
                if not ignore then
                    threads[i] = { thread }
                    i = i + 1
                end
            end
        end

        local resps = newTable(#threads, 0)
        for j, t in ipairs(threads) do
            thread = t[1]
            if not thread then
                resps[j] = { false, t[2] }
                goto loopEnd
            end

            ok, resp = wait(thread)
            if not ok then
                resps[j] = { false, "wait thread failed, err: "..resp }
            else
                resps[j] = { resp }
            end

            ::loopEnd::
        end

        return resps
    end
end