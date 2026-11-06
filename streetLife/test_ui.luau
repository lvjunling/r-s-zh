local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("/Users/lvjunling/work_space/flutter/persor/r-s-zh/streetLife/loader.lua")
assert(type(luau.load(source)) == "function")
local body = assert(source:match("local function fittedScale%(width, height, zoom%)(.-)\nend"))
local fit = luau.load("return function(width,height,zoom) " .. body .. " end")()
for _, view in {{390,844}, {844,390}, {1920,1080}, {320,568}} do
    local scale = fit(view[1], view[2], 1)
    assert(scale * 650 <= view[1] - 24 + 0.001)
    assert(scale * 500 <= view[2] - 80 + 0.001)
    assert(fit(view[1],view[2],scale - 0.1) < scale)
end
print("编译及横竖屏缩放检查通过；未运行游戏逻辑")
