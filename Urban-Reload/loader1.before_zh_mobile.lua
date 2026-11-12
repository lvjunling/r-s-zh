-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]

--[[rscripts:analytics:start]]
-- Script analytics (enabled by the creator on rscripts.net).
-- Runs in its own thread and cannot affect the script below.
task.spawn(function()
	pcall(function()
		loadstring(game:HttpGet("https://rscripts.net/api/telemetry/v2/client.lua?s=6adf4d77f733a6e82c132552"))()
	end)
end)
--[[rscripts:analytics:end]]

-- =========================================================
-- SILENT AIM + ESP + NO RECOIL
-- GUI carrée, sans Drawing
-- =========================================================
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM        = game:GetService("VirtualInputManager")
local RS         = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===== CONFIG =====
local CONFIG = {
    ENABLED         = false,
    AIMBOT_ENABLED  = false,
    TRIGGERBOT      = false,
    SHOW_FOV        = true,
    FOV             = 250,
    MAX_DISTANCE    = 800,
    AIM_PART        = "Head",
    SILENT_DELAY    = 0.05,
    PREDICT         = 0,
    AIM_SMOOTH      = 1.0,
    TRIGGER_DELAY   = 0.12,
    AIM_KEY         = Enum.UserInputType.MouseButton1,
    AIM_KEY_ALT     = Enum.UserInputType.MouseButton2,
}

local ESP = {
    ENABLED      = false,
    SHOW_BOX     = true,
    SHOW_NAME    = true,
    SHOW_HEALTH  = true,
    SHOW_DIST    = true,
    SHOW_TRACER  = true,
    MAX_DIST     = 1000,
    BOX_COLOR    = Color3.fromRGB(255, 60, 60),
    NAME_COLOR   = Color3.fromRGB(255, 255, 255),
    HEALTH_COLOR = Color3.fromRGB(0, 255, 100),
    TRACER_COLOR = Color3.fromRGB(255, 255, 255),
    TRACER_FROM  = "Bottom",
}

local NORECOIL = {
    ENABLED     = false,
    NO_BLOOM    = true,
    NO_SPREAD   = true,
    NO_RECOIL   = true,
    loaded      = false,
    clientState = nil,
    config      = nil,
}

local state = {
    currentTarget = nil,
    currentPos    = nil,
    holdingRight  = false,
    holdingLeft   = false,
    lastTrigger   = 0,
}

-- =========================================================
-- NO RECOIL
-- =========================================================
local function loadNoRecoilModules()
    local ok = pcall(function()
        local Weapons = RS:WaitForChild("Weapons", 5)
        if not Weapons then error("Weapons introuvable") end
        NORECOIL.clientState = require(Weapons:WaitForChild("ClientState"))
        NORECOIL.config = require(Weapons:WaitForChild("Config"))
        NORECOIL.loaded = true
    end)
    if not ok then NORECOIL.loaded = false; return false end
    return true
end

local NR_NAME = "NoRecoilLoop"
local NR_PRIORITY = Enum.RenderPriority.Camera.Value - 1

local function noRecoilLoop()
    if not NORECOIL.ENABLED or not NORECOIL.loaded then return end
    local cs, cfg = NORECOIL.clientState, NORECOIL.config
    if not cs then return end
    if NORECOIL.NO_RECOIL then
        cs.RecoilPitch = 0
        cs.RecoilYaw = 0
    end
    if NORECOIL.NO_SPREAD then
        cs.Spread = 0
        cs.SpreadRest = 0
        cs.SpreadMultiplier = 0
    end
    if NORECOIL.NO_BLOOM and cfg and cfg.Global then
        pcall(function() cfg.Global.BloomScale = 0 end)
    end
end

local function startNoRecoil()
    if not NORECOIL.loaded and not loadNoRecoilModules() then
        warn("[NoRecoil] Modules introuvables")
        return false
    end
    pcall(function() RunService:UnbindFromRenderStep(NR_NAME) end)
    RunService:BindToRenderStep(NR_NAME, NR_PRIORITY, noRecoilLoop)
    return true
end

local function stopNoRecoil()
    pcall(function() RunService:UnbindFromRenderStep(NR_NAME) end)
end

-- =========================================================
-- SCAN JOUEURS
-- =========================================================
local cachedTargets = {}
local lastScan = 0
local SCAN_INTERVAL = 0.1

