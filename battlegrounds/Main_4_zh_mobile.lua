local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local windowWidth = isMobile and math.clamp(viewport.X - 20, 320, 520) or 560
local windowHeight = isMobile and math.clamp(viewport.Y - 80, 300, 500) or 500

-- =========================================================
-- WINDUI
-- =========================================================

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "小Pond Hub",
    Author = "by pond",
    Icon = "gamepad-2",
    Folder = "PondHub",

    Size = UDim2.fromOffset(windowWidth, windowHeight),
    Transparent = false,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = isMobile and 135 or 180,

    HideSearchBar = false,
    ScrollBarEnabled = true,

    User = {
        Enabled = false,
        Anonymous = true,
    },

    OpenButton = {
        Enabled = true,
        Title = "打开小Pond Hub",
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.7,
    },
})

-- =========================================================
-- TABS
-- =========================================================

local MainTab = Window:Tab({
    Title = "主要功能",
    Icon = "house",
})

local BlockTab = Window:Tab({
    Title = "自动格挡",
    Icon = "shield",
})

local ScriptTab = Window:Tab({
    Title = "扩展脚本",
    Icon = "code-2",
})

local OtherTab = Window:Tab({
    Title = "其他",
    Icon = "settings-2",
})

-- =========================================================
-- VARIABLES
-- =========================================================

local enabled = false
local remoteEnabled = false
local AutoSkill = false
local flyEnabled = false
local freezeAnimEnabled = false
local fakeBugEnabled = false
local showFlyButton = true

local selectedPlayer = nil
local selectedPlayerName = nil

local distance = 5
local flySpeed = 50
local orbitSpeed = 0.5
local mode = "目标后方💦"
local orbitAngle = 0
local predictionEnabled = true
local predictionTime = 0.20
local followVersion = "New"
local followSmoothSpeed = 35
local savedCanCollide = {}
local noCollisionActive = false

local BV = nil
local BG = nil
local FakeBugGyro = nil
local previousPosition = nil

local moveThreshold = 0.05
local tiltActive = false
local tiltTimer = 0
local tiltDuration = 0.5

local animationConnection = nil
local SetFollowPhysics

-- =========================================================
-- AUTO BLOCK + COUNTER
-- =========================================================

local autoBlockEnabled = false
local blockDistance = 10
local blockDuration = 0.35
local isBlocking = false
local autoUnblock = true

local counterEnabled = true
local counterDelay = 0.05
local isCountering = false

-- =========================================================
-- TARGET ANIMATION IDS
-- =========================================================

local targetAnimationIds = {
    ["10469493270"] = true,
    ["10469630950"] = true,
    ["10469639222"] = true,
    ["10503381238"] = true,
    ["10479335397"] = true,
    ["10466974800"] = true,
    ["10468665991"] = true,

    ["13532562418"] = true,
    ["13532600125"] = true,
    ["13532604085"] = true,
    ["13294471966"] = true,

    ["12296882427"] = true,
    ["13380255751"] = true,
    ["13370310513"] = true,
    ["13390230973"] = true,

    ["13378751717"] = true,
    ["13378708199"] = true,
    ["10470104242"] = true,
    ["13379003796"] = true,

    ["13294790250"] = true,
    ["13376962659"] = true,
    ["14004222985"] = true,
    ["13997092940"] = true,

    ["14001963401"] = true,
    ["14136436157"] = true,
    ["14046756619"] = true,
    ["14004235777"] = true,

    ["15259161390"] = true,
    ["15240216931"] = true,
    ["15240176873"] = true,
    ["15162694192"] = true,

    ["15290930205"] = true,
    ["15295895753"] = true,

    ["16515503507"] = true,
    ["16515448089"] = true,
    ["16515520431"] = true,
    ["16552234590"] = true,

    ["16139108718"] = true,
    ["16139402582"] = true,

    ["17799224866"] = true,
    ["17857788598"] = true,
    ["17857880283"] = true,
    ["18179181663"] = true,

    ["77509627104305"] = true,
    ["123005629431309"] = true,
}

-- =========================================================
-- PLAYER LIST
-- =========================================================

local function GetPlayers()
    local t = {}

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= player then
            -- Username (DisplayName)
            table.insert(t, v.Name .. " (" .. v.DisplayName .. ")")
        end
    end

    table.sort(t)
    return t
end

local function GetPlayerFromOption(option)
    if not option then return nil end

    local username = option:match("^([^%(]+)%s*%(") or option
    username = username:gsub("%s+$", "")

    return Players:FindFirstChild(username)
end

-- =========================================================
-- PUNCH
-- =========================================================

local function SetCharacterNoCollision(enabledState)
    local char = player.Character
    if not char then return end

    if enabledState then
        if noCollisionActive then return end
        savedCanCollide = {}
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                savedCanCollide[obj] = obj.CanCollide
                obj.CanCollide = false
            end
        end
        noCollisionActive = true
    else
        if not noCollisionActive then return end
        for part, oldValue in pairs(savedCanCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = oldValue end)
            end
        end
        savedCanCollide = {}
        noCollisionActive = false
    end
