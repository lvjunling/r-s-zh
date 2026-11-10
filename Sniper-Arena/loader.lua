-- 狙击竞技场 · 简体中文 / PC 与触屏适配
-- 手机：点悬浮按钮保持瞄准；飞行使用摇杆及升降按钮；PC 保留右键和 WASD。
--[[
    ELITE SCRIPTS  ·  SNIPER ARENA
    Fluent UI — compact, dense, customizable accent
    AIM · Silent · Triggerbot · ESP (box/skel/tracer/name/dist/health)
    Bullet tracers · Hitbox · Crosshair · FOV rainbow
    Rage (fly/noclip/speed/infjump) · FullBright · NoFog · FPS
    No Recoil / No Spread · Config presets · Discord LED
    Customize tab — full accent color control
    Keyless · UNC universal
    Place focus: Sniper Arena (9D GAME CLUB)
]]

-- ======================== UNC / EXECUTOR COMPAT ========================
local function safeHttpGet(url)
    local ok, res = pcall(function()
        if syn and syn.request then
            local r = syn.request({Url = url, Method = "GET"})
            return r.Body
        elseif http and http.request then
            local r = http.request({Url = url, Method = "GET"})
            return r.Body
        elseif request then
            local r = request({Url = url, Method = "GET"})
            return r.Body
        elseif http_request then
            local r = http_request({Url = url, Method = "GET"})
            return r.Body
        elseif fluxus and fluxus.request then
            local r = fluxus.request({Url = url, Method = "GET"})
            return r.Body
        else
            return game:HttpGet(url)
        end
    end)
    if ok and res then return res end
    return game:HttpGet(url)
end