local function scanPlayers()
    local now = tick()
    if now - lastScan < SCAN_INTERVAL then return cachedTargets end
    lastScan = now
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(list, char)
            end
        end
    end
    cachedTargets = list
    return list
end

local function getAimPosition(char)
    if not char or not char.Parent then return nil end
    local part = char:FindFirstChild(CONFIG.AIM_PART)
        or char:FindFirstChild("HumanoidRootPart")
        or char.PrimaryPart
    if not part then return nil end
    local pos = part.Position
    if CONFIG.PREDICT > 0 and part:IsA("BasePart") then
        pos = pos + part.AssemblyLinearVelocity * CONFIG.PREDICT
    end
    return pos
end

local function getBestTarget()
    local myChar = player.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local vp = camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local best, bestDist2D, bestChar = nil, math.huge, nil

    for _, target in ipairs(scanPlayers()) do
        local aimPos = getAimPosition(target)
        if aimPos and (myRoot.Position - aimPos).Magnitude <= CONFIG.MAX_DISTANCE then
            local sp, onScreen = camera:WorldToViewportPoint(aimPos)
            if onScreen then
                local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d2 <= CONFIG.FOV and d2 < bestDist2D then
                    bestDist2D = d2
                    best = aimPos
                    bestChar = target
                end
            end
        end
    end
    return best, bestChar, bestDist2D
end

-- =========================================================
-- SILENT AIM
-- =========================================================
local function snapCamera(targetPos)
    if not targetPos then return end
    local old = camera.CFrame
    local goal = CFrame.lookAt(old.Position, targetPos)
    if CONFIG.AIM_SMOOTH >= 1 then
        camera.CFrame = goal
    else
        camera.CFrame = old:Lerp(goal, CONFIG.AIM_SMOOTH)
    end
    task.wait(CONFIG.SILENT_DELAY)
    camera.CFrame = old
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == CONFIG.AIM_KEY then
        state.holdingLeft = true
        if CONFIG.ENABLED and not CONFIG.AIMBOT_ENABLED then
            task.spawn(function()
                local pos = getBestTarget()
                snapCamera(pos)
            end)
        end
    elseif input.UserInputType == CONFIG.AIM_KEY_ALT then
        state.holdingRight = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == CONFIG.AIM_KEY then
        state.holdingLeft = false
    elseif input.UserInputType == CONFIG.AIM_KEY_ALT then
        state.holdingRight = false
    end
end)