end

local function PerformSinglePunchRemote()

    local char = player.Character

    if not char then
        return
    end

    local communicate = char:FindFirstChild("Communicate")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if communicate then

        pcall(function()

            local currentCF =
                hrp and hrp.CFrame or CFrame.new()

            communicate:FireServer({
                Mobile = true,
                Goal = "LeftClick",
                MousePos = currentCF
            })

            task.wait(0.03)

            communicate:FireServer({
                Goal = "LeftClickRelease"
            })

        end)
    end
end

-- =========================================================
-- BLOCK
-- =========================================================

local function TriggerBlockRemote()

    if isBlocking then
        return
    end

    local char = player.Character

    if not char then
        return
    end

    local communicate = char:FindFirstChild("Communicate")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not communicate then
        return
    end

    isBlocking = true

    pcall(function()

        local currentCF =
            hrp and hrp.CFrame or CFrame.new()

        communicate:FireServer({
            Goal = "KeyPress",
            Key = Enum.KeyCode.F,
            MousePos = currentCF
        })

    end)

    task.delay(blockDuration, function()

        if isBlocking and autoUnblock then

            pcall(function()

                communicate:FireServer({
                    Goal = "KeyRelease",
                    Key = Enum.KeyCode.F
                })

            end)

            isBlocking = false

            if counterEnabled and not isCountering then

                isCountering = true

                task.wait(counterDelay)

                PerformSinglePunchRemote()

                task.wait(0.1)

                isCountering = false

            end
        end
    end)
end

-- =========================================================
-- SCRIPT TAB
-- =========================================================

ScriptTab:Paragraph({
    Title = "📜 扩展脚本",
    Description = "点击下方按钮加载并运行脚本",
})

-- =========================================================
-- SUPA V2
-- =========================================================

ScriptTab:Button({
    Title = "Supa V2",
    Desc = "点击运行 Supa V2",
    Icon = "play",

    Callback = function()

        WindUI:Notify({
            Title = "Supa V2",
            Content = "正在加载脚本……",
            Duration = 2,
        })

        task.spawn(function()

            local success, err = pcall(function()

                local source = game:HttpGet(
                    "https://api.getpolsec.com/scripts/hosted/2753546c83053761e44664d36ffe5035d6e20fc8aee1d19f0eb7b933974ae537.lua"
                )

                local func = loadstring(source)

                if not func then
                    error("脚本加载失败")
                end

                func()

            end)

            if success then

                WindUI:Notify({
                    Title = "Supa V2",
                    Content = "Supa V2 运行成功 ✅",
                    Duration = 3,
                })

            else

                warn("[Supa V2 Error]:", err)

                WindUI:Notify({
                    Title = "Supa V2",
                    Content = "运行失败 ❌",
                    Duration = 4,
                })

            end
        end)
    end,
})

-- =========================================================
-- HITBOX
-- =========================================================

ScriptTab:Button({
    Title = "碰撞箱扩展",
    Desc = "点击运行碰撞箱扩展",
    Icon = "box",

    Callback = function()

        WindUI:Notify({
            Title = "碰撞箱扩展",
            Content = "正在加载脚本……",
            Duration = 2,
        })

        task.spawn(function()

            local success, err = pcall(function()

                local source = game:HttpGet(
                    "https://raw.githubusercontent.com/Cyborg883/HitboxExpander/refs/heads/main/Release"
                )

                local func = loadstring(source)

                if not func then
                    error("脚本加载失败")
                end

                func()

            end)

            if success then

                WindUI:Notify({
                    Title = "碰撞箱扩展",
                    Content = "碰撞箱扩展运行成功 ✅",
                    Duration = 3,
                })

            else

                warn("[Hitbox Error]:", err)

                WindUI:Notify({
                    Title = "碰撞箱扩展",
                    Content = "运行失败 ❌",
                    Duration = 4,
                })

            end
        end)
    end,
})

-- =========================================================
-- ดีด
-- =========================================================

ScriptTab:Button({
    Title = "击飞",
    Desc = "点击运行 NeverX",
    Icon = "zap",

    Callback = function()

        WindUI:Notify({
            Title = "击飞",
            Content = "正在加载脚本……",
            Duration = 2,
        })

        task.spawn(function()

            local success, err = pcall(function()

                local source = game:HttpGet(
                    "https://raw.githubusercontent.com/RovlixTinProject/NeverX/refs/heads/main/mfr.lua"
                )

                local func = loadstring(source)

                if not func then
                    error("脚本加载失败")
                end

                func()

            end)

            if success then

                WindUI:Notify({
                    Title = "击飞",
                    Content = "击飞脚本运行成功 ✅",
                    Duration = 3,
                })

            else

                warn("[击飞脚本错误]：", err)

                WindUI:Notify({
                    Title = "击飞",
                    Content = "运行失败 ❌",
                    Duration = 4,
                })

            end
        end)
    end,
})

