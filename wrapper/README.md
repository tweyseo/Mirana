# **wrapper**

## **Overview**

This component working on wrapping an object (or the partial functions of an object) for advanced features as tracer, checker, autotest and so on, and the wrap action was just **invoked once** for each object that need wrapping, during the stage of init. as a wrapper, you should implement `entry()`, `leave()` and `prepare()`. `prepare()` adapted original object to wrapper's actual object via `opt` forwarded by `wrap()`, and the actual object was invoked by `entry()` and `leave()`.

It's recommended to create wrappers in modules (folders), which was included the similar **module units**. note that, a **module unit** (or the partial functions of a **module unit**) can escape from wrapping via the `except` parameter that create the wrappers, and `inverse` parameter inversed the `except` list as a **module unit** (or the partial functions of a **module unit**) that need to wrap (this parameter was used for special wrappers that are rarely used), more details see [*wrap.lua*](https://github.com/tweyseo/Mirana/blob/master/wrapper/plugin/wrap.lua). 

About tracer, you can filter the tracing log and output them into the specified file via the `error_log` that setting in the nginx-*.conf, then get tracing log via `fetchTrace()` in [log](https://github.com/tweyseo/Mirana/tree/master/log) component and output them at the stage of `log_by_lua`, the behaviour of fetch and output on tracing log was the same as what we do on [log](https://github.com/tweyseo/Mirana/tree/master/log) component.

About checker, you can use "params" to specify expected parameter type list for checking the **parameters** of the corresponding object's function, and "results" for **results** return from the corresponding object's function ("results" was optional). note that, in **parameters** or **results**, value was set to string "nil" to escape from checking, and `maxDepth` was set to limit the max depth of nest table checking. at last,table type checking had a litte flaw at error information logging.

As final note, you are recommended to use wrapper of tracer at the outermost layer to get the more accurate tracking results.

## **Useage**

```
local wrapper = require("wrapper.index")
local object = require("/handler/test/hello")

local Tracer = wrapper.TRACER
local tracer = Tracer:new(Tracer.WARN, { ["hello"] = {"tcp", "capture"} })
tracer:wrap(object, { source = "/handler/test/hello" })
object.http()
-- more code
```

## **TODO**

1. wait for `table.nkeys()` to log more accurate error information when check failed in checker wrapper.
2. autotest and more wrapper to be implemented later.