-- [[ 🥊 BOLSONARO BATTLEGROUNDS V3.1 - OP + LEGIT ]] --
-- Fix: forward declarations + Config.Aimbot + applyProfile seguro

print("═══════════════════════════════════════════")
print("  🥊  战场助手  •  v3.1")
print("  强力 + 拟真 | 30+ 项功能")
print("═══════════════════════════════════════════")

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local VirtualInput     = game:GetService("VirtualInputManager")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

-- ═══════════════════════════════════════════════
--  FORWARD DECLARATIONS (evita bug de ordem)
-- ═══════════════════════════════════════════════
local applySpeed, applyJump, applyFOV, applyBrightness, applyFPSBoost
local cleanupESP, cleanupEnemyHitboxes, triggerBlockDown, triggerBlockUp
local refreshUIRefs = {}

-- ═══════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════
local Config = {
    Debug = false,
    Profile = "OP",

    -- ESP
    ESP = { Enabled = false, Color = Color3.fromRGB(255, 60, 60), ShowName = true, ShowHealth = true, ShowDistance = true },

    -- Combat
    AutoBlock = { Enabled = false, Radius = 15 },
    AutoParry = { Enabled = false, Radius = 12, ReactionDelay = 0.08 },
    AutoCombo = { Enabled = false, Key1 = Enum.KeyCode.One },
    AutoDodge = { Enabled = false, TriggerDist = 15, Cooldown = 0.4 },
    AutoSkill = { Enabled = false, Key1 = Enum.KeyCode.One, Key2 = Enum.KeyCode.Two, Key3 = Enum.KeyCode.Three, Key4 = Enum.KeyCode.Four },
    KillAura = { Enabled = false, Radius = 8, Delay = 0.12 },
    Hitbox = { Enabled = false, SizeX = 6, SizeY = 6, SizeZ = 6, ShowVisual = false },
    M1Reach = { Enabled = false, Range = 12 },
    SilentAim = { Enabled = false, FOV = 90, ClickDelay = 0.05 },
    AntiStun = { Enabled = false },
    TeleportToEnemy = { Enabled = false, Key = Enum.KeyCode.T },
    Aimbot = { Enabled = false, Smoothness = 0.15, Radius = 60, PredictTime = 0.15 },

    -- Movement
    Speed = { Enabled = false, WalkSpeed = 32, BaseSpeed = 16 },
    JumpPower = { Enabled = false, Value = 80, Base = 50 },
    InfiniteJump = { Enabled = false },
    Fly = { Enabled = false, Speed = 60 },
    Noclip = { Enabled = false },

    -- Visual
    Brightness = { Enabled = false, Value = 1.5 },
    FOV = { Value = 70, Base = 70 },
    FPSBoost = { Enabled = false },

    -- Legit
    Humanization = { Enabled = false, MinDelay = 0.05, MaxDelay = 0.2 },
    LegitAimbotFOV = { Value = 45 },

    -- Misc
    AntiAFK = { Enabled = false },
}

local Profiles = {
    OP = {
        Speed = { Enabled = true, WalkSpeed = 60 },
        JumpPower = { Enabled = true, Value = 120 },
        Hitbox = { Enabled = true, SizeX = 9, SizeY = 9, SizeZ = 9, ShowVisual = false },
        M1Reach = { Enabled = true, Range = 20 },
        KillAura = { Enabled = true, Radius = 10 },
        AutoBlock = { Enabled = true, Radius = 20 },
        AutoParry = { Enabled = true, Radius = 15, ReactionDelay = 0.03 },
        SilentAim = { Enabled = true, FOV = 120, ClickDelay = 0.03 },
        AutoDodge = { Enabled = true, TriggerDist = 20, Cooldown = 0.3 },
        Aimbot = { Enabled = true, Smoothness = 0.05, Radius = 90, PredictTime = 0.15 },
        AntiStun = { Enabled = true },
    },
    Legit = {
        Speed = { Enabled = true, WalkSpeed = 22 },
        JumpPower = { Enabled = false, Value = 55 },
        Hitbox = { Enabled = true, SizeX = 4.5, SizeY = 4.5, SizeZ = 4.5, ShowVisual = false },
        M1Reach = { Enabled = true, Range = 13 },
        KillAura = { Enabled = false, Radius = 6 },
        AutoBlock = { Enabled = true, Radius = 12 },
        AutoParry = { Enabled = true, Radius = 10, ReactionDelay = 0.18 },
        SilentAim = { Enabled = true, FOV = 45, ClickDelay = 0.12 },
        AutoDodge = { Enabled = true, TriggerDist = 12, Cooldown = 0.6 },
        Aimbot = { Enabled = true, Smoothness = 0.35, Radius = 40, PredictTime = 0.1 },
        Humanization = { Enabled = true, MinDelay = 0.08, MaxDelay = 0.25 },
        AntiStun = { Enabled = false },
    },
}

-- ═══════════════════════════════════════════════
--  ESTADO
-- ═══════════════════════════════════════════════
local Connections = {}
local UI_Elements = {}
local originalLighting = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
local destroyed = false
local espObjects = {}
local enemyHitboxData = {}
local dummyTouchConns = {}
local blockActive = false
local flyBV, flyBG = nil, nil
local lastKillAura, lastAutoCombo, lastM1Reach = 0, 0, 0
local lastAutoDodge, lastAutoSkill = 0, 0
local lastParryTrigger = 0
local mainFrame, restoreBtn = nil, nil
local savedPos = UDim2.fromScale(0.5, 0.5)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local savedFPS = nil
local blockButton = nil
local jumpRequested = false
local lastJumpTime = 0

-- ═══════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════
local function safeCall(f, ...) 
    if not f then return end
    local ok, err = pcall(f, ...); 
    if not ok and Config.Debug then warn("[BOLSONARO]", err) end
    return ok 
end

local function getSafeCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.Health > 0 then return char end
    return nil
end

local function getClosestEnemy(maxDist)
    local char = getSafeCharacter(); if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local best, bestDist = nil, maxDist or math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eHum = p.Character:FindFirstChildOfClass("Humanoid")
            local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if eHum and eRoot and eHum.Health > 0 then
                local d = (hrp.Position - eRoot.Position).Magnitude
                if d < bestDist then best, bestDist = p, d end
            end
        end
    end
    return best
end

local function pressKey(key, hold)
    hold = hold or 0.05
    safeCall(function() VirtualInput:SendKeyEvent(true, key, false, game) end)
    task.wait(hold)
    safeCall(function() VirtualInput:SendKeyEvent(false, key, false, game) end)
end