-- =========================================================
-- อีโมต
-- =========================================================

ScriptTab:Button({
    Title = "动作表情",
    Desc = "点击运行全部动作表情",
    Icon = "smile",

    Callback = function()

        WindUI:Notify({
            Title = "动作表情",
            Content = "正在加载脚本……",
            Duration = 2,
        })

        task.spawn(function()

            local success, err = pcall(function()

                local source = game:HttpGet(
                    "https://raw.githubusercontent.com/thefinalstandofizaan-droid/Script-for-me/main/All%20Emotes"
                )

                local func = loadstring(source)

                if not func then
                    error("脚本加载失败")
                end

                func()

            end)

            if success then

                WindUI:Notify({
                    Title = "动作表情",
                    Content = "动作表情脚本运行成功 ✅",
                    Duration = 3,
                })

            else

                warn("[Emotes Error]:", err)

                WindUI:Notify({
                    Title = "动作表情",
                    Content = "运行失败 ❌",
                    Duration = 4,
                })

            end
        end)
    end,
})

-- =========================================================
-- INF DASH
-- =========================================================

ScriptTab:Button({
    Title = "无限冲刺",
    Desc = "点击运行无限冲刺",
    Icon = "zap",
    Callback = function()
        WindUI:Notify({
            Title = "无限冲刺",
            Content = "正在加载脚本……",
            Duration = 2,
        })
        task.spawn(function()
            local success, err = pcall(function()
                local source = game:HttpGet(
                    "https://raw.githubusercontent.com/truly1ndonly/made-this-script-enjoy-teehee/refs/heads/main/TSB%20Infinite%20Dash"
                )
                local func = loadstring(source)
                if not func then error("脚本加载失败") end
                func()
            end)
            if success then
                WindUI:Notify({
                    Title = "无限冲刺",
                    Content = "无限冲刺运行成功 ✅",
                    Duration = 3,
                })
            else
                warn("[Inf Dash Error]:", err)
                WindUI:Notify({
                    Title = "无限冲刺",
                    Content = "运行失败 ❌",
                    Duration = 4,
                })
            end
        end)
    end,
})

-- =========================================================
-- FLOATING FLY BUTTON
-- =========================================================

local PlayerGui = player:WaitForChild("PlayerGui")
local oldFlyGui = PlayerGui:FindFirstChild("FlyButtonGui")
if oldFlyGui then oldFlyGui:Destroy() end

local FlyButtonGui = Instance.new("ScreenGui")

FlyButtonGui.Name = "FlyButtonGui"
FlyButtonGui.ResetOnSpawn = false
FlyButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FlyButtonGui.Parent = PlayerGui
FlyButtonGui.Enabled = true

local FlyButton = Instance.new("TextButton")

FlyButton.Name = "FlyButton"
FlyButton.Size = UDim2.new(0, 80, 0, 80)
FlyButton.Position = UDim2.new(1, -100, 0.5, -40)
FlyButton.BackgroundColor3 =
    Color3.fromRGB(40, 40, 40)

FlyButton.BorderSizePixel = 0
FlyButton.Text = "✈️"
FlyButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

FlyButton.TextSize = 40
FlyButton.Font = Enum.Font.GothamBold
FlyButton.Parent = FlyButtonGui

local Corner = Instance.new("UICorner")

Corner.CornerRadius = UDim.new(0, 15)
Corner.Parent = FlyButton

local function UpdateButtonColor()

    if flyEnabled then

        FlyButton.BackgroundColor3 =
            Color3.fromRGB(0, 170, 255)

        FlyButton.Text = "✈️ ON"
        FlyButton.TextSize = 24

    else

        FlyButton.BackgroundColor3 =
            Color3.fromRGB(40, 40, 40)

        FlyButton.Text = "✈️"
        FlyButton.TextSize = 40

    end
end

FlyButton.MouseButton1Click:Connect(function()

    flyEnabled = not flyEnabled

    UpdateButtonColor()

    if not flyEnabled then

        if BV then
            BV:Destroy()
            BV = nil
        end

        if BG then
            BG:Destroy()
            BG = nil
        end
    end

    if FlyToggle then

        pcall(function()
            FlyToggle:Set(flyEnabled)
        end)

    end
end)

-- =========================================================
-- DRAG FLY BUTTON
-- =========================================================

local dragging = false
local dragInput
local mousePos
local framePos

FlyButton.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true
        mousePos = input.Position
        framePos = FlyButton.Position

        input.Changed:Connect(function()

            if input.UserInputState ==
                Enum.UserInputState.End then

                dragging = false

            end
        end)
    end
end)

FlyButton.InputChanged:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseMovement
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragInput = input

    end
end)

