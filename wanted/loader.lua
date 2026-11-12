-- Script taken from https://robloxscripts.com website --

-- 执行器兼容：不伪造身份权限；缺少身份接口时按当前权限运行。
local env = (type(getgenv) == "function" and getgenv()) or _G
local getgenv = function() return env end
local identityGet = getthreadidentity or getidentity or (syn and syn.get_thread_identity)
local identitySet = setthreadidentity or setidentity or (syn and syn.set_thread_identity)
local getthreadidentity = function()
    if type(identityGet) == "function" then
        local ok, value = pcall(identityGet)
        if ok then return value end
    end
    return nil
end
local setthreadidentity = function(value)
    if value ~= nil and type(identitySet) == "function" then pcall(identitySet, value) end
end
local function parentGui(gui)
    local candidates = {}
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and parent then candidates[#candidates + 1] = parent end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok then candidates[#candidates + 1] = core end
    candidates[#candidates + 1] = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, parent in ipairs(candidates) do
        if pcall(function() gui.Parent = parent end) then return end
    end
    error("界面挂载失败，请检查执行器权限")
end
local function fetchSource(url)
    local requests = {}
    local function add(fn)
        if type(fn) == "function" and not table.find(requests, fn) then requests[#requests + 1] = fn end
    end
    add(syn and syn.request)
    add(http and http.request)
    add(request)
    add(http_request)
    add(fluxus and fluxus.request)
    for _, fn in ipairs(requests) do
        local ok, result = pcall(fn, {Url = url, Method = "GET"})
        if ok and type(result) == "table" then
            local status = tonumber(result.StatusCode or result.Status or result.status_code)
            local body = result.Body or result.body
            if status and status >= 200 and status < 300 and type(body) == "string" and #body > 0 then return body end
        end
    end
    local ok, source = pcall(function() return game:HttpGet(url) end)
    if ok and type(source) == "string" and #source > 0 then return source end
    error("界面库下载失败，请检查网络和执行器 HTTP 支持")
end

local lifecycle: any = ...
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer
local function usingTouch()
    local ok, preferred = pcall(function() return UserInputService.PreferredInput end)
    return UserInputService.TouchEnabled and (not ok or preferred == Enum.PreferredInput.Touch)
end
local touchControls
if UserInputService.TouchEnabled then
    task.spawn(function()
        local ok, controls = pcall(function()
            local scripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
            local module = scripts and scripts:WaitForChild("PlayerModule", 5)
            if module then return require(module):GetControls() end
        end)
        if ok and type(controls) == "table" and type(controls.GetMoveVector) == "function" then
            touchControls = controls
        end
    end)
end
assert(game.PlaceId == 14438406081, "This script is configured for Wanted.")
assert(LocalPlayer, "LocalPlayer is unavailable.")

local devvModule = ReplicatedStorage:WaitForChild("Devv", 10)
assert(devvModule and devvModule:IsA("ModuleScript"), "Wanted Devv module is unavailable.")
local requireModule: any = require
local moduleOK, Devv: any = pcall(requireModule, devvModule)
assert(moduleOK and type(Devv) == "table" and type(Devv.load) == "function",
    "执行器未能读取 Wanted 的 Devv 游戏模块：" .. tostring(Devv))
local ClientTools: any = Devv.load("ClientTools")
local ClientPlayers: any = Devv.load("ClientPlayers")
local ClientVehicles: any = Devv.load("ClientVehicles")
local ClientGizmos: any = Devv.load("ClientGizmos")
local Objects: any = Devv.load("Objects")
local ClientGuns: any = ClientTools.ToolModules.ClientGuns
local executorEnvironment = getgenv()
local previous = ClientGuns.__WantedAimLuna
if type(previous) ~= "table" then
    local candidate = executorEnvironment.__WantedAimLunaState
    if type(candidate) == "table" and candidate.SessionWorkspace == workspace then previous = candidate end
end
local previousConfig = type(previous) == "table" and previous.Config
if type(previous) == "table" and type(previous.Cleanup) == "function" then
    previous.Cleanup()
end

local Config = {
    Enabled = true,
    TargetPlayers = true,
    TargetNPCs = true,
    PoliceCheck = true,
    CrewCheck = true,
    WallCheck = true,
    ShowCircle = true,
    Radius = 150,
    ESPEnabled = true,
    ESPBoxes = true,
    ESPNames = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPFilters = true,
    ESPMaxDistance = 1500,
    ESPPlayers = true,
    ESPUseDisplayNames = true,
    ESPHealthText = true,
    ESPWeapons = true,
    ESPTeamNames = false,
    ESPTracers = false,
    ESPBoxFill = false,
    ESPVisibilityCheck = false,
    ESPVisibleOnly = false,
    ESPUseTeamColors = true,
    ESPTextOutline = true,
    ESPTextSize = 14,
    ESPBoxThickness = 1.5,
    ESPFillOpacity = 0.12,
    ESPOpacity = 0.95,
    ESPRefreshRate = 30,
    ESPBoxStyle = "Full",
    ESPTracerOrigin = "Bottom",
    ESPColor = Color3.fromRGB(245, 245, 245),
    ESPPoliceColor = Color3.fromRGB(95, 165, 255),
    ESPSyndicateColor = Color3.fromRGB(255, 105, 120),
    ESPFriendlyColor = Color3.fromRGB(100, 235, 145),
    ESPOccludedColor = Color3.fromRGB(160, 160, 170),
    ESPItems = true,
    ESPItemNames = true,
    ESPItemValues = true,
    ESPItemDistance = true,
    ESPItemRarity = false,
    ESPItemAvoidOverlap = true,
    ESPItemThroughWalls = true,
    ESPItemShowUnknown = true,
    ESPItemHighlight = true,
    ESPItemFilter = "All",
    ESPItemMaxDistance = 1500,
    ESPItemMinValue = 0,
    ESPHighValueThreshold = 20000,
    ESPItemLabelLimit = 100,
    ESPItemHighlightLimit = 16,
    ESPItemTextSize = 14,
    ESPItemFillOpacity = 0.35,
    ESPItemColor = Color3.fromRGB(140, 230, 255),
    ESPHighValueColor = Color3.fromRGB(255, 205, 65),
    RotationEnabled = true,
    AimKey = "V",
    MenuKey = "RightShift",
    KeybindX = 1,
    KeybindY = 0.08,
    VehicleAcceleration = false,
    VehicleBoostKey = "G",
    VehicleFly = false,
    VehicleFlyKey = "F",
    VehicleFlyKmh = 150,
    VehicleAccelTime = 2,
    VehicleSpeedOverride = true,
    VehicleMaxKmh = 600,
    VehicleInstantBrakes = true,
    Noclip = false,
    NoclipKey = "N",
    VehicleNoclip = false,
    VehicleNoclipKey = "B",
    CircleColor = Color3.fromRGB(140, 205, 255),
}
if type(previousConfig) == "table" then
    for key, value in pairs(previousConfig) do
        if Config[key] ~= nil and typeof(value) == typeof(Config[key]) then Config[key] = value end
    end
end
local State: any = {
    Build = "NPC-HS-2",
    SessionWorkspace = workspace,
    SessionJobId = game.JobId,
    Alive = true,
    Config = Config,
    Connections = {},
    Controls = {},
    ESPEntries = {},
    WeaponCache = {},
    Vehicle = {Active = false, Elapsed = 0, Status = "Waiting for a driver seat"},
    Drawings = {},
    OverlayDirty = {},
    VehicleOverrides = {},
    VehicleHasFocus = true,
    Noclip = {Character = nil, Vehicle = nil, LastLookup = -math.huge},
    FeatureTicks = {},
    FeatureLastSuccess = {},
    FeatureErrors = {},
    FeatureWarnings = {},
    Highlights = {},
    ItemEntries = {},
    ItemStats = {Tracked = 0, Visible = 0, Valuable = 0},
    ESPStats = {Tracked = 0, Visible = 0},
    Target = nil,
    NPCModels = {},
    NPCStats = {Tracked = 0, Alive = 0, Available = 0},
    HookCalls = 0,
    RedirectedBatches = 0,
    Rotation = {Active = false, Target = nil, LastAcquire = -math.huge},
}
local MathUtil: any = Devv.load("MathUtil")
local Network: any = Devv.load("Network")
local originalNetworkFire = Network.FireServer
local originalBatchAuto = ClientGuns.BatchAutoFirePacket
local networkHook: any = nil
local batchHook: any = nil
State.ShotDirections = {}
State.RewrittenProjectiles = 0
State.SyncedProjectiles = 0
local original = ClientGuns.MakeGunProjectiles
assert(type(original) == "function", "MakeGunProjectiles is unavailable.")
State.Original = original
ClientGuns.__WantedAimLuna = State
executorEnvironment.__WantedAimLunaState = State

local circle: any = nil
local Luna: any = nil
local librarySource: string? = nil
local hook: any = nil
local rotationBinding = "WantedAimLuna.BodyRotation"
local releaseRotation: (boolean?) -> () = function() end
local releaseVehicleAssist: () -> () = function() end
local destroyVehicleFlight: () -> () = function() end
local releaseNoclip: () -> () = function() end

-- Native in-game widgets render even when the executor's external overlay is hidden.
local function nativeOverlay(): ScreenGui
    if State.NativeOverlay and State.NativeOverlay.Parent then return State.NativeOverlay end
    local gui = Instance.new("ScreenGui")
    State.NativeOverlay = gui
    gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "WantedAimNativeOverlay", true, false
    gui.DisplayOrder, gui.ZIndexBehavior = 25, Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets = Enum.ScreenInsets.None
    parentGui(gui)
    return gui
end

local function newDrawing(className: any): any
    local values: any = {
        Visible = false, Color = Color3.new(1, 1, 1), Transparency = 1,
        Position = Vector2.zero, Size = if className == "Text" then 14 else Vector2.zero,
        Thickness = 1, Filled = false, Radius = 150, Text = "", Center = false,
        Font = Enum.Font.Gotham, Outline = true, ZIndex = 5, From = Vector2.zero, To = Vector2.zero,
    }
    local object: any = nil
    local gui: any = Instance.new(if className == "Text" then "TextLabel" else "Frame")
    gui.Name, gui.Visible, gui.BorderSizePixel = "Wanted" .. tostring(className), false, 0
    gui.BackgroundTransparency = 1
    local stroke: UIStroke? = nil
    if className == "Square" or className == "Circle" then
        local newStroke = Instance.new("UIStroke")
        newStroke.Parent = gui
        stroke = newStroke
    end
    if className == "Circle" then
        local corner = Instance.new("UICorner")
        corner.CornerRadius, corner.Parent = UDim.new(1, 0), gui
    end
    if className == "Text" then
        gui.RichText, gui.TextWrapped, gui.AutomaticSize = false, false, Enum.AutomaticSize.None
        gui.TextXAlignment, gui.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    end
    local removed = false
    local function textBounds(): Vector2
        return TextService:GetTextSize(tostring(values.Text), math.clamp(tonumber(values.Size) or 14, 8, 64),
            if typeof(values.Font) == "EnumItem" then values.Font else Enum.Font.Gotham, Vector2.new(10000, 1000))
    end
    local function sync()
        if removed then return end
        local opacity = math.clamp(values.Transparency, 0, 1)
        gui.Visible, gui.ZIndex = values.Visible, values.ZIndex
        if not values.Visible then return end
        local overlay = nativeOverlay()
        if gui.Parent ~= overlay then gui.Parent = overlay end
        local origin = overlay.AbsolutePosition
        local function position(point: Vector2): UDim2
            return UDim2.fromOffset(point.X - origin.X, point.Y - origin.Y)
        end
        if className == "Text" then
            local bounds = textBounds()
            gui.AnchorPoint = Vector2.new(if values.Center then 0.5 else 0, 0)
            gui.Position = position(values.Position)
            gui.Size = UDim2.fromOffset(bounds.X + 2, bounds.Y + 2)
            gui.Text, gui.TextSize = values.Text, values.Size
            gui.Font = if typeof(values.Font) == "EnumItem" then values.Font else Enum.Font.Gotham
            gui.TextColor3, gui.TextTransparency = values.Color, 1 - opacity
            gui.TextStrokeColor3, gui.TextStrokeTransparency = Color3.new(), if values.Outline then 1 - opacity else 1
        elseif className == "Line" then
            local delta, midpoint = values.To - values.From, (values.From + values.To) / 2
            gui.AnchorPoint, gui.Rotation = Vector2.new(0.5, 0.5), math.deg(math.atan2(delta.Y, delta.X))
            gui.Position = position(midpoint)
            gui.Size = UDim2.fromOffset(math.max(0, delta.Magnitude), values.Thickness)
            gui.BackgroundColor3, gui.BackgroundTransparency = values.Color, 1 - opacity
        else
            local circleShape = className == "Circle"
            local size = if circleShape then Vector2.new(values.Radius * 2, values.Radius * 2) else values.Size
            gui.AnchorPoint = if circleShape then Vector2.new(0.5, 0.5) else Vector2.zero
            gui.Position = position(values.Position)
            gui.Size = UDim2.fromOffset(math.max(0, size.X), math.max(0, size.Y))
            gui.BackgroundColor3, gui.BackgroundTransparency = values.Color, if values.Filled then 1 - opacity else 1
            if stroke then
                stroke.Enabled = not values.Filled
                stroke.Color, stroke.Thickness, stroke.Transparency = values.Color, values.Thickness, 1 - opacity
            end
        end
    end
    local function remove()
        if removed then return end
        removed = true
        State.Drawings[object], State.OverlayDirty[object] = nil, nil
        gui:Destroy()
    end
    object = setmetatable({}, {
        __index = function(_, key)
            if key == "Remove" then return remove end
            if key == "Sync" then return sync end
            if key == "Gui" then return gui end
            if key == "TextBounds" then return textBounds() end
            return values[key]
        end,
        __newindex = function(_, key, value)
            if removed or values[key] == value then return end
            values[key] = value
            State.OverlayDirty[object] = true
        end,
    })
    State.Drawings[object], State.OverlayDirty[object] = true, true
    gui.Parent = nativeOverlay()
    return object
end

local function flushNativeOverlay()
    local origin = nativeOverlay().AbsolutePosition
    if State.OverlayOrigin ~= origin then
        State.OverlayOrigin = origin
        for drawing in pairs(State.Drawings) do State.OverlayDirty[drawing] = true end
    end
    for drawing in pairs(State.OverlayDirty) do
        State.OverlayDirty[drawing] = nil
        drawing.Sync()
    end
end
State.FlushNativeOverlay = flushNativeOverlay

local function removeDrawing(drawing: any)
    if drawing then drawing:Remove() end
end

local function runFeature(name: string, callback: any, ...: any): boolean
    if not State.Alive then return false end
    State.FeatureTicks[name] = (State.FeatureTicks[name] or 0) + 1
    local identity = getthreadidentity()
    setthreadidentity(8)
    local ok, result = pcall(callback, ...)
    setthreadidentity(identity)
    if ok then
        State.FeatureLastSuccess[name] = os.clock()
    else
        State.FeatureErrors[name] = tostring(result)
        local lastWarning = State.FeatureWarnings[name] or -math.huge
        if os.clock() - lastWarning >= 5 then
            State.FeatureWarnings[name] = os.clock()
            warn("[Wanted " .. name .. "] " .. tostring(result))
        end
    end
    return ok
end
State.RunFeature = runFeature


local function updateKeybindList()
    local list = State.KeybindList
    if list then list.Update() end
end
State.UpdateKeybindList = updateKeybindList

local function createKeybindList()
    local list: any = {Tweens = {}, Wanted = false, Animating = false, Dragging = false, Transition = 0}
    State.KeybindList = list
    local function make(className: string, parent: Instance?, properties: any): any
        local instance: any = Instance.new(className)
        for property, value in pairs(properties) do instance[property] = value end
        instance.Parent = parent
        return instance
    end
    local gui = make("ScreenGui", nil, {
        Name = "WantedActiveKeybinds", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    list.Gui = gui
    gui.ScreenInsets = Enum.ScreenInsets.None
    parentGui(gui)
    local root = make("CanvasGroup", gui, {
        Name = "ActiveKeybinds", BackgroundTransparency = 1, Size = UDim2.fromOffset(280, 104),
        Visible = false, GroupTransparency = 1,
    })
    list.Root = root
    local scale = make("UIScale", root, {Scale = 0.96})
    list.Scale = scale
    for index = 3, 1, -1 do
        local shadow = make("Frame", root, {
            Name = "Shadow", BorderSizePixel = 0, BackgroundColor3 = Color3.new(),
            BackgroundTransparency = 0.91 - (3 - index) * 0.04,
            Position = UDim2.fromOffset(6 - index, 7 + index),
            Size = UDim2.new(1, -12 + index * 2, 1, -18 + index),
        })
        make("UICorner", shadow, {CornerRadius = UDim.new(0, 14 + index)})
    end
    local panel = make("Frame", root, {
        Name = "Panel", Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 1, -18),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
    })
    make("UICorner", panel, {CornerRadius = UDim.new(0, 12)})
    make("UIGradient", panel, {Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 35, 48)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 20, 29)),
    })})
    local stroke = make("UIStroke", panel, {Thickness = 1, Transparency = 0.62, Color = Config.CircleColor})
    local accent = make("Frame", panel, {
        Name = "Accent", Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 2),
        BorderSizePixel = 0, BackgroundColor3 = Config.CircleColor,
    })
    make("UICorner", accent, {CornerRadius = UDim.new(0, 2)})
    make("UIGradient", accent, {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0),
        NumberSequenceKeypoint.new(0.65, 0), NumberSequenceKeypoint.new(1, 1),
    })})
    local function label(parent: Instance, properties: any): any
        local defaults: any = {
            BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235, 237, 245),
            Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        }
        for key, value in pairs(properties) do defaults[key] = value end
        return make("TextLabel", parent, defaults)
    end
    label(panel, {Name = "Title", Text = "KEYBINDS", TextSize = 11, Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(164, 171, 193), Position = UDim2.fromOffset(15, 9), Size = UDim2.fromOffset(150, 24)})
    local grip = label(panel, {Name = "DragGrip", Text = "≡", TextSize = 21,
        TextColor3 = Color3.fromRGB(119, 128, 153), Position = UDim2.new(1, -37, 0, 6), Size = UDim2.fromOffset(25, 28)})
    local header = make("TextButton", panel, {
        Name = "DragHeader", Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 37), Active = true,
    })
    list.Header = header
    make("Frame", panel, {Name = "Divider", BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(88, 96, 122), BackgroundTransparency = 0.76,
        Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 1)})
    list.Rows = {}
    for index, specification in ipairs({
        {Field = "Enabled", KeyField = "AimKey", Text = "Silent aim"},
        {Field = "VehicleAcceleration", KeyField = "VehicleBoostKey", Text = "Acceleration", Tint = Color3.fromRGB(255, 201, 112)},
        {Field = "VehicleFly", KeyField = "VehicleFlyKey", Text = "Vehicle flight", Tint = Color3.fromRGB(184, 165, 255)},
        {Field = "Noclip", KeyField = "NoclipKey", Text = "Character noclip", Tint = Color3.fromRGB(120, 220, 255)},
        {Field = "VehicleNoclip", KeyField = "VehicleNoclipKey", Text = "Vehicle noclip", Tint = Color3.fromRGB(255, 162, 202)},
    }) do
        local row: any = specification
        row.Index = index
        row.Frame = make("Frame", panel, {Name = row.Text, BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 0, 30), Visible = false})
        row.Dot = make("Frame", row.Frame, {Name = "EnabledDot", BorderSizePixel = 0,
            BackgroundColor3 = row.Tint or Color3.fromRGB(117, 234, 174),
            Position = UDim2.fromOffset(2, 13), Size = UDim2.fromOffset(6, 6)})
        make("UICorner", row.Dot, {CornerRadius = UDim.new(1, 0)})
        row.Name = label(row.Frame, {Name = "Feature", Text = row.Text,
            Position = UDim2.fromOffset(17, 0), Size = UDim2.fromOffset(122, 30)})
        row.Pill = make("Frame", row.Frame, {Name = "KeyPill", AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Color3.fromRGB(39, 47, 65), BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(42, 27)})
        make("UICorner", row.Pill, {CornerRadius = UDim.new(0, 7)})
        row.Stroke = make("UIStroke", row.Pill, {Thickness = 1, Color = row.Tint or Config.CircleColor, Transparency = 0.78})
        row.Key = label(row.Pill, {Name = "Key", Text = "", TextSize = 12, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = row.Tint or Config.CircleColor, Size = UDim2.fromScale(1, 1)})
        table.insert(list.Rows, row)
    end
    list.Name, list.Key = list.Rows[1].Name, list.Rows[1].Key

    local function tween(name: string, object: Instance, duration: number, properties: any, style: Enum.EasingStyle?)
        if list.Tweens[name] then list.Tweens[name]:Cancel() end
        local animation = TweenService:Create(object, TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
        list.Tweens[name] = animation
        animation:Play()
    end
    local function cancelMotion()
        if list.Tweens.Visibility then list.Tweens.Visibility:Cancel() end
        list.Animating = false
    end
    local function availableSpace(): Vector2?
        local camera = workspace.CurrentCamera
        if not camera or camera.ViewportSize.X < 320 or camera.ViewportSize.Y < 144 then return nil end
        return Vector2.new(math.max(0, camera.ViewportSize.X - 296), math.max(0, camera.ViewportSize.Y - (list.Height or 104) - 16))
    end
    local function rootPosition(position: Vector2): UDim2
        local origin = gui.AbsolutePosition
        return UDim2.fromOffset(position.X - origin.X, position.Y - origin.Y)
    end
    local function desiredPosition(): Vector2
        local area = availableSpace() or Vector2.zero
        return Vector2.new(8 + math.clamp(Config.KeybindX, 0, 1) * area.X,
            8 + math.clamp(Config.KeybindY, 0, 1) * area.Y)
    end
    local function setVisible(visible: boolean, position: Vector2)
        list.Transition += 1
        local transition = list.Transition
        list.Wanted, list.Animating = visible, true
        if visible then
            if not root.Visible then
                root.GroupTransparency, scale.Scale = 1, 0.96
                root.Position = rootPosition(position - Vector2.new(0, 10))
            end
            root.Visible = true
            tween("Visibility", root, 0.24, {GroupTransparency = 0, Position = rootPosition(position)})
            tween("Scale", scale, 0.24, {Scale = 1})
        else
            list.Dragging, list.DragInput = false, nil
            tween("Visibility", root, 0.16, {GroupTransparency = 1, Position = rootPosition(position - Vector2.new(0, 6))})
            tween("Scale", scale, 0.16, {Scale = 0.98})
        end
        task.delay(if visible then 0.25 else 0.17, function()
            if not State.Alive or list.Transition ~= transition then return end
            list.Animating = false
            if not list.Wanted then root.Visible = false end
        end)
    end
    list.Update = function()
        if not State.Alive then return end
        local count = 0
        for _, row in ipairs(list.Rows) do
            local active = Config[row.Field]
            row.Frame.Visible = active
            if row.Key.Text ~= Config[row.KeyField] then
                row.Key.Text = Config[row.KeyField]
                row.Pill.Size = UDim2.fromOffset(math.clamp(#row.Key.Text * 7 + 20, 40, 112), 27)
                row.Pill.BackgroundColor3 = (row.Tint or Config.CircleColor):Lerp(Color3.fromRGB(29, 34, 48), 0.65)
                tween("KeyFlash" .. row.Index, row.Pill, 0.28, {BackgroundColor3 = Color3.fromRGB(39, 47, 65)})
            end
            row.Stroke.Color, row.Key.TextColor3 = row.Tint or Config.CircleColor, row.Tint or Config.CircleColor
            if active then
                local y = 44 + count * 34
                if row.TargetY ~= y then
                    row.TargetY = y
                    tween("Row" .. row.Index, row.Frame, 0.18, {Position = UDim2.fromOffset(14, y)})
                end
                count += 1
            end
        end
        local height = 70 + count * 34
        if list.Height ~= height then
            list.Height = height
            tween("Height", root, 0.18, {Size = UDim2.fromOffset(280, height)})
        end
        local position = desiredPosition()
        local visible = not usingTouch() and count > 0 and availableSpace() ~= nil
        if list.Color ~= Config.CircleColor then
            list.Color = Config.CircleColor
            stroke.Color, accent.BackgroundColor3 = list.Color, list.Color
        end
        if visible ~= list.Wanted then
            setVisible(visible, position)
        elseif visible and not list.Animating and not list.Dragging then
            root.Position = rootPosition(position)
        end
    end

    list.BeginDrag = function(pointer: Vector2)
        if not list.Wanted then return end
        list.Transition += 1
        cancelMotion()
        list.Dragging, list.DragStart = true, pointer
        list.StartPosition = root.AbsolutePosition
        root.GroupTransparency = 0
        tween("Scale", scale, 0.12, {Scale = 1.015})
        tween("Border", stroke, 0.12, {Transparency = 0.18})
    end
    list.MoveDrag = function(pointer: Vector2)
        if not list.Dragging then return end
        local area = availableSpace()
        if not area then return end
        local position = list.StartPosition + pointer - list.DragStart
        position = Vector2.new(math.clamp(position.X, 8, area.X + 8), math.clamp(position.Y, 8, area.Y + 8))
        Config.KeybindX = if area.X > 0 then (position.X - 8) / area.X else 0
        Config.KeybindY = if area.Y > 0 then (position.Y - 8) / area.Y else 0
        root.Position = rootPosition(position)
    end
    list.EndDrag = function()
        list.Dragging, list.DragInput = false, nil
        tween("Scale", scale, 0.18, {Scale = 1})
        tween("Border", stroke, 0.18, {Transparency = 0.62})
    end
    list.Destroy = function()
        for _, animation in pairs(list.Tweens) do animation:Cancel() end
        gui:Destroy()
    end
    table.insert(State.Connections, header.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        list.BeginDrag(Vector2.new(input.Position.X, input.Position.Y))
        list.DragInput = input
    end))
    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if not list.Dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input == list.DragInput then
            list.MoveDrag(Vector2.new(input.Position.X, input.Position.Y))
        end
    end))
    table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
        if list.Dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == list.DragInput) then list.EndDrag() end
    end))
    table.insert(State.Connections, UserInputService.WindowFocusReleased:Connect(function()
        if list.Dragging then list.EndDrag() end
    end))
    table.insert(State.Connections, header.MouseEnter:Connect(function()
        tween("Grip", grip, 0.14, {TextColor3 = Config.CircleColor})
    end))
    table.insert(State.Connections, header.MouseLeave:Connect(function()
        tween("Grip", grip, 0.14, {TextColor3 = Color3.fromRGB(119, 128, 153)})
    end))
    list.Update()
