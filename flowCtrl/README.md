# **flowCtrl**

## **Overview**

Cosoket like in [OpenResty](https://github.com/openresty/openresty) was amazing, but for higher porformance we need to parallelize unrelated operations sometimes, fortunately, we can do this with **light thread** provide by `ngx.thread`. this component was fit well for APIServer to dispatch the requests from client to backend.

Note that the function wrapped by this component can only return **one argument** - this behavior was limited by [`ngx.thread.wait`](https://github.com/openresty/lua-nginx-module/blob/master/README.markdown#ngxthreadwait).

## **Useage**

```
local index = require("flowCtrl.index")
local log = require("log.index")

local requestToServer1(id, name)
-- do something
end

local requestToServer2(type)
-- do something
end

local params = {
    { requestToServer1, { 13, "tweyseo" } },
    { requestToServer2, { 7 } }
}
local resps, result, err

-- parallel
local parallel = index.PARALLEL
resps = parallel(params)
for i, resp in ipiars(resps) do
    result, err = unpack(resp)
    if not result then
        log.warn("bad resp[", i, "], err: ", err)
    else
        log.info("resp[", i, "]: ", result)
    end
end

-- parallelRace
local parallelRace = index.PARALLEL_RACE
result, err = unpack(parallelRace(params))
if not result then
    log.warn("bad resp, err: ", err)
else
    log.info("the fast resp: ", result)
end

-- parallelPro
local parallelPro = index.PARALLEL_PRO
local pingDB(time)
    -- do something
    return pongTime
end

local echoToServer3()
    -- do something
end

params[3] = { pingDB, 1547914820, true, function(time) log.info("pong time: ", time) end }
params[4] = { echoToServer3, nil, true  }
resps = parallelPro(params)
for i, resp in ipiars(resps) do
    result, err = unpack(resp)
    if not result then
        log.warn("bad resp[", i, "], err: ", err)
    else
        log.info("resp[", i, "]: ", result)
    end
end

```

## **TODO**