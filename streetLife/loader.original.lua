-- =====================================================================
-- 🩸 RAGE HUB V2 | STREET LIFE REMASTERED (GLOBAL EDITION)
-- Premium Multi-Hack | Developed by Anonymous & AI
-- =====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    Combat = {
        AimbotEnabled = false,
        AimbotKey = Enum.UserInputType.MouseButton2,
        ShowFOV = false,
        FOVRadius = 150,
        Smoothness = 2,
        Prediction = 0.14,
        TargetPart = "Head",
        WallCheck = true
    },
    GunMods = {
        InfAmmo = false,
        FastReload = false,
        ReloadSpeed = 3.0,
        NoRecoil = false
    },
    ESP = {
        Enabled = false,
        Boxes = false,
        Names = false,
        Health = false,
        Distance = false,
        Skeleton = false,
        Tracers = false,
        ColorName = "Blood Red",
        MaxDistance = 1000
    },
    CarMods = {
        CarFly = false,
        CarFlyKey = Enum.KeyCode.F,
        CarSpeed = false,
        CarSpeedAmount = 150
    },
    Player = {
        GodMode = false,
        InfStamina = false,
        Noclip = false
    },
    Misc = {
        ShowFPS = false,
        CustomFOV = false,
        FOVValue = 100
    }
}

local colorMap = {
    ["Blood Red"] = Color3.fromRGB(220, 20, 60),
    ["White"]     = Color3.fromRGB(255, 255, 255),
    ["Purple"]    = Color3.fromRGB(130, 60, 255),
    ["Green"]     = Color3.fromRGB(50, 255, 50),
    ["Blue"]      = Color3.fromRGB(50, 150, 255),
    ["Yellow"]    = Color3.fromRGB(255, 255, 50)
}

local UIName = "RageHub_StreetLife_UI"
local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if ParentGui:FindFirstChild(UIName) then ParentGui[UIName]:Destroy() end
local ScreenGui = Instance.new("ScreenGui", ParentGui)
ScreenGui.Name = UIName
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local Colors = {
    Bg      = Color3.fromRGB(12, 10, 10),
    Sidebar = Color3.fromRGB(18, 12, 12),
    Accent  = Color3.fromRGB(220, 20, 60),
    Card    = Color3.fromRGB(24, 16, 16),
    Text    = Color3.fromRGB(240, 230, 230),
    SubText = Color3.fromRGB(160, 140, 140)
}

local function SendNotification(msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "🩸 Rage Hub",
            Text = msg,
            Duration = 3
        })
    end)
end

local function TeleportCar(pos)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local car = hum.SeatPart.Parent
        if car:IsA("Model") then
            car:PivotTo(CFrame.new(pos + Vector3.new(0, 5, 0)))
        else
            hum.SeatPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        end
    else
        SendNotification("You must be in a vehicle to teleport!")
    end
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false; FOVCircle.Thickness = 1.5; FOVCircle.Filled = false; FOVCircle.Color = Colors.Accent

local FPSLabel = Drawing.new("Text")
FPSLabel.Visible = false; FPSLabel.Color = Colors.Accent; FPSLabel.Size = 16
FPSLabel.Center = false; FPSLabel.Outline = true; FPSLabel.Position = Vector2.new(15, 15); FPSLabel.Font = 2

local function IsVisible(targetPart, cam)
    if not Config.Combat.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, cam}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(cam.CFrame.Position, targetPart.Position - cam.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestToMouse(cam)
    local target, shortestDist = nil, Config.Combat.FOVRadius
    local mousePos = UIS:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local part = char:FindFirstChild(Config.Combat.TargetPart) or char.HumanoidRootPart
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < shortestDist and IsVisible(part, cam) then
                    target = part; shortestDist = dist
                end
            end
        end
    end
    return target
end

local Aiming, isShooting, prevCamPitch = false, false, nil

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Config.Combat.AimbotKey or i.KeyCode == Config.Combat.AimbotKey then Aiming = true end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then isShooting = true; prevCamPitch = nil end
    if i.KeyCode == Config.CarMods.CarFlyKey then
        Config.CarMods.CarFly = not Config.CarMods.CarFly
        SendNotification(Config.CarMods.CarFly and "Car Fly Enabled" or "Car Fly Disabled")
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Config.Combat.AimbotKey or i.KeyCode == Config.Combat.AimbotKey then Aiming = false end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then isShooting = false; prevCamPitch = nil end
end)