local Fluent = loadstring(safeHttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(safeHttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(safeHttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

if not Drawing then
    pcall(function() Drawing = getgenv().Drawing or Drawing end)
end
if not Drawing then
    warn("[ELITE SCRIPTS] 执行器缺少 Drawing：透视、范围圆和自定义准星暂不可用，其他功能仍可使用。")
end

local function safeDrawing(class)
    if not Drawing then return nil end
    local ok, obj = pcall(function() return Drawing.new(class) end)
    if ok then return obj end
    return nil
end

local function safeMousemove(x, y)
    if mousemoverel then
        pcall(mousemoverel, x, y)
    elseif Input and Input.MouseMove then
        pcall(Input.MouseMove, x, y)
    end
end

-- ======================== SERVICES ========================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ======================== CROSS-PLATFORM INPUT ========================
local function usingTouch()
    return UserInputService.TouchEnabled
        and UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

local function getAimPoint()
    if usingTouch() then return Camera.ViewportSize / 2 end
    return UserInputService:GetMouseLocation()
end

local function safeMouse1Click()
    if not usingTouch() then
        if type(mouse1click) == "function" then
            if pcall(mouse1click) then return true end
        elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
            local pressed = pcall(mouse1press)
            task.wait(0.02)
            local released = pcall(mouse1release)
            if pressed and released then return true end
        end
    end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local ok = pcall(function() tool:Activate() end)
    if ok then
        task.delay(0.02, function()
            if tool.Parent then pcall(function() tool:Deactivate() end) end
        end)
    end
    return ok
end

-- ======================== SETTINGS ========================
local S = {
    Aimbot        = false,
    SilentAim     = false,
    Triggerbot    = false,
    AlwaysOn      = false,
    AimKey        = Enum.UserInputType.MouseButton2,
    FOV           = 120,
    Smoothness    = 0.10,
    AimPart       = "Head",
    TeamCheck     = true,
    WallCheck     = true,
    Prediction    = true,
    PredMult      = 0.08,
    ShowFOV       = true,
    FOVColor      = Color3.fromRGB(180, 80, 255),
    FOVRainbow    = false,
    AimMethod     = "Camera",
    TargetBots    = true,
    AccentColor   = Color3.fromRGB(188, 78, 255),

    ESP           = true,
    Box           = true,
    Skeleton      = true,
    Tracer        = true,
    Name          = true,
    Distance      = true,
    Health        = true,
    ESPTeamCheck  = true,
    ShowBots      = true,
    MaxDist       = 2500,
    BoxColor      = Color3.fromRGB(188, 78, 255),
    SkelColor     = Color3.fromRGB(210, 120, 255),
    TracerColor   = Color3.fromRGB(160, 60, 240),
    NameColor     = Color3.fromRGB(240, 230, 255),
    BotColor      = Color3.fromRGB(80, 180, 255),

    BulletTracer  = true,
    BulletColor   = Color3.fromRGB(255, 90, 220),
    BulletThick   = 2.0,
    BulletLife    = 1.2,
    BulletMaxDist = 2000,

    Hitbox        = false,
    HitboxSize    = 6,
    Crosshair     = false,
    CrosshairSize = 10,
    CrosshairColor= Color3.fromRGB(255, 80, 220),

    Fly           = false,
    FlySpeed      = 70,
    Noclip        = false,
    Speed         = false,
    WalkSpeed     = 24,
    InfiniteJump  = false,

    FullBright    = false,
    NoFog         = false,
    CustomFOV     = false,
    CamFOV        = 90,

    FPSUnlock     = false,
    AutoReload    = false,
    NoRecoil      = false,
    NoSpread      = false,
    InstantScope  = false,

    DiscordLED       = true,
    DiscordLEDColor  = Color3.fromRGB(188, 78, 255),
    DiscordLink      = "https://discord.gg/JyHTa3M7h",

    AutoReattach  = true,
}

-- ======================== STATE ========================
local HoldingAim = false
local Touch = {Aim = false}
if UserInputService.TouchEnabled then
    task.spawn(function()
        local ok, controls = pcall(function()
            local scripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
            local module = scripts and scripts:WaitForChild("PlayerModule", 5)
            if module then return require(module):GetControls() end
        end)
        if ok and type(controls) == "table" and type(controls.GetMoveVector) == "function" then
            Touch.Controls = controls
        end
    end)
end
local refreshTouchControls = function() end
local espCache   = {}
local bullets    = {}
local flyBV, flyBG
local origAmbient, origBrightness, origFog, origCamFOV
local crossLines = {}
local lastTrigger = 0

local FOVCircle = safeDrawing("Circle")
if FOVCircle then
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1.4
    FOVCircle.Filled = false
    FOVCircle.NumSides = 64
    FOVCircle.Transparency = 0.75
    FOVCircle.Color = S.FOVColor
    FOVCircle.Radius = S.FOV
end

local DiscordLEDGlow = safeDrawing("Text")
local DiscordLEDText = safeDrawing("Text")
local DiscordLEDLine = safeDrawing("Line")
if DiscordLEDGlow then
    DiscordLEDGlow.Text = "discord.gg/JyHTa3M7h"
    DiscordLEDGlow.Size = 13
    DiscordLEDGlow.Center = true
    DiscordLEDGlow.Outline = false
    DiscordLEDGlow.Color = S.DiscordLEDColor
    DiscordLEDGlow.Transparency = 0.72
    DiscordLEDGlow.Visible = S.DiscordLED
end
if DiscordLEDText then
    DiscordLEDText.Text = "discord.gg/JyHTa3M7h"
    DiscordLEDText.Size = 12
    DiscordLEDText.Center = true
    DiscordLEDText.Outline = true
    DiscordLEDText.Color = S.DiscordLEDColor
    DiscordLEDText.Transparency = 1
    DiscordLEDText.Visible = S.DiscordLED
end
if DiscordLEDLine then
    DiscordLEDLine.Thickness = 1
    DiscordLEDLine.Color = S.DiscordLEDColor
    DiscordLEDLine.Transparency = 0.6
    DiscordLEDLine.Visible = S.DiscordLED
end

for i = 1, 4 do
    local ln = safeDrawing("Line")
    if ln then
        ln.Thickness = 1.5
        ln.Color = S.CrosshairColor
        ln.Transparency = 1
        ln.Visible = false
        crossLines[i] = ln
    end
end

local flyHumanoid, savedPlatformStand
local function setFly(enabled, char)
    S.Fly = enabled
    Touch.Up, Touch.Down = nil, nil
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if flyHumanoid and flyHumanoid.Parent then
        flyHumanoid.PlatformStand = savedPlatformStand
    end
    flyHumanoid = nil
    char = char or LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if enabled and hrp and hum then
        flyHumanoid, savedPlatformStand = hum, hum.PlatformStand
        hum.PlatformStand = true
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.P = 9e4
        flyBG.Parent = hrp
    end
    refreshTouchControls()
end

-- ======================== FLUENT LOCALIZATION ========================
do
    local translations = {
        ["Interface"] = "界面",
        ["Configuration"] = "配置管理",
        ["Config name"] = "配置名称",
        ["Config list"] = "配置列表",
        ["Create config"] = "创建配置",
        ["Load config"] = "加载配置",
        ["Overwrite config"] = "覆盖配置",
        ["Refresh list"] = "刷新列表",
        ["Set as autoload"] = "设为自动加载",
        ["Current autoload config: none"] = "当前自动加载配置：无",
        ["Theme"] = "界面主题",
        ["Changes the interface theme."] = "切换界面的配色主题。",
        ["Acrylic"] = "背景模糊",
        ["The blurred background requires graphic quality 8+"] = "背景模糊需要图像质量达到 8 级或以上。",
        ["Transparency"] = "透明度",
        ["Makes the interface transparent."] = "切换界面的透明效果。",
        ["Minimize Bind"] = "最小化快捷键",
        ["Config loader"] = "配置加载器",
        ["Invalid config name (empty)"] = "配置名称不应为空。",
        ["Callback error"] = "回调执行出错",
        ["Close"] = "关闭",
        ["Yes"] = "是",
        ["No"] = "否",
        ["Are you sure you want to unload the interface?"] = "确定要关闭此界面吗？",
        ["LeftControl"] = "左 Ctrl",
        ["RightControl"] = "右 Ctrl",
        ["LeftShift"] = "左 Shift",
        ["RightShift"] = "右 Shift",
        ["Confirm"] = "确认",
        ["Cancel"] = "取消",
        ["Search"] = "搜索",
        ["Search..."] = "搜索…",
        ["Done"] = "完成",
        ["Are you sure?"] = "确定吗？",
        ["You can press LeftControl to toggle the interface."] = "按左 Ctrl 显示或隐藏界面。",
        ["Head"] = "头部",
        ["UpperTorso"] = "上半身",
        ["HumanoidRootPart"] = "角色根部",
        ["LowerTorso"] = "下半身",
        ["Torso"] = "躯干",
        ["Camera"] = "镜头",
        ["Mouse"] = "鼠标（PC）",
        ["Dark"] = "深色",
        ["Darker"] = "暗黑",
        ["Light"] = "浅色",
        ["Aqua"] = "水蓝",
        ["Amethyst"] = "紫晶",
        ["Rose"] = "玫瑰红",
    }
    local prefixes = {
        ["Current autoload config: "] = "当前自动加载配置：",
        ["Failed to load autoload config: "] = "自动加载配置失败：",
        ["Auto loaded config "] = "已自动加载配置：",
        ["Failed to save config: "] = "保存配置失败：",
        ["Created config "] = "已创建配置：",
        ["Failed to load config: "] = "加载配置失败：",
        ["Loaded config "] = "已加载配置：",
        ["Failed to overwrite config: "] = "覆盖配置失败：",
        ["Overwrote config "] = "已覆盖配置：",
    }
    local hooked = setmetatable({}, {__mode = "k"})
    local function hook(obj)
        if hooked[obj] then return end
        local property
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            property = "Text"
        elseif obj:IsA("TextBox") then
            property = "PlaceholderText"
        else
            return
        end
        hooked[obj] = true
        local applying = false
        local function apply()
            if applying then return end
            local text = obj[property]
            local translated = translations[text]
            local name = text:match('^Set (.+) to auto load$')
            if name then translated = "已将 " .. name .. " 设为自动加载" end
            local key = text:match('^Press (.+) to toggle the interface%.$')
            if key then translated = "按 " .. (translations[key] or key) .. " 显示或隐藏界面。" end
            if not translated then
                for prefix, replacement in pairs(prefixes) do
                    if text:sub(1, #prefix) == prefix then
                        translated = replacement .. text:sub(#prefix + 1)
                        break
                    end
                end
            end
            if translated and translated ~= text then
                applying = true
                obj[property] = translated
                applying = false
            end
        end
        apply()
        obj:GetPropertyChangedSignal(property):Connect(apply)
    end
    Fluent.GUI.DescendantAdded:Connect(function(obj) task.defer(hook, obj) end)
    for _, obj in ipairs(Fluent.GUI:GetDescendants()) do hook(obj) end
end

-- ======================== FLUENT WINDOW ========================
local Window = Fluent:CreateWindow({
    Title = "ELITE SCRIPTS",
    SubTitle = "狙击竞技场",
    TabWidth = 140,
    Size = UDim2.fromOffset(520, 420),
    Acrylic = not UserInputService.TouchEnabled,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Home       = Window:AddTab({ Title = "首页", Icon = "home" }),
    Aim        = Window:AddTab({ Title = "瞄准", Icon = "crosshair" }),
    Visuals    = Window:AddTab({ Title = "视觉", Icon = "eye" }),
    Player     = Window:AddTab({ Title = "玩家", Icon = "user" }),
    Weapons    = Window:AddTab({ Title = "武器", Icon = "swords" }),
    Customize  = Window:AddTab({ Title = "外观", Icon = "palette" }),
    Misc       = Window:AddTab({ Title = "其他", Icon = "settings" }),
    About      = Window:AddTab({ Title = "关于", Icon = "info" }),
}

local Options = Fluent.Options

-- ======================== MOBILE UI ========================
do
    local gui = Instance.new("ScreenGui")
    gui.Name = "EliteSniperTouchControls"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = Fluent.GUI.DisplayOrder + 1
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local area = Instance.new("Frame")
    area.Name = "SafeArea"
    area.Size = UDim2.fromScale(1, 1)
    area.BackgroundTransparency = 1
    area.Parent = gui
    local scale = Instance.new("UIScale")
    scale.Name = "ViewportScale"
    scale.Parent = Window.Root
    local connections = {}
    local function track(connection)
        connections[#connections + 1] = connection
    end
    local fitting = false
    local function fitWindow()
        if fitting then return end
        local view = area.AbsoluteSize
        if view.X <= 16 or view.Y <= 16 then return end
        fitting = true
        local root = Window.Root
        local width = root.Size.X.Scale * view.X + root.Size.X.Offset
        local height = root.Size.Y.Scale * view.Y + root.Size.Y.Offset
        if width > 0 and height > 0 then
            scale.Scale = math.min(1, (view.X - 16) / width, (view.Y - 16) / height)
            width, height = width * scale.Scale, height * scale.Scale
            local anchor = root.AnchorPoint
            local x = root.Position.X.Scale * view.X + root.Position.X.Offset - anchor.X * width
            local y = root.Position.Y.Scale * view.Y + root.Position.Y.Offset - anchor.Y * height
            x = math.clamp(x, 8, math.max(8, view.X - width - 8))
            y = math.clamp(y, 8, math.max(8, view.Y - height - 8))
            root.Position = UDim2.fromOffset(x + anchor.X * width, y + anchor.Y * height)
            Window.Position = root.Position
        end
        fitting = false
    end
    local function button(text, position, anchor, width)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(width, 48)
        btn.Position = position
        btn.AnchorPoint = anchor
        btn.BackgroundColor3 = Color3.fromRGB(35, 29, 48)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamMedium
        btn.Text = text
        btn.Parent = area
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn
        return btn
    end
    local menu = button("收起菜单", UDim2.new(1, -8, 0, 8), Vector2.new(1, 0), 120)
    local aim = button("瞄准保持：关", UDim2.new(0.5, 0, 1, -16), Vector2.new(0.5, 1), 128)
    local up = button("上升", UDim2.new(0.5, -6, 1, -72), Vector2.new(1, 1), 64)
    local down = button("下降", UDim2.new(0.5, 6, 1, -72), Vector2.new(0, 1), 64)
    refreshTouchControls = function()
        local visible = UserInputService.TouchEnabled
        menu.Visible, aim.Visible = visible, visible
        up.Visible = visible and S.Fly and flyBV ~= nil
        down.Visible = up.Visible
        menu.Text = Window.Root.Visible and "收起菜单" or "展开菜单"
        aim.Text = Touch.Aim and "瞄准保持：开" or "瞄准保持：关"
        aim.BackgroundColor3 = Touch.Aim and S.AccentColor or Color3.fromRGB(35, 29, 48)
    end
    menu.Activated:Connect(function() Window:Minimize() end)
    aim.Activated:Connect(function()
        Touch.Aim = not Touch.Aim
        if Touch.Aim then Options.AimEnable:SetValue(true) end
        refreshTouchControls()
    end)
    for name, btn in pairs({Up = up, Down = down}) do
        btn.InputBegan:Connect(function(input)
            if Touch[name] then return end
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                Touch[name] = input
            end
        end)
    end
    track(UserInputService.InputEnded:Connect(function(input)
        if input == Touch.Up then Touch.Up = nil end
        if input == Touch.Down then Touch.Down = nil end
    end))
    track(UserInputService.WindowFocusReleased:Connect(function()
        HoldingAim, Touch.Aim, Touch.Up, Touch.Down = false, false, nil, nil
        refreshTouchControls()
    end))
    track(UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
        Touch.Aim, Touch.Up, Touch.Down = false, nil, nil
        refreshTouchControls()
    end))
    track(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        if not usingTouch() then Touch.Aim, Touch.Up, Touch.Down = false, nil, nil end
        refreshTouchControls()
    end))
    track(area:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitWindow))
    track(Window.Root:GetPropertyChangedSignal("Size"):Connect(fitWindow))
    track(Window.Root:GetPropertyChangedSignal("Position"):Connect(fitWindow))
    track(Window.Root:GetPropertyChangedSignal("Visible"):Connect(refreshTouchControls))
    track(Window.Root.Destroying:Connect(function()
        HoldingAim, Touch.Aim, Touch.Up, Touch.Down = false, false, nil, nil
        setFly(false)
        for _, connection in ipairs(connections) do connection:Disconnect() end
        refreshTouchControls = function() end
        gui:Destroy()
    end))
    fitWindow()
    refreshTouchControls()
end

-- ======================== HOME ========================
do
    Tabs.Home:AddSection("状态")
    Tabs.Home:AddParagraph({
        Title = "ELITE SCRIPTS",
        Content = "狙击竞技场 · UNC 通用\n免密钥 · Discord：discord.gg/JyHTa3M7h"
    })
    Tabs.Home:AddParagraph({
        Title = "快捷开关",
        Content = "常用功能开关；详细设置请查看其他分页。"
    })
    Tabs.Home:AddToggle("HomeAim", {
        Title = "辅助瞄准",
        Default = false,
        Callback = function(v)
            S.Aimbot = v
            if not v then Touch.Aim = false end
            refreshTouchControls()
            if FOVCircle then FOVCircle.Visible = v and S.ShowFOV end
            if Options.AimEnable and Options.AimEnable.Value ~= v then Options.AimEnable:SetValue(v) end
        end
    })
    Tabs.Home:AddToggle("HomeESP", {
        Title = "透视",
        Default = true,
        Callback = function(v)
            S.ESP = v
            if Options.ESPEnable and Options.ESPEnable.Value ~= v then Options.ESPEnable:SetValue(v) end
        end
    })
    Tabs.Home:AddToggle("HomeSilent", {
        Title = "静默瞄准",
        Default = false,
        Callback = function(v)
            S.SilentAim = v
            if Options.SilentEnable and Options.SilentEnable.Value ~= v then Options.SilentEnable:SetValue(v) end
        end
    })
    Tabs.Home:AddToggle("HomeTrigger", {
        Title = "自动扳机",
        Default = false,
        Callback = function(v)
            S.Triggerbot = v
            if Options.TriggerEnable and Options.TriggerEnable.Value ~= v then Options.TriggerEnable:SetValue(v) end
        end
    })
    Tabs.Home:AddButton({
        Title = "复制 Discord 邀请",
        Description = "discord.gg/JyHTa3M7h",
        Callback = function()
            pcall(function()
                if setclipboard then setclipboard(S.DiscordLink) end
            end)
            Fluent:Notify({ Title = "ELITE SCRIPTS", Content = "Discord 邀请链接已复制", Duration = 3 })
        end
    })
end

-- ======================== AIM ========================
do
    Tabs.Aim:AddSection("核心功能")
    Tabs.Aim:AddToggle("AimEnable", {
        Title = "启用辅助瞄准",
        Default = false,
        Callback = function(v)
            S.Aimbot = v
            if not v then Touch.Aim = false end
            refreshTouchControls()
            if FOVCircle then FOVCircle.Visible = v and S.ShowFOV end
            if Options.HomeAim and Options.HomeAim.Value ~= v then Options.HomeAim:SetValue(v) end
        end
    })
    Tabs.Aim:AddToggle("SilentEnable", {
        Title = "静默瞄准",
        Default = false,
        Callback = function(v)
            S.SilentAim = v
            if Options.HomeSilent and Options.HomeSilent.Value ~= v then Options.HomeSilent:SetValue(v) end
        end
    })
    Tabs.Aim:AddToggle("TriggerEnable", {
        Title = "自动扳机",
        Default = false,
        Callback = function(v)
            S.Triggerbot = v
            if Options.HomeTrigger and Options.HomeTrigger.Value ~= v then Options.HomeTrigger:SetValue(v) end
        end
    })
    Tabs.Aim:AddToggle("AlwaysOn", {
        Title = "持续瞄准",
        Default = false,
        Callback = function(v) S.AlwaysOn = v end
    })
    Tabs.Aim:AddToggle("TeamCheck", {
        Title = "队伍检查",
        Default = true,
        Callback = function(v) S.TeamCheck = v end
    })
    Tabs.Aim:AddToggle("WallCheck", {
        Title = "遮挡检查",
        Default = true,
        Callback = function(v) S.WallCheck = v end
    })
    Tabs.Aim:AddToggle("Prediction", {
        Title = "移动预判",
        Default = true,
        Callback = function(v) S.Prediction = v end
    })
    Tabs.Aim:AddToggle("TargetBots", {
        Title = "瞄准机器人",
        Default = true,
        Callback = function(v) S.TargetBots = v end
    })

    Tabs.Aim:AddSection("目标设置")
    Tabs.Aim:AddDropdown("AimPart", {
        Title = "瞄准部位",
        Values = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Torso"},
        Multi = false,
        Default = 1,
        Callback = function(v) S.AimPart = v end
    })
    Tabs.Aim:AddDropdown("AimMethod", {
        Title = "瞄准方式",
        Values = {"Camera", "Mouse"},
        Multi = false,
        Default = 1,
        Callback = function(v) S.AimMethod = v end
    })

    Tabs.Aim:AddSection("参数调整")
    Tabs.Aim:AddSlider("FOV", {
        Title = "瞄准范围",
        Description = "范围圆半径",
        Default = 120,
        Min = 30,
        Max = 400,
        Rounding = 0,
        Callback = function(v)
            S.FOV = v
            if FOVCircle then FOVCircle.Radius = v end
        end
    })
    Tabs.Aim:AddSlider("Smooth", {
        Title = "平滑度",
        Default = 0.10,
        Min = 0.02,
        Max = 0.40,
        Rounding = 2,
        Callback = function(v) S.Smoothness = v end
    })
    Tabs.Aim:AddSlider("PredMult", {
        Title = "预判系数",
        Default = 0.08,
        Min = 0.01,
        Max = 0.30,
        Rounding = 2,
        Callback = function(v) S.PredMult = v end
    })
    Tabs.Aim:AddToggle("ShowFOV", {
        Title = "显示瞄准范围圆",
        Default = true,
        Callback = function(v)
            S.ShowFOV = v
            if FOVCircle then FOVCircle.Visible = v and (S.Aimbot or S.SilentAim) end
        end
    })
    Tabs.Aim:AddToggle("FOVRainbow", {
        Title = "范围圆彩虹色",
        Default = false,
        Callback = function(v) S.FOVRainbow = v end
    })
    Tabs.Aim:AddColorpicker("FOVColor", {
        Title = "范围圆颜色",
        Default = Color3.fromRGB(180, 80, 255),
        Callback = function(c)
            S.FOVColor = c
            if FOVCircle and not S.FOVRainbow then FOVCircle.Color = c end
        end
    })
end

-- ======================== VISUALS ========================
do
    Tabs.Visuals:AddSection("透视")
    Tabs.Visuals:AddToggle("ESPEnable", {
        Title = "启用透视",
        Default = true,
        Callback = function(v)
            S.ESP = v
            if Options.HomeESP and Options.HomeESP.Value ~= v then Options.HomeESP:SetValue(v) end
        end
    })
    Tabs.Visuals:AddToggle("BoxESP", {
        Title = "方框",
        Default = true,
        Callback = function(v) S.Box = v end
    })
    Tabs.Visuals:AddToggle("SkelESP", {
        Title = "骨骼",
        Default = true,
        Callback = function(v) S.Skeleton = v end
    })
    Tabs.Visuals:AddToggle("TracerESP", {
        Title = "玩家连线",
        Default = true,
        Callback = function(v) S.Tracer = v end
    })
    Tabs.Visuals:AddToggle("NameESP", {
        Title = "名称",
        Default = true,
        Callback = function(v) S.Name = v end
    })
    Tabs.Visuals:AddToggle("DistESP", {
        Title = "距离",
        Default = true,
        Callback = function(v) S.Distance = v end
    })
    Tabs.Visuals:AddToggle("HealthESP", {
        Title = "血条",
        Default = true,
        Callback = function(v) S.Health = v end
    })
    Tabs.Visuals:AddToggle("ESPTeam", {
        Title = "队伍检查",
        Default = true,
        Callback = function(v) S.ESPTeamCheck = v end
    })
    Tabs.Visuals:AddToggle("ShowBots", {
        Title = "显示机器人",
        Default = true,
        Callback = function(v) S.ShowBots = v end
    })
    Tabs.Visuals:AddSlider("MaxDist", {
        Title = "最大显示距离",
        Default = 2500,
        Min = 100,
        Max = 5000,
        Rounding = 0,
        Callback = function(v) S.MaxDist = v end
    })

    Tabs.Visuals:AddSection("颜色设置")
    Tabs.Visuals:AddColorpicker("BoxCol", {
        Title = "方框颜色",
        Default = Color3.fromRGB(188, 78, 255),
        Callback = function(c) S.BoxColor = c end
    })
    Tabs.Visuals:AddColorpicker("SkelCol", {
        Title = "骨骼颜色",
        Default = Color3.fromRGB(210, 120, 255),
        Callback = function(c) S.SkelColor = c end
    })
    Tabs.Visuals:AddColorpicker("TracerCol", {
        Title = "连线颜色",
        Default = Color3.fromRGB(160, 60, 240),
        Callback = function(c) S.TracerColor = c end
    })
    Tabs.Visuals:AddColorpicker("BotCol", {
        Title = "机器人颜色",
        Default = Color3.fromRGB(80, 180, 255),
        Callback = function(c) S.BotColor = c end
    })

    Tabs.Visuals:AddSection("附加功能")
    Tabs.Visuals:AddToggle("BulletTrace", {
        Title = "弹道轨迹",
        Default = true,
        Callback = function(v) S.BulletTracer = v end
    })
    Tabs.Visuals:AddColorpicker("BulletCol", {
        Title = "弹道颜色",
        Default = Color3.fromRGB(255, 90, 220),
        Callback = function(c) S.BulletColor = c end
    })
    Tabs.Visuals:AddToggle("CrosshairT", {
        Title = "自定义准星",
        Default = false,
        Callback = function(v)
            S.Crosshair = v
            for _, ln in ipairs(crossLines) do
                if ln then ln.Visible = v end
            end
        end
    })
    Tabs.Visuals:AddSlider("CrossSize", {
        Title = "准星大小",
        Default = 10,
        Min = 4,
        Max = 28,
        Rounding = 0,
        Callback = function(v) S.CrosshairSize = v end
    })
    Tabs.Visuals:AddColorpicker("CrossCol", {
        Title = "准星颜色",
        Default = Color3.fromRGB(255, 80, 220),
        Callback = function(c)
            S.CrosshairColor = c
            for _, ln in ipairs(crossLines) do
                if ln then ln.Color = c end
            end
        end
    })
    Tabs.Visuals:AddToggle("FullBright", {
        Title = "全亮模式",
        Default = false,
        Callback = function(v)
            S.FullBright = v
            if v then
                origAmbient = Lighting.Ambient
                origBrightness = Lighting.Brightness
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.Brightness = 2
            else
                if origAmbient then Lighting.Ambient = origAmbient end
                if origBrightness then Lighting.Brightness = origBrightness end
            end
        end
    })
    Tabs.Visuals:AddToggle("NoFog", {
        Title = "移除雾效",
        Default = false,
        Callback = function(v)
            S.NoFog = v
            if v then
                origFog = Lighting.FogEnd
                Lighting.FogEnd = 1e6
            else
                if origFog then Lighting.FogEnd = origFog end
            end
        end
    })
    Tabs.Visuals:AddToggle("CustomFOV", {
        Title = "自定义镜头视野",
        Default = false,
        Callback = function(v)
            S.CustomFOV = v
            if v then
                origCamFOV = Camera.FieldOfView
                Camera.FieldOfView = S.CamFOV
            else
                if origCamFOV then Camera.FieldOfView = origCamFOV end
            end
        end
    })
    Tabs.Visuals:AddSlider("CamFOV", {
        Title = "镜头视野角度",
        Default = 90,
        Min = 50,
        Max = 120,
        Rounding = 0,
        Callback = function(v)
            S.CamFOV = v
            if S.CustomFOV then Camera.FieldOfView = v end
        end
    })
end

-- ======================== PLAYER ========================
do
    Tabs.Player:AddSection("移动设置")
    Tabs.Player:AddToggle("FlyEnable", {
        Title = "飞行",
        Default = false,
        Callback = function(v)
            setFly(v)
        end
    })
    Tabs.Player:AddSlider("FlySpd", {
        Title = "飞行速度",
        Default = 70,
        Min = 20,
        Max = 180,
        Rounding = 0,
        Callback = function(v) S.FlySpeed = v end
    })
    Tabs.Player:AddToggle("Noclip", {
        Title = "穿墙",
        Default = false,
        Callback = function(v) S.Noclip = v end
    })
    Tabs.Player:AddToggle("Speed", {
        Title = "移动加速",
        Default = false,
        Callback = function(v)
            S.Speed = v
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v and S.WalkSpeed or 16 end
            end
        end
    })
    Tabs.Player:AddSlider("WalkSpd", {
        Title = "行走速度",
        Default = 24,
        Min = 16,
        Max = 80,
        Rounding = 0,
        Callback = function(v)
            S.WalkSpeed = v
            if S.Speed then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = v end
                end
            end
        end
    })
    Tabs.Player:AddToggle("InfJump", {
        Title = "无限跳跃",
        Default = false,
        Callback = function(v) S.InfiniteJump = v end
    })

    Tabs.Player:AddSection("命中框")
    Tabs.Player:AddToggle("HitboxT", {
        Title = "扩大命中框",
        Default = false,
        Callback = function(v) S.Hitbox = v end
    })
    Tabs.Player:AddSlider("HitboxSz", {
        Title = "命中框大小",
        Default = 6,
        Min = 2,
        Max = 16,
        Rounding = 1,
        Callback = function(v) S.HitboxSize = v end
    })
end

-- ======================== WEAPONS ========================
do
    Tabs.Weapons:AddSection("武器调整")
    Tabs.Weapons:AddToggle("NoRecoil", {
        Title = "无后坐力",
        Default = false,
        Callback = function(v) S.NoRecoil = v end
    })
    Tabs.Weapons:AddToggle("NoSpread", {
        Title = "无散射",
        Default = false,
        Callback = function(v) S.NoSpread = v end
    })
    Tabs.Weapons:AddToggle("AutoReload", {
        Title = "自动换弹",
        Default = false,
        Callback = function(v) S.AutoReload = v end
    })
    Tabs.Weapons:AddToggle("InstantScope", {
        Title = "快速开镜",
        Default = false,
        Callback = function(v) S.InstantScope = v end
    })
end

-- ======================== CUSTOMIZE ========================
do
    local function applyAccent(c)
        S.AccentColor = c
        S.FOVColor = c
        S.BoxColor = c
        S.SkelColor = Color3.new(
            math.min(c.R * 1.12, 1),
            math.min(c.G * 1.12, 1),
            math.min(c.B * 1.12, 1)
        )
        S.TracerColor = Color3.new(
            math.max(c.R * 0.85, 0),
            math.max(c.G * 0.85, 0),
            math.max(c.B * 0.85, 0)
        )
        S.NameColor = Color3.new(
            math.min(c.R * 1.25 + 0.15, 1),
            math.min(c.G * 1.25 + 0.15, 1),
            math.min(c.B * 1.25 + 0.15, 1)
        )
        S.DiscordLEDColor = c
        S.CrosshairColor = c
        S.BulletColor = Color3.new(
            math.min(c.R * 1.2, 1),
            math.min(c.G * 0.55 + 0.1, 1),
            math.min(c.B * 1.05, 1)
        )
        if FOVCircle and not S.FOVRainbow then FOVCircle.Color = c end
        if DiscordLEDGlow then DiscordLEDGlow.Color = c end
        if DiscordLEDText then DiscordLEDText.Color = c end
        if DiscordLEDLine then DiscordLEDLine.Color = c end
        for _, ln in ipairs(crossLines) do
            if ln then ln.Color = c end
        end
        pcall(function()
            if Fluent.SetTheme then
                -- keep base Dark theme; accent drives ESP/UI draws
            end
        end)
    end

    Tabs.Customize:AddSection("强调色")
    Tabs.Customize:AddParagraph({
        Title = "主题强调色",
        Content = "选择颜色后同步更新范围圆、透视、连线、准星、弹道和 Discord 页脚。"
    })
    Tabs.Customize:AddColorpicker("AccentPick", {
        Title = "主要强调色",
        Default = Color3.fromRGB(188, 78, 255),
        Callback = function(c)
            applyAccent(c)
        end
    })

    Tabs.Customize:AddSection("预设")
    local function presetBtn(title, rgb)
        Tabs.Customize:AddButton({
            Title = title,
            Callback = function()
                local c = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
                applyAccent(c)
                if Options.AccentPick then Options.AccentPick:SetValue(c) end
                Fluent:Notify({ Title = "ELITE SCRIPTS", Content = title .. "已应用", Duration = 2 })
            end
        })
    end
    presetBtn("紫色（默认）", {188, 78, 255})
    presetBtn("绯红", {220, 40, 60})
    presetBtn("青色", {0, 210, 255})
    presetBtn("青柠绿", {80, 255, 100})
    presetBtn("金色", {255, 190, 40})
    presetBtn("白色", {240, 240, 245})
    presetBtn("粉色", {255, 90, 180})
    presetBtn("橙色", {255, 130, 40})

    Tabs.Customize:AddSection("单独调整")
    Tabs.Customize:AddColorpicker("CustFOV", {
        Title = "仅调整范围圆",
        Default = Color3.fromRGB(180, 80, 255),
        Callback = function(c)
            S.FOVColor = c
            if FOVCircle and not S.FOVRainbow then FOVCircle.Color = c end
        end
    })
    Tabs.Customize:AddColorpicker("CustBox", {
        Title = "仅调整透视方框",
        Default = Color3.fromRGB(188, 78, 255),
        Callback = function(c) S.BoxColor = c end
    })
    Tabs.Customize:AddColorpicker("CustTracer", {
        Title = "仅调整玩家连线",
        Default = Color3.fromRGB(160, 60, 240),
        Callback = function(c) S.TracerColor = c end
    })
    Tabs.Customize:AddColorpicker("CustBullet", {
        Title = "仅调整弹道",
        Default = Color3.fromRGB(255, 90, 220),
        Callback = function(c) S.BulletColor = c end
    })
end

-- ======================== MISC ========================
do
    Tabs.Misc:AddSection("性能设置")
    Tabs.Misc:AddToggle("FPSUnlock", {
        Title = "解锁帧率",
        Default = false,
        Callback = function(v)
            S.FPSUnlock = v
            pcall(function()
                if setfpscap then setfpscap(v and 999 or 60) end
            end)
        end
    })
    Tabs.Misc:AddToggle("DiscordLED", {
        Title = "Discord 发光页脚",
        Default = true,
        Callback = function(v)
            S.DiscordLED = v
            if DiscordLEDGlow then DiscordLEDGlow.Visible = v end
            if DiscordLEDText then DiscordLEDText.Visible = v end
            if DiscordLEDLine then DiscordLEDLine.Visible = v end
        end
    })
    Tabs.Misc:AddToggle("AutoReattach", {
        Title = "重生后重新绑定镜头",
        Default = true,
        Callback = function(v) S.AutoReattach = v end
    })

    Tabs.Misc:AddSection("预设")
    Tabs.Misc:AddButton({
        Title = "激进预设",
        Description = "辅助瞄准 + 静默瞄准 + 自动扳机 + 透视 + 加速",
        Callback = function()
            S.Aimbot = true
            S.SilentAim = true
            S.Triggerbot = true
            S.ESP = true
            S.Speed = true
            if Options.AimEnable then Options.AimEnable:SetValue(true) end
            if Options.SilentEnable then Options.SilentEnable:SetValue(true) end
            if Options.TriggerEnable then Options.TriggerEnable:SetValue(true) end
            if Options.ESPEnable then Options.ESPEnable:SetValue(true) end
            if Options.Speed then Options.Speed:SetValue(true) end
            Fluent:Notify({ Title = "ELITE SCRIPTS", Content = "已应用激进预设", Duration = 3 })
        end
    })
    Tabs.Misc:AddButton({
        Title = "柔和预设",
        Description = "仅启用平滑瞄准与透视",
        Callback = function()
            S.Aimbot = true
            S.SilentAim = false
            S.Triggerbot = false
            S.Smoothness = 0.20
            S.ESP = true
            S.Speed = false
            if Options.AimEnable then Options.AimEnable:SetValue(true) end
            if Options.SilentEnable then Options.SilentEnable:SetValue(false) end
            if Options.TriggerEnable then Options.TriggerEnable:SetValue(false) end
            if Options.ESPEnable then Options.ESPEnable:SetValue(true) end
            if Options.Smooth then Options.Smooth:SetValue(0.20) end
            Fluent:Notify({ Title = "ELITE SCRIPTS", Content = "已应用柔和预设", Duration = 3 })
        end
    })
    Tabs.Misc:AddButton({
        Title = "狙击预设",
        Description = "静默瞄准 + 自动扳机 + 透视 + 全亮",
        Callback = function()
            S.Aimbot = false
            S.SilentAim = true
            S.Triggerbot = true
            S.ESP = true
            S.FullBright = true
            if Options.SilentEnable then Options.SilentEnable:SetValue(true) end
            if Options.TriggerEnable then Options.TriggerEnable:SetValue(true) end
            if Options.ESPEnable then Options.ESPEnable:SetValue(true) end
            if Options.FullBright then Options.FullBright:SetValue(true) end
            Fluent:Notify({ Title = "ELITE SCRIPTS", Content = "已应用狙击预设", Duration = 3 })
        end
    })
end

-- ======================== ABOUT ========================
do
    Tabs.About:AddParagraph({
        Title = "ELITE SCRIPTS",
        Content = "狙击竞技场版本\n维护者：Axion\nDiscord：discord.gg/JyHTa3M7h\nUNC 通用 · 免密钥"
    })
    Tabs.About:AddParagraph({
        Title = "功能说明",
        Content = "• 平滑瞄准 / 静默瞄准 / 自动扳机\n• 移动预判 / 遮挡与队伍检查 / 机器人目标\n• 透视（方框、骨骼、连线、名称、距离、血条）\n• 弹道 / 准星 / 范围圆彩虹色\n• 扩大命中框 / 飞行 / 穿墙 / 加速\n• 无后坐力 / 无散射 / 快速开镜\n• 激进 / 柔和 / 狙击预设\n• 自定义强调色\n• 通过 Fluent SaveManager 保存配置"
    })
    Tabs.About:AddButton({
        Title = "复制 Discord 链接",
        Callback = function()
            pcall(function()
                if setclipboard then setclipboard(S.DiscordLink) end
            end)
            Fluent:Notify({ Title = "ELITE SCRIPTS", Content = "已复制 discord.gg/JyHTa3M7h", Duration = 3 })
        end
    })
end

-- ======================== MANAGERS ========================
local ConfigReady = false
if type(isfolder) == "function" and type(makefolder) == "function"
    and type(isfile) == "function" and type(readfile) == "function"
    and type(writefile) == "function" and type(listfiles) == "function" then
    local ok, err = pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        InterfaceManager:SetFolder("EliteScripts")
        SaveManager:SetFolder("EliteScripts/SniperArena")
        InterfaceManager:BuildInterfaceSection(Tabs.Misc)
        SaveManager:BuildConfigSection(Tabs.Misc)
    end)
    ConfigReady = ok
    if not ok then warn("[配置] 初始化失败：" .. tostring(err)) end
end
if not ConfigReady then
    Tabs.Misc:AddParagraph({Title = "配置保存", Content = "文件接口缺失或写入失败，设置仅在本次运行中生效。"})
end

Window:SelectTab(1)

Fluent:Notify({
    Title = "ELITE SCRIPTS",
    Content = "狙击竞技场已加载，手机可使用悬浮按钮操作。",
    Duration = 5
})

-- ======================== CORE LOGIC ========================
local function isBot(plr)
    if not plr then return false end
    local n = string.lower(plr.Name)
    if n:find("bot") or n:find("npc") or n:find("ai") then return true end
    if plr:GetAttribute("IsBot") or plr:GetAttribute("Bot") then return true end
    return false
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local bot = isBot(plr)
    if bot and not S.TargetBots and not S.ShowBots then return false end
    if (S.TeamCheck or S.ESPTeamCheck) and not bot then
        if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
            return false
        end
    end
    return true
end

local function getPart(char, name)
    return char:FindFirstChild(name) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function visibleCheck(part)
    if not S.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local ray = Ray.new(origin, dir)
    local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    if not hit then return true end
    return (pos - part.Position).Magnitude < 4
end

local function getClosest()
    local best, bestDist = nil, S.FOV
    local point = getAimPoint()
    local mx, my = point.X, point.Y
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            if isBot(plr) and not S.TargetBots then continue end
            local part = getPart(plr.Character, S.AimPart)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(mx, my)).Magnitude
                    if d < bestDist and visibleCheck(part) then
                        bestDist = d
                        best = part
                    end
                end
            end
        end
    end
    return best
end

local function aimAt(part)
    if not part then return end
    local target = part.Position
    if S.Prediction then
        local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
        target = target + vel * S.PredMult
    end
    if S.AimMethod == "Camera" or usingTouch() then
        local cf = CFrame.new(Camera.CFrame.Position, target)
        Camera.CFrame = Camera.CFrame:Lerp(cf, S.Smoothness)
    else
        local pos = Camera:WorldToViewportPoint(target)
        local point = getAimPoint()
        local dx = pos.X - point.X
        local dy = pos.Y - point.Y
        safeMousemove(dx * S.Smoothness * 0.55, dy * S.Smoothness * 0.55)
    end
end

-- Input
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or UserInputService:GetFocusedTextBox() then return end
    if inp.UserInputType == S.AimKey or inp.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingAim = true
    end

end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == S.AimKey or inp.UserInputType == Enum.UserInputType.MouseButton2 then
        HoldingAim = false
    end
end)
UserInputService.JumpRequest:Connect(function()
    if not S.InfiniteJump or UserInputService:GetFocusedTextBox() then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)


-- ESP
local function clearESP(plr)
    local c = espCache[plr]
    if not c then return end
    for _, o in pairs(c) do
        if type(o) == "table" and o.Remove then
            pcall(function() o:Remove() end)
        elseif type(o) == "table" then
            for _, sub in pairs(o) do
                pcall(function() if sub and sub.Remove then sub:Remove() end end)
            end
        end
    end
    espCache[plr] = nil
end

local function ensureESP(plr)
    if espCache[plr] then return espCache[plr] end
    local t = {
        box = safeDrawing("Square"),
        name = safeDrawing("Text"),
        dist = safeDrawing("Text"),
        health = safeDrawing("Line"),
        tracer = safeDrawing("Line"),
        bones = {},
    }
    if t.box then
        t.box.Filled = false
        t.box.Thickness = 1.2
        t.box.Visible = false
    end
    if t.name then
        t.name.Size = 13
        t.name.Center = true
        t.name.Outline = true
        t.name.Visible = false
    end
    if t.dist then
        t.dist.Size = 12
        t.dist.Center = true
        t.dist.Outline = true
        t.dist.Visible = false
    end
    if t.health then
        t.health.Thickness = 2
        t.health.Visible = false
    end
    if t.tracer then
        t.tracer.Thickness = 1.1
        t.tracer.Visible = false
    end
    local bonePairs = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    }
    for i = 1, #bonePairs do
        local ln = safeDrawing("Line")
        if ln then
            ln.Thickness = 1.2
            ln.Visible = false
            t.bones[i] = ln
        end
    end
    t.bonePairs = bonePairs
    espCache[plr] = t
    return t
