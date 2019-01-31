# **net**

## **Overview**

This component working on "one-time" communications including TCP and HTTP. "one-time" here means after one request and one response then will recycle the connection to the connection pool provide by [OpenResty](https://github.com/openresty/openresty).

For HTTP, i wrapped [lua-resty-http](https://github.com/ledgetech/lua-resty-http), although this awesome resty already provides a fast [`request_uri`](https://github.com/ledgetech/lua-resty-http#request_uri) API, but i need more minimalist and automated HTTP communication in my project, so in this wrapper i use **json** encoding format as default and remove the support on **SSL**.

For TCP, i wrapped [`ngx.socket.tcp`](https://github.com/openresty/lua-nginx-module/blob/master/README.markdown#tcpsockconnect) as client which also do "one-time" communications, and use string as message boundary to parse a full message; and use wrapping of [`ngx.req.socket`](https://github.com/openresty/lua-nginx-module/blob/master/README.markdown#ngxreqsocket) as server that use the same message parse behavior as client, note that, server hands over the control of the recv loop to the upper layer after the "one-time" communication was done.

## **Useage**

```
local now = ngx.now
local net = require("net.index")
local log = require("log.index")
local utils = require("toolkit.utils")

-- HTTP
local httpc = net.HTTP_CLIENT_LITE

local resp, err = httpc({ addr = "192.25.106.105", port = 29527 }
    , { path = "/ping", body = { time = now() } })
if not resp then
    log.warn("send err: ", err)
    return
end

log.info("resp: ", utils.json_encode(resp))

-- TCP
-- client
local tcpc = net.TCP_CLIENT_LITE

local resp, err = tcpc({ addr = "192.25.106.105", port = 19527 }
    , { id = 1, body = { time = now() }})
if not resp then
    log.warn("send err: ", err)
    return
end

log.info("resp: ", utils.json_encode(resp))

-- server
local tcps = net.TCP_SERVER_LITE

local function router(req)
    -- resolveMessage and handleMessage
    return resp, continue
end

local function errHandler(data, err)
    -- handleErr
    return true
end

tcps(nil, router, errHandler)
```

## **TODO**

1. expect traditional message parse on TCP, which parse a full message through specified message header.
2. UDP wrapper