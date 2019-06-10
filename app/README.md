# **app**

## **Overview**

Even though there were many wonderful web frameworks like [lor](https://github.com/sumory/lor) which was fast and minimalist based on [OpenResty](https://github.com/openresty/openresty), but i still plan to build a more minimalist web framework that refer to lor.

The biggest difference from lor is the [**static route**](https://github.com/tweyseo/Mirana/blob/master/app/route/matcher/plugin/hash.lua), it's generated at the time of adding handler for URI, and it followed the idea of the onion model, the middlewares were added in order from short path to long, and which was inverse for the errHandlers.

The second is the initialization, it was completed at the stage of `int_worker_by_lua` instead of triggering by first user request, which will get more accurate request latency.

In the end, this component was done with keeping LuaJIT's behavior in mind, and it's APIs were adapted with lor.

Here is an sample benchmark via [wrk2](https://github.com/giltene/wrk2) between this component and lor:
```
this component:
    50000
        QPS:
                49377.07
        Latency:
                50.00%  1.95ms
                75.00%  2.86ms
                90.00%  5.82ms
    100000
        QPS:
                98664.79
        Latency:
                50.00%  3.23ms
                75.00%  7.40ms
                90.00%  37.38ms
    150000
        QPS:
                147546.51
        Latency:
                50.00%  13.61ms
                75.00%  230.27ms
                90.00%  687.10ms
lor:
     50000
        QPS:
                49446.4
        Latency:
                50.00%  2.22ms
                75.00%  3.68ms
                90.00%  5.73ms
    100000
        QPS:
                98852.33
        Latency:
                50.00%  5.02ms
                75.00%  8.36ms
                90.00%  19.42ms
    150000
        QPS:
                145306.11
        Latency:
                50.00%  113.15ms
                75.00%  759.81ms
                90.00%  1.80s
```
As we can see, the higher the concurrency, the more advantage this component does.

## **Useage**
```
local App = require("app.index")

local app =  App:new()

-- add middleware
app:use(function(_, _, next) print("use-mw-root1") next() end)
app:use("/test1", function(_, _, next) print("use-mw-test1-1") next() end)

-- add error handler
app:errUse(function(err, _, _, next) print("use-eh-root1: ", err) next(err) end)
app:errUse("/test1", function(err, _, _, next)  print("use-eh-test1-1: ", err) next(err) end)

-- add URI handler
app:get("/test1/test2", function(_, resp) print("handle-test2") resp:send() end)

-- run
app:run(function(err)
        if err ~= nil then
            print("final error handler: "..err)
        end
    end)
```

But you are recommended to add URI handler via [autoRequire](https://github.com/tweyseo/Mirana/blob/master/toolkit/autoRequire.lua) and suitable [wrapper](https://github.com/tweyseo/Mirana/tree/master/wrapper), like in [APIServer](https://github.com/tweyseo/Shredder)

## **TODO**

1. add [r3](https://github.com/iresty/lua-resty-libr3) for dynamic route.