end

local function updateESP()
    if not S.ESP then
        for plr in pairs(espCache) do clearESP(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if not isEnemy(plr) then
            clearESP(plr)
            continue
        end
        local bot = isBot(plr)
        if bot and not S.ShowBots then
            clearESP(plr)
            continue
        end
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            clearESP(plr)
            continue
        end
        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
        if dist > S.MaxDist then
            clearESP(plr)
            continue
        end
        local t = ensureESP(plr)
        local col = bot and S.BotColor or S.BoxColor
        local head = char:FindFirstChild("Head")
        local top = head and head.Position or (hrp.Position + Vector3.new(0, 2.5, 0))
        local bottom = hrp.Position - Vector3.new(0, 3, 0)
        local topV, on1 = Camera:WorldToViewportPoint(top)
        local botV, on2 = Camera:WorldToViewportPoint(bottom)
        local midV = Camera:WorldToViewportPoint(hrp.Position)
        if not (on1 or on2) then
            if t.box then t.box.Visible = false end
            if t.name then t.name.Visible = false end
            if t.dist then t.dist.Visible = false end
            if t.health then t.health.Visible = false end
            if t.tracer then t.tracer.Visible = false end
            for _, ln in ipairs(t.bones) do if ln then ln.Visible = false end end
            continue
        end
        local h = math.abs(topV.Y - botV.Y)
        local w = h * 0.55
        local cx = (topV.X + botV.X) / 2

        if t.box and S.Box then
            t.box.Size = Vector2.new(w, h)
            t.box.Position = Vector2.new(cx - w / 2, topV.Y)
            t.box.Color = col
            t.box.Visible = true
        elseif t.box then
            t.box.Visible = false
        end

        if t.name and S.Name then
            t.name.Text = bot and ("[机器人] " .. plr.Name) or plr.Name
            t.name.Position = Vector2.new(cx, topV.Y - 16)
            t.name.Color = bot and S.BotColor or S.NameColor
            t.name.Visible = true
        elseif t.name then
            t.name.Visible = false
        end

        if t.dist and S.Distance then
            t.dist.Text = string.format("[%d 格]", math.floor(dist))
            t.dist.Position = Vector2.new(cx, botV.Y + 2)
            t.dist.Color = S.NameColor
            t.dist.Visible = true
        elseif t.dist then
            t.dist.Visible = false
        end

        if t.health and S.Health then
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local barH = h * pct
            t.health.From = Vector2.new(cx - w / 2 - 4, botV.Y)
            t.health.To = Vector2.new(cx - w / 2 - 4, botV.Y - barH)
            t.health.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 40)
            t.health.Visible = true
        elseif t.health then
            t.health.Visible = false
        end

        if t.tracer and S.Tracer then
            t.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            t.tracer.To = Vector2.new(midV.X, midV.Y)
            t.tracer.Color = bot and S.BotColor or S.TracerColor
            t.tracer.Visible = true
        elseif t.tracer then
            t.tracer.Visible = false
        end

        if S.Skeleton and t.bones then
            for i, pair in ipairs(t.bonePairs) do
                local ln = t.bones[i]
                if ln then
                    local a = char:FindFirstChild(pair[1])
                    local b = char:FindFirstChild(pair[2])
                    if a and b then
                        local pa, oa = Camera:WorldToViewportPoint(a.Position)
                        local pb, ob = Camera:WorldToViewportPoint(b.Position)
                        if oa or ob then
                            ln.From = Vector2.new(pa.X, pa.Y)
                            ln.To = Vector2.new(pb.X, pb.Y)
                            ln.Color = bot and S.BotColor or S.SkelColor
                            ln.Visible = true
                        else
                            ln.Visible = false
                        end
                    else
                        ln.Visible = false
                    end
                end
            end
        else
            for _, ln in ipairs(t.bones) do if ln then ln.Visible = false end end
        end
    end
    for plr in pairs(espCache) do
        if not Players:FindFirstChild(plr.Name) then clearESP(plr) end
    end
