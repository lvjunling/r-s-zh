-- =====================================================================
-- 键盘逃生 — v0.0.1，作者 Lodar1s
-- 紧凑型跑步机自动移动面板。主开关启用后，每个 Heartbeat 自动向前行走，
-- 并可按设置调用 PersonalTreadmillStep、UpdateSpeed 与 TreadmillSignal。
-- 调试卡片会显示远程对象类型、调用错误数量以及捕获到的参数。
-- 支持关闭、最小化、窗口拖动和触屏拖动。
-- =====================================================================

-- 中文本地化版本：内部远程对象名称保持原值。

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local NAME    = "键盘逃生"
local VERSION = "0.0.1"
local AUTHOR  = "Lodar1s"

-- ===== Palette (как в ui.lua) =====
local T = {
    Bg       = Color3.fromRGB(18, 20, 27),
    Sidebar  = Color3.fromRGB(18, 20, 27),
    Card     = Color3.fromRGB(28, 31, 42),
    CardAlt  = Color3.fromRGB(38, 42, 56),
    Stroke   = Color3.fromRGB(44, 49, 66),
    Accent   = Color3.fromRGB(86, 156, 255),
    AccentDim= Color3.fromRGB(40, 60, 100),
    On       = Color3.fromRGB(54, 200, 150),
    Danger   = Color3.fromRGB(225, 80, 80),
    Text     = Color3.fromRGB(232, 236, 245),
    SubText  = Color3.fromRGB(138, 145, 162),
}

local TW_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_MED  = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ===== Helpers =====
local function corner(inst, r) local c = Instance.new("UICorner", inst); c.CornerRadius = UDim.new(0, r or 8); return c end
local function stroke(inst, color, thick)
    local s = Instance.new("UIStroke", inst)
    s.Color = color or T.Stroke; s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end