-- [[ GOD MODE: Hasar geldiğinde anında max cana çek ]]
local godConn = nil
local function SetupGodMode()
    if godConn then godConn:Disconnect(); godConn = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.Player.GodMode then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        godConn = hum.HealthChanged:Connect(function()
            if Config.Player.GodMode then
                hum.Health = math.huge
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    SetupGodMode()
end)

-- [[ ESP SYSTEM ]]
local ESP_Objects = {}

local function CreateESP(p)
    if p == LocalPlayer or ESP_Objects[p] then return end
    local esp = {
        Box=Drawing.new("Square"), BoxO=Drawing.new("Square"),
        Name=Drawing.new("Text"), Dist=Drawing.new("Text"),
        HpBg=Drawing.new("Square"), Hp=Drawing.new("Square"),
        Tracer=Drawing.new("Line"), Bones={}
    }
    for _, b in pairs({"Head_Spine","Spine_LArm","Spine_RArm","Spine_LLeg","Spine_RLeg"}) do
        local line = Drawing.new("Line"); line.Thickness = 1.5; esp.Bones[b] = line
    end
    esp.Box.Filled=false; esp.Box.Thickness=1
    esp.BoxO.Filled=false; esp.BoxO.Thickness=3; esp.BoxO.Color=Color3.new(0,0,0)
    esp.Name.Center=true; esp.Name.Outline=true; esp.Name.Size=14; esp.Name.Font=2
    esp.Dist.Center=true; esp.Dist.Outline=true; esp.Dist.Size=12; esp.Dist.Color=Colors.SubText; esp.Dist.Font=2
    esp.HpBg.Filled=true; esp.HpBg.Color=Color3.new(0,0,0)
    esp.Hp.Filled=true; esp.Tracer.Thickness=1
    ESP_Objects[p] = esp
end

local function RemoveESP(p)
    if ESP_Objects[p] then
        for k, v in pairs(ESP_Objects[p]) do
            if k == "Bones" then for _, l in pairs(v) do pcall(function() l.Visible=false; l:Remove() end) end
            else pcall(function() v.Visible=false; v:Remove() end) end
        end
        ESP_Objects[p] = nil
    end
end

local function HideESP(e)
    e.Box.Visible=false; e.BoxO.Visible=false; e.Name.Visible=false
    e.Dist.Visible=false; e.HpBg.Visible=false; e.Hp.Visible=false; e.Tracer.Visible=false
    for _, b in pairs(e.Bones) do b.Visible = false end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end