UserInputService.InputChanged:Connect(function(input)

    if input == dragInput and dragging then

        local delta =
            input.Position - mousePos

        FlyButton.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )

    end
end)

-- =========================================================
-- MAIN TAB
-- =========================================================

local PlayerDropdown = MainTab:Dropdown({

    Title = "选择玩家",
    Desc = "选择要跟随的玩家",

    Values = GetPlayers(),
    Value = nil,
    AllowNone = true,

    Callback = function(option)
        selectedPlayerName = option
        selectedPlayer = GetPlayerFromOption(option)
    end
})

MainTab:Button({

    Title = "刷新玩家",
    Desc = "更新玩家列表",
    Icon = "refresh-cw",

    Callback = function()

        PlayerDropdown:Refresh(
            GetPlayers()
        )

        WindUI:Notify({

            Title = "刷新成功",
            Content = "玩家列表已更新",
            Duration = 3,

        })

    end
})

MainTab:Toggle({
    Title = "目标后方💦",
    Desc = "按照所选版本跟随至目标后方",
    Default = false,
    Callback = function(Value)
        enabled = Value
        if Value then
            SetCharacterNoCollision(true)
        else
            SetCharacterNoCollision(false)

            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                SetFollowPhysics(false, hum)
            end
        end
    end
})
MainTab:Dropdown({
    Title = "跟随版本",
    Desc = "选择新版或旧版跟随系统",
    Values = {"New", "Old"},
    Value = "New",
    Callback = function(option)
        followVersion = option

        -- ป้องกัน AutoRotate ค้างเมื่อสลับเวอร์ชั่น
        if option == "Old" then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            SetFollowPhysics(false, hum)
        end

        WindUI:Notify({
            Title = "后方跟随",
            Content = "当前版本：" .. tostring(option),
            Duration = 2,
        })
    end
})



MainTab:Toggle({
    Title = "🔮 位置预测",
    Desc = "提前 0.20 秒预测目标位置",
    Default = true,
    Callback = function(Value)
        predictionEnabled = Value
        predictionTime = Value and 0.20 or 0
    end
})

MainTab:Toggle({

    Title = "自动攻击",
    Desc = "自动进行普通攻击",

    Default = false,

    Callback = function(Value)

        remoteEnabled = Value

    end
})

MainTab:Toggle({

    Title = "自动技能（仅光头角色）",
    Desc = "自动使用技能",

    Default = false,

    Callback = function(Value)

        AutoSkill = Value

    end
})

FlyToggle = MainTab:Toggle({

    Title = "飞行模式",
    Desc = "电脑按 C 或点击悬浮按钮开关",

    Default = false,

    Callback = function(Value)

        flyEnabled = Value

        UpdateButtonColor()

        if not Value then

            if BV then
                BV:Destroy()
                BV = nil
            end

            if BG then
                BG:Destroy()
                BG = nil
            end

        end
    end
})

MainTab:Toggle({

    Title = "显示飞行悬浮按钮 ✈️",
    Desc = "显示或隐藏飞行按钮",

    Default = true,

    Callback = function(Value)

        showFlyButton = Value
        FlyButtonGui.Enabled = Value

    end
})

MainTab:Toggle({

    Title = "冻结攻击动画",
    Desc = "暂停角色动画",

    Default = false,

    Callback = function(Value)

        freezeAnimEnabled = Value

        local char = player.Character

        if not char then
            return
        end

        local humanoid =
            char:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            return
        end

        if Value then

            if animationConnection then

                animationConnection:Disconnect()
                animationConnection = nil

            end

            animationConnection =
                humanoid.AnimationPlayed:Connect(
                    function(track)

                        pcall(function()

                            track:AdjustSpeed(0)
                            track.TimePosition = 0

                        end)

                    end
                )

            WindUI:Notify({

                Title = "动画冻结已开启",
                Content =
                    "已暂停全部角色动画",
                Duration = 3,

            })

        else

            if animationConnection then

                animationConnection:Disconnect()
                animationConnection = nil

            end

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if animator then

                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do

                    pcall(function()
                        track:AdjustSpeed(1)
                    end)

                end
            end

            WindUI:Notify({

                Title = "动画冻结已关闭",
                Content =
                    "角色动画已恢复",
                Duration = 3,

            })
        end
    end
})

MainTab:Toggle({

    Title = "🌀 假卡顿姿态",
    Desc = "移动时身体向上倾斜 35°",

    Default = false,

    Callback = function(Value)

        fakeBugEnabled = Value

        if not Value then

            if FakeBugGyro then

                FakeBugGyro:Destroy()
                FakeBugGyro = nil

            end

            previousPosition = nil
            tiltActive = false
            tiltTimer = 0

            WindUI:Notify({

                Title = "假卡顿姿态已关闭",
                Content = "角色姿态已恢复",
                Duration = 3,

            })

        else

            WindUI:Notify({

                Title = "假卡顿姿态已开启",
                Content =
                    "移动时角色将向上倾斜 35°",
                Duration = 3,

            })

        end
    end
})

