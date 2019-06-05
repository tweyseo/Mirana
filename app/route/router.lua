-- function reference
local setmetatable = setmetatable
local xpcall = xpcall
local traceback = debug.traceback
-- include
local routerConf = require("app.conf").router
local Matcher = require("app.route.matcher.index")
local common = require("toolkit.common")

-- replace closure to forbid NYI
local Chain = common.newTable(0, 1)

local handlersProc = function(self, err)
    if err ~= nil then
        return self.errProcess(err, self.req, self.resp, self.errHandlers, self.finalHandler)
    end

    if self.idx >= self.len then
        return self.finalHandler()
    end

    self.idx = self.idx + 1
    return self.handlers[self.idx](self.req, self.resp, self)
end

local errHandlersProc = function(self, err)
    if self.idx <= 1 then
        return self.finalHandler()
    end

    self.idx = self.idx - 1
    return self.errHandlers[self.idx](err, self.req, self.resp, self)
end

function Chain.new(len, proc)
    local instance = common.newTable(0, len)
    setmetatable(instance, { __call = proc })

    return instance
end

---

local Router = common.newTable(0, 6)

function Router:new(routeMode)
    local instance = {}
    instance.matcher = Matcher.new(routeMode)
    setmetatable(instance, { __index = self })

    return instance
end

local function errProcess(srcErr, req, resp, errHandlers, finalHandler)
    if errHandlers == nil or #errHandlers == 0 then
        return finalHandler(srcErr)
    end

    -- use onion model to invoke error handlers
    local next = Chain.new(5, errHandlersProc)
    next.idx = #errHandlers + 1
    next.finalHandler = finalHandler
    next.errHandlers = errHandlers
    next.req = req
    next.resp = resp
    return next(srcErr)
end

local function doProcess(req, resp, matcher, finalHandler, ref)
    local path, method, Err404 = req.path, req.method, routerConf.Err404
    if path == nil or method == nil then
        resp:setStatus(Err404.ec)
        -- use root error handler of the matcher to process 404 error
        return errProcess(Err404.em, req, resp, matcher:rootErrHandlers(), finalHandler)
    end

    -- node { handlers, errHandlers }
    ref.node = matcher:capture(path, method)
    if ref.node == nil then
        resp:setStatus(Err404.ec)
        -- use root error handler of the matcher to process 404 error
        return errProcess(Err404.em, req, resp, matcher:rootErrHandlers(), finalHandler)
    end

    req:setFound(true)

    local handlers = ref.node.handlers

    -- use onion model to invoke handlers (middlewares and handler)
    local next = Chain.new(8, handlersProc)
    next.errProcess = errProcess
    next.req = req
    next.resp = resp
    next.errHandlers = ref.node.errHandlers
    next.finalHandler = finalHandler
    next.idx = 0
    next.len = #handlers
    next.handlers = handlers
    next()
end

function Router:process(req, resp, finalHandler)
    local pOk, pErr
    do
        local ref = {}
        pOk, pErr = xpcall(doProcess, traceback, req, resp, self.matcher, finalHandler, ref)

        if pOk ~= true then
            local node = ref.node
            pOk, pErr = xpcall(errProcess, traceback, pErr, req, resp
                , node and node.errHandlers or self.matcher:rootErrHandlers(), finalHandler)
        end
    end

    if pOk ~= true then
        finalHandler(pErr)
    end
    --[[local ref = {}
    doProcess(req, resp, self.matcher, finalHandler, ref)]]
end

-- auto generate forward function and cache them
setmetatable(Router, { __index = function(_, method)
        local f = function(self, ...)
            -- router equal to self
            local matcher = self.matcher
            return matcher[method](matcher, ...)
        end

        Router[method] = f

        return f
    end})

return Router