local function clickMouse()
    safeCall(function() VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0) end)
    task.wait(0.02)
    safeCall(function() VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
end

local function findBlockButton()
    if not isMobile then return nil end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui"); if not playerGui then return nil end
    local nomes = { "block", "guard", "defend", "defense", "parry", "shield" }
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local n = gui.Name:lower()
            for _, a in ipairs(nomes) do
                if n:find(a, 1, true) and gui.Visible and gui.AbsoluteSize.X > 0 then
                    return gui
                end
            end
        end
    end
    return nil
end

local function ensureTouchInterest(part)
    if not part or not part.Parent then return false end
    for _, child in ipairs(part:GetChildren()) do
        if child.Name == "TouchInterest" then return true end
    end
    if not dummyTouchConns[part] or not dummyTouchConns[part].Connected then
        pcall(function() dummyTouchConns[part] = part.Touched:Connect(function() end) end)
    end
    return true
end

local function humanDelay()
    if not Config.Humanization.Enabled then return 0 end
    return Config.Humanization.MinDelay + math.random() * (Config.Humanization.MaxDelay - Config.Humanization.MinDelay)
end

-- ═══════════════════════════════════════════════
--  APLICAR PERFIL (agora seguro)
-- ═══════════════════════════════════════════════
local function applyProfile(name)
    local p = Profiles[name]
    if not p then return end
    Config.Profile = name
    for section, values in pairs(p) do
        if Config[section] then
            for k, v in pairs(values) do
                Config[section][k] = v
            end
        end
    end
    -- Reaplica efeitos (agora com forward declared functions)
    if applySpeed then pcall(applySpeed) end
    if applyJump then pcall(applyJump) end
    if applyFOV then pcall(applyFOV) end
    for _, r in ipairs(refreshUIRefs) do pcall(r) end
    print("[战场助手] 已应用配置：", name)
end

-- ═══════════════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════════════
cleanupESP = function()
    for _, obj in pairs(espObjects) do
        if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
        if obj.billboard then pcall(function() obj.billboard:Destroy() end) end
    end
    espObjects = {}
end

local function updateESP()
    if not Config.ESP.Enabled then if next(espObjects) then cleanupESP() end return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local obj = espObjects[player]
                if obj and (not obj.highlight or not obj.highlight.Parent or obj.highlight.Adornee ~= char) then
                    if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
                    if obj.billboard then pcall(function() obj.billboard:Destroy() end) end
                    espObjects[player] = nil; obj = nil
                end
                if not obj then
                    obj = {}
                    local hl = Instance.new("Highlight")
                    hl.Adornee = char; hl.FillColor = Config.ESP.Color
                    hl.OutlineColor = Color3.new(1,1,1); hl.FillTransparency = 0.5
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = char; obj.highlight = hl
                    local bb = Instance.new("BillboardGui")
                    bb.Adornee = hrp; bb.Size = UDim2.new(0, 120, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
                    bb.Parent = hrp
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1,0,0.5,0); label.BackgroundTransparency = 1
                    label.Text = player.Name; label.TextColor3 = Config.ESP.Color
                    label.TextStrokeTransparency = 0; label.TextStrokeColor3 = Color3.new(0,0,0)
                    label.TextScaled = true; label.Font = Enum.Font.GothamBold
                    label.Parent = bb
                    local hp = Instance.new("TextLabel")
                    hp.Size = UDim2.new(1,0,0.5,0); hp.Position = UDim2.new(0,0,0.5,0)
                    hp.BackgroundTransparency = 1; hp.TextColor3 = Color3.fromRGB(255,80,80)
                    hp.TextStrokeTransparency = 0; hp.TextStrokeColor3 = Color3.new(0,0,0)
                    hp.TextScaled = true; hp.Font = Enum.Font.GothamBold
                    hp.Parent = bb
                    obj.billboard = bb; obj.nameLabel = label; obj.hpLabel = hp
                    espObjects[player] = obj
                end
                local myChar = getSafeCharacter()
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local dist = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
                local txt = player.Name
                if Config.ESP.ShowDistance then txt = txt .. " [" .. math.floor(dist) .. "]" end
                obj.nameLabel.Text = txt
                obj.hpLabel.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            end
        end
    end
    local toRemove = {}
    for p in pairs(espObjects) do
        if not (p and p.Parent and p.Character and p.Character.Parent) then
            table.insert(toRemove, p)
        end
    end
    for _, p in ipairs(toRemove) do
        local obj = espObjects[p]
        if obj then
            if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
            if obj.billboard then pcall(function() obj.billboard:Destroy() end) end
        end
        espObjects[p] = nil
    end
end

-- ═══════════════════════════════════════════════
--  AUTO BLOCK
-- ═══════════════════════════════════════════════
local lastBlockRefresh = 0

triggerBlockDown = function()
    if blockActive then return end
    blockActive = true
    if isMobile then
        if not blockButton or not blockButton.Parent then blockButton = findBlockButton() end
        if blockButton then
            local pos = blockButton.AbsolutePosition + (blockButton.AbsoluteSize / 2)
            safeCall(function() VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0) end)
        else
            safeCall(function() VirtualInput:SendKeyEvent(true, Enum.KeyCode.F, false, game) end)
        end
    else
        safeCall(function() VirtualInput:SendKeyEvent(true, Enum.KeyCode.F, false, game) end)
    end
end