end


-- Luna leaves service connections behind after destroying its ScreenGui.
local function disconnectLibrarySignals()
    if not librarySource then return end
    local signals: {any} = {
        UserInputService.InputBegan,
        UserInputService.InputChanged,
        UserInputService.InputEnded,
        RunService.Stepped,
    }
    for _, signal in ipairs(signals) do
        local ok, connections = pcall(getconnections, signal)
        if ok then
            for _, connection in ipairs(connections) do
                local callback = connection.Function
                if type(callback) == "function" then
                    local readable, source = pcall(function() return debug.info(callback, "s") end)
                    if readable and source == librarySource then
                        pcall(function() connection:Disconnect() end)
                    end
                end
            end
        end
    end
end

local function cleanup()
    if not State.Alive then return end
    pcall(function() State.CleanupTrace = debug.traceback("Wanted cleanup", 2) end)
    State.Alive = false
    State.Target = nil
    for _, connection in ipairs(State.Connections) do
        connection:Disconnect()
    end
    table.clear(State.Connections)
    if State.KeybindList and State.KeybindList.Destroy then State.KeybindList.Destroy() end
    RunService:UnbindFromRenderStep(rotationBinding)
    releaseRotation()
    releaseVehicleAssist()
    releaseNoclip()
    if hook and ClientGuns.MakeGunProjectiles == hook then
        ClientGuns.MakeGunProjectiles = original
    end
    if networkHook and Network.FireServer == networkHook then
        Network.FireServer = originalNetworkFire
    end
    if batchHook and ClientGuns.BatchAutoFirePacket == batchHook then
        ClientGuns.BatchAutoFirePacket = originalBatchAuto
    end
    table.clear(State.ShotDirections)
    for drawing in pairs(State.Drawings) do removeDrawing(drawing) end
    if State.NativeOverlay then State.NativeOverlay:Destroy() end
    if State.MobileGui then State.MobileGui:Destroy() end
    for highlight in pairs(State.Highlights) do pcall(function() highlight:Destroy() end) end
    table.clear(State.Highlights)
    table.clear(State.ESPEntries)
    table.clear(State.WeaponCache)
    table.clear(State.NPCModels)
    table.clear(State.ItemEntries)
    if State.HighlightFolder then State.HighlightFolder:Destroy() end
    if circle then
        pcall(function() circle:Remove() end)
        circle = nil
    end
    disconnectLibrarySignals()
    if Luna then pcall(function() Luna:Destroy() end) end
    if ClientGuns.__WantedAimLuna == State then
        ClientGuns.__WantedAimLuna = nil
    end
    if executorEnvironment.__WantedAimLunaState == State then executorEnvironment.__WantedAimLunaState = nil end
end
State.Cleanup = cleanup
if type(lifecycle) == "table" and type(lifecycle.onCleanup) == "function" then
    lifecycle.onCleanup(cleanup)
end

local function validParty(id: any): boolean
    return id ~= nil and id ~= false and id ~= "" and id ~= 0
end

local function protected(
    myTeam: any, theirTeam: any, myParty: any, theirParty: any,
    policeCheck: boolean, crewCheck: boolean
): boolean
    if crewCheck and validParty(myParty) and myParty == theirParty then
        return true
    end
    -- Syndicate membership alone never makes someone friendly.
    return policeCheck and myTeam == "police" and theirTeam == "police"
end
State.IsProtected = protected

local function isProtected(player: Player): boolean
    return protected(
        LocalPlayer:GetAttribute("currentTeam"),
        player:GetAttribute("currentTeam"),
        LocalPlayer:GetAttribute("partyId"),
        player:GetAttribute("partyId"),
        Config.PoliceCheck,
        Config.CrewCheck
    )
end

-- Built by Olivia — https://discord.gg/ojailbreaks
-- Luau; isolated visibility helper; Roblox client.
-- Integrate above target selection, then keep one closure for the session.

local MAX_RAY_LENGTH = 15000
local MIN_RAY_LENGTH = 0.001

local function isFiniteNumber(value: number): boolean
    return value == value and value > -math.huge and value < math.huge
end

local function isFiniteVector(value: any): boolean
    return typeof(value) == "Vector3"
        and isFiniteNumber(value.X)
        and isFiniteNumber(value.Y)
        and isFiniteNumber(value.Z)
end

-- Wanted classifies the upper 20% of the root collider as an NPC headshot.
-- Animated visual heads are not the damage collider and may not be streamed.
local function aimPosition(part: BasePart): Vector3
    local model = part.Parent
    local folder = workspace:FindFirstChild("Mobs")
    if model and model:IsA("Model") and model.Parent == folder and model.PrimaryPart == part then
        return part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y * 0.4, 0))
    end
    return part.Position
end
State.AimPosition = aimPosition

local function makeWallVisibility(world: Workspace, localPlayer: Player)
    return function(origin: any, target: any, explicitModel: Model?): (boolean, string)
        if not isFiniteVector(origin) then
            return false, "invalid-origin"
        end
        if typeof(target) ~= "Instance" or target.Parent == nil then
            return false, "missing-target"
        end

        local part: BasePart? = nil
        local model: Model? = nil
        if target:IsA("BasePart") then
            part = target
            if typeof(explicitModel) == "Instance"
                and explicitModel:IsA("Model")
                and target:IsDescendantOf(explicitModel) then
                model = explicitModel
            end
        elseif target:IsA("Model") then
            model = target
            local folder = world:FindFirstChild("Mobs")
            local head = if target.Parent == folder then target.PrimaryPart else target:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                part = head
            end
        end
        if part == nil or not part:IsDescendantOf(world) then
            return false, "invalid-target"
        end

        local endpoint = aimPosition(part)
        if not isFiniteVector(endpoint) then
            return false, "invalid-endpoint"
        end
        local direction = endpoint - origin
        local distance = direction.Magnitude
        if not isFiniteNumber(distance) or distance > MAX_RAY_LENGTH then
            return false, "out-of-range"
        end
        if distance <= MIN_RAY_LENGTH then
            return true, "same-position"
        end

        -- Fresh filters track respawns and camera replacement without stale references.
        local ignored: {Instance} = {}
        local character = localPlayer.Character
        if character then
            table.insert(ignored, character)
        end
        local camera = world.CurrentCamera
        if camera then
            table.insert(ignored, camera)
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignored
        params.IgnoreWater = true
        params.RespectCanCollide = true

        -- Raycast can fail during world teardown; a failed query never permits redirect.
        local ok, result = pcall(function()
            return world:Raycast(origin, direction, params)
        end)
        if not ok then
            return false, "raycast-failed"
        end
        if result == nil then
            return true, "clear"
        end
        local hit = result.Instance
        -- Accept the target collider while keeping the headshot endpoint.
        if hit == part or (model ~= nil and hit:IsDescendantOf(model)) then
            return true, "target-hit"
        end
        return false, "blocked"
    end
end
local hasLineOfSight = makeWallVisibility(workspace, LocalPlayer)
State.HasLineOfSight = hasLineOfSight

local function npcAimPart(model: any, container: Instance?): BasePart?
    local folder = container or workspace:FindFirstChild("Mobs")
    if not folder or typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= folder
        or not model:IsDescendantOf(workspace) or model == LocalPlayer.Character
        or Players:GetPlayerFromCharacter(model) ~= nil or model:GetAttribute("objectId") == nil
        or model:GetAttribute("isDestroyed") == true or model:GetAttribute("isDead") == true then return nil end
    -- Mob Humanoids can remain at 100 after death; ClientMob.GetHealth reads this attribute.
    local health = model:GetAttribute("health")
    if type(health) ~= "number" or not isFiniteNumber(health) or health <= 0 then return nil end
    -- This collider owns hit registration; aimPosition selects only its headshot band.
    local part = model.PrimaryPart
    if not part or not part:IsA("BasePart") or not part:IsDescendantOf(model)
        or not isFiniteVector(part.Position) then return nil end
    return part
end
State.NPCAimPart = npcAimPart

local function refreshNPCs()
    local models = {}
    local stats = {Tracked = 0, Alive = 0, Available = 0}
    local folder = workspace:FindFirstChild("Mobs")
    if folder and Config.TargetNPCs then
        for index, model in ipairs(folder:GetChildren()) do
            if index > 512 then break end
            if not model:IsA("Model") then continue end
            table.insert(models, model)
            stats.Tracked += 1
            local health = model:GetAttribute("health")
            if type(health) == "number" and isFiniteNumber(health) and health > 0 then stats.Alive += 1 end
            if npcAimPart(model) then stats.Available += 1 end
        end
    end
    State.NPCModels, State.NPCStats = models, stats
end
State.RefreshNPCs = refreshNPCs

local function targetModel(part: BasePart?): Model?
    local folder = workspace:FindFirstChild("Mobs")
    local parent = part and part.Parent
    for _ = 1, 8 do
        if not parent or parent == workspace then break end
        if parent:IsA("Model") and (parent.Parent == folder or Players:GetPlayerFromCharacter(parent)) then return parent end
        parent = parent.Parent
    end
    return nil
end
State.TargetModel = targetModel

