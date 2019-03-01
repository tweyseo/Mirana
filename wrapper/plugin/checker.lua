-- function reference
local select = select
local error = error
local pairs = pairs
local ipairs = ipairs
local type = type
local setmetatable = setmetatable
-- include
local common = require("toolkit.common")
local conf = require("wrapper.conf").CHECKER
local log = require("log.index")

local Checker = common.newTable(0, 4)

-- process array and hash mix
local function tableCheck(refTab, tb, chain, depth)
    local refTabLen, tbLen = #refTab, #tb
    if refTabLen ~= tbLen then
        return false, "expect table length "..refTabLen.." but "..tbLen.." at "..chain
    end

    local val, tp, refTp
    for k, ref in pairs(refTab) do
        -- string "nil" to escape from checking
        if ref ~= "nil" then
            val = tb[k]
            tp, refTp = type(val), type(ref)
            if refTp == "table" and tp == refTp then
                k = type(k) == "number" and "["..k.."]" or k
                depth = depth + 1
                local maxDepth = conf.maxDepth
                if depth >= conf.maxDepth then
                    log.warn("exceed max checker depth: ", maxDepth)
                    return true
                end

                return tableCheck(ref, val, chain..k..".", depth)
            end

            if tp ~= ref then
                ref = refTp == "table" and "table" or ref
                return false, "expect "..ref.." but "..tp.." at "..(chain..k)
            end
        end
    end

    return true
end

-- split table check and other type check performance better
local function typeCheck(reference, ...)
    local val, tp, refTp
    for i, ref in ipairs(reference) do
        -- string "nil" to escape from checking
        if ref ~= "nil" then
            val = select(i, ...)
            tp, refTp = type(val), type(ref)
            if refTp == "table" and tp == refTp then
                return tableCheck(ref, val, i..": ", 1)
            end

            if tp ~= ref then
                ref = refTp == "table" and "table" or ref
                return false, "expect "..ref.." but "..tp.." at "..i
            end
        end
    end

    return true
end

local function doCheck(obj, index, mode, reference, ...)
    local ipt, opt = conf.mode.input, conf.mode.output
    -- results can escape from checking
    if mode == opt and reference == nil then
        return
    end

    local content = mode == ipt and "parameters" or "results"
    local len, refLen = select('#', ...), #reference
    if len ~= refLen then
        local err = "expect "..refLen.." but "..len
        error("invalid ["..content.."] length of function: "..obj.source.."/"..index.."(), "..err)
    end

    local ok, err = typeCheck(reference, ...)
    if not ok then
        error("invalid ["..content.."] content of function: "..obj.source.."/"..index.."(), "..err)
    end
end

local function inputCheck(obj, index, ...)
    local refFunc = obj.refObj[index]
    if refFunc == nil then
        log.warn("invalid checklist for function: ", obj.source, "/", index, "()")
        return
    end

    local refParams = refFunc["params"]
    if refParams == nil then
        log.warn("invalid checklist without params for function: ", obj.source, "/", index, "()")
    end

    doCheck(obj, index, conf.mode.input, refParams, ...)

    return refFunc["results"]
end

-- except?, inverse?
function Checker:new(checklist, except, inverse)
    local instance = {}
    instance.checklist = checklist
    instance.except = except
    instance.inverse = inverse

    setmetatable(instance, { __index = self })

    return instance
end

function Checker:prepare(obj, opt)
    local objectName, source = opt and opt.name, opt and opt.source
    if opt and opt.name and opt.source then
        local checklist = self.checklist
        local refObj = checklist and checklist[objectName]
        if refObj == nil then
            log.warn("invalid checklist or invalid objectName: ", objectName or "nil")
            return false
        end

        obj.refObj = refObj
        obj.source = source

        return true
    end

    log.warn("invalid name or invalid source")
    return false
end

function Checker:entry(obj, index, ...)
    local _ = self
    return { inputCheck(obj, index, ...) }
end

function Checker:leave(obj, index, context, ...)
    local _ = self
    doCheck(obj, index, conf.mode.output, context[1], ...)
    return ...
end

return setmetatable(Checker, { __index = { wrap = require("wrapper.plugin.wrap") } })