local fpsFrames, fpsTick, currentFPS = 0, tick(), 0

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local mouseLoc = UIS:GetMouseLocation()

    fpsFrames = fpsFrames + 1
    if tick() - fpsTick >= 1 then currentFPS = fpsFrames; fpsFrames = 0; fpsTick = tick() end
    FPSLabel.Visible = Config.Misc.ShowFPS
    FPSLabel.Text = "Rage Hub | FPS: " .. currentFPS

    FOVCircle.Position = mouseLoc; FOVCircle.Radius = Config.Combat.FOVRadius; FOVCircle.Visible = Config.Combat.ShowFOV

    if Config.Combat.AimbotEnabled and Aiming then
        local targetPart = GetClosestToMouse(cam)
        if targetPart then
            local predPos = targetPart.Position
            if Config.Combat.Prediction > 0 and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
                predPos = predPos + (targetPart.Parent.HumanoidRootPart.Velocity * Config.Combat.Prediction)
            end
            local pos, onScreen = cam:WorldToViewportPoint(predPos)
            if onScreen then
                if mousemoverel then
                    mousemoverel((pos.X - mouseLoc.X) / Config.Combat.Smoothness, (pos.Y - mouseLoc.Y) / Config.Combat.Smoothness)
                else
                    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, predPos), 1 / (Config.Combat.Smoothness * 2))
                end
            end
        end
    end

    if Config.GunMods.NoRecoil and isShooting then
        local _, currentPitch, _ = cam.CFrame:ToEulerAnglesYXZ()
        if prevCamPitch ~= nil then
            local delta = currentPitch - prevCamPitch
            if delta < -0.0008 and mousemoverel then
                local comp = math.deg(delta * -1) * (cam.ViewportSize.Y / cam.FieldOfView) * 0.85
                mousemoverel(0, comp)
            end
        end
        prevCamPitch = currentPitch
    elseif not isShooting then
        prevCamPitch = nil
    end

    if Config.Misc.CustomFOV then cam.FieldOfView = Config.Misc.FOVValue end

    local currentEspCol = colorMap[Config.ESP.ColorName] or Colors.Accent
    for p, e in pairs(ESP_Objects) do
        if not Players:FindFirstChild(p.Name) or not Config.ESP.Enabled then HideESP(e) continue end
        local char = p.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then HideESP(e) continue end
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char.HumanoidRootPart
        local dist = (cam.CFrame.Position - torso.Position).Magnitude
        if dist > Config.ESP.MaxDistance then HideESP(e) continue end
        local pos, onScreen = cam:WorldToViewportPoint(torso.Position)
        if not onScreen then HideESP(e) continue end
        local topPos = cam:WorldToViewportPoint(torso.Position + Vector3.new(0, 2.5, 0))
        local botPos  = cam:WorldToViewportPoint(torso.Position - Vector3.new(0, 3.0, 0))
        local h = math.abs(topPos.Y - botPos.Y); if h < 1 then HideESP(e) continue end
        local w = h / 1.5

        if Config.ESP.Boxes then
            e.Box.Size=Vector2.new(w,h); e.Box.Position=Vector2.new(pos.X-w/2,topPos.Y); e.Box.Color=currentEspCol; e.Box.Visible=true
            e.BoxO.Size=Vector2.new(w+2,h+2); e.BoxO.Position=Vector2.new(pos.X-w/2-1,topPos.Y-1); e.BoxO.Visible=true
        else e.Box.Visible=false; e.BoxO.Visible=false end

        if Config.ESP.Health then
            local hpPct = math.clamp(char.Humanoid.Health/char.Humanoid.MaxHealth,0,1)
            e.HpBg.Size=Vector2.new(3,h+2); e.HpBg.Position=Vector2.new(pos.X-w/2-6,topPos.Y-1); e.HpBg.Visible=true
            e.Hp.Size=Vector2.new(1,math.max(h*hpPct,1)); e.Hp.Position=Vector2.new(pos.X-w/2-5,topPos.Y+(h*(1-hpPct))); e.Hp.Color=Color3.fromHSV(hpPct*0.3,1,1); e.Hp.Visible=true
        else e.HpBg.Visible=false; e.Hp.Visible=false end

        if Config.ESP.Names then e.Name.Text=p.Name; e.Name.Position=Vector2.new(pos.X,topPos.Y-18); e.Name.Color=currentEspCol; e.Name.Visible=true else e.Name.Visible=false end
        if Config.ESP.Distance then e.Dist.Text="["..math.floor(dist).."m]"; e.Dist.Position=Vector2.new(pos.X,botPos.Y+2); e.Dist.Visible=true else e.Dist.Visible=false end
        if Config.ESP.Tracers then
            e.Tracer.From=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y); e.Tracer.To=Vector2.new(pos.X,botPos.Y); e.Tracer.Color=currentEspCol; e.Tracer.Visible=true
        else e.Tracer.Visible=false end

        if Config.ESP.Skeleton then
            local function drawBone(key, a, b)
                if a and b then
                    local s1, o1 = cam:WorldToViewportPoint(a.Position)
                    local s2, o2 = cam:WorldToViewportPoint(b.Position)
                    if o1 and o2 then
                        e.Bones[key].From=Vector2.new(s1.X,s1.Y); e.Bones[key].To=Vector2.new(s2.X,s2.Y)
                        e.Bones[key].Color=currentEspCol; e.Bones[key].Visible=true; return
                    end
                end
                e.Bones[key].Visible=false
            end
            local head  = char:FindFirstChild("Head")
            local spine = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            local lArm  = char:FindFirstChild("LeftUpperArm")  or char:FindFirstChild("Left Arm")
            local rArm  = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
            local lLeg  = char:FindFirstChild("LeftUpperLeg")  or char:FindFirstChild("Left Leg")
            local rLeg  = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
            drawBone("Head_Spine",  head,  spine)
            drawBone("Spine_LArm", spine, lArm)
            drawBone("Spine_RArm", spine, rArm)
            drawBone("Spine_LLeg", spine, lLeg)
            drawBone("Spine_RLeg", spine, rLeg)
        else for _, b in pairs(e.Bones) do b.Visible=false end end
    end
end)