local function validAimTarget(part: BasePart?): boolean
    if not part or not part:IsDescendantOf(workspace) then return false end
    local model = targetModel(part)
    if not model then return false end
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        return Config.TargetPlayers and player ~= LocalPlayer and not isProtected(player)
            and humanoid ~= nil and humanoid.Health > 0 and model:FindFirstChild("Head") == part
    end
    return Config.TargetNPCs and npcAimPart(model) == part
end
State.ValidAimTarget = validAimTarget

local function getTarget(ignoreAimSwitch: boolean?): BasePart?
    local camera = workspace.CurrentCamera
    if not camera or not State.Alive or (not Config.Enabled and not ignoreAimSwitch) then return nil end
    local center = camera.ViewportSize / 2
    local bestDistance = Config.Radius * Config.Radius
    local best: BasePart? = nil
    local function score(part: BasePart, model: Model)
        local endpoint = aimPosition(part)
        if not isFiniteVector(endpoint) then return end
        local point, onScreen = camera:WorldToViewportPoint(endpoint)
        if not onScreen or point.Z <= 0 then return end
        local dx, dy = point.X - center.X, point.Y - center.Y
        local distance = dx * dx + dy * dy
        if distance <= bestDistance then
            if Config.WallCheck and not hasLineOfSight(camera.CFrame.Position, part, model) then return end
            bestDistance = distance
            best = part
        end
    end
    if Config.TargetPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or isProtected(player) then continue end
            local character = player.Character
            if not character or not character:IsDescendantOf(workspace) then continue end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            if not humanoid or humanoid.Health <= 0 or not head or not head:IsA("BasePart") then continue end
            score(head, character)
        end
    end
    if Config.TargetNPCs then
        for _, model in ipairs(State.NPCModels) do
            local part = npcAimPart(model)
            if part then score(part, model) end
        end
    end
    return best
end
State.GetTarget = getTarget

-- Turn the networked character, never the camera or a local-only joint.
local function flatFacing(position: Vector3, target: Vector3): CFrame?
    local dx, dz = target.X - position.X, target.Z - position.Z
    if dx ~= dx or dz ~= dz or math.abs(dx) > 1e8 or math.abs(dz) > 1e8 then return nil end
    if dx * dx + dz * dz < 0.000001 then return nil end
    return CFrame.lookAt(position, position + Vector3.new(dx, 0, dz))
end
State.FlatFacing = flatFacing

local function getWantedCharacterModel(): any
    local identity = getthreadidentity()
    local ok, model = pcall(function()
        local playerObject = ClientPlayers.Get()
        local tool = playerObject and playerObject:GetEquippedReplica()
        return tool and tool:GetComponent("CharacterModel") or nil
    end)
    setthreadidentity(identity)
    if not ok then State.LastRotationError = tostring(model) end
    return ok and model or nil
end

local function restoreNativeRotation(humanoid: Humanoid?)
    if not humanoid or not humanoid.Parent then return end
    -- Wanted normally owns AutoRotate and AlignOrientation; cached false is not a release.
    humanoid.AutoRotate = true
    if humanoid.Parent == LocalPlayer.Character then
        local model = getWantedCharacterModel()
        if model then
            local identity = getthreadidentity()
            local ok, message = pcall(function()
                model:LocalPlayerStepped(1 / 60)
                model:CFrame(1 / 60)
            end)
            setthreadidentity(identity)
            if not ok then State.LastRotationError = tostring(message) end
        end
    end
end

releaseRotation = function(forceRecover: boolean?)
    local rotation = State.Rotation
    local humanoid = rotation.Humanoid
    if not humanoid and forceRecover and LocalPlayer.Character then
        humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    restoreNativeRotation(humanoid)
    rotation.Humanoid = nil
    rotation.Root = nil
    rotation.Target = nil
    rotation.Active = false
    rotation.LastAcquire = -math.huge
end

local function setRotationEnabled(enabled: boolean, syncToggle: boolean?)
    Config.RotationEnabled = enabled
    if not enabled then releaseRotation() end
    if syncToggle and State.Controls.SilentRotation then
        State.Controls.SilentRotation:Set({CurrentValue = enabled})
    end
end
State.SetRotationEnabled = setRotationEnabled

local function setAimEnabled(enabled: boolean, syncToggle: boolean?)
    Config.Enabled = enabled
    updateKeybindList()
    if not enabled then
        State.Target = nil
        releaseRotation(true)
    end
    if syncToggle and State.Controls.Enabled then
        State.Controls.Enabled:Set({CurrentValue = enabled})
    end
end
State.SetAimEnabled = setAimEnabled

local function updateRotation()
    if not State.Alive or not Config.Enabled or not Config.RotationEnabled then
        if State.Rotation.Active then releaseRotation() end
        return
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    -- A seated root belongs to the vehicle assembly; rotating it would turn the vehicle.
    if not character or not humanoid or humanoid.Health <= 0 or humanoid.Sit
        or humanoid.SeatPart or not root or not root:IsA("BasePart") or root.Anchored then
        releaseRotation()
        return
    end
    local rotation = State.Rotation
    local now = os.clock()
    if now - rotation.LastAcquire >= 1 / 30 then
        rotation.Target = getTarget()
        rotation.LastAcquire = now
    end
    local head = rotation.Target
    if not validAimTarget(head) then
        releaseRotation()
        return
    end
    local facing = flatFacing(root.Position, aimPosition(head))
    if not facing then
        releaseRotation()
        return
    end
    if rotation.Humanoid ~= humanoid or rotation.Root ~= root then
        releaseRotation()
        rotation.Humanoid = humanoid
        rotation.Root = root
    end
    humanoid.AutoRotate = false
    rotation.Target = head
    rotation.Active = true
    local wantedModel = getWantedCharacterModel()
    if wantedModel then
        wantedModel.rootCF = facing.Rotation
        if wantedModel.alignOrientation then wantedModel.alignOrientation.CFrame = facing end
    end
    if root.CFrame.LookVector:Dot(facing.LookVector) < 0.99999
        or root.CFrame.UpVector.Y < 0.99999 then
        root.CFrame = facing
    end
end
State.UpdateRotation = updateRotation

local function rewriteProjectiles(data: any, targetPosition: Vector3, targetPart: BasePart?): any
    if type(data) ~= "table" or not validAimTarget(targetPart) then return data end
    local result = table.clone(data)
    for key, projectile in pairs(data) do
        if type(projectile) == "table" and typeof(projectile[2]) == "CFrame" then
            local aim = projectile[2]
            if Config.WallCheck and targetPart
                and not hasLineOfSight(aim.Position, targetPart, targetModel(targetPart)) then continue end
            local delta = targetPosition - aim.Position
            if delta.Magnitude > 0.001 then
                local copy = table.clone(projectile)
                copy[2] = CFrame.lookAt(aim.Position, targetPosition, aim.UpVector)
                result[key] = copy
            end
        end
    end
    return result
end
State.RewriteProjectiles = rewriteProjectiles

-- Shooter builds independent local and compressed network tables. Join by projectile ID,
-- never by timing or whichever target happens to be selected when an auto batch is sent.
local function rememberShotDirections(toolId: any, before: any, after: any)
    local now = os.clock()
    local count = 0
    for id, shot in pairs(State.ShotDirections) do
        if now - shot.At > 5 then
            State.ShotDirections[id] = nil
        else
            count += 1
        end
    end
    for key, projectile in pairs(after) do
        if projectile == before[key] then continue end
        if count < 512 and type(projectile) == "table"
            and (type(projectile[1]) == "string" or type(projectile[1]) == "number")
            and typeof(projectile[2]) == "CFrame" then
            local ok, compressed = pcall(MathUtil.CompressCFrame, projectile[2])
            if ok and compressed ~= nil then
                State.ShotDirections[projectile[1]] = {ToolId = toolId, Compressed = compressed, At = now}
                State.RewrittenProjectiles += 1
                count += 1
                continue
            end
        end
        -- Never change local prediction if its matching packet cannot be changed.
        after[key] = before[key]
    end
end

local function syncShotPacket(toolId: any, data: any): any
    if type(data) ~= "table" then return data end
    local result: any = nil
    local now = os.clock()
    for key, projectile in pairs(data) do
        if type(projectile) ~= "table" then continue end
        local id = projectile[1]
        local shot = id ~= nil and State.ShotDirections[id]
        if type(shot) ~= "table" or shot.ToolId ~= toolId then continue end
        State.ShotDirections[id] = nil
        if now - shot.At > 5 then continue end
        result = result or table.clone(data)
        local copy = table.clone(projectile)
        copy[2] = shot.Compressed
        result[key] = copy
        State.SyncedProjectiles += 1
    end
    return result or data
end
State.SyncShotPacket = syncShotPacket


-- Remove only Luna's named effects; preserve Wanted's own post-processing.
local function disableLunaEffect(effect: Instance)
    if effect:IsA("DepthOfFieldEffect") and effect.Name:match("^DPT_%d+$") then
        effect.Enabled = false
        effect.NearIntensity = 0
        effect.FarIntensity = 0
    end
end

local function removeLegacyLunaBlur()
    RunService:UnbindFromRenderStep("neon::1")
    for _, effect in ipairs(Lighting:GetChildren()) do disableLunaEffect(effect) end
    local camera = workspace.CurrentCamera
    if camera then
        for _, child in ipairs(camera:GetChildren()) do
            if child:IsA("Folder") and child.Name == "LunaBlur" then child:Destroy() end
        end
    end
end

local CORNERS = {
    Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1),
    Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, -1), Vector3.new(1, -1, 1),
    Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
}
local function screenBounds(character: Model, camera: Camera): (Vector2?, Vector2?)
    local frame, size = character:GetBoundingBox()
    local half = size / 2
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, corner in ipairs(CORNERS) do
        local point = camera:WorldToViewportPoint(frame:PointToWorldSpace(corner * half))
        if point.Z <= 0.05 then return nil, nil end
        minX, minY = math.min(minX, point.X), math.min(minY, point.Y)
        maxX, maxY = math.max(maxX, point.X), math.max(maxY, point.Y)
    end
    local viewport = camera.ViewportSize
    if maxX < 0 or maxY < 0 or minX > viewport.X or minY > viewport.Y then return nil, nil end
    if maxX - minX < 1 or maxY - minY < 1 then return nil, nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end
State.ScreenBounds = screenBounds

local MPH_PER_STUD = 0.6262074377908017
local KMH_PER_MPH = 1.60934
local function kmhToStuds(kmh: number): number
    -- Invert Wanted's two integer speedometer conversions, so 600 displays as 600.
    return (math.ceil(math.clamp(kmh, 30, 600) / KMH_PER_MPH) + 0.001) / MPH_PER_STUD
end
local function studsToKmh(speed: number): number
    return math.floor(math.floor(math.abs(speed) * MPH_PER_STUD) * KMH_PER_MPH)
end
State.KmhToStuds, State.StudsToKmh = kmhToStuds, studsToKmh

local function resetVehicleRamp(ramp: any, status: string)
    ramp.Active, ramp.Elapsed, ramp.StartSpeed, ramp.LastSpeed = false, 0, 0, nil
    ramp.Chassis, ramp.Status = nil, status
end
local function restoreVehicleOverrides(keep: any?)
    for chassis, record in pairs(State.VehicleOverrides) do
        if chassis == keep then continue end
        if chassis.topSpeed == record.Applied then chassis.topSpeed = record.Original end
        State.VehicleOverrides[chassis] = nil
    end
end
releaseVehicleAssist = function()
    destroyVehicleFlight()
    restoreVehicleOverrides()
    State.VehicleChassis, State.LastVehicleLookup = nil, -math.huge
    resetVehicleRamp(State.Vehicle, "Waiting for a driver seat")
end
State.ReleaseVehicleAssist = releaseVehicleAssist

local function applyVehicleSpeedLimit(chassis: any)
    local boosted = Config.VehicleAcceleration and Config.VehicleSpeedOverride
    restoreVehicleOverrides(if boosted then chassis else nil)
    if not boosted then return end
    local record = State.VehicleOverrides[chassis]
    if not record then
        record = {Original = rawget(chassis, "topSpeed")}
        State.VehicleOverrides[chassis] = record
    elseif chassis.topSpeed ~= record.Applied then
        record.Original = rawget(chassis, "topSpeed")
    end
    record.Applied = kmhToStuds(Config.VehicleMaxKmh)
    chassis.topSpeed = record.Applied
end

local function acceleratedVelocity(velocity: Vector3, forward: Vector3, requested: number): (Vector3?, number?)
    if not isFiniteVector(velocity) or not isFiniteVector(forward) or not isFiniteNumber(requested) then return nil, nil end
    local direction = Vector3.new(forward.X, 0, forward.Z)
    if direction.Magnitude < 0.1 then return nil, nil end
    direction = direction.Unit
    local current = velocity:Dot(direction)
    local nextSpeed = math.max(current, requested)
    return velocity + direction * (nextSpeed - current), nextSpeed
end
State.AcceleratedVelocity = acceleratedVelocity

local function stepVehicleAcceleration(chassis: any, dt: number, ramp: any): boolean
    if not chassis or chassis.isDestroyed or not chassis.isDriver
        or (chassis.vehicleType ~= "Car" and chassis.vehicleType ~= "Motorcycle") then
        restoreVehicleOverrides()
        resetVehicleRamp(ramp, "Waiting for a driver seat")
        return false
    end
    local vehicle = chassis.clientVehicle
    local data = vehicle and vehicle.replica and vehicle.replica.Data
    if not data or data.driver ~= LocalPlayer then
        restoreVehicleOverrides()
        resetVehicleRamp(ramp, "Driver only")
        return false
    end
    local model = chassis.model
    local root = typeof(model) == "Instance" and model:FindFirstChild("Chassis")
    if not root or not root:IsA("BasePart") or not root:IsDescendantOf(workspace) or root.Anchored then
        restoreVehicleOverrides()
        resetVehicleRamp(ramp, "Waiting for vehicle chassis")
        return false
    end
    applyVehicleSpeedLimit(chassis)
    local velocity = root.AssemblyLinearVelocity
    if not isFiniteVector(velocity) then return false end
    local throttle, brake, wheels = chassis.throttle, chassis.brake, chassis.groundWheels
    local grounded = type(wheels) == "number" and isFiniteNumber(wheels) and wheels >= 1 and root.CFrame.UpVector.Y >= 0.35
    if Config.VehicleInstantBrakes and grounded and not chassis.inWater
        and ((type(brake) == "number" and isFiniteNumber(brake) and brake > 0) or chassis.handbrake) then
        root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
        local angular = root.AssemblyAngularVelocity
        root.AssemblyAngularVelocity = Vector3.new(angular.X, 0, angular.Z)
        chassis.engineSpeed, chassis.forwardSpeed, chassis.speed, chassis.sideSpeed = 0, 0, 0, 0
        if type(chassis.axles) == "table" then
            for index, axle in ipairs(chassis.axles) do
                if index > 8 then break end
                if type(axle.speed) == "number" then axle.speed = 0 end
            end
        end
        resetVehicleRamp(ramp, "Instant brake")
        ramp.CurrentKmh = 0
        return true
    end
    if not Config.VehicleAcceleration then
        resetVehicleRamp(ramp, if Config.VehicleSpeedOverride then "Custom top speed active" else "Acceleration assist off")
        return false
    end
    if type(throttle) ~= "number" or not isFiniteNumber(throttle) or throttle < 0.95
        or type(brake) ~= "number" or not isFiniteNumber(brake) or brake > 0
        or chassis.handbrake or chassis.inWater or not grounded then
        resetVehicleRamp(ramp, "Ready — hold forward throttle")
        return false
    end
    if not isFiniteNumber(dt) or dt <= 0 or type(chassis._getTopSpeed) ~= "function" then return false end
    local identity = getthreadidentity()
    local ok, topSpeed = pcall(chassis._getTopSpeed, chassis)
    setthreadidentity(identity)
    if not ok or type(topSpeed) ~= "number" or not isFiniteNumber(topSpeed) or topSpeed <= 0 or topSpeed > 1000 then
        resetVehicleRamp(ramp, "Vehicle top speed unavailable")
        return false
    end
    local horizontal = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if horizontal.Magnitude < 0.1 then return false end
    local current = velocity:Dot(horizontal.Unit)
    if current < -1 then
        resetVehicleRamp(ramp, "Waiting until reverse motion stops")
        return false
    end
    local lostSpeed = ramp.LastSpeed and ramp.LastSpeed > 30 and current < ramp.LastSpeed * 0.4
    if not ramp.Active or ramp.Chassis ~= chassis or lostSpeed then
        ramp.Active, ramp.Chassis, ramp.Elapsed, ramp.StartSpeed = true, chassis, 0, math.max(0, current)
    end
    ramp.Elapsed += math.clamp(dt, 0, 0.25)
    local duration = math.clamp(Config.VehicleAccelTime, 0, 2)
    local fraction = if duration <= 0.001 then 1 else math.clamp(ramp.Elapsed / duration, 0, 1)
    local requested = math.min(topSpeed, ramp.StartSpeed + math.max(0, topSpeed - ramp.StartSpeed) * fraction)
    local newVelocity, nextSpeed = acceleratedVelocity(velocity, root.CFrame.LookVector, requested)
    if not newVelocity or not nextSpeed then return false end
    if Config.VehicleSpeedOverride then
        local planar = Vector3.new(newVelocity.X, 0, newVelocity.Z)
        local limit = kmhToStuds(Config.VehicleMaxKmh)
        if planar.Magnitude > limit then
            planar = planar.Unit * limit
            newVelocity = Vector3.new(planar.X, newVelocity.Y, planar.Z)
            nextSpeed = newVelocity:Dot(horizontal.Unit)
        end
    end
    if (newVelocity - velocity).Magnitude > 0.001 then root.AssemblyLinearVelocity = newVelocity end
    if type(chassis.engineSpeed) == "number" then chassis.engineSpeed = math.max(chassis.engineSpeed, nextSpeed) end
    if type(chassis.axles) == "table" then
        for index, axle in ipairs(chassis.axles) do
            if index > 8 then break end
            if axle.isPowered and type(axle.speed) == "number" then axle.speed = math.max(axle.speed, nextSpeed) end
        end
    end
    chassis.forwardSpeed, chassis.speed, chassis.velocity = nextSpeed, math.abs(nextSpeed), newVelocity
    ramp.LastSpeed, ramp.TargetSpeed, ramp.CurrentKmh = nextSpeed, topSpeed, studsToKmh(nextSpeed)
    ramp.Status = if nextSpeed >= topSpeed * 0.99 then "At configured top speed" else "Accelerating"
    return true
