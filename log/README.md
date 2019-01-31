# **log**

## **Overview**

Why we must wrap `ngx.log` like we had done in this component:

1. in order to unify the code and easily to be replaced, we must wrap `ngx.log`;
2. if we wrap `ngx.log` in a function simply, since it just collects current stack information, we will lost actual invoke stack information especially when debugging;
3. and if we use `ngx.errlog` in [lua-resty-core](https://github.com/openresty/lua-resty-core), `raw_log` and `debug.getinfo` can solve problem above adequately. unfortunately, `raw_log` only accepts a single string, it means that we must concatenate the strings in lua land, which was low performance, and `debug.getinfo` was also inefficient.

Above all, for **debugging**, we wrap `ngx.log` with `debug.getinfo` and filter log level before invoke `debug.getinfo`; and simple wrap `ngx.log` for **overview logging** in the stage of `log_by_lua`, of course, log level filtering was done before add to overview logging. and of course, it will output into the "error_log" file that setting in the nginx-*.conf.

As a final note, `ngx.log` level is in the order of increasing severity but inversely proportional to number value.

## **Useage**

```
-- debugging
local log = require("log.index")
log.warn("hello ", "world!")

-- overview logging
location / {
    content_by_lua_block {
        local log = require("log.index")

        log.add(log.WARN, "hello ", "world!")
    }

    log_by_lua_block {
        local log = require("log.index")
        local common = require("toolkit.common")

        local logs = log.fetchLog()
        local traces = log.fetchTrace()
        log.overview("id:", common.reqId(), " status:", common.status(), " elapsed:", common.reqTime(), "\n"
            , logs and logs.."\n" or "", traces and traces.."\n" or "")
    }
}
```

## **TODO**

1. stream support.