triggerBlockUp = function()
    if not blockActive then return end
    blockActive = false
    if isMobile then
        if blockButton and blockButton.Parent then
            local pos = blockButton.AbsolutePosition + (blockButton.AbsoluteSize / 2)
            safeCall(function() VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end)
        else
            safeCall(function() VirtualInput:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
        end
    else
        safeCall(function() VirtualInput:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
    end
end

local function updateAutoBlock()
    if not Config.AutoBlock.Enabled then
        if blockActive then triggerBlockUp() end
        return
    end
    if isMobile then
        local now = tick()
        if now - lastBlockRefresh > 2 then
            lastBlockRefresh = now
            if not blockButton or not blockButton.Parent then blockButton = findBlockButton() end
        end
    end
    local char = getSafeCharacter(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local danger = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if eRoot then
                local d = (hrp.Position - eRoot.Position).Magnitude
                if d < Config.AutoBlock.Radius then
                    local toMe = (hrp.Position - eRoot.Position)
                    local flatToMe = Vector3.new(toMe.X, 0, toMe.Z)
                    local flatLook = Vector3.new(eRoot.CFrame.LookVector.X, 0, eRoot.CFrame.LookVector.Z)
                    if flatToMe.Magnitude > 0.1 and flatLook.Magnitude > 0.1 then
                        if flatLook.Unit:Dot(flatToMe.Unit) > 0.3 then danger = true; break end
                    end
                end
            end
        end
    end
    if danger and not blockActive then triggerBlockDown()
    elseif not danger and blockActive then triggerBlockUp() end
end

-- ═══════════════════════════════════════════════
--  AUTO PARRY
-- ═══════════════════════════════════════════════
local function updateAutoParry()
    if not Config.AutoParry.Enabled then return end
    local now = tick()
    if now - lastParryTrigger < (Config.AutoParry.ReactionDelay or 0.08) then return end

    local char = getSafeCharacter(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local eHum = p.Character:FindFirstChildOfClass("Humanoid")
            if eRoot and eHum and eHum.Health > 0 then
                local d = (hrp.Position - eRoot.Position).Magnitude
                if d < Config.AutoParry.Radius then
                    local eVel = eRoot.AssemblyLinearVelocity.Magnitude
                    local facing = eRoot.CFrame.LookVector:Dot((hrp.Position - eRoot.Position).Unit)
                    if facing > 0.5 and eVel > 5 then
                        lastParryTrigger = now
                        triggerBlockDown()
                        task.delay(Config.AutoParry.ReactionDelay, function()
                            triggerBlockUp()
                        end)
                        return
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════
--  AUTO COMBO
-- ═══════════════════════════════════════════════
local function updateAutoCombo()
    if not Config.AutoCombo.Enabled then return end
    if tick() - lastAutoCombo < 1.5 then return end
    lastAutoCombo = tick()
    task.spawn(function()
        local char = getSafeCharacter(); if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local enemy = getClosestEnemy(15); if not enemy then return end
        local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart"); if not eRoot then return end
        local goal = CFrame.new(hrp.Position, Vector3.new(eRoot.Position.X, hrp.Position.Y, eRoot.Position.Z))
        for i = 1, 5 do hrp.CFrame = hrp.CFrame:Lerp(goal, 0.4); task.wait(0.02) end
        for i = 1, 3 do clickMouse(); task.wait(0.08) end
        safeCall(function() VirtualInput:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
        task.wait(0.05); clickMouse()
        safeCall(function() VirtualInput:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
        task.wait(0.15)
        safeCall(function() VirtualInput:SendKeyEvent(true, Enum.KeyCode.W, false, game) end)
        safeCall(function() VirtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game) end)
        task.wait(0.1)
        safeCall(function() VirtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game) end)
        safeCall(function() VirtualInput:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
        pressKey(Config.AutoCombo.Key1)
    end)
end

-- ═══════════════════════════════════════════════
--  KILL AURA
-- ═══════════════════════════════════════════════
local function updateKillAura()
    if not Config.KillAura.Enabled then return end
    if tick() - lastKillAura < Config.KillAura.Delay then return end
    lastKillAura = tick()
    local char = getSafeCharacter(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local leg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightFoot") or char:FindFirstChild("RightLowerLeg")
    if not leg then return end
    ensureTouchInterest(leg)
    local enemy = getClosestEnemy(Config.KillAura.Radius); if not enemy then return end
    local eRoot = enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart"); if not eRoot then return end
    ensureTouchInterest(eRoot)
    pcall(function() firetouchinterest(leg, eRoot, 0); firetouchinterest(leg, eRoot, 1) end)
    local head = enemy.Character:FindFirstChild("Head")
    if head then
        ensureTouchInterest(head)
        pcall(function() firetouchinterest(leg, head, 0); firetouchinterest(leg, head, 1) end)
    end
    clickMouse()
end

-- ═══════════════════════════════════════════════
--  AUTO DODGE
-- ═══════════════════════════════════════════════
local function updateAutoDodge()
    if not Config.AutoDodge.Enabled then return end
    if tick() - lastAutoDodge < Config.AutoDodge.Cooldown then return end
    local char = getSafeCharacter(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local enemy = getClosestEnemy(Config.AutoDodge.TriggerDist)
    if not enemy then return end
    local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart"); if not eRoot then return end
    local facing = eRoot.CFrame.LookVector:Dot((hrp.Position - eRoot.Position).Unit)
    local eVel = eRoot.AssemblyLinearVelocity.Magnitude
    if facing > 0.6 and eVel > 3 then
        lastAutoDodge = tick()
        safeCall(function() VirtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game) end)
        task.wait(0.05)
        safeCall(function() VirtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game) end)
    end
end

-- ═══════════════════════════════════════════════
--  AUTO SKILL
-- ═══════════════════════════════════════════════
local skillRotation = 1
local function updateAutoSkill()
    if not Config.AutoSkill.Enabled then return end
    if tick() - lastAutoSkill < 0.4 then return end
    lastAutoSkill = tick()
    local enemy = getClosestEnemy(15)
    if not enemy then return end
    local key
    if skillRotation == 1 then key = Config.AutoSkill.Key1
    elseif skillRotation == 2 then key = Config.AutoSkill.Key2
    elseif skillRotation == 3 then key = Config.AutoSkill.Key3
    else key = Config.AutoSkill.Key4 end
    skillRotation = skillRotation + 1
    if skillRotation > 4 then skillRotation = 1 end
    task.spawn(function() pressKey(key, 0.05) end)
end

-- ═══════════════════════════════════════════════
--  SILENT AIM
-- ═══════════════════════════════════════════════
local function updateSilentAim()
    if not Config.SilentAim.Enabled then return end
    local enemy = getClosestEnemy(Config.SilentAim.FOV / 3)
    if not enemy then return end
    local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart"); if not eRoot then return end
    local cam = workspace.CurrentCamera; if not cam then return end
    local camPos = cam.CFrame.Position
    local toTarget = (eRoot.Position - camPos).Unit
    local dot = cam.CFrame.LookVector:Dot(toTarget)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    if angle < Config.SilentAim.FOV / 2 then
        if math.random() < 0.3 then
            task.spawn(function()
                local delay = humanDelay()
                if delay > 0 then task.wait(delay) end
                clickMouse()
            end)
        end
    end
end

-- ═══════════════════════════════════════════════
--  TELEPORT
-- ═══════════════════════════════════════════════
local function teleportToEnemy()
    local char = getSafeCharacter(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local enemy = getClosestEnemy(200); if not enemy then return end
    local eRoot = enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart"); if not eRoot then return end
    local targetPos = eRoot.Position + Vector3.new(0, 3, 0)
    local steps = 8
    local startPos = hrp.Position
    for i = 1, steps do
        local alpha = i / steps
        local newPos = startPos:Lerp(targetPos, alpha)
        pcall(function() hrp.CFrame = CFrame.new(newPos, eRoot.Position) end)
        task.wait(0.02)
    end
end

-- ═══════════════════════════════════════════════
--  ANTI-STUN
-- ═══════════════════════════════════════════════
local function updateAntiStun()
    if not Config.AntiStun.Enabled then return end
    local char = getSafeCharacter(); if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.PlatformStanding
       or state == Enum.HumanoidStateType.Ragdoll
       or state == Enum.HumanoidStateType.FallingDown then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end

-- ═══════════════════════════════════════════════
--  HITBOX
-- ═══════════════════════════════════════════════
cleanupEnemyHitboxes = function()
    for _, data in pairs(enemyHitboxData) do
        for _, info in ipairs(data.originals) do
            pcall(function() if info.part and info.part.Parent then info.part.Size = info.size end end)
        end
        if data.fakePart then pcall(function() data.fakePart:Destroy() end) end
    end
    enemyHitboxData = {}
end

local function updateHitbox()
    if not Config.Hitbox.Enabled then if next(enemyHitboxData) then cleanupEnemyHitboxes() end return end
    local sizeVec = Vector3.new(Config.Hitbox.SizeX, Config.Hitbox.SizeY, Config.Hitbox.SizeZ)
    local trans = Config.Hitbox.ShowVisual and 0.5 or 1

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if not enemyHitboxData[player] or enemyHitboxData[player].character ~= player.Character then
                    if enemyHitboxData[player] then
                        for _, info in ipairs(enemyHitboxData[player].originals) do
                            pcall(function() if info.part and info.part.Parent then info.part.Size = info.size end end)
                        end
                        if enemyHitboxData[player].fakePart then pcall(function() enemyHitboxData[player].fakePart:Destroy() end) end
                    end
                    enemyHitboxData[player] = { originals = {}, fakePart = nil, character = player.Character }
                    for _, partName in ipairs({ "Torso", "UpperTorso", "LowerTorso", "Head" }) do
                        local part = player.Character:FindFirstChild(partName)
                        if part and part:IsA("BasePart") then
                            table.insert(enemyHitboxData[player].originals, { part = part, size = part.Size })
                        end
                    end
                end
                for _, info in ipairs(enemyHitboxData[player].originals) do
                    if info.part and info.part.Parent then
                        pcall(function() info.part.Size = sizeVec end)
                    end
                end
                if not enemyHitboxData[player].fakePart or not enemyHitboxData[player].fakePart.Parent then
                    local fp = Instance.new("Part")
                    fp.Name = "Hitbox"; fp.Shape = Enum.PartType.Block
                    fp.Size = sizeVec; fp.Transparency = trans
                    fp.Color = Color3.fromRGB(255, 100, 100)
                    fp.CanCollide = false; fp.CanTouch = true; fp.CanQuery = false
                    fp.Massless = true; fp.Anchored = false
                    fp.CFrame = hrp.CFrame; fp.Parent = player.Character
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = hrp; w.Part1 = fp; w.Parent = fp
                    enemyHitboxData[player].fakePart = fp
                end
                if enemyHitboxData[player].fakePart then
                    enemyHitboxData[player].fakePart.Size = sizeVec
                    enemyHitboxData[player].fakePart.Transparency = trans
                end
            end
        end
    end
    local toRemove = {}
    for player in pairs(enemyHitboxData) do
        if not (player.Parent and player.Character and player.Character.Parent) then
            table.insert(toRemove, player)
        end
    end
    for _, player in ipairs(toRemove) do
        local data = enemyHitboxData[player]
        for _, info in ipairs(data.originals) do
            pcall(function() if info.part and info.part.Parent then info.part.Size = info.size end end)
        end
        if data.fakePart then pcall(function() data.fakePart:Destroy() end) end
        enemyHitboxData[player] = nil
    end
end

-- ═══════════════════════════════════════════════
--  M1 REACH
-- ═══════════════════════════════════════════════
local function updateM1Reach()
    if not Config.M1Reach.Enabled then return end
    if tick() - lastM1Reach < 0.1 then return end
    lastM1Reach = tick()
    local char = getSafeCharacter(); if not char then return end
    local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand") or char:FindFirstChild("RightLowerArm")
    if not arm then return end
    ensureTouchInterest(arm)
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local eRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local eHum = player.Character:FindFirstChildOfClass("Humanoid")
            if eRoot and eHum and eHum.Health > 0 then
                local d = (hrp.Position - eRoot.Position).Magnitude
                if d < Config.M1Reach.Range then
                    ensureTouchInterest(eRoot)
                    pcall(function() firetouchinterest(arm, eRoot, 0); firetouchinterest(arm, eRoot, 1) end)
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        ensureTouchInterest(head)
                        pcall(function() firetouchinterest(arm, head, 0); firetouchinterest(arm, head, 1) end)
                    end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════
--  SPEED / JUMP (assigned, não local!)
-- ═══════════════════════════════════════════════
applySpeed = function()
    local char = getSafeCharacter(); if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.WalkSpeed = Config.Speed.Enabled and Config.Speed.WalkSpeed or Config.Speed.BaseSpeed
end
applyJump = function()
    local char = getSafeCharacter(); if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower = Config.JumpPower.Enabled and Config.JumpPower.Value or Config.JumpPower.Base
end

-- ═══════════════════════════════════════════════
--  INFINITE JUMP
-- ═══════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    jumpRequested = true
    lastJumpTime = tick()
end)

local function updateInfiniteJump()
    if not Config.InfiniteJump.Enabled then return end
    local char = getSafeCharacter(); if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local state = hum:GetState()
    local canJump = state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Landed
    if canJump then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)
           or (jumpRequested and tick() - lastJumpTime < 0.15) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            jumpRequested = false
        end
    end
end

-- ═══════════════════════════════════════════════
--  FLY
-- ═══════════════════════════════════════════════
local function destroyFly()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
end
local function updateFly()
    if not Config.Fly.Enabled then destroyFly(); return end
    local char = getSafeCharacter(); if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if not flyBV then
        local bv = Instance.new("BodyVelocity"); bv.Name = "BolsoFly"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5); bv.Velocity = Vector3.zero
        bv.Parent = hrp; flyBV = bv
        local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.P = 1000; bg.D = 50; bg.Parent = hrp; flyBG = bg
    end
    local cam = workspace.CurrentCamera
    local move = Vector3.zero
    if isMobile then move = hum.MoveDirection
    else
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
    flyBV.Velocity = move.Magnitude > 0 and move.Unit * Config.Fly.Speed or Vector3.zero
    flyBG.CFrame = cam.CFrame
end

-- ═══════════════════════════════════════════════
--  NOCLIP
-- ═══════════════════════════════════════════════
local function updateNoclip()
    if not Config.Noclip.Enabled then return end
    local char = getSafeCharacter(); if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end

-- ═══════════════════════════════════════════════
--  AIMBOT
-- ═══════════════════════════════════════════════
local function updateAimbot(dt)
    if not Config.Aimbot or not Config.Aimbot.Enabled then return end
    local enemy = getClosestEnemy(Config.Aimbot.Radius)
    if not enemy or not enemy.Character then return end
    local eRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
    if not eRoot then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local head = enemy.Character:FindFirstChild("Head")
    local targetPos = head and head.Position or eRoot.Position
    local eVel = eRoot.AssemblyLinearVelocity
    local predictTime = Config.Aimbot.PredictTime or 0.15
    local predictedPos = targetPos + eVel * predictTime
    local camPos = cam.CFrame.Position
    local toTarget = (predictedPos - camPos)
    if toTarget.Magnitude < 0.5 then return end
    local goal = CFrame.new(camPos, predictedPos)
    local smooth = Config.Aimbot.Smoothness or 0.15

    if Config.Profile == "Legit" then
        local dot = cam.CFrame.LookVector:Dot(toTarget.Unit)
        local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
        if angle > Config.LegitAimbotFOV.Value then return end
    end

    if smooth <= 0.01 then
        cam.CFrame = goal
    else
        local camLook = cam.CFrame.LookVector
        local dirToTarget = toTarget.Unit
        local dotProd = math.clamp(camLook:Dot(dirToTarget), -1, 1)
        local angularDist = math.acos(dotProd)
        local alpha
        if angularDist > 0.4 then alpha = math.clamp(dt * 25, 0, 1)
        elseif angularDist > 0.15 then alpha = math.clamp(dt * (1 / math.max(smooth * 0.5, 0.02)), 0, 1)
        else alpha = math.clamp(dt * (1 / math.max(smooth, 0.02)), 0, 1) end
        cam.CFrame = cam.CFrame:Lerp(goal, alpha)
    end
end

-- ═══════════════════════════════════════════════
--  BRILHO / FOV / FPS BOOST
-- ═══════════════════════════════════════════════
applyBrightness = function()
    if Config.Brightness.Enabled then
        Lighting.Brightness = Config.Brightness.Value
        Lighting.Ambient = Color3.fromRGB(120,120,120)
        Lighting.OutdoorAmbient = Color3.fromRGB(120,120,120)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
end

applyFOV = function()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = Config.FOV.Value end
end

applyFPSBoost = function()
    if Config.FPSBoost.Enabled then
        if not savedFPS then savedFPS = {} end
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                if not savedFPS[v] then savedFPS[v] = v.Enabled end
                pcall(function() v.Enabled = false end)
            end
        end
    else
        if savedFPS then
            for obj, state in pairs(savedFPS) do
                pcall(function() if obj and obj.Parent then obj.Enabled = state end end)
            end
            savedFPS = nil
        end
    end
end

-- ═══════════════════════════════════════════════
--  ANTI-AFK / SERVER HOP / RESET
-- ═══════════════════════════════════════════════
local function updateAntiAFK()
    if not Config.AntiAFK.Enabled then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if vu then vu:CaptureController(); vu:ClickButton2(Vector2.new()) end
    end)
end

local function serverHop()
    local servers = {}
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(url))
        for _, s in ipairs(data.data or {}) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
    end)
    if #servers > 0 then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1]) end)
    else warn("[战场助手] 没有可切换的服务器") end
