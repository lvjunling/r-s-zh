-- 在仓库根目录运行：lune run Ultimate-Mining-Tycoon/test_loader.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local rb = require("@lune/roblox")
local E, V2, V3, U2, CF = rb.Enum, rb.Vector2, rb.Vector3, rb.UDim2, rb.CFrame
local source = fs.readFile("Ultimate-Mining-Tycoon/loader.lua")
assert(type(luau.load(source)) == "function")
for _, token in ipairs({
    "MY_PERMANENT_KEY",
    "GET_KEY_WEB_LINK",
    "KEY_FILE",
    "TIME_FILE",
    "IsKeyValid",
    "SaveKey24H",
    "MrGhostKeyGui",
    "readfile",
    "writefile",
    "isfile",
    "MouseButton1Click",
}) do
    assert(not source:find(token, 1, true), "密钥系统或旧输入事件残留：" .. token)
end
local exposed, count = source:gsub(
    "\nend%s+LoadMainScript%(%)[%s]*$",
    [[
return {Settings = Settings, ActiveESP = ActiveESP, OreInfo = GetOreVietnameseInfo}
end
return LoadMainScript()
]]
)
assert(count == 1)

local function signal()
    local entries = {}
    return {
        Connect = function(_, fn)
            local c = { Connected = true }
            function c:Disconnect()
                self.Connected = false
            end
            table.insert(entries, { c, fn })
            return c
        end,
        Fire = function(_, ...)
            for _, e in ipairs(table.clone(entries)) do
                if e[1].Connected then
                    e[2](...)
                end
            end
        end,
        Live = function()
            local n = 0
            for _, e in ipairs(entries) do
                if e[1].Connected then
                    n += 1
                end
            end
            return n
        end,
    }