end
State.StepVehicleAcceleration = stepVehicleAcceleration

destroyVehicleFlight = function()
    local flight = State.VehicleFlight
    if not flight then return end
    for _, field in ipairs({"Velocity", "Orientation", "Attachment"}) do
        local instance = flight[field]
        if instance then instance:Destroy() end
    end
    State.VehicleFlight = nil
end
State.DestroyVehicleFlight = destroyVehicleFlight

local function updateVehicleFlight(chassis: any, dt: number?): boolean
    local vehicle = chassis and chassis.clientVehicle
    local data = vehicle and vehicle.replica and vehicle.replica.Data
    local model = chassis and chassis.model
    local root = typeof(model) == "Instance" and model:FindFirstChild("Chassis")
    if not Config.VehicleFly or not chassis or chassis.isDestroyed or not chassis.isDriver
        or (chassis.vehicleType ~= "Car" and chassis.vehicleType ~= "Motorcycle")
        or not data or data.driver ~= LocalPlayer or not root or not root:IsA("BasePart")
        or not root:IsDescendantOf(workspace) or root.Anchored then
        destroyVehicleFlight()
        return false
    end
    local flight = State.VehicleFlight
    if not flight or flight.Root ~= root then
        destroyVehicleFlight()
        flight = {Root = root, Chassis = chassis}
        local initialHeading = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        flight.Heading = if initialHeading.Magnitude > 0.1 then initialHeading.Unit else Vector3.new(0, 0, -1)
        State.VehicleFlight = flight
        local attachment = Instance.new("Attachment")
        flight.Attachment = attachment
        attachment.Name, attachment.Parent = "WantedFlightAttachment", root
        local velocity = Instance.new("LinearVelocity")
        flight.Velocity = velocity
        velocity.Name, velocity.Attachment0 = "WantedFlightVelocity", attachment
        velocity.RelativeTo, velocity.VelocityConstraintMode = Enum.ActuatorRelativeTo.World, Enum.VelocityConstraintMode.Vector
        velocity.MaxForce = math.max(1000000, root.AssemblyMass * workspace.Gravity * 30)
        velocity.VectorVelocity, velocity.Parent = Vector3.zero, root
        local orientation = Instance.new("AlignOrientation")
        flight.Orientation = orientation
        orientation.Name, orientation.Attachment0 = "WantedFlightOrientation", attachment
        orientation.Mode, orientation.Responsiveness = Enum.OrientationAlignmentMode.OneAttachment, 35
        orientation.RigidityEnabled = true
        orientation.MaxTorque, orientation.MaxAngularVelocity = math.max(1000000, root.AssemblyMass * workspace.Gravity * 30), 25
        orientation.CFrame, orientation.Parent = root.CFrame.Rotation, root
        resetVehicleRamp(State.Vehicle, "Flying")
    end
    local camera = workspace.CurrentCamera
    local heading = if camera then camera.CFrame.LookVector else root.CFrame.LookVector
    heading = Vector3.new(heading.X, 0, heading.Z)
    if heading.Magnitude < 0.1 then heading = Vector3.new(0, 0, -1) end
    heading = heading.Unit
    local right = Vector3.new(-heading.Z, 0, heading.X)
    local move = Vector3.zero
    if State.VehicleHasFocus and usingTouch() and not UserInputService:GetFocusedTextBox() then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local direction = humanoid and humanoid.MoveDirection or Vector3.zero
        if touchControls then
            local ok, raw = pcall(touchControls.GetMoveVector, touchControls)
            if ok and typeof(raw) == "Vector3" then direction = right * raw.X - heading * raw.Z end
        end
        local touch = State.MobileFlight or {}
        move += direction + heading * ((touch.Forward or 0) - (touch.Back or 0))
            + right * ((touch.Right or 0) - (touch.Left or 0))
            + Vector3.yAxis * ((touch.Up or 0) - (touch.Down or 0))
    end
    if State.VehicleHasFocus and not UserInputService:GetFocusedTextBox() then
        local turn = (if UserInputService:IsKeyDown(Enum.KeyCode.E) then 1 else 0)
            - (if UserInputService:IsKeyDown(Enum.KeyCode.Q) then 1 else 0)
        if turn ~= 0 then
            local rotation = CFrame.fromAxisAngle(Vector3.yAxis, -turn * math.rad(75) * math.clamp(dt or 1 / 60, 0, 0.1))
            flight.Heading = rotation:VectorToWorldSpace(flight.Heading).Unit
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += heading end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= heading end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then move -= Vector3.yAxis end
    end
    local speed = kmhToStuds(Config.VehicleFlyKmh)
    local targetVelocity = if move.Magnitude > 0 then move.Unit * speed else Vector3.zero
    flight.Velocity.VectorVelocity = targetVelocity
    -- A world-space heading avoids feeding the vehicle-follow camera back into its own yaw.
    flight.Orientation.CFrame = CFrame.lookAt(Vector3.zero, flight.Heading, Vector3.yAxis)
    root.AssemblyAngularVelocity = Vector3.zero
    root.AssemblyLinearVelocity = targetVelocity
    chassis.speed, chassis.velocity = targetVelocity.Magnitude, targetVelocity
    chassis.forwardSpeed = targetVelocity:Dot(root.CFrame.LookVector)
    State.Vehicle.Status, State.Vehicle.CurrentKmh = "Flying", studsToKmh(targetVelocity.Magnitude)
    return true
end
State.UpdateVehicleFlight = updateVehicleFlight

local function setVehicleBoost(enabled: boolean, sync: boolean?)
    Config.VehicleAcceleration = enabled
    releaseVehicleAssist()
    if sync and State.Controls.VehicleAcceleration then State.Controls.VehicleAcceleration:Set({CurrentValue = enabled}) end
end
State.SetVehicleBoost = setVehicleBoost

local function setVehicleFlight(enabled: boolean, sync: boolean?)
    Config.VehicleFly = enabled
    if not enabled then destroyVehicleFlight() end
    if sync and State.Controls.VehicleFly then State.Controls.VehicleFly:Set({CurrentValue = enabled}) end
end
State.SetVehicleFlight = setVehicleFlight


local function updateVehicleAcceleration(dt: number)
    if not State.Alive or not (Config.VehicleAcceleration or Config.VehicleInstantBrakes or Config.VehicleFly) then
        releaseVehicleAssist()
        return
    end
    local now = os.clock()
    if now - (State.LastVehicleLookup or -math.huge) >= 0.1 then
        State.LastVehicleLookup = now
        local identity = getthreadidentity()
        local ok, chassis = pcall(function()
            local vehicle = ClientVehicles.Get()
            if not vehicle or not vehicle:IsDriver() then return nil end
            return vehicle:GetChassis()
        end)
        setthreadidentity(identity)
        State.VehicleChassis = if ok then chassis else nil
        if not ok then State.LastVehicleError = tostring(chassis) end
    end
    if Config.VehicleFly then
        if updateVehicleFlight(State.VehicleChassis, dt) then return end
    elseif State.VehicleFlight then
        destroyVehicleFlight()
    end
    if UserInputService:GetFocusedTextBox() then
        resetVehicleRamp(State.Vehicle, "Paused while typing")
        return
    end
    stepVehicleAcceleration(State.VehicleChassis, dt, State.Vehicle)
end
State.UpdateVehicleAcceleration = updateVehicleAcceleration

-- Own collision snapshots per model, so switching seats or respawning releases every old part.
local function releaseCollisionLease(lease: any)
    if not lease or not lease.Alive then return end
    lease.Alive = false
    for _, connection in ipairs(lease.Connections) do connection:Disconnect() end
    table.clear(lease.Connections)
    for part, originalCollision in pairs(lease.Parts) do
        pcall(function()
            if not part.CanCollide then part.CanCollide = originalCollision end
        end)
    end
    table.clear(lease.Parts)
    lease.Count = 0
end

local function createCollisionLease(model: Model): any
    local lease: any = {Model = model, Parts = {}, Connections = {}, Count = 0, Alive = true}
    local function add(instance: Instance)
        if not lease.Alive or not instance:IsA("BasePart") or lease.Parts[instance] ~= nil then return end
        if lease.Count >= 4096 then lease.Overflow = true; return end
        lease.Parts[instance] = instance.CanCollide
        lease.Count += 1
        instance.CanCollide = false
    end
    table.insert(lease.Connections, model.DescendantAdded:Connect(add))
    table.insert(lease.Connections, model.DescendantRemoving:Connect(function(instance)
        local originalCollision = lease.Parts[instance]
        if originalCollision == nil then return end
        lease.Parts[instance] = nil
        lease.Count -= 1
        pcall(function()
            local part = instance :: BasePart
            if not part.CanCollide then part.CanCollide = originalCollision end
        end)
    end))
    local descendants = model:GetDescendants()
    if #descendants > 8192 then lease.Overflow = true else
        for _, instance in ipairs(descendants) do add(instance) end
    end
    if lease.Overflow then releaseCollisionLease(lease) end
    return lease
end

local function stepCollisionLease(lease: any): boolean
    if not lease or not lease.Alive then return false end
    if lease.Overflow or not lease.Model:IsDescendantOf(workspace) then
        releaseCollisionLease(lease)
        return false
    end
    for part, originalCollision in pairs(lease.Parts) do
        if not part:IsDescendantOf(lease.Model) then
            lease.Parts[part] = nil
            lease.Count -= 1
            pcall(function() if not part.CanCollide then part.CanCollide = originalCollision end end)
        elseif part.CanCollide then
            part.CanCollide = false
        end
    end
    return true
end
State.CreateCollisionLease, State.StepCollisionLease, State.ReleaseCollisionLease = createCollisionLease, stepCollisionLease, releaseCollisionLease

local function noclipVehicleModel(vehicle: any, seat: BasePart?): Model?
    local replica = vehicle and vehicle.replica
    local data = replica and replica.Data
    local tags = replica and replica.Tags
    local kind = vehicle and (vehicle.vehicleType or (tags and tags.vehicleType))
    local model = vehicle and vehicle.model
    -- GetChassis is shared by all vehicles; use the seated vehicle's own model and driver replica.
    if not data or data.driver ~= LocalPlayer or vehicle.isDestroyed
        or (kind ~= "Car" and kind ~= "Motorcycle" and kind ~= "Helicopter")
        or typeof(model) ~= "Instance" or not model:IsA("Model") or not model:IsDescendantOf(workspace)
        or not seat or not seat:IsDescendantOf(model) then return nil end
    return model
end
State.NoclipVehicleModel = noclipVehicleModel

releaseNoclip = function()
    local noclip = State.Noclip
    releaseCollisionLease(noclip.Vehicle)
    releaseCollisionLease(noclip.Character)
    noclip.Vehicle, noclip.Character, noclip.VehicleObject, noclip.LastSeat = nil, nil, nil, nil
    noclip.LastLookup = -math.huge
    noclip.CharacterParts, noclip.VehicleParts, noclip.VehicleActive = 0, 0, false
end
State.ReleaseNoclip = releaseNoclip

local function updateNoclip()
    if not State.Alive or not (Config.Noclip or Config.VehicleNoclip) then releaseNoclip(); return end
    local noclip = State.Noclip
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not character:IsDescendantOf(workspace) or not humanoid or humanoid.Health <= 0 then
        releaseNoclip()
        return
    end
    local seat = humanoid.SeatPart
    if Config.VehicleNoclip and seat then
        local now = os.clock()
        if noclip.LastSeat ~= seat or now - noclip.LastLookup >= 0.1 then
            noclip.LastSeat, noclip.LastLookup = seat, now
            local identity = getthreadidentity()
            local ok, vehicle = pcall(ClientVehicles.Get)
            setthreadidentity(identity)
            noclip.VehicleObject = if ok then vehicle else nil
        end
    else
        noclip.VehicleObject, noclip.LastSeat, noclip.LastLookup = nil, nil, -math.huge
    end
    local vehicleModel = if Config.VehicleNoclip then noclipVehicleModel(noclip.VehicleObject, seat) else nil
    local characterModel = if Config.Noclip or vehicleModel then character else nil
    for _, field in ipairs({"Vehicle", "Character"}) do
        local model = if field == "Vehicle" then vehicleModel else characterModel
        local lease = noclip[field]
        if lease and (lease.Model ~= model or not lease.Alive) then
            releaseCollisionLease(lease)
            noclip[field], lease = nil, nil
        end
        if model and not lease then lease = createCollisionLease(model); noclip[field] = lease end
        if lease then stepCollisionLease(lease) end
    end
    noclip.VehicleActive = noclip.Vehicle ~= nil and noclip.Vehicle.Alive
    noclip.CharacterParts = if noclip.Character then noclip.Character.Count else 0
    noclip.VehicleParts = if noclip.Vehicle then noclip.Vehicle.Count else 0
end
State.UpdateNoclip = updateNoclip

local function setNoclip(enabled: boolean, sync: boolean?)
    Config.Noclip = enabled
    updateNoclip()
    if sync and State.Controls.Noclip then State.Controls.Noclip:Set({CurrentValue = enabled}) end
    updateKeybindList()
end
local function setVehicleNoclip(enabled: boolean, sync: boolean?)
    Config.VehicleNoclip = enabled
    updateNoclip()
    if sync and State.Controls.VehicleNoclip then State.Controls.VehicleNoclip:Set({CurrentValue = enabled}) end
    updateKeybindList()
end
State.SetNoclip, State.SetVehicleNoclip = setNoclip, setVehicleNoclip


local function getEquippedWeapon(player: Player, forceRefresh: boolean?): string
    local now, cache = os.clock(), State.WeaponCache[player]
    if not forceRefresh and cache and cache.Character == player.Character and now - cache.Updated < 0.12 then return cache.Name end
    local identity = getthreadidentity()
    local ok, name = pcall(function()
        local playerObject = ClientPlayers.GetByPlayerId(player.UserId)
        if not playerObject then return "Unknown" end
        local equipped = playerObject:GetEquippedReplica()
        if not equipped then return "Unarmed" end
        local toolState = equipped.toolState
        local value = type(toolState) == "table" and toolState.name or equipped.name
        if type(value) ~= "string" or value == "" then return "Unknown" end
        return (value:gsub("%c", "")):sub(1, 80)
    end)
    setthreadidentity(identity)
    local result = if ok then name else "Unknown"
    State.WeaponCache[player] = {Character = player.Character, Updated = now, Name = result}
    return result
end
State.GetEquippedWeapon = getEquippedWeapon


-- Built by Olivia — https://discord.gg/ojailbreaks
-- Luau | replacement player ESP block | Wanted / Real
local function makeESPEntry(player: Player): any
    local entry: any = {Drawings = {}, CornerLines = {}, CornerOutlines = {}}
    State.ESPEntries[player] = entry
    local function add(field: string, className: string): any
        local drawing = newDrawing(className)
        table.insert(entry.Drawings, drawing)
        entry[field] = drawing
        drawing.Visible = false
        drawing.Transparency = 1
        return drawing
    end
    add("TracerOutline", "Line")
    add("Tracer", "Line")
    add("Fill", "Square").Filled = true
    add("Outline", "Square").Filled = false
    add("Box", "Square").Filled = false
    add("HealthBack", "Line")
    add("Health", "Line")
    for _, field in ipairs({"Name", "Info", "Weapon"}) do
        local text = add(field, "Text")
        text.Center = true
        text.Font = Enum.Font.Gotham
    end
    entry.Outline.Color = Color3.new(0, 0, 0)
    entry.HealthBack.Color = Color3.new(0, 0, 0)
    entry.TracerOutline.Color = Color3.new(0, 0, 0)
    return entry
end

local function ensureCornerLines(entry: any)
    if #entry.CornerLines > 0 then return end
    -- Backgrounds precede foregrounds to preserve the one-pixel outline.
    for pass = 1, 2 do
        local lines = if pass == 1 then entry.CornerOutlines else entry.CornerLines
        for _ = 1, 8 do
            local line = newDrawing("Line")
            table.insert(entry.Drawings, line)
            table.insert(lines, line)
            line.Visible = false
            line.Transparency = 1
            if pass == 1 then line.Color = Color3.new(0, 0, 0) end
        end
    end
end

local function hideEntry(entry: any)
    for _, drawing in ipairs(entry.Drawings) do drawing.Visible = false end
end

local function removeESPPlayer(player: Player)
    State.WeaponCache[player] = nil
    local entry = State.ESPEntries[player]
    if not entry then return end
    State.ESPEntries[player] = nil
    for _, drawing in ipairs(entry.Drawings) do removeDrawing(drawing) end
    table.clear(entry.Drawings)
end

local function drawCornerBox(entry: any, position: Vector2, size: Vector2, color: Color3,
    thickness: number, opacity: number)
    ensureCornerLines(entry)
    local x, y, width, height = position.X, position.Y, size.X, size.Y
    local horizontal = math.min(width * 0.25, 24)
    local vertical = math.min(height * 0.22, 32)
    local endpoints = {
        {Vector2.new(x, y), Vector2.new(x + horizontal, y)},
        {Vector2.new(x, y), Vector2.new(x, y + vertical)},
        {Vector2.new(x + width, y), Vector2.new(x + width - horizontal, y)},
        {Vector2.new(x + width, y), Vector2.new(x + width, y + vertical)},
        {Vector2.new(x, y + height), Vector2.new(x + horizontal, y + height)},
        {Vector2.new(x, y + height), Vector2.new(x, y + height - vertical)},
        {Vector2.new(x + width, y + height), Vector2.new(x + width - horizontal, y + height)},
        {Vector2.new(x + width, y + height), Vector2.new(x + width, y + height - vertical)},
    }
    for index, points in ipairs(endpoints) do
        local outline, line = entry.CornerOutlines[index], entry.CornerLines[index]
        outline.From, outline.To = points[1], points[2]
        outline.Thickness, outline.Transparency, outline.Visible = thickness + 2, opacity, true
        line.From, line.To = points[1], points[2]
        line.Color, line.Thickness, line.Transparency, line.Visible = color, thickness, opacity, true
    end