MainTab:Slider({

    Title = "跟随距离",
    Desc = "与目标保持的距离",

    Step = 1,

    Value = {
        Min = 1,
        Max = 20,
        Default = 5
    },

    Callback = function(Value)

        distance = Value

    end
})

MainTab:Slider({

    Title = "飞行速度",
    Desc = "飞行系统移动速度",

    Step = 1,

    Value = {
        Min = 10,
        Max = 200,
        Default = 50
    },

    Callback = function(Value)

        flySpeed = Value

    end
})

MainTab:Dropdown({

    Title = "跟随方位",
    Desc = "选择目标周围的位置",

    Values = {
        "目标后方💦",
        "前方",
        "左侧",
        "右侧",
        "环绕"
    },

    Value = "目标后方💦",

    Callback = function(option)

        mode = option

    end
})

MainTab:Slider({

    Title = "环绕速度",
    Desc = "围绕目标旋转的速度",

    Step = 0.1,

    Value = {
        Min = 0.1,
        Max = 5,
        Default = 0.5
    },

    Callback = function(Value)

        orbitSpeed = Value

    end
})

-- =========================================================
-- AUTO BLOCK TAB
-- =========================================================

BlockTab:Paragraph({

    Title = "🛡️ 自动格挡系统",

    Description =
        "检测对手攻击动画并自动格挡"

})

BlockTab:Toggle({

    Title = "🛡️ 开启自动格挡",

    Desc = "检测对手的攻击动画",

    Default = false,

    Callback = function(Value)

        autoBlockEnabled = Value

        if not Value and isBlocking then

            local char =
                player.Character

            if char and
                char:FindFirstChild(
                    "Communicate"
                ) then

                pcall(function()

                    char.Communicate:FireServer({

                        Goal = "KeyRelease",
                        Key = Enum.KeyCode.F

                    })

                end)
            end

            isBlocking = false

        end
    end
})

BlockTab:Slider({

    Title = "攻击检测距离",

    Desc = "动画检测范围",

    Step = 1,

    Value = {
        Min = 4,
        Max = 20,
        Default = 10
    },

    Callback = function(Value)

        blockDistance = Value

    end
})

BlockTab:Slider({

    Title = "格挡保持时间",

    Desc = "按住格挡的持续时间",

    Step = 0.05,

    Value = {
        Min = 0.1,
        Max = 1.2,
        Default = 0.35
    },

    Callback = function(Value)

        blockDuration = Value

    end
})

BlockTab:Paragraph({

    Title = "⚔️ 自动反击系统",

    Description =
        "松开格挡后自动反击一次"

})

BlockTab:Toggle({

    Title = "⚔️ 开启自动反击",

    Desc = "松开格挡后自动普通攻击",

    Default = true,

    Callback = function(Value)

        counterEnabled = Value

    end
})

BlockTab:Slider({

    Title = "反击延迟",

    Desc = "触发普通攻击前的延迟",

    Step = 0.01,

    Value = {
        Min = 0,
        Max = 0.3,
        Default = 0.05
    },

    Callback = function(Value)

        counterDelay = Value

    end
})

-- =========================================================
-- OTHER TAB
-- =========================================================

OtherTab:Paragraph({

    Title = "ℹ️ 界面信息",

    Description =
        "UI Library: WindUI\n" ..
        "Created by: pond\n" ..
        "WindUI by Footagesus"

})

OtherTab:Button({

    Title = "测试通知",
    Icon = "bell",

    Callback = function()

        WindUI:Notify({

            Title = "小Pond Hub",

            Content =
                "WindUI 运行正常！",

            Duration = 3,

        })

    end
})

-- =========================================================
-- KEYBIND C
-- =========================================================

UserInputService.InputBegan:Connect(
    function(input, gameProcessed)

        if gameProcessed then
            return
        end

        if input.KeyCode ==
            Enum.KeyCode.C then

            flyEnabled = not flyEnabled

            UpdateButtonColor()

            if not flyEnabled then

                if BV then

                    BV:Destroy()
                    BV = nil

                end

                if BG then

                    BG:Destroy()
                    BG = nil

                end
            end

            if FlyToggle then

                pcall(function()

                    FlyToggle:Set(
                        flyEnabled
                    )

                end)

            end
        end
    end
)

-- =========================================================
-- SYSTEM ENGINE
-- =========================================================