-- [[ FPS OPTIMIZED INF STAMINA LOOP ]]
local staminaKeywords = {"stamina","energy","sprint","endurance","run","dash","fatigue"}
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.Player.InfStamina then
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        local n = string.lower(v.Name)
                        for _, kw in pairs(staminaKeywords) do
                            if string.find(n, kw) then
                                v.Value = v.Value < 90 and 100 or v.Value
                                break
                            end
                        end
                    end
                end
                for name, val in pairs(char:GetAttributes()) do
                    local n = string.lower(name)
                    for _, kw in pairs(staminaKeywords) do
                        if string.find(n, kw) and type(val) == "number" then
                            char:SetAttribute(name, math.max(val, 95))
                            break
                        end
                    end
                end
            end
            for _, v in pairs(LocalPlayer:GetDescendants()) do
                if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    local n = string.lower(v.Name)
                    for _, kw in pairs(staminaKeywords) do
                        if string.find(n, kw) then
                            v.Value = v.Value < 90 and 100 or v.Value
                            break
                        end
                    end
                end
            end
        end
    end
end)

RunService.Stepped:Connect(function(_, dt)
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local inCar = hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat")

    -- [[ PLAYER MODS ]]
    if Config.Player.GodMode and hum then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end

    if Config.Player.Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    -- [[ CAR MODS ]]
    if inCar then
        local seat = hum.SeatPart
        local cam  = workspace.CurrentCamera

        if Config.CarMods.CarSpeed and not Config.CarMods.CarFly and seat.AssemblyLinearVelocity.Magnitude > 5 then
            seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + (seat.CFrame.LookVector * (Config.CarMods.CarSpeedAmount * dt))
        end

        if Config.CarMods.CarFly then
            local vel = Vector3.new(0,0,0); local spd = Config.CarMods.CarSpeedAmount
            if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.CFrame.LookVector  * spd end
            if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.CFrame.LookVector  * spd end
            if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.CFrame.RightVector * spd end
            if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.CFrame.RightVector * spd end
            seat.AssemblyLinearVelocity  = vel
            seat.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
    end

    -- [[ GUN MODS ]]
    if Config.GunMods.InfAmmo or Config.GunMods.FastReload then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            if Config.GunMods.InfAmmo then
                for _, v in pairs(tool:GetDescendants()) do
                    if (v:IsA("IntValue") or v:IsA("NumberValue")) then
                        local n = string.lower(v.Name)
                        if string.find(n,"ammo") or string.find(n,"clip") or string.find(n,"mag") then v.Value = 999 end
                    end
                end
                for name, val in pairs(tool:GetAttributes()) do
                    local n = string.lower(name)
                    if type(val)=="number" and (string.find(n,"ammo") or string.find(n,"clip")) then tool:SetAttribute(name, 999) end
                end
            end
            if Config.GunMods.FastReload and hum then
                for _, anim in pairs(hum:GetPlayingAnimationTracks()) do
                    if string.find(string.lower(anim.Name), "reload") then anim:AdjustSpeed(Config.GunMods.ReloadSpeed) end
                end
            end
        end
    end
end)

-- =====================================================================
-- [[ UI ]]
-- =====================================================================
local Main = Instance.new("Frame", ScreenGui)
-- BOYUT GÜNCELLENDİ: Taşmayı önlemek için yükseklik 420'den 500'e çıkarıldı.
Main.Size=UDim2.new(0,650,0,500); Main.Position=UDim2.new(0.5,-325,0.5,-250)
Main.BackgroundColor3=Colors.Bg; Main.BorderSizePixel=0; Main.Active=true
Instance.new("UICorner", Main).CornerRadius=UDim.new(0,8)
local Stroke = Instance.new("UIStroke", Main); Stroke.Color=Colors.Accent; Stroke.Thickness=2; Stroke.Transparency=0.3

local dragging, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+(i.Position.X-dragStart.X),startPos.Y.Scale,startPos.Y.Offset+(i.Position.Y-dragStart.Y)) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
UIS.InputBegan:Connect(function(i,g) if not g and i.KeyCode==Enum.KeyCode.K then Main.Visible=not Main.Visible end end)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size=UDim2.new(0,180,1,0); Sidebar.BackgroundColor3=Colors.Sidebar; Sidebar.BorderSizePixel=0
Instance.new("UICorner", Sidebar).CornerRadius=UDim.new(0,8)

