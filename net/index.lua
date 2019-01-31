-- function reference
-- include
local tcpClientModeLite = require("net.plugin.tcp.clientModeLite")
local tcpServerModeLite = require("net.plugin.tcp.serverModeLite")
local httpClientModeLite = require("net.plugin.http.clientModeLite")

return {
    TCP_CLIENT_LITE = tcpClientModeLite(),
    TCP_SERVER_LITE = tcpServerModeLite(),
    HTTP_CLIENT_LITE = httpClientModeLite()
}