-- =========================================================
-- AIMBOT + TRIGGERBOT
-- =========================================================
RunService.RenderStepped:Connect(function()
    if not CONFIG.ENABLED then
        state.currentTarget = nil
        state.currentPos = nil
        return
    end

    local targetPos, targetChar, dist2D = getBestTarget()
    state.currentTarget = targetChar
    state.currentPos = targetPos

    if CONFIG.AIMBOT_ENABLED and state.holdingRight and targetPos then
        local old = camera.CFrame
        local goal = CFrame.lookAt(old.Position, targetPos)
        if CONFIG.AIM_SMOOTH >= 1 then
            camera.CFrame = goal
        else
            camera.CFrame = old:Lerp(goal, math.min(CONFIG.AIM_SMOOTH * 3, 1))
        end
    end

    if CONFIG.TRIGGERBOT and targetPos and dist2D and dist2D < 30 then
        local now = tick()
        if now - state.lastTrigger > CONFIG.TRIGGER_DELAY then
            state.lastTrigger = now
            task.spawn(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

-- =========================================================
-- ESP (version GUI, pas de Drawing)
-- =========================================================
local espGui = Instance.new("ScreenGui")
espGui.Name = "ESP_GUI"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.Parent = player:WaitForChild("PlayerGui")

local espObjects = {}

local function createESP(p)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = espGui

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 1
    box.BorderColor3 = ESP.BOX_COLOR
    box.Parent = frame

    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.BackgroundTransparency = 1
    name.TextColor3 = ESP.NAME_COLOR
    name.Font = Enum.Font.GothamBold
    name.TextSize = 14
    name.TextStrokeTransparency = 0
    name.Parent = frame

    local hpBg = Instance.new("Frame")
    hpBg.Name = "HpBg"
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = frame

    local hp = Instance.new("Frame")
    hp.Name = "Hp"
    hp.BackgroundColor3 = ESP.HEALTH_COLOR
    hp.BorderSizePixel = 0
    hp.Parent = hpBg

    local dist = Instance.new("TextLabel")
    dist.Name = "Dist"
    dist.BackgroundTransparency = 1
    dist.TextColor3 = ESP.NAME_COLOR
    dist.Font = Enum.Font.Gotham
    dist.TextSize = 12
    dist.TextStrokeTransparency = 0
    dist.Parent = frame

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.BackgroundColor3 = ESP.TRACER_COLOR
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0, 0.5)
    tracer.Parent = espGui

    espObjects[p] = {
        frame = frame,
        box = box,
        name = name,
        hpBg = hpBg,
        hp = hp,
        dist = dist,
        tracer = tracer,
    }
end

local function destroyESP(p)
    local d = espObjects[p]
    if not d then return end
    for _, obj in pairs(d) do
        pcall(function() obj:Destroy() end)
    end
    espObjects[p] = nil
end

local function destroyAllESP()
    for p in pairs(espObjects) do destroyESP(p) end
    espObjects = {}
end

RunService.RenderStepped:Connect(function()
    if not ESP.ENABLED then
        for _, d in pairs(espObjects) do
            d.frame.Visible = false
            d.tracer.Visible = false
        end
        return
    end

    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then
            if espObjects[p] then
                espObjects[p].frame.Visible = false
                espObjects[p].tracer.Visible = false
            end
            continue
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local dist = (myRoot.Position - root.Position).Magnitude
        if dist > ESP.MAX_DIST then
            if espObjects[p] then
                espObjects[p].frame.Visible = false
                espObjects[p].tracer.Visible = false
            end
            continue
        end

        if not espObjects[p] then createESP(p) end
        local d = espObjects[p]

        local head = char:FindFirstChild("Head")
        local topPos = head and (head.Position + Vector3.new(0, 0.5, 0)) or (root.Position + Vector3.new(0, 3, 0))
        local botPos = root.Position - Vector3.new(0, 3, 0)
        local topScreen, topOn = camera:WorldToViewportPoint(topPos)
        local botScreen, botOn = camera:WorldToViewportPoint(botPos)

        if not (topOn or botOn) then
            d.frame.Visible = false
            d.tracer.Visible = false
            continue
        end

        local height = math.abs(botScreen.Y - topScreen.Y)
        local width = height * 0.6
        local x = topScreen.X - width / 2
        local y = topScreen.Y

        d.frame.Visible = true
        d.frame.Position = UDim2.new(0, x, 0, y)
        d.frame.Size = UDim2.new(0, width, 0, height)

        d.box.Visible = ESP.SHOW_BOX
        d.box.Size = UDim2.new(1, 0, 1, 0)
        d.box.BorderColor3 = ESP.BOX_COLOR

        d.name.Visible = ESP.SHOW_NAME
        d.name.Text = p.Name
        d.name.Position = UDim2.new(0, 0, 0, -18)
        d.name.Size = UDim2.new(1, 0, 0, 16)

        if ESP.SHOW_HEALTH then
            local hpPct = hum.Health / hum.MaxHealth
            d.hpBg.Visible = true
            d.hpBg.Position = UDim2.new(0, -6, 0, 0)
            d.hpBg.Size = UDim2.new(0, 4, 1, 0)
            d.hp.Visible = true
            d.hp.Position = UDim2.new(0, 0, 1 - hpPct, 0)
            d.hp.Size = UDim2.new(1, 0, hpPct, 0)
            d.hp.BackgroundColor3 = ESP.HEALTH_COLOR
        else
            d.hpBg.Visible = false
            d.hp.Visible = false
        end

        d.dist.Visible = ESP.SHOW_DIST
        d.dist.Text = "[" .. math.floor(dist) .. "]"
        d.dist.Position = UDim2.new(0, 0, 1, 2)
        d.dist.Size = UDim2.new(1, 0, 0, 14)

        if ESP.SHOW_TRACER then
            local vp = camera.ViewportSize
            local fromX, fromY
            if ESP.TRACER_FROM == "Bottom" then
                fromX, fromY = vp.X / 2, vp.Y
            elseif ESP.TRACER_FROM == "Mouse" then
                local mp = UIS:GetMouseLocation()
                fromX, fromY = mp.X, mp.Y
            else
                fromX, fromY = vp.X / 2, vp.Y / 2
            end
            local toX = x + width / 2
            local toY = y + height / 2
            local dX = toX - fromX
            local dY = toY - fromY
            local len = math.sqrt(dX * dX + dY * dY)
            local angle = math.atan2(dY, dX)

            d.tracer.Visible = true
            d.tracer.BackgroundColor3 = ESP.TRACER_COLOR
            d.tracer.Position = UDim2.new(0, fromX, 0, fromY)
            d.tracer.Size = UDim2.new(0, len, 0, 1)
            d.tracer.Rotation = math.deg(angle)
        else
            d.tracer.Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(destroyESP)
player.CharacterAdded:Connect(destroyAllESP)

-- =========================================================
-- FOV VISUEL
-- =========================================================
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "SA_FOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.Parent = player:WaitForChild("PlayerGui")

local fovFrame = Instance.new("Frame")
fovFrame.Size = UDim2.fromOffset(CONFIG.FOV * 2, CONFIG.FOV * 2)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel = 0
fovFrame.Parent = fovGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1
fovStroke.Transparency = 0.5
fovStroke.Parent = fovFrame

RunService.RenderStepped:Connect(function()
    fovFrame.Visible = CONFIG.SHOW_FOV and CONFIG.ENABLED
    fovFrame.Size = UDim2.fromOffset(CONFIG.FOV * 2, CONFIG.FOV * 2)
    if state.currentTarget then
        fovStroke.Color = Color3.fromRGB(255, 60, 60)
        fovStroke.Transparency = 0
    else
        fovStroke.Color = Color3.fromRGB(255, 255, 255)
        fovStroke.Transparency = 0.5
    end
end)

-- =========================================================
-- GUI CARREE NOIR/BLANC
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("SA_MainGui") then
    playerGui.SA_MainGui:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "SA_MainGui"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 500)
main.Position = UDim2.new(0, 20, 0, 20)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 0)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 2
mainStroke.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
header.BorderSizePixel = 0
header.Parent = main
local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 2)
headerLine.Position = UDim2.new(0, 0, 1, -2)
headerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
headerLine.BorderSizePixel = 0
headerLine.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SILENT AIM + ESP + NO RECOIL"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header
local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Color3.fromRGB(255, 255, 255)
closeStroke.Thickness = 1
closeStroke.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    CONFIG.ENABLED = false
    ESP.ENABLED = false
    stopNoRecoil()
    sg:Destroy()
