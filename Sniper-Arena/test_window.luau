-- 在仓库根目录运行：lune run Sniper-Arena/test_window.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local rb = require("@lune/roblox")
local source = fs.readFile("Sniper-Arena/loader.lua")
local pixelTolerance = 1 -- UDim2 偏移取整，缩放及非零锚点可能产生亚像素误差。
assert(type(luau.load(source)) == "function")
-- 只运行显示规则和边界计算，不下载或执行第三方脚本。
local refreshBody = assert(source:match("\n    refreshTouchControls = function%(%)(.-)\n    end"))
local fitBody = assert(source:match("local function fitWindow%(keepWholeWindow%)(.-)\n    end"))
assert(not source:find("Touch.Aim", 1, true), "旧的悬浮瞄准状态应一并移除")
local floatingButtons = {}
for title in source:gmatch('local %w+ = button%("([^"]+)"') do
    table.insert(floatingButtons, title)
end
assert(table.concat(floatingButtons, ",") == "收起菜单,上升,下降", "游戏画面不应再创建瞄准悬浮条")
local ui = {
    UserInputService = { TouchEnabled = true },
    S = { AlwaysOn = false, Fly = false },
    Window = { Root = { Visible = true } },
    menu = {},
    up = {},
    down = {},
}
local refresh = luau.load("return function()" .. refreshBody .. "\nend", { environment = ui })()
for _, device in ipairs({ true, false }) do
    for _, flying in ipairs({ true, false }) do
        for _, windowOpen in ipairs({ true, false }) do
            ui.UserInputService.TouchEnabled = device
            ui.S.Fly = flying
            ui.Window.Root.Visible = windowOpen
            refresh()
            assert(ui.menu.Visible == device)
            assert(not ui.up.Visible and not ui.down.Visible)
            assert(ui.menu.Text == (windowOpen and "收起菜单" or "展开菜单"))
        end
    end
end
ui.UserInputService.TouchEnabled, ui.S.Fly, ui.flyBV = true, true, {}
refresh = luau.load("return function()" .. refreshBody .. "\nend", { environment = ui })()
refresh()
assert(ui.up.Visible and ui.down.Visible, "飞行升降控件应保持可用")
local toggleBody = assert(source:match('Tabs.Aim:AddToggle%("AlwaysOn", {.-Callback = function%(v%)(.-) end'))
local toggleAlwaysOn = luau.load("return function(v)" .. toggleBody .. "\nend", { environment = ui })()
toggleAlwaysOn(true)
assert(ui.S.AlwaysOn)
toggleAlwaysOn(false)
assert(not ui.S.AlwaysOn)
local aimCondition = assert(source:match("if S.Aimbot and %((.-)%) and target then"))
local shouldAim = luau.load(
    "return function(enabled, HoldingAim, alwaysOn) local S = {AlwaysOn = alwaysOn} return enabled and ("
        .. aimCondition
        .. ") end"
)()
for _, enabled in ipairs({ true, false }) do
    for _, held in ipairs({ true, false }) do
        for _, alwaysOn in ipairs({ true, false }) do
            assert(shouldAim(enabled, held, alwaysOn) == (enabled and (held or alwaysOn)))
        end
    end
end

for _, view in ipairs({ { 390, 744 }, { 744, 280 }, { 320, 480 }, { 480, 200 }, { 1920, 1080 } }) do
    for _, anchor in ipairs({ rb.Vector2.zero, rb.Vector2.new(0.5, 0.5) }) do
        local root =
            { Size = rb.UDim2.fromOffset(520, 420), Position = rb.UDim2.fromOffset(-500, 10000), AnchorPoint = anchor }
        local scale = { Scale = 1 }
        local context = {
            Window = { Root = root },
            area = { AbsoluteSize = rb.Vector2.new(view[1], view[2]) },
            scale = scale,
            UDim2 = rb.UDim2,
        }
        local fit = luau.load(
            "local fitting = false\nreturn function(keepWholeWindow)" .. fitBody .. "\nend",
            { environment = context }
        )()
        local function rect()
            local width, height = 520 * scale.Scale, 420 * scale.Scale
            return root.Position.X.Offset - anchor.X * width, root.Position.Y.Offset - anchor.Y * height, width, height
        end
        local function wholeWindowFits()
            local x, y, width, height = rect()
            assert(x >= 8 - pixelTolerance and y >= 8 - pixelTolerance)
            assert(x + width <= view[1] - 8 + pixelTolerance and y + height <= view[2] - 8 + pixelTolerance)
        end
        fit(true)
        wholeWindowFits()
        -- 缩放后贴满屏的方向也应允许拖动，不能每次都被吸回边缘。
        local _, _, width, height = rect()
        local desired = rb.UDim2.fromOffset(40 + anchor.X * width, 70 + anchor.Y * height)
        root.Position = desired
        fit()
        assert(
            math.abs(root.Position.X.Offset - desired.X.Offset) < 0.001
                and math.abs(root.Position.Y.Offset - desired.Y.Offset) < 0.001
        )
        assert(context.Window.Position == root.Position)
        for _, extreme in ipairs({ { -10000, -10000 }, { 10000, 10000 } }) do
            root.Position = rb.UDim2.fromOffset(extreme[1], extreme[2])
            fit()
            local x, y, w, h = rect()
            local grabWidth, grabHeight = math.min(w, 160 * scale.Scale), math.min(h, 42 * scale.Scale)
            assert(
                x + w >= 8 + grabWidth - pixelTolerance and x <= view[1] - grabWidth - 8 + pixelTolerance,
                string.format(
                    "view=%d,%d anchor=%s x=%f width=%f grab=%f",
                    view[1],
                    view[2],
                    tostring(anchor),
                    x,
                    w,
                    grabWidth
                )
            )
            assert(
                y >= 8 - pixelTolerance and y + grabHeight <= view[2] - 8 + pixelTolerance,
                string.format(
                    "view=%d,%d anchor=%s y=%f height=%f grab=%f",
                    view[1],
                    view[2],
                    tostring(anchor),
                    y,
                    h,
                    grabHeight
                )
            )
        end
        fit(true)
        wholeWindowFits()
    end
end
assert(source:find('GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fitWindow(true) end)', 1, true))
assert(source:find('GetPropertyChangedSignal("Size"):Connect(function() fitWindow(true) end)', 1, true))
assert(source:find('GetPropertyChangedSignal("Position"):Connect(fitWindow)', 1, true))
print(
    "通过：Luau 编译、瞄准悬浮条移除、菜单持续瞄准、PC 按键条件、飞行控件及拖动/横竖屏边界"
)
