-- function reference
local select = select
local remove = table.remove
local unpack = unpack
-- include
local Rediscluster = require("rediscluster")
local defaultConf = require("storage.conf").REDISCLUSTER
local mergeConf = require("toolkit.utils").mergeConf

return function()
    -- conf see storage.conf.REDISCLUSTER
    -- cmds { method, key, value }, ...
    return function(conf, ...)
        -- init
        conf = mergeConf(conf, defaultConf)
        local rcc, err
        rcc, err = Rediscluster:new(conf)
        if not rcc then
            return nil, err
        end

         -- execute
        local function execute(self, cmd)
            local method = self[cmd[1]]
            remove(cmd, 1)
            return method(self, unpack(cmd))
        end
        local count = select('#', ...)
        local result, cmd
        if count == 1 then
            cmd = select(1, ...)
            result, err = execute(rcc, cmd)
        else
            rcc:init_pipeline()
            for i = 1, count do
                cmd = select(i, ...)
                execute(rcc, cmd)
            end
            result, err = rcc:commit_pipeline()
        end
        if not result then
            return nil, err
        end

        return result
    end
end