RunService.Heartbeat:Connect(function(dt)

    local char = player.Character

    if not char then
        return
    end

    local hrp =
        char:FindFirstChild(
            "HumanoidRootPart"
        )

    local hum =
        char:FindFirstChildOfClass(
            "Humanoid"
        )

    if not hrp or not hum then
        return
    end

    -- FREEZE ANIMATION

    if freezeAnimEnabled then

        local animator =
            hum:FindFirstChildOfClass(
                "Animator"
            )

        if animator then

            for _, track in ipairs(
                animator:GetPlayingAnimationTracks()
            ) do

                pcall(function()

                    track.TimePosition = 0
                    track:AdjustSpeed(0)

                end)

            end
        end
    end

    -- FLY

    if flyEnabled then

        if not BV then

            BV = Instance.new("BodyVelocity")
            BV.Parent = hrp

            BV.MaxForce =
                Vector3.new(
                    9e9,
                    9e9,
                    9e9
                )

        end

        if not BG then

            BG = Instance.new("BodyGyro")
            BG.Parent = hrp

            BG.MaxTorque =
                Vector3.new(
                    9e9,
                    9e9,
                    9e9
                )

            BG.P = 10000
            BG.D = 500

        end

        local cam =
            workspace.CurrentCamera

        local moveDirection =
            Vector3.zero

        if UserInputService:IsKeyDown(
            Enum.KeyCode.W
        ) then

            moveDirection +=
                cam.CFrame.LookVector

        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.S
        ) then

            moveDirection -=
                cam.CFrame.LookVector

        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.A
        ) then

            moveDirection -=
                cam.CFrame.RightVector

        end

        if UserInputService:IsKeyDown(
            Enum.KeyCode.D
        ) then

            moveDirection +=
                cam.CFrame.RightVector

        end

        if UserInputService.TouchEnabled then

            local moveDir =
                hum.MoveDirection

            if moveDir.Magnitude > 0 then

                local camCF =
                    cam.CFrame

                local camLook =
                    camCF.LookVector

                local camRight =
                    camCF.RightVector

                local flatLook =
                    Vector3.new(
                        camLook.X,
                        0,
                        camLook.Z
                    )

                local flatRight =
                    Vector3.new(
                        camRight.X,
                        0,
                        camRight.Z
                    )

                if flatLook.Magnitude > 0 then

                    flatLook =
                        flatLook.Unit

                end

                if flatRight.Magnitude > 0 then

                    flatRight =
                        flatRight.Unit

                end

                local forwardAmount =
                    moveDir:Dot(
                        flatLook
                    )

                local rightAmount =
                    moveDir:Dot(
                        flatRight
                    )

                moveDirection =
                    (
                        camLook *
                        forwardAmount
                    )
                    +
                    (
                        camRight *
                        rightAmount
                    )

            end
        end

        if moveDirection.Magnitude > 0 then

            moveDirection =
                moveDirection.Unit

        end

        BV.Velocity =
            moveDirection * flySpeed

        BG.CFrame =
            CFrame.new(
                hrp.Position,
                hrp.Position +
                    cam.CFrame.LookVector
            )

    else

        if BV then

            BV:Destroy()
            BV = nil

        end

        if BG then

            BG:Destroy()
            BG = nil

        end
    end

    -- FAKE BUG

    if fakeBugEnabled then

        if not FakeBugGyro
            or FakeBugGyro.Parent ~= hrp then

            FakeBugGyro =
                Instance.new("BodyGyro")

            FakeBugGyro.MaxTorque =
                Vector3.new(
                    9e9,
                    9e9,
                    9e9
                )

            FakeBugGyro.P = 10000
            FakeBugGyro.D = 500
            FakeBugGyro.Parent = hrp

            previousPosition =
                hrp.Position

        end

        local currentState =
            hum:GetState()

        local isDown =
            hum.Health <= 0
            or currentState ==
                Enum.HumanoidStateType.Dead
            or currentState ==
                Enum.HumanoidStateType.Ragdoll
            or currentState ==
                Enum.HumanoidStateType.FallingDown
            or currentState ==
                Enum.HumanoidStateType.Physics

        local isGettingUp =
            currentState ==
                Enum.HumanoidStateType.GettingUp

        if isDown then

            FakeBugGyro.MaxTorque =
                Vector3.zero

        elseif isGettingUp then

            FakeBugGyro.MaxTorque =
                Vector3.new(
                    1e5,
                    1e5,
                    1e5
                )

            FakeBugGyro.CFrame =
                CFrame.new(
                    hrp.Position,
                    hrp.Position +
                        hrp.CFrame.LookVector
                )

        else

            FakeBugGyro.MaxTorque =
                Vector3.new(
                    9e9,
                    9e9,
                    9e9
                )

            if previousPosition then

                local distanceMoved =
                    (
                        hrp.Position -
                        previousPosition
                    ).Magnitude

                if distanceMoved >
                    moveThreshold then

                    tiltActive = true
                    tiltTimer = tiltDuration

                else

                    if tiltTimer > 0 then

                        tiltTimer -= dt

                    else

                        tiltActive = false

                    end
                end

                previousPosition =
                    hrp.Position

            else

                previousPosition =
                    hrp.Position

            end

            if tiltActive then

                local lookVector =
                    hrp.CFrame.LookVector

                local tiltCF =
                    CFrame.new(
                        hrp.Position,
                        hrp.Position +
                            lookVector
                    )
                    *
                    CFrame.Angles(
                        math.rad(35),
                        0,
                        0
                    )

                FakeBugGyro.CFrame =
                    tiltCF

            else

                FakeBugGyro.CFrame =
                    CFrame.new(
                        hrp.Position,
                        hrp.Position +
                            hrp.CFrame.LookVector
                    )

            end
        end

    else

        if FakeBugGyro then

            FakeBugGyro:Destroy()
            FakeBugGyro = nil

        end
    end

    -- AUTO BLOCK

    if autoBlockEnabled then

        for _, otherPlayer in ipairs(
            Players:GetPlayers()
        ) do

            if otherPlayer ~= player
                and otherPlayer.Character then

                local targetChar =
                    otherPlayer.Character

                local targetHRP =
                    targetChar:FindFirstChild(
                        "HumanoidRootPart"
                    )

                local targetHum =
                    targetChar:FindFirstChildOfClass(
                        "Humanoid"
                    )

                if targetHRP and targetHum then

                    local dist =
                        (
                            hrp.Position -
                            targetHRP.Position
                        ).Magnitude

                    if dist <= blockDistance then

                        local animator =
                            targetHum:FindFirstChildOfClass(
                                "Animator"
                            )

                        if animator then

                            for _, track in ipairs(
                                animator:GetPlayingAnimationTracks()
                            ) do

                                if track.IsPlaying
                                    and track.Animation then

                                    local animId =
                                        tostring(
                                            track.Animation.AnimationId
                                            or ""
                                        ):match("%d+")

                                    if animId
                                        and targetAnimationIds[animId]
                                        and track.TimePosition < 0.35 then

                                        TriggerBlockRemote()

                                        break

                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================
