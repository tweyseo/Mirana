-- function reference
local setmetatable = setmetatable
local type = type
local pairs = pairs
local ipairs = ipairs
local find = ngx.re.find -- todo: add resty.core
local insert = table.insert
local lower = string.lower
local error = error
-- include
local conf = require("app.route.matcher.conf")
local common = require("toolkit.common")
local split = require("ngx.re").split
-- const
local hIdx, ehIdx = 1, 2 -- for instance.nodes.path
local keyIdx, nodeIdx, countIdx = 1, 2, 3  --for instance.cache
local rootGroupId = 1
local defaultGroupLength = 10
local additionalLength = #conf.caret + #conf.slash

-- static route for exact match (URI without colon and regex)
-- note that addMiddlewares and addErrHandlers must be invoked before calling addHandler
local Hash = common.newTable(0, 7)

function Hash:new()
    local instance = {}
    --[[
        to implement the idea of the onion model and more easier generation of static routes, the
        middlewares and the errHandlers was grouped by path length, like onions. the middlewares
        was grouped in order from short to long, and which was inverse in the errHandlers.
    ]]
    --[[
        { { path1 = { function1, function2, ... } , path2 = { function1, function2, ... }, ... }
        , { path1 = { function1, function2, ... } , path2 = { function1, function2, ... }, ... }
        , ... }
    ]]
    instance.middlewares = common.newTable(defaultGroupLength, 0)
    instance.mwCursor = 0
    -- similar with middlewares
    instance.errHandlers = common.newTable(defaultGroupLength, 0)
    instance.ehCursor = 0
    --[[
        nodes = {
            path:method = {
                { function1, function2, ... }   -- middlewares and method handler under this path
                , { function1, function2, ... } -- errHandlers under this path
            } }
    ]]
    instance.nodes = {}
    -- only cacahe one path with hot counter
    instance.cache = {}
    setmetatable(instance, { __index = self })

    return instance
end

-- return groupId and more regular path for easier generation of static routes
local function groupPath(path)
    -- root path
    if path == conf.rootPath then
        return rootGroupId, path
    end

    local m, err = split(path, conf.slash, "jo")
    if err then
        error(err)
    end
    --[[
        the length of the split result (#m) decided the group id.
        caret and slash add in path was for exact matching (e.g. /test or /test2 do not match
        /test1/test2, but /test1 do).
    ]]
    return #m, conf.caret..path..conf.slash
end

local function dynamicArray(array, cursor, index)
    if index <= cursor then
        return cursor
    end

    for _ = 1, index - cursor do
        insert(array, {})
    end
    -- return index as new cursor
    return index
end

-- nil path means root "/"
function Hash:addMiddlewares(path, func)
    if type(path) == "function" then
        func = path
        path = conf.rootPath
    end

    local groupId, newPath = groupPath(path)
    self.mwCursor = dynamicArray(self.middlewares, self.mwCursor, groupId)

    local group = self.middlewares[groupId]
    local funcList = group[newPath]
    if funcList == nil then
        group[newPath] = { func }
        return
    end

    insert(funcList, func)
end

-- nil path means root "/"
function Hash:addErrHandlers(path, func)
    if type(path) == "function" then
        func = path
        path = conf.rootPath
    end

    local groupId, newPath = groupPath(path)
    self.ehCursor = dynamicArray(self.errHandlers, self.ehCursor, groupId)

    local group = self.errHandlers[groupId]
    local funcList = group[newPath]
    if funcList == nil then
        group[newPath] = { func }
        return
    end

    insert(funcList, func)
end

-- collect handlers from middlewares or errHandlers for generation of static routes
local function collectHandlers(groups, srcPath)
    local handlerList = {}
    for groupId, group in ipairs(groups) do
        -- root path and can be empty
        if groupId == rootGroupId and group[conf.rootPath] ~= nil then
            for _, func in ipairs(group[conf.rootPath]) do
                insert(handlerList, func)
            end
        else
            for path, funcList in pairs(group) do
                -- filter with length first, and additionalLength is length of caret and slash
                if #srcPath >= #path - additionalLength
                    and find(srcPath..conf.slash, path, "jo") ~= nil then
                    for _, func in ipairs(funcList) do
                        insert(handlerList, func)
                    end
                end
            end
        end
    end

    return handlerList
end

-- note that, different path with different method only map one handler.
function Hash:addHandler(method, path, func)
    local key = path..conf.colon..lower(method)
    local node = self.nodes[key]
    if node == nil then
        local handlers = collectHandlers(self.middlewares, path)
        insert(handlers, func)
        self.nodes[key] = { handlers, collectHandlers(self.errHandlers, path) }
        -- ignore, if already exists
        return
    end
end

--[[
    root error handler process:
    1. an error occurred before the node was found
    2. the found node has no error handler
]]
function Hash:rootErrHandlers()
    local rootGroup = self.errHandlers[rootGroupId]
    return rootGroup and rootGroup[conf.rootPath]
end

local function searchCache(self, key)
    if conf.cache == false then
        return
    end

    local cache = self.cache
    if cache[keyIdx] == key then
        cache[countIdx] = cache[countIdx] + 1
        return cache[nodeIdx]
    end
end

local function missCache(self, key, node)
    if conf.cache == false then
        return
    end

    local cache = self.cache
    if cache[countIdx] == nil or cache[countIdx] == 1 then
        self.cache = { key, node, 1 }
        return
    end

    self.cache[countIdx] = self.cache[countIdx] - 1
end

function Hash:dumpCache()
    if conf.cache == false then
        return nil
    end

    local cache = self.cache
    return { key = cache[keyIdx], count = cache[countIdx] }
end

function Hash:capture(path, method)
    local key = path..conf.colon..lower(method)
    local node = searchCache(self, key)
    if node ~= nil then
        return { handlers = node[hIdx], errHandlers = node[ehIdx] }
    end

    local miss = true
    node = self.nodes[key]
    if node == nil then
        -- just do effective cache miss
        return
    end

    if miss == true then
        missCache(self, key, node)
    end

    return { handlers = node[hIdx], errHandlers = node[ehIdx] }
end

return Hash