end
local function fixture(coreAllowed, promptSupported, promptFails)
    local objects, jobs = {}, {}
    local interactions = 0
    local function new(class, parent)
        local values = {
            Name = class,
            ClassName = class,
            Text = "",
            Visible = true,
            Active = false,
            destroyed = false,
            Position = U2.fromOffset(0, 0),
            Size = U2.fromOffset(0, 0),
            AbsoluteSize = V2.new(390, 744),
            AnchorPoint = V2.zero,
            CFrame = CF.new(),
            Position3D = V3.zero,
            Attributes = {},
        }
        local events = { Activated = signal(), InputBegan = signal(), Destroying = signal() }
        local changes, methods = {}, {}
        function methods:IsA(kind)
            return class == kind or (kind == "BasePart" and class == "Part")
        end
        function methods:GetAttribute(name)
            return values.Attributes[name]
        end
        function methods:GetChildren()
            local list = {}
            for _, obj in ipairs(objects) do
                if obj.Parent == self then
                    table.insert(list, obj)
                end
            end
            return list
        end
        function methods:FindFirstChild(name, recursive)
            if self.Name == "CoreGui" and not coreAllowed then
                error("模拟 CoreGui 访问受限")
            end
            for _, obj in ipairs(self:GetChildren()) do
                if obj.Name == name then
                    return obj
                end
                if recursive then
                    local found = obj:FindFirstChild(name, true)
                    if found then
                        return found
                    end
                end
            end
        end
        function methods:FindFirstChildOfClass(kind)
            for _, obj in ipairs(self:GetChildren()) do
                if obj:IsA(kind) then
                    return obj
                end
            end
        end
        function methods:WaitForChild(name)
            return assert(self:FindFirstChild(name), name)
        end
        function methods:GetPropertyChangedSignal(name)
            changes[name] = changes[name] or signal()
            return changes[name]
        end
        function methods:Destroy()
            if values.destroyed then
                return
            end
            values.destroyed = true
            events.Destroying:Fire()
            for _, obj in ipairs(self:GetChildren()) do
                obj:Destroy()
            end
            self.Parent = nil
        end
        local obj = setmetatable({}, {
            __index = function(self, key)
                if key == "Parent" then
                    return values.Parent
                end
                if methods[key] then
                    return methods[key]
                end
                if events[key] then
                    return events[key]
                end
                if values[key] ~= nil then
                    return values[key]
                end
                return methods.FindFirstChild(self, key)
            end,
            __newindex = function(_, key, value)
                if key == "Parent" and value and value.Name == "CoreGui" and not coreAllowed then
                    error("模拟 CoreGui 写入受限")
                end
                if values[key] == value then
                    return
                end
                values[key] = value
                if changes[key] then
                    changes[key]:Fire()
                end
            end,
        })
        table.insert(objects, obj)
        if parent then
            obj.Parent = parent
        end
        return obj
    end
    local function named(class, name, parent)
        local obj = new(class, parent)
        obj.Name = name
        return obj
    end
    local core, playerGui, workspace =
        named("Folder", "CoreGui"), named("PlayerGui", "PlayerGui"), named("Folder", "Workspace")
    local char = named("Model", "Character", workspace)
    local root = named("Part", "HumanoidRootPart", char)
    root.CFrame = CF.new(1, 2, 3)
    local player = { Name = "Local", Character = char, PlayerGui = playerGui }
    function player:WaitForChild(name)
        return assert(self[name])
    end
    function player:FindFirstChild(name)
        return self[name]
    end
    local input =
        { InputBegan = signal(), InputChanged = signal(), InputEnded = signal(), WindowFocusReleased = signal() }
    function input:GetFocusedTextBox()
        return self.focused
    end
    local tween = {}
    function tween:Create(obj, _, props)
        return {
            Completed = signal(),
            Play = function()
                for key, value in pairs(props) do
                    obj[key] = value
                end
            end,
        }
    end
    local services = {
        CoreGui = core,
        Players = { LocalPlayer = player },
        TweenService = tween,
        UserInputService = input,
        ReplicatedStorage = named("Folder", "ReplicatedStorage"),
        Workspace = workspace,
    }
    local env = {
        game = {
            GetService = function(_, name)
                return assert(services[name], name)
            end,
        },
        Instance = { new = new },
        Enum = E,
        Vector2 = V2,
        Vector3 = V3,
        Vector3int16 = rb.Vector3int16,
        UDim = rb.UDim,
        UDim2 = U2,
        Color3 = rb.Color3,
        CFrame = CF,
        TweenInfo = {
            new = function()
                return {}
            end,
        },
        task = {
            spawn = function(fn)
                table.insert(jobs, fn)
            end,
            wait = function(t)
                coroutine.yield(t)
            end,
        },
    }
    if promptSupported then
        env.fireproximityprompt = function()
            interactions += 1
            if promptFails then
                error("模拟出售交互失败")
            end
        end
    end
    local state = luau.load(exposed, { environment = env })()
    return {
        state = state,
        objects = objects,
        jobs = jobs,
        new = new,
        named = named,
        env = env,
        player = player,
        core = core,
        playerGui = playerGui,
        workspace = workspace,
        root = root,
        input = input,
        interactions = function()
            return interactions
        end,
        reload = function()
            return luau.load(exposed, { environment = env })()
        end,
    }
end
local function find(f, text)
    for _, obj in ipairs(f.objects) do
        if not obj.destroyed and (obj.Name == text or obj.Text:match("^%s*(.-)%s*$") == text) then
            return obj
        end
    end
    error("控件缺失：" .. text)
end
local function pointer(kind, x, y)
    return { UserInputType = kind, UserInputState = E.UserInputState.Begin, Position = V3.new(x, y, 0) }
end
local function release(f, p)
    p.UserInputState = E.UserInputState.End
    f.input.InputEnded:Fire(p)
end
local function resume(co)
    local ok, err = coroutine.resume(co)
    assert(ok, err)
end

local f = fixture(false, false)
local gui, main, area = find(f, "MrGhost_Template_VIP"), find(f, "MainWindow"), find(f, "SafeArea")
assert(gui.Parent == f.playerGui and main.Visible)
for _, obj in ipairs(f.objects) do
    assert(not obj:IsA("TextBox"), "启动不应创建密钥输入界面")