-- TELEPORT ENGINE (OLD / NEW)
-- =========================================================

local savedAutoRotate = nil
local followWasActive = false

SetFollowPhysics = function(enabledState, humanoid)
    if not humanoid then return end

    if enabledState then
        if not followWasActive then
            savedAutoRotate = humanoid.AutoRotate
            followWasActive = true
        end
        humanoid.AutoRotate = false
    else
        if followWasActive then
            humanoid.AutoRotate =
                savedAutoRotate ~= nil and savedAutoRotate or true
            savedAutoRotate = nil
            followWasActive = false
        end
    end
end

-- =========================================================
-- OLD FOLLOW
-- =========================================================

local function UpdatePositionOld()
    if not enabled or not selectedPlayer then
        return
    end

    local target = selectedPlayer.Character
    local me = player.Character

    if not target or not me then
        return
    end

    local tHRP = target:FindFirstChild("HumanoidRootPart")
    local mHRP = me:FindFirstChild("HumanoidRootPart")

    if not tHRP or not mHRP then
        return
    end

    local predictedTargetPos =
        tHRP.Position + (tHRP.Velocity * predictionTime)

    local predictedCFrame =
        CFrame.new(predictedTargetPos) *
        (tHRP.CFrame - tHRP.Position)

    local finalTargetPos

    if mode == "目标后方💦" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(0, 0, distance)).Position
    elseif mode == "前方" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(0, 0, -distance)).Position
    elseif mode == "左侧" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(-distance, 0, 0)).Position
    elseif mode == "右侧" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(distance, 0, 0)).Position
    elseif mode == "环绕" then
        orbitAngle += orbitSpeed * 0.05

        local x = math.cos(orbitAngle) * distance
        local z = math.sin(orbitAngle) * distance

        finalTargetPos =
            predictedTargetPos + Vector3.new(x, 0, z)
    end

    if finalTargetPos then
        mHRP.CFrame = CFrame.lookAt(
            finalTargetPos,
            predictedTargetPos
        )
    end
end

-- =========================================================
-- NEW FOLLOW
-- =========================================================

