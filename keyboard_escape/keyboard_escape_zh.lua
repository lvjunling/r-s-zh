-- SCRIPT BY SANG EXECUTOR

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- Xóa UI cũ nếu script được execute lại (Anti-dupe)
if CoreGui:FindFirstChild("SangMenuGui") then
    CoreGui.SangMenuGui:Destroy()
end

-- Tạo ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "SangMenuGui"
sg.Parent = CoreGui 

-- HÀM LÀM CHO GUI CÓ THỂ DI CHUYỂN BẰNG THANH TIÊU ĐỀ
local function makeDraggable(handle, gui)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 已移除秘钥输入界面，直接初始化主菜单

-- Hàm khởi tạo Menu chính
local openBtn, menu
local mainInitialized = false

local function initMainUI()
    if mainInitialized then return end
    mainInitialized = true

    -- BẢNG DỊCH NGÔN NGỮ (Đã đổi tên phím C sang God Mode)
    local currentLang = "中文"
    local strings = {
        ["Tiếng Việt"] = {
            title = "SANG EXECUTOR - MENU",
            antiBan = "Chống ban (Anti-Ban): ",
            godMode = "Bất Tử (Phím C): ",
            godNote = "⚠️ Chết 10 lần liên tiếp sẽ đưa về spawn",
            infJump = "Nhảy Vô Hạn: ",
            noclip = "Xuyên Tường: ",
            walkSpeed = "Tốc Độ Chạy: ",
            speedVal = "Tốc độ chạy",
            fly = "Bay (Fly): ",
            flySpeedVal = "Tốc độ bay",
            antiAfk = "chống ban khi AFK: ",
            getGamepasses = "获取管理员秘密工具",
            printPos = "In Tọa Độ (F9 Console)",
            tpW1 = "Dịch Chuyển Cuối World 1",
            tpW2 = "Dịch Chuyển Cuối World 2",
            langText = "🌐 Ngôn ngữ: Tiếng Việt"
        },
        ["English"] = {
            title = "SANG EXECUTOR - MENU",
            antiBan = "Anti-Ban: ",
            godMode = "God Mode (Key C): ",
            godNote = "⚠️ Dying 10 consecutive times resets to spawn",
            infJump = "Inf Jump: ",
            noclip = "Noclip: ",
            walkSpeed = "Walk Speed: ",
            speedVal = "Speed Value",
            fly = "Fly: ",
            flySpeedVal = "Fly Speed Value",
            antiAfk = "Anti-AFK: ",
            getGamepasses = "获取管理员秘密工具",
            printPos = "Print Position (F9 Console)",
            tpW1 = "Tele Win World 1",
            tpW2 = "Tele Win Final World 2",
            langText = "🌐 Language: English"
        },
        ["中文"] = {
            title = "SANG EXECUTOR - 菜单",
            antiBan = "防封禁: ",
            godMode = "无敌模式 (C键): ",
            godNote = "⚠️ 连续死亡10次将重置回出生点",
            infJump = "无限跳跃: ",
            noclip = "穿墙: ",
            walkSpeed = "移动速度: ",
            speedVal = "速度值",
            fly = "飞行: ",
            flySpeedVal = "飞行速度值",
            antiAfk = "防挂机: ",
            getGamepasses = "获取管理员秘密工具",
            printPos = "打印坐标 (F9 控制台)",
            tpW1 = "传送 第一世界通关",
            tpW2 = "传送 第二世界终点",
            langText = "🌐 语言: 中文"
        }
    }

    -- NÚT BẬT/TẮT MENU
    openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 90, 0, 90)
    openBtn.Position = UDim2.new(0, 20, 0.5, -45)
    openBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    openBtn.Font = Enum.Font.Michroma
    openBtn.TextSize = 14
    openBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    openBtn.Text = "SANG\nEXECUTOR"
    openBtn.TextWrapped = true
    openBtn.Parent = sg
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)
    local btnStroke = Instance.new("UIStroke", openBtn)
    btnStroke.Color = Color3.fromRGB(0, 255, 255)
    btnStroke.Thickness = 1.5
    makeDraggable(openBtn, openBtn)

    -- KHUNG MENU CHÍNH
    menu = Instance.new("ScrollingFrame")
    menu.Size = UDim2.new(0, 320, 0, 450)
    menu.Position = UDim2.new(0.5, -160, 0.5, -225)
    menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    menu.Visible = false
    menu.CanvasSize = UDim2.new(0, 0, 0, 650)
    menu.ScrollBarThickness = 6
    menu.Parent = sg
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)
    local menuStroke = Instance.new("UIStroke", menu)
    menuStroke.Color = Color3.fromRGB(0, 255, 255)
    menuStroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Text = strings[currentLang].title
    title.Font = Enum.Font.Michroma
    title.TextSize = 11
    title.Parent = menu
    makeDraggable(title, menu)

    openBtn.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
    end)

    -- NÚT CHỌN NGÔN NGỮ LAUNCHER
    local langBtn = Instance.new("TextButton")
    langBtn.Size = UDim2.new(0, 280, 0, 32)
    langBtn.Position = UDim2.new(0, 20, 0, 40)
    langBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    langBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
    langBtn.Text = strings[currentLang].langText
    langBtn.Font = Enum.Font.GothamBold
    langBtn.TextSize = 13
    langBtn.Parent = menu
    Instance.new("UICorner", langBtn).CornerRadius = UDim.new(0, 6)

    -- KHUNG DROPDOWN CHỌN NGÔN NGỮ
    local langDropdown = Instance.new("Frame")
    langDropdown.Size = UDim2.new(0, 280, 0, 100)
    langDropdown.Position = UDim2.new(0, 20, 0, 75)
    langDropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    langDropdown.Visible = false
    langDropdown.ZIndex = 10
    langDropdown.Parent = menu
    Instance.new("UICorner", langDropdown).CornerRadius = UDim.new(0, 6)
    local dropStroke = Instance.new("UIStroke", langDropdown)
    dropStroke.Color = Color3.fromRGB(0, 255, 255)
    dropStroke.Thickness = 1

    -- BIẾN TRẠNG THÁI TÍNH NĂNG
    local infJumpEnabled = false
    local noclipEnabled = false
    local speedEnabled = false
    local currentWalkSpeed = 16
    local flyEnabled = false
    local currentFlySpeed = 50
    local antiAfkEnabled = false
    local antiBanEnabled = false
    local godModeEnabled = false

    local btnAntiBan, btnGodMode, godText, godNote, btnInfJump, btnNoclip, btnSpeedToggle, speedLabelRef, btnFly, flyLabelRef, btnAntiAfk, btnGetGamepasses, btnPrintPos, btnTpW1, btnTpW2

    -- HÀM CẬP NHẬT TOÀN BỘ NGÔN NGỮ TRÊN UI
    local function updateUI1Texts()
        local s = strings[currentLang]
        title.Text = s.title
        langBtn.Text = s.langText

        if btnAntiBan then btnAntiBan.Text = s.antiBan .. (antiBanEnabled and "ON" or "OFF") end
        if godText then godText.Text = s.godMode .. (godModeEnabled and "ON" or "OFF") end
        if godNote then godNote.Text = s.godNote end
        if btnInfJump then btnInfJump.Text = s.infJump .. (infJumpEnabled and "ON" or "OFF") end
        if btnNoclip then btnNoclip.Text = s.noclip .. (noclipEnabled and "ON" or "OFF") end
        if btnSpeedToggle then btnSpeedToggle.Text = s.walkSpeed .. (speedEnabled and "ON" or "OFF") end
        if speedLabelRef then speedLabelRef.Text = s.speedVal .. ": " .. currentWalkSpeed end
        if btnFly then btnFly.Text = s.fly .. (flyEnabled and "ON" or "OFF") end
        if flyLabelRef then flyLabelRef.Text = s.flySpeedVal .. ": " .. currentFlySpeed end
        if btnAntiAfk then btnAntiAfk.Text = s.antiAfk .. (antiAfkEnabled and "ON" or "OFF") end
        if btnGetGamepasses then btnGetGamepasses.Text = s.getGamepasses end
        if btnPrintPos then btnPrintPos.Text = s.printPos end
        if btnTpW1 then btnTpW1.Text = s.tpW1 end
        if btnTpW2 then btnTpW2.Text = s.tpW2 end
    end

    local function createLangOption(posY, langName, displayName)
        local opt = Instance.new("TextButton")
        opt.Size = UDim2.new(0, 268, 0, 28)
        opt.Position = UDim2.new(0, 6, 0, posY)
        opt.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        opt.TextColor3 = Color3.fromRGB(255, 255, 255)
        opt.Text = displayName
        opt.Font = Enum.Font.GothamBold
        opt.TextSize = 13
        opt.ZIndex = 11
        opt.Parent = langDropdown
        Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 4)

        opt.MouseButton1Click:Connect(function()
            currentLang = langName
            langDropdown.Visible = false
            updateUI1Texts()
        end)
        return opt
    end

    createLangOption(6, "中文", "中文")
    createLangOption(36, "English", "English")
    createLangOption(66, "Tiếng Việt", "Tiếng Việt")

    langBtn.MouseButton1Click:Connect(function()
        langDropdown.Visible = not langDropdown.Visible
    end)

    -- LOGIC ANTI-BAN NÂNG CAO
    pcall(function()
        local oldNameCall
        oldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local name = tostring(self):lower()
            if antiBanEnabled then
                if (method == "Kick" or method == "kick") and self == player then return end
                if method == "FireServer" or method == "InvokeServer" then
                    if name:match("ban") or name:match("kick") or name:match("report") or name:match("log") or name:match("anticheat") then
                        return
                    end
                end
            end
            return oldNameCall(self, ...)
        end)
    end)

    -- HỆ THỐNG HOTKEYS C & M (Đã chuyển phím C sang God Mode)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.M then
            menu.Visible = not menu.Visible
        elseif input.KeyCode == Enum.KeyCode.C then
            -- Chuyển phím C điều khiển God Mode
            godModeEnabled = not godModeEnabled
            if godText and btnGodMode and godNote then
                godText.Text = strings[currentLang].godMode .. (godModeEnabled and "ON" or "OFF")
                if godModeEnabled then
                    btnGodMode.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                    godText.TextColor3 = Color3.fromRGB(255, 255, 255)
                    godNote.TextColor3 = Color3.fromRGB(230, 230, 230)
                else
                    btnGodMode.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
                    godText.TextColor3 = Color3.fromRGB(0, 0, 0)
                    godNote.TextColor3 = Color3.fromRGB(160, 80, 0)
                end
            end
        end
    end)

    -- HÀM HỖ TRỢ BAY
    local flyConnection
    local function updateFly(state)
        flyEnabled = state
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        if flyEnabled then
            hum.PlatformStand = true

            local bg = Instance.new("BodyGyro")
            bg.P = 9e4
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.CFrame = hrp.CFrame
            bg.Name = "FlyGyro_Sang"
            bg.Parent = hrp

            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Name = "FlyVel_Sang"
            bv.Parent = hrp

            flyConnection = RunService.RenderStepped:Connect(function(deltaTime)
                if not flyEnabled or not char or not hrp then
                    if flyConnection then flyConnection:Disconnect() end
                    return
                end
                
                local cam = Workspace.CurrentCamera
                local moveDir = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                
                hrp.CFrame = hrp.CFrame + (moveDir * (currentFlySpeed * deltaTime))
                bg.CFrame = cam.CFrame
            end)
        else
            hum.PlatformStand = false
            if flyConnection then flyConnection:Disconnect() end
            if hrp:FindFirstChild("FlyGyro_Sang") then hrp.FlyGyro_Sang:Destroy() end
            if hrp:FindFirstChild("FlyVel_Sang") then hrp.FlyVel_Sang:Destroy() end
        end
    end

    -- HÀM TẠO NÚT BẤM THƯỜNG
    local function createButton(posY, defaultText)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 280, 0, 32)
        btn.Position = UDim2.new(0, 20, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.Text = defaultText
        btn.Font = Enum.Font.GothamBold
        btn.TextSize, btn.TextWrapped = 13, true
        btn.Parent = menu
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- HÀM TẠO THANH KÉO (SLIDER)
    local function createSlider(posY, titleText, minVal, maxVal, defaultVal, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 280, 0, 42)
        container.Position = UDim2.new(0, 20, 0, posY)
        container.BackgroundTransparency = 1
        container.Parent = menu

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 16)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Text = titleText .. ": " .. defaultVal
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.Parent = container

        local bgBar = Instance.new("Frame")
        bgBar.Size = UDim2.new(1, 0, 0, 9)
        bgBar.Position = UDim2.new(0, 0, 0, 20)
        bgBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        bgBar.Parent = container
        Instance.new("UICorner", bgBar).CornerRadius = UDim.new(1, 0)

        local fillBar = Instance.new("Frame")
        fillBar.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
        fillBar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        fillBar.Parent = bgBar
        Instance.new("UICorner", fillBar).CornerRadius = UDim.new(1, 0)

        local draggingSlider = false
        local function updateValue(input)
            local pos = math.clamp((input.Position.X - bgBar.AbsolutePosition.X) / bgBar.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            fillBar.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = titleText .. ": " .. val
            callback(val)
        end

        bgBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = true
                updateValue(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateValue(input)
            end
        end)

        return label
    end

    -- HÀM TELEPORT TỨC THỜI
    local function instantTeleport(targetCFrame)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            hrp.CFrame = targetCFrame
        end
    end

    -- ================= TẠO CÁC CHỨC NĂNG =================
    
    btnAntiBan = createButton(78, strings[currentLang].antiBan .. "OFF")
    btnAntiBan.MouseButton1Click:Connect(function()
        antiBanEnabled = not antiBanEnabled
        btnAntiBan.Text = strings[currentLang].antiBan .. (antiBanEnabled and "ON" or "OFF")
        btnAntiBan.BackgroundColor3 = antiBanEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(220, 220, 220)
    end)

    -- GOD MODE
    btnGodMode = Instance.new("TextButton")
    btnGodMode.Size = UDim2.new(0, 280, 0, 46)
    btnGodMode.Position = UDim2.new(0, 20, 0, 114)
    btnGodMode.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    btnGodMode.Text = ""
    btnGodMode.Parent = menu
    Instance.new("UICorner", btnGodMode).CornerRadius = UDim.new(0, 6)

    godText = Instance.new("TextLabel")
    godText.Size = UDim2.new(1, 0, 0, 22)
    godText.Position = UDim2.new(0, 0, 0, 4)
    godText.BackgroundTransparency = 1
    godText.TextColor3 = Color3.fromRGB(0, 0, 0)
    godText.Text = strings[currentLang].godMode .. "OFF"
    godText.Font = Enum.Font.GothamBold
    godText.TextSize = 13
    godText.Parent = btnGodMode

    godNote = Instance.new("TextLabel")
    godNote.Size = UDim2.new(1, 0, 0, 16)
    godNote.Position = UDim2.new(0, 0, 0, 24)
    godNote.BackgroundTransparency = 1
    godNote.TextColor3 = Color3.fromRGB(160, 80, 0)
    godNote.Text = strings[currentLang].godNote
    godNote.Font = Enum.Font.Gotham
    godNote.TextSize = 10
    godNote.Parent = btnGodMode

    btnGodMode.MouseButton1Click:Connect(function()
        godModeEnabled = not godModeEnabled
        godText.Text = strings[currentLang].godMode .. (godModeEnabled and "ON" or "OFF")
        if godModeEnabled then
            btnGodMode.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            godText.TextColor3 = Color3.fromRGB(255, 255, 255)
            godNote.TextColor3 = Color3.fromRGB(230, 230, 230)
        else
            btnGodMode.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
            godText.TextColor3 = Color3.fromRGB(0, 0, 0)
            godNote.TextColor3 = Color3.fromRGB(160, 80, 0)
        end
    end)

    btnInfJump = createButton(166, strings[currentLang].infJump .. "OFF")
    btnInfJump.MouseButton1Click:Connect(function()
        infJumpEnabled = not infJumpEnabled
        btnInfJump.Text = strings[currentLang].infJump .. (infJumpEnabled and "ON" or "OFF")
        btnInfJump.BackgroundColor3 = infJumpEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(220, 220, 220)
    end)

    UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled then
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    btnNoclip = createButton(204, strings[currentLang].noclip .. "OFF")
    btnNoclip.MouseButton1Click:Connect(function()
        noclipEnabled = not noclipEnabled
        btnNoclip.Text = strings[currentLang].noclip .. (noclipEnabled and "ON" or "OFF")
        btnNoclip.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(220, 220, 220)
    end)

    btnSpeedToggle = createButton(242, strings[currentLang].walkSpeed .. "OFF")
    btnSpeedToggle.MouseButton1Click:Connect(function()
        speedEnabled = not speedEnabled
        btnSpeedToggle.Text = strings[currentLang].walkSpeed .. (speedEnabled and "ON" or "OFF")
        btnSpeedToggle.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(220, 220, 220)
    end)

    speedLabelRef = createSlider(280, strings[currentLang].speedVal, 16, 1000, 16, function(val)
        currentWalkSpeed = val
    end)

    btnFly = createButton(328, strings[currentLang].fly .. "OFF")
    btnFly.MouseButton1Click:Connect(function()
        updateFly(not flyEnabled)
        btnFly.Text = strings[currentLang].fly .. (flyEnabled and "ON" or "OFF")
        btnFly.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(220, 220, 220)
    end)

    flyLabelRef = createSlider(366, strings[currentLang].flySpeedVal, 16, 1000, 50, function(val)
        currentFlySpeed = val
    end)

    btnAntiAfk = createButton(414, strings[currentLang].antiAfk .. "OFF")
    btnAntiAfk.MouseButton1Click:Connect(function()
        antiAfkEnabled = not antiAfkEnabled
        btnAntiAfk.Text = strings[currentLang].antiAfk .. (antiAfkEnabled and "ON" or "OFF")
        btnAntiAfk.BackgroundColor3 = antiAfkEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(220, 220, 220)
    end)

    -- NÚT LẤY TOOL BÍ MẬT CỦA ADMIN
    btnGetGamepasses = createButton(452, strings[currentLang].getGamepasses)
    btnGetGamepasses.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    btnGetGamepasses.MouseButton1Click:Connect(function()
        local backpackRef = player:WaitForChild("Backpack")
        local function processContainer(container)
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("Tool") then
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "已获取物品：",
                        Text = obj.Name,
                        Duration = 3
                    })
                    obj:Clone().Parent = backpackRef
                    task.wait(0.5)
                end
            end
        end

        task.spawn(function()
            processContainer(ReplicatedStorage)
            processContainer(Lighting)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "完成",
                Text = "已将所有物品放入背包！",
                Duration = 4
            })
        end)
    end)

    player.Idled:Connect(function()
        if antiAfkEnabled then
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end
    end)

    btnPrintPos = createButton(490, strings[currentLang].printPos)
    btnPrintPos.BackgroundColor3 = Color3.fromRGB(255, 230, 180)
    btnPrintPos.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.CFrame
            print("你当前的坐标为：CFrame.new(" .. tostring(pos.X) .. ", " .. tostring(pos.Y) .. ", " .. tostring(pos.Z) .. ")")
        end
    end)

    btnTpW1 = createButton(528, strings[currentLang].tpW1)
    btnTpW1.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    btnTpW1.MouseButton1Click:Connect(function()
        instantTeleport(CFrame.new(-14004.904296875, 754.157958984375, 3066.256591796875)) 
    end)

    btnTpW2 = createButton(566, strings[currentLang].tpW2)
    btnTpW2.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
    btnTpW2.MouseButton1Click:Connect(function()
        instantTeleport(CFrame.new(7984.4072265625, 720.1798706054688, 5141.7080078125)) 
    end)

    RunService.Stepped:Connect(function()
        if noclipEnabled or flyEnabled then
            local char = player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)

    -- LOGIC MÁU VÀ ĐẾM CHẾT
    local lastPosition = nil
    local deathCountAtSpot = 0

    local function setupCharacter(char)
        local hum = char:WaitForChild("Humanoid", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        
        if hum and hrp then
            if godModeEnabled and lastPosition and deathCountAtSpot < 10 then
                task.spawn(function()
                    for i = 1, 15 do
                        if not hrp or not hrp.Parent then break end
                        hrp.CFrame = lastPosition
                        task.wait()
                    end
                end)
            elseif deathCountAtSpot >= 10 then
                deathCountAtSpot = 0
                lastPosition = nil
            end

            hum.Died:Connect(function()
                if hrp and hrp.Parent then
                    local currentPos = hrp.Position
                    if lastPosition then
                        local distance = (currentPos - lastPosition.Position).Magnitude
                        if distance <= 10 then
                            deathCountAtSpot = deathCountAtSpot + 1
                        else
                            deathCountAtSpot = 1
                        end
                    else
                        deathCountAtSpot = 1
                    end
                    lastPosition = hrp.CFrame
                end
            end)
        end
    end

    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        setupCharacter(player.Character)
    end

    RunService.Heartbeat:Connect(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if speedEnabled then
                    hum.WalkSpeed = currentWalkSpeed
                end
                if godModeEnabled then
                    hum.Health = hum.Health + 100000
                end
            end
        end
    end)
end

-- 直接启动主界面
initMainUI()