local Title = Instance.new("TextLabel", Sidebar)
Title.Size=UDim2.new(1,0,0,30); Title.Position=UDim2.new(0,15,0,15); Title.BackgroundTransparency=1
Title.Text="Rage Hub"; Title.TextColor3=Colors.Accent; Title.Font=Enum.Font.GothamBlack; Title.TextSize=24; Title.TextXAlignment=Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Sidebar)
SubTitle.Size=UDim2.new(1,0,0,20); SubTitle.Position=UDim2.new(0,15,0,40); SubTitle.BackgroundTransparency=1
SubTitle.Text="we are anonymous"; SubTitle.TextColor3=Colors.SubText; SubTitle.TextTransparency=0.6
SubTitle.Font=Enum.Font.GothamMedium; SubTitle.TextSize=11; SubTitle.TextXAlignment=Enum.TextXAlignment.Left

local TabHold = Instance.new("Frame", Sidebar)
TabHold.Size=UDim2.new(1,0,1,-140); TabHold.Position=UDim2.new(0,0,0,80); TabHold.BackgroundTransparency=1
local tLayout = Instance.new("UIListLayout", TabHold)
tLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; tLayout.Padding=UDim.new(0,8)

local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Size=UDim2.new(1,0,0,50); UserProfile.Position=UDim2.new(0,0,1,-50); UserProfile.BackgroundTransparency=1
local ProfLine = Instance.new("Frame", UserProfile)
ProfLine.Size=UDim2.new(1,-30,0,1); ProfLine.Position=UDim2.new(0,15,0,0); ProfLine.BackgroundColor3=Colors.Card; ProfLine.BorderSizePixel=0
local Avatar = Instance.new("ImageLabel", UserProfile)
Avatar.Size=UDim2.new(0,26,0,26); Avatar.Position=UDim2.new(0,15,0.5,-13); Avatar.BackgroundColor3=Colors.Bg
Avatar.Image="rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150"
Instance.new("UICorner", Avatar).CornerRadius=UDim.new(1,0)
local NameLbl = Instance.new("TextLabel", UserProfile)
NameLbl.Size=UDim2.new(1,-55,1,-1); NameLbl.Position=UDim2.new(0,50,0,1); NameLbl.BackgroundTransparency=1
NameLbl.Text=LocalPlayer.DisplayName or LocalPlayer.Name; NameLbl.TextColor3=Colors.Text
NameLbl.Font=Enum.Font.GothamBold; NameLbl.TextSize=12; NameLbl.TextXAlignment=Enum.TextXAlignment.Left

local Content = Instance.new("Frame", Main)
Content.Size=UDim2.new(1,-190,1,-20); Content.Position=UDim2.new(0,185,0,10); Content.BackgroundTransparency=1

local function SelectTab(b, p)
    for _, x in pairs(Content:GetChildren()) do if x:IsA("ScrollingFrame") then x.Visible=false end end
    for _, x in pairs(TabHold:GetChildren()) do if x:IsA("TextButton") then x.TextColor3=Colors.SubText; x.BackgroundColor3=Colors.Card end end
    p.Visible=true; b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Colors.Accent
end

local function createTab(name)
    local b = Instance.new("TextButton", TabHold)
    b.Size=UDim2.new(0.9,0,0,36); b.BackgroundColor3=Colors.Card; b.Text="  "..name
    b.TextColor3=Colors.SubText; b.Font=Enum.Font.GothamBold; b.TextSize=13; b.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
    local p = Instance.new("ScrollingFrame", Content)
    p.Size=UDim2.new(1,0,1,0); p.Visible=false; p.BackgroundTransparency=1; p.BorderSizePixel=0
    p.ScrollBarThickness=3; p.ScrollBarImageColor3=Colors.Accent
    local layout = Instance.new("UIListLayout", p); layout.Padding=UDim.new(0,8)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() p.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10) end)
    b.MouseButton1Click:Connect(function() SelectTab(b,p) end)
    return p, b
end

local function addToggle(page, text, tbl, key, onChange)
    local r = Instance.new("TextButton", page); r.Size=UDim2.new(1,-10,0,40); r.BackgroundColor3=Colors.Card; r.Text=""
    Instance.new("UICorner", r).CornerRadius=UDim.new(0,6)
    local l = Instance.new("TextLabel", r); l.Size=UDim2.new(0.7,0,1,0); l.Position=UDim2.new(0,15,0,0); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=Colors.Text; l.Font=Enum.Font.GothamMedium; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left
    local tBg = Instance.new("Frame", r); tBg.Size=UDim2.new(0,36,0,18); tBg.Position=UDim2.new(1,-50,0.5,-9); tBg.BackgroundColor3=Color3.fromRGB(40,40,45)
    Instance.new("UICorner", tBg).CornerRadius=UDim.new(1,0)
    local tC = Instance.new("Frame", tBg); tC.Size=UDim2.new(0,14,0,14); tC.Position=UDim2.new(0,2,0,2); tC.BackgroundColor3=Colors.SubText
    Instance.new("UICorner", tC).CornerRadius=UDim.new(1,0)
    local function up()
        local s=tbl[key]
        TweenService:Create(tBg,TweenInfo.new(0.2),{BackgroundColor3=s and Colors.Accent or Color3.fromRGB(40,40,45)}):Play()
        TweenService:Create(tC,TweenInfo.new(0.2),{Position=s and UDim2.new(1,-16,0,2) or UDim2.new(0,2,0,2), BackgroundColor3=s and Color3.new(1,1,1) or Colors.SubText}):Play()
    end
    up()
    r.MouseButton1Click:Connect(function()
        tbl[key]=not tbl[key]; up()
        if onChange then onChange(tbl[key]) end
    end)