end

local function updateESP()
    local camera = workspace.CurrentCamera
    local tracked, visible = 0, 0
    for _, entry in pairs(State.ESPEntries) do
        hideEntry(entry)
        tracked += 1
    end
    if not State.Alive or not Config.ESPEnabled or not Config.ESPPlayers or not camera then
        State.ESPStats = {Tracked = tracked, Visible = 0}
        return
    end
    local cameraPosition, viewport = camera.CFrame.Position, camera.ViewportSize
    local opacity = math.clamp(Config.ESPOpacity, 0, 1)
    local textSize = math.clamp(Config.ESPTextSize, 8, 32)
    local thickness = math.clamp(Config.ESPBoxThickness, 1, 5)
    local maxDistanceSquared = Config.ESPMaxDistance * Config.ESPMaxDistance
    local tracerOrigin = Vector2.new(viewport.X / 2, viewport.Y - 2)
    if Config.ESPTracerOrigin == "Center" then
        tracerOrigin = viewport / 2
    elseif Config.ESPTracerOrigin == "Top" then
        tracerOrigin = Vector2.new(viewport.X / 2, 2)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local friendly = isProtected(player)
        if Config.ESPFilters and friendly then continue end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not character or not humanoid or humanoid.Health <= 0
            or not root or not root:IsA("BasePart") then continue end
        local delta = root.Position - cameraPosition
        local distanceSquared = delta:Dot(delta)
        if distanceSquared > maxDistanceSquared then continue end
        local position, size = screenBounds(character, camera)
        if not position or not size then continue end
        local unobstructed = true
        if Config.ESPVisibilityCheck or Config.ESPVisibleOnly then
            local head = character:FindFirstChild("Head")
            local checkPart = if head and head:IsA("BasePart") then head else root
            unobstructed = hasLineOfSight(cameraPosition, checkPart, character)
            if Config.ESPVisibleOnly and not unobstructed then continue end
        end
        local entry = State.ESPEntries[player]
        if not entry then
            entry = makeESPEntry(player)
            tracked += 1
        end
        visible += 1
        local team = player:GetAttribute("currentTeam")
        local color = Config.ESPColor
        if Config.ESPUseTeamColors then
            if friendly then color = Config.ESPFriendlyColor
            elseif team == "police" then color = Config.ESPPoliceColor
            elseif team == "syndicate" then color = Config.ESPSyndicateColor end
        end
        if Config.ESPVisibilityCheck and not unobstructed then color = Config.ESPOccludedColor end
        entry.Fill.Position, entry.Fill.Size, entry.Fill.Color = position, size, color
        entry.Fill.Transparency = math.clamp(Config.ESPFillOpacity, 0, 1) * opacity
        entry.Fill.Visible = Config.ESPBoxes and Config.ESPBoxFill
        if Config.ESPBoxes then
            if Config.ESPBoxStyle == "Corners" then
                drawCornerBox(entry, position, size, color, thickness, opacity)
            else
                entry.Outline.Position, entry.Outline.Size = position, size
                entry.Outline.Thickness, entry.Outline.Transparency = thickness + 2, opacity
                entry.Outline.Visible = true
                entry.Box.Position, entry.Box.Size, entry.Box.Color = position, size, color
                entry.Box.Thickness, entry.Box.Transparency, entry.Box.Visible = thickness, opacity, true
            end
        end
        local centerX, bottomY = position.X + size.X / 2, position.Y + size.Y
        for _, text in ipairs({entry.Name, entry.Info, entry.Weapon}) do
            text.Size, text.Outline, text.Transparency, text.Color = textSize, Config.ESPTextOutline, opacity, color
        end
        entry.Name.Text = if Config.ESPUseDisplayNames then player.DisplayName else player.Name
        entry.Name.Position = Vector2.new(centerX, position.Y - textSize - 3)
        entry.Name.Visible = Config.ESPNames
        local info = {}
        if Config.ESPTeamNames then
            table.insert(info, "Team: " .. (if team ~= nil then tostring(team) else "unknown"))
        end
        if Config.ESPDistance then table.insert(info, string.format("%.0f studs", math.sqrt(distanceSquared))) end
        if Config.ESPHealthText then
            table.insert(info, string.format("%.0f / %.0f HP", humanoid.Health, humanoid.MaxHealth))
        end
        entry.Info.Text = table.concat(info, " | ")
        entry.Info.Position = Vector2.new(centerX, bottomY + 2)
        entry.Info.Visible = #info > 0
        entry.Weapon.Visible = Config.ESPWeapons
        if Config.ESPWeapons then
            entry.Weapon.Text = "Held: " .. getEquippedWeapon(player)
            entry.Weapon.Position = Vector2.new(centerX, bottomY + 2 + (if #info > 0 then textSize + 2 else 0))
        end
        if Config.ESPHealth then
            local fraction = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
            local bottom = Vector2.new(position.X - thickness - 4, bottomY)
            entry.HealthBack.From, entry.HealthBack.To = bottom, Vector2.new(bottom.X, position.Y)
            entry.HealthBack.Thickness, entry.HealthBack.Transparency, entry.HealthBack.Visible = thickness + 3, opacity, true
            entry.Health.From, entry.Health.To = bottom, Vector2.new(bottom.X, position.Y + size.Y * (1 - fraction))
            entry.Health.Color = Color3.fromRGB(255, 75, 75):Lerp(Color3.fromRGB(80, 235, 115), fraction)
            entry.Health.Thickness, entry.Health.Transparency, entry.Health.Visible = thickness + 1, opacity, fraction > 0
        end
        if Config.ESPTracers then
            local endpoint = Vector2.new(centerX, bottomY)
            entry.TracerOutline.From, entry.TracerOutline.To = tracerOrigin, endpoint
            entry.TracerOutline.Thickness, entry.TracerOutline.Transparency, entry.TracerOutline.Visible = thickness + 2, opacity, true
            entry.Tracer.From, entry.Tracer.To, entry.Tracer.Color = tracerOrigin, endpoint, color
            entry.Tracer.Thickness, entry.Tracer.Transparency, entry.Tracer.Visible = thickness, opacity, true
        end
    end
    State.ESPStats = {Tracked = tracked, Visible = visible}
end
State.UpdateESP = updateESP

-- Floor pickups are local gizmo models, rather than inventory replicas or map props.
local pickupCategories = {
    Lootable = "Loot", WorldItem = "Weapons", Cash = "Cash", CashPallet = "Cash",
    WorldBag = "Bags", WorldLootbox = "Other", WorldWrap = "Other",
}
local itemDataCache: any = {}
local function gameRead(callback: any, ...: any): (boolean, any)
    local identity = getthreadidentity()
    local ok, result = pcall(callback, ...)
    setthreadidentity(identity)
    return ok, result
end

local function nonnegativeNumber(value: any): number?
    if type(value) == "number" and value == value and value >= 0 and value < math.huge then
        return value
    end
    return nil
end

local function itemAvailable(gizmo: any, model: Instance): boolean
    if model.Parent == nil or model:GetAttribute("isDestroyed") == true or gizmo.isCollected then return false end
    local state = if type(gizmo.gizmoState) == "table" then gizmo.gizmoState else {}
    if state.disabled or state.isDestroyed then return false end
    if type(state.collectedPlayers) == "table" then
        for _, userId in pairs(state.collectedPlayers) do
            if tostring(userId) == tostring(LocalPlayer.UserId) then return false end
        end
    end
    return true
end

local function describeItem(model: Model, gizmo: any): any
    local kind = gizmo.gizmoType or model:GetAttribute("gizmoType") or gizmo.ClassName
    local category = pickupCategories[kind]
    if not category or not itemAvailable(gizmo, model) then return nil end
    local properties = if type(gizmo.properties) == "table" then gizmo.properties else {}
    local state = if type(gizmo.gizmoState) == "table" then gizmo.gizmoState else {}
    local name = tostring(gizmo.name or model.Name):sub(1, 120)
    if kind == "WorldItem" and type(properties.toolName) == "string" then name = properties.toolName:sub(1, 120) end
    local data = itemDataCache[name]
    if data == nil then
        local ok, result = gameRead(Objects.GetData, name, true)
        data = if ok and type(result) == "table" then result else false
        itemDataCache[name] = data
    end
    local value: number? = nil
    if category == "Cash" then
        -- Event currencies are not in-game dollars, even when their models resemble cash.
        if name == "Cash" or name == "CashPallet" or properties.currencyName == "cash" then
            value = nonnegativeNumber(state.amount)
        end
    elseif data then
        value = nonnegativeNumber(data.sellValue)
    end
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return nil end
    return {
        Model = model, Gizmo = gizmo, Part = part, Name = name,
        Category = category, Value = value,
        Rarity = if data and data.rarity ~= nil then tostring(data.rarity) else nil,
    }
end
State.DescribeItem = describeItem

local function destroyItemHighlight(entry: any)
    if not entry.Highlight then return end
    State.Highlights[entry.Highlight] = nil
    entry.Highlight:Destroy()
    entry.Highlight = nil
end

local function removeItemEntry(model: Model)
    local entry = State.ItemEntries[model]
    if not entry then return end
    removeDrawing(entry.Label)
    destroyItemHighlight(entry)
    State.ItemEntries[model] = nil
end

local function refreshItems()
    if not State.Alive then return end
    local localFolder = workspace:FindFirstChild("Local")
    local folder = localFolder and localFolder:FindFirstChild("Gizmos")
    local seen: any = {}
    if folder and Config.ESPEnabled and Config.ESPItems then
        for index, model in ipairs(folder:GetChildren()) do
            if index > 2048 then break end
            if not model:IsA("Model") then continue end
            local objectId = model:GetAttribute("objectId")
            if objectId == nil then continue end
            local ok, gizmo = gameRead(ClientGizmos.Get, objectId)
            if not ok or type(gizmo) ~= "table" or gizmo.model ~= model then continue end
            local description = describeItem(model, gizmo)
            if not description then continue end
            seen[model] = true
            local entry = State.ItemEntries[model]
            if not entry then
                entry = description
                State.ItemEntries[model] = entry
            else
                for key, value in pairs(description) do entry[key] = value end
                entry.Value, entry.Rarity = description.Value, description.Rarity
            end
        end
    end
    for model in pairs(State.ItemEntries) do
        if not seen[model] then removeItemEntry(model) end
    end
end
State.RefreshItems = refreshItems

local function dollarLabel(value: number): string
    local digits = string.format("%.0f", value)
    local separated = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return "$" .. separated
end

local function isValuable(value: any): boolean
    local number = nonnegativeNumber(value)
    return number ~= nil and number >= Config.ESPHighValueThreshold
end
State.IsValuableItem = isValuable

local function updateItemESP()
    local camera = workspace.CurrentCamera
    local tracked = 0
    for _, entry in pairs(State.ItemEntries) do
        tracked += 1
        if entry.Label then entry.Label.Visible = false end
        entry.KeepHighlight = false
    end
    State.ItemStats = {Tracked = tracked, Visible = 0, Valuable = 0, Highlighted = 0}
    if not State.Alive or not Config.ESPEnabled or not Config.ESPItems or not camera then
        for _, entry in pairs(State.ItemEntries) do destroyItemHighlight(entry) end
        return
    end
    local candidates: any = {}
    local localFolder = workspace:FindFirstChild("Local")
    local folder = localFolder and localFolder:FindFirstChild("Gizmos")
    for model, entry in pairs(State.ItemEntries) do
        if model.Parent ~= folder or not itemAvailable(entry.Gizmo, model)
            or not entry.Part:IsDescendantOf(model) then continue end
        local value = entry.Value
        local valuable = isValuable(value)
        if value == nil then
            if not Config.ESPItemShowUnknown or Config.ESPItemMinValue > 0 then continue end
        elseif value < Config.ESPItemMinValue then continue end
        if Config.ESPItemFilter == "High value only" then
            if not valuable then continue end
        elseif Config.ESPItemFilter ~= "All" and Config.ESPItemFilter ~= entry.Category then continue end
        local position = entry.Part.Position
        local delta = position - camera.CFrame.Position
        local distance = delta.Magnitude
        if distance > Config.ESPItemMaxDistance then continue end
        if not Config.ESPItemThroughWalls and not hasLineOfSight(camera.CFrame.Position, entry.Part, model) then continue end
        local screen, onScreen = camera:WorldToViewportPoint(position)
        if not onScreen then continue end
        table.insert(candidates, {Entry = entry, Distance = distance, Valuable = valuable, Screen = screen})
    end
    table.sort(candidates, function(a, b)
        if a.Valuable ~= b.Valuable then return a.Valuable end
        return a.Distance < b.Distance
    end)
    local visible, valuableCount, highlighted = 0, 0, 0
    local occupiedRows: any = {}
    local function reserveLabel(position: Vector2, bounds: Vector2): boolean
        if not Config.ESPItemAvoidOverlap then return true end
        local rectangle = {
            Left = position.X - bounds.X / 2 - 4, Right = position.X + bounds.X / 2 + 4,
            Top = position.Y - 2, Bottom = position.Y + bounds.Y + 2,
        }
        local first, last = math.floor(rectangle.Top / 24), math.floor(rectangle.Bottom / 24)
        for row = first, last do
            for _, other in ipairs(occupiedRows[row] or {}) do
                if rectangle.Left < other.Right and rectangle.Right > other.Left
                    and rectangle.Top < other.Bottom and rectangle.Bottom > other.Top then return false end
            end
        end
        for row = first, last do
            if not occupiedRows[row] then occupiedRows[row] = {} end
            table.insert(occupiedRows[row], rectangle)
        end
        return true
    end
    for _, candidate in ipairs(candidates) do
        local entry = candidate.Entry
        local color = if candidate.Valuable then Config.ESPHighValueColor else Config.ESPItemColor
        local parts = {}
        if Config.ESPItemNames then table.insert(parts, entry.Name) end
        if Config.ESPItemValues then table.insert(parts, if entry.Value ~= nil then dollarLabel(entry.Value) else "value unknown") end
        if Config.ESPItemDistance then table.insert(parts, string.format("%.0f studs", candidate.Distance)) end
        if Config.ESPItemRarity and entry.Rarity then table.insert(parts, entry.Rarity) end
        if #parts > 0 and visible < Config.ESPItemLabelLimit then
            if not entry.Label then
                entry.Label = newDrawing("Text")
                entry.Label.Center, entry.Label.Font = true, Enum.Font.Gotham
            end
            local label = entry.Label
            label.Text, label.Size = table.concat(parts, " | "), Config.ESPItemTextSize
            label.Position = Vector2.new(candidate.Screen.X, candidate.Screen.Y)
            label.Color, label.Outline = color, Config.ESPTextOutline
            label.Transparency = Config.ESPOpacity
            label.Visible = reserveLabel(label.Position, label.TextBounds)
            if label.Visible then visible += 1 end
        end
        if candidate.Valuable then
            valuableCount += 1
            if Config.ESPItemHighlight and highlighted < Config.ESPItemHighlightLimit then
                if not State.HighlightFolder then
                    local folderInstance = Instance.new("Folder")
                    State.HighlightFolder = folderInstance
                    folderInstance.Name = "WantedLunaItemHighlights"
                    folderInstance.Parent = workspace
                end
                if not entry.Highlight then
                    local highlight = Instance.new("Highlight")
                    State.Highlights[highlight] = true
                    entry.Highlight = highlight
                    highlight.Adornee = entry.Model
                    highlight.Parent = State.HighlightFolder
                end
                local highlight = entry.Highlight
                highlight.FillColor, highlight.OutlineColor = color, color
                highlight.FillTransparency = 1 - Config.ESPItemFillOpacity
                highlight.OutlineTransparency, highlight.Enabled = 0, true
                highlight.DepthMode = if Config.ESPItemThroughWalls then Enum.HighlightDepthMode.AlwaysOnTop else Enum.HighlightDepthMode.Occluded
                entry.KeepHighlight = true
                highlighted += 1
            end
        end
    end
    for _, entry in pairs(State.ItemEntries) do
        if not entry.KeepHighlight then destroyItemHighlight(entry) end
    end
    State.ItemStats = {Tracked = tracked, Visible = visible, Valuable = valuableCount, Highlighted = highlighted}
end
State.UpdateItems = updateItemESP
local updatePlayerESP = updateESP
updateESP = function()
    runFeature("PlayerESP", updatePlayerESP)
    runFeature("ItemESP", updateItemESP)
    flushNativeOverlay()
end
State.UpdateESP = updateESP


local function restoreVisualDefaults()
    local reset = {ShowCircle = true, Radius = 150, ESPEnabled = true, ESPPlayers = true, ESPItems = true, ESPWeapons = true}
    for field, value in pairs(reset) do
        Config[field] = value
        local control = State.Controls[field]
        if control then control:Set({CurrentValue = value}) end
    end
    setAimEnabled(true, true)
    if State.UpdateCircle then State.UpdateCircle() end
    updateESP()
    flushNativeOverlay()
end
State.RestoreFeatures = restoreVisualDefaults

local PROFILE_FOLDER = "WantedAimLuna/profiles"
local function profileName(value: any): string?
    if type(value) ~= "string" then return nil end
    local name = value:match("^%s*(.-)%s*$")
    if not name or #name < 1 or #name > 48 or not name:match("^[%w _%-]+$") then return nil end
    return name
end

local function validKeyName(name: any): boolean
    if type(name) ~= "string" or #name > 32 then return false end
    local ok, value = pcall(function() return Enum.KeyCode[name] end)
    return ok and value ~= nil and value ~= Enum.KeyCode.Unknown
end

local function assignFeatureKey(field: string, keyName: any): boolean
    local valid = validKeyName(keyName)
    for _, other in ipairs({"AimKey", "MenuKey", "VehicleBoostKey", "VehicleFlyKey", "NoclipKey", "VehicleNoclipKey"}) do
        if other ~= field and Config[other] == keyName then valid = false end
    end
    if not valid then
        local control = State.Controls[field]
        if control then
            local settings = table.clone(control.Settings)
            settings.CurrentBind = Config[field]
            control:Set(settings)
        end
        return false
    end
    Config[field] = keyName
    return true
end

local function readProfile(name: any): (any?, string?)
    local safeName = profileName(name)
    if not safeName then return nil, "Use a name of 1–48 letters, numbers, spaces, - or _." end
    local ok, result = pcall(function()
        local contents = readfile(PROFILE_FOLDER .. "/" .. safeName .. ".json")
        assert(type(contents) == "string" and #contents <= 65536, "Configuration is too large.")
        return HttpService:JSONDecode(contents)
    end)
    if not ok then return nil, tostring(result) end
    if type(result) ~= "table" or result.Version ~= 1 or type(result.Settings) ~= "table" then
        return nil, "Unsupported configuration format."
    end

    local function finiteNumber(value: any): boolean
        return type(value) == "number" and value == value and value > -math.huge and value < math.huge
    end
    local function decodeColor(value: any): Color3?
        if typeof(value) == "Color3" then value = {value.R, value.G, value.B} end
        if type(value) ~= "table" or #value ~= 3 then return nil end
        for i = 1, 3 do
            if not finiteNumber(value[i]) or value[i] < 0 or value[i] > 1 then return nil end
        end
        return Color3.new(value[1], value[2], value[3])
    end
    -- These limits match the sliders; the third number marks integer fields.
    local numericRanges: {[string]: {number}} = {
        Radius = {5, 3000, 0},
        VehicleAccelTime = {0, 2, 0},
        VehicleMaxKmh = {30, 600, 1},
        VehicleFlyKmh = {30, 600, 1},
        KeybindX = {0, 1, 0},
        KeybindY = {0, 1, 0},
        ESPMaxDistance = {100, 10000, 0},
        ESPItemMaxDistance = {50, 10000, 0},
        ESPTextSize = {8, 32, 1},
        ESPItemTextSize = {8, 32, 1},
        ESPBoxThickness = {1, 5, 0},
        ESPFillOpacity = {0, 1, 0},
        ESPItemFillOpacity = {0, 1, 0},
        ESPOpacity = {0, 1, 0},
        ESPRefreshRate = {5, 60, 1},
        ESPItemMinValue = {0, 200000, 1},
        ESPHighValueThreshold = {1000, 200000, 1},
        ESPItemLabelLimit = {10, 200, 1},
        ESPItemHighlightLimit = {1, 24, 1},
    }
    local stringOptions: {[string]: {[string]: boolean}} = {
        ESPBoxStyle = {Full = true, Corners = true},
        ESPTracerOrigin = {Bottom = true, Center = true, Top = true},
        ESPItemFilter = {
            All = true, Loot = true, Weapons = true, Cash = true, Bags = true,
            Other = true, ["High value only"] = true,
        },
    }
    local settings = table.clone(Config)
    for key, current in pairs(Config) do
        local value = result.Settings[key]
        -- Older configs inherit fields introduced after they were saved.
        if value == nil then value = current end
        local kind = typeof(current)
        if kind == "boolean" then
            if type(value) ~= "boolean" then return nil, "Invalid " .. key end
        elseif kind == "number" then
            local bounds = numericRanges[key]
            if not bounds or not finiteNumber(value) then return nil, "Invalid " .. key end
            value = math.clamp(value, bounds[1], bounds[2])
            if bounds[3] == 1 then value = math.floor(value + 0.5) end
        elseif kind == "Color3" then
            value = decodeColor(value)
            if value == nil then return nil, "Invalid " .. key end
        elseif kind == "string" then
            if key == "AimKey" or key == "MenuKey" or key == "VehicleBoostKey" or key == "VehicleFlyKey"
                or key == "NoclipKey" or key == "VehicleNoclipKey" then
                if not validKeyName(value) then return nil, "Invalid " .. key end
            else
                local choices = stringOptions[key]
                if type(value) ~= "string" or not choices or not choices[value] then
                    return nil, "Invalid " .. key
                end
            end
        else
            return nil, "Unsupported setting " .. key
        end
        settings[key] = value
    end
    if settings.MenuKey == settings.AimKey then return nil, "Menu and aim keys must differ." end
    local usedKeys: any = {[settings.AimKey] = true, [settings.MenuKey] = true}
    for _, field in ipairs({"VehicleBoostKey", "VehicleFlyKey", "NoclipKey", "VehicleNoclipKey"}) do
        if usedKeys[settings[field]] and result.Settings[field] == nil then
            for _, candidate in ipairs({"G", "F", "N", "B", "H", "J", "K", "L"}) do
                if not usedKeys[candidate] then settings[field] = candidate; break end
            end
        end
        if usedKeys[settings[field]] then return nil, "Choose a different key for each feature and the menu." end
        usedKeys[settings[field]] = true
    end
    local theme = result.Theme
    if theme ~= nil then
        if type(theme) ~= "table" or #theme ~= 3 then return nil, "Invalid theme." end
        local validated = {}
        for i = 1, 3 do
            local color = decodeColor(theme[i])
            if color == nil then return nil, "Invalid theme color." end
            validated[i] = {color.R, color.G, color.B}
        end
        theme = validated
    end
    return {Settings = settings, Theme = theme, RendererVersion = result.RendererVersion, BoostVersion = result.BoostVersion}, nil
end
State.ReadProfile = readProfile

local function buildProfiles(window: any)
    local tab = window:CreateTab({Name = "Configs", Icon = "save", ImageSource = "Material"})
    local currentName = "Default"
    local selection: any = nil
    local function notify(ok: boolean, message: string)
        Luna:Notification({
            Title = ok and "Configuration" or "Configuration error",
            Content = message,
            Icon = ok and "check_circle_outline" or "warning",
            ImageSource = "Material",
        })
    end
    local function listProfiles(): {string}
        local names = {}
        local ok, files = pcall(function()
            makefolder(PROFILE_FOLDER)
            return listfiles(PROFILE_FOLDER)
        end)
        if ok and type(files) == "table" then
            for _, file in ipairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if profileName(name) then table.insert(names, name) end
                if #names >= 200 then break end
            end
        end
        table.sort(names)
        return names
    end
    local function refresh()
        if selection then selection:Set({Options = listProfiles()}) end
    end
    local function saveProfile(name: any): (boolean, string)
        local safeName = profileName(name)
        if not safeName then return false, "Enter a valid configuration name." end
        local settings = {}
        for key, value in pairs(Config) do
            settings[key] = if typeof(value) == "Color3" then {value.R, value.G, value.B} else value
        end
        local theme = {}
        for _, point in ipairs(Luna.ThemeGradient.Keypoints) do
            local color = point.Value
            table.insert(theme, {color.R, color.G, color.B})
        end
        local ok, message = pcall(function()
            makefolder(PROFILE_FOLDER)
            writefile(PROFILE_FOLDER .. "/" .. safeName .. ".json", HttpService:JSONEncode({
                Attribution = "Built by Olivia — https://discord.gg/ojailbreaks",
                Version = 1, RendererVersion = 2, BoostVersion = 1, Settings = settings, Theme = theme,
            }))
        end)
        return ok, if ok then "Saved " .. safeName else tostring(message)
    end
    local function loadProfile(name: any): (boolean, string)
        local saved, message = readProfile(name)
        if not saved then return false, message or "Cannot read configuration." end
        setAimEnabled(false, true)
        for key, value in pairs(saved.Settings) do
            if key ~= "Enabled" then Config[key] = value end
        end
        window.Bind = Enum.KeyCode[Config.MenuKey]
        -- Config keys match control IDs, with one historic rotation ID.
        for key, value in pairs(saved.Settings) do
            if key == "Enabled" then continue end
            local controlName = if key == "RotationEnabled" then "SilentRotation" else key
            local control = State.Controls[controlName]
            if not control then continue end
            if key == "AimKey" or key == "MenuKey" or key == "VehicleBoostKey" or key == "VehicleFlyKey"
                or key == "NoclipKey" or key == "VehicleNoclipKey" then
                -- Luna replaces omitted bind callbacks, so retain the entire settings table.
                local settings = table.clone(control.Settings)
                settings.CurrentBind = value
                control:Set(settings)
            elseif typeof(value) == "Color3" then
                control:Set({Color = value})
            elseif key == "ESPBoxStyle" or key == "ESPTracerOrigin" or key == "ESPItemFilter" then
                control:Set({CurrentOption = {value}})
            else
                control:Set({CurrentValue = value})
            end
        end
        if saved.Theme then
            for i, channels in ipairs(saved.Theme) do
                local picker = Luna.Options["LunaInterfaceSuitePrebuiltCPC" .. tostring(i)]
                if picker then picker:Set({Color = Color3.new(channels[1], channels[2], channels[3])}) end
            end
        end
        setAimEnabled(saved.Settings.Enabled, true)
        updateNoclip()
        -- Apply visibility immediately, including item labels and highlights.
        updateESP()
        return true, "Loaded " .. tostring(name)
    end
    State.SaveConfig, State.LoadConfig = saveProfile, loadProfile
    tab:CreateInput({
        Name = "Config name", CurrentValue = currentName, PlaceholderText = "Default",
        MaxCharacters = 48,
        Callback = function(value) currentName = value end,
    })
    selection = tab:CreateDropdown({
        Name = "Saved configs", Options = listProfiles(), CurrentOption = {}, MultipleOptions = false,
        Callback = function(value)
            if type(value) == "table" then value = value[1] end
            if type(value) == "string" then currentName = value end
        end,
    })
    tab:CreateButton({Name = "Save config", Callback = function()
        local ok, message = saveProfile(currentName)
        notify(ok, message)
        refresh()
    end})
    tab:CreateButton({Name = "Load config", Callback = function()
        local ok, message = loadProfile(currentName)
        notify(ok, message)
    end})
    tab:CreateButton({Name = "Refresh configs", Callback = refresh})
    tab:CreateButton({Name = "Use config on startup", Callback = function()
        local name = profileName(currentName)
        if not name or not isfile(PROFILE_FOLDER .. "/" .. name .. ".json") then
            notify(false, "Save or select an existing configuration first.")
            return
        end
        local ok, message = pcall(writefile, PROFILE_FOLDER .. "/autoload.txt", name)
        notify(ok, if ok then "Startup config: " .. name else tostring(message))
    end})
    tab:CreateButton({Name = "Clear startup config", Callback = function()
        local ok, message = pcall(function()
            if isfile(PROFILE_FOLDER .. "/autoload.txt") then delfile(PROFILE_FOLDER .. "/autoload.txt") end
        end)
        notify(ok, if ok then "Startup configuration cleared." else tostring(message))
    end})
    tab:CreateButton({Name = "Delete selected config", Callback = function()
        local name = profileName(currentName)
        if not name then
            notify(false, "Select a valid configuration.")
            return
        end
        local ok, message = pcall(function() delfile(PROFILE_FOLDER .. "/" .. name .. ".json") end)
        notify(ok, if ok then "Deleted " .. name else tostring(message))
        refresh()
    end})
    if isfile(PROFILE_FOLDER .. "/autoload.txt") then
        local ok, name = pcall(readfile, PROFILE_FOLDER .. "/autoload.txt")
        if ok then
            local loaded, message = loadProfile(name)
            if loaded then
                local parsed = readProfile(name)
                local safeName = profileName(name)
                if parsed and parsed.BoostVersion ~= 1 then
                    Config.VehicleAcceleration = false
                    State.Controls.VehicleAcceleration:Set({CurrentValue = false})
                    releaseVehicleAssist()
                end
                if parsed and parsed.RendererVersion ~= 2 and safeName then
                    local profilePath = PROFILE_FOLDER .. "/" .. safeName .. ".json"
                    local backupPath = PROFILE_FOLDER .. "/" .. safeName .. ".before-native.json"
                    if not isfile(backupPath) then writefile(backupPath, readfile(profilePath)) end
                    restoreVisualDefaults()
                    local saved, saveMessage = saveProfile(safeName)
                    if not saved then warn("[Wanted profile upgrade] " .. saveMessage) end
                end
                if parsed and parsed.BoostVersion ~= 1 and safeName then saveProfile(safeName) end
            end
            notify(loaded, message)
        end
    end
end


local function setupChineseMobile()
    local dictionary = game:GetService("HttpService"):JSONDecode([==[{"Built by Olivia — https://discord.gg/ojailbreaks": "作者 Olivia — https://discord.gg/ojailbreaks", "KEYBINDS": "快捷操作", "Silent aim": "静默瞄准", "Acceleration": "加速", "Vehicle flight": "车辆飞行", "Character noclip": "角色穿墙", "Vehicle noclip": "车辆穿墙", "Aimbot": "瞄准", "Target players": "以玩家为目标", "Target NPCs": "以 NPC 为目标", "Turn off for NPC-only silent aim. Police and crew checks still apply to players.": "关闭后仅瞄准 NPC；警察和队伍筛选仍适用于玩家。", "Living Wanted mobs and mutants. Shares your aim key, FOV and wall check.": "以存活怪物和变异体为目标，沿用瞄准快捷键、范围和墙体检测。", "Police check": "警察筛选", "When you are police, skip other police. Syndicates remain targets.": "自己是警察时跳过其他警察，仍以犯罪集团成员为目标。", "Crew check": "队伍筛选", "Skip players sharing your Wanted crew / party.": "跳过同队或同小队的玩家。", "Wall check": "墙体检测", "Require a clear view and a clear projectile path to the target.": "仅选择视线及弹道均无遮挡的目标。", "Rotate character with silent aim": "静默瞄准时转向目标", "Face the selected target with your character; keep the camera free.": "角色朝向所选目标，镜头仍可自由移动。", "Silent aim toggle key": "静默瞄准快捷键", "Click the key field, then press the keyboard key you want.": "点击按键栏后按下键盘按键；手机可使用屏幕快捷按钮。", "Live status": "实时状态", "Reading faction and crew...": "正在读取阵营和队伍…", "ESP": "透视", "Players": "玩家", "Enable ESP": "启用透视", "Show or hide all player and floor item overlays.": "显示或隐藏所有玩家及地面物品标记。", "Player ESP": "玩家透视", "Player boxes": "玩家方框", "Player names": "玩家名称", "Use display names": "显示昵称", "Turn off to show Roblox usernames.": "关闭后显示 Roblox 用户名。", "Health bars": "生命条", "Health numbers": "生命值数字", "Held weapon": "手持武器", "Show the weapon or item currently held by each player.": "显示玩家当前手持的武器或物品。", "Player distance": "玩家距离", "Faction labels": "阵营标签", "Player tracers": "玩家追踪线", "Player distance (studs)": "玩家显示距离（格）", "Player visibility": "玩家可见性", "Use police and crew filters": "使用警察和队伍筛选", "Follow your police and crew checks from Aimbot.": "沿用瞄准页面中的警察和队伍筛选。", "Color blocked players": "为被遮挡玩家单独着色", "Use the blocked color when a wall hides the player.": "玩家被墙挡住时使用遮挡颜色。", "Show visible players only": "仅显示可见玩家", "Hide player overlays behind walls.": "隐藏墙后玩家的标记。", "Player appearance": "玩家标记外观", "Box style": "方框样式", "Tracer origin": "追踪线起点", "Full": "完整方框", "Corners": "四角方框", "Bottom": "底部", "Center": "中心", "Top": "顶部", "Filled player boxes": "填充玩家方框", "Use faction colors": "按阵营着色", "Text outlines": "文字描边", "Player text size": "玩家文字大小", "Box and tracer thickness": "方框及追踪线粗细", "Box fill opacity": "方框填充不透明度", "Player overlay opacity": "玩家标记不透明度", "Default player color": "默认玩家颜色", "Police color": "警察颜色", "Syndicate color": "犯罪集团颜色", "Crew and friendly color": "队友和友方颜色", "Blocked player color": "被遮挡玩家颜色", "Floor items": "地面物品", "Floor item ESP": "地面物品透视", "Item names": "物品名称", "Item dollar values": "物品价值", "Item distance": "物品距离", "Item rarity": "物品稀有度", "Avoid overlapping item labels": "避免物品标签重叠", "Show items through walls": "穿墙显示物品", "Show items with unknown values": "显示价值未知的物品", "Keep unpriced items visible when your value filter allows them.": "价值筛选允许时保留价值未知的物品标记。", "Item category": "物品类别", "All": "全部", "Loot": "战利品", "Weapons": "武器", "Cash": "现金", "Bags": "背包", "Other": "其他", "High value only": "仅高价值物品", "Item distance (studs)": "物品显示距离（格）", "Minimum item value ($)": "物品最低价值（$）", "Item text size": "物品文字大小", "Standard item color": "普通物品颜色", "Valuable items": "高价值物品", "Highlight valuable items": "高亮高价值物品", "Highlight items at or above your dollar threshold. Default: $20,000.": "高亮达到设定价值的物品，默认阈值为 $20,000。", "Valuable item threshold ($)": "高价值阈值（$）", "Valuable item color": "高价值物品颜色", "Item highlight fill opacity": "物品高亮填充不透明度", "ESP performance": "透视性能", "Overlay refresh rate (Hz)": "标记刷新率（Hz）", "Maximum item labels": "物品标签数量上限", "Maximum item highlights": "物品高亮数量上限", "Field of view": "瞄准范围", "Show FOV circle": "显示瞄准范围圈", "FOV radius (pixels)": "范围圈半径（像素）", "FOV circle color": "范围圈颜色", "UI settings": "界面设置", "Open menu key": "打开菜单快捷键", "Menu": "菜单", "Use X to hide the menu and your menu key to reopen it. The circle and target selection share the exact screen center. Luna blur is disabled.": "点击 X 隐藏菜单，可用菜单快捷键或屏幕“菜单”按钮重新打开。范围圈及目标选择以屏幕中心为准；已禁用 Luna 模糊效果。", "Movement": "移动", "Pass through solid parts. Turning off restores your character's original collisions.": "穿过实体物件；关闭后恢复角色原始碰撞状态。", "Character noclip toggle key": "角色穿墙快捷键", "Vehicles": "车辆", "Car / motorcycle / helicopter noclip": "汽车／摩托车／直升机穿墙", "Driver only. Includes your rider. Pair with flight to pass through floors; switch off in clear space.": "仅驾驶员使用，包含骑乘角色。配合飞行可穿过地面，请在空旷处关闭。", "Vehicle noclip toggle key": "车辆穿墙快捷键", "Emergency acceleration toggle key": "紧急加速快捷键", "Custom top speed while boost is on": "加速时自定义最高速度", "Top speed (km/h)": "最高速度（千米/小时）", "Up to 600 km/h, approximately 373 mph.": "最高 600 千米/小时，约 373 英里/小时。", "Instant brakes": "瞬间刹车", "Stop horizontal motion immediately with the normal brake or handbrake.": "使用普通刹车或手刹立即停止水平运动。", "Emergency acceleration boost": "紧急加速", "Off by default. Your boost key toggles this; off restores normal acceleration and top speed.": "默认关闭。快捷键或触屏按钮可切换；关闭后恢复正常加速度和最高速度。", "Time to top speed (seconds)": "加速至极速所需时间（秒）", "Default: 2 seconds. Set to 0 for instant acceleration.": "默认 2 秒，设为 0 可立即加速。", "Car / motorcycle flight": "汽车／摩托车飞行", "WASD move. Space / Ctrl up / down. Q / E turn. Release movement keys to hover.": "电脑：WASD 移动，空格／Ctrl 升降，Q／E 转向。手机：使用摇杆或屏幕方向按钮。松开移动输入后悬停。", "Flight toggle key": "飞行快捷键", "Flight speed (km/h)": "飞行速度（千米/小时）", "Reset keybind list position": "重置快捷操作面板位置", "Drag the list by its header. Its position saves with your config.": "拖动标题栏移动面板，位置随配置保存。", "Restore aim and visuals": "恢复瞄准和透视默认值", "Enable aim, player/item ESP and the circle, with a visible 150-pixel FOV. Keep your keybind.": "启用瞄准、玩家和物品透视及 150 像素范围圈，保留快捷键设置。", "Unload and restore": "卸载并还原", "Remove the menu, ESP, circle, aim and rotation; restore AutoRotate.": "移除菜单、透视、范围圈、瞄准和转向逻辑，恢复自动转向。", "Config name": "配置名称", "Default": "默认", "Saved configs": "已保存配置", "Save config": "保存配置", "Load config": "加载配置", "Refresh configs": "刷新配置列表", "Use config on startup": "启动时使用此配置", "Clear startup config": "清除启动配置", "Delete selected config": "删除所选配置", "Save or select an existing configuration first.": "请先保存或选择已有配置。", "Startup configuration cleared.": "启动配置已清除。", "Select a valid configuration.": "请选择有效配置。", "Configuration": "配置管理", "Settings": "设置", "Theme": "主题", "Appearance": "外观", "Color Picker": "颜色选择器", "Search this page": "搜索当前页面", "Show Luna": "显示 Luna", "Luna Settings": "Luna 设置", "Luna Keybind": "Luna 快捷键", "Current Autoload: None": "当前自动加载配置：无", "Wanted | Aim & ESP": "Wanted｜瞄准与透视", "Configs": "配置方案", "Configuration error": "配置错误", "Interface Hidden": "界面已隐藏"}]==])
    local watched = setmetatable({}, {__mode = "k"})
    local function hookText(obj)
        if watched[obj] or not State.Alive then return end
        local property = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and "Text"
            or (obj:IsA("TextBox") and "PlaceholderText")
        if not property then return end
        watched[obj] = true
        local applying = false
        local function apply()
            if applying then return end
            local value = dictionary[obj[property]]
            if value and value ~= obj[property] then
                applying = true; obj[property] = value; applying = false
            end
        end
        apply()
        table.insert(State.Connections, obj:GetPropertyChangedSignal(property):Connect(apply))
    end
    local roots = {LocalPlayer:WaitForChild("PlayerGui")}
    pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and parent then roots[#roots + 1] = parent end
    end
    local seen = {}
    local function watchGui(gui)
        for _, obj in ipairs(gui:GetDescendants()) do hookText(obj) end
        table.insert(State.Connections, gui.DescendantAdded:Connect(function(obj) task.defer(hookText, obj) end))
    end
    -- 只处理本脚本和 Luna 创建的 GUI，不翻译游戏原生界面。
    local function isWantedGui(obj)
        return obj:IsA("ScreenGui") and (obj.Name:find("Luna", 1, true) ~= nil
            or obj.Name == "WantedActiveKeybinds" or obj.Name == "WantedMobileControls")
    end
    for _, root in ipairs(roots) do
        if not seen[root] then
            seen[root] = true
            for _, obj in ipairs(root:GetChildren()) do if isWantedGui(obj) then watchGui(obj) end end
            table.insert(State.Connections, root.ChildAdded:Connect(function(obj)
                if isWantedGui(obj) then watchGui(obj) end
            end))
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "WantedMobileControls", false, 1100
    parentGui(gui)
    table.insert(State.Connections, gui.Destroying:Connect(function() State.MobileFlight = {} end))
    local function button(text, x, y, parent)
        local btn = Instance.new("TextButton")
        btn.Size, btn.Position = UDim2.fromOffset(78, 42), UDim2.fromOffset(x, y)
        btn.BackgroundColor3, btn.TextColor3 = Color3.fromRGB(26, 33, 49), Color3.new(1,1,1)
        btn.Text, btn.TextSize, btn.Font = text, 13, Enum.Font.GothamBold
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end
    local holder = Instance.new("Frame", gui)
    holder.Size, holder.Position = UDim2.fromOffset(78, 42), UDim2.new(1, -90, 0, 12)
    holder.BackgroundTransparency = 1
    local menu = button("菜单", 0, 0, holder)
    menu.Activated:Connect(function()
        if State.Window and State.Window.SetMenuVisible then
            State.Window:SetMenuVisible(not State.Window.State)
        end
    end)
    local function findMain()
        for _, root in ipairs(roots) do
            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("ScreenGui") and obj.Name:find("Luna", 1, true) then
                    local main = obj:FindFirstChild("SmartWindow", true)
                    if main and main:IsA("GuiObject") then return main end
                end
            end
        end
    end
    local zoom = 1
    local function fitWindow()
        local main, camera = findMain(), workspace.CurrentCamera
        if not main or not camera then return end
        local scale = main:FindFirstChild("WantedMobileScale") or Instance.new("UIScale", main)
        scale.Name = "WantedMobileScale"
        local size = main.Size
        local width, height = math.max(size.X.Offset, 320), math.max(size.Y.Offset, 240)
        local view = camera.ViewportSize
        scale.Scale = math.max(0.1, math.min(zoom, (view.X - 24) / width, (view.Y - 70) / height))
        main.AnchorPoint, main.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5)
    end
    State.SetWindowZoom = function(delta)
        zoom = math.clamp(zoom + delta, 0.3, 1.2)
        fitWindow()
    end
    local cameraConnection
    local function bindCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        if workspace.CurrentCamera then
            cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitWindow)
            table.insert(State.Connections, cameraConnection)
        end
        fitWindow()
    end
    table.insert(State.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))
    bindCamera()
    task.delay(1, function() if State.Alive then fitWindow() end end)
    State.MobileFlight = {}
    if UserInputService.TouchEnabled then
        local pad = Instance.new("Frame", gui)
        pad.Size, pad.Position = UDim2.fromOffset(248, 88), UDim2.new(1, -260, 1, -240)
        pad.BackgroundTransparency = 1
        local controls = {{"前进","Forward"},{"上升","Up"},{"后退","Back"},{"左移","Left"},{"下降","Down"},{"右移","Right"}}
        for index, item in ipairs(controls) do
            local btn = button(item[1], ((index - 1) % 3) * 84, math.floor((index - 1) / 3) * 46, pad)
            btn.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                State.MobileFlight[item[2]] = 1
                local ended
                ended = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        State.MobileFlight[item[2]] = 0
                        ended:Disconnect()
                    end
                end)
                table.insert(State.Connections, ended)
            end)
        end
        table.insert(State.Connections, UserInputService.WindowFocusReleased:Connect(function() State.MobileFlight = {} end))
        pad.Visible = false
        State.MobileFlightPad = pad
    end
    State.UpdateMobileVisibility = function()
        local menuOpen = State.Window and State.Window.State == true
        holder.Visible = not menuOpen
        if State.MobileFlightPad then
            local visible = usingTouch() and Config.VehicleFly and not menuOpen
            State.MobileFlightPad.Visible = visible
            if not visible then State.MobileFlight = {} end
        end
    end
    State.UpdateMobileVisibility()
    State.MobileGui = gui
