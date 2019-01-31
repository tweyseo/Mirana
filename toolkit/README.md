# **toolkit**

## **Overview**

It's not a component, but a toolkit. *common.lua* is wrapper of lua, luajit and ngx that built into [OpenResty](https://github.com/openresty/openresty), and *utils.lua* is wrapper for third party libraries.

Note, **autoRequire** is a special tool for requiring lua file automatically:
- parameters **regexInfo**: it turn absolute path to relative path by named captures **path** in **regex** (more about relative path was specified by `lua_package_path` in nginx-*.conf), and named captures **objectName** is the key to store the results of `autoRequire` in requireTable, so attention duplicate key.
- parameters **except**: it specify lua file to skip of `autoRequire`.
- parameters **wrapper**: it wrap the results of `autoRequire` before store them in requireTable, more details see [wrapper](https://github.com/tweyseo/Mirana/tree/master/wrapper) component.

## **Useage**

In [APIServer](https://github.com/tweyseo/Shredder) demo, i use `autoRequire` for requiring all **handlers** and all **models**, the **handlers** requiring as follow: 

```
local AutoRequire = require("toolkit.autoRequire")
local wrapper = require("wrapper.index")
-- const
local regex = [[(?<path>\/\w+\/\w+\/(?<objectName>\w+))\.]]
local requirePath = "/app/handler/test"

-- more code

local regexInfo = { regex, "path", "objectName" }
local Tracer = wrapper.TRACER
local tracer = Tracer:new(Tracer.WARN)
local autoRequire = AutoRequire:new(regexInfo, { ["index.lua"] = true }, tracer)

-- more code
```

the regex is to match the path like "/home/tweyseo/project/APIServer/app/handler/test/hello.lua", it will capture "path = /handler/test/hello" and "objectName = hello", "path" and "objectName" for requiring and storing, "path" for the wrapper that pass to `autoRequire`, and the wrapper here is a call tracing.

more details see [APIServer](https://github.com/tweyseo/Shredder)

## **TODO**

Implement the LFS library via ffi.