-- function reference
-- include
local parallel = require("flowCtrl.plugin.parallel")
local parallelPro = require("flowCtrl.plugin.parallelPro")
local parallelRace = require("flowCtrl.plugin.parallelRace")

return {
    PARALLEL = parallel(),
    PARALLEL_PRO = parallelPro(),
    PARALLEL_RACE = parallelRace()
}