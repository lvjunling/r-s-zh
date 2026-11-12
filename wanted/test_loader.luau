local fs = require("@lune/fs")
local luau = require("@lune/luau")
local path = "wanted/loader.lua"
local source = fs.readFile(path)
assert(type(luau.load(source)) == "function")
for _, removed in {"1drv.ms", "keyBox", "denyAuth", "KEY_PLACEHOLDER", "setclipboard"} do
    assert(not source:find(removed, 1, true), removed)
end
assert(source:find("未包含", 1, true))
print("编译与密钥/下载引导移除检查通过；未执行界面")
