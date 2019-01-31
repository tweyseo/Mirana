-- function reference
-- include
local redisLite = require("storage.plugin.redis.redisLite")
local redisclusterLite = require("storage.plugin.redis.redisclusterLite")

return {
    REDIS_LITE = redisLite(),
    REDISCLUSTER_LITE = redisclusterLite()
}