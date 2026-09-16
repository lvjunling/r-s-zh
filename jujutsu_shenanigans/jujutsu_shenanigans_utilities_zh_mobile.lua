-- Jujutsu Shenanigans 实用工具（中文/手机适配版）

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local state = {
    alive = true,
    moneyFarm = false,
    antiAFK = false,
    stamina = false,
    speed = false,
    esp = false,
}

-- 这些坐标来自原文件，游戏地图更新后可在此处调整。
local TeleportLocations = {
    ["学校"] = Vector3.new(0, 50, 0),
    ["竞技场"] = Vector3.new(100, 50, 100),
    ["训练场"] = Vector3.new(-100, 50, -100),
    ["首领竞技场"] = Vector3.new(200, 50, 200),
}

local function characterParts()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    return character, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.Active = true
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function newPanel(name, titleText, width, height, position)
    local old = PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = PlayerGui

    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    width = math.min(width, math.max(280, viewport.X - 24))
    height = math.min(height, math.max(260, viewport.Y - 70))

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(width, height)
    frame.Position = position or UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 150, 0)
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    title.TextColor3 = Color3.fromRGB(15, 15, 15)
    title.Text = titleText
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

    makeDraggable(frame, title)
    return gui, frame, title
end

local function createButton(parent, text, order, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -12, 0, 40)
    button.LayoutOrder = order
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
    button.TextColor3 = Color3.fromRGB(255, 205, 60)
    button.Text = text
    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Parent = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    button.Activated:Connect(function()
        task.spawn(callback, button)
    end)
    return button
end

local function createTeleportMenu()
    local gui, frame = newPanel("JJS_TeleportGui", "传送菜单（拖动标题栏移动）", 260, 250)
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, 0, 1, -42)
    list.Position = UDim2.fromOffset(0, 40)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 3
    list.Parent = frame
    local layout = Instance.new("UIListLayout", list)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 6)

    local order = 1
    for locationName, position in pairs(TeleportLocations) do
        createButton(list, "📍 " .. locationName, order, function()
            local _, _, root = characterParts()
            if root then root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) end
        end)
        order += 1
    end
    createButton(list, "关闭传送菜单", 100, function() gui:Destroy() end)
end

local function boostStats()
    local _, humanoid = characterParts()
    if humanoid then
        humanoid.MaxHealth *= 1.5
        humanoid.Health = humanoid.MaxHealth
    end
end

local function setSpeed(enabled)
    state.speed = enabled
    local _, humanoid = characterParts()
    if humanoid then humanoid.WalkSpeed = enabled and 24 or 16 end
end

local function clearESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local old = character:FindFirstChild("JJS_PlayerESP")
            if old then old:Destroy() end
        end
    end
end

local function attachESP(player)
    if not state.esp or player == LocalPlayer then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or character:FindFirstChild("JJS_PlayerESP") then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "JJS_PlayerESP"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(160, 34)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    billboard.Parent = character
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    label.BackgroundTransparency = 0.25
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
end

local function setESP(enabled)
    state.esp = enabled
    clearESP()
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do attachESP(player) end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() task.wait(1); attachESP(player) end)
end)

local function collectMoneyItems()
    local _, _, root = characterParts()
    if not root then return end
    for _, item in ipairs(Workspace:GetDescendants()) do
        if not state.moneyFarm then break end
        if item:IsA("BasePart") then
            local name = item.Name:lower()
            if name:find("money", 1, true) or name:find("cash", 1, true) or name:find("coin", 1, true) then
                root.CFrame = item.CFrame + Vector3.new(0, 3, 0)
                if type(firetouchinterest) == "function" then
                    pcall(firetouchinterest, root, item, 0)
                    pcall(firetouchinterest, root, item, 1)
                end
                task.wait(0.25)
            end
        end
    end
end

task.spawn(function()
    while state.alive do
        if state.moneyFarm then pcall(collectMoneyItems) end
        if state.stamina then
            local _, humanoid = characterParts()
            if humanoid then humanoid:SetAttribute("Stamina", 9999) end
        end
        if state.esp then
            for _, player in ipairs(Players:GetPlayers()) do attachESP(player) end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while state.alive do
        if state.antiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
        task.wait(60)
    end
end)

local function createUtilitiesGUI()
    local gui, frame = newPanel("JJS_UtilitiesGui", "咒术乱斗实用工具", 300, 430)
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, 0, 1, -42)
    list.Position = UDim2.fromOffset(0, 40)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 4
    list.Parent = frame
    local layout = Instance.new("UIListLayout", list)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 6)

    createButton(list, "📍 打开传送菜单", 1, createTeleportMenu)
    createButton(list, "⚡ 提升生命值", 2, boostStats)
    createButton(list, "🏃 速度增强：关闭", 3, function(button)
        setSpeed(not state.speed)
        button.Text = "🏃 速度增强：" .. (state.speed and "开启" or "关闭")
    end)
    createButton(list, "♾️ 无限耐力：关闭", 4, function(button)
        state.stamina = not state.stamina
        button.Text = "♾️ 无限耐力：" .. (state.stamina and "开启" or "关闭")
    end)
    createButton(list, "🔄 防挂机：关闭", 5, function(button)
        state.antiAFK = not state.antiAFK
        button.Text = "🔄 防挂机：" .. (state.antiAFK and "开启" or "关闭")
    end)
    createButton(list, "👁️ 玩家透视：关闭", 6, function(button)
        setESP(not state.esp)
        button.Text = "👁️ 玩家透视：" .. (state.esp and "开启" or "关闭")
    end)
    createButton(list, "💰 自动拾取货币：关闭", 7, function(button)
        state.moneyFarm = not state.moneyFarm
        button.Text = "💰 自动拾取货币：" .. (state.moneyFarm and "开启" or "关闭")
    end)
    createButton(list, "❌ 关闭工具", 100, function()
        state.alive = false
        state.moneyFarm, state.stamina, state.antiAFK = false, false, false
        setSpeed(false)
        setESP(false)
        local teleportGui = PlayerGui:FindFirstChild("JJS_TeleportGui")
        if teleportGui then teleportGui:Destroy() end
        gui:Destroy()
    end)
end

createUtilitiesGUI()
print("咒术乱斗实用工具已加载")