local function newText(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextColor3 = T.Text
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

-- ===== MUI-style switch (перенесён из ui.lua) =====
local SW_W, SW_H = 44, 22
local SW_THUMB   = 20
local SW_TRACK_H = 14
local SW_OFF_X   = 12
local SW_ON_X    = SW_W - 12
local SW_THUMB_ON, SW_THUMB_OFF = T.Accent, Color3.fromRGB(240, 242, 248)
local SW_TRACK_ON, SW_TRACK_OFF = T.Accent, Color3.fromRGB(125, 132, 150)

local function makeSwitch(parent, default, onToggle)
    local sw = Instance.new("TextButton", parent)
    sw.Size = UDim2.new(0, SW_W, 0, SW_H)
    sw.BackgroundTransparency = 1
    sw.AutoButtonColor = false
    sw.Text = ""

    local track = Instance.new("Frame", sw)
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.Position = UDim2.new(0.5, 0, 0.5, 0)
    track.Size = UDim2.new(0, SW_W - 8, 0, SW_TRACK_H)
    track.BackgroundColor3 = default and SW_TRACK_ON or SW_TRACK_OFF
    track.BackgroundTransparency = 0.55
    track.ZIndex = 1
    corner(track, math.floor(SW_TRACK_H / 2))

    local shadow = Instance.new("Frame", sw)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Size = UDim2.new(0, SW_THUMB, 0, SW_THUMB)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.78
    shadow.ZIndex = 2
    corner(shadow, math.floor(SW_THUMB / 2))

    local thumb = Instance.new("Frame", sw)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Size = UDim2.new(0, SW_THUMB, 0, SW_THUMB)
    thumb.BackgroundColor3 = default and SW_THUMB_ON or SW_THUMB_OFF
    thumb.ZIndex = 3
    corner(thumb, math.floor(SW_THUMB / 2))

    local state = default
    local function apply(animate)
        local tx = state and SW_ON_X or SW_OFF_X
        local thumbGoal  = UDim2.new(0, tx, 0.5, 0)
        local shadowGoal = UDim2.new(0, tx, 0.5, 1)
        local thumbCol = state and SW_THUMB_ON or SW_THUMB_OFF
        local trackCol = state and SW_TRACK_ON or SW_TRACK_OFF
        if animate then
            TweenService:Create(thumb,  TW_FAST, { Position = thumbGoal, BackgroundColor3 = thumbCol }):Play()
            TweenService:Create(shadow, TW_FAST, { Position = shadowGoal }):Play()
            TweenService:Create(track,  TW_FAST, { BackgroundColor3 = trackCol }):Play()
        else
            thumb.Position = thumbGoal; thumb.BackgroundColor3 = thumbCol
            shadow.Position = shadowGoal
            track.BackgroundColor3 = trackCol
        end
    end
    apply(false)

    sw.MouseButton1Click:Connect(function()
        state = not state
        apply(true)
        onToggle(state)
    end)

    return {
        Btn = sw,
        Set = function(v) if v ~= state then state = v; apply(true) end end,
        Get = function() return state end,
    }
end

-- =====================================================================
-- Логика спама ремоута
-- =====================================================================
local WalkSpam = {}
WalkSpam.enabled = false
WalkSpam.sent    = 0
local heartbeatConn = nil

-- Кэшируем ремоуты заранее, чтобы вызов стоил максимально дёшево.
-- ГЛАВНЫЙ ремоут прогресса на дорожке = PersonalTreadmillStep (без аргументов):
-- именно его игра сама спамит на каждый шаг (видно в SimpleSpy). Прежние два
-- (UpdateSpeed/TreadmillSignal) прогресс НЕ двигают — оставлены для отладки.
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local stepRemote      = Remotes:WaitForChild("PersonalTreadmillStep")
local speedRemote     = Remotes:WaitForChild("UpdateSpeed")
local treadmillRemote = Remotes:WaitForChild("TreadmillSignal")

-- Аргументы задаём таблицей (unpack в момент вызова). {} = без аргументов.
local STEP_ARGS      = {}          -- PersonalTreadmillStep:FireServer()
local WALK_ARGS      = { "Walking" }
local TREADMILL_ARGS = { false }

-- Авто-ходьба напрямую через Humanoid:Move(). Работает и на мобиле/эмуляторе
-- (LDPlayer), где нет клавиши W — движение идёт тач-джойстиком, а Move()
-- дёргает персонажа в обход схемы ввода. Клавишу слать бесполезно: мобильный
-- Roblox её не слушает (её мапит сам эмулятор поверх игры).
local LP = Players.LocalPlayer
local function getHumanoid()
    local ch = LP.Character
    return ch and ch:FindFirstChildOfClass("Humanoid"), ch
end

-- Направление «вперёд»: куда смотрит камера, спроецированное на землю.
local function walkForward()
    local hum, ch = getHumanoid()
    if not hum then return end
    local cam = workspace.CurrentCamera
    local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
    local dir = Vector3.new(look.X, 0, look.Z)
    if dir.Magnitude < 0.01 then return end
    hum:Move(dir.Unit, false)   -- false = мировые координаты
end

-- Управление источниками (для отладки: можно включить/выключить любой).
WalkSpam.autoWalk     = true       -- ГЛАВНЫЙ: авто-ходьба вперёд (Humanoid:Move)
WalkSpam.useStep      = false      -- спам ремоутов (сервер, похоже, игнорит)
WalkSpam.useSpeed     = false
WalkSpam.useTreadmill = false

-- ===== Ускорители (byepass-попытки, подбирать аккуратно) =====
-- 1) WalkSpeed boost: насильно держим Humanoid.WalkSpeed = N каждый кадр
--    (игра может сбрасывать — поэтому переписываем постоянно). 16 = дефолт.
WalkSpam.boostSpeed   = 0          -- 0 = не трогать WalkSpeed
-- 2) CFrame step: микро-телепорт вперёд на N студов/сек поверх ходьбы.
--    Чем больше — тем быстрее, но тем выше шанс отката анти-читом.
WalkSpam.cframeStep   = 0          -- студов в секунду, 0 = выкл