end

local function addSlider(page, text, tbl, key, min, max, isFloat)
    local r = Instance.new("Frame", page); r.Size=UDim2.new(1,-10,0,50); r.BackgroundColor3=Colors.Card
    Instance.new("UICorner", r).CornerRadius=UDim.new(0,6)
    local l = Instance.new("TextLabel", r); l.Size=UDim2.new(0.5,0,0,20); l.Position=UDim2.new(0,15,0,5); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=Colors.Text; l.Font=Enum.Font.GothamMedium; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left
    local vL = Instance.new("TextLabel", r); vL.Size=UDim2.new(0.5,-30,0,20); vL.Position=UDim2.new(0.5,0,0,5); vL.BackgroundTransparency=1
    vL.Text=tostring(tbl[key]); vL.TextColor3=Colors.Accent; vL.Font=Enum.Font.GothamBold; vL.TextSize=13; vL.TextXAlignment=Enum.TextXAlignment.Right
    local sBg = Instance.new("Frame", r); sBg.Size=UDim2.new(1,-30,0,6); sBg.Position=UDim2.new(0,15,0,32); sBg.BackgroundColor3=Colors.Bg
    Instance.new("UICorner", sBg).CornerRadius=UDim.new(1,0)
    local fill = Instance.new("Frame", sBg); fill.Size=UDim2.new(math.clamp((tbl[key]-min)/(max-min),0,1),0,1,0); fill.BackgroundColor3=Colors.Accent
    Instance.new("UICorner", fill).CornerRadius=UDim.new(1,0)
    local btn = Instance.new("TextButton", sBg); btn.Size=UDim2.new(1,0,1,10); btn.Position=UDim2.new(0,0,0,-5); btn.BackgroundTransparency=1; btn.Text=""
    local ds=false
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end end)
    UIS.InputChanged:Connect(function(i)
        if ds and i.UserInputType==Enum.UserInputType.MouseMovement then
            local pct=math.clamp((i.Position.X-sBg.AbsolutePosition.X)/sBg.AbsoluteSize.X,0,1)
            fill.Size=UDim2.new(pct,0,1,0)
            local val=min+((max-min)*pct)
            if not isFloat then val=math.floor(val) else val=math.floor(val*100)/100 end
            vL.Text=tostring(val); tbl[key]=val
        end
    end)
end

