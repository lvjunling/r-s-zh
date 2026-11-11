-- =======================================================
-- 👑 MRGHOST HUB V4 · 中文矿石透视与自动挖矿 / PC、移动端
-- =======================================================
local DISCORD_LINK = "https://discord.gg/xSECFRv9s"

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function CreateScreenGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = PlayerGui end
    return gui
end

-- [[ NOTIFICATION ]]
local function SendCyberNotify(titleText, descText, duration, isSuccess)
    task.spawn(function()
        local NotifyGui
        for _, parent in ipairs({CoreGui, PlayerGui}) do
            local ok, found = pcall(function() return parent:FindFirstChild("MrGhostNotifyGui") end)
            if ok and found then NotifyGui = found; break end
        end
        if not NotifyGui then NotifyGui = CreateScreenGui("MrGhostNotifyGui") end
        NotifyGui.DisplayOrder = 50

        local Card = Instance.new("Frame", NotifyGui)
        Card.Size = UDim2.new(1, -24, 0, 75)
        Card.AnchorPoint = Vector2.new(1, 1)
        Card.Position = UDim2.new(1, 320, 1, -12)
        local limit = Instance.new("UISizeConstraint", Card)
        limit.MaxSize = Vector2.new(310, 75)
        Card.BackgroundColor3 = Color3.fromRGB(14, 16, 30)
        Card.ClipsDescendants = true
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 16)
        local Stroke = Instance.new("UIStroke", Card)
        Stroke.Thickness = 2
        Stroke.Color = isSuccess and Color3.fromRGB(192, 132, 252) or Color3.fromRGB(248, 113, 113)

        local Icon = Instance.new("TextLabel", Card)
        Icon.Size = UDim2.new(0, 52, 1, 0); Icon.BackgroundTransparency = 1
        Icon.Text = isSuccess and "👻✨" or "💥⚠️"; Icon.TextSize = 24

        local Title = Instance.new("TextLabel", Card)
        Title.Position = UDim2.new(0, 52, 0, 10); Title.Size = UDim2.new(1, -56, 0, 20); Title.BackgroundTransparency = 1
        Title.Text = titleText; Title.TextColor3 = isSuccess and Color3.fromRGB(233, 213, 255) or Color3.fromRGB(254, 202, 202)
        Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left

        local Desc = Instance.new("TextLabel", Card)
        Desc.Position = UDim2.new(0, 52, 0, 32); Desc.Size = UDim2.new(1, -56, 0, 34); Desc.BackgroundTransparency = 1
        Desc.Text = descText; Desc.TextColor3 = Color3.fromRGB(180, 190, 220); Desc.Font = Enum.Font.Gotham; Desc.TextSize = 12; Desc.TextWrapped = true; Desc.TextXAlignment = Enum.TextXAlignment.Left

        TweenService:Create(Card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -12, 1, -12)}):Play()
        task.wait(duration or 3)
        local slideOut = TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 320, 1, -12)})
        slideOut:Play()
        slideOut.Completed:Connect(function() Card:Destroy() end)
    end)
end