local function applyBoosts(dt)
    local hum, ch = getHumanoid()
    if not hum then return end
    -- WalkSpeed
    if WalkSpam.boostSpeed > 0 and hum.WalkSpeed ~= WalkSpam.boostSpeed then
        hum.WalkSpeed = WalkSpam.boostSpeed
    end
    -- CFrame шаг вперёд (по направлению камеры, по земле)
    if WalkSpam.cframeStep > 0 then
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if hrp and cam then
            local look = cam.CFrame.LookVector
            local dir = Vector3.new(look.X, 0, look.Z)
            if dir.Magnitude > 0.01 then
                hrp.CFrame = hrp.CFrame + dir.Unit * (WalkSpam.cframeStep * dt)
            end
        end
    end
end

-- Диагностика — заполняется в рантайме и показывается в debug-карточке.
local DBG = {
    stepClass  = stepRemote.ClassName,
    speedClass = speedRemote.ClassName,
    treadClass = treadmillRemote.ClassName,
    errCount   = 0,
    lastErr    = "",
    hookArgs   = "",   -- последние пойманные аргументы PersonalTreadmillStep
}

-- ===== Hook-спай (__namecall): ловим РЕАЛЬНЫЕ аргументы, которые игра шлёт
-- в PersonalTreadmillStep при легальной ходьбе. Одноразовая установка.
local hookInstalled = false
local function installHook()
    if hookInstalled then return true end
    if not (getrawmetatable and setreadonly and getnamecallmethod) then
        DBG.hookArgs = "Hook：当前执行环境缺少所需接口"
        return false
    end
    local ok, err = pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = (newcclosure or function(f) return f end)(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and not checkcaller()
                and typeof(self) == "Instance" and self.Name == "PersonalTreadmillStep" then
                local args = { ... }
                local parts = {}
                for i, v in ipairs(args) do
                    parts[#parts + 1] = typeof(v) .. "=" .. tostring(v)
                end
                DBG.hookArgs = #parts > 0 and table.concat(parts, ", ") or "（无参数）"
                -- дублируем в консоль (F9), чтобы видеть даже при выключенном Spam
                print("[KeyboardEscape] Step:FireServer ->", DBG.hookArgs)
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
    if not ok then
        DBG.hookArgs = "Hook 错误：" .. tostring(err)
        return false
    end
    hookInstalled = true
    DBG.hookArgs = "Hook 已就绪，请手动行走以捕获参数"
    return true
end

-- Универсальный вызов: RemoteEvent → FireServer, RemoteFunction → InvokeServer.
-- Всё в pcall, чтобы поймать серверные ошибки (иначе они молча теряются).
local function invoke(rem, args)
    local cls = rem.ClassName
    local ok, err
    if cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" then
        ok, err = pcall(rem.FireServer, rem, table.unpack(args))
    elseif cls == "RemoteFunction" then
        -- InvokeServer yield-ит: гоняем в отдельном потоке, чтобы не морозить цикл.
        task.spawn(function() pcall(rem.InvokeServer, rem, table.unpack(args)) end)
        ok = true
    else
        ok, err = false, "未知对象类型：" .. cls
    end
    if not ok then
        DBG.errCount = DBG.errCount + 1
        DBG.lastErr = tostring(err)
    end
    return ok
end

-- Интервал между отправками в секундах. 0 = каждый кадр (максимум).
-- Если сервер режет слишком быстрый темп шагов — увеличиваем интервал.
WalkSpam.interval = 0

local function startSpam(onTick)
    if heartbeatConn then return end
    -- Heartbeat идёт каждый кадр, но реально шлём не чаще, чем раз в interval.
    -- Аккумулируем dt: так частота не зависит от FPS и легко регулируется.
    local acc = 0
    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        -- Авто-ходьба — каждый кадр (Move нужно вызывать непрерывно).
        if WalkSpam.autoWalk then
            local ok, err = pcall(walkForward)
            if not ok then DBG.errCount = DBG.errCount + 1; DBG.lastErr = "移动：" .. tostring(err) end
        end
        do
            local ok, err = pcall(applyBoosts, dt)
            if not ok then DBG.errCount = DBG.errCount + 1; DBG.lastErr = "加速：" .. tostring(err) end
        end
        -- Спам ремоутов — по выбранной частоте.
        acc = acc + dt
        if acc < WalkSpam.interval then return end
        acc = 0
        if WalkSpam.useStep      then invoke(stepRemote, STEP_ARGS) end
        if WalkSpam.useSpeed     then invoke(speedRemote, WALK_ARGS) end
        if WalkSpam.useTreadmill then invoke(treadmillRemote, TREADMILL_ARGS) end
        WalkSpam.sent = WalkSpam.sent + 1
        if onTick then onTick(WalkSpam.sent, DBG) end
    end)
end

local function stopSpam()
    if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
end

-- =====================================================================
-- UI
-- =====================================================================
local player   = Players.LocalPlayer
local uiParent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
if uiParent:FindFirstChild("KeyboardEscapeUI") then uiParent.KeyboardEscapeUI:Destroy() end
stopSpam()

local ScreenGui = Instance.new("ScreenGui", uiParent)
ScreenGui.Name = "KeyboardEscapeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

-- ===== Main window =====
local Main = Instance.new("Frame", ScreenGui)
Main.Name = "MainFrame"
Main.BackgroundColor3 = T.Bg
Main.Size = UDim2.new(0, 320, 0, 592)
Main.Position = UDim2.new(0.5, -160, 0.5, -296)
Main.ClipsDescendants = true
corner(Main, 16)
local mainStroke = stroke(Main, T.Stroke, 1)

local isMinimized = false
local minimizeUI, expandUI

-- entrance animation
Main.Size = UDim2.new(0, 300, 0, 340)
TweenService:Create(Main, TW_MED, { Size = UDim2.new(0, 320, 0, 592) }):Play()

-- ===== Header =====
local Header = Instance.new("Frame", Main)
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 52)