end

local function updateHitbox()
    if not S.Hitbox then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
                    hrp.Transparency = 0.65
                    hrp.CanCollide = false
                end)
            end
        end
    end
end

local function flyStep()
    if not S.Fly or not flyBV or not flyBG or not flyBV.Parent or not flyBG.Parent then return end
    if UserInputService:GetFocusedTextBox() then
        flyBV.Velocity = Vector3.zero
        return
    end
    local cam = Camera.CFrame
    local move = Vector3.zero
    if usingTouch() then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        -- PlatformStand 下优先读取摇杆原始输入；自定义控制器保留 MoveDirection 回退。
        if hum then move = hum.MoveDirection end
        if Touch.Controls then
            local ok, direction = pcall(Touch.Controls.GetMoveVector, Touch.Controls)
            if ok and typeof(direction) == "Vector3" then
                move = cam:VectorToWorldSpace(direction)
            end
        end
    elseif not UserInputService:GetFocusedTextBox() then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            move = move - Vector3.new(0, 1, 0)
        end
    end
    local vertical = (Touch.Up and 1 or 0) - (Touch.Down and 1 or 0)
    move = move + Vector3.new(0, vertical, 0)
    if move.Magnitude > 0 then move = move.Unit * S.FlySpeed end
    flyBV.Velocity = move
    flyBG.CFrame = cam