end

local function setup()
    removeLegacyLunaBlur()
    table.insert(State.Connections, Lighting.ChildAdded:Connect(function(effect)
        task.defer(function() if State.Alive then disableLunaEffect(effect) end end)
    end))
    local env = getgenv()
    env.ConfirmLuna = true
    local source = fetchSource(
        "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/master/source.lua"
    )
    -- Prevent Luna from creating global depth-of-field and glass blur.
    local patched, replacements = source:gsub(
        "local function BlurModule%(Frame%)",
        "local function BlurModule(Frame)\n\tif true then return end",
        1
    )
    assert(replacements == 1, "Luna 版本变化：模糊补丁未匹配。")
    local guardCount
    patched, guardCount = patched:gsub(
        "wait%(0%.2%)([\r\n]+)([ \t]*)if ButtonV%.Hover then",
        function(newline, indent)
            return "wait(0.2)" .. newline .. indent
                .. 'if not Button.Parent or not Button:FindFirstChild("UIStroke") then return end'
                .. newline .. indent .. "if ButtonV.Hover then"
        end
    )
    assert(guardCount == 2, "Luna 版本变化：按钮清理补丁未匹配。")
    local sizeCount
    patched, sizeCount = patched:gsub(
        "MainSize = UDim2%.fromOffset%(675, 424%)",
        "MainSize = UDim2.fromOffset(math.min(820, Camera.ViewportSize.X - 60), math.min(520, Camera.ViewportSize.Y - 60))"
    )
    assert(sizeCount == 1, "Luna 版本变化：窗口尺寸补丁未匹配。")
    local menuCount
    patched, menuCount = patched:gsub(
        "Main%.Controls%.Close%.ImageLabel%.MouseButton1Click:Connect%(function%(%)",
        function()
            return [[Window.SetMenuVisible = function(self, visible)
                if visible then Unhide(Main, Window.CurrentTab) else Hide(Main, Window.Bind, false) end
                dragBar.Visible = visible
                Window.State = visible
                LunaUI.MobileSupport.Visible = not visible
            end
            Main.Controls.Close.ImageLabel.MouseButton1Click:Connect(function()]]
        end, 1)
    assert(menuCount == 1, "Luna 版本变化：菜单接口补丁未匹配。")
    local loader, loadError = loadstring(patched, "=WantedLunaUI")
    assert(loader, loadError)
    pcall(function() librarySource = debug.info(loader, "s") end)
    Luna = loader()
    assert(type(Luna) == "table" and type(Luna.CreateWindow) == "function", "Luna failed to load.")

    circle = newDrawing("Circle")
    circle.Filled = false
    circle.Thickness = 1.5
    circle.Transparency = 0.9
    circle.Color = Config.CircleColor
    circle.Radius = Config.Radius
    circle.Visible = false
    State.Circle = circle
    createKeybindList()

    local window = Luna:CreateWindow({
        Name = "Wanted | Aim & ESP",
        Subtitle = "Built by Olivia — https://discord.gg/ojailbreaks",
        LoadingEnabled = false,
        KeySystem = false,
        ConfigSettings = {ConfigFolder = "WantedAimLuna"},
    })
    State.Window = window
    window.Bind = Enum.KeyCode.RightShift
    local targeting = window:CreateTab({
        Name = "Aimbot", Icon = "location_searching", ImageSource = "Material",
    })
    State.Controls.Enabled = targeting:CreateToggle({
        Name = "Silent aim",
        CurrentValue = Config.Enabled,
        Callback = function(value)
            setAimEnabled(value, false)
        end,
    }, "Enabled")
    State.Controls.TargetPlayers = targeting:CreateToggle({
        Name = "Target players", CurrentValue = Config.TargetPlayers,
        Description = "Turn off for NPC-only silent aim. Police and crew checks still apply to players.",
        Callback = function(value)
            Config.TargetPlayers = value
            State.Rotation.LastAcquire = -math.huge
        end,
    }, "TargetPlayers")
    State.Controls.TargetNPCs = targeting:CreateToggle({
        Name = "Target NPCs", CurrentValue = Config.TargetNPCs,
        Description = "Living Wanted mobs and mutants. Shares your aim key, FOV and wall check.",
        Callback = function(value)
            Config.TargetNPCs = value
            refreshNPCs()
            State.Rotation.LastAcquire = -math.huge
        end,
    }, "TargetNPCs")
    State.Controls.PoliceCheck = targeting:CreateToggle({
        Name = "Police check",
        Description = "When you are police, skip other police. Syndicates remain targets.",
        CurrentValue = Config.PoliceCheck,
        Callback = function(value) Config.PoliceCheck = value end,
    }, "PoliceCheck")
    State.Controls.CrewCheck = targeting:CreateToggle({
        Name = "Crew check",
        Description = "Skip players sharing your Wanted crew / party.",
        CurrentValue = Config.CrewCheck,
        Callback = function(value) Config.CrewCheck = value end,
    }, "CrewCheck")
    State.Controls.WallCheck = targeting:CreateToggle({
        Name = "Wall check",
        Description = "Require a clear view and a clear projectile path to the target.",
        CurrentValue = Config.WallCheck,
        Callback = function(value) Config.WallCheck = value end,
    }, "WallCheck")
    State.Controls.SilentRotation = targeting:CreateToggle({
        Name = "Rotate character with silent aim",
        Description = "Face the selected target with your character; keep the camera free.",
        CurrentValue = Config.RotationEnabled,
        Callback = function(value) setRotationEnabled(value, false) end,
    }, "SilentRotation")
    State.Controls.AimKey = targeting:CreateBind({
        Name = "Silent aim toggle key",
        Description = "Click the key field, then press the keyboard key you want.",
        CurrentBind = Config.AimKey,
        HoldToInteract = false,
        OnChangedCallback = function(keyName)
            if assignFeatureKey("AimKey", keyName) then updateKeybindList() end
        end,
        Callback = function()
            if State.Alive and not UserInputService:GetFocusedTextBox() then
                -- Read our toggle state; Luna's keybind keeps an independent Active flag.
                setAimEnabled(not Config.Enabled, true)
            end
        end,
    }, "AimKey")
    local status = targeting:CreateParagraph({
        Title = "Live status",
        Text = "Reading faction and crew...",
    })
    -- Built by Olivia — https://discord.gg/ojailbreaks
    -- Luau | replacement ESP tab block | Luna
    local espTab = window:CreateTab({
        Name = "ESP", Icon = "visibility", ImageSource = "Material",
    })
    State.ESPTab = espTab
    local function refreshESPControls()
        if State.Alive then updateESP() end
    end
    local function espToggle(name: string, field: string, description: string?)
        State.Controls[field] = espTab:CreateToggle({
            Name = name,
            Description = description,
            CurrentValue = Config[field],
            Callback = function(value)
                if type(value) ~= "boolean" then return end
                Config[field] = value
                refreshESPControls()
            end,
        }, field)
    end
    local function espSlider(name: string, field: string, minimum: number, maximum: number,
        increment: number, description: string?)
        State.Controls[field] = espTab:CreateSlider({
            Name = name,
            Description = description,
            Range = {minimum, maximum},
            Increment = increment,
            CurrentValue = Config[field],
            Callback = function(value)
                if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
                Config[field] = math.clamp(value, minimum, maximum)
                refreshESPControls()
            end,
        }, field)
    end
    local function espDropdown(name: string, field: string, options: {string}, description: string?)
        State.Controls[field] = espTab:CreateDropdown({
            Name = name,
            Description = description,
            Options = options,
            CurrentOption = {Config[field]},
            MultipleOptions = false,
            Callback = function(value)
                if type(value) == "table" then value = value[1] end
                if type(value) ~= "string" or not table.find(options, value) then return end
                Config[field] = value
                refreshESPControls()
            end,
        }, field)
    end
    local function espColor(name: string, field: string)
        State.Controls[field] = espTab:CreateColorPicker({
            Name = name,
            Color = Config[field],
            Callback = function(color)
                if typeof(color) ~= "Color3" then return end
                Config[field] = color
                refreshESPControls()
            end,
        }, field)
    end

    espTab:CreateSection("Players")
    espToggle("Enable ESP", "ESPEnabled", "Show or hide all player and floor item overlays.")
    espToggle("Player ESP", "ESPPlayers")
    espToggle("Player boxes", "ESPBoxes")
    espToggle("Player names", "ESPNames")
    espToggle("Use display names", "ESPUseDisplayNames", "Turn off to show Roblox usernames.")
    espToggle("Health bars", "ESPHealth")
    espToggle("Health numbers", "ESPHealthText")
    espToggle("Held weapon", "ESPWeapons", "Show the weapon or item currently held by each player.")
    espToggle("Player distance", "ESPDistance")
    espToggle("Faction labels", "ESPTeamNames")
    espToggle("Player tracers", "ESPTracers")
    espSlider("Player distance (studs)", "ESPMaxDistance", 100, 10000, 50)

    espTab:CreateSection("Player visibility")
    espToggle("Use police and crew filters", "ESPFilters",
        "Follow your police and crew checks from Aimbot.")
    espToggle("Color blocked players", "ESPVisibilityCheck",
        "Use the blocked color when a wall hides the player.")
    espToggle("Show visible players only", "ESPVisibleOnly",
        "Hide player overlays behind walls.")

    espTab:CreateSection("Player appearance")
    espDropdown("Box style", "ESPBoxStyle", {"Full", "Corners"})
    espDropdown("Tracer origin", "ESPTracerOrigin", {"Bottom", "Center", "Top"})
    espToggle("Filled player boxes", "ESPBoxFill")
    espToggle("Use faction colors", "ESPUseTeamColors")
    espToggle("Text outlines", "ESPTextOutline")
    espSlider("Player text size", "ESPTextSize", 8, 32, 1)
    espSlider("Box and tracer thickness", "ESPBoxThickness", 1, 5, 0.5)
    espSlider("Box fill opacity", "ESPFillOpacity", 0, 1, 0.01)
    espSlider("Player overlay opacity", "ESPOpacity", 0, 1, 0.01)
    espColor("Default player color", "ESPColor")
    espColor("Police color", "ESPPoliceColor")
    espColor("Syndicate color", "ESPSyndicateColor")
    espColor("Crew and friendly color", "ESPFriendlyColor")
    espColor("Blocked player color", "ESPOccludedColor")

    espTab:CreateSection("Floor items")
    espToggle("Floor item ESP", "ESPItems")
    espToggle("Item names", "ESPItemNames")
    espToggle("Item dollar values", "ESPItemValues")
    espToggle("Item distance", "ESPItemDistance")
    espToggle("Item rarity", "ESPItemRarity")
    espToggle("Avoid overlapping item labels", "ESPItemAvoidOverlap")
    espToggle("Show items through walls", "ESPItemThroughWalls")
    espToggle("Show items with unknown values", "ESPItemShowUnknown",
        "Keep unpriced items visible when your value filter allows them.")
    espDropdown("Item category", "ESPItemFilter",
        {"All", "Loot", "Weapons", "Cash", "Bags", "Other", "High value only"})
    espSlider("Item distance (studs)", "ESPItemMaxDistance", 50, 10000, 50)
    espSlider("Minimum item value ($)", "ESPItemMinValue", 0, 200000, 1000)
    espSlider("Item text size", "ESPItemTextSize", 8, 32, 1)
    espColor("Standard item color", "ESPItemColor")

    espTab:CreateSection("Valuable items")
    espToggle("Highlight valuable items", "ESPItemHighlight",
        "Highlight items at or above your dollar threshold. Default: $20,000.")
    espSlider("Valuable item threshold ($)", "ESPHighValueThreshold", 1000, 200000, 1000)
    espColor("Valuable item color", "ESPHighValueColor")
    espSlider("Item highlight fill opacity", "ESPItemFillOpacity", 0, 1, 0.01)

    espTab:CreateSection("ESP performance")
    espSlider("Overlay refresh rate (Hz)", "ESPRefreshRate", 5, 60, 1)
    espSlider("Maximum item labels", "ESPItemLabelLimit", 10, 200, 1)
    espSlider("Maximum item highlights", "ESPItemHighlightLimit", 1, 24, 1)
    table.insert(State.Connections, Players.PlayerRemoving:Connect(removeESPPlayer))


    targeting:CreateSection("Field of view")
    State.Controls.ShowCircle = targeting:CreateToggle({
        Name = "Show FOV circle",
        CurrentValue = Config.ShowCircle,
        Callback = function(value) Config.ShowCircle = value end,
    }, "ShowCircle")
    State.Controls.Radius = targeting:CreateSlider({
        Name = "FOV radius (pixels)",
        Range = {5, 3000},
        Increment = 5,
        CurrentValue = Config.Radius,
        Callback = function(value)
            if type(value) == "number" and value == value then
                Config.Radius = math.clamp(value, 5, 3000)
            end
        end,
    }, "Radius")
    State.Controls.CircleColor = targeting:CreateColorPicker({
        Name = "FOV circle color",
        Color = Config.CircleColor,
        Callback = function(color) Config.CircleColor = color end,
    }, "CircleColor")
    local visuals = window:CreateTab({Name = "UI settings", Icon = "settings", ImageSource = "Material"})
    State.Controls.MenuKey = visuals:CreateBind({
        Name = "Open menu key",
        CurrentBind = Config.MenuKey,
        HoldToInteract = false,
        OnChangedCallback = function(keyName)
            if not assignFeatureKey("MenuKey", keyName) then return end
            window.Bind = Enum.KeyCode[keyName]
        end,
        Callback = function() end,
    }, "MenuKey")
    visuals:CreateParagraph({
        Title = "Menu",
        Text = "Use X to hide the menu and your menu key to reopen it. "
            .. "The circle and target selection share the exact screen center. "
            .. "Luna blur is disabled.",
    })
    visuals:CreateButton({Name = "缩小界面", Callback = function()
        if State.SetWindowZoom then State.SetWindowZoom(-0.1) end
    end})
    visuals:CreateButton({Name = "放大界面", Callback = function()
        if State.SetWindowZoom then State.SetWindowZoom(0.1) end
    end})
    visuals:BuildThemeSection()
    local movementTab = window:CreateTab({Name = "Movement", Icon = "directions_walk", ImageSource = "Material"})
    State.Controls.Noclip = movementTab:CreateToggle({
        Name = "Character noclip", CurrentValue = Config.Noclip,
        Description = "Pass through solid parts. Turning off restores your character's original collisions.",
        Callback = function(value) setNoclip(value, false) end,
    }, "Noclip")
    State.Controls.NoclipKey = movementTab:CreateBind({
        Name = "Character noclip toggle key", CurrentBind = Config.NoclipKey, HoldToInteract = false,
        OnChangedCallback = function(keyName) assignFeatureKey("NoclipKey", keyName) end,
        Callback = function()
            if State.Alive and not UserInputService:GetFocusedTextBox() then setNoclip(not Config.Noclip, true) end
        end,
    }, "NoclipKey")
    local vehiclesTab = window:CreateTab({Name = "Vehicles", Icon = "directions_car", ImageSource = "Material"})
    State.Controls.VehicleNoclip = vehiclesTab:CreateToggle({
        Name = "Car / motorcycle / helicopter noclip", CurrentValue = Config.VehicleNoclip,
        Description = "Driver only. Includes your rider. Pair with flight to pass through floors; switch off in clear space.",
        Callback = function(value) setVehicleNoclip(value, false) end,
    }, "VehicleNoclip")
    State.Controls.VehicleNoclipKey = vehiclesTab:CreateBind({
        Name = "Vehicle noclip toggle key", CurrentBind = Config.VehicleNoclipKey, HoldToInteract = false,
        OnChangedCallback = function(keyName) assignFeatureKey("VehicleNoclipKey", keyName) end,
        Callback = function()
            if State.Alive and not UserInputService:GetFocusedTextBox() then setVehicleNoclip(not Config.VehicleNoclip, true) end
        end,
    }, "VehicleNoclipKey")
    State.Controls.VehicleBoostKey = vehiclesTab:CreateBind({
        Name = "Emergency acceleration toggle key", CurrentBind = Config.VehicleBoostKey, HoldToInteract = false,
        OnChangedCallback = function(keyName) assignFeatureKey("VehicleBoostKey", keyName) end,
        Callback = function()
            if State.Alive and not UserInputService:GetFocusedTextBox() then setVehicleBoost(not Config.VehicleAcceleration, true) end
        end,
    }, "VehicleBoostKey")
    State.Controls.VehicleSpeedOverride = vehiclesTab:CreateToggle({
        Name = "Custom top speed while boost is on", CurrentValue = Config.VehicleSpeedOverride,
        Callback = function(value) Config.VehicleSpeedOverride = value; releaseVehicleAssist() end,
    }, "VehicleSpeedOverride")
    State.Controls.VehicleMaxKmh = vehiclesTab:CreateSlider({
        Name = "Top speed (km/h)", Description = "Up to 600 km/h, approximately 373 mph.",
        Range = {30, 600}, Increment = 5, CurrentValue = Config.VehicleMaxKmh,
        Callback = function(value)
            if type(value) == "number" and isFiniteNumber(value) then
                Config.VehicleMaxKmh = math.clamp(value, 30, 600)
                releaseVehicleAssist()
            end
        end,
    }, "VehicleMaxKmh")
    State.Controls.VehicleInstantBrakes = vehiclesTab:CreateToggle({
        Name = "Instant brakes", Description = "Stop horizontal motion immediately with the normal brake or handbrake.",
        CurrentValue = Config.VehicleInstantBrakes,
        Callback = function(value) Config.VehicleInstantBrakes = value; releaseVehicleAssist() end,
    }, "VehicleInstantBrakes")
    State.Controls.VehicleAcceleration = vehiclesTab:CreateToggle({
        Name = "Emergency acceleration boost",
        Description = "Off by default. Your boost key toggles this; off restores normal acceleration and top speed.",
        CurrentValue = Config.VehicleAcceleration,
        Callback = function(value)
            setVehicleBoost(value, false)
        end,
    }, "VehicleAcceleration")
    State.Controls.VehicleAccelTime = vehiclesTab:CreateSlider({
        Name = "Time to top speed (seconds)",
        Description = "Default: 2 seconds. Set to 0 for instant acceleration.",
        Range = {0, 2}, Increment = 0.1, CurrentValue = Config.VehicleAccelTime,
        Callback = function(value)
            if type(value) == "number" and isFiniteNumber(value) then
                Config.VehicleAccelTime = math.clamp(value, 0, 2)
                releaseVehicleAssist()
            end
        end,
    }, "VehicleAccelTime")
    vehiclesTab:CreateSection("Vehicle flight")
    State.Controls.VehicleFly = vehiclesTab:CreateToggle({
        Name = "Car / motorcycle flight", CurrentValue = Config.VehicleFly,
        Description = "WASD move. Space / Ctrl up / down. Q / E turn. Release movement keys to hover.",
        Callback = function(value) setVehicleFlight(value, false) end,
    }, "VehicleFly")
    State.Controls.VehicleFlyKey = vehiclesTab:CreateBind({
        Name = "Flight toggle key", CurrentBind = Config.VehicleFlyKey, HoldToInteract = false,
        OnChangedCallback = function(keyName) assignFeatureKey("VehicleFlyKey", keyName) end,
        Callback = function()
            if State.Alive and not UserInputService:GetFocusedTextBox() then setVehicleFlight(not Config.VehicleFly, true) end
        end,
    }, "VehicleFlyKey")
    State.Controls.VehicleFlyKmh = vehiclesTab:CreateSlider({
        Name = "Flight speed (km/h)", Range = {30, 600}, Increment = 5, CurrentValue = Config.VehicleFlyKmh,
        Callback = function(value)
            if type(value) == "number" and isFiniteNumber(value) then Config.VehicleFlyKmh = math.clamp(value, 30, 600) end
        end,
    }, "VehicleFlyKmh")
    table.insert(State.Connections, UserInputService.WindowFocusReleased:Connect(function() State.VehicleHasFocus = false end))
    table.insert(State.Connections, UserInputService.WindowFocused:Connect(function() State.VehicleHasFocus = true end))
    visuals:CreateButton({
        Name = "Reset keybind list position",
        Description = "Drag the list by its header. Its position saves with your config.",
        Callback = function()
            Config.KeybindX, Config.KeybindY = 1, 0.08
            updateKeybindList()
        end,
    })
    buildProfiles(window)
    setupChineseMobile()
    espTab:Activate()
    visuals:CreateButton({
        Name = "Restore aim and visuals",
        Description = "Enable aim, player/item ESP and the circle, with a visible 150-pixel FOV. Keep your keybind.",
        Callback = function() State.RestoreFeatures() end,
    })
    visuals:CreateButton({
        Name = "Unload and restore",
        Description = "Remove the menu, ESP, circle, aim and rotation; restore AutoRotate.",
        Callback = function() task.defer(cleanup) end,
    })

    hook = function(ownerId: any, toolId: any, muzzleCFrame: any, data: any, ...: any)
        if not State.Alive or not Config.Enabled or ownerId ~= LocalPlayer.UserId
            or type(data) ~= "table" then
            return original(ownerId, toolId, muzzleCFrame, data, ...)
        end
        State.HookCalls += 1
        -- Resolve once per batch, so every pellet shares one valid target.
        local head = getTarget()
        State.Target = head
        if not head then return original(ownerId, toolId, muzzleCFrame, data, ...) end
        local rewritten = rewriteProjectiles(data, aimPosition(head), head)
        rememberShotDirections(toolId, data, rewritten)
        State.RedirectedBatches += 1
        return original(ownerId, toolId, muzzleCFrame, rewritten, ...)
    end
    State.Hook = hook
    if type(lifecycle) == "table" and type(lifecycle.override) == "function" then
        lifecycle.override(ClientGuns, "MakeGunProjectiles", hook)
    else
        ClientGuns.MakeGunProjectiles = hook
    end

    networkHook = function(event: any, ...: any)
        if not State.Alive or event ~= "shoot" then return originalNetworkFire(event, ...) end
        local args = table.pack(...)
        args[3] = syncShotPacket(args[1], args[3])
        return originalNetworkFire(event, table.unpack(args, 1, args.n))
    end
    batchHook = function(toolId: any, muzzle: any, data: any, ...: any)
        if not State.Alive then return originalBatchAuto(toolId, muzzle, data, ...) end
        return originalBatchAuto(toolId, muzzle, syncShotPacket(toolId, data), ...)
    end
    State.NetworkHook = networkHook
    State.BatchHook = batchHook
    if type(lifecycle) == "table" and type(lifecycle.override) == "function" then
        lifecycle.override(Network, "FireServer", networkHook)
        lifecycle.override(ClientGuns, "BatchAutoFirePacket", batchHook)
    else
        Network.FireServer = networkHook
        ClientGuns.BatchAutoFirePacket = batchHook
    end

    removeLegacyLunaBlur()
    releaseRotation(true)
    local function updateCircle()
        local camera = workspace.CurrentCamera
        circle.Visible = State.Alive and Config.ShowCircle and camera ~= nil
        if camera then
            circle.Position, circle.Radius, circle.Color = camera.ViewportSize / 2, Config.Radius, Config.CircleColor
        end
    end
    State.UpdateCircle = updateCircle
    table.insert(State.Connections, RunService.PreSimulation:Connect(function(dt)
        runFeature("BodyRotation", updateRotation)
    end))
    table.insert(State.Connections, RunService.PreSimulation:Connect(function(dt)
        runFeature("Vehicles", updateVehicleAcceleration, dt)
    end))
    table.insert(State.Connections, RunService.PreSimulation:Connect(function()
        runFeature("Noclip", updateNoclip)
    end))
    table.insert(State.Connections, LocalPlayer.CharacterRemoving:Connect(releaseNoclip))
    RunService:BindToRenderStep(rotationBinding, Enum.RenderPriority.Character.Value + 1, function()
        runFeature("BodyRotationRender", updateRotation)
    end)
    runFeature("FloorDiscovery", refreshItems)
    runFeature("NPCDiscovery", refreshNPCs)
    local itemElapsed, statusElapsed, espElapsed = 0, 0, 0
    table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
        if not State.Alive then return end
        itemElapsed += dt
        if itemElapsed < 0.5 then return end
        itemElapsed = 0
        runFeature("FloorDiscovery", refreshItems)
        runFeature("NPCDiscovery", refreshNPCs)
    end))
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        runFeature("FOV", updateCircle)
    end))
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        runFeature("KeybindHUD", updateKeybindList)
        if State.UpdateMobileVisibility then State.UpdateMobileVisibility() end
    end))
    table.insert(State.Connections, RunService.RenderStepped:Connect(function(dt)
        if not State.Alive then return end
        espElapsed += dt
        if espElapsed < 1 / math.clamp(Config.ESPRefreshRate, 5, 60) then return end
        espElapsed = 0
        updateESP()
    end))
    local lastStatus = ""
    local function updateStatus()
        State.Target = getTarget()
        local head = State.Target
        local model = targetModel(head)
        local player = model and Players:GetPlayerFromCharacter(model)
        local targetName = if player then player.DisplayName else (if model then "[NPC] " .. model.Name else "范围内无可见目标")
        local text = string.format(
            "静默瞄准：%s [%s]\n阵营：%s\n队伍：%s\n目标：%s\n范围：%d 像素\n角色转向：%s\n玩家透视：%d 名可见\nNPC：%d 个存活／%d 个已加载判定框",
            Config.Enabled and "on" or "off", Config.AimKey,
            tostring(LocalPlayer:GetAttribute("currentTeam") or "loading"),
            tostring(LocalPlayer:GetAttribute("partyId") or "none"),
            targetName, Config.Radius,
            Config.Enabled and Config.RotationEnabled and (State.Rotation.Active and "跟踪中" or "等待目标") or "off",
            State.ESPStats.Visible or 0, State.NPCStats.Alive, State.NPCStats.Available
        )
        text = text .. "\n版本：" .. State.Build
        if text ~= lastStatus then lastStatus = text; status:Set({Text = text}) end
    end
    table.insert(State.Connections, RunService.RenderStepped:Connect(function(dt)
        if not State.Alive then return end
        statusElapsed += dt
        if statusElapsed < 0.2 then return end
        statusElapsed = 0
        runFeature("AimStatus", updateStatus)
    end))
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        runFeature("NativeOverlay", flushNativeOverlay)
    end))
    runFeature("FOV", updateCircle)
    runFeature("NativeOverlay", flushNativeOverlay)

end

local ok, setupError = pcall(setup)
if not ok then
    cleanup()
    error("Wanted aim setup failed: " .. tostring(setupError), 0)
end
return State