-- маленький логотип-квадрат
local Logo = Instance.new("TextLabel", Header)
Logo.BackgroundColor3 = T.Accent
Logo.Position = UDim2.new(0, 16, 0, 11)
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Font = Enum.Font.GothamBlack
Logo.Text = "K"
Logo.TextSize = 16
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
Logo.TextXAlignment = Enum.TextXAlignment.Center
corner(Logo, 9)

local HTitle = newText(Header, {
    Position = UDim2.new(0, 56, 0, 9), Size = UDim2.new(1, -140, 0, 20),
    Font = Enum.Font.GothamBold, Text = NAME, TextSize = 16,
})
local HSub = newText(Header, {
    Position = UDim2.new(0, 56, 0, 29), Size = UDim2.new(1, -140, 0, 15),
    Text = "跑步机自动移动", TextSize = 11, TextColor3 = T.SubText,
})

-- Close (X) / Minimize (_)
local function hdrCtrl(symbol, color, xOffset, onClick)
    local b = Instance.new("TextButton", Header)
    b.BackgroundTransparency = 1
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, xOffset, 0.5, 0)
    b.Size = UDim2.new(0, 22, 0, 22)
    b.Font = Enum.Font.GothamBold
    b.Text = symbol
    b.TextSize = 15
    b.TextColor3 = color
    b.AutoButtonColor = false
    b.ZIndex = 5
    b.MouseEnter:Connect(function() TweenService:Create(b, TW_FAST, { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TW_FAST, { TextColor3 = color }):Play() end)
    b.MouseButton1Click:Connect(onClick)
    return b
end
hdrCtrl("X", T.Danger, -12, function()
    stopSpam()
    ScreenGui:Destroy()
end)
hdrCtrl("_", T.SubText, -38, function() minimizeUI() end)

-- divider
local divLine = Instance.new("Frame", Main)
divLine.BackgroundColor3 = T.Stroke
divLine.BorderSizePixel = 0
divLine.Position = UDim2.new(0, 0, 0, 52)
divLine.Size = UDim2.new(1, 0, 0, 1)

-- ===== Content =====
local Content = Instance.new("Frame", Main)
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 53)
Content.Size = UDim2.new(1, 0, 1, -75)

