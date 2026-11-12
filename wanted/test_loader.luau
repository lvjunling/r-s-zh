local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("wanted/loader.lua")
assert(type(luau.load(source)) == "function")
for _, token in {"setupChineseMobile()", "State.MobileFlight", "parentGui(gui)", "Window.SetMenuVisible", 'KeySystem = false'} do
    assert(source:find(token, 1, true), token)
end
local profile = source:match('local stringOptions:.-local settings = table.clone%(Config%)')
assert(profile and profile:find('ESPBoxStyle = {Full = true, Corners = true}', 1, true))
print("编译、手机接口及配置键保留检查通过；未执行游戏逻辑")
local fetchBody = assert(source:match("local function fetchSource%(url%)(.-)\nlocal lifecycle:"))
local attempts = {}
local fetch = luau.load("return function(url) " .. fetchBody, {
    environment = {
        syn = {request = function() attempts[#attempts+1] = "syn"; error("offline") end},
        http = {request = function() attempts[#attempts+1] = "http"; return {StatusCode=500, Body="error"} end},
        request = function() attempts[#attempts+1] = "request"; return {status_code=200, body="source"} end,
        game = {HttpGet = function() error("should not reach fallback") end},
    },
})()
-- 提取的函数体包含结尾 end，包装后只验证下载逻辑。
assert(fetch("https://example.com/script.lua") == "source")
assert(table.concat(attempts, ",") == "syn,http,request")
print("HTTP 接口逐个回退测试通过")