local function UpdatePositionNew(deltaTime)
    local me = player.Character
    local mHumanoid = me and me:FindFirstChildOfClass("Humanoid")
    local mHRP = me and me:FindFirstChild("HumanoidRootPart")

    if not enabled or not selectedPlayer then
        SetFollowPhysics(false, mHumanoid)
        return
    end

    if not me then return end

    local target = selectedPlayer.Character
    if not target then return end

    local tHumanoid = target:FindFirstChildOfClass("Humanoid")
    local tHRP = target:FindFirstChild("HumanoidRootPart")

    if not tHumanoid or not mHumanoid or not tHRP or not mHRP then
        return
    end

    if tHumanoid.Health <= 0 or mHumanoid.Health <= 0 then
        return
    end

    SetFollowPhysics(true, mHumanoid)

    local predictionOffset = Vector3.zero
    if predictionEnabled then
        predictionOffset =
            tHRP.AssemblyLinearVelocity * predictionTime
    end

    local predictedTargetPos =
        tHRP.Position + predictionOffset

    local targetRotation =
        tHRP.CFrame - tHRP.Position

    local predictedCFrame =
        CFrame.new(predictedTargetPos) * targetRotation

    local finalTargetPos

    if mode == "目标后方💦" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(0, 0, distance)).Position
    elseif mode == "前方" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(0, 0, -distance)).Position
    elseif mode == "左侧" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(-distance, 0, 0)).Position
    elseif mode == "右侧" then
        finalTargetPos =
            (predictedCFrame * CFrame.new(distance, 0, 0)).Position
    elseif mode == "环绕" then
        orbitAngle += orbitSpeed * deltaTime

        local x = math.cos(orbitAngle) * distance
        local z = math.sin(orbitAngle) * distance

        finalTargetPos =
            predictedTargetPos + Vector3.new(x, 0, z)
    end

    if not finalTargetPos then return end

    local alpha = math.clamp(
        1 - math.exp(-followSmoothSpeed * deltaTime),
        0,
        1
    )

    local smoothPosition =
        mHRP.Position:Lerp(finalTargetPos, alpha)

    local direction =
        predictedTargetPos - smoothPosition

    local rotation

    if direction.Magnitude > 0.01 then
        rotation = CFrame.lookAt(
            smoothPosition,
            predictedTargetPos
        )
    else
        rotation =
            CFrame.new(smoothPosition) *
            (mHRP.CFrame - mHRP.Position)
    end

    mHRP.CFrame = rotation

    mHRP.AssemblyLinearVelocity = Vector3.zero
    mHRP.AssemblyAngularVelocity = Vector3.zero
end

-- =========================================================
-- VERSION SELECTOR
-- =========================================================


-- ใช้ Heartbeat ตัวเดียว แล้วเลือกว่าจะรัน Old หรือ New
RunService.Heartbeat:Connect(function(dt)
    if followVersion == "Old" then
        UpdatePositionOld()
    else
        UpdatePositionNew(dt)
    end
end)


-- PUNCH LOOP
-- =========================================================

task.spawn(function()

    while task.wait(0.1) do

        if remoteEnabled then

            local char =
                player.Character

            local communicate =
                char and
                char:FindFirstChild(
                    "Communicate"
                )

            if communicate then

                pcall(function()

                    communicate:FireServer({

                        Goal = "LeftClick",
                        Mobile = true

                    })

                end)
            end
        end
    end
end)

-- =========================================================
-- AUTO SKILL LOOP
-- =========================================================

task.spawn(function()

    while task.wait(0.5) do

        if AutoSkill then

            local char =
                player.Character

            local hum =
                char and
                char:FindFirstChild(
                    "Humanoid"
                )

            local backpack =
                player:FindFirstChild(
                    "Backpack"
                )

            if char
                and hum
                and hum.Health > 0
                and backpack then

                local communicate =
                    char:FindFirstChild(
                        "Communicate"
                    )

                if communicate then

                    local skills = {

                        "Normal Punch",
                        "Consecutive Punches",
                        "Shove",
                        "Uppercut"

                    }

                    for _, skillName in ipairs(
                        skills
                    ) do

                        if not AutoSkill then
                            break
                        end

                        local skill =
                            backpack:FindFirstChild(
                                skillName
                            )

                        if skill then

                            local args = {{

                                IsAutoActivate = true,
                                Goal = "Console Move",
                                Tool = skill,
                                ToolName = skillName

                            }}

                            pcall(function()

                                communicate:FireServer(
                                    unpack(args)
                                )

                            end)

                            task.wait(0.5)

                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================
-- REAPPLY NO COLLISION AFTER RESPAWN
player.CharacterAdded:Connect(function(char)
    savedCanCollide = {}
    noCollisionActive = false

    if freezeAnimEnabled then
        task.wait(0.5)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if animationConnection then
                animationConnection:Disconnect()
                animationConnection = nil
            end
            animationConnection = humanoid.AnimationPlayed:Connect(function(track)
                pcall(function()
                    track:AdjustSpeed(0)
                    track.TimePosition = 0
                end)
            end)
        end
    end

    if enabled then
        task.wait(0.2)
        SetCharacterNoCollision(true)
    end
end)

-- PLAYER EVENTS
-- =========================================================

Players.PlayerAdded:Connect(function(newPlayer)

    PlayerDropdown:Refresh(
        GetPlayers()
    )

    if selectedPlayer == newPlayer then
        task.wait(0.5)
        selectedPlayer = newPlayer
    end
end)

Players.PlayerRemoving:Connect(function(
    leavingPlayer
)

    PlayerDropdown:Refresh(
        GetPlayers()
    )

    if leavingPlayer ==
        selectedPlayer then

        selectedPlayer = nil
        selectedPlayerName = nil

    end
end)

-- =========================================================
-- START NOTIFY
-- =========================================================

WindUI:Notify({

    Title = "小Pond Hub",

    Content =
        "加载成功！主要功能 → 自动格挡 → 扩展脚本 → 其他",

    Duration = 5,

})