local list = Instance.new("UIListLayout", Content)
list.Padding = UDim.new(0, 12)
list.SortOrder = Enum.SortOrder.LayoutOrder
local cpad = Instance.new("UIPadding", Content)
cpad.PaddingTop = UDim.new(0, 14); cpad.PaddingLeft = UDim.new(0, 16)
cpad.PaddingRight = UDim.new(0, 16)

-- карточка
local function makeCard(order)
    local card = Instance.new("Frame", Content)
    card.LayoutOrder = order
    card.BackgroundColor3 = T.Card
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    corner(card, 12)
    stroke(card, T.Stroke, 1)
    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
    local lay = Instance.new("UIListLayout", card)
    lay.Padding = UDim.new(0, 10)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    return card
end

-- ===== Toggle card =====
local mainCard = makeCard(1)
local row = Instance.new("Frame", mainCard)
row.BackgroundTransparency = 1
row.Size = UDim2.new(1, 0, 0, 44)

local dot = Instance.new("Frame", row)
dot.BackgroundColor3 = T.Danger
dot.Position = UDim2.new(0, 0, 0, 6)
dot.Size = UDim2.new(0, 12, 0, 12)
corner(dot, 6)

local statusText = newText(row, {
    Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -80, 0, 20),
    Font = Enum.Font.GothamSemibold, Text = "运行状态：关闭", TextSize = 15, TextColor3 = T.Danger,
})
local sentText = newText(row, {
    Position = UDim2.new(0, 24, 0, 22), Size = UDim2.new(1, -80, 0, 16),
    Text = "循环次数：0", TextSize = 11, TextColor3 = T.SubText,
})

local function setStatus(on)
    if on then
        statusText.Text = "运行状态：开启"; statusText.TextColor3 = T.On
        TweenService:Create(dot, TW_FAST, { BackgroundColor3 = T.On }):Play()
    else
        statusText.Text = "运行状态：关闭"; statusText.TextColor3 = T.Danger
        TweenService:Create(dot, TW_FAST, { BackgroundColor3 = T.Danger }):Play()
    end
end

local refreshDebug  -- fwd

local walkSwitch
walkSwitch = makeSwitch(row, false, function(state)
    WalkSpam.enabled = state
    setStatus(state)
    if state then
        WalkSpam.sent = 0
        DBG.errCount = 0; DBG.lastErr = ""
        startSpam(function(n) sentText.Text = "循环次数：" .. n; if refreshDebug then refreshDebug() end end)
    else
        stopSpam()
    end
end)
walkSwitch.Btn.AnchorPoint = Vector2.new(1, 0.5)
walkSwitch.Btn.Position = UDim2.new(1, 0, 0.5, 0)

newText(mainCard, {
    LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 16),
    Text = '自动向前行走（Humanoid:Move，适用于手机和模拟器）', TextSize = 10,
    Font = Enum.Font.GothamMedium, TextColor3 = T.SubText,
})

-- ===== DEBUG card =====
local dbgCard = makeCard(2)
newText(dbgCard, {
    LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16),
    Font = Enum.Font.GothamBold, Text = "调试信息", TextSize = 12, TextColor3 = T.Accent,
})