end

local function noclipStep()
    if not S.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end

local function hookTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    tool.Activated:Connect(function()
        if not S.BulletTracer then return end
        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local origin = head.Position
        local dir = Camera.CFrame.LookVector * S.BulletMaxDist
        local hit, pos = Workspace:FindPartOnRayWithIgnoreList(Ray.new(origin, dir), {char})
        local endPos = hit and pos or (origin + dir)
        local ln = safeDrawing("Line")
        if ln then
            ln.Thickness = S.BulletThick
            ln.Color = S.BulletColor
            ln.Transparency = 1
            local o = Camera:WorldToViewportPoint(origin)
            local e = Camera:WorldToViewportPoint(endPos)
            ln.From = Vector2.new(o.X, o.Y)
            ln.To = Vector2.new(e.X, e.Y)
            ln.Visible = true
            table.insert(bullets, {obj = ln, t = tick()})
        end
    end)
end

local function setupChar(char)
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") then hookTool(c) end
    end
    char.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then hookTool(c) end
    end)
    if S.Speed then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = S.WalkSpeed end
    end
    if S.Fly then
        task.wait(0.3)
        if char == LocalPlayer.Character and S.Fly then setFly(true, char) end
    end
end

if LocalPlayer.Character then setupChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupChar)

if LocalPlayer:FindFirstChild("Backpack") then
    LocalPlayer.Backpack.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then hookTool(c) end
    end)