-- [[ MAIN HUB ]]
local function LoadMainScript()
    SendCyberNotify("MRGHOST HUB V4 👻", "中文矿石透视与自动挖矿界面已就绪。", 3.5, true)

    for _, parent in ipairs({CoreGui, PlayerGui}) do
        pcall(function()
            local previous = parent:FindFirstChild("MrGhost_Template_VIP")
            if previous then previous:Destroy() end
        end)
    end

    local Settings = {
        AutoMine = false,
        AutoTPToOre = false,
        AutoSell = false,
        OreESP = false,
        InfJump = false,
        MineRange = 60,
        WalkSpeed = 40,
        AutoSellCount = 8
    }
    local ActiveESP = {}
    local maximized = false
    local normalPosition

    local connections = {}
    local fitUI = function() end
    local function track(connection)
        connections[#connections + 1] = connection
    end
    local function makeDraggable(handle, target, onTap)
        local pointer, dragStart, startPos
        local distance = 0
        handle.InputBegan:Connect(function(input)
            if pointer then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            pointer, dragStart, startPos = input, input.Position, target.Position
            distance = 0
        end)
        track(UserInputService.InputChanged:Connect(function(input)
            if not pointer then return end
            if pointer.UserInputType == Enum.UserInputType.Touch then
                if input ~= pointer then return end
            elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local delta = input.Position - dragStart
            distance = math.max(distance, math.abs(delta.X) + math.abs(delta.Y))
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            fitUI(false)
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input ~= pointer then return end
            local delta = input.Position - dragStart
            distance = math.max(distance, math.abs(delta.X) + math.abs(delta.Y))
            pointer = nil
            if onTap and distance < 8 and input.UserInputState == Enum.UserInputState.End then onTap() end
        end))
        track(UserInputService.WindowFocusReleased:Connect(function() pointer = nil end))
    end

    local ScreenGui = CreateScreenGui("MrGhost_Template_VIP")
    local SafeArea = Instance.new("Frame", ScreenGui)
    SafeArea.Name = "SafeArea"
    SafeArea.Size = UDim2.fromScale(1, 1)
    SafeArea.BackgroundTransparency = 1
    ScreenGui.Destroying:Connect(function()
        for name, value in pairs(Settings) do
            if type(value) == "boolean" then Settings[name] = false end
        end
        for _, connection in ipairs(connections) do connection:Disconnect() end
        for _, tag in pairs(ActiveESP) do pcall(function() tag:Destroy() end) end
        table.clear(ActiveESP)
    end)

    local ToggleButton = Instance.new("TextButton", SafeArea)
    ToggleButton.Position = UDim2.new(0.04, 0, 0.28, 0); ToggleButton.Size = UDim2.new(0, 56, 0, 56)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(15, 18, 32); ToggleButton.Text = "👻"; ToggleButton.TextSize = 26; ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)
    local ToggleStroke = Instance.new("UIStroke", ToggleButton)
    ToggleStroke.Thickness = 2; ToggleStroke.Color = Color3.fromRGB(192, 132, 252)

    local MainFrame = Instance.new("Frame", SafeArea)
    MainFrame.Name = "MainWindow"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5); MainFrame.Size = UDim2.new(0, 440, 0, 470)
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 26); MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)
    local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = Color3.fromRGB(192, 132, 252); MainStroke.Thickness = 2

    local Header = Instance.new("Frame", MainFrame); Header.Size = UDim2.new(1, 0, 0, 60); Header.BackgroundTransparency = 1
    Header.Name = "WindowHeader"
    Header.Active = true
    local DragHeader = Instance.new("Frame", Header)
    DragHeader.Name = "DragHeader"
    DragHeader.Size = UDim2.new(1, -112, 1, 0)
    DragHeader.BackgroundTransparency = 1
    DragHeader.Active = true
    DragHeader.ZIndex = 2
    makeDraggable(DragHeader, MainFrame)
    local Title = Instance.new("TextLabel", Header); Title.Position = UDim2.new(0, 18, 0, 12); Title.Size = UDim2.new(1, -136, 0, 22)
    Title.BackgroundTransparency = 1; Title.Text = "MRGHOST HUB V4 · 中文版 👻"; Title.TextColor3 = Color3.fromRGB(245, 245, 255); Title.Font = Enum.Font.GothamBold; Title.TextSize = 18; Title.TextTruncate = Enum.TextTruncate.AtEnd; Title.TextXAlignment = Enum.TextXAlignment.Left

    local SubTitle = Instance.new("TextLabel", Header); SubTitle.Position = UDim2.new(0, 18, 0, 34); SubTitle.Size = UDim2.new(1, -136, 0, 16)
    SubTitle.BackgroundTransparency = 1; SubTitle.Text = "中文矿石透视 · 自动挖矿与出售"
    SubTitle.TextColor3 = Color3.fromRGB(160, 150, 200); SubTitle.Font = Enum.Font.Gotham; SubTitle.TextSize = 11; SubTitle.TextTruncate = Enum.TextTruncate.AtEnd; SubTitle.TextXAlignment = Enum.TextXAlignment.Left

    local function CreateHeaderButton(text, offset)
        local btn = Instance.new("TextButton", Header)
        btn.Size = UDim2.fromOffset(44, 44)
        btn.Position = UDim2.new(1, offset, 0, 8)
        btn.BackgroundColor3 = Color3.fromRGB(20, 24, 42)
        btn.Text = text; btn.TextColor3 = Color3.fromRGB(233, 213, 255)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        return btn
    end
    local MaximizeButton = CreateHeaderButton("放大", -104)
    local MinimizeButton = CreateHeaderButton("收起", -52)

    local ContentContainer = Instance.new("ScrollingFrame", MainFrame)
    ContentContainer.Position = UDim2.new(0, 16, 0, 65); ContentContainer.Size = UDim2.new(1, -32, 1, -110)
    ContentContainer.BackgroundTransparency = 1; ContentContainer.ScrollBarThickness = 4; ContentContainer.ScrollBarImageColor3 = Color3.fromRGB(192, 132, 252)
    ContentContainer.Active = true
    ContentContainer.CanvasSize = UDim2.fromOffset(0, 0)
    ContentContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local UIList = Instance.new("UIListLayout", ContentContainer); UIList.SortOrder = Enum.SortOrder.LayoutOrder; UIList.Padding = UDim.new(0, 10)

    fitUI = function(keepWholeWindow)
        local view = SafeArea.AbsoluteSize
        if view.X <= 16 or view.Y <= 16 then return end
        local width = maximized and view.X - 16 or math.min(440, view.X - 16)
        local height = maximized and view.Y - 16 or math.min(470, view.Y - 16)
        MainFrame.Size = UDim2.fromOffset(width, height)
        MaximizeButton.Text = maximized and "还原" or "放大"
        local x = MainFrame.Position.X.Scale * view.X + MainFrame.Position.X.Offset - width / 2
        local y = MainFrame.Position.Y.Scale * view.Y + MainFrame.Position.Y.Offset - height / 2
        if keepWholeWindow then
            x = math.clamp(x, 8, view.X - width - 8)
            y = math.clamp(y, 8, view.Y - height - 8)
        else
            -- 满屏时仍允许拖动，只保证标题栏可抓取。
            local grabWidth = math.min(160, width)
            x = math.clamp(x, 8 + grabWidth - width, math.max(8, view.X - grabWidth - 8))
            y = math.clamp(y, 8, math.max(8, view.Y - 68))
        end
        MainFrame.Position = UDim2.fromOffset(x + width / 2, y + height / 2)
        local buttonX = ToggleButton.Position.X.Scale * view.X + ToggleButton.Position.X.Offset
        local buttonY = ToggleButton.Position.Y.Scale * view.Y + ToggleButton.Position.Y.Offset
        ToggleButton.Position = UDim2.fromOffset(
            math.clamp(buttonX, 8, math.max(8, view.X - 64)),
            math.clamp(buttonY, 8, math.max(8, view.Y - 64)))
    end
    track(SafeArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fitUI(true) end))
    fitUI(true)
    MaximizeButton.Activated:Connect(function()
        if maximized then
            MainFrame.Position = normalPosition
        else
            normalPosition = MainFrame.Position
            MainFrame.Position = UDim2.fromScale(0.5, 0.5)
        end
        maximized = not maximized
        fitUI(true)
    end)

    local function CreateToggle(text, callback)
        local Btn = Instance.new("TextButton", ContentContainer)
        Btn.Size = UDim2.new(1, 0, 0, 44); Btn.BackgroundColor3 = Color3.fromRGB(20, 24, 42)
        Btn.Text = "  " .. text .. " [关]"; Btn.TextColor3 = Color3.fromRGB(200, 200, 220); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
        local Stroke = Instance.new("UIStroke", Btn); Stroke.Color = Color3.fromRGB(40, 45, 70); Stroke.Thickness = 1

        local state = false
        Btn.Activated:Connect(function()
            state = not state
            if callback(state) == false then state = false end
            Btn.Text = "  " .. text .. (state and " [开]" or " [关]")
            Btn.TextColor3 = state and Color3.fromRGB(192, 132, 252) or Color3.fromRGB(200, 200, 220)
            Stroke.Color = state and Color3.fromRGB(192, 132, 252) or Color3.fromRGB(40, 45, 70)
        end)
    end

    local function CreateButton(text, callback)
        local Btn = Instance.new("TextButton", ContentContainer)
        Btn.Size = UDim2.new(1, 0, 0, 44); Btn.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
        Btn.Text = text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 10)
        Btn.Activated:Connect(callback)
    end

    -- ========================================================
    -- 💎 BẢNG DỮ LIỆU TOÀN BỘ QUẶNG & KHOÁNG SẢN (FULL ORE DB)
    -- ========================================================
    local ORE_DATABASE = {
        { key = "Coal",             name = "⬛ 煤炭",               color = Color3.fromRGB(100, 116, 139) },
        { key = "Copper",           name = "🟠 铜矿",             color = Color3.fromRGB(249, 115, 22)  },
        { key = "Tin",              name = "⚪ 锡矿",            color = Color3.fromRGB(203, 213, 225) },
        { key = "Iron",             name = "🔵 铁矿",              color = Color3.fromRGB(148, 163, 184) },
        { key = "Lead",             name = "⚙️ 铅矿",              color = Color3.fromRGB(112, 128, 144) },
        { key = "Silver",           name = "🪙 银矿",              color = Color3.fromRGB(241, 245, 249) },
        { key = "Gold",             name = "🌟 金矿",             color = Color3.fromRGB(234, 179, 8)   },
        { key = "ShaleMetal",       name = "⚙️ 页岩金属",         color = Color3.fromRGB(59, 130, 246)  },
        { key = "CubicBlockMetal",  name = "🧊 立方块金属",          color = Color3.fromRGB(6, 182, 212)   },
        { key = "Zinc",             name = "🛡️ 锌矿",              color = Color3.fromRGB(161, 161, 170) },
        { key = "Nickel",           name = "🪙 镍矿",            color = Color3.fromRGB(212, 212, 216) },
        { key = "Aluminum",         name = "⚙️ 铝矿",             color = Color3.fromRGB(228, 228, 231) },
        { key = "Cobalt",           name = "🔷 钴矿",            color = Color3.fromRGB(30, 64, 175)   },
        { key = "Titanium",         name = "🛡️ 钛矿",            color = Color3.fromRGB(100, 116, 139) },
        { key = "Platinum",         name = "⚪ 铂金",               color = Color3.fromRGB(255, 255, 255) },
        { key = "Molybden",         name = "🔮 钼矿",         color = Color3.fromRGB(168, 85, 247)  },
        { key = "Bismuth",          name = "🌈 铋矿",          color = Color3.fromRGB(236, 72, 153)  },
        { key = "Uranium",          name = "☢️ 铀矿",            color = Color3.fromRGB(132, 204, 22)  },
        { key = "Thorium",          name = "☣️ 钍矿",            color = Color3.fromRGB(101, 163, 13)  },
        { key = "Plutonium",        name = "⚠️ 钚矿",          color = Color3.fromRGB(34, 197, 94)   },
        { key = "Rhodium",          name = "⚡ 铑矿",          color = Color3.fromRGB(56, 189, 248)  },
        { key = "Iridium",          name = "✨ 铱矿",            color = Color3.fromRGB(192, 132, 252) },
        { key = "Osmium",           name = "🌐 锇矿",             color = Color3.fromRGB(99, 102, 241)  },
        { key = "Mithril",          name = "🛡️ 秘银矿",          color = Color3.fromRGB(45, 212, 191)  },
        { key = "Adamantium",       name = "🔱 艾德曼合金",       color = Color3.fromRGB(239, 68, 68)   },
        { key = "Unobtainium",      name = "🌀 奇异矿（Unobtainium）",      color = Color3.fromRGB(168, 85, 247)  },
        { key = "Palladium",        name = "⚡ 钯矿",           color = Color3.fromRGB(251, 146, 60)  },
        { key = "Vibranium",        name = "🔮 振金矿",        color = Color3.fromRGB(139, 92, 246)  },
        { key = "Quartz",           name = "🪨 石英",             color = Color3.fromRGB(226, 232, 240) },
        { key = "Topaz",            name = "🟠 黄玉",  color = Color3.fromRGB(251, 146, 60)  },
        { key = "Amethyst",         name = "🔮 紫水晶",         color = Color3.fromRGB(192, 132, 252) },
        { key = "Sapphire",         name = "🔹 蓝宝石",   color = Color3.fromRGB(59, 130, 246)  },
        { key = "Emerald",          name = "🟢 祖母绿",     color = Color3.fromRGB(34, 197, 94)   },
        { key = "Ruby",             name = "🔴 红宝石",      color = Color3.fromRGB(239, 68, 68)   },
        { key = "Diamond",          name = "💎 钻石",             color = Color3.fromRGB(45, 212, 191)  },
        { key = "Opal",             name = "🦩 蛋白石",    color = Color3.fromRGB(244, 114, 182) },
        { key = "Jade",             name = "🟩 玉石",      color = Color3.fromRGB(16, 185, 129)  },
        { key = "Alexandrite",      name = "✨ 变石",        color = Color3.fromRGB(217, 70, 239)  },
        { key = "Magma",            name = "🔥 岩浆矿",       color = Color3.fromRGB(249, 115, 22)  },
        { key = "Lava",             name = "🔥 熔岩矿",       color = Color3.fromRGB(239, 68, 68)   },
        { key = "Obsidian",         name = "🖤 黑曜石",            color = Color3.fromRGB(71, 85, 105)   },
        { key = "Meteorite",        name = "☄️ 陨石矿",      color = Color3.fromRGB(250, 204, 21)  },
        { key = "Void",             name = "🌌 虚空矿",       color = Color3.fromRGB(147, 51, 234)  },
        { key = "Supreme",          name = "👑 至高矿",         color = Color3.fromRGB(250, 204, 21)  },
        { key = "Primordial",       name = "⚜️ 原初矿",      color = Color3.fromRGB(244, 63, 94)   },
        { key = "Gem",              name = "💎 宝石晶体",       color = Color3.fromRGB(236, 72, 153)  },
        { key = "Crystall",         name = "💎 矿物晶体",       color = Color3.fromRGB(236, 72, 153)  },
        { key = "OreMesh",          name = "⛏️ 原矿块",         color = Color3.fromRGB(217, 119, 6)   },
    }

    local function GetOreVietnameseInfo(orePart)
        if not orePart:IsA("BasePart") then return nil, nil end
        local name = orePart.Name
        local rawId = tostring(orePart:GetAttribute("MineId") or orePart:GetAttribute("OreId") or name)

        -- Lọc bỏ các khối vật cản, đá nền không đào được
        if rawId:find("SolidStone") or name:find("SolidStone") or rawId:find("Bedrock") or rawId:find("Unbreakable") then
            return nil, nil
        end

        for _, data in ipairs(ORE_DATABASE) do
            if rawId:find(data.key) or name:find(data.key) then
                return data.name, data.color
            end
        end

        return "📦 矿块：" .. rawId, Color3.fromRGB(200, 200, 220)
    end

    -- ========================================================
    -- 🚀 AUTO MINE & TỰ DỊCH CHUYỂN TÌM QUẶNG
    -- ========================================================
    local function GetTool()
        if not LocalPlayer.Character then return nil end
        for _, v in pairs(LocalPlayer.Character:GetChildren()) do
            if v:FindFirstChild("EquipRemote") or string.lower(v.Name):find("pickaxe") or string.lower(v.Name):find("cuốc") then return v end
        end
        local backpack = LocalPlayer:FindFirstChild("InnoBackpack") or LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, v in pairs(backpack:GetChildren()) do
                if v:FindFirstChild("EquipRemote") or string.lower(v.Name):find("pickaxe") or string.lower(v.Name):find("cuốc") then return v end
            end
        end
        return nil
    end

    CreateToggle("⛏️ 自动挖矿", function(state)
        Settings.AutoMine = state
        if state then
            task.spawn(function()
                while Settings.AutoMine do
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local tool = GetTool()

                    if root and tool then
                        local placedOre = Workspace:FindFirstChild("PlacedOre") or Workspace:FindFirstChild("SpawnedBlocks")
                        if placedOre then
                            local closestBlock, closestDist = nil, math.huge
                            for _, v in pairs(placedOre:GetChildren()) do
                                local vnName, _ = GetOreVietnameseInfo(v)
                                if vnName then
                                    local dist = (root.Position - v.Position).Magnitude
                                    if dist <= Settings.MineRange and dist < closestDist then
                                        closestBlock = v; closestDist = dist
                                    end
                                end
                            end

                            if closestBlock then
                                local gridPos = closestBlock:GetAttribute("ChunkPosition") or closestBlock:GetAttribute("GridPosition")
                                if not gridPos then
                                    local worldPos = closestBlock.Position
                                    gridPos = Vector3int16.new(math.floor(worldPos.X / 4), math.floor(worldPos.Y / 4), math.floor(worldPos.Z / 4))
                                end
                                local madCommId = tool:GetAttribute("MadCommId")
                                if madCommId and ReplicatedStorage:FindFirstChild("MadCommEvents") and ReplicatedStorage.MadCommEvents:FindFirstChild(madCommId) then
                                    ReplicatedStorage.MadCommEvents[madCommId].Activate:FireServer(10, gridPos)
                                else
                                    if tool:FindFirstChild("RemoteEvent") then tool.RemoteEvent:FireServer(gridPos) end
                                end
                            end
                        end
                    end
                    task.wait(0.08)
                end
            end)
        end
    end)

    CreateToggle("🚀 自动前往矿石", function(state)
        Settings.AutoTPToOre = state
        if state then
            task.spawn(function()
                while Settings.AutoTPToOre do
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")

                    if root then
                        local placedOre = Workspace:FindFirstChild("PlacedOre") or Workspace:FindFirstChild("SpawnedBlocks")
                        if placedOre then
                            local closestBlock, closestDist = nil, math.huge
                            for _, v in pairs(placedOre:GetChildren()) do
                                local vnName, _ = GetOreVietnameseInfo(v)
                                if vnName then
                                    local dist = (root.Position - v.Position).Magnitude
                                    if dist < closestDist then
                                        closestBlock = v; closestDist = dist
                                    end
                                end
                            end

                            if closestBlock then
                                root.CFrame = closestBlock.CFrame * CFrame.new(0, 3, 0)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end)

    CreateToggle("👁️ 矿石透视（中文 / 多色）", function(state)
        Settings.OreESP = state
        if not state then
            for _, v in pairs(ActiveESP) do pcall(function() v:Destroy() end) end
            table.clear(ActiveESP)
        else
            task.spawn(function()
                while Settings.OreESP do
                    local oreFolder = Workspace:FindFirstChild("PlacedOre") or Workspace:FindFirstChild("SpawnedBlocks")
                    if oreFolder then
                        for _, ore in pairs(oreFolder:GetChildren()) do
                            local vnName, oreColor = GetOreVietnameseInfo(ore)
                            if vnName and not ore:FindFirstChild("MrGhost_Tag") then
                                local tag = Instance.new("BillboardGui", ore)
                                tag.Name = "MrGhost_Tag"; tag.AlwaysOnTop = true; tag.Size = UDim2.new(0, 140, 0, 30); tag.Adornee = ore; tag.StudsOffset = Vector3.new(0, 2, 0)

                                local lbl = Instance.new("TextLabel", tag)
                                lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = oreColor; lbl.TextStrokeTransparency = 0
                                lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.Text = vnName
                                table.insert(ActiveESP, tag)
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end)

    local function FindCargoUnloader()
        local factoryServer = Workspace:FindFirstChild("FactoryGridItemsServer")
        local factoryClient = Workspace:FindFirstChild("FactoryGridItemsClient")
        if factoryServer then
            for _, folder in pairs(factoryServer:GetChildren()) do
                if folder:IsA("Folder") then
                    local cargoVolume = folder:FindFirstChild("CargoVolume", true) or folder:FindFirstChild("Unloader", true)
                    if cargoVolume then
                        local prompt = cargoVolume:FindFirstChildOfClass("ProximityPrompt") or cargoVolume:FindFirstChild("CargoPrompt", true)
                        if prompt and factoryClient then
                            local clientFolder = factoryClient:FindFirstChild(folder.Name)
                            if clientFolder then
                                local sub = clientFolder:FindFirstChild(folder.Name)
                                local targetPos = sub and (sub:FindFirstChild("Unloader1") and sub.Unloader1:FindFirstChild("CargoVolume") or sub:FindFirstChild("CargoVolume", true))
                                if targetPos then return prompt, targetPos end
                            end
                        end
                    end
                end
            end
        end
        return nil, nil
    end

    CreateToggle("💰 自动前往出售", function(state)
        if state and type(fireproximityprompt) ~= "function" then
            SendCyberNotify("自动出售未启动", "当前执行器缺少交互接口，请手动使用出售点。", 3, false)
            return false
        end
        Settings.AutoSell = state
        if state then
            task.spawn(function()
                while Settings.AutoSell do
                    local currentOres = 0
                    local pWS = Workspace:FindFirstChild(LocalPlayer.Name)
                    if pWS and pWS:FindFirstChild("OrePackCargo") then
                        for _, c in pairs(pWS.OrePackCargo:GetChildren()) do
                            if not c:IsA("Weld") and not c:IsA("Motor6D") then currentOres = currentOres + 1 end
                        end
                    end

                    if currentOres >= Settings.AutoSellCount then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local prompt, targetPosPart = FindCargoUnloader()

                        if hrp and prompt and targetPosPart then
                            local savedCFrame = hrp.CFrame
                            local holdDuration = prompt.HoldDuration
                            local triggered = false
                            local ok, err = pcall(function()
                                hrp.CFrame = targetPosPart.CFrame * CFrame.new(0, 3, 0)
                                task.wait(0.3)
                                if not Settings.AutoSell or char ~= LocalPlayer.Character then return end
                                prompt.HoldDuration = 0
                                fireproximityprompt(prompt)
                                triggered = true
                                task.wait(0.3)
                            end)
                            pcall(function() prompt.HoldDuration = holdDuration end)
                            if hrp.Parent and char == LocalPlayer.Character then
                                pcall(function() hrp.CFrame = savedCFrame end)
                            end
                            if not ok then
                                SendCyberNotify("出售交互失败", tostring(err), 3, false)
                            elseif triggered then
                                SendCyberNotify("自动出售 💰", "已提交出售：" .. currentOres .. " 份矿石。", 2.5, true)
                            end
                        end
                        task.wait(2)
                    end
                    task.wait(1)
                end
            end)
        end
    end)

    CreateButton("🏠 返回自己的工厂", function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local targetCFrame = nil
        local searchFolders = {Workspace:FindFirstChild("Plots"), Workspace:FindFirstChild("Tycoons"), Workspace:FindFirstChild("Factories"), Workspace}

        for _, folder in pairs(searchFolders) do
            if folder then
                for _, plot in pairs(folder:GetChildren()) do
                    local ownerVal = plot:FindFirstChild("Owner") or plot:GetAttribute("Owner")
                    if ownerVal == LocalPlayer.Name or (typeof(ownerVal) == "Instance" and ownerVal.Value == LocalPlayer) then
                        targetCFrame = plot:GetPivot()
                        break
                    end
                end
            end
            if targetCFrame then break end
        end

        if targetCFrame then
            hrp.CFrame = targetCFrame * CFrame.new(0, 5, 0)
            SendCyberNotify("传送完成 ⚡", "已返回自己的工厂。", 2.5, true)
        else
            SendCyberNotify("传送失败 ❌", "尚未找到属于你的工厂地块。", 2.5, false)
        end
    end)

    CreateButton("⛏️ 传送到矿场入口", function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(-1854.75, 2.04, -194.96); SendCyberNotify("传送完成 ⚡", "已到达矿场入口。", 2, true) end
    end)

    CreateButton("🛒 传送到商店", function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(-1551.34, 7.16, 20.68); SendCyberNotify("传送完成 ⚡", "已到达商店。", 2, true) end
    end)

    local function ToggleMenuState()
        MainFrame.Visible = not MainFrame.Visible
        ToggleStroke.Color = MainFrame.Visible and Color3.fromRGB(192, 132, 252) or Color3.fromRGB(100, 100, 130)
    end

    MinimizeButton.Activated:Connect(ToggleMenuState)
    makeDraggable(ToggleButton, ToggleButton, ToggleMenuState)
    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and not UserInputService:GetFocusedTextBox()
            and input.KeyCode == Enum.KeyCode.RightControl then ToggleMenuState() end
    end))
end

LoadMainScript()
