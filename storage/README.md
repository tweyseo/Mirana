# **storage**

## **Overview**

This component working on "one-time" communications including redis and rediscluster. "one-time" here means after one request and one response then will recycle the connection to the connection pool provide by [OpenResty](https://github.com/openresty/openresty).

For redis, i wrapped [lua-resty-redis](https://github.com/openresty/lua-resty-redis), it will auto restore the database index to default index (0) after your `select` operation. note that, if you need `select` database index before execute commands, please use pipeline mode to wrapper them. and the same as rediscluster, in lua-resty-redis, a valid redis error value will return `{ false, err }`.

For rediscluster, i wrapped [resty-redis-cluster](https://github.com/steve0511/resty-redis-cluster), the key is when use `eval` command, in script for `eval`, you can use lua table variable as hashtag for redis hashslot at the beginning of this script, but it's a loose solution and **transaction was not recommended in rediscluster spec**. and you should know, pipeline mode with the key in same hashslot(or same rediscluster node at least) has better performance.

As final note, if value in redis is empty, redis will return `ngx.null` which pass to `json_decode` will return `nil`, and if there was an redis error, it will return an table like `{false, error_message}` for the corresponding command in pipeline or transaction

## **Useage**

```
local ipairs = ipairs
local type = type
local unpack = unpack
local utils = require("toolkit.utils")
local log = require("log.index")
-- redis
local redis = require("storage.index").REDIS_LITE

local config = {
    -- your config
}
local resps, err = redis(config , { "set", "name", "tweyseo" }
    , { "select", 1 }, { "set", "timestamp", "1548225156" })
if not resps then
    log.warn("redis pipeline: ", err)
    return
end

local resp
for i, v in ipairs(resps) do
    resp, err = unpack(type(v) == "table" and v or { v })
    -- false means valid redis error value
    if not resp or resp == false then
        log.add(log.WARN, "command [", i, "] err: ", err)
    else
        log.add(log.WARN, "command [", i, "] resp: ", resp)
    end
end

-- rediscluster
local rediscluster = require("storage.index").REDISCLUSTER_LITE

config = {
    -- your config
}
resps, err = rediscluster(config,  { "set", "name", "tweyseo" }, { "set", "timestamp", "1548225156" })
if not resps then
    log.warn("redis pipeline: ", err)
    return
end

for i, v in ipairs(resps) do
    resp, err = unpack(type(v) == "table" and v or { v })
    -- false means valid redis error value
    if not resp or resp == false then
        log.add(log.WARN, "command [", i, "] err: ", err)
    else
        log.add(log.WARN, "command [", i, "] resp: ", resp)
    end
ene
```

## **TODO**

1. mysql wrapper