end

if S.AutoReattach then
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        Camera = Workspace.CurrentCamera
    end)
end

-- Main loop
RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera
    if not Camera then return end
    local aimPoint = getAimPoint()

    if FOVCircle then
        FOVCircle.Position = aimPoint
        if S.FOVRainbow then
            FOVCircle.Color = Color3.fromHSV((tick() * 0.4) % 1, 0.9, 1)
        end
        FOVCircle.Visible = (S.Aimbot or S.SilentAim) and S.ShowFOV
        FOVCircle.Radius = S.FOV
    end

    if S.Crosshair then
        local cx, cy = aimPoint.X, aimPoint.Y
        local s, gap = S.CrosshairSize, 3
        if crossLines[1] then
            crossLines[1].From = Vector2.new(cx - s, cy)
            crossLines[1].To = Vector2.new(cx - gap, cy)
            crossLines[1].Visible = true
        end
        if crossLines[2] then
            crossLines[2].From = Vector2.new(cx + gap, cy)
            crossLines[2].To = Vector2.new(cx + s, cy)
            crossLines[2].Visible = true
        end
        if crossLines[3] then
            crossLines[3].From = Vector2.new(cx, cy - s)
            crossLines[3].To = Vector2.new(cx, cy - gap)
            crossLines[3].Visible = true
        end
        if crossLines[4] then
            crossLines[4].From = Vector2.new(cx, cy + gap)
            crossLines[4].To = Vector2.new(cx, cy + s)
            crossLines[4].Visible = true
        end
    end

    local target = nil
    if not UserInputService:GetFocusedTextBox() and (S.Aimbot or S.SilentAim or S.Triggerbot) then
        target = getClosest()
    end

    if S.Aimbot and (HoldingAim or Touch.Aim or S.AlwaysOn) and target then
        aimAt(target)
    elseif S.SilentAim and target then
        aimAt(target)
    end

    if S.Triggerbot and target and tick() - lastTrigger > 0.08 then
        local pos = Camera:WorldToViewportPoint(target.Position)
        local d = (Vector2.new(pos.X, pos.Y) - aimPoint).Magnitude
        if d < 18 then
            safeMouse1Click()
            lastTrigger = tick()
        end
    end

    updateESP()
    flyStep()
    noclipStep()
    updateHitbox()

    if S.DiscordLED and DiscordLEDText then
        local vs = Camera.ViewportSize
        local y, x = vs.Y - 18, vs.X / 2
        DiscordLEDText.Position = Vector2.new(x, y)
        if DiscordLEDGlow then
            DiscordLEDGlow.Position = Vector2.new(x, y)
            DiscordLEDGlow.Color = S.DiscordLEDColor
        end
        DiscordLEDText.Color = S.DiscordLEDColor
        if DiscordLEDLine then
            DiscordLEDLine.From = Vector2.new(x - 70, y - 10)
            DiscordLEDLine.To = Vector2.new(x + 70, y - 10)
            DiscordLEDLine.Color = S.DiscordLEDColor
        end
    end

    local now = tick()
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        local age = now - b.t
        if age > S.BulletLife then
            pcall(function() b.obj:Remove() end)
            table.remove(bullets, i)
        else
            b.obj.Transparency = 1 - (age / S.BulletLife)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.35)
        if not (S.NoRecoil or S.NoSpread or S.AutoReload or S.InstantScope) then continue end
        local char = LocalPlayer.Character
        if not char then continue end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then continue end
        pcall(function()
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n = string.lower(v.Name)
                    if S.NoRecoil and (n:find("recoil") or n:find("kick")) then
                        v.Value = 0
                    end
                    if S.NoSpread and (n:find("spread") or n:find("accuracy")) then
                        v.Value = 0
                    end
                    if S.InstantScope and (n:find("scope") or n:find("ads") or n:find("aimspeed")) then
                        v.Value = 0
                    end
                end
            end
        end)
    end
end)

if ConfigReady then pcall(function() SaveManager:LoadAutoloadConfig() end) end

print("[ELITE SCRIPTS] 狙击竞技场已加载，当前显示首页")