end)

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -44)
scroll.Position = UDim2.new(0, 10, 0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 5)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

-- Helpers
local function makeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = scroll
    return lbl
end

local function makeToggle(text, order, default, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)
    b.Text = text .. " : " .. (default and "ON" or "OFF")
    b.TextColor3 = default and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.LayoutOrder = order
    b.Parent = scroll
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Parent = b

    local state = default
    b.MouseButton1Click:Connect(function()
        state = not state
        b.BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)
        b.TextColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        b.Text = text .. " : " .. (state and "ON" or "OFF")
        callback(state)
    end)
    return b
end

local function makeSlider(text, order, min, max, default, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = scroll
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 18)
    lbl.Position = UDim2.new(0, 5, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. " : " .. default .. (suffix or "")
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -10, 0, 10)
    bar.Position = UDim2.new(0, 5, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(255, 255, 255)
    barStroke.Thickness = 1
    barStroke.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = bar

    clickBtn.MouseButton1Down:Connect(function()
        local dragging = true
        local conn1, conn2
        conn1 = UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * rel)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                lbl.Text = text .. " : " .. val .. (suffix or "")
                callback(val)
            end
        end)
        conn2 = UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                conn1:Disconnect()
                conn2:Disconnect()
            end
        end)
    end)
    return frame
end

local function makeDropdown(text, order, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = scroll
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Parent = frame

    local current = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text .. " : " .. current
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = frame

    local open = false
    local optionFrame = Instance.new("Frame")
    optionFrame.Size = UDim2.new(1, 0, 0, #options * 26)
    optionFrame.Position = UDim2.new(0, 0, 1, 0)
    optionFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    optionFrame.BorderSizePixel = 0
    optionFrame.Visible = false
    optionFrame.ZIndex = 5
    optionFrame.Parent = frame
    local optStroke = Instance.new("UIStroke")
    optStroke.Color = Color3.fromRGB(255, 255, 255)
    optStroke.Thickness = 1
    optStroke.Parent = optionFrame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1) * 26)
        optBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 10
        optBtn.BorderSizePixel = 0
        optBtn.ZIndex = 6
        optBtn.Parent = optionFrame
        optBtn.MouseButton1Click:Connect(function()
            current = opt
            btn.Text = text .. " : " .. current
            optionFrame.Visible = false
            open = false
            callback(opt)
        end)
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        optionFrame.Visible = open
    end)
    return frame
