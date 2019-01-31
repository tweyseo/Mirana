# **scheduler**

## **Overview**

This component is a special component for adapting existing spec with some common components like **net**. in fact, this component is expected to be the unified scheduling layer for some common components like **net**, **storage** and so on. but note that, adapters in this component were just for adapting existing spec with common components and they may **slow down** your preformance, so you are recommended use this component as **scheduling** rather than adapting.

## **Useage**

```
local scheduler = require("scheduler.index")
local now = ngx.now
local log = require("log.index")
local utils = require("toolkit.utils")

local resp, err = scheduler(scheduler.HTTP
    , "http://192.25.106.105:29527/ping"
    , { body = { time = now() } })
if not resp then
    log.warn("send err: ", err)
    return
end

log.add(log.INFO, "resp: ", utils.json_encode(resp))
```

## **TODO**

1. breaker plugin.