local function addCycle(page, text, list, tbl, key)
    local r = Instance.new("TextButton", page); r.Size=UDim2.new(1,-10,0,40); r.BackgroundColor3=Colors.Card; r.Text=""
    Instance.new("UICorner", r).CornerRadius=UDim.new(0,6)
    local l = Instance.new("TextLabel", r); l.Size=UDim2.new(0.5,0,1,0); l.Position=UDim2.new(0,15,0,0); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=Colors.Text; l.Font=Enum.Font.GothamMedium; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left
    local v = Instance.new("TextLabel", r); v.Size=UDim2.new(0.5,-15,1,0); v.Position=UDim2.new(0.5,0,0,0); v.BackgroundTransparency=1
    v.Text="[ "..tostring(tbl[key]).." ]"; v.TextColor3=Colors.Accent; v.Font=Enum.Font.GothamBold; v.TextSize=12; v.TextXAlignment=Enum.TextXAlignment.Right
    local idx=1; for i,val in ipairs(list) do if val==tbl[key] then idx=i break end end
    r.MouseButton1Click:Connect(function() idx=(idx%#list)+1; tbl[key]=list[idx]; v.Text="[ "..tostring(list[idx]).." ]" end)
end

local function addKeybind(page, text, tbl, key, cb)
    local r = Instance.new("Frame", page); r.Size=UDim2.new(1,-10,0,40); r.BackgroundColor3=Colors.Card
    Instance.new("UICorner", r).CornerRadius=UDim.new(0,6)
    local l = Instance.new("TextLabel", r); l.Size=UDim2.new(0.5,0,1,0); l.Position=UDim2.new(0,15,0,0); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=Colors.Text; l.Font=Enum.Font.GothamMedium; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", r); btn.Size=UDim2.new(0,100,0,24); btn.Position=UDim2.new(1,-115,0.5,-12)
    btn.BackgroundColor3=Color3.fromRGB(40,40,45); btn.TextColor3=Colors.Text; btn.Font=Enum.Font.GothamBold; btn.TextSize=12; btn.Text=tbl[key].Name
    Instance.new("UICorner", btn).CornerRadius=UDim.new(0,4)
    local listening=false; btn.MouseButton1Click:Connect(function() listening=true; btn.Text="..." end)
    UIS.InputBegan:Connect(function(i)
        if listening then
            if i.UserInputType==Enum.UserInputType.Keyboard then tbl[key]=i.KeyCode; btn.Text=i.KeyCode.Name; listening=false; if cb then cb() end
            elseif i.UserInputType==Enum.UserInputType.MouseButton2 or i.UserInputType==Enum.UserInputType.MouseButton3 then tbl[key]=i.UserInputType; btn.Text=i.UserInputType.Name; listening=false; if cb then cb() end end
        end
    end)
end

local function addButton(page, text, callback)
    local r = Instance.new("TextButton", page); r.Size=UDim2.new(1,-10,0,40); r.BackgroundColor3=Colors.Card; r.Text=""
    Instance.new("UICorner", r).CornerRadius=UDim.new(0,6)
    local l = Instance.new("TextLabel", r); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=Colors.Text; l.Font=Enum.Font.GothamBold; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Center
    r.MouseButton1Click:Connect(function()
        TweenService:Create(r,TweenInfo.new(0.1),{BackgroundColor3=Colors.Accent}):Play()
        task.wait(0.1)
        TweenService:Create(r,TweenInfo.new(0.1),{BackgroundColor3=Colors.Card}):Play()
        if callback then callback() end
    end)
end

-- =====================================================================
-- [[ TABS ]]
-- =====================================================================
local pHome, bHome = createTab("Home")
local pAim,  bAim  = createTab("Combat")
local pGun,  bGun  = createTab("Gun Mods")
local pEsp,  bEsp  = createTab("Visuals")
local pCar,  bCar  = createTab("Car Mods")
local pPlay, bPlay = createTab("Player")
local pTp,   bTp   = createTab("Teleports")
local pMis,  bMis  = createTab("Misc")

-- HOME
do
    local card = Instance.new("Frame", pHome)
    card.Size=UDim2.new(1,-10,0,130); card.BackgroundColor3=Colors.Card
    Instance.new("UICorner", card).CornerRadius=UDim.new(0,6)
    local bar = Instance.new("Frame", card); bar.Size=UDim2.new(0,3,1,-16); bar.Position=UDim2.new(0,0,0,8); bar.BackgroundColor3=Colors.Accent; bar.BorderSizePixel=0
    Instance.new("UICorner", bar).CornerRadius=UDim.new(1,0)
    local function row(y, txt, col)
        local t = Instance.new("TextLabel", card); t.Size=UDim2.new(1,-20,0,18); t.Position=UDim2.new(0,14,0,y); t.BackgroundTransparency=1
        t.Text=txt; t.TextColor3=col or Colors.Text; t.Font=Enum.Font.GothamBold; t.TextSize=12; t.TextXAlignment=Enum.TextXAlignment.Left
    end
    row(8,  "Rage Hub  —  Street Life Edition", Colors.Accent)
    row(30, "[K]  →  Show / Hide Menu")
    row(50, "[F]  →  Toggle Car Fly  (changeable in Car Mods tab)")
    row(70, "Teleports: you must be seated in a car!")
    row(90, "No Fall Damage, Noclip & Inf Stamina are in the Player tab")
    row(110,"Use at your own risk  •  we are anonymous", Color3.fromRGB(140,50,70))
end

-- COMBAT
addToggle(pAim, "Enable Aimbot", Config.Combat, "AimbotEnabled")
addKeybind(pAim, "Aimbot Keybind", Config.Combat, "AimbotKey")
addSlider(pAim, "Smoothness  (1 = Instant)", Config.Combat, "Smoothness", 1, 10, false)
addSlider(pAim, "Prediction", Config.Combat, "Prediction", 0, 0.5, true)
addToggle(pAim, "Show FOV Circle", Config.Combat, "ShowFOV")
addSlider(pAim, "FOV Radius", Config.Combat, "FOVRadius", 10, 500, false)
addCycle(pAim, "Target Part", {"Head","Torso","HumanoidRootPart"}, Config.Combat, "TargetPart")
addToggle(pAim, "Wall Check", Config.Combat, "WallCheck")

-- GUN MODS
addToggle(pGun, "Infinite Ammo", Config.GunMods, "InfAmmo")
addToggle(pGun, "Fast Reload", Config.GunMods, "FastReload")
addSlider(pGun, "Reload Speed Multiplier", Config.GunMods, "ReloadSpeed", 1, 10, true)
addToggle(pGun, "No Recoil", Config.GunMods, "NoRecoil")

-- VISUALS
addToggle(pEsp, "Enable ESP", Config.ESP, "Enabled")
addSlider(pEsp, "Max Distance", Config.ESP, "MaxDistance", 100, 2000, false)
addCycle(pEsp, "ESP Color", {"Blood Red","White","Purple","Green","Blue","Yellow"}, Config.ESP, "ColorName")
addToggle(pEsp, "Box ESP", Config.ESP, "Boxes")
addToggle(pEsp, "Skeleton ESP", Config.ESP, "Skeleton")
addToggle(pEsp, "Name ESP", Config.ESP, "Names")
addToggle(pEsp, "Health Bar", Config.ESP, "Health")
addToggle(pEsp, "Distance ESP", Config.ESP, "Distance")
addToggle(pEsp, "Tracers", Config.ESP, "Tracers")

-- CAR MODS
addToggle(pCar, "Car Fly  (WASD + Camera Dir)", Config.CarMods, "CarFly")
addKeybind(pCar, "Car Fly Keybind", Config.CarMods, "CarFlyKey")
addSlider(pCar, "Fly / Boost Speed", Config.CarMods, "CarSpeedAmount", 50, 500, false)
addToggle(pCar, "Ground Speed Boost", Config.CarMods, "CarSpeed")

-- PLAYER
addToggle(pPlay, "No Fall Damage", Config.Player, "GodMode", function(val)
    if val then
        SetupGodMode()
        SendNotification("No Fall Damage Enabled ")
    else
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.MaxHealth = 100; hum.Health = 100 end
        end
        if godConn then godConn:Disconnect(); godConn = nil end
        SendNotification("No Fall Damage Disabled")
    end
end)
addToggle(pPlay, "Noclip (Walk Through Walls)", Config.Player, "Noclip")
addToggle(pPlay, "Infinite Stamina", Config.Player, "InfStamina")

-- TELEPORTS
local locations = {
    {Name="→  Jewelry",    Pos=Vector3.new(1,    52,  -186)},
    {Name="→  Yacht",      Pos=Vector3.new(927,  81,  -1824)},
    {Name="→  Bank",       Pos=Vector3.new(395,  52,  59)},
    {Name="→  Museum",     Pos=Vector3.new(1322, 52,  -117)},
    {Name="→  Mansion",    Pos=Vector3.new(1367, 55,  221)},
    {Name="→  Gas Station",Pos=Vector3.new(309,  52,  179)},
    {Name="→  Gunstore 1", Pos=Vector3.new(604,  52,  -368)},
    {Name="→  Gunstore 2", Pos=Vector3.new(35,   70,  551)},
    {Name="→  Dealer",     Pos=Vector3.new(242,  52,  309)},
    {Name="→  Gun Buyer",  Pos=Vector3.new(1002, 52,  -106)}
}
for _, loc in pairs(locations) do
    addButton(pTp, loc.Name, function() TeleportCar(loc.Pos) end)
end

-- MISC
addToggle(pMis, "Custom FOV", Config.Misc, "CustomFOV")
addSlider(pMis, "FOV Value", Config.Misc, "FOVValue", 70, 120, false)
addToggle(pMis, "Show FPS Counter", Config.Misc, "ShowFPS")
addButton(pMis, "Server Hop", function()
    local placeId, jobId = game.PlaceId, game.JobId
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"))
        if servers and servers.data then
            for _, srv in pairs(servers.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= jobId then
                    TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer); break
                end
            end
        end
    end)
end)

SelectTab(bHome, pHome)
