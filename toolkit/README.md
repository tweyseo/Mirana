# **toolkit**

## **Overview**

It's not a component, but a toolkit. *common.lua* is wrapper of lua, luajit and ngx that built into [OpenResty](https://github.com/openresty/openresty), and *utils.lua* is wrapper for third party libraries.

Note, **autoRequire** is a special tool for requiring lua file automatically:
- parameters **regexInfo**: it turn absolute path to relative path by named captures **path** in **regex** (more about relative path was specified by `lua_package_path` in nginx-*.conf), and named captures **objectName** is the key to store the results of `autoRequire` in requireTable, so attention duplicate key.
- parameters **except**: it specify lua file to skip `autoRequire`.
- variable arguments **wrappers**: they wrap the results of `autoRequire` before store them in requireTable, more details see [wrapper](https://github.com/tweyseo/Mirana/tree/master/wrapper) component.

## **Useage**

```
local AutoRequire = require("toolkit.autoRequire")
local wrapper = require("wrapper.index")
-- const
local regex = [[(?<path>\/\w+\/\w+\/(?<objectName>\w+))\.]]
local requirePath = "/app/handler/test"

-- more code

local regexInfo = { regex, "path", "objectName" }
local Tracer = wrapper.TRACER
local tracer = Tracer:new(Tracer.WARN, { ["hello"] = {"tcp", "capture"} })
local autoRequire = AutoRequire:new(regexInfo, { ["index.lua"] = true }, tracer)
local requireTable = {}
autoRequire(requirePath, requireTable)

-- more code
```

the regex is to match the path like **/home/tweyseo/project/APIServer/app/handler/test/hello.lua**, it will capture **path = /handler/test/hello** and **objectName = hello**, **path** and **objectName** is for requiring and storing, respectively, and the wrapper here is a call tracing, more details see [*index.lua*](https://github.com/tweyseo/Shredder/blob/master/app/handler/test/index.lua).

## **TODO**

Implement the LFS library via ffi.