-- независимые переключатели ремоутов
local function dbgToggleRow(order, title, default, onToggle)
    local r = Instance.new("Frame", dbgCard)
    r.LayoutOrder = order
    r.BackgroundTransparency = 1
    r.Size = UDim2.new(1, 0, 0, 24)
    newText(r, {
        Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(1, -54, 0, 20),
        Font = Enum.Font.GothamMedium, Text = title, TextSize = 12,
    })
    local sw = makeSwitch(r, default, onToggle)
    sw.Btn.AnchorPoint = Vector2.new(1, 0.5)
    sw.Btn.Position = UDim2.new(1, 0, 0.5, 0)
    return sw
end
dbgToggleRow(2, "自动行走（Humanoid:Move）", true, function(s) WalkSpam.autoWalk = s end)
dbgToggleRow(3, "PersonalTreadmillStep", false, function(s) WalkSpam.useStep = s end)
dbgToggleRow(4, "更新速度（行走）", false, function(s) WalkSpam.useSpeed = s end)
dbgToggleRow(4.5, "跑步机信号（false）", false, function(s) WalkSpam.useTreadmill = s end)
dbgToggleRow(4.7, "Hook 监视（捕获参数）", false, function(s) if s then installHook() end end)

-- ===== Ряды пресетов (общий конструктор): подпись + кнопки-значения =====
local function makePresetRow(orderLabel, orderRow, label, presets, current, onSelect)
    newText(dbgCard, {
        LayoutOrder = orderLabel, Size = UDim2.new(1, 0, 0, 14),
        Text = label, TextSize = 11, TextColor3 = T.SubText,
    })
    local rowF = Instance.new("Frame", dbgCard)
    rowF.LayoutOrder = orderRow
    rowF.BackgroundTransparency = 1
    rowF.Size = UDim2.new(1, 0, 0, 26)
    local lay = Instance.new("UIListLayout", rowF)
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Padding = UDim.new(0, 5)

    local buttons = {}
    local function select(value)
        onSelect(value)
        for _, b in ipairs(buttons) do
            local active = (b:GetAttribute("Value") == value)
            b.BackgroundColor3 = active and T.Accent or T.CardAlt
            b.TextColor3 = active and Color3.fromRGB(255, 255, 255) or T.SubText
        end
    end
    for i, preset in ipairs(presets) do
        local b = Instance.new("TextButton", rowF)
        b.Size = UDim2.new(0, 50, 1, 0)
        b.BackgroundColor3 = T.CardAlt
        b.Font = Enum.Font.GothamBold
        b.Text = preset[1]
        b.TextSize = 11
        b.TextColor3 = T.SubText
        b.AutoButtonColor = false
        b:SetAttribute("Value", preset[2])
        corner(b, 7)
        b.MouseButton1Click:Connect(function() select(preset[2]) end)
        buttons[i] = b
    end
    select(current)
end

-- Частота отправки ремоутов (0 = каждый кадр)
makePresetRow(5, 5.1, "发送频率：", {
    { "最高", 0 }, { "30/s", 1/30 }, { "20/s", 1/20 }, { "10/s", 1/10 }, { "5/s", 1/5 },
}, WalkSpam.interval, function(v) WalkSpam.interval = v end)

-- WalkSpeed boost (0 = не трогать, 16 = дефолт Roblox).
-- Фарм скейлится именно от WalkSpeed (подтверждено тестами), поэтому
-- пресеты агрессивные — ищем серверный потолок.
makePresetRow(5.2, 5.3, "行走速度：", {
    { "关闭", 0 }, { "100", 100 }, { "500", 500 }, { "2k", 2000 }, { "10k", 10000 },
}, WalkSpam.boostSpeed, function(v) WalkSpam.boostSpeed = v end)

-- CFrame step, студов/сек (0 = выкл) — микро-телепорт вперёд поверх ходьбы
makePresetRow(5.4, 5.5, "CFrame 位移：", {
    { "关闭", 0 }, { "8", 8 }, { "16", 16 }, { "32", 32 }, { "64", 64 },
}, WalkSpam.cframeStep, function(v) WalkSpam.cframeStep = v end)