end
local icon, header = find(f, "👻"), find(f, "DragHeader")
local tap = pointer(E.UserInputType.Touch, 10, 10)
icon.InputBegan:Fire(tap)
release(f, tap)
assert(not main.Visible)
local click = pointer(E.UserInputType.MouseButton1, 10, 10)
icon.InputBegan:Fire(click)
release(f, click)
assert(main.Visible)
local first, other = pointer(E.UserInputType.Touch, 50, 50), pointer(E.UserInputType.Touch, 100, 100)
local original = icon.Position
icon.InputBegan:Fire(first)
icon.InputBegan:Fire(other)
other.Position = V3.new(140, 140, 0)
f.input.InputChanged:Fire(other)
release(f, other)
assert(icon.Position == original)
first.Position = V3.new(90, 50, 0)
f.input.InputChanged:Fire(first)
release(f, first)
assert(icon.Position ~= original and main.Visible, "拖动悬浮图标不应切换菜单")
local start = main.Position
local drag = pointer(E.UserInputType.Touch, 50, 50)
header.InputBegan:Fire(drag)
drag.Position = V3.new(75, 80, 0)
f.input.InputChanged:Fire(drag)
release(f, drag)
assert(main.Position ~= start)
local control = { KeyCode = E.KeyCode.RightControl }
f.input.focused = {}
f.input.InputBegan:Fire(control, false)
assert(main.Visible)
f.input.focused = nil
f.input.InputBegan:Fire(control, false)
assert(not main.Visible)

-- 原生调整窗口尺寸并滚动列表，不缩小按钮字号。
for _, view in ipairs({ { 390, 744 }, { 744, 280 }, { 320, 480 }, { 480, 200 }, { 1920, 1080 } }) do
    area.AbsoluteSize = V2.new(view[1], view[2])
    area:GetPropertyChangedSignal("AbsoluteSize"):Fire()
    local w, h = main.Size.X.Offset, main.Size.Y.Offset
    assert(w <= view[1] - 16 and h <= view[2] - 16)
    local x, y = main.Position.X.Offset - w / 2, main.Position.Y.Offset - h / 2
    assert(x >= 7 and y >= 7 and x + w <= view[1] - 7 and y + h <= view[2] - 7)
end
-- 放大/还原、收起/展开及屏幕旋转不应重置功能状态。
local maximize, minimize = find(f, "放大"), find(f, "收起")
assert(maximize.Size == U2.fromOffset(44, 44) and minimize.Size == U2.fromOffset(44, 44))
assert(maximize.Parent == header.Parent and header.Size.X.Offset == -112, "标题栏按钮与拖动热区应分离")
local reopen = pointer(E.UserInputType.Touch, 10, 10)
icon.InputBegan:Fire(reopen)
release(f, reopen)
assert(main.Visible)
local mine = find(f, "⛏️ 自动挖矿 [关]")
mine.Activated:Fire()
assert(f.state.Settings.AutoMine)
for _, view in ipairs({ { 390, 744 }, { 744, 280 }, { 320, 480 }, { 480, 200 }, { 1920, 1080 } }) do
    area.AbsoluteSize = V2.new(view[1], view[2])
    area:GetPropertyChangedSignal("AbsoluteSize"):Fire()
    local normalSize, normalPosition = main.Size, main.Position
    maximize.Activated:Fire()
    assert(main.Size == U2.fromOffset(view[1] - 16, view[2] - 16) and maximize.Text == "还原")
    local fullSize = main.Size
    minimize.Activated:Fire()
    assert(not main.Visible and f.state.Settings.AutoMine)
    local tapIcon = pointer(E.UserInputType.Touch, 10, 10)
    icon.InputBegan:Fire(tapIcon)
    release(f, tapIcon)
    assert(main.Visible and main.Size == fullSize and maximize.Text == "还原")
    maximize.Activated:Fire()
    assert(main.Size == normalSize and main.Position == normalPosition and maximize.Text == "放大")
    assert(f.state.Settings.AutoMine and mine.Text:find("[开]", 1, true))
end
maximize.Activated:Fire()
area.AbsoluteSize = V2.new(320, 480)
assert(main.Size == U2.fromOffset(304, 464) and maximize.Text == "还原")
minimize.Activated:Fire()
area.AbsoluteSize = V2.new(744, 280)
assert(not main.Visible and main.Size == U2.fromOffset(728, 264))
local rotatedTap = pointer(E.UserInputType.Touch, 10, 10)
icon.InputBegan:Fire(rotatedTap)
release(f, rotatedTap)
maximize.Activated:Fire()
assert(main.Size == U2.fromOffset(440, 264) and maximize.Text == "放大")
local left, top = main.Position.X.Offset - 220, main.Position.Y.Offset - 132
assert(left >= 7 and left + 440 <= 737 and top >= 7 and top + 264 <= 273)
mine.Activated:Fire()
assert(not f.state.Settings.AutoMine)