end

-- Section Activation
makeSection("ACTIVATION", 1)
makeToggle("Script actif", 2, false, function(v) CONFIG.ENABLED = v end)
makeToggle("Aimbot continu", 3, false, function(v) CONFIG.AIMBOT_ENABLED = v end)
makeToggle("TriggerBot", 4, false, function(v) CONFIG.TRIGGERBOT = v end)
makeToggle("Afficher FOV", 5, true, function(v) CONFIG.SHOW_FOV = v end)

-- Section Silent Aim
makeSection("SILENT AIM", 6)
makeSlider("FOV", 7, 50, 800, 250, "px", function(v) CONFIG.FOV = v end)
makeSlider("Distance max", 8, 50, 2000, 800, " studs", function(v) CONFIG.MAX_DISTANCE = v end)
makeSlider("Delai silent", 9, 5, 200, 50, "ms", function(v) CONFIG.SILENT_DELAY = v / 1000 end)
makeSlider("Smooth", 10, 10, 100, 100, "%", function(v) CONFIG.AIM_SMOOTH = v / 100 end)
makeSlider("Prediction", 11, 0, 100, 0, "ms", function(v) CONFIG.PREDICT = v / 1000 end)
makeSlider("Delai triggerbot", 12, 50, 500, 120, "ms", function(v) CONFIG.TRIGGER_DELAY = v / 1000 end)

makeDropdown("Partie visee", 13, {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}, "Head", function(v)
    CONFIG.AIM_PART = v
end)

-- Section ESP
makeSection("ESP", 14)
makeToggle("ESP actif", 15, false, function(v) ESP.ENABLED = v end)
makeToggle("Boite", 16, true, function(v) ESP.SHOW_BOX = v end)
makeToggle("Nom", 17, true, function(v) ESP.SHOW_NAME = v end)
makeToggle("Barre de vie", 18, true, function(v) ESP.SHOW_HEALTH = v end)
makeToggle("Distance", 19, true, function(v) ESP.SHOW_DIST = v end)
makeToggle("Tracer", 20, true, function(v) ESP.SHOW_TRACER = v end)
makeSlider("Distance max ESP", 21, 50, 5000, 1000, " studs", function(v) ESP.MAX_DIST = v end)
makeDropdown("Tracer depuis", 22, {"Bottom", "Center", "Mouse"}, "Bottom", function(v) ESP.TRACER_FROM = v end)

-- Section No Recoil
makeSection("NO RECOIL", 23)
makeToggle("No Recoil actif", 24, false, function(v)
    NORECOIL.ENABLED = v
    if v then startNoRecoil() else stopNoRecoil() end
end)
makeToggle("No Recoil (pitch/yaw)", 25, true, function(v) NORECOIL.NO_RECOIL = v end)
makeToggle("No Spread", 26, true, function(v) NORECOIL.NO_SPREAD = v end)
makeToggle("No Bloom", 27, true, function(v) NORECOIL.NO_BLOOM = v end)

-- Section Diagnostic
makeSection("DIAGNOSTIC", 28)
local diagBtn = Instance.new("TextButton")
diagBtn.Size = UDim2.new(1, 0, 0, 28)
diagBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
diagBtn.Text = "Tester compatibilite No Recoil"
diagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
diagBtn.Font = Enum.Font.GothamBold
diagBtn.TextSize = 11
diagBtn.BorderSizePixel = 0
diagBtn.LayoutOrder = 29
diagBtn.Parent = scroll
local diagStroke = Instance.new("UIStroke")
diagStroke.Color = Color3.fromRGB(255, 255, 255)
diagStroke.Thickness = 1
diagStroke.Parent = diagBtn
diagBtn.MouseButton1Click:Connect(function()
    if loadNoRecoilModules() then
        print("[NoRecoil] Modules trouves - compatible")
    else
        print("[NoRecoil] Modules Weapons introuvables")
    end
end)

print("========================================")
print("[SA + ESP + NR] Script charge")
print("  Clic gauche = silent aim")
print("  Clic droit = aimbot continu")
print("  X = fermer")
print("========================================")
