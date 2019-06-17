-- function reference
local select = select
local unpack = unpack
-- include
local Redis = require("resty.redis")
local defaultConf = require("storage.conf").REDIS
local log = require("log.index")
local mergeConf = require("toolkit.utils").mergeConf

-- if you need select db before execute commands, pls use pipeline mode to wrapper select op
return function()
    -- conf see storage.conf.REDIS
    -- cmds { method, key, value }, ...
    return function(conf, ...)
        -- init
        conf = mergeConf(conf, defaultConf)
        local rc, err, ok
        rc, err = Redis:new()
        if not rc then
            return nil, err
        end
        rc:set_timeout(conf.timeout)

        -- connect
        ok, err = rc:connect(conf.addr, conf.port)
        if not ok then
            return nil, err
        end

        -- auth
        local auth = conf.auth
        if auth and auth ~= "" then
            local count
            count, err = rc:get_reused_times()
            if count == 0 then
                ok, err = rc:auth(auth)
            elseif err then
                ok = false
            else
                ok = true
            end
            if not ok then
                return nil, err
            end
        end

        -- execute
        local function execute(self, cmd)
            local method = self[cmd[1]]
            return method(self, unpack(cmd, 2))
        end
        local count, selectdb, result, cmd = select('#', ...), false
        if count == 1 then
            cmd = select(1, ...)
            result, err = execute(rc, cmd)
        else
            rc:init_pipeline(count)
            for i = 1, count do
                cmd = select(i, ...)
                if not selectdb and cmd[1] == "select" then selectdb = true end
                execute(rc, cmd)
            end
            result, err = rc:commit_pipeline()
        end
        if not result then
            return nil, err
        end

        -- restore to db 0
        if selectdb then
            ok, err = rc:select(0)
            if not ok then
                -- just log warn and do not keep this connenction alive
                log.warn("select db 0 failed: ", err)
            else
                -- select 0 success set the flag selectdb false
                selectdb = false
            end
        end

        -- keep alive
        -- select 0 success or did not select db both treat as healty connection
        if not selectdb then
            ok, err = rc:set_keepalive(conf.maxIdleTimeout, conf.poolSize)
            if not ok then
                -- just log warn
                log.warn("keep alive failed: ", err)
            end
        end

        return result
    end
end