for _, obj in ipairs(f.objects) do
    if obj:IsA("TextButton") and obj.Parent and obj.Parent:IsA("ScrollingFrame") then
        assert(obj.Size.Y.Offset == 44 and obj.TextSize == 13)
    end
end
local sell = find(f, "💰 自动前往出售 [关]")
sell.Activated:Fire()
assert(not f.state.Settings.AutoSell and sell.Text:find("[关]", 1, true))
local coal = f.named("Part", "Coal", f.workspace)
assert(f.state.OreInfo(coal) == "⬛ 煤炭")
coal.Attributes = { MineId = "Bedrock" }
assert(f.state.OreInfo(coal) == nil)
coal.Name, coal.Attributes = "Block", { MineId = "Copper" }
assert(f.state.OreInfo(coal) == "🟠 铜矿")
coal.Attributes = { OreId = "MysteryOre" }
assert(f.state.OreInfo(coal) == "📦 矿块：MysteryOre")
-- 通知也能在 CoreGui 受限时创建，并在窄屏下保持边距。
local notice = coroutine.create(f.jobs[1])
resume(notice)
local noticeGui = find(f, "MrGhostNotifyGui")
assert(noticeGui.Parent == f.playerGui)
local card = noticeGui:GetChildren()[1]
assert(card.Size.X.Scale == 1 and card.Size.X.Offset == -24 and card.AnchorPoint == V2.new(1, 1))

for _, fails in ipairs({ false, true }) do
    local s = fixture(true, true, fails)
    assert(find(s, "MrGhost_Template_VIP").Parent == s.core)
    local owner = s.named("Folder", s.player.Name, s.workspace)
    local cargo = s.named("Folder", "OrePackCargo", owner)
    for n = 1, 8 do
        s.named("Part", "Ore" .. n, cargo)
    end
    local server = s.named("Folder", "FactoryGridItemsServer", s.workspace)
    local factory = s.named("Folder", "FactoryA", server)
    local volume = s.named("Part", "CargoVolume", factory)
    local prompt = s.named("ProximityPrompt", "CargoPrompt", volume)
    prompt.HoldDuration = 0.75
    local client = s.named("Folder", "FactoryGridItemsClient", s.workspace)
    local clientFactory = s.named("Folder", "FactoryA", client)
    local sub = s.named("Folder", "FactoryA", clientFactory)
    local target = s.named("Part", "CargoVolume", sub)
    target.CFrame = CF.new(100, 5, 10)
    local saved = s.root.CFrame
    local btn = find(s, "💰 自动前往出售 [关]")
    btn.Activated:Fire()
    assert(s.state.Settings.AutoSell and btn.Text:find("[开]", 1, true))
    local worker = coroutine.create(s.jobs[#s.jobs])
    resume(worker)
    assert(s.root.CFrame ~= saved)
    resume(worker)
    if not fails then
        resume(worker)
    end
    assert(s.root.CFrame == saved and prompt.HoldDuration == 0.75 and s.interactions() == 1)
    btn.Activated:Fire()
    assert(not s.state.Settings.AutoSell)
end

find(f, "⛏️ 自动挖矿 [关]").Activated:Fire()
assert(f.state.Settings.AutoMine)
local tag = f.named("BillboardGui", "MrGhost_Tag", coal)
f.state.ActiveESP[1] = tag
local oldState = f.state
f.reload()
assert(gui.destroyed and not oldState.Settings.AutoMine and tag.destroyed and #oldState.ActiveESP == 0)
assert(f.input.InputChanged:Live() == 2, "重载不应遗留旧拖动监听")
print(
    "通过：无密钥启动、中文矿名、放大/还原/收起、悬浮展开、按钮触控、多指拖动、横竖屏、CoreGui 回退、出售失败复位与重载清理"
)