end

local function autoReset()
    local char = getSafeCharacter()
    if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = 0 end end
end

-- ═══════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════
local function createUI()
    local parentGui
    local ok = pcall(function() parentGui = game:GetService("CoreGui") end)
    if not ok or not parentGui then parentGui = LocalPlayer:WaitForChild("PlayerGui") end
    local staleGui = parentGui:FindFirstChild("BolsonaroBG")
    if staleGui then staleGui:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BolsonaroBG"; ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = parentGui
    table.insert(UI_Elements, ScreenGui)

    restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 55, 0, 55); restoreBtn.Position = UDim2.new(0, 20, 0, 100)
    restoreBtn.BackgroundColor3 = Color3.fromRGB(20,20,24); restoreBtn.BorderSizePixel = 0
    restoreBtn.Text = "🥊"; restoreBtn.TextSize = 26; restoreBtn.Font = Enum.Font.GothamBold
    restoreBtn.AutoButtonColor = false; restoreBtn.Visible = false; restoreBtn.Active = true
    restoreBtn.Parent = ScreenGui
    local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(1,0); rbc.Parent = restoreBtn
    local rbs = Instance.new("UIStroke"); rbs.Color = Color3.fromRGB(200,50,50); rbs.Thickness = 2; rbs.Parent = restoreBtn
    do
        local drag, ds, sp
        restoreBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag, ds, sp = true, i.Position, restoreBtn.Position
            end
        end)
        restoreBtn.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                restoreBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        restoreBtn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
        end)
    end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 700, 0, 460); Main.Position = savedPos
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local responsiveScale = math.min(1, (viewport.X - 20) / 700, (viewport.Y - 20) / 460)
    local mainScale = Instance.new("UIScale")
    mainScale.Scale = math.max(0.48, responsiveScale)
    mainScale.Parent = Main
    Main.BackgroundColor3 = Color3.fromRGB(12,12,14); Main.BorderSizePixel = 0
    Main.Active = true; Main.Parent = ScreenGui; mainFrame = Main
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,14); mc.Parent = Main
    local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(200,50,50); ms.Thickness = 1; ms.Transparency = 0.3; ms.Parent = Main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,44); header.BackgroundColor3 = Color3.fromRGB(20,20,25)
    header.BorderSizePixel = 0; header.Parent = Main
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0,14); hc.Parent = header

    local ll = Instance.new("TextLabel")
    ll.Size = UDim2.new(0,30,1,0); ll.Position = UDim2.new(0,12,0,0)
    ll.BackgroundTransparency = 1; ll.Text = "🥊"; ll.TextSize = 20
    ll.Font = Enum.Font.GothamBold; ll.Parent = header
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(0,250,1,0); nl.Position = UDim2.new(0,44,0,0)
    nl.BackgroundTransparency = 1; nl.Text = "战场助手"
    nl.TextSize = 15; nl.Font = Enum.Font.GothamBold; nl.TextColor3 = Color3.fromRGB(255,255,255)
    nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = header

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0,120,0,22); badge.Position = UDim2.new(0,255,0,11)
    badge.BackgroundColor3 = Color3.fromRGB(40,40,45); badge.BackgroundTransparency = 0.3
    badge.BorderSizePixel = 0; badge.Parent = header
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = badge
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(1,0,1,0); vl.BackgroundTransparency = 1
    vl.Text = "v3.1 • OP"; vl.TextSize = 11; vl.Font = Enum.Font.GothamBold
    vl.TextColor3 = Color3.fromRGB(220,220,220); vl.Parent = badge
    local profileLabel = vl

    local opBtn = Instance.new("TextButton")
    opBtn.Size = UDim2.new(0, 55, 0, 22); opBtn.Position = UDim2.new(0, 385, 0, 11)
    opBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    opBtn.Text = "OP"; opBtn.TextColor3 = Color3.new(1,1,1)
    opBtn.Font = Enum.Font.GothamBold; opBtn.TextSize = 12
    opBtn.Parent = header
    local obc = Instance.new("UICorner"); obc.CornerRadius = UDim.new(0,6); obc.Parent = opBtn

    local legitBtn = Instance.new("TextButton")
    legitBtn.Size = UDim2.new(0, 55, 0, 22); legitBtn.Position = UDim2.new(0, 445, 0, 11)
    legitBtn.BackgroundColor3 = Color3.fromRGB(40,40,45)
    legitBtn.Text = "拟真"; legitBtn.TextColor3 = Color3.fromRGB(200,200,200)
    legitBtn.Font = Enum.Font.GothamBold; legitBtn.TextSize = 12
    legitBtn.Parent = header
    local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0,6); lbc.Parent = legitBtn

    opBtn.MouseButton1Click:Connect(function()
        applyProfile("OP")
        opBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); opBtn.TextColor3 = Color3.new(1,1,1)
        legitBtn.BackgroundColor3 = Color3.fromRGB(40,40,45); legitBtn.TextColor3 = Color3.fromRGB(200,200,200)
        profileLabel.Text = "v3.1 • OP"
    end)
    legitBtn.MouseButton1Click:Connect(function()
        applyProfile("Legit")
        opBtn.BackgroundColor3 = Color3.fromRGB(40,40,45); opBtn.TextColor3 = Color3.fromRGB(200,200,200)
        legitBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80); legitBtn.TextColor3 = Color3.new(1,1,1)
        profileLabel.Text = "v3.1 • 拟真"
    end)

    local function makeWinBtn(text, xPos, onClick)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,24,0,24); b.Position = UDim2.new(1,xPos,0,10)
        b.BackgroundTransparency = 1; b.Text = text; b.TextSize = 16
        b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.fromRGB(200,200,200)
        b.Parent = header
        if onClick then b.MouseButton1Click:Connect(onClick) end
        return b
    end
    makeWinBtn("−", -80, function() savedPos = Main.Position; Main.Visible = false; restoreBtn.Visible = true end)
    makeWinBtn("⛶", -52, function() end)
    makeWinBtn("×", -26, function() Main.Visible = false; restoreBtn.Visible = false end)
    restoreBtn.MouseButton1Click:Connect(function() Main.Visible = true; Main.Position = savedPos; restoreBtn.Visible = false end)

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0,150,1,-56); sidebar.Position = UDim2.new(0,8,0,48)
    sidebar.BackgroundTransparency = 1; sidebar.BorderSizePixel = 0; sidebar.Parent = Main
    local sl = Instance.new("UIListLayout")
    sl.Padding = UDim.new(0,4); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Parent = sidebar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-170,1,-56); content.Position = UDim2.new(0,162,0,48)
    content.BackgroundTransparency = 1; content.BorderSizePixel = 0; content.Parent = Main

    local pages, navButtons = {}, {}

    local function addNav(name, icon, label, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,34); btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
        btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0; btn.Text = ""
        btn.AutoButtonColor = false; btn.LayoutOrder = order; btn.Parent = sidebar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = btn
        local ic = Instance.new("TextLabel")
        ic.Size = UDim2.new(0,26,1,0); ic.Position = UDim2.new(0,8,0,0)
        ic.BackgroundTransparency = 1; ic.Text = icon; ic.TextSize = 15; ic.Parent = btn
        local lb = Instance.new("TextLabel")
        lb.Name = "Label"; lb.Size = UDim2.new(1,-36,1,0); lb.Position = UDim2.new(0,36,0,0)
        lb.BackgroundTransparency = 1; lb.Text = label; lb.TextSize = 12
        lb.Font = Enum.Font.GothamSemibold; lb.TextColor3 = Color3.fromRGB(180,180,180)
        lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = btn
        navButtons[name] = btn
    end

    local function setPage(name)
        for n, page in pairs(pages) do page.Visible = (n == name) end
        for n, btn in pairs(navButtons) do
            local lb = btn:FindFirstChild("Label")
            if n == name then
                btn.BackgroundColor3 = Color3.fromRGB(200,50,50); btn.BackgroundTransparency = 0.3
                if lb then lb.TextColor3 = Color3.fromRGB(255,255,255) end
            else
                btn.BackgroundColor3 = Color3.fromRGB(0,0,0); btn.BackgroundTransparency = 1
                if lb then lb.TextColor3 = Color3.fromRGB(180,180,180) end
            end
        end
    end

    addNav("玩家","👤","玩家",1)
    addNav("ESP","👁","ESP",2)
    addNav("战斗","⚔️","战斗",3)
    addNav("移动","🏃","移动",4)
    addNav("画面","🎨","画面",5)
    addNav("其他","📋","其他",6)
    for n,btn in pairs(navButtons) do btn.MouseButton1Click:Connect(function() setPage(n) end) end

    local function newPage(name)
        local p = Instance.new("ScrollingFrame")
        p.Name = name.."Page"; p.Size = UDim2.new(1,0,1,0)
        p.BackgroundTransparency = 1; p.BorderSizePixel = 0
        p.ScrollBarThickness = 2; p.ScrollBarImageColor3 = Color3.fromRGB(80,80,90)
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.CanvasSize = UDim2.new(0,0,0,0)
        p.Visible = false; p.Parent = content
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0,6); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = p
        pages[name] = p; return p
    end

    local function makeCard(parent, order)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1,-10,0,56); card.BackgroundColor3 = Color3.fromRGB(25,20,25)
        card.BackgroundTransparency = 0.35; card.BorderSizePixel = 0
        card.LayoutOrder = order; card.Parent = parent
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = card
        return card
    end

    local function makeToggle(parent, order, title, subtitle, cfg, key, onChange)
        local card = makeCard(parent, order)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,-70,0,20); t.Position = UDim2.new(0,12,0,6)
        t.BackgroundTransparency = 1; t.Text = title; t.TextSize = 13
        t.Font = Enum.Font.GothamBold; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = card
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1,-70,0,16); s.Position = UDim2.new(0,12,0,28)
        s.BackgroundTransparency = 1; s.Text = subtitle or ""; s.TextSize = 10
        s.Font = Enum.Font.Gotham; s.TextColor3 = Color3.fromRGB(160,160,170)
        s.TextXAlignment = Enum.TextXAlignment.Left; s.Parent = card
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0,46,0,24); sw.Position = UDim2.new(1,-58,0.5,-12)
        sw.BackgroundColor3 = Color3.fromRGB(210,210,210); sw.BorderSizePixel = 0
        sw.Text = ""; sw.AutoButtonColor = false; sw.Parent = card
        local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1,0); sc.Parent = sw
        local kn = Instance.new("Frame")
        kn.Size = UDim2.new(0,18,0,18); kn.Position = UDim2.new(0,3,0.5,-9)
        kn.BackgroundColor3 = Color3.fromRGB(255,255,255); kn.BorderSizePixel = 0; kn.Parent = sw
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = kn
        local function refresh()
            local on = cfg[key]
            if on then sw.BackgroundColor3 = Color3.fromRGB(200,50,50); kn.Position = UDim2.new(1,-21,0.5,-9)
            else sw.BackgroundColor3 = Color3.fromRGB(200,200,200); kn.Position = UDim2.new(0,3,0.5,-9) end
        end
        sw.MouseButton1Click:Connect(function()
            cfg[key] = not cfg[key]
            if onChange then safeCall(onChange, cfg[key]) end
            refresh()
        end)
        refresh(); table.insert(refreshUIRefs, refresh)
    end

    local function makeSlider(parent, order, title, subtitle, cfg, key, min, max, step, onChange)
        local card = makeCard(parent, order)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0,180,0,20); t.Position = UDim2.new(0,12,0,6)
        t.BackgroundTransparency = 1; t.Text = title; t.TextSize = 13
        t.Font = Enum.Font.GothamBold; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = card
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(0,180,0,16); s.Position = UDim2.new(0,12,0,28)
        s.BackgroundTransparency = 1; s.Text = subtitle or ""; s.TextSize = 10
        s.Font = Enum.Font.Gotham; s.TextColor3 = Color3.fromRGB(160,160,170)
        s.TextXAlignment = Enum.TextXAlignment.Left; s.Parent = card
        local vL = Instance.new("TextLabel")
        vL.Size = UDim2.new(0,40,1,0); vL.Position = UDim2.new(1,-140,0,0)
        vL.BackgroundTransparency = 1; vL.Text = tostring(cfg[key])
        vL.TextSize = 12; vL.Font = Enum.Font.GothamBold
        vL.TextColor3 = Color3.fromRGB(220,220,220); vL.Parent = card
        local tr = Instance.new("Frame")
        tr.Size = UDim2.new(0,90,0,6); tr.Position = UDim2.new(1,-95,0.5,-3)
        tr.BackgroundColor3 = Color3.fromRGB(70,70,80); tr.BorderSizePixel = 0; tr.Parent = card
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = tr
        local fl = Instance.new("Frame")
        local pct = math.clamp((cfg[key]-min)/(max-min), 0, 1)
        fl.Size = UDim2.new(pct,0,1,0); fl.BackgroundColor3 = Color3.fromRGB(200,50,50)
        fl.BorderSizePixel = 0; fl.Parent = tr
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fl
        local kno = Instance.new("Frame")
        kno.Size = UDim2.new(0,14,0,14); kno.Position = UDim2.new(pct,-7,0.5,-7)
        kno.BackgroundColor3 = Color3.fromRGB(255,255,255); kno.BorderSizePixel = 0
        kno.ZIndex = 2; kno.Parent = tr
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = kno
        local function refresh()
            local rel = math.clamp((cfg[key]-min)/(max-min), 0, 1)
            fl.Size = UDim2.new(rel,0,1,0); kno.Position = UDim2.new(rel,-7,0.5,-7)
            vL.Text = tostring(cfg[key])
        end
        table.insert(refreshUIRefs, refresh)
        local dragging = false
        local function upd(inp)
            local rel = math.clamp((inp.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
            local v = math.floor((min + (max-min) * rel) / step + 0.5) * step
            cfg[key] = v; refresh()
            if onChange then safeCall(onChange, v) end
        end
        tr.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; upd(i) end
        end)
        tr.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    local function makeLabel(parent, order, text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,-10,0,22); l.BackgroundTransparency = 1
        l.Text = text; l.TextSize = 10; l.Font = Enum.Font.GothamBold
        l.TextColor3 = Color3.fromRGB(255,120,120)
        l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order; l.Parent = parent
    end

    -- PLAYER
    local pP = newPage("玩家")
    makeLabel(pP, 1, "― 玩家属性")
    makeToggle(pP, 2, "速度增强", "行走速度", Config.Speed, "Enabled", applySpeed)
    makeSlider(pP, 3, "速度", "16-100", Config.Speed, "行走速度", 16, 100, 1, applySpeed)
    makeToggle(pP, 4, "跳跃增强", "跳跃高度", Config.JumpPower, "Enabled", applyJump)
    makeSlider(pP, 5, "跳跃", "50-200", Config.JumpPower, "Value", 50, 200, 5, applyJump)
    makeSlider(pP, 6, "FOV", "40-120", Config.FOV, "Value", 40, 120, 1, applyFOV)
    makeLabel(pP, 7, "― 拟人化")
    makeToggle(pP, 8, "拟人化延迟", "加入随机操作延迟", Config.Humanization, "Enabled")

    -- ESP
    local pE = newPage("ESP")
    makeLabel(pE, 1, "― 玩家透视")
    makeToggle(pE, 2, "开启玩家透视", "显示其他玩家", Config.ESP, "Enabled")
    makeToggle(pE, 3, "Nome", "名称与距离", Config.ESP, "ShowName")
    makeToggle(pE, 4, "生命值", "敌人生命值", Config.ESP, "ShowHealth")
    makeToggle(pE, 5, "距离", "显示距离", Config.ESP, "ShowDistance")

    -- COMBAT
    local pC = newPage("战斗")
    makeLabel(pC, 1, "― 格挡 / 弹反")
    makeToggle(pC, 2, "自动格挡", "敌人接近时格挡", Config.AutoBlock, "Enabled")
    makeSlider(pC, 3, "格挡半径", "5-30", Config.AutoBlock, "Radius", 5, 30, 1)
    makeToggle(pC, 4, "自动弹反", "按攻击时机弹反", Config.AutoParry, "Enabled")
    makeSlider(pC, 5, "弹反半径", "5-25", Config.AutoParry, "Radius", 5, 25, 1)
    makeSlider(pC, 6, "弹反延迟", "0.02-0.3s", Config.AutoParry, "ReactionDelay", 0.02, 0.3, 0.01)
    makeLabel(pC, 7, "― 连招 / 技能")
    makeToggle(pC, 8, "自动连招", "自动执行连招", Config.AutoCombo, "Enabled")
    makeToggle(pC, 9, "自动技能", "循环释放技能", Config.AutoSkill, "Enabled")
    makeToggle(pC, 10, "自动闪避", "受到攻击时冲刺", Config.AutoDodge, "Enabled")
    makeSlider(pC, 11, "闪避半径", "5-30", Config.AutoDodge, "TriggerDist", 5, 30, 1)
    makeLabel(pC, 12, "― 攻击光环 / 距离")
    makeToggle(pC, 13, "攻击光环", "攻击附近目标", Config.KillAura, "Enabled")
    makeSlider(pC, 14, "光环半径", "3-15", Config.KillAura, "Radius", 3, 15, 1)
    makeToggle(pC, 15, "普攻距离", "扩大普通攻击距离", Config.M1Reach, "Enabled")
    makeSlider(pC, 16, "攻击距离", "5-30", Config.M1Reach, "Range", 5, 30, 1)
    makeLabel(pC, 17, "― 碰撞箱")
    makeToggle(pC, 18, "扩大碰撞箱", "扩大敌人碰撞范围", Config.Hitbox, "Enabled")
    makeToggle(pC, 19, "显示碰撞箱", "显示红色范围", Config.Hitbox, "ShowVisual")
    makeSlider(pC, 20, "Hitbox X", "4-20", Config.Hitbox, "SizeX", 4, 20, 1)
    makeSlider(pC, 21, "Hitbox Y", "4-20", Config.Hitbox, "SizeY", 4, 20, 1)
    makeSlider(pC, 22, "Hitbox Z", "4-20", Config.Hitbox, "SizeZ", 4, 20, 1)
    makeLabel(pC, 23, "― 瞄准")
    makeToggle(pC, 24, "自动瞄准", "自动锁定目标", Config.Aimbot, "Enabled")
    makeSlider(pC, 25, "瞄准半径", "20-100", Config.Aimbot, "Radius", 20, 100, 5)
    makeSlider(pC, 26, "瞄准平滑度", "0 表示完全锁定", Config.Aimbot, "Smoothness", 0, 1, 0.05)
    makeSlider(pC, 27, "移动预测", "0.05-0.3s", Config.Aimbot, "PredictTime", 0.05, 0.3, 0.05)
    makeToggle(pC, 28, "静默瞄准", "自动点击目标", Config.SilentAim, "Enabled")
    makeSlider(pC, 29, "静默瞄准视野", "20-180", Config.SilentAim, "FOV", 20, 180, 5)
    makeLabel(pC, 30, "― 战斗辅助")
    makeToggle(pC, 31, "防眩晕", "移除眩晕和布娃娃状态", Config.AntiStun, "Enabled")
    makeToggle(pC, 32, "传送至敌人", "电脑按 T 传送至敌人", Config.TeleportToEnemy, "Enabled")

    -- MOVEMENT
    local pM = newPage("移动")
    makeLabel(pM, 1, "― 移动")
    makeToggle(pM, 2, "无限跳跃", "允许连续跳跃", Config.InfiniteJump, "Enabled")
    makeToggle(pM, 3, "飞行", "开启飞行", Config.Fly, "Enabled")
    makeSlider(pM, 4, "飞行速度", "20-150", Config.Fly, "速度", 20, 150, 5)
    makeToggle(pM, 5, "穿墙", "穿过墙壁", Config.Noclip, "Enabled")

    -- VISUAL
    local pV = newPage("画面")
    makeLabel(pV, 1, "― 画面")
    makeToggle(pV, 2, "高亮画面", "调整环境亮度", Config.Brightness, "Enabled", applyBrightness)
    makeSlider(pV, 3, "数值", "0-4", Config.Brightness, "Value", 0, 4, 0.1, applyBrightness)
    makeToggle(pV, 4, "帧率优化", "关闭高耗性能特效", Config.FPSBoost, "Enabled", applyFPSBoost)

    -- MISC
    local pMi = newPage("其他")
    makeLabel(pMi, 1, "― 其他")
    makeToggle(pMi, 2, "防挂机", "定时发送活动输入", Config.AntiAFK, "Enabled")
    makeToggle(pMi, 3, "调试日志", "在控制台输出日志", Config, "调试日志")

    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1,-10,0,40); hopBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    hopBtn.Text = "🌐 切换服务器"; hopBtn.TextColor3 = Color3.new(1,1,1)
    hopBtn.Font = Enum.Font.GothamBold; hopBtn.TextSize = 13
    hopBtn.LayoutOrder = 4; hopBtn.Parent = pMi
    local hbc = Instance.new("UICorner"); hbc.CornerRadius = UDim.new(0,6); hbc.Parent = hopBtn
    hopBtn.MouseButton1Click:Connect(function() pcall(serverHop) end)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1,-10,0,40); resetBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    resetBtn.Text = "🔄 重置角色"; resetBtn.TextColor3 = Color3.new(1,1,1)
    resetBtn.Font = Enum.Font.GothamBold; resetBtn.TextSize = 13
    resetBtn.LayoutOrder = 5; resetBtn.Parent = pMi
    local rbc2 = Instance.new("UICorner"); rbc2.CornerRadius = UDim.new(0,6); rbc2.Parent = resetBtn
    resetBtn.MouseButton1Click:Connect(function() pcall(autoReset) end)

    setPage("战斗")

    do
        local drag, ds, sp
        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag, ds, sp = true, i.Position, Main.Position
            end
        end)
        header.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        header.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
        end)
    end

    table.insert(Connections, UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            if restoreBtn.Visible then Main.Visible = true; Main.Position = savedPos; restoreBtn.Visible = false
            else Main.Visible = not Main.Visible; if Main.Visible then restoreBtn.Visible = false end end
        elseif i.KeyCode == Enum.KeyCode.K then
            Config.AutoParry.Enabled = not Config.AutoParry.Enabled
            for _, r in ipairs(refreshUIRefs) do pcall(r) end
        elseif i.KeyCode == Enum.KeyCode.J then
            Config.KillAura.Enabled = not Config.KillAura.Enabled
            for _, r in ipairs(refreshUIRefs) do pcall(r) end
        elseif i.KeyCode == Enum.KeyCode.L then
            Config.ESP.Enabled = not Config.ESP.Enabled
            for _, r in ipairs(refreshUIRefs) do pcall(r) end
        elseif i.KeyCode == Config.TeleportToEnemy.Key and Config.TeleportToEnemy.Enabled then
            pcall(teleportToEnemy)
        end
    end))

    _G.BOLSONARO = _G.BOLSONARO or {}
    _G.BOLSONARO.refreshUI = function() for _, r in ipairs(refreshUIRefs) do pcall(r) end end
    _G.BOLSONARO.showUI = function() if mainFrame then mainFrame.Visible = true; if restoreBtn then restoreBtn.Visible = false end end end
    _G.BOLSONARO.profile = applyProfile
