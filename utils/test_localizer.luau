-- 在仓库根目录运行：lune run utils/test_localizer.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local rb = require("@lune/roblox")
local source = fs.readFile("utils/localizer.lua")
assert(type(luau.load(source)) == "function")
-- 只运行工具窗口的创建代码，避免下载或执行待汉化脚本。
local ui = assert(source:match("^(.-)\nlocal hooked ="))
local objects, connections = {}, {}
local function create(className)
    local obj = {Name = className, Visible = true, Enabled = true}
    function obj:Destroy()
        self.destroyed = true
        for _, child in ipairs(objects) do
            if child.Parent == self then child:Destroy() end
        end
    end
    obj.Activated = {Connect = function(_, callback)
        local connection = {Connected = true}
        function connection:Disconnect() self.Connected = false end
        obj.click = callback
        table.insert(connections, connection)
        return connection
    end}
    table.insert(objects, obj)
    return obj
end
local playerGui = {}
local services = {
    Players = {LocalPlayer = {WaitForChild = function() return playerGui end}},
    HttpService = {}, UserInputService = {},
}
luau.load(ui, {environment = {
    game = {GetService = function(_, name) return assert(services[name]) end},
    Instance = {new = create}, UDim2 = rb.UDim2, Vector2 = rb.Vector2,
    Color3 = rb.Color3, Enum = rb.Enum,
}})()
local function find(name)
    for _, obj in ipairs(objects) do
        if obj.Name == name or obj.Text == name then return obj end
    end
    error("控件缺失：" .. name)
end
local frame, output = find("Frame"), find("TextBox")
local panel, restore = find("GuiLocalizerCollector"), find("RestoreLocalizer")
local minimize = find("最小化界面")
local originalSize = frame.Size
output.Text = '{"translations":{"Hello":"你好"}}'
assert(frame.Visible and not restore.Visible and restore.Parent == panel)
for _ = 1, 3 do
    minimize.click()
    assert(not frame.Visible and restore.Visible and panel.Enabled)
    assert(output.Visible and output.Text:find("你好", 1, true))
    assert(frame.Size == originalSize, "最小化不应改变内容区域或窗口尺寸")
    restore.click()
    assert(frame.Visible and not restore.Visible and output.Visible)
    assert(frame.Size == originalSize and output.Text:find("你好", 1, true))
end
minimize.click()
restore.click()
find("结束采集").click()
assert(panel.destroyed and frame.destroyed and restore.destroyed)
for _, connection in ipairs(connections) do assert(not connection.Connected) end
print("通过：Luau 编译、整窗最小化/展开、内容及尺寸保留、恢复按钮清理")
