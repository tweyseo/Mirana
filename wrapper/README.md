# **wrapper**

## **Overview**

This component working on wrapping all functions of a table for advanced features as tracer, typeChecking, autotest and so on. as a wrapper, you should implement `entry()`, `leave()` and `prepare()`. note that, `prepare()` adapt original object to wrapper's actual object with varargs forwarded by `wrap()`.

About tracer, you can filter the tracing log and output them into the specified file, via `error_log` that setting in the nginx-*.conf, then get tracing log via `fetchTrace()` in [log](https://github.com/tweyseo/Mirana/tree/master/log) component.

As a final note, you are recommended to wrap tracer to the outermost layer to get the more accurate tracking results.

## **Useage**

```
local wrapper = require("wrapper.index")
local object = require("/handler/test/hello")

local Tracer = wrapper.TRACER
local tracer = Tracer:new(Tracer.WARN)
tracer:wrap(object, { source = "/handler/test/hello" })
object.http()
-- more code
```

## **TODO**

1. typeChecking, autotest and more wrapper to be implemented later.