end

-- ═══════════════════════════════════════════════
--  LIMPEZA
-- ═══════════════════════════════════════════════
function destroyAll()
    if destroyed then return end
    destroyed = true
    cleanupESP(); applyBrightness(); applyFPSBoost()
    if next(enemyHitboxData) then cleanupEnemyHitboxes() end
    destroyFly()
    if blockActive then triggerBlockUp() end
    local char = getSafeCharacter()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Speed.BaseSpeed; hum.JumpPower = Config.JumpPower.Base end
    end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = Config.FOV.Base end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    Connections = {}
    for _, u in ipairs(UI_Elements) do pcall(function() u:Destroy() end) end
    UI_Elements = {}
    warn("[战场助手] 已关闭。")
end

-- ═══════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════
pcall(createUI)
pcall(applyProfile, "OP")

table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    pcall(updateESP)
    pcall(updateAutoBlock)
    pcall(updateAutoParry)
    pcall(updateAutoCombo)
    pcall(updateAutoSkill)
    pcall(updateAutoDodge)
    pcall(updateKillAura)
    pcall(updateHitbox)
    pcall(updateM1Reach)
    pcall(updateInfiniteJump)
    pcall(updateFly)
    pcall(updateNoclip)
    pcall(updateAntiStun)
    pcall(updateSilentAim)
    pcall(updateAimbot, dt)
    pcall(applySpeed)
    pcall(applyJump)
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    pcall(updateAntiAFK)
end))

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(applySpeed)
    pcall(applyJump)
    pcall(applyFOV)
    if next(espObjects) then cleanupESP() end
    if next(enemyHitboxData) then cleanupEnemyHitboxes() end
    blockActive = false
    blockButton = nil
end))

if isMobile then
    task.spawn(function()
        task.wait(2)
        blockButton = findBlockButton()
        if Config.Debug then
            print("[BOLSONARO] Block button:", blockButton and blockButton:GetFullName() or "未找到")
        end
    end)
end

print("═══════════════════════════════════════════")
print("  🥊 战场助手 v3.1 已加载")
print("  Perfil: OP | RSHIFT=menu")
print("  K=弹反 | J=光环 | L=透视 | T=传送")
print("  设备：", isMobile and "手机" or "电脑")
print("═══════════════════════════════════════════")