local dbgInfo = newText(dbgCard, {
    LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    Font = Enum.Font.Code, TextSize = 11, TextColor3 = T.SubText, TextWrapped = true,
    Text = "",
})

refreshDebug = function()
    local errLine = DBG.errCount > 0
        and string.format("错误：%d  最近错误：%s", DBG.errCount, DBG.lastErr)
        or "错误：0（未抛出异常）"
    local hookLine = DBG.hookArgs ~= "" and ("\nHook：" .. DBG.hookArgs) or ""
    dbgInfo.Text = string.format(
        "步进：%s | 速度：%s | 跑步机：%s\n%s%s",
        DBG.stepClass, DBG.speedClass, DBG.treadClass, errLine, hookLine)
    dbgInfo.TextColor3 = DBG.errCount > 0 and T.Danger or T.SubText
end
refreshDebug()

-- Debug-строка обновляется сама (2 р/с), даже если главный Spam выключен —
-- иначе hook spy нечем было бы показать пойманные аргументы.
task.spawn(function()
    while ScreenGui.Parent do
        refreshDebug()
        task.wait(0.5)
    end
end)

-- ===== Footer =====
local accentHex = string.format("rgb(%d,%d,%d)",
    math.floor(T.Accent.R * 255), math.floor(T.Accent.G * 255), math.floor(T.Accent.B * 255))
newText(Main, {
    Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, -14, 0, 18),
    RichText = true,
    Text = '<font color="' .. accentHex .. '">' .. string.upper(NAME) .. ' ' .. VERSION .. '</font>  •  作者：' .. AUTHOR,
    TextSize = 11, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center,
    Font = Enum.Font.GothamMedium,
})

-- ===== Drag через header =====
do
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- ===== Свернуть / развернуть =====
-- В свёрнутом виде остаётся кружок-логотип: тап — развернуть, drag — таскать.
local miniBtn = Instance.new("TextButton", Main)
miniBtn.BackgroundColor3 = T.Accent
miniBtn.AnchorPoint = Vector2.new(0.5, 0.5)
miniBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
miniBtn.Size = UDim2.new(0, 44, 0, 44)
miniBtn.Font = Enum.Font.GothamBlack
miniBtn.Text = "K"
miniBtn.TextSize = 20
miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.AutoButtonColor = false
miniBtn.Visible = false
miniBtn.ZIndex = 20
corner(miniBtn, 12)

minimizeUI = function()
    isMinimized = true
    Header.Visible = false
    divLine.Visible = false
    Content.Visible = false
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 56, 0, 56) }):Play()
    task.delay(0.22, function()
        Main.BackgroundTransparency = 1
        mainStroke.Transparency = 1
        miniBtn.Visible = true
    end)
end

expandUI = function()
    isMinimized = false
    miniBtn.Visible = false
    Main.BackgroundTransparency = 0
    mainStroke.Transparency = 0
    Header.Visible = true
    divLine.Visible = true
    Content.Visible = true
    TweenService:Create(Main, TW_MED, { Size = UDim2.new(0, 320, 0, 592) }):Play()
end

-- miniBtn: клик — развернуть, drag — перетаскивание
do
    local mbDragging, mbStart, mbStartPos, mbDist = false, nil, nil, 0
    miniBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            mbDragging = true; mbDist = 0
            mbStart = inp.Position; mbStartPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not mbDragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - mbStart
            mbDist = d.Magnitude
            if mbDist > 4 then
                Main.Position = UDim2.new(mbStartPos.X.Scale, mbStartPos.X.Offset + d.X,
                    mbStartPos.Y.Scale, mbStartPos.Y.Offset + d.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and mbDragging then
            mbDragging = false
            if mbDist <= 4 then expandUI() end
        end
    end)
end
