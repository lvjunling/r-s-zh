-- deobf by suda
local clock
clock = os.clock
local clock2
clock2 = os.clock
local floor
floor = math.floor
local ceil
ceil = math.ceil
local abs
abs = math.abs
local min
min = math.min
local max
max = math.max
local sqrt
sqrt = math.sqrt
local rad
rad = math.rad
local clamp
clamp = math.clamp
local vector
vector = Vector3.new
local vector2
vector2 = Vector2.new
local color
color = Color3.fromRGB
local cframe
cframe = CFrame.new
local format
format = string.format
local v

local function fn()
	local v2 = cloneref
	if not v2 then
		return function(arg)
			return arg
		end
	end
	local obj = setmetatable({}, { __mode = "v" })

	return function(arg)
		if not arg then
			return nil
		end
		local debugId = arg:GetDebugId()
		local v3 = obj[debugId]
		if v3 then
			return v3
		end
		local v4 = v2(arg)
		obj[debugId] = v4
		return v4
	end
end

v = fn()

if getgenv().SkinHubLoaded then
	game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Skin HUB v4.2", Text = "请勿重复执行", Duration = 3 })
	return
end

getgenv().SkinHubLoaded = true
local v2, v3, lib, lib2, lib3, options, toggles, tbl, lib4, fn2
local v4, v5, v6, v7, v8, v9, v10, v11, localPlayer, str
local tbl2, fn3, fn4, fn5, tbl3

do
	local v12 = clock()
	v2 = v(game:GetService("HttpService"))
	v3 = v(game:GetService("TeleportService"))
	lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
	lib2 = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua"))()
	lib3 = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua"))()
	lib.ForceCheckbox = true
	options = lib.Options
	toggles = lib.Toggles
	tbl = {}
	lib4 = nil

	pcall(function()
		lib4 = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
	end)

	if lib4 == nil then
		lib4 = getgenv().mstudio45_ESP
	end

	if lib4 ~= nil then
		pcall(function()
			lib4.GlobalConfig.Billboards = true
			lib4.GlobalConfig.Distance = true
		end)
	end

	tbl.addESP = function(arg)
		if lib4 == nil then
			return nil
		end
		local ok, result = pcall(lib4.Add, lib4, arg)
		if ok then
			return result
		end
		return nil
	end

	tbl.destroyESP = function(arg)
		if arg ~= nil then
			pcall(function()
				arg:Destroy()
			end)
		end
	end

	tbl.notify = function(arg, arg2)
		lib:Notify(arg, arg2 or 2)
	end

	fn2 = function(arg, ...)
		local tbl4 = { ... }

		for i = 1, #tbl4 do
			local v13 = tbl4[i]

			if arg then
				arg = arg:FindFirstChild(v13)
			else
				arg = nil
			end

			if not arg then
				return nil
			end
		end

		return arg
	end

	v4 = v(game:GetService("Players"))
	v5 = v(game:GetService("RunService"))
	v6 = v(game:GetService("UserInputService"))
	v7 = v(game:GetService("ReplicatedStorage"))
	v8 = v(game:GetService("TweenService"))
	v9 = v(game:GetService("Lighting"))
	v10 = v(game:GetService("Stats"))
	local v13 = v(game:GetService("CoreGui"))
	v11 = v(game:GetService("MarketplaceService"))
	local network = v10 and v10:FindFirstChild("Network")
	network = network and network:FindFirstChild("ServerStatsItem")
	local dataPing = network and network:FindFirstChild("Data Ping")
	localPlayer = v4.LocalPlayer

	tbl.createFloatingButton = function(name, text, position, textSize, arg)
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = name
		screenGui.ResetOnSpawn = false
		screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
		local textButton = Instance.new("TextButton")
		textButton.Size = UDim2.new(0, 60, 0, 60)
		textButton.Position = position
		textButton.BackgroundColor3 = lib.Scheme.MainColor
		textButton.BackgroundTransparency = 0.2
		textButton.BorderSizePixel = 0
		textButton.Text = text
		textButton.TextColor3 = Color3.new(1, 1, 1)
		textButton.TextSize = textSize
		textButton.Font = Enum.Font.GothamBold
		textButton.Parent = screenGui
		textButton.Active = true
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 12)
		uiCorner.Parent = textButton
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = lib.Scheme.AccentColor
		uiStroke.Thickness = 2.5
		uiStroke.Transparency = 0.3
		uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		uiStroke.Parent = textButton
		local flag = false
		local flag2 = false
		local position2 = nil
		local position3 = nil
		local tbl4 = {}

		table.insert(tbl4, textButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				flag = true
				flag2 = false
				position2 = input.Position
				position3 = textButton.Position
			end
		end))

		table.insert(tbl4, v6.InputChanged:Connect(function(input)
			if flag and input.UserInputType == Enum.UserInputType.MouseMovement then
				if (input.Position - position2).Magnitude > 4 then
					flag2 = true
				end

				local n = input.Position - position2
				textButton.Position = UDim2.new(position3.X.Scale, position3.X.Offset + n.X, position3.Y.Scale, position3.Y.Offset + n.Y)
			end
		end))

		table.insert(tbl4, v6.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				flag = false
			end
		end))

		table.insert(tbl4, screenGui.Destroying:Connect(function()
			for _, v14 in tbl4, nil, nil do
				pcall(function()
					v14:Disconnect()
				end)
			end
		end))

		textButton.MouseButton1Click:Connect(function()
			if flag2 then
				return
			end
			arg()
		end)

		return screenGui, textButton
	end

	tbl.GUN_NAME_SET = {
		Musket = true,
		Carbine = true,
		Rifle = true,
		Pistol = true,
		Blunderbuss = true,
		["Air Rifle"] = true,
		["Horse Artillery Pistol"] = true,
		["Nock Gun"] = true,
		["Navy Pistol"] = true,
		["Brass Pistol"] = true,
		["Double Barrel Pistol"] = true,
		["Flintlock Pistol"] = true,
		["Model 29"] = true,
		["Old Blunderbuss"] = true,
		["Needle Gun"] = true,
		Shotgun = true,
		["Bolt Rifle"] = true,
		["Officer Pistol"] = true,
		["Heavy Pistol"] = true,
		["Light Dragoon Pistol"] = true,
	}

	tbl.WEAPON_SPEED_MAP = {
		Musket = 1650,
		Rifle = 1800,
		["Baker Rifle"] = 1750,
		["Jäger Rifle"] = 1750,
		["Ferguson Rifle"] = 1700,
		Carbine = 1550,
		Musketoon = 1500,
		["Air Rifle"] = 1300,
		["Needle Gun"] = 1600,
		["Bolt Rifle"] = 1700,
		Pistol = 900,
		["Flintlock Pistol"] = 880,
		["Navy Pistol"] = 920,
		["Brass Pistol"] = 890,
		["Officer Pistol"] = 950,
		["Heavy Pistol"] = 900,
		["Light Dragoon Pistol"] = 910,
		["Horse Artillery Pistol"] = 930,
		["Double Barrel Pistol"] = 900,
		Colt = 950,
		["Duckfoot Pistol"] = 850,
		["Howdah Pistol"] = 880,
		Blunderbuss = 650,
		["Old Blunderbuss"] = 630,
		["Nock Gun"] = 680,
		Shotgun = 620,
	}

	tbl.sharedIsGun = function(arg)
		if not arg or not arg:IsA("Tool") then
			return false
		end
		local animations = arg:FindFirstChild("Animations")
		if not animations then
			return false
		end
		return animations:FindFirstChild("Aim") ~= nil or animations:FindFirstChild("Aiming") ~= nil
	end

	tbl.sharedGetShotsLoaded = function(arg)
		if not arg then
			return 0
		end
		local shotsLoaded = arg:FindFirstChild("ShotsLoaded")
		if shotsLoaded and (shotsLoaded:IsA("IntValue") or shotsLoaded:IsA("NumberValue")) then
			return shotsLoaded.Value
		end
		local players = workspace:FindFirstChild("Players")

		if players then
			local v14 = players:FindFirstChild(localPlayer.Name)

			if v14 then
				local v15 = v14:FindFirstChild(arg.Name)

				if v15 then
					local shotsLoaded2 = v15:FindFirstChild("ShotsLoaded")
					if shotsLoaded2 and (shotsLoaded2:IsA("IntValue") or shotsLoaded2:IsA("NumberValue")) then
						return shotsLoaded2.Value
					end
				end
			end
		end

		return 0
	end

	tbl.sharedGetRemote = function(arg)
		if not arg then
			return nil
		end
		local remoteEvent = arg:FindFirstChild("RemoteEvent")
		if remoteEvent then
			return remoteEvent
		end
		local players = workspace:FindFirstChild("Players")

		if players then
			local v14 = players:FindFirstChild(localPlayer.Name)

			if v14 then
				local v15 = v14:FindFirstChild(arg.Name)
				if v15 then
					return v15:FindFirstChild("RemoteEvent")
				end
			end
		end

		return nil
	end

	tbl.getHeldToolRemote = function()
		local character = localPlayer.Character
		if not character then
			return nil, nil
		end

		for _, v14 in character:GetChildren() do
			if v14:IsA("Tool") then
				local remoteEvent = v14:FindFirstChild("RemoteEvent")
				if remoteEvent then
					return remoteEvent, v14
				end
			end
		end

		return nil, nil
	end

	tbl.sharedGetCurrentBulletSpeed = function()
		local character = localPlayer.Character
		if not character then
			return 900
		end
		local tool = character:FindFirstChildOfClass("Tool")
		if not tool then
			return 900
		end
		local name = tool.Name
		local v14 = tbl.WEAPON_SPEED_MAP[name]
		if v14 then
			return v14
		end
		local str2 = name:lower()
		if str2:find("rifle") or str2:find("musket") or str2:find("carbine") or str2:find("needle") or str2:find("bolt") or str2:find("jäger") or str2:find("ferguson") or str2:find("musketoon") then
			return 1650
		end

		if str2:find("pistol") or str2:find("colt") or str2:find("revolver") or str2:find("horse") or str2:find("double") then
			return 900
		end

		if str2:find("blunderbuss") or str2:find("nock") or str2:find("shotgun") then
			return 650
		end
		return 900
	end

	tbl.sharedGetPing = function()
		local ok, result = pcall(function()
			return dataPing:GetValue()
		end)

		if ok and result then
			return result
		end
		return 0
	end

	tbl._charAddedHandlers = {}

	localPlayer.CharacterAdded:Connect(function(character)
		local charAddedHandlers = tbl._charAddedHandlers

		for i = 1, #charAddedHandlers do
			local v14 = charAddedHandlers[i]

			if v14 then
				local ok, result = pcall(v14, character)

				if not ok then
					warn("[SkinHub] CharacterAdded handler error: " .. tostring(result))
				end
			end
		end
	end)

	tbl.onCharacterAdded = function(arg)
		table.insert(tbl._charAddedHandlers, arg)

		return function()
			for i = #tbl._charAddedHandlers, 1, -1 do
				if tbl._charAddedHandlers[i] == arg then
					table.remove(tbl._charAddedHandlers, i)
					break
				end
			end
		end
	end

	tbl.ZombieWatch = { _models = {}, _addedSubs = {}, _started = false }
	local tbl4 = { "Zombies", "Camera" }

	tbl.ZombieWatch.start = function()
		if tbl.ZombieWatch._started then
			return
		end
		tbl.ZombieWatch._started = true
		local addedSubs = tbl.ZombieWatch._addedSubs

		local function fn6(arg)
			if arg:IsA("Model") and not tbl.ZombieWatch._models[arg] then
				tbl.ZombieWatch._models[arg] = true

				for _, v14 in addedSubs, nil, nil do
					task.spawn(v14, arg)
				end
			end
		end

		local function fn7(arg)
			if not arg or arg:GetAttribute("SkinHubZombieWatch") then
				return
			end
			arg:SetAttribute("SkinHubZombieWatch", true)

			arg.ChildAdded:Connect(function(child)
				task.defer(fn6, child)
			end)

			arg.ChildRemoved:Connect(function(child)
				tbl.ZombieWatch._models[child] = nil
			end)

			for _, v14 in arg:GetChildren() do
				task.spawn(fn6, v14)
			end
		end

		local function fn8()
			for _, v14 in tbl4, nil, nil do
				fn7(workspace:FindFirstChild(v14))
			end
		end

		fn8()

		workspace.ChildAdded:Connect(function(child)
			for _, v14 in tbl4, nil, nil do
				if child.Name == v14 then
					task.defer(fn7, child)
				end
			end
		end)
	end

	tbl.ZombieWatch.getAll = function()
		local tbl5 = {}

		for k in tbl.ZombieWatch._models, nil, nil do
			if k.Parent then
				tbl5[#tbl5 + 1] = k
			else
				tbl.ZombieWatch._models[k] = nil
			end
		end

		return tbl5
	end

	tbl.ZombieWatch.onAdded = function(arg)
		table.insert(tbl.ZombieWatch._addedSubs, arg)

		return function()
			local v14 = table.find(tbl.ZombieWatch._addedSubs, arg)

			if v14 then
				table.remove(tbl.ZombieWatch._addedSubs, v14)
			end
		end
	end

	tbl.ZombieWatch.forEach = function(arg)
		for _, v14 in tbl.ZombieWatch.getAll() do
			pcall(arg, v14)
		end
	end

	local str2 = "fish"

	pcall(function()
		local imageManager = lib.ImageManager
		if not imageManager then
			return
		end

		if not imageManager.GetAsset("SkinHubLogo") then
			imageManager.AddAsset("SkinHubLogo", 0, "https://raw.githubusercontent.com/Zephyrastic/sepweqeq/main/UI_image.png")
		end

		str2 = imageManager.GetAsset("SkinHubLogo") or str2
	end)

	local n = 100

	local v14 = lib:CreateLoading({
		Title = "Skin HUB v4.2",
		Icon = str2,
		IconSize = UDim2.fromOffset(40, 40),
		CurrentStep = 0,
		TotalSteps = n,
		ShowSidebar = false,
		AlwaysOnTop = true,
		WindowWidth = 460,
		WindowHeight = 220,
		ContentWidth = 460,
	})

	v14:SetMessage("Skin HUB v4.2")
	v14:SetDescription("正在初始化...")
	v14:SetCurrentStep(0)
	local color2 = Color3.fromRGB(255, 255, 255)

	__StyleLoadingDesc = function()
		local screenGui = v14 and v14.ScreenGui
		if not screenGui then
			return
		end

		local function fn6(arg)
			if arg:IsA("TextLabel") then
				pcall(function()
					arg.TextColor3 = color2
					arg.TextStrokeTransparency = 0.4
					arg.TextStrokeColor3 = Color3.fromRGB(20, 60, 100)
				end)

				if not arg:GetAttribute("SkinHubDescLock") then
					arg:SetAttribute("SkinHubDescLock", true)

					arg:GetPropertyChangedSignal("TextColor3"):Connect(function()
						if arg.TextColor3 ~= color2 then
							pcall(function()
								arg.TextColor3 = color2
							end)
						end
					end)
				end
			end
		end

		for _, v15 in screenGui:GetDescendants() do
			fn6(v15)
		end

		if not screenGui:GetAttribute("SkinHubDescHook") then
			screenGui:SetAttribute("SkinHubDescHook", true)

			screenGui.DescendantAdded:Connect(function(descendant)
				task.defer(function()
					fn6(descendant)
				end)
			end)
		end
	end

	task.defer(function()
		pcall(__StyleLoadingDesc)
	end)

	tbl.bootLanguage = "中文"
	tbl.bootLanguagePicked = false
	tbl.bootLanguageGui = nil
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SkinHubLanguagePicker"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 2147483646
	screenGui.Parent = playerGui
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -24)
	frame.Size = UDim2.new(0, 280, 0, 76)
	frame.BackgroundColor3 = color(8, 14, 26)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = frame
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = color(45, 90, 140)
	uiStroke.Thickness = 1.5
	uiStroke.Parent = frame
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.new(0, 0, 0, 4)
	textLabel.Size = UDim2.new(1, 0, 0, 20)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = "语言 / Language"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextSize = 14
	textLabel.Parent = frame
	local tbl5 = {}

	local function fn6()
		for k, v15 in tbl5, nil, nil do
			if k == tbl.bootLanguage then
				v15.BackgroundColor3 = color(80, 200, 255)
				v15.TextColor3 = color(4, 8, 16)
			else
				v15.BackgroundColor3 = color(18, 32, 56)
				v15.TextColor3 = Color3.new(1, 1, 1)
			end
		end
	end

	local function fn7(text, arg)
		local textButton = Instance.new("TextButton")
		textButton.Position = UDim2.new(0, arg, 0, 30)
		textButton.Size = UDim2.new(0, 128, 0, 36)
		textButton.Font = Enum.Font.GothamBold
		textButton.Text = text
		textButton.TextSize = 15
		textButton.BorderSizePixel = 0
		textButton.Parent = frame
		local uiCorner2 = Instance.new("UICorner")
		uiCorner2.CornerRadius = UDim.new(0, 8)
		uiCorner2.Parent = textButton

		textButton.MouseButton1Click:Connect(function()
			tbl.bootLanguage = text
			tbl.bootLanguagePicked = true
			fn6()

			if type(__FinishLoading) == "function" then
				task.defer(__FinishLoading)
			end
		end)

		tbl5[text] = textButton
	end

	fn7("中文", 8)
	fn7("English", 144)
	fn6()
	tbl.bootLanguageGui = screenGui

	tbl.destroyBootLanguagePicker = function()
		if tbl.bootLanguageGui == nil then
			return
		end

		pcall(function()
			tbl.bootLanguageGui:Destroy()
		end)

		tbl.bootLanguageGui = nil
	end

	local v15 = color(80, 200, 255)
	local v16 = color(140, 240, 255)
	local v17 = color(18, 32, 56)
	local v18 = color(8, 14, 26)
	local v19 = color(45, 90, 140)
	local color3 = Color3.new(1, 1, 1)
	local font = Font.fromEnum(Enum.Font.SciFi)
	local screenGui2 = v14.ScreenGui

	local function fn8(parent)
		if parent:IsA("Frame") then
			local backgroundColor3 = parent.BackgroundColor3

			if backgroundColor3 == Color3.fromRGB(15, 15, 15) then
				parent.BackgroundColor3 = v18
			elseif backgroundColor3 == Color3.fromRGB(25, 25, 25) then
				parent.BackgroundColor3 = v17
			elseif backgroundColor3 == Color3.fromRGB(125, 85, 255) then
				parent.BackgroundColor3 = v15
			end

			if parent.BackgroundColor3 == v15 and parent.Size.Y.Offset <= 20 then
				if not parent:FindFirstChildOfClass("UIGradient") then
					local uiGradient = Instance.new("UIGradient")
					uiGradient.Color = ColorSequence.new(v15, v16)
					uiGradient.Rotation = 0
					uiGradient.Parent = parent
				end
			end
		elseif parent:IsA("ImageLabel") then
			if not (parent.Size.X.Offset >= 36) then
				parent.ImageColor3 = v15
			end
		elseif parent:IsA("UIStroke") then
			parent.Color = v19
		elseif parent:IsA("TextLabel") then
			parent.TextColor3 = color3
			parent.TextStrokeTransparency = 0.4
			parent.TextStrokeColor3 = color(20, 60, 100)

			if not parent:GetAttribute("SkinHubFontGuard") then
				parent:SetAttribute("SkinHubFontGuard", true)
				local flag = false

				parent:GetPropertyChangedSignal("FontFace"):Connect(function()
					if flag then
						return
					end

					if parent.FontFace ~= font then
						flag = true
						parent.FontFace = font
						flag = false
					end
				end)

				task.spawn(function()
					while parent and parent.Parent do
						if parent.FontFace ~= font then
							parent.FontFace = font
						end

						task.wait(0.15)
					end
				end)
			end

			if parent.FontFace ~= font then
				parent.FontFace = font
			end

			if parent.Text == "Skin HUB v4.2" and not parent:GetAttribute("SkinHubTitleFX") then
				parent:SetAttribute("SkinHubTitleFX", true)
				local uiGradient = Instance.new("UIGradient")
				local colorSequence = ColorSequence.new
				local tbl6 = {}
				local v20 = ColorSequenceKeypoint.new(0, color(120, 220, 255))
				local v21 = ColorSequenceKeypoint.new(0.35, color(200, 245, 255))
				local new = ColorSequenceKeypoint.new
				local v22 = ColorSequenceKeypoint.new(0.65, color(140, 220, 255))
				tbl6[1] = v20
				tbl6[2] = v21
				tbl6[3] = v22

				do
					local values = table.pack(new(1, color(120, 220, 255)))
					table.move(values, 1, values.n, 4, tbl6)
				end

				uiGradient.Color = colorSequence(tbl6)
				uiGradient.Parent = parent

				task.spawn(function()
					local now = os.clock()

					while parent and parent.Parent do
						uiGradient.Rotation = (os.clock() - now) * 60 % 360
						v5.RenderStepped:Wait()
					end
				end)
			end
		end
	end

	for _, v20 in screenGui2:GetDescendants() do
		pcall(fn8, v20)
	end

	screenGui2.DescendantAdded:Connect(function(descendant)
		task.defer(function()
			pcall(fn8, descendant)
		end)
	end)

	task.defer(function()
		for _, v20 in screenGui2:GetDescendants() do
			if v20:IsA("Frame") and v20.Size.X.Offset >= 400 and v20.Size.Y.Offset >= 180 then
				local uiStroke2 = v20:FindFirstChildOfClass("UIStroke")

				if uiStroke2 then
					uiStroke2.Color = v15
					uiStroke2.Thickness = 1.5
					uiStroke2.Transparency = 0.4

					task.spawn(function()
						while v20 and v20.Parent do
							uiStroke2.Transparency = 0.25 + (math.sin(os.clock() * 1.8) + 1) * 0.5 * 0.35
							task.wait(0.05)
						end
					end)
				end

				break
			end
		end
	end)

	local n2 = 0
	local n3 = 90
	local flag = false
	local flag2 = false

	task.spawn(function()
		local tbl6 = {
			{ 0, "Skin HUB v4.2", "正在启动..." },
			{ 15, "初始化界面", "准备 UI 资源..." },
			{ 35, "加载模块", "解析脚本模块..." },
			{ 55, "构建功能", "注册自动化任务..." },
			{ 75, "应用主题", "调整配色与字体..." },
			{ 85, "收尾工作", "检查依赖..." },
		}

		local n4 = 1

		while not flag and n2 < n3 do
			if n4 <= #tbl6 and n2 >= tbl6[n4][1] then
				v14:SetMessage(tbl6[n4][2])
				v14:SetDescription(tbl6[n4][3])
				n4 += 1
			end

			n2 = math.min(n2 + math.random(2, 4), 90)
			v14:SetCurrentStep(n2)
			task.wait(0.05)
		end

		v14:SetCurrentStep(90)
		v14:SetMessage("请选择语言")
		v14:SetDescription("Please select your language")
		pcall(__StyleLoadingDesc)
	end)

	__FinishLoading = function()
		if flag2 then
			return
		end
		flag2 = true
		flag = true
		tbl.destroyBootLanguagePicker()

		task.spawn(function()
			if tbl.bootLanguagePicked and options and options.InterfaceLanguage then
				pcall(function()
					options.InterfaceLanguage:SetValue(tbl.bootLanguage)
				end)

				pcall(function()
					SetInterfaceLanguage(tbl.bootLanguage)
				end)
			end

			task.wait(0.15)
			v14:SetMessage("加载完成")
			v14:SetDescription("Loading complete")
			pcall(__StyleLoadingDesc)

			while n2 < n do
				n2 = math.min(n2 + 2, 100)
				v14:SetCurrentStep(n2)
				task.wait(0.03)
			end

			task.wait(0.4)
			local screenGui3 = Instance.new("ScreenGui")
			screenGui3.Name = "SkinHubFadeOverlay"
			screenGui3.DisplayOrder = 2147483647
			screenGui3.IgnoreGuiInset = true
			screenGui3.ResetOnSpawn = false

			if not pcall(function()
				screenGui3.Parent = v(game:GetService("CoreGui"))
			end) then
				screenGui3.Parent = v4.LocalPlayer:WaitForChild("PlayerGui")
			end

			local frame2 = Instance.new("Frame")
			frame2.BackgroundColor3 = Color3.fromRGB(8, 14, 26)
			frame2.BackgroundTransparency = 1
			frame2.Size = UDim2.fromScale(1, 1)
			frame2.BorderSizePixel = 0
			frame2.ZIndex = 1
			frame2.Parent = screenGui3
			local tween = v8:Create(frame2, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
			tween:Play()
			tween.Completed:Wait()
			v14:Continue()
			task.wait(0.15)
			local tween2 = v8:Create(frame2, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
			tween2:Play()
			tween2.Completed:Wait()
			screenGui3:Destroy()

			pcall(function()
				v(game:GetService("StarterGui")):SetCore("SendNotification", { Title = "Skin HUB v4.2", Text = format("已加载，耗时 %.2f 秒", clock() - v12), Duration = 5 })
			end)
		end)
	end

	lib.Scheme = {
		BackgroundColor = Color3.new(0, 0, 0),
		MainColor = color(20, 50, 90),
		AccentColor = color(80, 200, 255),
		OutlineColor = color(100, 180, 255),
		FontColor = Color3.new(1, 1, 1),
		Font = Font.fromEnum(Enum.Font.Code),
		RedColor = color(255, 80, 80),
		DestructiveColor = color(220, 38, 38),
		DarkColor = Color3.new(0, 0, 0),
		WhiteColor = Color3.new(1, 1, 1),
		BackgroundImage = "",
	}

	local v20 = lib:CreateWindow({
		Title = "Skin HUB v4.2",
		Footer = "Created by Liuye 柳叶［Willow leaf］",
		NotifySide = "Right",
		ShowCustomCursor = true,
		CornerRadius = 6,
		TabButtonsStyle = {
			Gap = 6,
			Padding = 6,
			CornerRadius = 6,
			Indicator = true,
			IndicatorWidth = 2,
			IndicatorHeight = 20,
		},
		Icon = str2,
		IconSize = UDim2.fromOffset(44, 44),
		Animations = {
			ToggleWindow = false,
			TabSwitch = true,
			Groupbox = true,
			Dropdown = true,
			KeyPicker = true,
		},
		TabTransitionTime = 0.22,
		TabSwipeOffset = 26,
		TabSwipeFrom = "Auto",
	})

	v20:SetBackgroundImage("https://chaton-images.s3.us-east-2.amazonaws.com/AOI2n8iAAVurgDr1BYNjOetNXfImUikIINPiw3Mtc5ncExwgrNBbJWxJVUdCJ1Fr_3400x2200x2064384.jpeg")

	task.defer(function()
		local screenGui3 = lib.ScreenGui
		if not screenGui3 then
			return
		end

		for _, v21 in screenGui3:GetDescendants() do
			if v21:IsA("ImageLabel") and v21.ScaleType == Enum.ScaleType.Stretch and v21.BackgroundTransparency == 1 and v21.Size == UDim2.fromScale(1, 1) then
				v21.ImageTransparency = 1
				break
			end
		end
	end)

	lib.IsMobile = true

	for _, v21 in lib.Floats:GetChildren() do
		if v21:IsA("TextButton") then
			if v21.Text == "Toggle" then
				v21.Text = "Skin v4.2"
				v21.TextColor3 = Color3.new(1, 1, 1)
				v21.TextSize = 13
				v21.FontFace = Font.fromEnum(Enum.Font.SciFi)
				v21.Size = UDim2.new(0, 55, 0, 55)
				v21.Position = UDim2.new(0.02, 0, 0.5, -120)
				v21.AnchorPoint = Vector2.new(0, 0.5)
				v21.BackgroundTransparency = 1
				local uiCorner2 = v21:FindFirstChild("UICorner")

				if not uiCorner2 then
					uiCorner2 = Instance.new("UICorner")
					uiCorner2.Parent = v21
				end

				uiCorner2.CornerRadius = UDim.new(1, 0)
				local uiGradient = v21:FindFirstChild("UIGradient")

				if uiGradient then
					uiGradient:Destroy()
				end

				local strokeOuter = v21:FindFirstChild("StrokeOuter")

				if not strokeOuter then
					strokeOuter = Instance.new("UIStroke")
					strokeOuter.Name = "StrokeOuter"
					strokeOuter.Parent = v21
				end

				strokeOuter.Thickness = 4
				strokeOuter.Transparency = 0.2
				strokeOuter.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				strokeOuter.Color = color(0, 110, 180)
				local strokeInner = v21:FindFirstChild("StrokeInner")

				if not strokeInner then
					strokeInner = Instance.new("UIStroke")
					strokeInner.Name = "StrokeInner"
					strokeInner.Parent = v21
				end

				strokeInner.Thickness = 2
				strokeInner.Transparency = 0
				strokeInner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				strokeInner.Color = color(220, 250, 255)
				v21.TextStrokeColor3 = color(20, 60, 100)
				v21.TextStrokeTransparency = 0.35
				local font2 = Font.fromEnum(Enum.Font.SciFi)
				local flag3 = false

				v21:GetPropertyChangedSignal("FontFace"):Connect(function()
					if flag3 then
						return
					end

					if v21.FontFace ~= font2 then
						flag3 = true
						v21.FontFace = font2
						flag3 = false
					end
				end)

				task.spawn(function()
					while v21 and v21.Parent do
						if v21.FontFace ~= font2 then
							v21.FontFace = font2
						end

						task.wait(0.2)
					end
				end)

				task.spawn(function()
					while v21 and v21.Parent do
						local n4 = (math.sin(clock2() * 2.2) + 1) * 0.5
						strokeOuter.Transparency = 0.1 + n4 * 0.3
						strokeInner.Transparency = 0.3 + n4 * 0.4
						task.wait(0.05)
					end
				end)

				local flag4 = false
				local flag5 = false
				local flag6 = false
				local tween = nil

				local function fn9()
					if tween then
						tween:Cancel()
					end

					local n4

					if flag6 then
						n4 = 68
					elseif flag5 then
						n4 = 48
					elseif flag4 then
						n4 = 62
					else
						n4 = 55
					end

					tween = v8:Create(v21, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, n4, 0, n4) })
					tween:Play()
				end

				v21.MouseEnter:Connect(function()
					flag4 = true
					fn9()
				end)

				v21.MouseLeave:Connect(function()
					flag4 = false
					fn9()
				end)

				local position = nil
				local n4 = 5

				v21.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						flag5 = true
						position = input.Position
						fn9()
					end
				end)

				v21.InputChanged:Connect(function(input)
					if not flag5 or not position then
						return
					end

					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if (input.Position - position).Magnitude > n4 and not flag6 then
							flag6 = true
							fn9()
						end
					end
				end)

				v6.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						flag5 = false
						flag6 = false
						position = nil
						fn9()
					end
				end)
			end

			if v21.Text == "Lock" then
				v21.Visible = false
			end
		end
	end

	str = "中文"
	tbl2 = {}

	pcall(function()
		local response = game:HttpGet("https://raw.githubusercontent.com/Zephyrastic/Translations/main/translations/en.json")
		local data = v2:JSONDecode(response)
		if typeof(data) ~= "table" then
			return
		end

		for k, v21 in data, nil, nil do
			if typeof(k) == "string" and typeof(v21) == "string" and v21 ~= "" then
				tbl2[k] = v21
			end
		end
	end)

	local obj = setmetatable({}, { __mode = "k" })
	local tbl6 = {}

	pcall(function()
		local response = game:HttpGet("https://raw.githubusercontent.com/Zephyrastic/Translations/main/translations/en-fragments.json")
		local data = v2:JSONDecode(response)
		if typeof(data) ~= "table" then
			return
		end

		for k, v21 in data, nil, nil do
			if typeof(k) == "string" and typeof(v21) == "string" and v21 ~= "" then
				tbl6[k] = v21
			end
		end
	end)

	fn3 = function(arg)
		if str ~= "English" then
			return arg
		end

		if tbl2[arg] then
			return tbl2[arg]
		end

		if type(arg) ~= "string" then
			return arg
		end
		local v21 = arg:byte(1)
		if v21 and v21 < 128 then
			return arg
		end

		for k, v22 in tbl6, nil, nil do
			arg = string.gsub(arg, k, v22)
		end

		return arg
	end

	fn4 = function(arg)
		return fn3(arg)
	end

	local tbl7 = {}

	for k, v21 in tbl2, nil, nil do
		tbl7[v21] = k
	end

	local function fn9(arg)
		if tbl7[arg] then
			return tbl7[arg]
		end
		return arg
	end

	local function fn10()
		local screenGui3 = lib and lib.ScreenGui
		if not screenGui3 then
			return false
		end
		local flag3 = false

		for _, v21 in screenGui3:GetChildren() do
			if v21:IsA("TextLabel") and v21:FindFirstChildOfClass("UIPadding") and v21:FindFirstChildOfClass("UIStroke") and v21:FindFirstChildOfClass("UICorner") and not v21:GetAttribute("SkinHubTooltipHook") then
				v21:SetAttribute("SkinHubTooltipHook", true)
				local flag4 = false

				v21:GetPropertyChangedSignal("Text"):Connect(function()
					if flag4 then
						return
					end
					local text = v21.Text
					if type(text) ~= "string" or text == "" then
						return
					end

					if str == "English" then
						local v22 = fn3(text)

						if v22 ~= text then
							flag4 = true
							v21.Text = v22
							flag4 = false
						end
					elseif string.byte(text, 1) and string.byte(text, 1) < 128 then
						local v22 = fn9(text)

						if v22 ~= text then
							flag4 = true
							v21.Text = v22
							flag4 = false
						end
					end
				end)

				flag3 = true
			end
		end

		return flag3
	end

	local function fn11(arg)
		if arg:GetAttribute("SkinHubLiveTranslate") then
			return
		end
		arg:SetAttribute("SkinHubLiveTranslate", true)
		local flag3 = false

		arg:GetPropertyChangedSignal("Text"):Connect(function()
			if flag3 then
				return
			end
			local text = arg.Text
			if type(text) ~= "string" or text == "" then
				return
			end

			if str ~= "English" then
				return
			end
			local text2 = tbl2[text]

			if not text2 then
				local v21 = string.split(text, ", ")
				local flag4 = #v21 > 1

				for _, v22 in v21, nil, nil do
					if not tbl2[v22] then
						flag4 = false
						break
					end
				end

				if flag4 then
					local tbl8 = {}

					for _, v22 in v21, nil, nil do
						tbl8[#tbl8 + 1] = tbl2[v22]
					end

					text2 = table.concat(tbl8, ", ")
				end
			end

			if text2 and text2 ~= text then
				flag3 = true
				arg.Text = text2
				flag3 = false
			end
		end)

		if arg:IsA("TextBox") then
			arg:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
				if flag3 then
					return
				end
				local placeholderText = arg.PlaceholderText
				if type(placeholderText) ~= "string" or placeholderText == "" then
					return
				end

				if str ~= "English" then
					return
				end
				local v21 = tbl2[placeholderText]

				if v21 and v21 ~= placeholderText then
					flag3 = true
					arg.PlaceholderText = v21
					flag3 = false
				end
			end)
		end
	end

	local function fn12()
		local screenGui3 = lib and lib.ScreenGui
		if not screenGui3 then
			return false
		end

		if screenGui3:GetAttribute("SkinHubLiveTranslateRoot") then
			return true
		end
		screenGui3:SetAttribute("SkinHubLiveTranslateRoot", true)

		screenGui3.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				fn11(descendant)
			end
		end)

		for _, v21 in screenGui3:GetDescendants() do
			if v21:IsA("TextLabel") or v21:IsA("TextButton") or v21:IsA("TextBox") then
				fn11(v21)
			end
		end

		return true
	end

	task.spawn(function()
		local flag3 = false

		for i = 1, 100 do
			flag3 = flag3 or fn10()
			if not (flag3 and fn12()) then
				task.wait(0.2)
				continue
			end
			break
		end

		while not fn12() do
			task.wait(0.5)
		end
	end)

	local function fn13()
		local tbl8 = {}

		if lib and lib.ScreenGui then
			table.insert(tbl8, lib.ScreenGui)
		end

		local playerGui2 = localPlayer:FindFirstChildOfClass("PlayerGui")

		if playerGui2 then
			table.insert(tbl8, playerGui2)
		end

		if v13 then
			table.insert(tbl8, v13)
		end

		return tbl8
	end

	local function fn14(arg)
		if lib and lib.ScreenGui then
			if arg == lib.ScreenGui or arg:IsDescendantOf(lib.ScreenGui) then
				return false
			end
		end

		for i = 1, 20 do
			if not arg then
				return false
			end

			if arg.Name == "RobloxGui" then
				return true
			end
			arg = arg.Parent
		end

		return false
	end

	local function fn15(arg)
		return arg:IsA("TextLabel") or arg:IsA("TextButton") or arg:IsA("TextBox")
	end

	local function fn16(arg, arg2)
		if typeof(arg.Text) ~= "string" then
			return
		end
		local text = fn9(arg.Text)
		obj[arg] = text
		text = arg2 == "English" and fn3(text) or text

		if arg.Text ~= text then
			arg.Text = text
		end
	end

	fn5 = function(arg)
		str = arg

		for _, v21 in fn13() do
			for _, v22 in v21:GetDescendants() do
				if fn15(v22) and not fn14(v22) then
					fn16(v22, arg)
				end
			end
		end

		if options.PvpAimPart then
			options.PvpAimPart:SetValue(options.PvpAimPart.Value)
		end

		if options.AutoRepairMode then
			options.AutoRepairMode:SetValue(options.AutoRepairMode.Value)
		end

		if options.AuraMode then
			options.AuraMode:SetValue(options.AuraMode.Value)
		end
	end

	task.defer(function()
		local tbl8 = {}
		local flag3 = false

		local function fn17()
			flag3 = false
			if str ~= "English" then
				table.clear(tbl8)
				return
			end

			for k in tbl8, nil, nil do
				if k.Parent and fn15(k) and not fn14(k) then
					fn16(k, str)
				end
			end

			table.clear(tbl8)
		end

		for _, v21 in fn13() do
			v21.DescendantAdded:Connect(function(descendant)
				if str ~= "English" then
					return
				end

				if not fn15(descendant) then
					return
				end
				tbl8[descendant] = true

				if not flag3 then
					flag3 = true
					task.defer(fn17)
				end
			end)
		end
	end)

	tbl3 = {
		Home = v20:AddTab("主页", "house"),
		Main = v20:AddTab("主要与杀戮", "sword"),
		Auto = v20:AddTab("其他与透视", "eye"),
		Minor = v20:AddTab("防护功能", "shield"),
		Anims = v20:AddTab("动画包", "film"),
		AutoFunc = v20:AddTab("自动与PVP", "zap"),
		Extra = v20:AddTab("职业功能", "users"),
		LocalPlayer = v20:AddTab("本地玩家", "user"),
		Misc = v20:AddTab("杂项", "layout-grid"),
		Settings = v20:AddTab("设置", "settings"),
	}
end

do
	local v12 = tbl3.Home:AddGroupbox({ Side = "Left", Name = "用户", IconName = "user", Description = "账号信息" })
	local v13 = tbl3.Home:AddGroupbox({ Side = "Right", Name = "会话", IconName = "clock", Description = "在线状态" })
	local v14 = localPlayer
	local v15 = clock()

	local function fn6(arg, arg2)
		return str == "English" and arg2 or arg
	end

	local str2 = "Unknown"

	pcall(function()
		if identifyexecutor then
			str2 = identifyexecutor()
		end
	end)

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 1, 0)
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Avatar"
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.Size = UDim2.new(0, 96, 0, 96)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxasset://textures/ui/iconAssetMissing.png"
	imageLabel.ScaleType = Enum.ScaleType.Crop
	imageLabel.BorderColor3 = color(0, 0, 0)
	imageLabel.Parent = frame

	task.spawn(function()
		local ok, image = pcall(function()
			return v4:GetUserThumbnailAsync(v14.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)

		if ok and image and image ~= "" and imageLabel and imageLabel.Parent then
			imageLabel.Image = image
		end
	end)

	v12:AddUIPassthrough("HomeAvatar", { Instance = frame, Height = 110 })
	local name = v14.Name
	local v16 = v12:AddLabel(("%s: %s"):format(fn6("用户名", "Username"), name))
	local userId = v14.UserId
	local v17 = v12:AddLabel(("%s: %d"):format(fn6("用户ID", "UserId"), userId))
	local v18 = v12:AddLabel(("%s: %s"):format(fn6("执行器", "Executor"), str2))
	local addLabel = v12.AddLabel
	local format2 = ("%s: 00:00:00").format
	local v19 = fn6("会话时间", "Session Time")
	local v20 = addLabel(v12, format2("%s: 00:00:00", v19))

	v12:AddButton({
		Text = "复制用户名",
		Func = function()
			pcall(function()
				setclipboard(v14.Name)
			end)
		end,
	})

	v12:AddButton({
		Text = "复制个人资料链接",
		Func = function()
			pcall(function()
				setclipboard(("https://www.roblox.com/users/%d/profile"):format(v14.UserId))
			end)
		end,
	})

	local v21 = tbl3.Home:AddGroupbox({ Side = "Left", Name = "信息", IconName = "info", Description = "版本信息" })
	v21:AddLabel("师傅：小皮")
	v21:AddLabel("英文翻译：Zephy")
	v21:AddLabel("脚本优化：Zephy")
	local str3 = "Unknown"

	pcall(function()
		local productInfo = v11:GetProductInfo(game.PlaceId)

		if productInfo and productInfo.Name then
			str3 = productInfo.Name
		end
	end)

	local v22 = v4
	local v23 = v13:AddLabel(("%s: %s"):format(fn6("游戏", "Game"), str3))
	local maxPlayers = v22.MaxPlayers
	local v24 = v13:AddLabel(("%s: %d/%d"):format(fn6("玩家", "Players"), #v22:GetPlayers(), maxPlayers))
	v13:AddLabel(("JobId: %s"):format(game.JobId ~= "" and game.JobId:sub(1, 8) .. "..." or "Studio"))
	local addLabel2 = v13.AddLabel
	local format3 = ("%s: 0 ms").format
	local v25 = fn6("延迟", "Ping")
	local v26 = addLabel2(v13, format3("%s: 0 ms", v25))

	v13:AddButton({
		Text = "重新加入服务器",
		Func = function()
			pcall(function()
				v3:TeleportToPlaceInstance(game.PlaceId, game.JobId, v14)
			end)
		end,
	})

	v13:AddButton({
		Text = "复制 Job ID",
		Func = function()
			pcall(function()
				setclipboard(game.JobId)
			end)
		end,
	})

	task.spawn(function()
		while true do
			local v27 = floor(clock() - v15)
			local v28 = floor(v27 / 3600)
			local v29 = floor(v27 % 3600 / 60)
			local n = v27 % 60

			pcall(function()
				local name2 = v14.Name
				v16:SetText(("%s: %s"):format(fn6("用户名", "Username"), name2))
				local userId2 = v14.UserId
				v17:SetText(("%s: %d"):format(fn6("用户ID", "UserId"), userId2))
				v18:SetText(("%s: %s"):format(fn6("执行器", "Executor"), str2))
				v23:SetText(("%s: %s"):format(fn6("游戏", "Game"), str3))
				v20:SetText(("%s: %02d:%02d:%02d"):format(fn6("会话时间", "Session Time"), v28, v29, n))
				local maxPlayers2 = v22.MaxPlayers
				v24:SetText(("%s: %d/%d"):format(fn6("玩家", "Players"), #v22:GetPlayers(), maxPlayers2))
				local v30 = floor(v10.Network.ServerStatsItem["Data Ping"]:GetValue())
				v26:SetText(("%s: %d ms"):format(fn6("延迟", "Ping"), v30))
			end)

			task.wait(1)
		end
	end)
end

do
	local v12 = tbl3.Misc:AddGroupbox({ Side = "Left", Name = "杂项功能", IconName = "layout-grid", Description = "视野辅助" })
	local v13 = tbl3.Misc:AddGroupbox({ Side = "Right", Name = "娱乐功能", IconName = "party-popper", Description = "趣味效果" })

	v13:AddToggle("RollTiltToggle", {
		Text = "我好像有点卡顿",
		Default = false,
		Tooltip = fn4("让人物看起来卡卡的"),
		Callback = function(arg)
			if arg then
				tbl.rollTiltStart()
			else
				tbl.rollTiltStop()
			end
		end,
	})

	v13:AddSlider("RollTiltSpeed", {
		Text = "卡顿程度",
		Default = 3,
		Min = 1,
		Max = 10,
		Suffix = " 级",
		Callback = function(rollTiltSpeed)
			tbl.rollTiltSpeed = rollTiltSpeed
		end,
	})

	v13:AddToggle("SpinToggle", {
		Text = "旋转",
		Default = false,
		Tooltip = fn4("让人物持续旋转"),
		Callback = function(enabled)
			tbl.spin.enabled = enabled

			if enabled then
				tbl.spin.start()
			else
				tbl.spin.stop()
			end
		end,
	})

	v13:AddSlider("SpinSpeed", {
		Text = "旋转速度",
		Default = 5,
		Min = 1,
		Max = 30,
		Suffix = " 级",
		Callback = function(speed)
			tbl.spin.speed = speed
		end,
	})

	v13:AddToggle("ThirdPersonToggle", {
		Text = "解除视角限制",
		Default = false,
		Tooltip = fn4("解除玩家视角上限"),
		Callback = function(arg)
			if arg then
				tbl.thirdPerson.start()
			else
				tbl.thirdPerson.stop()
			end
		end,
	})

	v13:AddToggle("AnimFreezeToggle", {
		Text = "人体十字架",
		Default = false,
		Tooltip = fn4("化身成人体十字架"),
		Callback = function(arg)
			if arg then
				tbl.animFreeze.start()
			else
				tbl.animFreeze.stop()
			end
		end,
	})

	v13:AddToggle("InvertToggle", {
		Text = "倒立行走",
		Default = false,
		Tooltip = fn4("让玩家倒立"),
		Callback = function(arg)
			tbl.invert.setEnabled(arg)
		end,
	})

	v13:AddToggle("BigHeadToggle", {
		Text = "大头儿子",
		Default = false,
		Tooltip = fn4("所有僵尸变成大头儿子"),
		Callback = function(arg)
			if arg then
				tbl.bigHead.enable()
			else
				tbl.bigHead.disable()
			end
		end,
	})

	v13:AddSlider("BigHeadSize", {
		Text = "头部大小",
		Default = 3,
		Min = 1,
		Max = 10,
		Suffix = " 倍",
		Callback = function(headSize)
			tbl.bigHead.headSize = headSize

			if tbl.bigHead.enabled then
				tbl.bigHead.updateAllZombies()
			end
		end,
	})

	v13:AddSlider("BigHeadTrans", {
		Text = "头部透明度",
		Default = 5,
		Min = 1,
		Max = 10,
		Suffix = " 级",
		Callback = function(arg)
			tbl.bigHead.headTrans = arg / 10

			if tbl.bigHead.enabled then
				tbl.bigHead.updateAllZombies()
			end
		end,
	})

	v13:AddToggle("AnimLoop1205Toggle", {
		Text = "自己猜🤓",
		Default = false,
		Tooltip = fn4("自己猜🤓"),
		Callback = function(animLoop1205Enabled)
			tbl.animLoop1205Enabled = animLoop1205Enabled

			if animLoop1205Enabled then
				tbl.startAnimLoop1205()
			else
				tbl.stopAnimLoop1205()
			end
		end,
	})

	v12:AddButton({
		Text = "删除帽子",
		Func = function()
			tbl.removeAllHats()
		end,
	})

	v12:AddButton({
		Text = "删除上衣",
		Func = function()
			tbl.removeAllShirts()
		end,
	})

	v12:AddButton({
		Text = "删除裤子",
		Func = function()
			tbl.removeAllPants()
		end,
	})

	v12:AddButton({
		Text = "一键删除以上全部",
		Func = function()
			tbl.removeAllHats()
			tbl.removeAllShirts()
			tbl.removeAllPants()
		end,
	})

	v12:AddButton({
		Text = "移除马车模型",
		Func = function()
			tbl.removeCarriages()
		end,
	})

	v12:AddButton({
		Text = "降低画质 <font color=\"rgb(255,0,0)\">（不可恢复）</font>",
		Func = function()
			local terrain = workspace.Terrain

			pcall(function()
				sethiddenproperty(v9, "Technology", 2)
				sethiddenproperty(terrain, "Decoration", false)
			end)

			terrain.WaterWaveSize = 0
			terrain.WaterWaveSpeed = 0
			terrain.WaterReflectance = 0
			terrain.WaterTransparency = 0
			v9.GlobalShadows = false
			v9.FogEnd = 9e9
			v9.Brightness = 0

			pcall(function()
				local level01 = Enum.QualityLevel.Level01
				settings().Rendering.QualityLevel = level01
			end)

			for _, descendant in pairs(workspace:GetDescendants()) do
				if descendant:IsA("BasePart") and not descendant:IsA("MeshPart") then
					descendant.Material = "Plastic"
					descendant.Reflectance = 0
				elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
					descendant.Transparency = 1
				elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
					descendant.Lifetime = NumberRange.new(0)
				elseif descendant:IsA("Explosion") then
					descendant.BlastPressure = 1
					descendant.BlastRadius = 1
				elseif descendant:IsA("Fire") or descendant:IsA("SpotLight") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
					descendant.Enabled = false
				elseif descendant:IsA("MeshPart") then
					descendant.Material = "Plastic"
					descendant.Reflectance = 0
				elseif descendant:IsA("SpecialMesh") then
					descendant.TextureId = ""
				elseif descendant:IsA("ShirtGraphic") then
					descendant.Graphic = ""
				end
			end

			for _, child in pairs(v9:GetChildren()) do
				if child:IsA("BlurEffect") or child:IsA("SunRaysEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("BloomEffect") or child:IsA("DepthOfFieldEffect") then
					child.Enabled = false
				end
			end
		end,
	})

	v12:AddSlider("WaveSkipCount", {
		Text = "波次数",
		Default = 1,
		Min = 1,
		Max = 100,
		Rounding = 0,
		Callback = function(waveNum)
			tbl.waveNum = waveNum
		end,
	})

	v12:AddButton({
		Text = "跳过 N 波",
		Func = function()
			tbl.sendChatCmd("/skipwave " .. tbl.waveNum)
		end,
	})

	tbl.Bright = { Enabled = false, OriginalLighting = nil }

	v12:AddToggle("BrightToggle", {
		Text = "亮度提升",
		Default = false,
		Tooltip = fn4("提高场景亮度"),
		Callback = function(arg)
			local v14 = v9

			if arg then
				if not tbl.Bright.OriginalLighting then
					tbl.Bright.OriginalLighting = {
						ClockTime = v14.ClockTime,
						Ambient = v14.Ambient,
						GlobalShadows = v14.GlobalShadows,
						OutdoorAmbient = v14.OutdoorAmbient,
					}
				end

				v14.ClockTime = 14
				v14.Ambient = color(255, 255, 255)
				v14.GlobalShadows = false
				v14.OutdoorAmbient = color(255, 255, 255)
				tbl.Bright.Enabled = true
			else
				if tbl.Bright.OriginalLighting then
					v14.ClockTime = tbl.Bright.OriginalLighting.ClockTime
					v14.Ambient = tbl.Bright.OriginalLighting.Ambient
					v14.GlobalShadows = tbl.Bright.OriginalLighting.GlobalShadows
					v14.OutdoorAmbient = tbl.Bright.OriginalLighting.OutdoorAmbient
				end

				tbl.Bright.Enabled = false
			end
		end,
	})

	v12:AddToggle("NoFogToggle", {
		Text = "无雾效果",
		Default = false,
		Tooltip = fn4("移除雾效与大气效果，并在地图切换后自动重新应用"),
		Callback = function(noFogEnabled)
			tbl.noFogEnabled = noFogEnabled

			if noFogEnabled then
				tbl.applyNoFog()
				tbl.startNoFogMonitor()
			else
				tbl.stopNoFogMonitor()
				tbl.restoreNoFog()
			end
		end,
	})
end

local v12 = tbl3.Misc:AddGroupbox({ Side = "Left", Name = "娱乐", IconName = "smile", Description = "一键操作" })
tbl.oneClick = tbl.oneClick or {}
tbl.oneClick.ui = nil
tbl.oneClick.VALID_WEAPONS = { Carbine = true, Axe = true, Pickaxe = true }

tbl.oneClick.getCurrentWeapon = function()
	local character = localPlayer.Character
	if not character then
		return nil
	end

	for _, v13 in character:GetChildren() do
		if v13:IsA("Tool") then
			if tbl.oneClick.VALID_WEAPONS[v13.Name] then
				if v13:FindFirstChild("RemoteEvent") then
					return v13
				end
			end
		end
	end

	return nil
end

tbl.oneClick.collectTargets = function()
	local tbl4 = {}

	for _, v13 in workspace:GetDescendants() do
		if v13.Name == "DoorHit" or v13.Name == "BreakGlass" then
			table.insert(tbl4, v13)
		end
	end

	pcall(function()
		if getnilinstances then
			for _, v13 in getnilinstances() do
				if v13.Name == "DoorHit" or v13.Name == "BreakGlass" then
					table.insert(tbl4, v13)
				end
			end
		end
	end)

	local tbl5 = {}
	local tbl6 = {}

	for _, v13 in tbl4, nil, nil do
		if not tbl5[v13] then
			tbl5[v13] = true
			table.insert(tbl6, v13)
		end
	end

	return tbl6
end

tbl.oneClick.getTargetPosition = function(arg)
	if arg:IsA("BasePart") then
		return arg.Position
	end

	if arg:IsA("Attachment") then
		return arg.WorldPosition
	end

	if arg.Parent and arg.Parent:IsA("BasePart") then
		return arg.Parent.Position
	end

	if arg.Parent and arg.Parent.Parent and arg.Parent.Parent:IsA("BasePart") then
		return arg.Parent.Parent.Position
	end
	return Vector3.zero
end

tbl.oneClick.execute = function()
	local v13 = tbl.oneClick.getCurrentWeapon()
	if not v13 then
		lib:Notify(fn3("请手持卡宾枪/稿子/斧头"), 2)
		return
	end
	local remoteEvent = v13:FindFirstChild("RemoteEvent")
	if not remoteEvent then
		return
	end
	local v14 = tbl.oneClick.collectTargets()
	if #v14 == 0 then
		return
	end

	pcall(function()
		remoteEvent:FireServer("BraceBlock")
		task.wait(0.08)
		remoteEvent:FireServer("StopBraceBlock")
		task.wait(0.05)

		for _, v15 in v14, nil, nil do
			local v16 = tbl.oneClick.getTargetPosition(v15)
			remoteEvent:FireServer("FeedbackStunObject", v15, v16)
			task.wait(0.003)
		end
	end)
end

tbl.oneClick.createUI = function()
	if tbl.oneClick.ui then
		tbl.oneClick.ui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OneClick"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
	local textButton = Instance.new("TextButton")
	textButton.Size = UDim2.new(0, 60, 0, 60)
	textButton.Position = UDim2.new(0.5, -30, 0.45, 0)
	textButton.BackgroundColor3 = color(30, 30, 40)
	textButton.BackgroundTransparency = 0.2
	textButton.BorderSizePixel = 0
	textButton.Text = "拆"
	textButton.TextColor3 = color(255, 255, 255)
	textButton.TextSize = 24
	textButton.Font = Enum.Font.GothamBold
	textButton.Parent = screenGui
	textButton.Active = true
	textButton.Draggable = true
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = textButton
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Parent = textButton
	uiStroke.Color = color(100, 200, 255)
	uiStroke.Thickness = 2.5
	uiStroke.Transparency = 0.3
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tbl.oneClick.ui = screenGui

	textButton.MouseButton1Click:Connect(function()
		task.spawn(tbl.oneClick.execute)
	end)
end

tbl.flyAway = { isEnabled = false, connections = {}, toggleBtn = nil, screenGui = nil }

tbl.flyAway.SafeGetCharacter = function(arg)
	if not arg then
		return nil
	end
	local character = arg.Character
	if not character or not character.Parent then
		return nil
	end
	return character
end

tbl.flyAway.SafeGetHumanoid = function(arg)
	if not arg then
		return nil
	end
	return arg:FindFirstChildOfClass("Humanoid")
end

tbl.flyAway.SafeGetHRP = function(arg)
	if not arg then
		return nil
	end
	return arg:FindFirstChild("HumanoidRootPart")
end

tbl.flyAway.UpdateButton = function()
	if not tbl.flyAway.toggleBtn then
		return
	end

	if tbl.flyAway.isEnabled then
		tbl.flyAway.toggleBtn.Text = "关"
		tbl.flyAway.toggleBtn.BackgroundColor3 = color(200, 80, 80)
	else
		tbl.flyAway.toggleBtn.Text = "碰"
		tbl.flyAway.toggleBtn.BackgroundColor3 = color(30, 30, 40)
	end
end

tbl.flyAway.ToggleCore = function(isEnabled)
	tbl.flyAway.isEnabled = isEnabled

	for _, v13 in tbl.flyAway.connections, nil, nil do
		if v13 then
			pcall(function()
				v13:Disconnect()
			end)
		end
	end

	tbl.flyAway.connections = {}

	if tbl.flyAway.isEnabled then
		local connection = v5.Stepped:Connect(function()
			if not tbl.flyAway.isEnabled then
				return
			end
			local v13 = tbl.flyAway.SafeGetCharacter(localPlayer)
			local v14 = tbl.flyAway.SafeGetHumanoid(v13)
			local v15 = tbl.flyAway.SafeGetHRP(v13)

			if v14 and v15 then
				pcall(function()
					v14.PlatformStand = false
					v14.Sit = false
					v14.AutoRotate = true
					local state = v14:GetState()

					if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
						v14:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			end

			if tbl.flyAway.isEnabled then
				for _, v16 in v4:GetPlayers() do
					if v16 ~= localPlayer then
						local v17 = tbl.flyAway.SafeGetCharacter(v16)

						if v17 then
							for _, v18 in v17:GetDescendants() do
								if v18:IsA("BasePart") then
									pcall(function()
										v18.CanCollide = false
									end)
								end
							end
						end
					end
				end
			end
		end)

		table.insert(tbl.flyAway.connections, connection)

		local connection2 = v5.Heartbeat:Connect(function()
			if not tbl.flyAway.isEnabled then
				return
			end
			local v13 = tbl.flyAway.SafeGetCharacter(localPlayer)
			local v14 = tbl.flyAway.SafeGetHRP(v13)
			local v15 = tbl.flyAway.SafeGetHumanoid(v13)

			if v15 and v14 then
				pcall(function()
					local assemblyLinearVelocity = v14.AssemblyLinearVelocity
					v15:ChangeState(Enum.HumanoidStateType.Running)
					local y = assemblyLinearVelocity.Y

					if y > 35 then
						y = 35
					end

					if y < -40 then
						y = -40
					end

					v14.AssemblyAngularVelocity = Vector3.new(1350, 1350, 1350)
					v14.AssemblyLinearVelocity = vector(assemblyLinearVelocity.X * 1, y, assemblyLinearVelocity.Z * 1)
					v5.RenderStepped:Wait()

					if v14 and v14.Parent then
						v14.AssemblyAngularVelocity = Vector3.zero
					end
				end)
			end
		end)

		table.insert(tbl.flyAway.connections, connection2)
	end

	tbl.flyAway.UpdateButton()
end

tbl.flyAway.CreateUI = function()
	if tbl.flyAway.screenGui then
		tbl.flyAway.screenGui:Destroy()
	end

	tbl.flyAway.screenGui = Instance.new("ScreenGui")
	tbl.flyAway.screenGui.Name = "碰UI"
	tbl.flyAway.screenGui.ResetOnSpawn = false
	tbl.flyAway.screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
	tbl.flyAway.toggleBtn = Instance.new("TextButton")
	tbl.flyAway.toggleBtn.Size = UDim2.new(0, 60, 0, 60)
	tbl.flyAway.toggleBtn.Position = UDim2.new(0.5, -30, 0.45, 0)
	tbl.flyAway.toggleBtn.BackgroundColor3 = color(30, 30, 40)
	tbl.flyAway.toggleBtn.BackgroundTransparency = 0.2
	tbl.flyAway.toggleBtn.BorderSizePixel = 0
	tbl.flyAway.toggleBtn.Text = "碰"
	tbl.flyAway.toggleBtn.TextColor3 = color(255, 255, 255)
	tbl.flyAway.toggleBtn.TextSize = 24
	tbl.flyAway.toggleBtn.Font = Enum.Font.GothamBold
	tbl.flyAway.toggleBtn.Parent = tbl.flyAway.screenGui
	tbl.flyAway.toggleBtn.Active = true
	tbl.flyAway.toggleBtn.Draggable = true
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = tbl.flyAway.toggleBtn
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = color(100, 200, 255)
	uiStroke.Thickness = 2.5
	uiStroke.Transparency = 0.3
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = tbl.flyAway.toggleBtn

	tbl.flyAway.toggleBtn.MouseButton1Click:Connect(function()
		tbl.flyAway.isEnabled = not tbl.flyAway.isEnabled
		tbl.flyAway.ToggleCore(tbl.flyAway.isEnabled)
	end)

	tbl.flyAway.UpdateButton()
end

tbl.flyAway.Start = function()
	if tbl.flyAway.screenGui and tbl.flyAway.screenGui.Parent then
		return
	end
	tbl.flyAway.CreateUI()
	tbl.flyAway.isEnabled = false
	tbl.flyAway.ToggleCore(false)
end

tbl.flyAway.Stop = function()
	if tbl.flyAway.screenGui then
		tbl.flyAway.screenGui:Destroy()
		tbl.flyAway.screenGui = nil
		tbl.flyAway.toggleBtn = nil
	end

	if tbl.flyAway.isEnabled then
		tbl.flyAway.ToggleCore(false)
	end

	for _, v13 in tbl.flyAway.connections, nil, nil do
		if v13 then
			pcall(function()
				v13:Disconnect()
			end)
		end
	end

	tbl.flyAway.connections = {}
end

v12:AddToggle("OneClickToggle", {
	Text = "打全图门窗",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.oneClick.createUI()
		elseif tbl.oneClick.ui then
			tbl.oneClick.ui:Destroy()
		end
	end,
})

v12:AddToggle("FlyAwayToggle", {
	Text = "打开甩飞快捷栏",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.flyAway.Start()
		else
			tbl.flyAway.Stop()
		end
	end,
})

tbl.invisScript = tbl.invisScript or { enabled = false, cleanup = nil }

tbl.startInvisScript = function()
	if tbl.invisScript.enabled then
		return
	end

	if type(loadstring) ~= "function" then
		tbl.notify(fn3("错误") .. ": loadstring unavailable", 2)
		return
	end

	local chunk = loadstring([[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local c = true
local h = {}
local d = Vector3.new(0, 0, 0)

local sg = Instance.new("ScreenGui")
sg.Name = "InvisFloatWindow"
sg.ResetOnSpawn = false
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 60, 0, 60)
btn.Position = UDim2.new(0.5, -30, 0.45, 0)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
btn.BackgroundTransparency = 0.2
btn.BorderSizePixel = 0
btn.Text = "关"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 18
btn.Font = Enum.Font.GothamBold
btn.Parent = sg
btn.Active = true
btn.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = btn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 200, 255)
stroke.Thickness = 2.5
stroke.Transparency = 0.3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = btn

local function updateOffset()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local head = char:FindFirstChild("Head")
    local topY = hrp.Position.Y + hrp.Size.Y * 0
    if head then
        topY = head.Position.Y + head.Size.Y * 0
    end
    local up = (topY - hrp.Position.Y) + 500
    d = Vector3.new(0, up, 0)
end

local btnConn = btn.MouseButton1Click:Connect(function()
    c = not c
    if c then
        btn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        btn.Text = "开"
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.Text = "关"
    end
end)

c = false
btn.Text = "关"
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)

local heartbeatConn = RunService.Heartbeat:Connect(function()
    if c == true and LocalPlayer.Character then
        local i = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not i then return end
        updateOffset()
        h[1] = i.CFrame
        h[2] = i.AssemblyLinearVelocity
        local j = i.CFrame + d
        i.CFrame = j
        i.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        RunService.RenderStepped:Wait()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = h[1]
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = h[2]
        end
    end
end)

local originalIndex
originalIndex = hookmetamethod(game, "__index", newcclosure(function(self, l)
    if c == true then
        if not checkcaller() then
            if l == "CFrame" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Humanoid").Health > 0 then
                if self == LocalPlayer.Character.HumanoidRootPart then
                    return (h[1] or CFrame.new()) + d
                elseif self == LocalPlayer.Character.Head then
                    local m = h[1] or CFrame.new()
                    return m + d
                end
            end
        end
    end
    return originalIndex(self, l)
end))

local renderBindName = "FakePosCamFix_" .. tostring(math.random(100000, 999999))
RunService:BindToRenderStep(
    renderBindName,
    Enum.RenderPriority.Camera.Value + 1,
    function()
        if c == true and LocalPlayer.Character then
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame - d
            end
        end
    end
)

return function()
    c = false
    if btnConn then pcall(function() btnConn:Disconnect() end) end
    if heartbeatConn then pcall(function() heartbeatConn:Disconnect() end) end
    if sg and sg.Parent then pcall(function() sg:Destroy() end) end
    pcall(function() RunService:UnbindFromRenderStep(renderBindName) end)
    if originalIndex then
        pcall(function() hookmetamethod(game, "__index", originalIndex) end)
    end
end
]])

	if not chunk then
		tbl.notify(fn3("错误") .. ": loadstring failed", 2)
		return
	end
	local ok, cleanup = pcall(chunk)

	if not ok then
		warn("[InvisScript] load error: " .. tostring(cleanup))
		tbl.notify(fn3("错误") .. ": " .. tostring(cleanup), 3)
		return
	end

	tbl.invisScript.enabled = true
	tbl.invisScript.cleanup = cleanup
end

tbl.stopInvisScript = function()
	if not tbl.invisScript.enabled then
		return
	end
	tbl.invisScript.enabled = false

	if tbl.invisScript.cleanup then
		pcall(tbl.invisScript.cleanup)
		tbl.invisScript.cleanup = nil
	end

	pcall(function()
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		playerGui = playerGui and playerGui:FindFirstChild("InvisFloatWindow")

		if playerGui then
			playerGui:Destroy()
		end
	end)
end

v12:AddToggle("InvisScriptToggle", {
	Text = "打开隐身快捷栏",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.startInvisScript()
		else
			tbl.stopInvisScript()
		end
	end,
})

local v13
v13 = tbl3.Anims:AddGroupbox({ Side = "Left", Name = "动画包", IconName = "film", Description = "姿势动画" })
local v14
v14 = tbl3.Anims:AddGroupbox({ Side = "Right", Name = "其它动画", IconName = "clapperboard", Description = "舞蹈动作" })

do
	local v15 = tbl3.AutoFunc:AddGroupbox({ Side = "Left", Name = "自动功能", IconName = "zap", Description = "自动挖拾" })
	tbl.autoDigEnabled = false
	tbl.autoDigConnection = nil

	tbl.DIGGABLE_PATHS = {
		"Vardohus Fortress/Modes/Objective/DoorSnow/Diggable",
		"Vardohus Fortress/Modes/Objective/Diggable",
		"OLD Vardohus Fortress/Modes/Objective/DigSnow/Diggable",
	}

	tbl.getDiggingTool = function()
		local character = localPlayer.Character
		if not character then
			return nil
		end

		for _, v16 in character:GetChildren() do
			if (v16.Name == "Shovel" or v16.Name == "Spade") and v16:FindFirstChild("RemoteEvent") then
				return v16
			end
		end

		for _, v16 in localPlayer.Backpack:GetChildren() do
			if (v16.Name == "Shovel" or v16.Name == "Spade") and v16:FindFirstChild("RemoteEvent") then
				return v16
			end
		end

		return nil
	end

	tbl.findValidDiggable = function()
		for _, v16 in tbl.DIGGABLE_PATHS, nil, nil do
			local tbl4 = {}

			for match in string.gmatch(v16, "[^/]+") do
				table.insert(tbl4, match)
			end

			local v17 = workspace

			for _, v18 in tbl4, nil, nil do
				v17 = v17:FindFirstChild(v18)
				if v17 then
					continue
				end
				break
			end

			if v17 then
				return v17
			end
		end

		return nil
	end

	tbl.executeDig = function()
		if not tbl.autoDigEnabled then
			return
		end
		local v16 = tbl.findValidDiggable()
		if not v16 then
			return
		end
		local v17 = tbl.getDiggingTool()
		if not v17 then
			return
		end

		if v17.Parent ~= localPlayer.Character then
			v17.Parent = localPlayer.Character
			task.wait(0.2)
		end

		local remoteEvent = v17:FindFirstChild("RemoteEvent")
		if not remoteEvent then
			return
		end

		pcall(function()
			remoteEvent:FireServer("Dig", v16, v16.Position)
		end)
	end

	tbl.autoDigLoop = function()
		while tbl.autoDigEnabled do
			tbl.executeDig()
			task.wait(0.01)
		end
	end

	tbl.toggleAutoDig = function(autoDigEnabled)
		tbl.autoDigEnabled = autoDigEnabled

		if autoDigEnabled then
			if tbl.autoDigConnection then
				task.cancel(tbl.autoDigConnection)
			end

			tbl.autoDigConnection = task.spawn(tbl.autoDigLoop)
			tbl.notify(fn3("自动挖雪已开启"), 2)
		else
			if tbl.autoDigConnection then
				task.cancel(tbl.autoDigConnection)
				tbl.autoDigConnection = nil
			end

			tbl.notify(fn3("自动挖雪已关闭"), 2)
		end
	end

	tbl.onCharacterAdded(function()
		if tbl.autoDigEnabled then
			tbl.autoDigEnabled = false

			if tbl.autoDigConnection then
				task.cancel(tbl.autoDigConnection)
				tbl.autoDigConnection = nil
			end

			local autoDigToggle = toggles.AutoDigToggle

			if autoDigToggle and autoDigToggle.SetValue then
				autoDigToggle:SetValue(false)
			end
		end
	end)

	v15:AddToggle("AutoDigToggle", {
		Text = "自动挖雪",
		Default = false,
		Tooltip = fn4("自动挖掘雪堆（需要铲子）"),
		Callback = function(arg)
			tbl.toggleAutoDig(arg)
		end,
	})

	tbl.autoCollectEnabled = false
	tbl.autoCollectConnection = nil
	tbl.activePrompts = {}
	tbl.descendantAddedConn = nil

	tbl.setupAutoCollect = function()
		if tbl.descendantAddedConn then
			tbl.descendantAddedConn:Disconnect()
		end

		for _, v16 in workspace:GetDescendants() do
			if v16:IsA("ProximityPrompt") then
				tbl.activePrompts[v16] = true
			end
		end

		tbl.descendantAddedConn = workspace.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ProximityPrompt") then
				tbl.activePrompts[descendant] = true
			end
		end)

		tbl.autoCollectConnection = v5.Heartbeat:Connect(function()
			if not tbl.autoCollectEnabled or not localPlayer.Character then
				return
			end
			local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				return
			end

			for k in tbl.activePrompts, nil, nil do
				if k and k.Parent and k:IsA("ProximityPrompt") and k.Enabled then
					local parent = k.Parent

					if parent:IsA("BasePart") then
						if (parent.Position - humanoidRootPart.Position).Magnitude <= k.MaxActivationDistance then
							pcall(function()
								fireproximityprompt(k)
							end)
						end
					end
				else
					tbl.activePrompts[k] = nil
				end
			end
		end)
	end

	tbl.toggleAutoCollect = function(autoCollectEnabled)
		tbl.autoCollectEnabled = autoCollectEnabled

		if autoCollectEnabled then
			if tbl.autoCollectConnection then
				tbl.autoCollectConnection:Disconnect()
			end

			if tbl.descendantAddedConn then
				tbl.descendantAddedConn:Disconnect()
			end

			tbl.activePrompts = {}
			tbl.setupAutoCollect()
			tbl.notify(fn3("自动收集已开启"), 2)
		else
			if tbl.autoCollectConnection then
				tbl.autoCollectConnection:Disconnect()
				tbl.autoCollectConnection = nil
			end

			if tbl.descendantAddedConn then
				tbl.descendantAddedConn:Disconnect()
				tbl.descendantAddedConn = nil
			end

			tbl.activePrompts = {}
			tbl.notify(fn3("自动收集已关闭"), 2)
		end
	end

	tbl.onCharacterAdded(function()
		if tbl.autoCollectEnabled then
			tbl.autoCollectEnabled = false

			if tbl.autoCollectConnection then
				tbl.autoCollectConnection:Disconnect()
				tbl.autoCollectConnection = nil
			end

			if tbl.descendantAddedConn then
				tbl.descendantAddedConn:Disconnect()
				tbl.descendantAddedConn = nil
			end

			tbl.activePrompts = {}
			local autoCollectToggle = toggles.AutoCollectToggle

			if autoCollectToggle and autoCollectToggle.SetValue then
				autoCollectToggle:SetValue(false)
			end
		end
	end)

	v15:AddToggle("AutoCollectToggle", {
		Text = "自动收集",
		Default = false,
		Tooltip = fn4("自动触发附近的收集提示（Kaub地图）"),
		Callback = function(arg)
			tbl.toggleAutoCollect(arg)
		end,
	})

	if not tbl.autoFeatures then
		tbl.autoFeatures = {}
	end

	tbl.autoFeatures.brickBreaker = tbl.autoFeatures.brickBreaker or {
		active = false,
		thread = nil,
		cachedMap = nil,
		cachedWall = nil,
		cachedBricks = nil,
		lastRefresh = 0,
	}

	tbl.getBrickBreakerTool = function()
		local character = localPlayer.Character
		if not character then
			return nil
		end

		for _, v16 in character:GetChildren() do
			if v16:IsA("Tool") and v16:FindFirstChild("RemoteEvent") then
				local str2 = v16.Name:lower()
				if str2:find("斧") or str2:find("锤") or str2:find("axe") or str2:find("hammer") or str2:find("sledge") or str2:find("pickaxe") then
					return v16:FindFirstChild("RemoteEvent")
				end
			end
		end

		return nil
	end

	tbl.getBrickWall = function()
		local v16 = clock()
		if v16 - tbl.autoFeatures.brickBreaker.lastRefresh < 1 and tbl.autoFeatures.brickBreaker.cachedWall then
			return tbl.autoFeatures.brickBreaker.cachedBricks or {}, tbl.autoFeatures.brickBreaker.cachedWall
		end
		tbl.autoFeatures.brickBreaker.lastRefresh = v16
		local cachedMap = tbl.autoFeatures.brickBreaker.cachedMap

		if not cachedMap or not cachedMap.Parent then
			local catacombesDeParis = workspace:FindFirstChild("Catacombes de Paris")

			if not catacombesDeParis then
				for _, v17 in workspace:GetChildren() do
					if v17.Name:lower():find("catacomb") then
						catacombesDeParis = v17
						break
					end
				end

				cachedMap = catacombesDeParis
			else
				cachedMap = catacombesDeParis
			end

			tbl.autoFeatures.brickBreaker.cachedMap = cachedMap
		end

		if not cachedMap then
			return {}, nil
		end
		local brickwall = cachedMap:FindFirstChild("Modes") and cachedMap.Modes:FindFirstChild("Objective") and cachedMap.Modes.Objective:FindFirstChild("brickwall")
		if not brickwall then
			return {}, nil
		end
		local cachedBricks = {}

		for _, v17 in brickwall:GetChildren() do
			if v17:IsA("BasePart") then
				table.insert(cachedBricks, v17)
			end
		end

		tbl.autoFeatures.brickBreaker.cachedBricks = cachedBricks
		tbl.autoFeatures.brickBreaker.cachedWall = brickwall
		return cachedBricks, brickwall
	end

	tbl.breakBrickOnce = function()
		local v16 = tbl.getBrickBreakerTool()
		if not v16 then
			return
		end
		local v17, v18 = tbl.getBrickWall()
		if not v18 or #v17 == 0 then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end

		if (humanoidRootPart.Position - v18:GetPivot().Position).Magnitude > 10 then
			return
		end
		pcall(v16.FireServer, v16, "Swing", "Over")

		for i = 1, #v17, 25 do
			for i2 = i, min(i + 25 - 1, #v17) do
				pcall(v16.FireServer, v16, "HitBreakable", { v17[i2] }, Vector3.new(0.97238314, 0, -0.23338981))
			end

			task.wait(0.1)
		end
	end

	tbl.brickBreakerLoop = function()
		while tbl.autoFeatures.brickBreaker.active do
			tbl.breakBrickOnce()
			task.wait(0.3)
		end
	end

	v15:AddToggle("AutoBreakWallToggle", {
		Text = "自动砸砖墙",
		Tooltip = fn4("巴黎地下墓穴自动砸砖墙"),
		Default = false,
		Callback = function(active)
			tbl.autoFeatures.brickBreaker.active = active

			if active then
				if tbl.autoFeatures.brickBreaker.thread then
					task.cancel(tbl.autoFeatures.brickBreaker.thread)
				end

				tbl.autoFeatures.brickBreaker.thread = task.spawn(tbl.brickBreakerLoop)
				tbl.notify(fn3("自动砸砖墙已开启"), 2)
			else
				if tbl.autoFeatures.brickBreaker.thread then
					task.cancel(tbl.autoFeatures.brickBreaker.thread)
				end

				tbl.autoFeatures.brickBreaker.thread = nil
				tbl.autoFeatures.brickBreaker.cachedMap = nil
				tbl.autoFeatures.brickBreaker.cachedWall = nil
				tbl.autoFeatures.brickBreaker.cachedBricks = nil
				tbl.notify(fn3("自动砸砖墙已关闭"), 2)
			end
		end,
	})

	local autoBarrel = {
		enabled = false,
		thread = nil,
		markers = {},
		activeZone = nil,
		idx = 1,
		GetNil = function(arg, arg2)
			local ok, result = pcall(function()
				return getnilinstances
			end)

			if not ok then
				return nil
			end

			for _, v16 in result() do
				if v16.Name ~= arg then
					continue
				end

				local ok2, result2 = pcall(function()
					return v16:GetDebugId()
				end)

				if not ok2 or result2 == arg2 then
					return v16
				end
			end

			return nil
		end,
		GetEvent = function()
			for _, v16 in { localPlayer.Character, localPlayer:FindFirstChild("Backpack") }, nil, nil do
				if v16 then
					for _, v17 in v16:GetChildren() do
						if v17:IsA("Tool") and v17:FindFirstChild("RemoteEvent") then
							return v17:FindFirstChild("RemoteEvent")
						end
					end
				end
			end

			local RemoteEvent = tbl.autoBarrel.GetNil("RemoteEvent", "1_1065169")
			if RemoteEvent then
				return RemoteEvent
			end
			return nil
		end,
		FindAxe = function()
			for _, v16 in { localPlayer.Character, localPlayer:FindFirstChild("Backpack") }, nil, nil do
				if v16 then
					for _, v17 in v16:GetChildren() do
						if v17:IsA("Tool") and (v17.Name:find("斧") or v17.Name:find("Axe")) and v17:FindFirstChild("RemoteEvent") then
							return v17
						end
					end
				end
			end

			return nil
		end,
		EquipAxe = function(arg)
			if arg and localPlayer.Character and arg.Parent ~= localPlayer.Character then
				arg.Parent = localPlayer.Character
			end
		end,
		UnequipAxe = function(arg)
			if arg and localPlayer:FindFirstChild("Backpack") and arg.Parent == localPlayer.Character then
				arg.Parent = localPlayer.Backpack
			end
		end,
		CreateMarker = function(position, text)
			local part = Instance.new("Part")
			part.Size = Vector3.new(5, 0.2, 5)
			part.Position = position
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0.3
			part.BrickColor = BrickColor.new("Bright red")
			part.Material = Enum.Material.Neon
			part.Parent = workspace
			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Parent = part
			billboardGui.Adornee = part
			billboardGui.Size = UDim2.new(0, 200, 0, 50)
			billboardGui.StudsOffset = Vector3.new(0, 3, 0)
			billboardGui.MaxDistance = 100
			billboardGui.AlwaysOnTop = true
			local textLabel = Instance.new("TextLabel")
			textLabel.Parent = billboardGui
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.Text = text
			textLabel.TextColor3 = Color3.new(1, 1, 1)
			textLabel.BackgroundTransparency = 1
			textLabel.TextStrokeTransparency = 0
			textLabel.Font = Enum.Font.SourceSansBold
			textLabel.TextSize = 20
			return part
		end,
	}

	local zones = {}

	local tbl4 = {
		name = "Sixth.Vat",
		markerPos = Vector3.new(-504, 84, -887),
		markerText = fn3("站在这自动攻击"),
		getBarrel = function()
			for _, v16 in workspace:GetDescendants() do
				if v16.Name == "WeaponHitEvent" and v16:GetFullName():find("Sixth.Vat") then
					return v16
				end
			end

			return nil
		end,
		attacks = {
			{
				dir = Vector3.new(-500.75604, 84.927505, -890.66754),
				pos = Vector3.new(-0.89652354, 0.060126048, -0.43889672),
			},
			{
				dir = Vector3.new(-500.98862, 85.332466, -890.1306),
				pos = Vector3.new(-0.9041061, 0.06780118, -0.42189467),
			},
			{
				dir = Vector3.new(-501.20587, 88.09386, -885.5167),
				pos = Vector3.new(-0.9857517, 0.07103491, 0.15247163),
			},
			{
				dir = Vector3.new(-501.19708, 88.0306, -885.4305),
				pos = Vector3.new(-0.9857517, 0.07103491, 0.15247163),
			},
			{
				dir = Vector3.new(-501.08237, 85.746765, -883.75226),
				pos = Vector3.new(-0.9848724, 0.06706964, 0.15977508),
			},
			{
				dir = Vector3.new(-501.0717, 85.640114, -883.64154),
				pos = Vector3.new(-0.98487234, 0.067069635, 0.15977506),
			},
			{
				dir = Vector3.new(-501.14145, 85.49108, -884.00916),
				pos = Vector3.new(-0.9848723, 0.06706963, 0.15977503),
			},
			{
				dir = Vector3.new(-501.06598, 85.75685, -883.6555),
				pos = Vector3.new(-0.98487234, 0.067069635, 0.15977506),
			},
			{
				dir = Vector3.new(-500.78323, 85.59901, -890.52026),
				pos = Vector3.new(-0.8965356, 0.059777364, -0.4389197),
			},
			{
				dir = Vector3.new(-501.03415, 85.72296, -889.8983),
				pos = Vector3.new(-0.9848487, 0.06741139, -0.15977699),
			},
			{
				dir = Vector3.new(-501.09647, 85.69531, -889.52576),
				pos = Vector3.new(-0.9848487, 0.0674114, -0.15977699),
			},
			{
				dir = Vector3.new(-501.11978, 85.646645, -889.4025),
				pos = Vector3.new(-0.9848487, 0.06741139, -0.15977699),
			},
			{
				dir = Vector3.new(-501.16486, 85.47568, -889.19714),
				pos = Vector3.new(-0.98485446, 0.06732521, -0.15977794),
			},
			{
				dir = Vector3.new(-501.12622, 85.940796, -884.10394),
				pos = Vector3.new(-0.9848723, 0.067069635, 0.15977506),
			},
			{
				dir = Vector3.new(-501.1567, 85.96322, -884.3014),
				pos = Vector3.new(-0.9848723, 0.06706963, 0.15977506),
			},
			{
				dir = Vector3.new(-501.34366, 88.06598, -886.39453),
				pos = Vector3.new(-0.9857517, 0.07103491, 0.15247163),
			},
			{ dir = Vector3.new(-500.15363, 85.16352, -889.7227), pos = Vector3.new(0, 1, 0) },
			{
				dir = Vector3.new(-501.2279, 87.05052, -885.19653),
				pos = Vector3.new(-0.9848732, 0.067056514, 0.1597752),
			},
			{
				dir = Vector3.new(-500.1642, 85.16352, -889.6371),
				pos = Vector3.new(0, 0.99999994, 0),
			},
			{
				dir = Vector3.new(-501.29144, 88.43513, -886.2289),
				pos = Vector3.new(-0.985762, 0.07103563, 0.15240449),
			},
			{
				dir = Vector3.new(-501.23367, 88.04647, -887.66705),
				pos = Vector3.new(-0.98581445, 0.070850246, -0.15215096),
			},
			{
				dir = Vector3.new(-501.07944, 85.71344, -889.62317),
				pos = Vector3.new(-0.9848487, 0.06741139, -0.15977699),
			},
			{
				dir = Vector3.new(-501.16504, 85.38667, -889.23346),
				pos = Vector3.new(-0.98485446, 0.06732521, -0.15977794),
			},
			{
				dir = Vector3.new(-501.0604, 85.61904, -889.7803),
				pos = Vector3.new(-0.9848487, 0.0674114, -0.15977699),
			},
			{
				dir = Vector3.new(-501.24405, 88.32903, -887.4678),
				pos = Vector3.new(-0.98580045, 0.07084924, -0.15224236),
			},
			{
				dir = Vector3.new(-500.76483, 86.16497, -890.4764),
				pos = Vector3.new(-0.90410596, 0.06780121, -0.42189494),
			},
		},
	}

	local tbl5 = {
		name = "Fifth.Vat",
		markerPos = Vector3.new(-503, 84, -855),
		markerText = fn3("站在这自动攻击"),
		getBarrel = function()
			local ok, result = pcall(function()
				local london = workspace:FindFirstChild("London")
				return london and london.Modes.Objective.PlantEvent.Vats.Fifth.Vat.Union
			end)

			if ok and result and result:FindFirstChild("WeaponHitEvent") then
				return result:FindFirstChild("WeaponHitEvent")
			end
			return tbl.autoBarrel.GetNil("WeaponHitEvent", "1_1065268")
		end,
		attacks = {
			{
				dir = Vector3.new(-501.07547, 85.681076, -858.6612),
				pos = Vector3.new(-0.98484874, 0.0674114, -0.159777),
			},
			{
				dir = Vector3.new(-501.18845, 85.63276, -857.9856),
				pos = Vector3.new(-0.98485446, 0.067325205, -0.15977792),
			},
			{
				dir = Vector3.new(-501.4731, 85.29793, -856.372),
				pos = Vector3.new(-0.98492193, 0.06730186, -0.15937145),
			},
			{
				dir = Vector3.new(-500.92535, 85.855034, -852.1581),
				pos = Vector3.new(-0.90419996, 0.067528576, 0.42173722),
			},
			{
				dir = Vector3.new(-500.88934, 85.85879, -852.0815),
				pos = Vector3.new(-0.9041999, 0.067528576, 0.4217372),
			},
			{
				dir = Vector3.new(-501.176, 87.96922, -854.2655),
				pos = Vector3.new(-0.9857516, 0.07103491, 0.15247163),
			},
			{
				dir = Vector3.new(-501.03616, 85.97066, -852.56134),
				pos = Vector3.new(-0.98487234, 0.067069635, 0.15977506),
			},
			{
				dir = Vector3.new(-501.0589, 88.31807, -853.687),
				pos = Vector3.new(-0.9848724, 0.067069635, 0.15977506),
			},
			{ dir = Vector3.new(-499.66125, 85.16353, -853.49677), pos = Vector3.new(0, 1, 0) },
			{
				dir = Vector3.new(-501.037, 87.9361, -853.3915),
				pos = Vector3.new(-0.98487234, 0.067069635, 0.15977506),
			},
			{
				dir = Vector3.new(-500.39682, 85.50465, -854.4968),
				pos = Vector3.new(0.7061626, -0.05049091, -0.7062471),
			},
			{
				dir = Vector3.new(-500.93835, 85.88355, -852.19055),
				pos = Vector3.new(-0.90419996, 0.06752858, 0.42173725),
			},
			{
				dir = Vector3.new(-500.9397, 85.8612, -852.1898),
				pos = Vector3.new(-0.9041999, 0.067528576, 0.4217372),
			},
			{
				dir = Vector3.new(-501.0238, 85.66065, -852.35504),
				pos = Vector3.new(-0.98487234, 0.06706963, 0.15977505),
			},
			{
				dir = Vector3.new(-501.04617, 85.94073, -852.6105),
				pos = Vector3.new(-0.98487234, 0.06706963, 0.15977505),
			},
			{
				dir = Vector3.new(-500.78168, 85.65259, -851.8307),
				pos = Vector3.new(-0.8974282, 0.05971466, 0.43710032),
			},
			{
				dir = Vector3.new(-500.8728, 85.297035, -851.9692),
				pos = Vector3.new(-0.8974283, 0.059714667, 0.43710032),
			},
			{
				dir = Vector3.new(-501.1628, 84.407585, -855.2833),
				pos = Vector3.new(0.70647174, 0.04231629, -0.70647496),
			},
			{
				dir = Vector3.new(-499.37216, 84.492935, -857.3116),
				pos = Vector3.new(0.6035478, 0.5211642, 0.60342175),
			},
			{
				dir = Vector3.new(-501.2195, 88.377556, -854.73663),
				pos = Vector3.new(-0.98576206, 0.071035646, 0.15240449),
			},
			{
				dir = Vector3.new(-501.17966, 85.689224, -858.0156),
				pos = Vector3.new(-0.9848487, 0.06741139, -0.15977699),
			},
			{
				dir = Vector3.new(-501.1714, 85.6417, -858.0866),
				pos = Vector3.new(-0.98484874, 0.0674114, -0.159777),
			},
			{
				dir = Vector3.new(-501.17776, 85.642426, -858.04694),
				pos = Vector3.new(-0.9848487, 0.0674114, -0.159777),
			},
			{
				dir = Vector3.new(-501.07324, 85.03772, -858.94867),
				pos = Vector3.new(-0.9848843, 0.06680974, -0.15981026),
			},
			{
				dir = Vector3.new(-501.22708, 88.80728, -854.98596),
				pos = Vector3.new(-0.98576206, 0.07103564, 0.1524045),
			},
			{
				dir = Vector3.new(-501.07352, 85.897545, -858.58203),
				pos = Vector3.new(-0.98484874, 0.06741139, -0.15977699),
			},
		},
	}

	local tbl6 = {
		name = "Eleventh.Vat",
		markerPos = Vector3.new(-549, 86, -811),
		markerText = fn3("站在这自动攻击"),
		getBarrel = function()
			local ok, result = pcall(function()
				return fn2(workspace, "London", "Modes", "Objective", "PlantEvent", "Vats", "Eleventh", "Vat", "Union")
			end)

			if ok and result and result:FindFirstChild("WeaponHitEvent") then
				return result:FindFirstChild("WeaponHitEvent")
			end
			return tbl.autoBarrel.GetNil("WeaponHitEvent", "1_1073300")
		end,
		attacks = {
			{
				dir = Vector3.new(-552.7838, 88.71797, -809.0079),
				pos = Vector3.new(0.98476565, 0.067194454, 0.16037914),
			},
			{
				dir = Vector3.new(-552.7044, 89.815094, -811.3433),
				pos = Vector3.new(0.9857639, 0.07104273, -0.15238886),
			},
			{
				dir = Vector3.new(-552.6829, 89.84794, -811.1889),
				pos = Vector3.new(0.98576397, 0.07104273, -0.15238887),
			},
			{
				dir = Vector3.new(-553.07263, 85.68813, -814.20605),
				pos = Vector3.new(0.90414244, -0.067688905, -0.4218347),
			},
			{
				dir = Vector3.new(-552.8813, 87.53904, -813.42303),
				pos = Vector3.new(0.9848784, 0.06709598, -0.15972693),
			},
			{
				dir = Vector3.new(-552.87427, 85.38809, -813.2256),
				pos = Vector3.new(0.98481035, -0.067274585, -0.16007093),
			},
			{
				dir = Vector3.new(-552.59705, 87.250275, -809.54016),
				pos = Vector3.new(0.98476404, 0.06718805, 0.16039178),
			},
			{
				dir = Vector3.new(-552.732, 87.07971, -808.63654),
				pos = Vector3.new(0.98478204, 0.06877595, 0.15960649),
			},
			{
				dir = Vector3.new(-552.6297, 87.18196, -809.311),
				pos = Vector3.new(0.98476565, 0.06719446, 0.16037914),
			},
			{
				dir = Vector3.new(-552.58185, 88.96362, -810.9475),
				pos = Vector3.new(0.98576397, 0.07104273, -0.15238887),
			},
			{
				dir = Vector3.new(-552.91504, 87.483086, -813.6546),
				pos = Vector3.new(0.9848784, 0.06709599, -0.15972693),
			},
			{
				dir = Vector3.new(-552.92816, 85.77101, -813.718),
				pos = Vector3.new(0.98481035, -0.06727458, -0.16007093),
			},
			{
				dir = Vector3.new(-552.77795, 88.10868, -808.78876),
				pos = Vector3.new(0.98476404, 0.06718804, 0.16039176),
			},
			{
				dir = Vector3.new(-552.76764, 88.29107, -808.92865),
				pos = Vector3.new(0.984764, 0.06718804, 0.16039175),
			},
			{
				dir = Vector3.new(-552.7499, 89.06903, -809.36346),
				pos = Vector3.new(0.984764, 0.06718804, 0.16039175),
			},
			{
				dir = Vector3.new(-552.751, 88.92, -809.2942),
				pos = Vector3.new(0.98476404, 0.06718804, 0.16039176),
			},
			{
				dir = Vector3.new(-552.653, 87.09329, -809.1295),
				pos = Vector3.new(0.98478204, 0.06877594, 0.15960647),
			},
			{
				dir = Vector3.new(-552.44196, 86.75629, -810.2867),
				pos = Vector3.new(0.984782, 0.06877593, 0.15960647),
			},
			{
				dir = Vector3.new(-552.9142, 85.77261, -813.6325),
				pos = Vector3.new(0.9848103, -0.06727458, -0.16007091),
			},
			{
				dir = Vector3.new(-552.76385, 87.46857, -812.7283),
				pos = Vector3.new(0.9848784, 0.06709598, -0.15972692),
			},
			{
				dir = Vector3.new(-552.9091, 86.100426, -813.73914),
				pos = Vector3.new(0.98481035, -0.067274585, -0.16007093),
			},
			{
				dir = Vector3.new(-552.8866, 85.23353, -813.23645),
				pos = Vector3.new(0.98481035, -0.067274585, -0.16007093),
			},
			{
				dir = Vector3.new(-552.6922, 84.79696, -809.4828),
				pos = Vector3.new(0.9848438, -0.06738122, 0.1598204),
			},
			{
				dir = Vector3.new(-552.7633, 86.98217, -808.4014),
				pos = Vector3.new(0.98483956, 0.067443065, 0.15981972),
			},
			{
				dir = Vector3.new(-552.69714, 86.88089, -808.76624),
				pos = Vector3.new(0.9848396, 0.06744306, 0.15981974),
			},
			{
				dir = Vector3.new(-552.7866, 89.133865, -812.1694),
				pos = Vector3.new(0.9848784, 0.06709599, -0.15972693),
			},
			{
				dir = Vector3.new(-552.7429, 87.9488, -812.3979),
				pos = Vector3.new(0.9848811, 0.06705528, -0.15972736),
			},
		},
	}

	local tbl7 = {
		name = "Eighth.Vat",
		markerPos = Vector3.new(-551, 73, -863),
		markerText = fn3("站在这自动攻击"),
		getBarrel = function()
			local ok, result = pcall(function()
				local london = workspace:FindFirstChild("London")
				return london and london.Modes.Objective.PlantEvent.Vats.Eighth.Vat.Union
			end)

			if ok and result and result:FindFirstChild("WeaponHitEvent") then
				return result:FindFirstChild("WeaponHitEvent")
			end
			return tbl.autoBarrel.GetNil("WeaponHitEvent", "1_1078763")
		end,
		attacks = {
			{
				dir = Vector3.new(-554.957, 74.623535, -861.18964),
				pos = Vector3.new(0.89145, -0.2004975, 0.40634662),
			},
			{
				dir = Vector3.new(-554.94885, 74.613556, -861.21246),
				pos = Vector3.new(0.89145005, -0.20049751, 0.40634665),
			},
			{
				dir = Vector3.new(-554.80457, 74.60722, -861.53204),
				pos = Vector3.new(0.89145, -0.20049748, 0.40634662),
			},
			{
				dir = Vector3.new(-554.8045, 74.65089, -861.5106),
				pos = Vector3.new(0.89145, -0.20049748, 0.4063466),
			},
			{
				dir = Vector3.new(-554.6135, 74.701675, -861.9043),
				pos = Vector3.new(0.8914683, -0.20056136, 0.40627486),
			},
			{
				dir = Vector3.new(-554.6528, 74.588844, -861.8741),
				pos = Vector3.new(0.89143723, -0.20055987, 0.40634373),
			},
			{
				dir = Vector3.new(-554.6643, 74.60165, -861.8426),
				pos = Vector3.new(0.89145, -0.20049746, 0.40634656),
			},
			{
				dir = Vector3.new(-554.6403, 74.7055, -861.8439),
				pos = Vector3.new(0.89145, -0.20049748, 0.4063466),
			},
			{
				dir = Vector3.new(-553.95575, 74.82688, -867.0438),
				pos = Vector3.new(0.96702576, -0.20930187, -0.14509974),
			},
			{
				dir = Vector3.new(-553.9352, 74.665886, -866.6744),
				pos = Vector3.new(0.9670257, -0.20930186, -0.14509976),
			},
			{
				dir = Vector3.new(-553.9174, 74.855194, -866.8293),
				pos = Vector3.new(0.9670257, -0.20930186, -0.14509974),
			},
			{
				dir = Vector3.new(-553.90857, 74.83263, -866.7375),
				pos = Vector3.new(0.9670257, -0.20930187, -0.14509974),
			},
			{
				dir = Vector3.new(-553.47955, 77.100334, -864.2589),
				pos = Vector3.new(0.9661953, -0.19930883, 0.16353197),
			},
			{
				dir = Vector3.new(-553.4386, 77.0082, -864.62286),
				pos = Vector3.new(0.96637833, -0.209183, 0.1495171),
			},
			{ dir = Vector3.new(-554.3455, 74.50676, -865.581), pos = Vector3.new(0, -1, 0) },
			{
				dir = Vector3.new(-553.6022, 76.671036, -864.05756),
				pos = Vector3.new(0.9661952, -0.19930883, 0.16353197),
			},
			{
				dir = Vector3.new(-553.59204, 76.67828, -864.1087),
				pos = Vector3.new(0.9661953, -0.19930881, 0.16353197),
			},
			{
				dir = Vector3.new(-554.0542, 74.54925, -867.2995),
				pos = Vector3.new(0.96702576, -0.20930187, -0.14509976),
			},
			{
				dir = Vector3.new(-554.0468, 74.52961, -867.2221),
				pos = Vector3.new(0.96702576, -0.20930187, -0.14509976),
			},
			{
				dir = Vector3.new(-553.8126, 74.88644, -866.1759),
				pos = Vector3.new(0.9670257, -0.20930184, -0.14509974),
			},
			{
				dir = Vector3.new(-553.8118, 74.88818, -866.1729),
				pos = Vector3.new(0.96702576, -0.20930187, -0.14509976),
			},
			{
				dir = Vector3.new(-553.91675, 74.664246, -866.5492),
				pos = Vector3.new(0.96702576, -0.20930189, -0.14509976),
			},
			{
				dir = Vector3.new(-554.6526, 74.563324, -861.8871),
				pos = Vector3.new(0.89145005, -0.2004975, 0.40634662),
			},
			{
				dir = Vector3.new(-554.6871, 74.51005, -861.8376),
				pos = Vector3.new(0.8914684, -0.20056139, 0.40627494),
			},
			{
				dir = Vector3.new(-553.98035, 74.56279, -866.8266),
				pos = Vector3.new(0.96702576, -0.20930187, -0.14509976),
			},
			{
				dir = Vector3.new(-553.9917, 74.51576, -866.8348),
				pos = Vector3.new(0.96702576, -0.20930187, -0.14509974),
			},
			{
				dir = Vector3.new(-553.4251, 77.44363, -864.1622),
				pos = Vector3.new(0.9661952, -0.1993088, 0.16353196),
			},
			{
				dir = Vector3.new(-554.6713, 74.7969, -861.7308),
				pos = Vector3.new(0.89145005, -0.20049754, 0.40634656),
			},
			{
				dir = Vector3.new(-553.3532, 77.73155, -864.236),
				pos = Vector3.new(0.9661952, -0.19930881, 0.16353197),
			},
			{
				dir = Vector3.new(-553.48865, 76.52338, -864.97766),
				pos = Vector3.new(0.96637833, -0.209183, 0.1495171),
			},
			{
				dir = Vector3.new(-554.21155, 74.735115, -862.81683),
				pos = Vector3.new(0.9661952, -0.19930878, 0.16353194),
			},
			{
				dir = Vector3.new(-554.95905, 74.62028, -861.1867),
				pos = Vector3.new(0.89145, -0.2004975, 0.40634665),
			},
		},
	}

	zones[1] = tbl4
	zones[2] = tbl5
	zones[3] = tbl6
	zones[4] = tbl7
	autoBarrel.zones = zones

	autoBarrel.ClearMarkers = function()
		for _, v16 in tbl.autoBarrel.markers, nil, nil do
			if v16 and v16.Parent then
				v16:Destroy()
			end
		end

		tbl.autoBarrel.markers = {}
	end

	autoBarrel.MainLoop = function()
		while tbl.autoBarrel.enabled do
			local character = localPlayer.Character
			character = character and character:FindFirstChild("HumanoidRootPart")

			if character then
				local v16 = nil

				for _, v17 in tbl.autoBarrel.zones, nil, nil do
					local v18 = v17.getBarrel()

					if v18 and v18.Parent then
						if (character.Position - v17.markerPos).Magnitude <= 7 then
							v17.barrelObj = v18
							v16 = v17
							break
						else
							v16 = nil
						end
					else
						v16 = nil
					end
				end

				if v16 and tbl.autoBarrel.activeZone ~= v16 then
					tbl.autoBarrel.activeZone = v16
					tbl.autoBarrel.idx = 1
					local v17 = tbl.autoBarrel.FindAxe()

					if v17 then
						tbl.autoBarrel.EquipAxe(v17)
						task.wait(0.3)
					end
				end

				if not v16 and tbl.autoBarrel.activeZone then
					tbl.autoBarrel.activeZone = nil
				end

				if tbl.autoBarrel.activeZone and v16 then
					local v17 = tbl.autoBarrel.GetEvent()

					if v17 then
						local activeZone = tbl.autoBarrel.activeZone

						if not activeZone.barrelObj or not activeZone.barrelObj.Parent then
							activeZone.barrelObj = activeZone.getBarrel()
						end

						if activeZone.barrelObj and activeZone.barrelObj.Parent then
							local v18 = activeZone.attacks[tbl.autoBarrel.idx]
							pcall(v17.FireServer, v17, "PrepareSwing")
							pcall(v17.FireServer, v17, "Swing", "Side")
							pcall(v17.FireServer, v17, "WeaponHitEvent", activeZone.barrelObj, v18.dir, v18.pos)
						end

						tbl.autoBarrel.idx = tbl.autoBarrel.idx + 1

						if #activeZone.attacks < tbl.autoBarrel.idx then
							tbl.autoBarrel.idx = 1
						end
					end
				end
			elseif tbl.autoBarrel.activeZone then
				local v16 = tbl.autoBarrel.FindAxe()

				if v16 then
					pcall(tbl.autoBarrel.UnequipAxe, v16)
				end

				tbl.autoBarrel.activeZone = nil
			end

			task.wait(0.1)
		end
	end

	autoBarrel.Start = function()
		if tbl.autoBarrel.enabled then
			return
		end
		tbl.autoBarrel.enabled = true
		tbl.autoBarrel.ClearMarkers()

		for _, v16 in tbl.autoBarrel.zones, nil, nil do
			local v17 = tbl.autoBarrel.CreateMarker(v16.markerPos, v16.markerText)
			table.insert(tbl.autoBarrel.markers, v17)
		end

		if tbl.autoBarrel.thread then
			task.cancel(tbl.autoBarrel.thread)
		end

		tbl.autoBarrel.thread = task.spawn(tbl.autoBarrel.MainLoop)
		tbl.notify(fn3("自动打酒桶已开启"), 2)
	end

	autoBarrel.Stop = function()
		tbl.autoBarrel.enabled = false

		if tbl.autoBarrel.thread then
			task.cancel(tbl.autoBarrel.thread)
			tbl.autoBarrel.thread = nil
		end

		tbl.autoBarrel.ClearMarkers()
		tbl.autoBarrel.activeZone = nil
		tbl.autoBarrel.idx = 1
		tbl.notify(fn3("自动打酒桶已关闭"), 2)
	end

	tbl.autoBarrel = autoBarrel

	v15:AddToggle("AutoBarrelToggle", {
		Text = "自动打酒桶",
		Default = false,
		Tooltip = fn4("自动攻击伦敦酒桶"),
		Callback = function(arg)
			if arg then
				tbl.autoBarrel.Start()
			else
				tbl.autoBarrel.Stop()
			end
		end,
	})

	tbl.autoWestminster = { enabled = false, thread = nil, AttackInterval = 0.1, AttackRange = 15, _tmp = {} }

	tbl.autoWestminster.getTargetParts = function()
		tbl.autoWestminster._tmp.west = workspace:FindFirstChild("Westminster")
		if not tbl.autoWestminster._tmp.west then
			return {}
		end
		tbl.autoWestminster._tmp.modes = tbl.autoWestminster._tmp.west:FindFirstChild("Modes")
		if not tbl.autoWestminster._tmp.modes then
			return {}
		end
		tbl.autoWestminster._tmp.obj = tbl.autoWestminster._tmp.modes:FindFirstChild("Objective")
		if not tbl.autoWestminster._tmp.obj then
			return {}
		end
		tbl.autoWestminster._tmp.barricade = tbl.autoWestminster._tmp.obj:FindFirstChild("StreetBarricade")
		if not tbl.autoWestminster._tmp.barricade then
			return {}
		end
		tbl.autoWestminster._tmp.model = tbl.autoWestminster._tmp.barricade:FindFirstChild("Model")
		if not tbl.autoWestminster._tmp.model then
			return {}
		end
		tbl.autoWestminster._tmp.boundingBox = tbl.autoWestminster._tmp.model:FindFirstChild("BoundingBox")
		if not tbl.autoWestminster._tmp.boundingBox then
			return {}
		end
		tbl.autoWestminster._tmp.parts = {}

		if tbl.autoWestminster._tmp.boundingBox:IsA("BasePart") then
			tbl.autoWestminster._tmp.parts[#tbl.autoWestminster._tmp.parts + 1] = tbl.autoWestminster._tmp.boundingBox
		end

		tbl.autoWestminster._tmp.children = tbl.autoWestminster._tmp.boundingBox:GetDescendants()

		for i = 1, #tbl.autoWestminster._tmp.children do
			if tbl.autoWestminster._tmp.children[i]:IsA("BasePart") then
				tbl.autoWestminster._tmp.parts[#tbl.autoWestminster._tmp.parts + 1] = tbl.autoWestminster._tmp.children[i]
			end
		end

		return tbl.autoWestminster._tmp.parts
	end

	tbl.autoWestminster.getNearestTarget = function(arg)
		tbl.autoWestminster._tmp.parts = tbl.autoWestminster.getTargetParts()
		tbl.autoWestminster._tmp.bestPart = nil
		tbl.autoWestminster._tmp.bestDist = tbl.autoWestminster.AttackRange + 1

		for i = 1, #tbl.autoWestminster._tmp.parts do
			tbl.autoWestminster._tmp.dist = (tbl.autoWestminster._tmp.parts[i].Position - arg).Magnitude

			if tbl.autoWestminster._tmp.dist < tbl.autoWestminster._tmp.bestDist then
				tbl.autoWestminster._tmp.bestDist = tbl.autoWestminster._tmp.dist
				tbl.autoWestminster._tmp.bestPart = tbl.autoWestminster._tmp.parts[i]
			end
		end

		if not tbl.autoWestminster._tmp.bestPart then
			return nil, nil, nil, nil
		end
		tbl.autoWestminster._tmp.hitPos = tbl.autoWestminster._tmp.bestPart.Position
		tbl.autoWestminster._tmp.normal = (arg - tbl.autoWestminster._tmp.hitPos).Unit
		return tbl.autoWestminster._tmp.bestPart, tbl.autoWestminster._tmp.hitPos, tbl.autoWestminster._tmp.normal, tbl.autoWestminster._tmp.bestDist
	end

	tbl.autoWestminster.getCurrentWeaponRemote = function()
		return tbl.getHeldToolRemote()
	end

	tbl.autoWestminster.performAttack = function(arg, arg2, arg3, arg4)
		if not arg then
			return
		end
		arg:FireServer("PrepareSwing")
		task.wait(0.02)
		arg:FireServer("Swing", "Side")
		task.wait(0.02)
		arg:FireServer("HitCon", arg2, arg3, arg4)
	end

	tbl.autoWestminster.attackLoop = function()
		while tbl.autoWestminster.enabled do
			local tmp = tbl.autoWestminster._tmp
			local tmp2 = tbl.autoWestminster._tmp
			local v16, v17 = tbl.autoWestminster.getCurrentWeaponRemote()
			tmp.remote = v16
			tmp2.weapon = v17

			if tbl.autoWestminster._tmp.remote and tbl.autoWestminster._tmp.weapon and localPlayer.Character then
				tbl.autoWestminster._tmp.root = localPlayer.Character:FindFirstChild("HumanoidRootPart")

				if tbl.autoWestminster._tmp.root then
					local tmp3 = tbl.autoWestminster._tmp
					local tmp4 = tbl.autoWestminster._tmp
					local tmp5 = tbl.autoWestminster._tmp
					local tmp6 = tbl.autoWestminster._tmp
					local v18, v19, v20, v21 = tbl.autoWestminster.getNearestTarget(tbl.autoWestminster._tmp.root.Position)
					tmp3.tPart = v18
					tmp4.hPos = v19
					tmp5.normal = v20
					tmp6.dist = v21

					if tbl.autoWestminster._tmp.tPart and tbl.autoWestminster._tmp.dist <= tbl.autoWestminster.AttackRange then
						tbl.autoWestminster.performAttack(tbl.autoWestminster._tmp.remote, tbl.autoWestminster._tmp.tPart, tbl.autoWestminster._tmp.hPos, tbl.autoWestminster._tmp.normal)
					end
				end
			end

			task.wait(tbl.autoWestminster.AttackInterval)
		end
	end

	tbl.autoWestminster.Start = function()
		if tbl.autoWestminster.enabled then
			return
		end
		tbl.autoWestminster.enabled = true

		if tbl.autoWestminster.thread then
			task.cancel(tbl.autoWestminster.thread)
		end

		tbl.autoWestminster.thread = task.spawn(tbl.autoWestminster.attackLoop)
		tbl.notify(fn3("自动打威斯特敏障碍已开启"), 2)
	end

	tbl.autoWestminster.Stop = function()
		tbl.autoWestminster.enabled = false

		if tbl.autoWestminster.thread then
			task.cancel(tbl.autoWestminster.thread)
			tbl.autoWestminster.thread = nil
		end

		tbl.notify(fn3("自动打威斯特敏障碍已关闭"), 2)
	end

	v15:AddToggle("AutoWestminsterToggle", {
		Text = "自动打威斯特敏障碍",
		Default = false,
		Tooltip = fn4("自动攻击威斯特敏路障"),
		Callback = function(arg)
			if arg then
				tbl.autoWestminster.Start()
			else
				tbl.autoWestminster.Stop()
			end
		end,
	})

	tbl.autoLeipzigBarricade = { enabled = false, thread = nil, AttackInterval = 0.3, _tmp = {} }

	tbl.autoLeipzigBarricade.getTarget = function()
		tbl.autoLeipzigBarricade._tmp.leipzig = workspace:FindFirstChild("Leipzig")
		if not tbl.autoLeipzigBarricade._tmp.leipzig then
			return nil
		end
		tbl.autoLeipzigBarricade._tmp.modes = tbl.autoLeipzigBarricade._tmp.leipzig:FindFirstChild("Modes")
		if not tbl.autoLeipzigBarricade._tmp.modes then
			return nil
		end
		tbl.autoLeipzigBarricade._tmp.objective = tbl.autoLeipzigBarricade._tmp.modes:FindFirstChild("Objective")
		if not tbl.autoLeipzigBarricade._tmp.objective then
			return nil
		end
		tbl.autoLeipzigBarricade._tmp.barricade = tbl.autoLeipzigBarricade._tmp.objective:FindFirstChild("Barricade")
		if not tbl.autoLeipzigBarricade._tmp.barricade then
			return nil
		end
		return tbl.autoLeipzigBarricade._tmp.barricade:FindFirstChild("Hitbox")
	end

	tbl.autoLeipzigBarricade.getCurrentWeaponRemote = function()
		return tbl.getHeldToolRemote()
	end

	tbl.autoLeipzigBarricade.performAttack = function(arg, arg2)
		if not arg or not arg2 then
			return
		end
		tbl.autoLeipzigBarricade._tmp.hitPos = Vector3.new(-154.15071, -6.2045636, -95.3622)
		tbl.autoLeipzigBarricade._tmp.normal = Vector3.new(0.2588048, 0, 0.9659296)
		arg:FireServer("PrepareSwing")
		task.wait(0.02)
		arg:FireServer("Swing", "Side")
		task.wait(0.02)
		arg:FireServer("HitCon", arg2, tbl.autoLeipzigBarricade._tmp.hitPos, tbl.autoLeipzigBarricade._tmp.normal)
	end

	tbl.autoLeipzigBarricade.attackLoop = function()
		while tbl.autoLeipzigBarricade.enabled do
			local tmp = tbl.autoLeipzigBarricade._tmp
			local tmp2 = tbl.autoLeipzigBarricade._tmp
			local v16, v17 = tbl.autoLeipzigBarricade.getCurrentWeaponRemote()
			tmp.remote = v16
			tmp2.weapon = v17
			tbl.autoLeipzigBarricade._tmp.target = tbl.autoLeipzigBarricade.getTarget()

			if tbl.autoLeipzigBarricade._tmp.remote and tbl.autoLeipzigBarricade._tmp.target then
				tbl.autoLeipzigBarricade.performAttack(tbl.autoLeipzigBarricade._tmp.remote, tbl.autoLeipzigBarricade._tmp.target)
			end

			task.wait(tbl.autoLeipzigBarricade.AttackInterval)
		end
	end

	tbl.autoLeipzigBarricade.Start = function()
		if tbl.autoLeipzigBarricade.enabled then
			return
		end
		tbl.autoLeipzigBarricade.enabled = true

		if tbl.autoLeipzigBarricade.thread then
			task.cancel(tbl.autoLeipzigBarricade.thread)
		end

		tbl.autoLeipzigBarricade.thread = task.spawn(tbl.autoLeipzigBarricade.attackLoop)
		tbl.notify(fn3("自动打莱比锡木板已开启"), 2)
	end

	tbl.autoLeipzigBarricade.Stop = function()
		tbl.autoLeipzigBarricade.enabled = false

		if tbl.autoLeipzigBarricade.thread then
			task.cancel(tbl.autoLeipzigBarricade.thread)
			tbl.autoLeipzigBarricade.thread = nil
		end

		tbl.notify(fn3("自动打莱比锡木板已关闭"), 2)
	end

	v15:AddToggle("AutoLeipzigToggle", {
		Text = "自动打莱比锡木板",
		Default = false,
		Tooltip = fn4("自动攻击莱比锡木板"),
		Callback = function(arg)
			if arg then
				tbl.autoLeipzigBarricade.Start()
			else
				tbl.autoLeipzigBarricade.Stop()
			end
		end,
	})

	tbl.autoCopenhagenGate = { enabled = false, thread = nil, AttackRange = 5, AttackInterval = 0.2, _tmp = {} }

	tbl.autoCopenhagenGate.getTarget = function()
		tbl.autoCopenhagenGate._tmp.copenhagen = workspace:FindFirstChild("Copenhagen")
		if not tbl.autoCopenhagenGate._tmp.copenhagen then
			return nil
		end
		tbl.autoCopenhagenGate._tmp.modes = tbl.autoCopenhagenGate._tmp.copenhagen:FindFirstChild("Modes")
		if not tbl.autoCopenhagenGate._tmp.modes then
			return nil
		end
		tbl.autoCopenhagenGate._tmp.obj = tbl.autoCopenhagenGate._tmp.modes:FindFirstChild("Objective")
		if not tbl.autoCopenhagenGate._tmp.obj then
			return nil
		end
		tbl.autoCopenhagenGate._tmp.gateObj = tbl.autoCopenhagenGate._tmp.obj:FindFirstChild("GateObj")
		if not tbl.autoCopenhagenGate._tmp.gateObj then
			return nil
		end
		tbl.autoCopenhagenGate._tmp.gate = tbl.autoCopenhagenGate._tmp.gateObj:FindFirstChild("Gate")
		if not tbl.autoCopenhagenGate._tmp.gate then
			return nil
		end
		return tbl.autoCopenhagenGate._tmp.gate:FindFirstChild("Lock")
	end

	tbl.autoCopenhagenGate.getCurrentWeaponRemote = function()
		return tbl.getHeldToolRemote()
	end

	tbl.autoCopenhagenGate.performAttack = function(arg, arg2)
		if not arg or not arg2 then
			return
		end
		tbl.autoCopenhagenGate._tmp.hitPos = Vector3.new(62.246265, 9.197623, -45.4807)
		tbl.autoCopenhagenGate._tmp.normal = Vector3.new(0.90587777, 0.03483456, -0.42210424)
		arg:FireServer("PrepareSwing")
		task.wait(0.02)
		arg:FireServer("Swing", "Thrust")
		task.wait(0.02)
		arg:FireServer("HitCon", arg2, tbl.autoCopenhagenGate._tmp.hitPos, tbl.autoCopenhagenGate._tmp.normal)
	end

	tbl.autoCopenhagenGate.attackLoop = function()
		while tbl.autoCopenhagenGate.enabled do
			local tmp = tbl.autoCopenhagenGate._tmp
			local tmp2 = tbl.autoCopenhagenGate._tmp
			local v16, v17 = tbl.autoCopenhagenGate.getCurrentWeaponRemote()
			tmp.remote = v16
			tmp2.weapon = v17
			tbl.autoCopenhagenGate._tmp.target = tbl.autoCopenhagenGate.getTarget()

			if tbl.autoCopenhagenGate._tmp.remote and tbl.autoCopenhagenGate._tmp.target then
				if localPlayer.Character then
					tbl.autoCopenhagenGate._tmp.root = localPlayer.Character:FindFirstChild("HumanoidRootPart")

					if tbl.autoCopenhagenGate._tmp.root then
						tbl.autoCopenhagenGate._tmp.dist = (tbl.autoCopenhagenGate._tmp.root.Position - tbl.autoCopenhagenGate._tmp.target.Position).Magnitude

						if tbl.autoCopenhagenGate._tmp.dist <= tbl.autoCopenhagenGate.AttackRange then
							tbl.autoCopenhagenGate.performAttack(tbl.autoCopenhagenGate._tmp.remote, tbl.autoCopenhagenGate._tmp.target)
						end
					end
				end
			end

			task.wait(tbl.autoCopenhagenGate.AttackInterval)
		end
	end

	tbl.autoCopenhagenGate.Start = function()
		if tbl.autoCopenhagenGate.enabled then
			return
		end
		tbl.autoCopenhagenGate.enabled = true

		if tbl.autoCopenhagenGate.thread then
			task.cancel(tbl.autoCopenhagenGate.thread)
		end

		tbl.autoCopenhagenGate.thread = task.spawn(tbl.autoCopenhagenGate.attackLoop)
		tbl.notify(fn3("自动打哥本哈根锁已开启"), 2)
	end

	tbl.autoCopenhagenGate.Stop = function()
		tbl.autoCopenhagenGate.enabled = false

		if tbl.autoCopenhagenGate.thread then
			task.cancel(tbl.autoCopenhagenGate.thread)
			tbl.autoCopenhagenGate.thread = nil
		end

		tbl.notify(fn3("自动打哥本哈根锁已关闭"), 2)
	end

	v15:AddToggle("AutoCopenhagenToggle", {
		Text = "自动打哥本哈根锁",
		Default = false,
		Tooltip = fn4("自动攻击哥本哈根门锁"),
		Callback = function(arg)
			if arg then
				tbl.autoCopenhagenGate.Start()
			else
				tbl.autoCopenhagenGate.Stop()
			end
		end,
	})

	tbl.autoCannon = { enabled = false, connection = nil, lastReloadTime = 0, reloadCooldown = 0.5 }

	tbl.autoCannon.findNearestGun = function()
		local character = localPlayer.Character
		if not character or not character.Parent then
			return nil
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return nil
		end
		local huge = math.huge
		local v16 = nil

		for _, v17 in workspace:GetDescendants() do
			if v17.Name == "12 Pound Gun" and v17:IsA("Model") then
				local hole = v17:FindFirstChild("Gun") and v17.Gun:FindFirstChild("Hole")

				if hole then
					local magnitude = (hole.Position - humanoidRootPart.Position).Magnitude

					if magnitude < huge then
						huge = magnitude
						v16 = v17
					end
				end
			end
		end

		return v16
	end

	tbl.autoCannon.reload = function()
		local v16 = clock()
		if v16 - tbl.autoCannon.lastReloadTime < tbl.autoCannon.reloadCooldown then
			return
		end
		local v17 = tbl.autoCannon.findNearestGun()

		if v17 then
			local interact = v17:FindFirstChild("Gun") and v17.Gun:FindFirstChild("Hole") and v17.Gun.Hole:FindFirstChild("Interact")

			if interact and interact:IsA("RemoteEvent") then
				interact:FireServer()
				tbl.autoCannon.lastReloadTime = v16
			end
		end
	end

	tbl.startAutoCannon = function()
		tbl.stopAutoCannon()
		tbl.autoCannon.enabled = true
		tbl.autoCannon.connection = v5.Heartbeat:Connect(tbl.autoCannon.reload)
		tbl.notify(fn3("自动装填大炮已开启"), 2)
	end

	tbl.stopAutoCannon = function()
		tbl.autoCannon.enabled = false

		if tbl.autoCannon.connection then
			tbl.autoCannon.connection:Disconnect()
			tbl.autoCannon.connection = nil
		end

		tbl.notify(fn3("自动装填大炮已关闭"), 2)
	end

	v15:AddToggle("AutoCannonToggle", {
		Text = "自动装填大炮",
		Default = false,
		Tooltip = fn4("自动装填最近的12磅炮"),
		Callback = function(arg)
			if arg then
				tbl.startAutoCannon()
			else
				tbl.stopAutoCannon()
			end
		end,
	})

	tbl.autoBell = { enabled = false, conn = nil }

	tbl.autoBell.start = function()
		if tbl.autoBell.conn then
			return
		end
		tbl.autoBell.enabled = true

		tbl.autoBell.conn = v5.Heartbeat:Connect(function()
			if not tbl.autoBell.enabled then
				return
			end
			local leipzig = workspace:FindFirstChild("Leipzig")

			if leipzig and leipzig:FindFirstChild("Modes") then
				local modes = leipzig.Modes

				if modes:FindFirstChild("Objective") then
					local bellInteract = modes.Objective:FindFirstChild("BellInteract")

					if bellInteract and bellInteract:FindFirstChild("Interact") then
						pcall(function()
							bellInteract.Interact:FireServer()
						end)
					end
				end
			end
		end)
	end

	tbl.autoBell.stop = function()
		tbl.autoBell.enabled = false

		if tbl.autoBell.conn then
			tbl.autoBell.conn:Disconnect()
			tbl.autoBell.conn = nil
		end
	end

	v15:AddToggle("AutoBellToggle", {
		Text = "莱比锡自动拉铃",
		Default = false,
		Tooltip = fn4("自动拉响莱比锡钟楼铃铛"),
		Callback = function(arg)
			if arg then
				tbl.autoBell.start()
			else
				tbl.autoBell.stop()
			end
		end,
	})

	tbl.LondonBoardAuto = { enabled = false, heartbeat = nil, refPos = Vector3.new(-149.42, 31.08, -1354.9), range = 7 }

	tbl.LondonBoardAuto.getWeaponRemote = function()
		return tbl.getHeldToolRemote()
	end

	tbl.LondonBoardAuto.cachedLeft = nil
	tbl.LondonBoardAuto.cachedRight = nil

	local function fn6()
		local cachedLeft = tbl.LondonBoardAuto.cachedLeft
		local cachedRight = tbl.LondonBoardAuto.cachedRight
		if cachedLeft and cachedRight and cachedLeft.Parent and cachedRight.Parent then
			return cachedLeft, cachedRight
		end

		local ok, cachedLeft2, cachedRight2 = pcall(function()
			local london = workspace:FindFirstChild("London")
			if not london then
				return nil, nil
			end
			return london.Modes.Objective.SniperSection.BarricadedDoors.Left.Boards, london.Modes.Objective.SniperSection.BarricadedDoors.Right.Boards
		end)

		if not ok then
			return nil, nil
		end
		tbl.LondonBoardAuto.cachedLeft = cachedLeft2
		tbl.LondonBoardAuto.cachedRight = cachedRight2
		return cachedLeft2, cachedRight2
	end

	tbl.LondonBoardAuto.execute = function()
		if not tbl.LondonBoardAuto.enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart or (humanoidRootPart.Position - tbl.LondonBoardAuto.refPos).Magnitude > tbl.LondonBoardAuto.range then
			return
		end
		local v16 = tbl.LondonBoardAuto.getWeaponRemote()
		if not v16 then
			return
		end
		local v17, v18 = fn6()
		if not v17 or not v18 then
			return
		end

		for _, v19 in {
			function()
				v16:FireServer("PrepareSwing")
			end,
			function()
				v16:FireServer("Swing", "Over")
			end,
			function()
				v16:FireServer("HitCon", v17:GetChildren()[2], Vector3.new(-149.42076, 31.076683, -1354.8972), Vector3.new(-2.0772219e-05, 1, 7.6293945e-05))
			end,
			function()
				v16:FireServer("HitCon", v18:GetChildren()[2], Vector3.new(-145.23814, 33.006237, -1366.2483), Vector3.new(0.9428723, 7.6293945e-05, 0.33315423))
			end,
			function()
				v16:FireServer("HitCon", v17:GetChildren()[2], Vector3.new(-149.55505, 29.676874, -1354.6289), Vector3.new(-0.9428972, 5.841255e-06, -0.33308378))
			end,
			function()
				v16:FireServer("HitCon", v17:GetChildren()[2], Vector3.new(-149.55505, 29.676874, -1354.6289), Vector3.new(-0.9428972, 5.841255e-06, -0.33308378))
			end,
			function()
				v16:FireServer("HitCon", v17:GetChildren()[2], Vector3.new(-150.2777, 29.679218, -1351.9828), Vector3.new(0.9428972, -5.841255e-06, 0.33308378))
			end,
			function()
				v16:FireServer("HitCon", v18:GetChildren()[2], Vector3.new(-146.18898, 32.863514, -1363.5574), Vector3.new(0.9428723, 7.6293945e-05, 0.33315423))
			end,
		}, nil, nil do
			pcall(v19)
		end
	end

	tbl.LondonBoardAuto.start = function()
		if tbl.LondonBoardAuto.thread then
			return
		end
		tbl.LondonBoardAuto.enabled = true

		tbl.LondonBoardAuto.thread = task.spawn(function()
			while tbl.LondonBoardAuto.enabled do
				tbl.LondonBoardAuto.execute()
				task.wait(0.1)
			end
		end)
	end

	tbl.LondonBoardAuto.stop = function()
		tbl.LondonBoardAuto.enabled = false

		if tbl.LondonBoardAuto.thread then
			task.cancel(tbl.LondonBoardAuto.thread)
			tbl.LondonBoardAuto.thread = nil
		end
	end

	v15:AddToggle("LondonBoardToggle", {
		Text = "自动打伦敦四块木板",
		Default = false,
		Tooltip = fn4("自动攻击伦敦狙神处四块木板"),
		Callback = function(arg)
			if arg then
				tbl.LondonBoardAuto.start()
			else
				tbl.LondonBoardAuto.stop()
			end
		end,
	})

	tbl.autoBandage = { enabled = false, thread = nil, cooldown = 0, healedOnce = false }

	tbl.autoBandage.getHealth = function()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.Health or 0
	end

	tbl.autoBandage.getMaxHealth = function()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.MaxHealth or 100
	end

	tbl.autoBandage.findBandage = function()
		local character = localPlayer.Character

		if character then
			for _, v16 in character:GetChildren() do
				if v16:IsA("Tool") and v16.Name:lower():find("bandage") then
					return v16
				end
			end
		end

		local backpack = localPlayer:FindFirstChild("Backpack")

		if backpack then
			for _, v16 in backpack:GetChildren() do
				if v16:IsA("Tool") and v16.Name:lower():find("bandage") then
					return v16
				end
			end
		end

		return nil
	end

	tbl.autoBandage.zombieNear = function(arg, arg2)
		for _, v16 in { "Zombies", "Camera" }, nil, nil do
			local v17 = workspace:FindFirstChild(v16)

			if v17 then
				for _, v18 in v17:GetDescendants() do
					if v18:IsA("Model") and v18.Name == "m_Zombie" then
						local humanoidRootPart = v18:FindFirstChild("HumanoidRootPart")
						if humanoidRootPart and (humanoidRootPart.Position - arg).Magnitude <= arg2 then
							return true
						end
					end
				end
			end
		end

		return false
	end

	tbl.autoBandage.loop = function()
		while tbl.autoBandage.enabled do
			task.wait(0.5)
			local v16 = tbl.autoBandage.getHealth()
			local v17 = tbl.autoBandage.getMaxHealth()
			local n = v16 / v17 * 100

			if v17 <= v16 then
				tbl.autoBandage.healedOnce = false
			else
				if n < 50 then
					tbl.autoBandage.healedOnce = false
				end

				if not (tbl.autoBandage.healedOnce and n >= 50) then
					local character = localPlayer.Character
					local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

					if not (humanoidRootPart and tbl.autoBandage.zombieNear(humanoidRootPart.Position, 5)) then
						local v18 = tbl.autoBandage.findBandage()

						if v18 then
							local cooldown = tbl.autoBandage.cooldown

							if not (clock() - cooldown < 1) then
								tbl.autoBandage.cooldown = clock()

								if v18.Parent ~= character then
									pcall(function()
										v18.Parent = character
									end)

									task.wait(0.3)
								end

								local remoteEvent = v18:FindFirstChild("RemoteEvent")

								if remoteEvent then
									pcall(function()
										remoteEvent:FireServer()
									end)

									tbl.autoBandage.healedOnce = true
								end

								task.wait(1)
							end
						end
					end
				end
			end
		end
	end

	tbl.autoBandage.start = function()
		if tbl.autoBandage.thread then
			return
		end
		tbl.autoBandage.enabled = true
		tbl.autoBandage.healedOnce = false
		tbl.autoBandage.thread = task.spawn(tbl.autoBandage.loop)
	end

	tbl.autoBandage.stop = function()
		tbl.autoBandage.enabled = false
		tbl.autoBandage.healedOnce = false

		if tbl.autoBandage.thread then
			task.cancel(tbl.autoBandage.thread)
			tbl.autoBandage.thread = nil
		end
	end

	v15:AddToggle("AutoBandageToggle", {
		Text = "自动打绷带",
		Default = false,
		Tooltip = fn4("血量低于75%时自动使用绷带（仅一次，低于50%重置）"),
		Callback = function(arg)
			if arg then
				tbl.autoBandage.start()
			else
				tbl.autoBandage.stop()
			end
		end,
	})

	tbl.autoWatch = { enabled = false, thread = nil, range = 5, done = false }

	tbl.autoWatch.getModelPos = function(arg)
		local pivot = arg:GetPivot()
		if pivot then
			return pivot.Position
		end

		for _, v16 in arg:GetDescendants() do
			if v16:IsA("BasePart") then
				return v16.Position
			end
		end

		return nil
	end

	tbl.autoWatch.getHRP = function()
		local character = localPlayer.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end

	tbl.autoWatch.loop = function()
		tbl.autoWatch.done = false

		while tbl.autoWatch.enabled and not tbl.autoWatch.done do
			task.wait(0.2)
			local v16 = tbl.autoWatch.getHRP()

			if not v16 then
				task.wait(0.5)
			else
				local westminster = workspace:FindFirstChild("Westminster")

				if westminster then
					local modes = westminster:FindFirstChild("Modes")

					if modes then
						local objective = modes:FindFirstChild("Objective")

						if objective then
							local wellingtonScene = objective:FindFirstChild("WellingtonScene")

							if wellingtonScene then
								local pocketWatch = wellingtonScene:FindFirstChild("Pocket Watch")

								if pocketWatch then
									local proximityPrompt = pocketWatch:FindFirstChild("ProximityPrompt")

									if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") and proximityPrompt.Enabled then
										local v17 = tbl.autoWatch.getModelPos(pocketWatch)

										if v17 and (v17 - v16.Position).Magnitude <= tbl.autoWatch.range then
											pcall(function()
												fireproximityprompt(proximityPrompt)
											end)

											if proximityPrompt.HoldDuration > 0 then
												for i = 1, 50 do
													pcall(function()
														fireproximityprompt(proximityPrompt)
													end)

													task.wait(0.01)
												end
											end
										end
									end
								else
									tbl.autoWatch.done = true

									pcall(function()
										tbl.notify(fn3("自动拿怀表已完成"), 2)
									end)
								end
							end
						end
					end
				end
			end
		end

		if tbl.autoWatch.done then
			tbl.autoWatch.enabled = false
			tbl.autoWatch.thread = nil
		end
	end

	tbl.autoWatch.start = function()
		if tbl.autoWatch.thread then
			return
		end
		tbl.autoWatch.enabled = true
		tbl.autoWatch.done = false
		tbl.autoWatch.thread = task.spawn(tbl.autoWatch.loop)
	end

	tbl.autoWatch.stop = function()
		tbl.autoWatch.enabled = false
		tbl.autoWatch.done = false

		if tbl.autoWatch.thread then
			task.cancel(tbl.autoWatch.thread)
			tbl.autoWatch.thread = nil
		end
	end

	v15:AddToggle("AutoWatchToggle", {
		Text = "自动拿怀表",
		Default = false,
		Tooltip = fn4("自动拾取威斯敏斯特怀表"),
		Callback = function(arg)
			if arg then
				tbl.autoWatch.start()
			else
				tbl.autoWatch.stop()
			end
		end,
	})

	tbl.autoFlag = { enabled = false, thread = nil, range = 5, done = false }

	tbl.autoFlag.getHRP = function()
		return tbl.autoWatch.getHRP()
	end

	tbl.autoFlag.getModelPos = function(arg)
		return tbl.autoWatch.getModelPos(arg)
	end

	tbl.autoFlag.loop = function()
		tbl.autoFlag.done = false

		while tbl.autoFlag.enabled and not tbl.autoFlag.done do
			task.wait(0.3)
			local v16 = tbl.autoFlag.getHRP()

			if not v16 then
				task.wait(0.5)
			else
				local exitTo = nil

				for _, v17 in workspace:GetDescendants() do
					if v17:IsA("ProximityPrompt") and v17.Enabled then
						local parent = v17.Parent

						if parent and parent.Name == "Standard" and parent:IsA("Model") then
							local v18 = tbl.autoFlag.getModelPos(parent)
							if v18 and (v18 - v16.Position).Magnitude <= tbl.autoFlag.range then
								exitTo = 1
								break
							end
						end
					end
				end

				if exitTo == 1 then
					for i = 1, 25 do
						if s4.Enabled then
							pcall(function()
								fireproximityprompt(s4)
							end)

							if s4.HoldDuration > 0 then
								for i2 = 1, 30 do
									pcall(function()
										fireproximityprompt(s4)
									end)

									task.wait(0.01)
								end
							end

							task.wait(0.2)
							continue
						end

						break
					end

					tbl.autoFlag.done = true

					pcall(function()
						tbl.notify(fn3("自动抢旗杆已完成"), 2)
					end)
				end
			end
		end

		if tbl.autoFlag.done then
			tbl.autoFlag.enabled = false
			tbl.autoFlag.thread = nil
		end
	end

	tbl.autoFlag.start = function()
		if tbl.autoFlag.thread then
			return
		end
		tbl.autoFlag.enabled = true
		tbl.autoFlag.done = false
		tbl.autoFlag.thread = task.spawn(tbl.autoFlag.loop)
	end

	tbl.autoFlag.stop = function()
		tbl.autoFlag.enabled = false
		tbl.autoFlag.done = false

		if tbl.autoFlag.thread then
			task.cancel(tbl.autoFlag.thread)
			tbl.autoFlag.thread = nil
		end
	end

	v15:AddToggle("AutoFlagToggle", {
		Text = "自动抢旗杆",
		Default = false,
		Tooltip = fn4("自动拾取威斯敏斯特旗杆"),
		Callback = function(arg)
			if arg then
				tbl.autoFlag.start()
			else
				tbl.autoFlag.stop()
			end
		end,
	})

	tbl.autoAttackDoor = { enabled = false, thread = nil, range = 10, attackCooldown = 0.3 }

	tbl.autoAttackDoor.getWeaponRemote = function()
		return tbl.getHeldToolRemote()
	end

	tbl.autoAttackDoor.findTargets = function()
		local character = localPlayer.Character
		if not character then
			return {}
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return {}
		end
		local position = humanoidRootPart.Position
		local tbl8 = {}
		local tbl9 = {}

		for _, v16 in workspace:GetDescendants() do
			if v16:IsA("BasePart") and v16.CanQuery ~= false and v16.Parent then
				local magnitude = (v16.Position - position).Magnitude

				if magnitude <= tbl.autoAttackDoor.range then
					local str2 = v16.Name:upper()

					if v16.Name == "Main" or str2:find("DOOR") or str2:find("GATE") then
						local str3 = tostring(v16)

						if not tbl9[str3] then
							tbl9[str3] = true
							table.insert(tbl8, { part = v16, dist = magnitude })
						end
					end
				end
			end
		end

		table.sort(tbl8, function(arg, arg2)
			return arg.dist < arg2.dist
		end)

		return tbl8
	end

	tbl.autoAttackDoor.loop = function()
		while tbl.autoAttackDoor.enabled do
			local v16 = tbl.autoAttackDoor.getWeaponRemote()

			if v16 and localPlayer.Character then
				local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then
					local v17 = tbl.autoAttackDoor.findTargets()

					if #v17 > 0 then
						local v18 = v17[1]
						local position = v18.part.Position
						local unit = (humanoidRootPart.Position - position).Unit

						pcall(function()
							v16:FireServer("PrepareSwing")
							task.wait(0.02)
							v16:FireServer("Swing", "Side")
							task.wait(0.02)
							v16:FireServer("HitCon", v18.part, position, unit)
						end)

						task.wait(tbl.autoAttackDoor.attackCooldown)
					end
				end
			end

			task.wait(0.1)
		end
	end

	tbl.autoAttackDoor.start = function()
		if tbl.autoAttackDoor.thread then
			return
		end
		tbl.autoAttackDoor.enabled = true
		tbl.autoAttackDoor.thread = task.spawn(tbl.autoAttackDoor.loop)
	end

	tbl.autoAttackDoor.stop = function()
		tbl.autoAttackDoor.enabled = false

		if tbl.autoAttackDoor.thread then
			task.cancel(tbl.autoAttackDoor.thread)
			tbl.autoAttackDoor.thread = nil
		end
	end

	v15:AddToggle("AutoAttackDoorToggle", {
		Text = "自动攻击门",
		Default = false,
		Tooltip = fn4("自动攻击附近的门"),
		Callback = function(arg)
			if arg then
				tbl.autoAttackDoor.start()
			else
				tbl.autoAttackDoor.stop()
			end
		end,
	})

	tbl.autoFindDoctor = {
		enabled = false,
		thread = nil,
		threshold = 40,
		teleportCount = 0,
		maxTeleports = 2,
		prevHP = 100,
		trigger = 50,
	}

	tbl.autoFindDoctor.getHRP = function(arg)
		return arg and arg:FindFirstChild("HumanoidRootPart")
	end

	tbl.autoFindDoctor.getHealth = function()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.Health or 0
	end

	tbl.autoFindDoctor.getMaxHealth = function()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.MaxHealth or 100
	end

	tbl.autoFindDoctor.isDoctor = function(arg)
		if arg == localPlayer then
			return false
		end

		if arg:GetAttribute("CurrentClass") == "Surgeon" then
			return true
		end
		local character = arg.Character

		if character then
			if character:GetAttribute("CurrentClass") == "Surgeon" then
				return true
			end

			if character:FindFirstChild("MedicalSupplies") then
				return true
			end

			if character:FindFirstChild("Meter") then
				return true
			end
		end

		return false
	end

	tbl.autoFindDoctor.hasSupplies = function(arg)
		local character = arg.Character
		if not character then
			return false
		end
		local meter = character:FindFirstChild("Meter")
		return meter and meter.Value > 0 or false
	end

	tbl.autoFindDoctor.findNearestDoctor = function(arg)
		local n = 999
		local v16 = nil

		for _, v17 in v4:GetPlayers() do
			if not (not tbl.autoFindDoctor.isDoctor(v17) or not tbl.autoFindDoctor.hasSupplies(v17)) then
				local character = v17.Character
				character = character and tbl.autoFindDoctor.getHRP(character)

				if character then
					local magnitude = (character.Position - arg).Magnitude

					if magnitude < n then
						n = magnitude
						v16 = v17
					end
				end
			end
		end

		return v16, n
	end

	tbl.autoFindDoctor.teleportToDoctor = function(arg)
		local character = arg.Character
		local v16 = character and tbl.autoFindDoctor.getHRP(character)
		if not v16 then
			return false
		end
		local character2 = localPlayer.Character
		character2 = character2 and tbl.autoFindDoctor.getHRP(character2)
		if not character2 then
			return false
		end
		local n = v16.Position + v16.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)
		if not pcall(function()
			character2.CFrame = cframe(n)
		end) then
			return false
		end
		local n2 = clock() + 1

		while clock() < n2 do
			local character3 = localPlayer.Character
			character3 = character3 and tbl.autoFindDoctor.getHRP(character3)

			if character3 then
				pcall(function()
					character3.CFrame = cframe(n)
				end)
			end

			task.wait()
		end

		return true
	end

	tbl.autoFindDoctor.loop = function()
		tbl.autoFindDoctor.teleportCount = 0
		tbl.autoFindDoctor.prevHP = 100
		tbl.autoFindDoctor.trigger = tbl.autoFindDoctor.threshold + 10

		while tbl.autoFindDoctor.enabled do
			task.wait(1)
			local character = localPlayer.Character
			local v16 = character and tbl.autoFindDoctor.getHRP(character)

			if not v16 then
				tbl.autoFindDoctor.teleportCount = 0
				tbl.autoFindDoctor.prevHP = 100
			else
				local v17 = tbl.autoFindDoctor.getHealth()
				local n = v17 / tbl.autoFindDoctor.getMaxHealth() * 100

				if n >= tbl.autoFindDoctor.trigger then
					if tbl.autoFindDoctor.teleportCount > 0 then
						print("[自动找医生] 血量恢复(" .. floor(n) .. "%)，重置")
					end

					tbl.autoFindDoctor.teleportCount = 0
					tbl.autoFindDoctor.prevHP = v17
				elseif n < tbl.autoFindDoctor.threshold then
					if v17 > tbl.autoFindDoctor.prevHP then
						tbl.autoFindDoctor.teleportCount = 0
						tbl.autoFindDoctor.prevHP = v17
					else
						local v18, v19 = tbl.autoFindDoctor.findNearestDoctor(v16.Position)

						if not v18 then
							tbl.autoFindDoctor.prevHP = v17
						elseif v19 <= 20 then
							tbl.autoFindDoctor.teleportCount = 0
							tbl.autoFindDoctor.prevHP = v17
						else
							if tbl.autoFindDoctor.teleportCount < tbl.autoFindDoctor.maxTeleports then
								tbl.autoFindDoctor.teleportCount = tbl.autoFindDoctor.teleportCount + 1

								if not tbl.autoFindDoctor.teleportToDoctor(v18) then
									tbl.autoFindDoctor.teleportCount = tbl.autoFindDoctor.teleportCount - 1
								end
							end

							tbl.autoFindDoctor.prevHP = v17
						end
					end
				else
					if tbl.autoFindDoctor.teleportCount > 0 and n >= tbl.autoFindDoctor.threshold and n < tbl.autoFindDoctor.trigger then
						if v17 > tbl.autoFindDoctor.prevHP then
							tbl.autoFindDoctor.teleportCount = 0
						end
					end

					tbl.autoFindDoctor.prevHP = v17
				end
			end
		end
	end

	tbl.autoFindDoctor.start = function()
		if tbl.autoFindDoctor.thread then
			return
		end
		tbl.autoFindDoctor.enabled = true
		tbl.autoFindDoctor.teleportCount = 0
		tbl.autoFindDoctor.prevHP = 100
		tbl.autoFindDoctor.trigger = tbl.autoFindDoctor.threshold + 10
		tbl.autoFindDoctor.thread = task.spawn(tbl.autoFindDoctor.loop)
	end

	tbl.autoFindDoctor.stop = function()
		tbl.autoFindDoctor.enabled = false

		if tbl.autoFindDoctor.thread then
			task.cancel(tbl.autoFindDoctor.thread)
			tbl.autoFindDoctor.thread = nil
		end

		tbl.autoFindDoctor.teleportCount = 0
		tbl.autoFindDoctor.prevHP = 100
	end

	v15:AddToggle("AutoFindDoctorToggle", {
		Text = "自动找医生",
		Default = false,
		Tooltip = fn4("血量低于阈值（默认40%）且还在掉血时传送至医生"),
		Callback = function(arg)
			if arg then
				tbl.autoFindDoctor.start()
			else
				tbl.autoFindDoctor.stop()
			end
		end,
	})

	v15:AddSlider("DoctorThreshold", {
		Text = "找医生血量阈值 (%)",
		Default = 40,
		Min = 1,
		Max = 100,
		Suffix = "%",
		Callback = function(threshold)
			tbl.autoFindDoctor.threshold = threshold
			tbl.autoFindDoctor.trigger = threshold + 10
		end,
	})

	v15:AddToggle("AutoHelpToggle", {
		Text = "自动求救",
		Default = false,
		Tooltip = fn4("血量低于80%时自动发送语音求助"),
		Callback = function(arg)
			if arg then
				tbl.autoHelp.start()
			else
				tbl.autoHelp.stop()
			end
		end,
	})

	tbl.autoDoorEnabled = false
	tbl.autoDoorThread = nil
	tbl.processingDoors = {}

	tbl.autoDoorLoop = function()
		while tbl.autoDoorEnabled do
			local character = localPlayer.Character
			character = character and character:FindFirstChild("HumanoidRootPart")

			if character then
				for _, v16 in workspace:GetDescendants() do
					if v16.Name == "Main" and v16:IsA("Model") then
						local ok, result = pcall(function()
							return v16:GetPivot()
						end)

						if ok and result and (character.Position - result.Position).Magnitude <= 23 then
							local attribute = v16:GetAttribute("Open")

							if attribute == nil then
								pcall(function()
									attribute = v16.Open
								end)
							end

							if attribute == false then
								local main = v16:FindFirstChild("Main")
								local interact = main and main:FindFirstChild("Interact")

								if interact and interact:IsA("RemoteEvent") and not tbl.processingDoors[v16] then
									tbl.processingDoors[v16] = true

									task.spawn(function()
										interact:FireServer()
										task.wait(0)
										tbl.processingDoors[v16] = nil
									end)
								end
							end
						end
					end
				end
			end

			task.wait(0)
		end
	end

	tbl.toggleAutoDoor = function(autoDoorEnabled)
		tbl.autoDoorEnabled = autoDoorEnabled

		if autoDoorEnabled then
			if not tbl.autoDoorThread then
				tbl.autoDoorThread = task.spawn(tbl.autoDoorLoop)
			end
		elseif tbl.autoDoorThread then
			task.cancel(tbl.autoDoorThread)
			tbl.autoDoorThread = nil
		end
	end

	v15:AddToggle("AutoDoorToggle", {
		Text = "自动开门",
		Default = false,
		Tooltip = fn4("自动开启附近场景中的门（适用于所有地图）"),
		Callback = function(arg)
			tbl.toggleAutoDoor(arg)
		end,
	})
end

tbl.waveNum = 1

tbl.sendChatCmd = function(arg)
	if not pcall(function()
		v(game:GetService("TextChatService")):FindFirstChild("TextChannels").RBXGeneral:SendAsync(arg)
	end) then
		local events = v7:FindFirstChild("Events")
		local chatUpdate = events and events:FindFirstChild("ChatUpdate")

		if chatUpdate then
			pcall(function()
				chatUpdate:FireServer(arg)
			end)
		end
	end
end

local tbl4
tbl4 = { _velHistory = {} }
local v15 = tbl3.AutoFunc:AddGroupbox({ Side = "Right", Name = "PVP 功能", IconName = "swords", Description = "战斗辅助" })

v15:AddToggle("PvpAimbotToggle", {
	Text = "开启自瞄",
	Default = false,
	Callback = function(arg)
		if tbl4 and tbl4.toggle then
			tbl4.toggle(arg)
		end
	end,
})

v15:AddToggle("PvpSilentToggle", {
	Text = "启用静默",
	Default = false,
	Callback = function(silentMode)
		tbl4.silentMode = silentMode

		if tbl4.aimEnabled then
			if silentMode then
				tbl4.setupSilentHook()
			else
				tbl4.removeSilentHook()
			end
		end
	end,
})

v15:AddDropdown("PvpAimPart", {
	Text = "瞄准部位",
	Values = { "头部", "身体" },
	Value = "头部",
	FormatDisplayValue = function(arg)
		return str == "English" and (tbl2[arg] or arg) or arg
	end,
	Callback = function(arg)
		if tbl4 and tbl4.setAimPart then
			tbl4.setAimPart(arg)
		end
	end,
})

v15:AddSlider("PvpFOVSize", {
	Text = "瞄准大小",
	Default = 90,
	Min = 1,
	Max = 360,
	Suffix = "°",
	Callback = function(arg)
		if tbl4 and tbl4.setFOV then
			tbl4.setFOV(arg)
		end
	end,
})

v15:AddToggle("PvpTeamCheck", {
	Text = "队伍检测",
	Default = false,
	Callback = function(arg)
		if tbl4 and tbl4.toggleTeamCheck then
			tbl4.toggleTeamCheck(arg)
		end
	end,
})

v15:AddToggle("PvpWallCheck", {
	Text = "墙体检测",
	Default = true,
	Callback = function(arg)
		if tbl4 and tbl4.toggleWallCheck then
			tbl4.toggleWallCheck(arg)
		end
	end,
})

v15:AddToggle("PvpPrediction", {
	Text = "子弹预判",
	Default = false,
	Callback = function(arg)
		if tbl4 and tbl4.togglePrediction then
			tbl4.togglePrediction(arg)
		end
	end,
})

v15:AddToggle("PvpMeleeAura", {
	Text = "杀戮光环（近战）",
	Default = false,
	Tooltip = fn4("体验虐杀的快感"),
	Callback = function(arg)
		if tbl4 and tbl4.toggleMelee then
			tbl4.toggleMelee(arg)
		end
	end,
})

v15:AddToggle("PvpTeleport", {
	Text = "预判传送至敌方身后",
	Default = false,
	Tooltip = fn4("预判传送"),
	Callback = function(arg)
		if tbl4 and tbl4.toggleTeleport then
			tbl4.toggleTeleport(arg)
		end
	end,
})

v15:AddToggle("PvpForceEquip", {
	Text = "强制装备武器",
	Default = false,
	Tooltip = fn4("持续装备近战武器"),
	Callback = function(arg)
		if tbl4 and tbl4.toggleForceEquip then
			tbl4.toggleForceEquip(arg)
		end
	end,
})

tbl4.weaponSpeedMap = tbl.WEAPON_SPEED_MAP

tbl4.getCurrentBulletSpeed = function()
	return tbl.sharedGetCurrentBulletSpeed()
end

tbl4.getPing = function()
	return tbl.sharedGetPing()
end

tbl4.getShotsLoaded = function()
	local character = localPlayer.Character
	return tbl.sharedGetShotsLoaded(character and character:FindFirstChildOfClass("Tool"))
end

tbl4.aimEnabled = false
tbl4.aimPart = "Head"
tbl4.showFov = false
tbl4.fov = 90
tbl4.teamCheck = false
tbl4.prediction = false
tbl4.wallCheck = true
tbl4.aimConn = nil
tbl4.meleeEnabled = false
tbl4.meleeConn = nil
tbl4.tpEnabled = false
tbl4.tpThread = nil
tbl4.tpTarget = nil
tbl4.tpHighlight = nil
tbl4.bulletSpeed = 700
tbl4.silentMode = false
tbl4.silentHook = nil
tbl4.silentTarget = nil
tbl4._lastDistNotify = 0
tbl4._velHistory = {}
tbl4.lastNotifiedPlayer = nil
tbl4.indicatorData = nil
tbl4.indicatorPart = nil

do
	local function fn6()
		local character = localPlayer.Character
		return tbl.sharedIsGun(character and character:FindFirstChildOfClass("Tool"))
	end

	local function fn7(arg, arg2, arg3)
		local tbl5 = {
			Vector3.zero,
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(-0.5, 0.5, -0.5),
			Vector3.new(0.5, -0.5, 0.5),
			Vector3.new(-0.5, -0.5, -0.5),
			Vector3.new(0.8, 0, 0),
			Vector3.new(-0.8, 0, 0),
			Vector3.new(0, 0.8, 0),
			Vector3.new(0, -0.8, 0),
		}

		local n = #tbl5
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local filterDescendantsInstances = {}

		for _, v16 in v4:GetPlayers() do
			if v16.Character then
				table.insert(filterDescendantsInstances, v16.Character)
			end
		end

		if arg3 then
			table.insert(filterDescendantsInstances, arg3)
		end

		raycastParams.FilterDescendantsInstances = filterDescendantsInstances
		local n2 = 0

		for _, v16 in tbl5, nil, nil do
			local hit = workspace:Raycast(arg, arg2 + v16 - arg, raycastParams)

			if hit then
				local instance = hit.Instance

				if instance and instance:IsA("BasePart") and instance.CanCollide then
					n2 += 1
				end
			end
		end

		return n2 > n / 2
	end

	local function fn8()
		local v16 = localPlayer
		local character = v16.Character
		if not character then
			return nil
		end
		local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
		if not head then
			return nil
		end
		local currentCamera = workspace.CurrentCamera
		local n = tbl4.getCurrentBulletSpeed()

		if n <= 0 then
			n = 700
		end

		local n2 = tbl4.getPing() / 1000

		if not tbl4._velHistory then
			tbl4._velHistory = {}
		end

		local huge = math.huge
		local huge2 = math.huge
		local tbl5 = nil

		for _, v17 in v4:GetPlayers() do
			if v17 ~= v16 then
				if not (tbl.isMarked and tbl.isMarked(v17)) then
					local character2 = v17.Character

					if character2 then
						local humanoid = character2:FindFirstChildOfClass("Humanoid")

						if not (not humanoid or humanoid.Health <= 0) then
							if not (humanoid.Health > 1000) then
								if tbl4.teamCheck then
									local v18 = tbl.getPlayerTeam(v16)
									local v19 = tbl.getPlayerTeam(v17)
									if v18 and v19 and v18 == v19 then
										continue
									end
								end

								local head2 = character2:FindFirstChild(tbl4.aimPart) or character2:FindFirstChild("Head") or character2:FindFirstChild("HumanoidRootPart")

								if head2 then
									local magnitude = (head2.Position - currentCamera.CFrame.Position).Magnitude

									if not (magnitude > 1000) then
										if tbl4.wallCheck then
											if fn7(head.Position, head2.Position, character2) then
												continue
											end
										end

										if tbl4.silentMode then
											if huge <= magnitude then
												continue
											end
											huge = magnitude
										else
											local v18, v19 = currentCamera:WorldToViewportPoint(head2.Position)
											if not v18 or not v19 then
												continue
											end
											local n3 = currentCamera.ViewportSize / 2
											local magnitude2 = (vector2(v18.X, v18.Y) - n3).Magnitude
											if magnitude2 > tbl4.fov or magnitude2 >= huge2 then
												continue
											end
											huge2 = magnitude2
										end

										local position = head2.Position
										local flag = tbl4.prediction and n > 0
										local v18 = nil
										local v19

										if flag then
											local humanoidRootPart = character2:FindFirstChild("HumanoidRootPart")
											local v20 = nil

											if humanoidRootPart then
												local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity
												local flag2 = assemblyLinearVelocity and assemblyLinearVelocity.Magnitude > 0.3
												local v21 = nil

												if flag2 then
													if not tbl4._velHistory[v17] then
														tbl4._velHistory[v17] = {}
													end

													local v22 = tbl4._velHistory[v17]
													table.insert(v22, assemblyLinearVelocity)

													if #v22 > 8 then
														table.remove(v22, 1)
													end

													local v23 = vector()
													local n3 = 0

													for i = 1, #v22 do
														local n4 = i / #v22
														v23 += v22[i] * n4
														n3 += n4
													end

													if n3 > 0 then
														v23 /= n3
													end

													local n4 = 0

													if #v22 >= 2 then
														local v24 = v22[#v22 - 1].Unit:Dot(v22[#v22].Unit)
														n4 = 1 - abs(v24)
													end

													local n5 = 0

													if #v22 >= 2 then
														local magnitude2 = v22[#v22 - 1].Magnitude
														local magnitude3 = v22[#v22].Magnitude

														if magnitude2 > 0.1 then
															n5 = abs(magnitude3 - magnitude2) / magnitude2
														end
													end

													local n6 = 1.2 * (1 - min(1, n4 * 0.8 + n5 * 0.4) * 0.6)
													local n7 = magnitude / n + n2
													local n8 = vector(v23.X, 0, v23.Z) * n7 * n6
													local v24 = min(20, magnitude * 0.1)

													if v24 < n8.Magnitude then
														n8 = n8.Unit * v24
													end

													local y = v23.Y
													local n9

													if y < -0.5 then
														n9 = -(0.5 * workspace.Gravity * n7 * n7 * 0.25)
													else
														n9 = 0

														if y > 1.5 then
															n9 = y * n7 * 0.12
														end
													end

													local n10 = head2.Position + n8 + vector(0, n9, 0)
													v19 = n10
													v18 = n10
												else
													v19 = position
													v18 = v21
												end
											else
												v19 = position
												v18 = v20
											end
										else
											v19 = position
										end

										tbl5 = {
											player = v17,
											aimPos = v19,
											part = head2,
											dist = magnitude,
											bulletSpeed = n,
											predictedPos = v18,
										}
									end
								end
							end
						end
					end
				end
			end
		end

		for k in tbl4._velHistory, nil, nil do
			if not k or not k.Parent then
				tbl4._velHistory[k] = nil
			end
		end

		return tbl5
	end

	tbl4.updateIndicator = function(position, hasTarget)
		if not position then
			if tbl4.indicatorData then
				if tbl4.indicatorData.billboard then
					tbl4.indicatorData.billboard:Destroy()
				end

				tbl4.indicatorData = nil
			end

			if tbl4.indicatorPart then
				tbl4.indicatorPart:Destroy()
				tbl4.indicatorPart = nil
			end

			return
		end

		if not tbl4.indicatorPart or not tbl4.indicatorPart.Parent then
			tbl4.indicatorPart = Instance.new("Part")
			tbl4.indicatorPart.Name = "AimIndicatorAnchor"
			tbl4.indicatorPart.Size = Vector3.new(0.2, 0.2, 0.2)
			tbl4.indicatorPart.Transparency = 1
			tbl4.indicatorPart.CanCollide = false
			tbl4.indicatorPart.Anchored = true
			tbl4.indicatorPart.Parent = workspace
		end

		tbl4.indicatorPart.Position = position

		if not tbl4.indicatorData or not tbl4.indicatorData.billboard or not tbl4.indicatorData.billboard.Parent then
			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Size = UDim2.new(0, 25, 0, 25)
			billboardGui.StudsOffset = Vector3.zero
			billboardGui.AlwaysOnTop = true
			billboardGui.Adornee = tbl4.indicatorPart
			billboardGui.Parent = tbl4.indicatorPart
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundTransparency = 1
			frame.Parent = billboardGui
			local frame2 = Instance.new("Frame")
			frame2.Size = UDim2.new(1, 0, 1, 0)
			frame2.BackgroundTransparency = 1
			frame2.Parent = frame
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Thickness = 1
			uiStroke.Color = color(255, 255, 255)
			uiStroke.Transparency = 0.2
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Parent = frame2
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = frame2
			local frame3 = Instance.new("Frame")
			frame3.Size = UDim2.new(0.65, 0, 0.65, 0)
			frame3.Position = UDim2.new(0.175, 0, 0.175, 0)
			frame3.BackgroundTransparency = 1
			frame3.Parent = frame
			local uiStroke2 = Instance.new("UIStroke")
			uiStroke2.Thickness = 0.7
			uiStroke2.Color = color(255, 255, 255)
			uiStroke2.Transparency = 0.35
			uiStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke2.Parent = frame3
			local uiCorner2 = Instance.new("UICorner")
			uiCorner2.CornerRadius = UDim.new(1, 0)
			uiCorner2.Parent = frame3
			local frame4 = Instance.new("Frame")
			frame4.Size = UDim2.new(0, 1, 0, 12)
			frame4.Position = UDim2.new(0.5, -0.5, 0.15, 0)
			frame4.BackgroundColor3 = color(255, 255, 255)
			frame4.BackgroundTransparency = 0.3
			frame4.Parent = frame
			local uiCorner3 = Instance.new("UICorner")
			uiCorner3.CornerRadius = UDim.new(0, 1)
			uiCorner3.Parent = frame4
			local uiGradient = Instance.new("UIGradient")
			local new = NumberSequenceKeypoint.new
			uiGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), new(1, 0.1) })
			uiGradient.Rotation = 180
			uiGradient.Parent = frame4
			local tbl5 = {}

			for _, v16 in { { -1, -1, 0 }, { 1, -1, 90 }, { -1, 1, -90 }, { 1, 1, 180 } }, nil, nil do
				local frame5 = Instance.new("Frame")
				frame5.Size = UDim2.new(0, 3.5, 0, 3.5)
				frame5.BackgroundTransparency = 1
				frame5.Position = UDim2.new(0.5 + v16[1] * 0.36, -1.75, 0.5 + v16[2] * 0.36, -1.75)
				frame5.Rotation = v16[3]
				frame5.Parent = frame
				local frame6 = Instance.new("Frame")
				frame6.Size = UDim2.new(1, 0, 0, 1)
				frame6.BackgroundColor3 = color(255, 255, 255)
				frame6.BackgroundTransparency = 0.4
				frame6.Parent = frame5
				local frame7 = Instance.new("Frame")
				frame7.Size = UDim2.new(0, 1, 1, 0)
				frame7.BackgroundColor3 = color(255, 255, 255)
				frame7.BackgroundTransparency = 0.4
				frame7.Parent = frame5
				table.insert(tbl5, frame5)
			end

			tbl4.indicatorData = {
				billboard = billboardGui,
				container = frame,
				outer = frame2,
				outerStroke = uiStroke,
				inner = frame3,
				innerStroke = uiStroke2,
				scanline = frame4,
				corners = tbl5,
				rotation = 0,
				hasTarget = false,
			}

			task.spawn(function()
				local rotation = 0

				while tbl4.indicatorData and tbl4.indicatorData.billboard and tbl4.indicatorData.billboard.Parent do
					rotation += 3

					if tbl4.indicatorData.outer then
						tbl4.indicatorData.outer.Rotation = rotation
					end

					if tbl4.indicatorData.inner then
						tbl4.indicatorData.inner.Rotation = -rotation * 0.6
					end

					if tbl4.indicatorData.scanline then
						tbl4.indicatorData.scanline.Rotation = rotation * 1.5
					end

					local hasTarget2 = tbl4.indicatorData.hasTarget
					local transparency = (math.sin(clock() * 4) + 1) / 2 * 0.2 + 0.15
					local transparency2 = (math.sin(clock() * 4 + 0.5) + 1) / 2 * 0.25 + 0.2

					if hasTarget2 then
						local v16 = color(0, floor((0.7 + (math.sin(clock() * 2) + 1) / 2 * 0.3) * 255), 80)

						if tbl4.indicatorData.outerStroke then
							tbl4.indicatorData.outerStroke.Color = v16
							tbl4.indicatorData.outerStroke.Transparency = transparency
						end

						if tbl4.indicatorData.innerStroke then
							tbl4.indicatorData.innerStroke.Color = v16
							tbl4.indicatorData.innerStroke.Transparency = transparency2
						end

						if tbl4.indicatorData.scanline then
							tbl4.indicatorData.scanline.BackgroundColor3 = v16
							tbl4.indicatorData.scanline.BackgroundTransparency = 0.3
						end

						for _, v17 in tbl4.indicatorData.corners, nil, nil do
							for _, v18 in v17:GetChildren() do
								if v18:IsA("Frame") then
									v18.BackgroundColor3 = v16
								end
							end
						end
					else
						local v16 = color(255, 255, 255)

						if tbl4.indicatorData.outerStroke then
							tbl4.indicatorData.outerStroke.Color = v16
							tbl4.indicatorData.outerStroke.Transparency = transparency
						end

						if tbl4.indicatorData.innerStroke then
							tbl4.indicatorData.innerStroke.Color = v16
							tbl4.indicatorData.innerStroke.Transparency = transparency2
						end

						if tbl4.indicatorData.scanline then
							tbl4.indicatorData.scanline.BackgroundColor3 = v16
							tbl4.indicatorData.scanline.BackgroundTransparency = 0.3
						end

						for _, v17 in tbl4.indicatorData.corners, nil, nil do
							for _, v18 in v17:GetChildren() do
								if v18:IsA("Frame") then
									v18.BackgroundColor3 = v16
								end
							end
						end
					end

					task.wait(0.02)
				end
			end)
		else
			if tbl4.indicatorData.billboard.Adornee ~= tbl4.indicatorPart then
				tbl4.indicatorData.billboard.Adornee = tbl4.indicatorPart
			end

			tbl4.indicatorData.hasTarget = hasTarget
		end
	end

	tbl4.hideIndicator = function()
		if tbl4.indicatorData then
			if tbl4.indicatorData.billboard then
				tbl4.indicatorData.billboard:Destroy()
			end

			tbl4.indicatorData = nil
		end

		if tbl4.indicatorPart then
			tbl4.indicatorPart:Destroy()
			tbl4.indicatorPart = nil
		end
	end

	tbl4.setupSilentHook = function()
		if tbl4.silentHook then
			return
		end

		if type(hookmetamethod) ~= "function" then
			warn("静默自瞄需要 hookmetamethod")
			return
		end

		tbl4.silentHook = hookmetamethod(game, "__namecall", function(arg, ...)
			local v16 = table.pack(...)

			if getnamecallmethod() == "FireServer" and tbl4.aimEnabled and tbl4.silentMode then
				local tbl5 = { ... }

				if tbl5[1] == "Fire" and tbl4.silentTarget and tbl4.silentTarget.aimPos then
					if localPlayer.Character then
						local tbl6 = {}

						for i = 1, #tbl5 do
							tbl6[i] = tbl5[i]
						end

						if #tbl6 >= 3 then
							tbl6[3] = tbl4.silentTarget.aimPos
						end

						return tbl4.silentHook(arg, unpack(tbl6))
					end
				end

				return tbl4.silentHook(arg, table.unpack(v16, 1, v16.n))
			end

			return tbl4.silentHook(arg, ...)
		end)
	end

	tbl4.removeSilentHook = function()
		if tbl4.silentHook then
			hookmetamethod(game, "__namecall", tbl4.silentHook)
			tbl4.silentHook = nil
		end
	end

	local function fn9()
		while tbl4.aimEnabled do
			if not fn6() then
				tbl4.hideIndicator()
				task.wait()
			else
				local v16 = fn8()

				if v16 and v16.player and v16.player.Character then
					tbl4.silentTarget = v16
					tbl4.updateIndicator(v16.aimPos, true)

					if v16.player ~= tbl4.lastNotifiedPlayer then
						tbl4.lastNotifiedPlayer = v16.player

						pcall(function()
							local bulletSpeed = v16.bulletSpeed or 0
							tbl.notify(str == "English" and "Distance: " .. floor(v16.dist) .. " studs | Speed: " .. bulletSpeed or "距离: " .. floor(v16.dist) .. "格 | 速度: " .. bulletSpeed, 1)
						end)
					end

					if not tbl4.silentMode then
						local currentCamera = workspace.CurrentCamera

						if currentCamera then
							currentCamera.CFrame = cframe(currentCamera.CFrame.Position, v16.aimPos)
						end
					end
				else
					tbl4.silentTarget = nil
					tbl4.lastNotifiedPlayer = nil
					tbl4.updateIndicator(nil, false)
				end

				task.wait()
			end
		end
	end

	tbl4.toggle = function(aimEnabled)
		tbl4.aimEnabled = aimEnabled

		if aimEnabled then
			if not tbl4.aimConn then
				tbl4.aimConn = task.spawn(fn9)

				if tbl4.silentMode then
					tbl4.setupSilentHook()
				else
					tbl4.removeSilentHook()
				end
			end
		else
			if tbl4.aimConn then
				task.cancel(tbl4.aimConn)
				tbl4.aimConn = nil
			end

			tbl4.removeSilentHook()
			tbl4.silentTarget = nil
			tbl4.lastNotifiedPlayer = nil
			tbl4.hideIndicator()
		end
	end
end

tbl4.setAimPart = function(arg)
	tbl4.aimPart = arg == "身体" and "HumanoidRootPart" or "Head"
end

tbl4.toggleFOV = function(showFov)
	tbl4.showFov = showFov
end

tbl4.setFOV = function(fov)
	tbl4.fov = fov
end

tbl4.toggleTeamCheck = function(teamCheck)
	tbl4.teamCheck = teamCheck
end

tbl4.togglePrediction = function(prediction)
	tbl4.prediction = prediction
end

tbl4.setBulletSpeed = function(bulletSpeed)
	tbl4.bulletSpeed = bulletSpeed
end

tbl4.toggleWallCheck = function(wallCheck)
	tbl4.wallCheck = wallCheck
end

tbl4.toggleMelee = function(meleeEnabled)
	tbl4.meleeEnabled = meleeEnabled

	if meleeEnabled then
		if not tbl4.meleeConn then
			tbl4.meleeConn = v5.Heartbeat:Connect(function()
				if not tbl4.meleeEnabled then
					return
				end
				local character = localPlayer.Character
				if not character then
					return
				end
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then
					return
				end
				local tool = character:FindFirstChildOfClass("Tool")
				if not tool then
					return
				end
				local remoteEvent = tool:FindFirstChild("RemoteEvent")
				if not remoteEvent then
					return
				end

				for _, v16 in v4:GetPlayers() do
					if v16 ~= localPlayer then
						if not (tbl.isMarked and tbl.isMarked(v16)) then
							if tbl4.teamCheck then
								local v17 = tbl.getPlayerTeam(localPlayer)
								local v18 = tbl.getPlayerTeam(v16)
								if v17 and v18 and v17 == v18 then
									continue
								end
							end

							local character2 = v16.Character

							if character2 then
								local humanoid = character2:FindFirstChildOfClass("Humanoid")

								if not (not humanoid or humanoid.Health <= 0) then
									if not (humanoid.Health > 1000) then
										local humanoidRootPart2 = character2:FindFirstChild("HumanoidRootPart")

										if humanoidRootPart2 then
											if not ((humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude > 45) then
												local head = character2:FindFirstChild("Head")

												if head then
													pcall(function()
														remoteEvent:FireServer("PrepareSwing")
														remoteEvent:FireServer("Swing", "Side")
														remoteEvent:FireServer("HitPlayer", humanoid, head.Position)
													end)
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
		end
	elseif tbl4.meleeConn then
		tbl4.meleeConn:Disconnect()
		tbl4.meleeConn = nil
	end
end

tbl4.toggleTeleport = function(tpEnabled)
	tbl4.tpEnabled = tpEnabled

	if tpEnabled then
		if tbl4.tpThread then
			return
		end
		tbl4.tpTargetHistory = {}
		tbl4.tpExtraLeadTime = 0.18
		tbl4.tpBackDistance = 4
		tbl4.tpUpOffset = 6
		tbl4.tpMaxPredict = 20

		tbl4.tpThread = task.spawn(function()
			while tbl4.tpEnabled do
				local character = v4.LocalPlayer.Character

				if character then
					local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

					if humanoidRootPart then
						if tbl4.tpTarget then
							local character2 = tbl4.tpTarget.Character
							local humanoidRootPart2 = character2 and character2:FindFirstChild("HumanoidRootPart")
							local flag = false

							if humanoidRootPart2 then
								local humanoid = character2:FindFirstChildOfClass("Humanoid")
								humanoid = humanoid and humanoid.Health > 0
								flag = false

								if humanoid then
									local v16 = tbl.getPlayerTeam(v4.LocalPlayer)
									local v17 = tbl.getPlayerTeam(tbl4.tpTarget)
									local flag2 = not v16 or not v17 or v16 ~= v17
									flag = false

									if flag2 then
										flag = true
									end
								end
							end

							if not flag then
								if tbl4.tpHighlight then
									tbl4.tpHighlight:Destroy()
									tbl4.tpHighlight = nil
								end

								tbl4.tpTarget = nil
								tbl4.tpTargetHistory = {}
							end
						end

						if not tbl4.tpTarget then
							local v16 = tbl.getPlayerTeam(v4.LocalPlayer)
							local huge = math.huge
							local v17 = nil

							for _, v18 in v4:GetPlayers() do
								if v18 ~= v4.LocalPlayer then
									local character2 = v18.Character

									if character2 then
										local humanoid = character2:FindFirstChildOfClass("Humanoid")

										if not (not humanoid or humanoid.Health <= 0) then
											local humanoidRootPart2 = character2:FindFirstChild("HumanoidRootPart")

											if humanoidRootPart2 then
												local v19 = tbl.getPlayerTeam(v18)

												if not (v16 and v19 and v16 == v19) then
													local magnitude = (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude

													if magnitude < huge then
														huge = magnitude
														v17 = v18
													end
												end
											end
										end
									end
								end
							end

							if v17 then
								tbl4.tpTarget = v17
								tbl4.tpTargetHistory = {}

								if tbl4.tpHighlight then
									tbl4.tpHighlight:Destroy()
								end

								local highlight = Instance.new("Highlight")
								highlight.FillColor = color(0, 255, 0)
								highlight.OutlineColor = color(0, 255, 0)
								highlight.FillTransparency = 0.3
								highlight.OutlineTransparency = 0.3
								highlight.Adornee = v17.Character
								highlight.Parent = v17.Character
								tbl4.tpHighlight = highlight
							end
						end

						if tbl4.tpTarget and tbl4.tpTarget.Character then
							local humanoidRootPart2 = tbl4.tpTarget.Character:FindFirstChild("HumanoidRootPart")

							if humanoidRootPart2 then
								table.insert(tbl4.tpTargetHistory, { time = clock(), pos = humanoidRootPart2.Position, cframe = humanoidRootPart2.CFrame })

								if #tbl4.tpTargetHistory > 10 then
									table.remove(tbl4.tpTargetHistory, 1)
								end

								local n = tbl4.getPing() / 1000

								if #tbl4.tpTargetHistory < 2 then
									local position = humanoidRootPart2.Position
									humanoidRootPart.CFrame = cframe(humanoidRootPart2.Position - humanoidRootPart2.CFrame.LookVector * tbl4.tpBackDistance + vector(0, tbl4.tpUpOffset, 0), position)
									task.wait(0.2)
								else
									local tpTargetHistory = tbl4.tpTargetHistory
									local vector3 = Vector3.zero
									local n2 = 0
									local n3 = 0
									local n4 = 0

									for i = 2, #tpTargetHistory do
										local v16 = tpTargetHistory[i - 1]
										local v17 = tpTargetHistory[i]
										local n5 = v17.time - v16.time

										if n5 > 0.001 then
											vector3 += (v17.pos - v16.pos) / n5
											local lookVector = v16.cframe.LookVector
											local lookVector2 = v17.cframe.LookVector
											local v18 = lookVector:Cross(lookVector2)
											local v19 = lookVector:Dot(lookVector2)
											local n6 = math.atan2(v18.Magnitude, v19)

											if v19 < 0 then
												n6 = 3.1415926535897931 - n6
											end

											n2 += n6
											n3 += n5
											n4 += 1
										end
									end

									if n4 > 0 then
										vector3 /= n4
									end

									local n5 = 0
									local n6 = 0

									if #tpTargetHistory >= 2 then
										local n7 = 1 - abs((tpTargetHistory[#tpTargetHistory - 1].pos - tpTargetHistory[#tpTargetHistory].pos).Unit:Dot((tpTargetHistory[#tpTargetHistory].pos - tpTargetHistory[#tpTargetHistory - 1].pos).Unit))
										local magnitude = (tpTargetHistory[#tpTargetHistory].pos - tpTargetHistory[#tpTargetHistory - 1].pos).Magnitude
										local magnitude2 = (tpTargetHistory[#tpTargetHistory].pos - tpTargetHistory[#tpTargetHistory - 1].pos).Magnitude
										local n8 = 0

										if magnitude > 0.1 then
											n5 = n7
											n6 = abs(magnitude2 - magnitude) / magnitude
										else
											n5 = n7
											n6 = n8
										end
									end

									local n7 = 1 - min(1, n5 * 0.8 + n6 * 0.4) * 0.6
									local v16 = tpTargetHistory[#tpTargetHistory]
									local n8 = v16.pos + vector3 * n * n7

									if tbl4.tpMaxPredict < (n8 - v16.pos).Magnitude then
										n8 = v16.pos + (n8 - v16.pos).Unit * tbl4.tpMaxPredict
									end

									local lookVector = v16.cframe.LookVector
									local n9 = 0

									if n3 > 0.001 then
										n9 = n2 / n3
									end

									local v17

									if n9 == 0 then
										v17 = lookVector
									else
										local n10 = n9 * n
										local vector4 = lookVector:Cross(Vector3.new(0, 1, 0))

										if vector4.Magnitude < 0.001 then
											vector4 = Vector3.new(1, 0, 0)
										end

										v17 = CFrame.fromAxisAngle(vector4.Unit, n10):VectorToWorldSpace(lookVector)
									end

									local n10 = n8 - v17 * tbl4.tpBackDistance
									local unit = vector3.Magnitude > 0.5 and vector3.Unit or Vector3.zero

									if unit.Magnitude > 0 then
										n10 += unit * vector3.Magnitude * tbl4.tpExtraLeadTime
									end

									humanoidRootPart.CFrame = cframe(n10 + vector(0, tbl4.tpUpOffset, 0), n8)
									task.wait(1e-09)
								end

								continue
							end
						end
					end
				end

				task.wait(1e-09)
			end
		end)
	else
		tbl4.tpEnabled = false

		if tbl4.tpThread then
			task.cancel(tbl4.tpThread)
			tbl4.tpThread = nil
		end

		if tbl4.tpHighlight then
			tbl4.tpHighlight:Destroy()
			tbl4.tpHighlight = nil
		end

		tbl4.tpTarget = nil
		tbl4.tpTargetHistory = {}
	end
end

tbl4.forceEquipEnabled = false
tbl4.forceEquipConn = nil

tbl4.toggleForceEquip = function(forceEquipEnabled)
	tbl4.forceEquipEnabled = forceEquipEnabled

	if forceEquipEnabled then
		if not tbl4.forceEquipConn then
			tbl4.forceEquipConn = v5.Heartbeat:Connect(function()
				if not tbl4.forceEquipEnabled then
					return
				end
				local character = v4.LocalPlayer.Character
				if not character then
					return
				end
				local backpack = v4.LocalPlayer:FindFirstChild("Backpack")
				if not backpack then
					return
				end
				local flag = false

				for _, v16 in character:GetChildren() do
					if v16:IsA("Tool") and v16:GetAttribute("Melee") then
						flag = true
						break
					end
				end

				if not flag then
					for _, v16 in backpack:GetChildren() do
						if v16:IsA("Tool") and v16:GetAttribute("Melee") then
							v16.Parent = character
							break
						end
					end
				end
			end)
		end
	elseif tbl4.forceEquipConn then
		tbl4.forceEquipConn:Disconnect()
		tbl4.forceEquipConn = nil
	end
end

tbl.onCharacterAdded(function()
	if tbl4.tpHighlight then
		tbl4.tpHighlight:Destroy()
		tbl4.tpHighlight = nil
	end

	tbl4.tpTarget = nil
	tbl4.hideIndicator()

	if tbl4.aimEnabled then
		tbl4.toggle(false)
		task.wait(0.5)
		tbl4.toggle(true)
	end

	if tbl4.meleeEnabled then
		tbl4.toggleMelee(false)
		task.wait(0.5)
		tbl4.toggleMelee(true)
	end

	if tbl4.tpEnabled then
		tbl4.toggleTeleport(false)
		task.wait(0.5)
		tbl4.toggleTeleport(true)
	end
end)

tbl.disguise = {}
tbl.disguise.lastVictimName = ""
tbl.disguise.active = false

tbl.disguise.getUserIdByUsername = function(arg)
	local ok, result = pcall(function()
		return game:HttpGet("https://users.roblox.com/v1/users/search?keyword=" .. v2:UrlEncode(arg), true)
	end)

	if not ok then
		return nil, nil, nil
	end
	local data = v2:JSONDecode(result)
	if data and data.data and #data.data > 0 then
		return data.data[1].id, data.data[1].name, data.data[1].displayName
	end
	return nil, nil, nil
end

tbl.disguise.applyCharacterAppearance = function(parent, arg)
	local characterAppearanceAsync = v4:GetCharacterAppearanceAsync(arg)

	for _, v16 in parent:GetChildren() do
		if v16:IsA("Accessory") or v16:IsA("Shirt") or v16:IsA("Pants") or v16:IsA("BodyColors") then
			v16:Destroy()
		end
	end

	for _, v16 in characterAppearanceAsync:GetChildren() do
		if v16:IsA("Shirt") or v16:IsA("Pants") or v16:IsA("BodyColors") then
			v16:Clone().Parent = parent
		elseif v16:IsA("Accessory") then
			parent.Humanoid:AddAccessory(v16:Clone())
		end
	end

	if characterAppearanceAsync:FindFirstChild("face") then
		if parent:WaitForChild("Head"):FindFirstChild("face") then
			parent.Head.face:Destroy()
		end

		local head = parent.Head
		characterAppearanceAsync.face:Clone().Parent = head
	end

	local parent2 = parent.Parent
	parent.Parent = nil
	parent.Parent = parent2
end

tbl.disguise.applyAppearanceOnly = function(arg)
	if arg == "" then
		lib:Notify({ Title = fn3("错误"), Description = fn3("请输入目标玩家名字"), Time = 3 })
		return false
	end

	return (pcall(function()
		local v16 = localPlayer
		local v17, v18, v19 = tbl.disguise.getUserIdByUsername(arg)
		if not v17 then
			lib:Notify({ Title = fn3("错误"), Description = fn3("找不到该玩家"), Time = 3 })
			return
		end

		if not v16.Character then
			v16.CharacterAdded:Wait()
		end

		while true do
			task.wait()
			if not (v16.Character and v16.Character:FindFirstChild("Humanoid")) then
				continue
			end
			break
		end

		local character = v16.Character
		tbl.disguise.applyCharacterAppearance(character, v17)
		task.wait(0.1)

		pcall(function()
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				workspace.CurrentCamera.CameraSubject = humanoid
				workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			end
		end)

		lib:Notify({
			Title = fn3("成功"),
			Description = format(str == "English" and "Replaced with %s's appearance" or "已替换为 %s 外观", v19),
			Time = 3,
		})
	end))
end

tbl.disguise.changeNameOnly = function(arg)
	if arg == "" then
		lib:Notify({ Title = fn3("错误"), Description = fn3("请输入新名字"), Time = 3 })
		return false
	end

	return (pcall(function()
		local v16 = localPlayer
		local v17, v18, v19 = tbl.disguise.getUserIdByUsername(arg)
		if not v17 then
			lib:Notify({ Title = fn3("错误"), Description = fn3("该用户名不存在"), Time = 3 })
			return
		end

		if not v16.Character then
			v16.CharacterAdded:Wait()
		end

		while true do
			task.wait()
			if not (v16.Character and v16.Character:FindFirstChild("Humanoid")) then
				continue
			end
			break
		end

		local character = v16.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		pcall(function()
			v16.Name = v18
			v16.UserId = v17
			v16.CharacterAppearanceId = v17
			v16.DisplayName = v19
			character.Name = v18

			if humanoid then
				humanoid.DisplayName = v19
			end
		end)

		lib:Notify({
			Title = fn3("成功"),
			Description = format(str == "English" and "Name changed to: %s" or "名字已改为: %s", v19),
			Time = 3,
		})
	end))
end

if hookmetamethod then
	local v16 = nil

	local function fn6(arg, ...)
		if getnamecallmethod() == "Destroy" and tbl.disguise.active then
			local character = localPlayer.Character
			if character and arg == character then
				return nil
			end
		end

		local v17 = table.pack(...)
		return v16(arg, table.unpack(v17, 1, v17.n))
	end

	v16 = hookmetamethod
	v16 = v16(game, "__namecall", fn6)
end

tbl.getPurchaseEvent = function()
	if not v7 then
		return nil
	end
	local events = v7:FindFirstChild("Events")
	if not events then
		return nil
	end
	local customize = events:FindFirstChild("Customize")
	if not customize then
		return nil
	end
	return customize:FindFirstChild("PurchaseEvent")
end

local fn6

fn6 = function()
	local character = localPlayer.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return humanoid, animator
end

do
	local function fn7()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			for _, v16 in humanoid:GetPlayingAnimationTracks() do
				pcall(function()
					v16:Stop()
				end)
			end
		end
	end

	local function fn8()
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.WalkSpeed = 16
		end
	end

	tbl.resetAnims = function()
		fn7()
		fn8()
	end
end

do
	local function fn7(arg, animationId)
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		local v16 = arg:LoadAnimation(animation)
		v16.Priority = Enum.AnimationPriority.Action4
		return v16
	end

	tbl.ANIM_KEYS = {
		"horseDance",
		"barry",
		"blyucher",
		"eatBroadcast",
		"playDead",
		"headlessSoldier",
		"crossUse",
		"fracture",
		"napoleon",
		"anim13725477218",
		"animEaten",
		"animBoatPull",
		"animCustomDual1",
		"animCustomDual2",
		"animLoop87443816703028",
		"animLoop15827239870",
		"animCustomDual3",
		"animPlayOnce14860627011",
		"anim107068529359282",
		"anim127516132968916",
		"anim27432686",
		"animCustomDual4",
	}

	tbl.AnimStopOthers = function(arg)
		if tbl._animStopping then
			return
		end
		tbl._animStopping = true

		for _, v16 in tbl.ANIM_KEYS, nil, nil do
			local v17 = tbl[v16]

			if v16 ~= arg and v17 and v17.active then
				local v18 = tbl["stop" .. v16:sub(1, 1):upper() .. v16:sub(2)]

				if v18 then
					pcall(v18)
				end
			end
		end

		tbl._animStopping = false
	end

	v14:AddToggle("DanceHorseToggle", {
		Text = "骑马舞",
		Default = false,
		Tooltip = fn4("播放骑马舞动画"),
		Callback = function(arg)
			if arg then
				tbl.startHorseDance()
			else
				tbl.stopHorseDance()
			end
		end,
	})

	tbl.horseDance = { active = false, track = nil, thread = nil }

	tbl.startHorseDance = function()
		if tbl.horseDance.active then
			return
		end
		tbl.AnimStopOthers("horseDance")
		tbl.horseDance.active = true
		tbl.resetAnims()
		local v16, v17 = fn6()
		if not v17 then
			tbl.horseDance.active = false
			return
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://182435998"
		local v18 = v17:LoadAnimation(animation)
		v18.Priority = Enum.AnimationPriority.Action4
		v18.Looped = true
		v18:Play()
		tbl.horseDance.track = v18
	end

	tbl.stopHorseDance = function()
		if not tbl.horseDance.active then
			return
		end
		tbl.horseDance.active = false

		if tbl.horseDance.track then
			pcall(function()
				tbl.horseDance.track:Stop()
			end)
		end

		tbl.resetAnims()
	end

	tbl.barry = { active = false, trackList = {}, thread = nil }

	local function fn8(arg)
		local trackList = {}
		local v16 = fn7(arg, "rbxassetid://14284371664")
		local v17 = fn7(arg, "rbxassetid://14284387207")
		local v18 = fn7(arg, "rbxassetid://14284382730")
		trackList[1] = v16
		trackList[2] = v17
		trackList[3] = v18

		do
			local values = table.pack(fn7(arg, "rbxassetid://14304936421"))
			table.move(values, 1, values.n, 4, trackList)
		end

		tbl.barry.trackList = trackList

		local function fn9(arg2, arg3)
			local flag = false

			local connection = arg2.Stopped:Once(function()
				flag = true
			end)

			local v19 = clock2()

			while not flag and arg2.IsPlaying and clock2() - v19 < arg3 do
				task.wait(0.05)
			end

			pcall(function()
				connection:Disconnect()
			end)
		end

		while tbl.barry.active do
			trackList[1]:Play()
			fn9(trackList[1], 10)

			if tbl.barry.active then
				trackList[2]:Play()
				task.wait(1)

				if trackList[2].IsPlaying then
					trackList[2]:Stop()
				end

				if tbl.barry.active then
					trackList[3]:Play()
					fn9(trackList[3], 10)

					if tbl.barry.active then
						trackList[2]:Play()
						task.wait(0.3)

						if trackList[2].IsPlaying then
							trackList[2]:Stop()
						end

						if tbl.barry.active then
							trackList[4]:Play()
							fn9(trackList[4], 10)
							continue
						end
					end
				end
			end

			break
		end

		for _, v19 in trackList, nil, nil do
			pcall(function()
				v19:Stop()
			end)
		end

		tbl.barry.trackList = {}
	end

	tbl.startBarry = function()
		if tbl.barry.active then
			return
		end
		tbl.AnimStopOthers("barry")
		tbl.barry.active = true
		tbl.resetAnims()
		local v16, v17 = fn6()
		if not v17 then
			tbl.barry.active = false
			return
		end
		tbl.barry.thread = task.spawn(fn8, v17)
	end
end

tbl.stopBarry = function()
	if not tbl.barry.active then
		return
	end
	tbl.barry.active = false

	if tbl.barry.thread then
		task.cancel(tbl.barry.thread)
	end

	for _, v16 in tbl.barry.trackList, nil, nil do
		pcall(function()
			v16:Stop()
		end)
	end

	tbl.barry.trackList = {}
	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.horseDance and tbl.horseDance.active then
		tbl.stopHorseDance()
	end

	if tbl.blyucher and tbl.blyucher.active then
		tbl.stopBlyucher()
	end

	if tbl.barry and tbl.barry.active then
		tbl.stopBarry()
	end
end)

tbl.blyucher = { active = false, thread = nil, tracks = {} }

tbl.startBlyucher = function()
	if tbl.blyucher.active then
		return
	end
	tbl.AnimStopOthers("blyucher")
	tbl.blyucher.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.blyucher.active = false
		return
	end

	local function fn7(animationId)
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		local v18 = v17:LoadAnimation(animation)
		v18.Priority = Enum.AnimationPriority.Action4
		return v18
	end

	local v18 = fn7("rbxassetid://15603033178")
	local v19 = fn7("rbxassetid://16168689655")
	local v20 = fn7("rbxassetid://15680560478")
	local v21 = fn7("rbxassetid://15688743558")
	local v22 = fn7("rbxassetid://15637342030")
	tbl.blyucher.tracks = { v18, v19, v20, v21, v22 }

	tbl.blyucher.thread = task.spawn(function()
		if not tbl.blyucher.active then
			return
		end
		v18:Play()
		v18.Stopped:Wait()
		if not tbl.blyucher.active then
			return
		end
		v19:Play()
		v19.Stopped:Wait()
		if not tbl.blyucher.active then
			return
		end
		v20:Play()
		task.wait(3)

		if v20.IsPlaying then
			v20:Stop()
		end

		if not tbl.blyucher.active then
			return
		end
		v21:Play()
		v21.Stopped:Wait()
		if not tbl.blyucher.active then
			return
		end
		v20:Play()
		task.wait(3)

		if v20.IsPlaying then
			v20:Stop()
		end

		if not tbl.blyucher.active then
			return
		end
		v22:Play()
		v22.Stopped:Wait()

		if tbl.blyucher.active then
			tbl.blyucher.active = false

			pcall(function()
				if type(tbl.updateBlyucherButton) == "function" then
					tbl.updateBlyucherButton(false)
				end
			end)

			tbl.resetAnims()
		end
	end)
end

tbl.stopBlyucher = function()
	if not tbl.blyucher.active then
		return
	end
	tbl.blyucher.active = false

	if tbl.blyucher.thread then
		task.cancel(tbl.blyucher.thread)
		tbl.blyucher.thread = nil
	end

	for _, v16 in tbl.blyucher.tracks, nil, nil do
		pcall(function()
			v16:Stop()
		end)
	end

	tbl.blyucher.tracks = {}
	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.blyucher and tbl.blyucher.active then
		tbl.stopBlyucher()
	end
end)

v14:AddToggle("DanceBlyucherToggle", {
	Text = "布吕歇尔",
	Default = false,
	Tooltip = fn4("老不死的布吕歇尔动作（播放完整序列后自动停止）"),
	Callback = function(arg)
		if arg then
			tbl.startBlyucher()

			tbl.updateBlyucherButton = function(arg2)
				local danceBlyucherToggle = toggles.DanceBlyucherToggle

				if danceBlyucherToggle and danceBlyucherToggle.SetValue then
					danceBlyucherToggle:SetValue(arg2)
				end
			end
		else
			tbl.stopBlyucher()
			tbl.updateBlyucherButton = nil
		end
	end,
})

v14:AddToggle("DanceBarryToggle", {
	Text = "Barry",
	Default = false,
	Tooltip = fn4("耐咬王 Barry 动作"),
	Callback = function(arg)
		if arg then
			tbl.startBarry()
		else
			tbl.stopBarry()
		end
	end,
})

tbl.eatBroadcast = { active = false, track = nil }

tbl.startEatBroadcast = function()
	if tbl.eatBroadcast.active then
		return
	end
	tbl.AnimStopOthers("eatBroadcast")
	tbl.eatBroadcast.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.eatBroadcast.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://18339432914"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18:Play()
	tbl.eatBroadcast.track = v18
end

tbl.stopEatBroadcast = function()
	if not tbl.eatBroadcast.active then
		return
	end
	tbl.eatBroadcast.active = false

	if tbl.eatBroadcast.track then
		pcall(function()
			tbl.eatBroadcast.track:Stop()
		end)

		tbl.eatBroadcast.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.eatBroadcast and tbl.eatBroadcast.active then
		tbl.stopEatBroadcast()
	end
end)

v14:AddToggle("DanceEatToggle", {
	Text = "吃东西",
	Default = false,
	Tooltip = fn4("山伯乐吃东西动画"),
	Callback = function(arg)
		if arg then
			tbl.startEatBroadcast()
		else
			tbl.stopEatBroadcast()
		end
	end,
})

tbl.playDead = { active = false, track = nil, thread = nil }

tbl.startPlayDead = function()
	if tbl.playDead.active then
		return
	end
	tbl.AnimStopOthers("playDead")
	tbl.playDead.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.playDead.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://89945348540089"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	tbl.playDead.track = v18

	tbl.playDead.thread = task.spawn(function()
		while tbl.playDead.active do
			v18:Play()
			task.wait(1)

			if v18.IsPlaying then
				v18:Stop()
			end
		end
	end)
end

tbl.stopPlayDead = function()
	if not tbl.playDead.active then
		return
	end
	tbl.playDead.active = false

	if tbl.playDead.thread then
		task.cancel(tbl.playDead.thread)
		tbl.playDead.thread = nil
	end

	if tbl.playDead.track then
		pcall(function()
			tbl.playDead.track:Stop()
		end)

		tbl.playDead.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.playDead and tbl.playDead.active then
		tbl.stopPlayDead()
	end
end)

v14:AddToggle("DancePlayDeadToggle", {
	Text = "睡着了",
	Default = false,
	Tooltip = fn4("装死动画"),
	Callback = function(arg)
		if arg then
			tbl.startPlayDead()
		else
			tbl.stopPlayDead()
		end
	end,
})

tbl.headlessSoldier = { active = false, idleTrack = nil, walkTrack = nil, conn = nil }

tbl.startHeadlessSoldier = function()
	if tbl.headlessSoldier.active then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	for _, v16 in humanoid:GetPlayingAnimationTracks() do
		pcall(function()
			v16:Stop()
		end)
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://107080941320600"
	local animation2 = Instance.new("Animation")
	animation2.AnimationId = "rbxassetid://74764025513892"
	local v16 = animator:LoadAnimation(animation)
	local v17 = animator:LoadAnimation(animation2)
	v16.Priority = Enum.AnimationPriority.Action3
	v17.Priority = Enum.AnimationPriority.Action3
	tbl.headlessSoldier.idleTrack = v16
	tbl.headlessSoldier.walkTrack = v17
	tbl.headlessSoldier.active = true

	local function fn7()
		if not tbl.headlessSoldier.active then
			return
		end

		if humanoid.MoveDirection.Magnitude > 0 then
			if v17 and not v17.IsPlaying then
				if v16 and v16.IsPlaying then
					v16:Stop()
				end

				v17:Play()
			end
		elseif v16 and not v16.IsPlaying then
			if v17 and v17.IsPlaying then
				v17:Stop()
			end

			v16:Play()
		end
	end

	fn7()
	tbl.headlessSoldier.conn = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(fn7)
end

tbl.stopHeadlessSoldier = function()
	if not tbl.headlessSoldier.active then
		return
	end
	tbl.headlessSoldier.active = false

	if tbl.headlessSoldier.conn then
		tbl.headlessSoldier.conn:Disconnect()
		tbl.headlessSoldier.conn = nil
	end

	if tbl.headlessSoldier.idleTrack then
		pcall(function()
			tbl.headlessSoldier.idleTrack:Stop()
		end)

		tbl.headlessSoldier.idleTrack = nil
	end

	if tbl.headlessSoldier.walkTrack then
		pcall(function()
			tbl.headlessSoldier.walkTrack:Stop()
		end)

		tbl.headlessSoldier.walkTrack = nil
	end

	local character = localPlayer.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			for _, v16 in humanoid:GetPlayingAnimationTracks() do
				pcall(function()
					v16:Stop()
				end)
			end
		end
	end
end

tbl.onCharacterAdded(function()
	if tbl.headlessSoldier and tbl.headlessSoldier.active then
		tbl.stopHeadlessSoldier()
		local headlessSoldierToggle = toggles.HeadlessSoldierToggle

		if headlessSoldierToggle and headlessSoldierToggle.SetValue then
			headlessSoldierToggle:SetValue(false)
		end
	end
end)

v14:AddToggle("HeadlessSoldierToggle", {
	Text = "无头士兵",
	Default = false,
	Tooltip = fn4("播放无头士兵待机/行走动画（自动切换）"),
	Callback = function(arg)
		if arg then
			tbl.startHeadlessSoldier()
		else
			tbl.stopHeadlessSoldier()
		end
	end,
})

tbl.crossUse = { active = false, track = nil }

tbl.startCrossUse = function()
	if tbl.crossUse.active then
		return
	end
	tbl.AnimStopOthers("crossUse")
	tbl.crossUse.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.crossUse.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://15210536563"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	tbl.crossUse.track = v18
	v18:Play()
end

tbl.stopCrossUse = function()
	if not tbl.crossUse.active then
		return
	end
	tbl.crossUse.active = false

	if tbl.crossUse.track then
		pcall(function()
			tbl.crossUse.track:Stop()
		end)

		tbl.crossUse.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.crossUse and tbl.crossUse.active then
		tbl.stopCrossUse()
		local crossUseToggle = toggles.CrossUseToggle

		if crossUseToggle and crossUseToggle.SetValue then
			crossUseToggle:SetValue(false)
		end
	end
end)

v14:AddToggle("CrossUseToggle", {
	Text = "十字架",
	Default = false,
	Tooltip = fn4("播放十字架使用动画（循环）"),
	Callback = function(arg)
		if arg then
			tbl.startCrossUse()
		else
			tbl.stopCrossUse()
		end
	end,
})

tbl.fracture = { active = false, track1 = nil, track2 = nil }

tbl.startFracture = function()
	if tbl.fracture.active then
		return
	end
	tbl.AnimStopOthers("fracture")
	tbl.fracture.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.fracture.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://12333490324"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	local animation2 = Instance.new("Animation")
	animation2.AnimationId = "rbxassetid://12333489072"
	local v19 = v17:LoadAnimation(animation2)
	v19.Priority = Enum.AnimationPriority.Action4
	v19.Looped = true
	tbl.fracture.track1 = v18
	tbl.fracture.track2 = v19
	v18:Play()

	v18.Stopped:Connect(function()
		if tbl.fracture.active then
			v19:Play()
		end
	end)
end

tbl.stopFracture = function()
	if not tbl.fracture.active then
		return
	end
	tbl.fracture.active = false

	if tbl.fracture.track1 then
		pcall(function()
			tbl.fracture.track1:Stop()
		end)

		tbl.fracture.track1 = nil
	end

	if tbl.fracture.track2 then
		pcall(function()
			tbl.fracture.track2:Stop()
		end)

		tbl.fracture.track2 = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.fracture and tbl.fracture.active then
		tbl.stopFracture()
		local fractureToggle = toggles.FractureToggle

		if fractureToggle and fractureToggle.SetValue then
			fractureToggle:SetValue(false)
		end
	end
end)

v14:AddToggle("FractureToggle", {
	Text = "骨折",
	Default = false,
	Tooltip = fn4("播放骨折动画（第一段播完第二段循环）"),
	Callback = function(arg)
		if arg then
			tbl.startFracture()
		else
			tbl.stopFracture()
		end
	end,
})

tbl.napoleon = { active = false, idleTrack = nil, walkTrack = nil, conn = nil }

tbl.startNapoleon = function()
	if tbl.napoleon.active then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	for _, v16 in humanoid:GetPlayingAnimationTracks() do
		pcall(function()
			v16:Stop()
		end)
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://103557875332543"
	local v16 = animator:LoadAnimation(animation)
	v16.Priority = Enum.AnimationPriority.Action4
	tbl.napoleon.idleTrack = v16
	tbl.napoleon.walkTrack = nil
	tbl.napoleon.active = true

	local function fn7()
		if not tbl.napoleon.active then
			return
		end

		if not v16.IsPlaying then
			v16:Play()
		end
	end

	fn7()
	tbl.napoleon.conn = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(fn7)
end

tbl.stopNapoleon = function()
	if not tbl.napoleon.active then
		return
	end
	tbl.napoleon.active = false

	if tbl.napoleon.conn then
		tbl.napoleon.conn:Disconnect()
		tbl.napoleon.conn = nil
	end

	if tbl.napoleon.idleTrack then
		pcall(function()
			tbl.napoleon.idleTrack:Stop()
		end)

		tbl.napoleon.idleTrack = nil
	end

	if tbl.napoleon.walkTrack then
		pcall(function()
			tbl.napoleon.walkTrack:Stop()
		end)

		tbl.napoleon.walkTrack = nil
	end

	local character = localPlayer.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			for _, v16 in humanoid:GetPlayingAnimationTracks() do
				pcall(function()
					v16:Stop()
				end)
			end
		end
	end
end

tbl.onCharacterAdded(function()
	if tbl.napoleon and tbl.napoleon.active then
		tbl.stopNapoleon()
		local napoleonToggle = toggles.NapoleonToggle

		if napoleonToggle and napoleonToggle.SetValue then
			napoleonToggle:SetValue(false)
		end
	end
end)

v14:AddToggle("NapoleonToggle", {
	Text = "仙人背手",
	Default = false,
	Tooltip = fn4("播放拿破仑背手动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			tbl.startNapoleon()
		else
			tbl.stopNapoleon()
		end
	end,
})

tbl.anim13725477218 = { active = false, track = nil }

tbl.startAnim13725477218 = function()
	if tbl.anim13725477218.active then
		return
	end
	tbl.AnimStopOthers("anim13725477218")
	tbl.anim13725477218.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.anim13725477218.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://13725477218"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	v18:Play()
	tbl.anim13725477218.track = v18
end

tbl.stopAnim13725477218 = function()
	if not tbl.anim13725477218.active then
		return
	end
	tbl.anim13725477218.active = false

	if tbl.anim13725477218.track then
		pcall(function()
			tbl.anim13725477218.track:Stop()
		end)

		tbl.anim13725477218.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.anim13725477218 and tbl.anim13725477218.active then
		tbl.stopAnim13725477218()
		local anim13725477218Toggle = toggles.Anim13725477218Toggle

		if anim13725477218Toggle and anim13725477218Toggle.SetValue then
			anim13725477218Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("Anim13725477218Toggle", {
	Text = "突进肘击",
	Default = false,
	Tooltip = fn4("循环播放指定动画（优先级 Action4）"),
	Callback = function(arg)
		if arg then
			tbl.startAnim13725477218()
		else
			tbl.stopAnim13725477218()
		end
	end,
})

tbl.animEaten = { active = false, track = nil }

tbl.startAnimEaten = function()
	if tbl.animEaten.active then
		return
	end
	tbl.AnimStopOthers("animEaten")
	tbl.animEaten.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.animEaten.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://12333488486"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	v18:Play()
	tbl.animEaten.track = v18
end

tbl.stopAnimEaten = function()
	if not tbl.animEaten.active then
		return
	end
	tbl.animEaten.active = false

	if tbl.animEaten.track then
		pcall(function()
			tbl.animEaten.track:Stop()
		end)

		tbl.animEaten.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.animEaten and tbl.animEaten.active then
		tbl.stopAnimEaten()
		local animEatenToggle = toggles.AnimEatenToggle

		if animEatenToggle and animEatenToggle.SetValue then
			animEatenToggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimEatenToggle", {
	Text = "被山伯乐啃",
	Default = false,
	Tooltip = fn4("循环播放被啃动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnimEaten()
		else
			tbl.stopAnimEaten()
		end
	end,
})

tbl.animBoatPull = { active = false, track = nil }

tbl.startAnimBoatPull = function()
	if tbl.animBoatPull.active then
		return
	end
	tbl.AnimStopOthers("animBoatPull")
	tbl.animBoatPull.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.animBoatPull.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://122021683613392"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	v18:Play()
	tbl.animBoatPull.track = v18
end

tbl.stopAnimBoatPull = function()
	if not tbl.animBoatPull.active then
		return
	end
	tbl.animBoatPull.active = false

	if tbl.animBoatPull.track then
		pcall(function()
			tbl.animBoatPull.track:Stop()
		end)

		tbl.animBoatPull.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.animBoatPull and tbl.animBoatPull.active then
		tbl.stopAnimBoatPull()
		local animBoatPullToggle = toggles.AnimBoatPullToggle

		if animBoatPullToggle and animBoatPullToggle.SetValue then
			animBoatPullToggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimBoatPullToggle", {
	Text = "扒船",
	Default = false,
	Tooltip = fn4("循环播放扒船动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnimBoatPull()
		else
			tbl.stopAnimBoatPull()
		end
	end,
})

tbl.startDual = function(arg, animationId, animationId2)
	if arg.active then
		return
	end
	tbl.AnimStopOthers(arg.key)
	local character = localPlayer.Character
	if not character then
		arg.active = false
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		arg.active = false
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	tbl.resetAnims()
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local animation2 = Instance.new("Animation")
	animation2.AnimationId = animationId2
	local v16 = animator:LoadAnimation(animation)
	local v17 = animator:LoadAnimation(animation2)
	v16.Priority = Enum.AnimationPriority.Action3
	v17.Priority = Enum.AnimationPriority.Action3
	arg.idleTrack = v16
	arg.walkTrack = v17
	arg.active = true

	local function fn7()
		if not arg.active then
			return
		end

		if humanoid.MoveDirection.Magnitude > 0 then
			if not v17.IsPlaying then
				if v16.IsPlaying then
					v16:Stop()
				end

				v17:Play()
			end
		elseif not v16.IsPlaying then
			if v17.IsPlaying then
				v17:Stop()
			end

			v16:Play()
		end
	end

	fn7()
	arg.conn = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(fn7)
end

tbl.stopDual = function(arg)
	if not arg.active then
		return
	end
	arg.active = false

	if arg.conn then
		arg.conn:Disconnect()
		arg.conn = nil
	end

	if arg.idleTrack then
		pcall(function()
			arg.idleTrack:Stop()
		end)

		arg.idleTrack = nil
	end

	if arg.walkTrack then
		pcall(function()
			arg.walkTrack:Stop()
		end)

		arg.walkTrack = nil
	end

	tbl.resetAnims()
	local character = localPlayer.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			for _, v16 in humanoid:GetPlayingAnimationTracks() do
				pcall(function()
					v16:Stop()
				end)
			end

			local animate = character:FindFirstChild("Animate")

			if animate then
				pcall(function()
					animate.Disabled = false
				end)
			end
		end
	end
end

tbl.startIdleWalk = function(arg, animationId, animationId2, priority, walkSpeed, animationId3)
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	for _, v16 in humanoid:GetPlayingAnimationTracks() do
		pcall(function()
			v16:Stop()
		end)
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local animation2 = Instance.new("Animation")
	animation2.AnimationId = animationId2
	local v16 = animator:LoadAnimation(animation)
	local v17 = animator:LoadAnimation(animation2)
	v16.Priority = priority
	v17.Priority = priority

	if walkSpeed then
		humanoid.WalkSpeed = walkSpeed
	end

	local v18 = nil

	if animationId3 then
		local animation3 = Instance.new("Animation")
		animation3.AnimationId = animationId3
		v18 = animator:LoadAnimation(animation3)
		v18.Priority = Enum.AnimationPriority.Action2
		v18.Looped = true
		v18:Play()
	end

	local function fn7()
		if humanoid.MoveDirection.Magnitude > 0 then
			if not v17.IsPlaying then
				if v16.IsPlaying then
					v16:Stop()
				end

				v17:Play()
			end
		elseif not v16.IsPlaying then
			if v17.IsPlaying then
				v17:Stop()
			end

			v16:Play()
		end
	end

	local connection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(fn7)
	fn7()
	arg = arg or {}
	arg.idle = v16
	arg.walk = v17
	arg.conn = connection

	if v18 then
		arg.sit = v18
	end

	return arg
end

tbl.stopIdleWalk = function(arg, walkSpeed)
	if arg then
		if arg.idle then
			pcall(function()
				arg.idle:Stop()
			end)

			arg.idle = nil
		end

		if arg.walk then
			pcall(function()
				arg.walk:Stop()
			end)

			arg.walk = nil
		end

		if arg.sit then
			pcall(function()
				arg.sit:Stop()
			end)

			arg.sit = nil
		end

		if arg.conn then
			pcall(function()
				arg.conn:Disconnect()
			end)

			arg.conn = nil
		end
	end

	local character = localPlayer.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			if walkSpeed then
				humanoid.WalkSpeed = walkSpeed
			end

			for _, v16 in humanoid:GetPlayingAnimationTracks() do
				pcall(function()
					v16:Stop()
				end)
			end

			local animate = character:FindFirstChild("Animate")

			if animate then
				pcall(function()
					animate.Disabled = false
				end)
			end
		end
	end
end

tbl.animCustomDual1 = { active = false, idleTrack = nil, walkTrack = nil, conn = nil, key = "animCustomDual1" }

tbl.startAnimCustomDual1 = function()
	tbl.startDual(tbl.animCustomDual1, "rbxassetid://86354512475506", "rbxassetid://78012833820631")
end

tbl.stopAnimCustomDual1 = function()
	tbl.stopDual(tbl.animCustomDual1)
end

tbl.onCharacterAdded(function()
	if tbl.animCustomDual1 and tbl.animCustomDual1.active then
		tbl.stopAnimCustomDual1()
		local animCustomDual1Toggle = toggles.AnimCustomDual1Toggle

		if animCustomDual1Toggle and animCustomDual1Toggle.SetValue then
			animCustomDual1Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimCustomDual1Toggle", {
	Text = "推炮车1",
	Default = false,
	Tooltip = fn4("静止播放动画1，移动播放动画2"),
	Callback = function(arg)
		if arg then
			tbl.startAnimCustomDual1()
		else
			tbl.stopAnimCustomDual1()
		end
	end,
})

tbl.animCustomDual2 = { active = false, idleTrack = nil, walkTrack = nil, conn = nil, key = "animCustomDual2" }

tbl.startAnimCustomDual2 = function()
	tbl.startDual(tbl.animCustomDual2, "rbxassetid://110409103422089", "rbxassetid://105941369341054")
end

tbl.stopAnimCustomDual2 = function()
	tbl.stopDual(tbl.animCustomDual2)
end

tbl.onCharacterAdded(function()
	if tbl.animCustomDual2 and tbl.animCustomDual2.active then
		tbl.stopAnimCustomDual2()
		local animCustomDual2Toggle = toggles.AnimCustomDual2Toggle

		if animCustomDual2Toggle and animCustomDual2Toggle.SetValue then
			animCustomDual2Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimCustomDual2Toggle", {
	Text = "推炮车2",
	Default = false,
	Tooltip = fn4("静止播放动画5，移动播放动画6"),
	Callback = function(arg)
		if arg then
			tbl.startAnimCustomDual2()
		else
			tbl.stopAnimCustomDual2()
		end
	end,
})

tbl.animLoop87443816703028 = { active = false, track = nil, thread = nil }

tbl.startAnimLoop87443816703028 = function()
	if tbl.animLoop87443816703028.active then
		return
	end
	tbl.AnimStopOthers("animLoop87443816703028")
	tbl.animLoop87443816703028.active = true
	tbl.resetAnims()
	local v16
	v16, v16 = fn6()
	if not v16 then
		tbl.animLoop87443816703028.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://87443816703028"

	tbl.animLoop87443816703028.thread = task.spawn(function()
		while tbl.animLoop87443816703028.active do
			if tbl.animLoop87443816703028.track then
				pcall(function()
					tbl.animLoop87443816703028.track:Stop()
				end)

				tbl.animLoop87443816703028.track = nil
			end

			local v17 = v16:LoadAnimation(animation)
			v17.Priority = Enum.AnimationPriority.Action4
			v17.Looped = true
			v17:Play()
			tbl.animLoop87443816703028.track = v17
			local v18 = clock()

			while tbl.animLoop87443816703028.active and clock() - v18 < 0.5 do
				task.wait()
			end
		end
	end)
end

tbl.stopAnimLoop87443816703028 = function()
	if not tbl.animLoop87443816703028.active then
		return
	end
	tbl.animLoop87443816703028.active = false

	if tbl.animLoop87443816703028.thread then
		task.cancel(tbl.animLoop87443816703028.thread)
		tbl.animLoop87443816703028.thread = nil
	end

	if tbl.animLoop87443816703028.track then
		pcall(function()
			tbl.animLoop87443816703028.track:Stop()
		end)

		tbl.animLoop87443816703028.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.animLoop87443816703028 and tbl.animLoop87443816703028.active then
		tbl.stopAnimLoop87443816703028()
		local animLoop87443816703028Toggle = toggles.AnimLoop87443816703028Toggle

		if animLoop87443816703028Toggle and animLoop87443816703028Toggle.SetValue then
			animLoop87443816703028Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimLoop87443816703028Toggle", {
	Text = "神秘举东西",
	Default = false,
	Tooltip = fn4("每0.5秒重新触发一次循环动画 ID: 87443816703028"),
	Callback = function(arg)
		if arg then
			tbl.startAnimLoop87443816703028()
		else
			tbl.stopAnimLoop87443816703028()
		end
	end,
})

tbl.animLoop15827239870 = { active = false, track = nil, thread = nil }

tbl.startAnimLoop15827239870 = function()
	if tbl.animLoop15827239870.active then
		return
	end
	tbl.AnimStopOthers("animLoop15827239870")
	tbl.animLoop15827239870.active = true
	tbl.resetAnims()
	local v16
	v16, v16 = fn6()
	if not v16 then
		tbl.animLoop15827239870.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://15827239870"

	tbl.animLoop15827239870.thread = task.spawn(function()
		while tbl.animLoop15827239870.active do
			if tbl.animLoop15827239870.track then
				pcall(function()
					tbl.animLoop15827239870.track:Stop()
				end)

				tbl.animLoop15827239870.track = nil
			end

			local v17 = v16:LoadAnimation(animation)
			v17.Priority = Enum.AnimationPriority.Action3
			v17.Looped = false
			v17:Play()
			tbl.animLoop15827239870.track = v17
			local v18 = clock()

			while tbl.animLoop15827239870.active and clock() - v18 < 0.73 do
				task.wait()
			end
		end
	end)
end

tbl.stopAnimLoop15827239870 = function()
	if not tbl.animLoop15827239870.active then
		return
	end
	tbl.animLoop15827239870.active = false

	if tbl.animLoop15827239870.thread then
		task.cancel(tbl.animLoop15827239870.thread)
		tbl.animLoop15827239870.thread = nil
	end

	if tbl.animLoop15827239870.track then
		pcall(function()
			tbl.animLoop15827239870.track:Stop()
		end)

		tbl.animLoop15827239870.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.animLoop15827239870 and tbl.animLoop15827239870.active then
		tbl.stopAnimLoop15827239870()
		local animLoop15827239870Toggle = toggles.AnimLoop15827239870Toggle

		if animLoop15827239870Toggle and animLoop15827239870Toggle.SetValue then
			animLoop15827239870Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimLoop15827239870Toggle", {
	Text = "转枪",
	Default = false,
	Tooltip = fn4("每0.73秒播放一次转枪动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnimLoop15827239870()
		else
			tbl.stopAnimLoop15827239870()
		end
	end,
})

tbl.animCustomDual3 = { active = false, idleTrack = nil, walkTrack = nil, conn = nil, key = "animCustomDual3" }

tbl.startAnimCustomDual3 = function()
	tbl.startDual(tbl.animCustomDual3, "rbxassetid://99319014110614", "rbxassetid://115122618346402")
end

tbl.stopAnimCustomDual3 = function()
	tbl.stopDual(tbl.animCustomDual3)
end

tbl.onCharacterAdded(function()
	if tbl.animCustomDual3 and tbl.animCustomDual3.active then
		tbl.stopAnimCustomDual3()
		local animCustomDual3Toggle = toggles.AnimCustomDual3Toggle

		if animCustomDual3Toggle and animCustomDual3Toggle.SetValue then
			animCustomDual3Toggle:SetValue(false)
		end
	end
end)

v13:AddToggle("AnimCustomDual3Toggle", {
	Text = "推大炮1",
	Default = false,
	Tooltip = fn4("静止播放动画1，移动播放动画2"),
	Callback = function(arg)
		if arg then
			tbl.startAnimCustomDual3()
		else
			tbl.stopAnimCustomDual3()
		end
	end,
})

tbl.animPlayOnce14860627011 = { active = false, track = nil, session = 0 }

tbl.startAnimPlayOnce14860627011 = function()
	if tbl.animPlayOnce14860627011.active then
		return
	end
	tbl.AnimStopOthers("animPlayOnce14860627011")
	tbl.animPlayOnce14860627011.active = true
	tbl.animPlayOnce14860627011.session = tbl.animPlayOnce14860627011.session + 1
	local session = tbl.animPlayOnce14860627011.session
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.animPlayOnce14860627011.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://14860627011"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18:Play()
	tbl.animPlayOnce14860627011.track = v18

	task.delay(20, function()
		if tbl.animPlayOnce14860627011 and tbl.animPlayOnce14860627011.active and tbl.animPlayOnce14860627011.session == session then
			tbl.stopAnimPlayOnce14860627011()
			local animPlayOnce14860627011Toggle = toggles.AnimPlayOnce14860627011Toggle

			if animPlayOnce14860627011Toggle and animPlayOnce14860627011Toggle.SetValue then
				animPlayOnce14860627011Toggle:SetValue(false)
			end
		end
	end)
end

tbl.stopAnimPlayOnce14860627011 = function()
	if not tbl.animPlayOnce14860627011.active then
		return
	end
	tbl.animPlayOnce14860627011.active = false
	tbl.animPlayOnce14860627011.session = tbl.animPlayOnce14860627011.session + 1

	if tbl.animPlayOnce14860627011.track then
		pcall(function()
			tbl.animPlayOnce14860627011.track:Stop()
		end)

		tbl.animPlayOnce14860627011.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.animPlayOnce14860627011 and tbl.animPlayOnce14860627011.active then
		tbl.stopAnimPlayOnce14860627011()
		local animPlayOnce14860627011Toggle = toggles.AnimPlayOnce14860627011Toggle

		if animPlayOnce14860627011Toggle and animPlayOnce14860627011Toggle.SetValue then
			animPlayOnce14860627011Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("AnimPlayOnce14860627011Toggle", {
	Text = "开心舞蹈",
	Default = false,
	Tooltip = fn4("播放动画（20秒后自动停止）"),
	Callback = function(arg)
		if arg then
			tbl.startAnimPlayOnce14860627011()
		else
			tbl.stopAnimPlayOnce14860627011()
		end
	end,
})

tbl.anim107068529359282 = { active = false, track = nil }

tbl.startAnim107068529359282 = function()
	if tbl.anim107068529359282.active then
		return
	end
	tbl.anim107068529359282.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.anim107068529359282.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://107068529359282"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	v18:Play()
	tbl.anim107068529359282.track = v18
end

tbl.stopAnim107068529359282 = function()
	if not tbl.anim107068529359282.active then
		return
	end
	tbl.anim107068529359282.active = false

	if tbl.anim107068529359282.track then
		pcall(function()
			tbl.anim107068529359282.track:Stop()
		end)

		tbl.anim107068529359282.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.anim107068529359282 and tbl.anim107068529359282.active then
		tbl.stopAnim107068529359282()
		local anim107068529359282Toggle = toggles.Anim107068529359282Toggle

		if anim107068529359282Toggle and anim107068529359282Toggle.SetValue then
			anim107068529359282Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("Anim107068529359282Toggle", {
	Text = "疯子",
	Default = false,
	Tooltip = fn4("循环播放指定动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnim107068529359282()
		else
			tbl.stopAnim107068529359282()
		end
	end,
})

tbl.anim127516132968916 = { active = false, track = nil }

tbl.startAnim127516132968916 = function()
	if tbl.anim127516132968916.active then
		return
	end
	tbl.anim127516132968916.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.anim127516132968916.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://127516132968916"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	v18:Play()
	tbl.anim127516132968916.track = v18
end

tbl.stopAnim127516132968916 = function()
	if not tbl.anim127516132968916.active then
		return
	end
	tbl.anim127516132968916.active = false

	if tbl.anim127516132968916.track then
		pcall(function()
			tbl.anim127516132968916.track:Stop()
		end)

		tbl.anim127516132968916.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.anim127516132968916 and tbl.anim127516132968916.active then
		tbl.stopAnim127516132968916()
		local anim127516132968916Toggle = toggles.Anim127516132968916Toggle

		if anim127516132968916Toggle and anim127516132968916Toggle.SetValue then
			anim127516132968916Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("Anim127516132968916Toggle", {
	Text = "趴下",
	Default = false,
	Tooltip = fn4("循环播放指定动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnim127516132968916()
		else
			tbl.stopAnim127516132968916()
		end
	end,
})

tbl.anim27432686 = { active = false, track = nil, pauseThread = nil }

tbl.startAnim27432686 = function()
	if tbl.anim27432686.active then
		return
	end
	tbl.AnimStopOthers("anim27432686")
	tbl.anim27432686.active = true
	tbl.resetAnims()
	local v16, v17 = fn6()
	if not v17 then
		tbl.anim27432686.active = false
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://27432686"
	local v18 = v17:LoadAnimation(animation)
	v18.Priority = Enum.AnimationPriority.Action4
	v18.Looped = true
	v18:Play()
	tbl.anim27432686.track = v18

	if tbl.anim27432686.pauseThread then
		task.cancel(tbl.anim27432686.pauseThread)
		tbl.anim27432686.pauseThread = nil
	end

	tbl.anim27432686.pauseThread = task.spawn(function()
		task.wait(0.3)

		if tbl.anim27432686.active and tbl.anim27432686.track then
			pcall(function()
				tbl.anim27432686.track:AdjustSpeed(0)
			end)
		end

		tbl.anim27432686.pauseThread = nil
	end)
end

tbl.stopAnim27432686 = function()
	if not tbl.anim27432686.active then
		return
	end
	tbl.anim27432686.active = false

	if tbl.anim27432686.pauseThread then
		task.cancel(tbl.anim27432686.pauseThread)
		tbl.anim27432686.pauseThread = nil
	end

	if tbl.anim27432686.track then
		pcall(function()
			tbl.anim27432686.track:Stop()
		end)

		tbl.anim27432686.track = nil
	end

	tbl.resetAnims()
end

tbl.onCharacterAdded(function()
	if tbl.anim27432686 and tbl.anim27432686.active then
		tbl.stopAnim27432686()
		local anim27432686Toggle = toggles.Anim27432686Toggle

		if anim27432686Toggle and anim27432686Toggle.SetValue then
			anim27432686Toggle:SetValue(false)
		end
	end
end)

v14:AddToggle("Anim27432686Toggle", {
	Text = "僵尸",
	Default = false,
	Tooltip = fn4("播放0.3秒后暂停定格"),
	Callback = function(arg)
		if arg then
			tbl.startAnim27432686()
		else
			tbl.stopAnim27432686()
		end
	end,
})

do
	local flag = false
	local v16 = nil
	local v17 = nil

	tbl.startAnim92032645117961 = function()
		if flag then
			return
		end
		flag = true
		tbl.resetAnims()
		local v18, v19 = fn6()
		if not v19 then
			flag = false
			return
		end
		v17 = v19
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://92032645117961"
		local v20 = v19:LoadAnimation(animation)
		v20.Priority = Enum.AnimationPriority.Action4
		v20:Play()
		v16 = v20

		v20.Stopped:Connect(function()
			if flag then
				tbl.stopAnim92032645117961()
				local anim92032645117961Toggle = toggles.Anim92032645117961Toggle

				if anim92032645117961Toggle and anim92032645117961Toggle.SetValue then
					anim92032645117961Toggle:SetValue(false)
				end
			end
		end)
	end

	tbl.stopAnim92032645117961 = function()
		flag = false

		if v16 then
			pcall(function()
				v16:Stop()
			end)

			v16 = nil
		end

		v17 = nil
		tbl.resetAnims()
	end

	tbl.onCharacterAdded(function()
		if flag then
			tbl.stopAnim92032645117961()
			local anim92032645117961Toggle = toggles.Anim92032645117961Toggle

			if anim92032645117961Toggle and anim92032645117961Toggle.SetValue then
				anim92032645117961Toggle:SetValue(false)
			end
		end
	end)
end

v14:AddToggle("Anim92032645117961Toggle", {
	Text = "被抓走",
	Default = false,
	Tooltip = fn4("播放动画（播放一次后自动关闭）"),
	Callback = function(arg)
		if arg then
			tbl.startAnim92032645117961()
		else
			tbl.stopAnim92032645117961()
		end
	end,
})

local v16 = nil

tbl.startAnim17593577988 = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		local animator2 = Instance.new("Animator")
		animator2.Parent = humanoid
		animator = animator2
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://17593577988"
	v16 = animator:LoadAnimation(animation)
	v16.Priority = Enum.AnimationPriority.Action4
	v16:Play()
end

tbl.stopAnim17593577988 = function()
	if v16 then
		pcall(function()
			v16:Stop()
		end)

		v16 = nil
	end
end

v14:AddToggle("Anim17593577988Toggle", {
	Text = "爬绳子",
	Default = false,
	Tooltip = fn4("播放动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnim17593577988()
		else
			tbl.stopAnim17593577988()
		end
	end,
})

local v17 = nil

tbl.startAnim17871770160 = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://17871770160"
	v17 = animator:LoadAnimation(animation)
	v17.Priority = Enum.AnimationPriority.Action4
	v17.Looped = true
	v17:Play()
end

tbl.stopAnim17871770160 = function()
	if v17 then
		pcall(function()
			v17:Stop()
		end)

		v17 = nil
	end
end

v14:AddToggle("Anim17871770160Toggle", {
	Text = "翻滚",
	Default = false,
	Tooltip = fn4("循环播放动画"),
	Callback = function(arg)
		if arg then
			tbl.startAnim17871770160()
		else
			tbl.stopAnim17871770160()
		end
	end,
})

do
	local animationId = "rbxassetid://14686794862"
	local v18 = nil
	local v19 = nil
	local v20 = nil
	local flag = false

	local function fn7()
		if v20 then
			pcall(function()
				v20:Stop()
			end)

			v20 = nil
		end

		flag = false

		if v19 then
			v19.Text = "开"
			v19.BackgroundColor3 = color(30, 30, 40)
		end
	end

	local function fn8()
		fn7()
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local animator = humanoid:FindFirstChildOfClass("Animator")

		if not animator then
			local animator2 = Instance.new("Animator")
			animator2.Parent = humanoid
			animator = animator2
		end

		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		local v21 = animator:LoadAnimation(animation)
		v21.Priority = Enum.AnimationPriority.Action4
		v21:Play()
		v21:AdjustSpeed(0)
		v20 = v21
		flag = true

		if v19 then
			v19.Text = "关"
			v19.BackgroundColor3 = color(200, 80, 80)
		end
	end

	tbl.toggleNewAnimUI = function(arg)
		if arg then
			if v18 then
				v18:Destroy()
			end

			local NewAnimUI, v21 = tbl.createFloatingButton("NewAnimUI", "开", UDim2.new(0.5, 105, 0.45, 0), 18, function()
				if flag then
					fn7()
				else
					fn8()
				end
			end)

			v18 = NewAnimUI
			v19 = v21
			flag = false
		else
			if v18 then
				v18:Destroy()
				v18 = nil
				v19 = nil
			end

			fn7()
		end
	end
end

v14:AddToggle("NewAnimUIToggle", {
	Text = "打开遁地快捷栏",
	Default = false,
	Tooltip = fn4("无"),
	Callback = function(arg)
		tbl.toggleNewAnimUI(arg)
	end,
})

do
	local flag = false
	local v18 = nil
	local thread = nil
	local v19 = nil
	local v20 = nil

	local function fn7()
		if flag then
			return
		end
		flag = true
		local v21, v22 = fn6()
		if not v22 then
			flag = false
			return
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://17871770160"
		local v23 = v22:LoadAnimation(animation)
		v23.Priority = Enum.AnimationPriority.Action4
		v23.Looped = true
		v23:Play()
		v18 = v23

		if thread then
			task.cancel(thread)
		end

		thread = task.spawn(function()
			task.wait(0.45)

			if flag and v18 then
				pcall(function()
					v18:AdjustSpeed(0)
				end)
			end

			thread = nil
		end)
	end

	local function fn8()
		flag = false

		if thread then
			task.cancel(thread)
			thread = nil
		end

		if v18 then
			pcall(function()
				v18:Stop()
			end)

			v18 = nil
		end
	end

	local function fn9()
		if v20 then
			return
		end

		local Anim17871770160UI, v21 = tbl.createFloatingButton("Anim17871770160UI", "开启", UDim2.new(0.5, 175, 0.45, 0), 18, function()
			if flag then
				fn8()
				v19.Text = "开启"
				v19.BackgroundColor3 = color(30, 30, 40)
			else
				fn7()
				v19.Text = "关闭"
				v19.BackgroundColor3 = color(200, 80, 80)
			end
		end)

		v19 = v21
		v20 = Anim17871770160UI
	end

	local function fn10()
		if v20 then
			v20:Destroy()
			v20 = nil
			v19 = nil
		end

		fn8()
	end

	tbl.onCharacterAdded(function()
		if flag then
			fn8()

			if v19 then
				v19.Text = "开启"
				v19.BackgroundColor3 = color(30, 30, 40)
			end
		end
	end)

	tbl.toggleAnim17871770160UI = function(arg)
		if arg then
			fn9()
		else
			fn10()
		end
	end
end

tbl.animCustomDual4 = { active = false, idleTrack = nil, walkTrack = nil, conn = nil, key = "animCustomDual4" }

tbl.startAnimCustomDual4 = function()
	tbl.startDual(tbl.animCustomDual4, "rbxassetid://99319014110614", "rbxassetid://81750747292490")
end

tbl.stopAnimCustomDual4 = function()
	tbl.stopDual(tbl.animCustomDual4)
end

tbl.onCharacterAdded(function()
	if tbl.animCustomDual4 and tbl.animCustomDual4.active then
		tbl.stopAnimCustomDual4()
		local animCustomDual4Toggle = toggles.AnimCustomDual4Toggle

		if animCustomDual4Toggle and animCustomDual4Toggle.SetValue then
			animCustomDual4Toggle:SetValue(false)
		end
	end
end)

v13:AddToggle("AnimCustomDual4Toggle", {
	Text = "拉大炮2",
	Default = false,
	Tooltip = fn4("静止播放动画1，移动播放动画2"),
	Callback = function(arg)
		if arg then
			tbl.startAnimCustomDual4()
		else
			tbl.stopAnimCustomDual4()
		end
	end,
})

local v18
v18 = tbl3.Extra:AddGroupbox({ Side = "Left", Name = "工兵", IconName = "hammer", Description = "修建近战" })
local v19

do
	local v20 = tbl3.Extra:AddGroupbox({ Side = "Right", Name = "军官 线列 水手", IconName = "users", Description = "武器功能" })
	tbl.officer = tbl.officer or {}
	tbl.officer.autoReload = { enabled = false, monitoredTools = {}, notifyCooldown = 4, lastNotifyTime = 0 }
	tbl.officer.autoReload.isGun = tbl.sharedIsGun
	tbl.officer.autoReload.getShotsLoaded = tbl.sharedGetShotsLoaded
	tbl.officer.autoReload.getRemote = tbl.sharedGetRemote

	tbl.officer.autoReload.tryReload = function(arg)
		if not tbl.officer.autoReload.enabled then
			return
		end

		if not arg or not arg.Parent then
			return
		end

		if not tbl.officer.autoReload.isGun(arg) then
			return
		end

		if tbl.officer.autoReload.getShotsLoaded(arg) == 0 then
			local v21 = tbl.officer.autoReload.getRemote(arg)

			if v21 then
				pcall(function()
					v21:FireServer("Reload")
				end)
			end
		end
	end

	tbl.officer.autoReload.watchTool = function(arg)
		if not arg or not tbl.officer.autoReload.isGun(arg) then
			return
		end

		if tbl.officer.autoReload.monitoredTools[arg] then
			return
		end
		local shotsLoaded = arg:FindFirstChild("ShotsLoaded")
		local flag = not shotsLoaded

		if not flag then
			flag = not (shotsLoaded:IsA("IntValue") or shotsLoaded:IsA("NumberValue"))
		end

		if flag then
			local players = workspace:FindFirstChild("Players")

			if players then
				local v21 = players:FindFirstChild(localPlayer.Name)

				if v21 then
					local v22 = v21:FindFirstChild(arg.Name)

					if v22 then
						shotsLoaded = v22:FindFirstChild("ShotsLoaded")
					end
				end
			end
		end

		if not shotsLoaded then
			return
		end
		local v21 = tbl.officer.autoReload.getRemote(arg)
		local n = shotsLoaded.Value or 0

		if tbl.officer.autoReload.enabled and n == 0 and v21 then
			pcall(function()
				v21:FireServer("Reload")
			end)
		end

		local flag2 = false
		local connection = nil

		local connection2 = shotsLoaded.Changed:Connect(function()
			local value = shotsLoaded.Value

			if tbl.officer.autoReload.enabled and value == 0 and v21 and not flag2 then
				flag2 = true

				pcall(function()
					v21:FireServer("Reload")
				end)

				task.delay(1.2, function()
					flag2 = false
				end)
			end

			n = value
		end)

		connection = arg.AncestryChanged:Connect(function(child, parent)
			if not parent then
				if connection2 then
					connection2:Disconnect()
				end

				tbl.officer.autoReload.monitoredTools[arg] = nil

				if connection then
					connection:Disconnect()
				end
			end
		end)

		tbl.officer.autoReload.monitoredTools[arg] = connection2
	end

	tbl.officer.autoReload.scanAllTools = function()
		for _, v21 in tbl.officer.autoReload.monitoredTools, nil, nil do
			if v21 then
				v21:Disconnect()
			end
		end

		tbl.officer.autoReload.monitoredTools = {}
		local backpack = localPlayer:FindFirstChild("Backpack")

		if backpack then
			for _, v21 in backpack:GetChildren() do
				if v21:IsA("Tool") and tbl.officer.autoReload.isGun(v21) then
					tbl.officer.autoReload.watchTool(v21)
				end
			end
		end

		local character = localPlayer.Character

		if character then
			for _, v21 in character:GetChildren() do
				if v21:IsA("Tool") and tbl.officer.autoReload.isGun(v21) then
					tbl.officer.autoReload.watchTool(v21)
				end
			end
		end
	end

	tbl.officer.autoReload.enable = function()
		if tbl.officer.autoReload.enabled then
			return
		end
		tbl.officer.autoReload.enabled = true
		tbl.officer.autoReload.scanAllTools()

		if tbl.officer.autoReload.backpackConn then
			tbl.officer.autoReload.backpackConn:Disconnect()
		end

		local function fn7()
			local backpack = localPlayer:FindFirstChild("Backpack")
			if not backpack then
				return false
			end

			if tbl.officer.autoReload.backpackConn then
				tbl.officer.autoReload.backpackConn:Disconnect()
			end

			tbl.officer.autoReload.backpackConn = backpack.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and tbl.officer.autoReload.isGun(child) then
					task.wait(0.1)

					if tbl.officer.autoReload.enabled then
						tbl.officer.autoReload.watchTool(child)
					end
				end
			end)

			return true
		end

		if not fn7() then
			task.spawn(function()
				while tbl.officer.autoReload.enabled and not tbl.officer.autoReload.backpackConn do
					task.wait(0.5)
					fn7()
				end
			end)
		end

		if tbl.officer.autoReload.characterConn then
			tbl.officer.autoReload.characterConn:Disconnect()
			tbl.officer.autoReload.characterConn = nil
		end

		if localPlayer.Character then
			tbl.officer.autoReload.characterConn = localPlayer.Character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and tbl.officer.autoReload.isGun(child) then
					task.wait(0.1)

					if tbl.officer.autoReload.enabled then
						tbl.officer.autoReload.watchTool(child)
						tbl.officer.autoReload.tryReload(child)
					end
				end
			end)
		end

		tbl.notify(fn3("自动换弹已开启"), 2)
	end

	tbl.officer.autoReload.disable = function()
		tbl.officer.autoReload.enabled = false

		for _, v21 in tbl.officer.autoReload.monitoredTools, nil, nil do
			if v21 then
				v21:Disconnect()
			end
		end

		tbl.officer.autoReload.monitoredTools = {}

		if tbl.officer.autoReload.backpackConn then
			tbl.officer.autoReload.backpackConn:Disconnect()
			tbl.officer.autoReload.backpackConn = nil
		end

		if tbl.officer.autoReload.characterConn then
			tbl.officer.autoReload.characterConn:Disconnect()
			tbl.officer.autoReload.characterConn = nil
		end

		tbl.notify(fn3("自动换弹已关闭"), 2)
	end

	v20:AddToggle("OfficerAutoReloadToggle", {
		Text = "自动换弹",
		Default = false,
		Tooltip = fn4("枪械子弹打空后自动装填"),
		Callback = function(arg)
			if arg then
				tbl.officer.autoReload.enable()
			else
				tbl.officer.autoReload.disable()
			end
		end,
	})

	tbl.officer = tbl.officer or {}
	tbl.officer.autoHolster = { enabled = false, isHolstering = false, monitoredTools = {} }
	tbl.officer.autoHolster.isGun = tbl.sharedIsGun
	tbl.officer.autoHolster.getShotsLoaded = tbl.sharedGetShotsLoaded

	tbl.officer.autoHolster.holsterAndReequip = function(arg)
		if not tbl.officer.autoHolster.enabled then
			return
		end

		if tbl.officer.autoHolster.isHolstering then
			return
		end

		if not arg or not arg.Parent then
			return
		end
		tbl.officer.autoHolster.isHolstering = true

		task.spawn(function()
			local character = localPlayer.Character
			local backpack = localPlayer:FindFirstChild("Backpack")

			if character and backpack and arg and arg.Parent == character then
				arg.Parent = backpack
				task.wait(0.05)

				if arg and arg.Parent == backpack then
					arg.Parent = character
				end
			end

			task.wait(0.05)
			tbl.officer.autoHolster.isHolstering = false
		end)
	end

	tbl.officer.autoHolster.watchTool = function(arg)
		if not arg or not tbl.officer.autoHolster.isGun(arg) then
			return
		end

		if tbl.officer.autoHolster.monitoredTools[arg] then
			return
		end
		local shotsLoaded = arg:FindFirstChild("ShotsLoaded")
		local flag = not shotsLoaded

		if not flag then
			flag = not (shotsLoaded:IsA("IntValue") or shotsLoaded:IsA("NumberValue"))
		end

		if flag then
			local players = workspace:FindFirstChild("Players")

			if players then
				local v21 = players:FindFirstChild(localPlayer.Name)

				if v21 then
					local v22 = v21:FindFirstChild(arg.Name)

					if v22 then
						shotsLoaded = v22:FindFirstChild("ShotsLoaded")
					end
				end
			end
		end

		if not shotsLoaded then
			return
		end
		local n = shotsLoaded.Value or 0
		local connection = nil

		local connection2 = shotsLoaded.Changed:Connect(function()
			local value = shotsLoaded.Value

			if tbl.officer.autoHolster.enabled and type(value) == "number" and type(n) == "number" and value > n then
				for i = n + 1, value do
					task.spawn(function()
						tbl.officer.autoHolster.holsterAndReequip(arg)
					end)
				end
			end

			n = value
		end)

		connection = arg.AncestryChanged:Connect(function(child, parent)
			if not parent then
				if connection2 then
					connection2:Disconnect()
				end

				tbl.officer.autoHolster.monitoredTools[arg] = nil

				if connection then
					connection:Disconnect()
				end
			end
		end)

		tbl.officer.autoHolster.monitoredTools[arg] = connection2
	end

	tbl.officer.autoHolster.scanAllTools = function()
		for _, v21 in tbl.officer.autoHolster.monitoredTools, nil, nil do
			if v21 then
				v21:Disconnect()
			end
		end

		tbl.officer.autoHolster.monitoredTools = {}
		local backpack = localPlayer:FindFirstChild("Backpack")

		if backpack then
			for _, v21 in backpack:GetChildren() do
				if v21:IsA("Tool") and tbl.officer.autoHolster.isGun(v21) then
					tbl.officer.autoHolster.watchTool(v21)
				end
			end
		end

		local character = localPlayer.Character

		if character then
			for _, v21 in character:GetChildren() do
				if v21:IsA("Tool") and tbl.officer.autoHolster.isGun(v21) then
					tbl.officer.autoHolster.watchTool(v21)
				end
			end
		end
	end

	tbl.officer.autoHolster.start = function()
		if tbl.officer.autoHolster.enabled then
			return
		end
		tbl.officer.autoHolster.enabled = true
		tbl.officer.autoHolster.scanAllTools()

		if tbl.officer.autoHolster.backpackConn then
			tbl.officer.autoHolster.backpackConn:Disconnect()
		end

		local function fn7()
			local backpack = localPlayer:FindFirstChild("Backpack")
			if not backpack then
				return false
			end

			if tbl.officer.autoHolster.backpackConn then
				tbl.officer.autoHolster.backpackConn:Disconnect()
			end

			tbl.officer.autoHolster.backpackConn = backpack.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and tbl.officer.autoHolster.isGun(child) then
					task.wait(0.1)

					if tbl.officer.autoHolster.enabled then
						tbl.officer.autoHolster.watchTool(child)
					end
				end
			end)

			return true
		end

		if not fn7() then
			task.spawn(function()
				while tbl.officer.autoHolster.enabled and not tbl.officer.autoHolster.backpackConn do
					task.wait(0.5)
					fn7()
				end
			end)
		end

		if tbl.officer.autoHolster.characterConn then
			tbl.officer.autoHolster.characterConn:Disconnect()
			tbl.officer.autoHolster.characterConn = nil
		end

		if localPlayer.Character then
			tbl.officer.autoHolster.characterConn = localPlayer.Character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and tbl.officer.autoHolster.isGun(child) then
					task.wait(0.1)

					if tbl.officer.autoHolster.enabled then
						tbl.officer.autoHolster.watchTool(child)
					end
				end
			end)
		end

		tbl.notify(fn3("自动收枪已开启"), 2)
	end

	tbl.officer.autoHolster.stop = function()
		tbl.officer.autoHolster.enabled = false

		for _, v21 in tbl.officer.autoHolster.monitoredTools, nil, nil do
			if v21 then
				v21:Disconnect()
			end
		end

		tbl.officer.autoHolster.monitoredTools = {}

		if tbl.officer.autoHolster.backpackConn then
			tbl.officer.autoHolster.backpackConn:Disconnect()
			tbl.officer.autoHolster.backpackConn = nil
		end

		if tbl.officer.autoHolster.characterConn then
			tbl.officer.autoHolster.characterConn:Disconnect()
			tbl.officer.autoHolster.characterConn = nil
		end

		tbl.notify(fn3("自动收枪已关闭"), 2)
	end

	v20:AddToggle("OfficerAutoHolsterToggle", {
		Text = "换弹完成后自动重新装备武器",
		Default = false,
		Tooltip = fn4("每装填一发子弹后自动收回枪械再装备"),
		Callback = function(arg)
			if arg then
				tbl.officer.autoHolster.start()
			else
				tbl.officer.autoHolster.stop()
			end
		end,
	})

	tbl.officer.autoJump = {
		enabled = false,
		jumpHeight = 3,
		cooldown = 0.5,
		lastJump = 0,
		trackCache = {},
		animator = nil,
		humanoid = nil,
		monitoring = false,
	}

	local tbl5 = {
		"rbxassetid://17406577733",
		"rbxassetid://15669224658",
		"rbxassetid://12591948314",
		"rbxassetid://12333491302",
	}

	tbl.officer.autoJump.isTargetAnim = function(arg)
		for _, v21 in tbl5, nil, nil do
			if arg == v21 then
				return true
			end
		end

		return false
	end

	tbl.officer.autoJump.doJump = function()
		if not tbl.officer.autoJump.humanoid or not tbl.officer.autoJump.humanoid.Parent then
			return
		end
		local lastJump = tbl.officer.autoJump.lastJump
		if clock() - lastJump < tbl.officer.autoJump.cooldown then
			return
		end

		task.spawn(function()
			pcall(function()
				local v21 = clock2()

				while clock2() - v21 < 1 do
					local state = tbl.officer.autoJump.humanoid:GetState()
					if not (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Climbing) then
						task.wait(0.05)
						continue
					end
					break
				end

				local humanoidRootPart = tbl.officer.autoJump.humanoid.Parent:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then
					local z = humanoidRootPart.AssemblyLinearVelocity.Z
					humanoidRootPart.AssemblyLinearVelocity = vector(humanoidRootPart.AssemblyLinearVelocity.X, sqrt(2 * workspace.Gravity * clamp(tbl.officer.autoJump.jumpHeight, 0, 6)), z)
					tbl.officer.autoJump.lastJump = clock()
				end
			end)
		end)
	end

	tbl.officer.autoJump.startMonitoring = function()
		if tbl.officer.autoJump.monitoring then
			return
		end
		tbl.officer.autoJump.monitoring = true

		task.spawn(function()
			while tbl.officer.autoJump.monitoring do
				if tbl.officer.autoJump.animator then
					local ok, result = pcall(function()
						return tbl.officer.autoJump.animator:GetPlayingAnimationTracks()
					end)

					if ok and result then
						for _, v21 in result, nil, nil do
							local animation = v21.Animation

							if animation and tbl.officer.autoJump.isTargetAnim(animation.AnimationId) and not tbl.officer.autoJump.trackCache[v21] then
								tbl.officer.autoJump.trackCache[v21] = true
								pcall(tbl.officer.autoJump.doJump)

								v21.Stopped:Once(function()
									tbl.officer.autoJump.trackCache[v21] = nil
								end)
							end
						end
					end
				end

				task.wait(0.08)
			end
		end)
	end

	tbl.officer.autoJump.stopMonitoring = function()
		tbl.officer.autoJump.monitoring = false
		tbl.officer.autoJump.trackCache = {}
	end

	tbl.officer.autoJump.refreshCharacter = function(arg)
		tbl.officer.autoJump.humanoid = arg and arg:FindFirstChildOfClass("Humanoid")
		tbl.officer.autoJump.animator = nil

		if tbl.officer.autoJump.humanoid then
			tbl.officer.autoJump.animator = tbl.officer.autoJump.humanoid:FindFirstChildOfClass("Animator")

			if not tbl.officer.autoJump.animator then
				tbl.officer.autoJump.animator = Instance.new("Animator")
				tbl.officer.autoJump.animator.Parent = tbl.officer.autoJump.humanoid
			end
		end

		tbl.officer.autoJump.trackCache = {}
		tbl.officer.autoJump.lastJump = 0
	end

	tbl.officer.autoJump.start = function()
		if tbl.officer.autoJump.enabled then
			return
		end
		tbl.officer.autoJump.enabled = true
		tbl.officer.autoJump.refreshCharacter(localPlayer.Character)
		tbl.officer.autoJump.startMonitoring()
		tbl.notify(fn3("自动跳刀已开启"), 2)
	end

	tbl.officer.autoJump.stop = function()
		tbl.officer.autoJump.enabled = false
		tbl.officer.autoJump.stopMonitoring()
		tbl.notify(fn3("自动跳刀已关闭"), 2)
	end

	tbl.onCharacterAdded(function(arg)
		task.wait(0.2)

		if tbl.officer.autoJump.enabled then
			tbl.officer.autoJump.refreshCharacter(arg)
			tbl.officer.autoJump.startMonitoring()
		end
	end)

	v20:AddToggle("OfficerAutoJumpToggle", {
		Text = "自动跳刀",
		Default = false,
		Tooltip = fn4("军刀前刺动画时自动跳跃"),
		Callback = function(arg)
			if arg then
				tbl.officer.autoJump.start()
			else
				tbl.officer.autoJump.stop()
			end
		end,
	})

	tbl.martyr = tbl.martyr or {}
	tbl.martyr.autoCharge = { enabled = false, thread = nil }

	tbl.martyr.autoCharge.loop = function()
		while tbl.martyr.autoCharge.enabled do
			local character = localPlayer.Character

			if character then
				for _, v21 in character:GetChildren() do
					if v21:IsA("Tool") then
						local remoteEvent = v21:FindFirstChild("RemoteEvent")

						if remoteEvent then
							pcall(function()
								remoteEvent:FireServer("Charge")
							end)
						end
					end
				end
			end

			task.wait(0.125)
		end
	end

	tbl.martyr.autoCharge.start = function()
		if tbl.martyr.autoCharge.thread then
			return
		end
		tbl.martyr.autoCharge.enabled = true
		tbl.martyr.autoCharge.thread = task.spawn(tbl.martyr.autoCharge.loop)
		tbl.notify(fn3("自动冲锋已开启"), 2)
	end

	tbl.martyr.autoCharge.stop = function()
		tbl.martyr.autoCharge.enabled = false

		if tbl.martyr.autoCharge.thread then
			task.cancel(tbl.martyr.autoCharge.thread)
			tbl.martyr.autoCharge.thread = nil
		end

		tbl.notify(fn3("自动冲锋已关闭"), 2)
	end

	tbl.onCharacterAdded(function()
		if tbl.martyr.autoCharge.enabled then
			task.wait(0.5)
			tbl.martyr.autoCharge.stop()
			task.wait(0.1)
			tbl.martyr.autoCharge.start()
		end
	end)

	v20:AddToggle("MartyrAutoChargeToggle", {
		Text = "自动冲锋",
		Default = false,
		Tooltip = fn4("能量满后自动开启冲锋"),
		Callback = function(arg)
			if arg then
				tbl.martyr.autoCharge.start()
			else
				tbl.martyr.autoCharge.stop()
			end
		end,
	})

	tbl.martyr.autoBlackKnife = { enabled = false, thread = nil, cd = {}, range = 15, teamRange = 7 }

	tbl.martyr.autoBlackKnife.getHRP = function(arg)
		return arg and arg:FindFirstChild("HumanoidRootPart")
	end

	tbl.martyr.autoBlackKnife.getWeapon = function()
		local character = localPlayer.Character
		if not character then
			return nil
		end

		for _, v21 in character:GetChildren() do
			if v21:IsA("Tool") and v21:GetAttribute("Melee") then
				return v21
			end
		end

		return character:FindFirstChildOfClass("Tool")
	end

	tbl.martyr.autoBlackKnife.getBarrelZombies = function()
		local tbl6 = {}
		local zombies = workspace:FindFirstChild("Zombies")

		if zombies then
			for _, v21 in zombies:GetChildren() do
				if v21:IsA("Model") and (v21:GetAttribute("Type") == "Barrel" or v21:FindFirstChild("Barrel")) then
					table.insert(tbl6, v21)
				end
			end
		end

		return tbl6
	end

	tbl.martyr.autoBlackKnife.attackBarrel = function(arg)
		if not arg then
			return false
		end
		local v21 = tbl.martyr.autoBlackKnife.getWeapon()
		if not v21 then
			return false
		end
		local remoteEvent = v21:FindFirstChild("RemoteEvent")
		if not remoteEvent then
			return false
		end
		local head = arg:FindFirstChild("Head")
		if not head then
			return false
		end
		local humanoidRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

		if humanoidRootPart then
			pcall(function()
				humanoidRootPart.CFrame = cframe(humanoidRootPart.Position, vector(head.Position.X, humanoidRootPart.Position.Y, head.Position.Z))
			end)
		end

		pcall(function()
			remoteEvent:FireServer("Swing", "Side")
			remoteEvent:FireServer("HitZombie", arg, head.Position, true)
		end)

		return true
	end

	tbl.martyr.autoBlackKnife.loop = function()
		while tbl.martyr.autoBlackKnife.enabled do
			task.wait(0.15)
			local character = localPlayer.Character and tbl.martyr.autoBlackKnife.getHRP(localPlayer.Character)

			if character then
				for _, v21 in tbl.martyr.autoBlackKnife.getBarrelZombies(), nil, nil do
					if tbl.martyr.autoBlackKnife.enabled then
						local humanoidRootPart = v21:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart then
							if not (tbl.martyr.autoBlackKnife.range < (humanoidRootPart.Position - character.Position).Magnitude) then
								local flag = false
								local str2 = ""

								for _, v22 in v4:GetPlayers() do
									if v22 == localPlayer then
										flag = false
										str2 = ""
									else
										local character2 = v22.Character and tbl.martyr.autoBlackKnife.getHRP(v22.Character)

										if character2 and (character2.Position - humanoidRootPart.Position).Magnitude <= tbl.martyr.autoBlackKnife.teamRange then
											str2 = v22.Name
											flag = true
											break
										else
											flag = false
											str2 = ""
										end
									end
								end

								if flag then
									local str3 = str2 .. tostring(v21)
									local flag2 = tbl.martyr.autoBlackKnife.cd[str3]

									if flag2 then
										local v22 = tbl.martyr.autoBlackKnife.cd[str3]
										flag2 = clock() - v22 < 0.5
									end

									if not flag2 then
										tbl.martyr.autoBlackKnife.cd[str3] = clock()

										for i = 1, 3 do
											tbl.martyr.autoBlackKnife.attackBarrel(v21)
											task.wait(0.05)
										end
									end
								end
							end
						end

						continue
					end

					break
				end
			end
		end
	end

	tbl.martyr.autoBlackKnife.start = function()
		if tbl.martyr.autoBlackKnife.thread then
			return
		end
		tbl.martyr.autoBlackKnife.enabled = true
		tbl.martyr.autoBlackKnife.cd = {}
		tbl.martyr.autoBlackKnife.thread = task.spawn(tbl.martyr.autoBlackKnife.loop)
		tbl.notify(fn3("自动黑刀已开启"), 2)
	end

	tbl.martyr.autoBlackKnife.stop = function()
		tbl.martyr.autoBlackKnife.enabled = false

		if tbl.martyr.autoBlackKnife.thread then
			task.cancel(tbl.martyr.autoBlackKnife.thread)
			tbl.martyr.autoBlackKnife.thread = nil
		end

		tbl.martyr.autoBlackKnife.cd = {}
		tbl.notify(fn3("自动黑刀已关闭"), 2)
	end

	v20:AddToggle("MartyrAutoBlackKnifeToggle", {
		Text = "自动黑刀",
		Default = false,
		Tooltip = fn4("队友靠近自爆时自动攻击"),
		Callback = function(arg)
			if arg then
				tbl.martyr.autoBlackKnife.start()
			else
				tbl.martyr.autoBlackKnife.stop()
			end
		end,
	})

	v19 = v(game:GetService("Workspace"))
	local v21 = localPlayer
	tbl.customBlackGunEnabled = false
	tbl.customBlackGunNoEquip = false
	tbl.customBlackGunCooldown = 0.3
	tbl.customBlackGunEquipDelay = 0.1
	tbl.customBlackGunBarrelDistance = 10
	tbl.customWallCheckEnabled = false
	tbl.customShootingThread = nil
	tbl.customShootingRunning = false

	tbl.isGun = function(arg)
		if not arg or not arg:IsA("Tool") then
			return false
		end
		local animations = arg:FindFirstChild("Animations")

		if animations then
			animations = animations:FindFirstChild("Aim") or animations:FindFirstChild("Aiming")
		end

		if animations then
			return true
		end
		return tbl.GUN_NAME_SET[arg.Name] == true
	end

	tbl.getShotsLoaded = tbl.sharedGetShotsLoaded
	tbl.getRemote = tbl.sharedGetRemote

	tbl.getAnyGun = function()
		local character = v21.Character
		local backpack = v21:FindFirstChild("Backpack")

		if backpack then
			for _, v22 in backpack:GetChildren() do
				if v22:IsA("Tool") and tbl.isGun(v22) then
					local v23 = tbl.getShotsLoaded(v22)
					if v23 and v23 > 0 then
						return v22
					end
				end
			end
		end

		if character then
			for _, v22 in character:GetChildren() do
				if v22:IsA("Tool") and tbl.isGun(v22) then
					local v23 = tbl.getShotsLoaded(v22)
					if v23 and v23 > 0 then
						return v22
					end
				end
			end
		end

		return nil
	end

	tbl.hasAnyAmmo = function()
		local backpack = v21:FindFirstChild("Backpack")

		if backpack then
			for _, v22 in backpack:GetChildren() do
				if v22:IsA("Tool") and tbl.isGun(v22) then
					local v23 = tbl.getShotsLoaded(v22)
					if v23 and v23 > 0 then
						return true
					end
				end
			end
		end

		local character = v21.Character

		if character then
			for _, v22 in character:GetChildren() do
				if v22:IsA("Tool") and tbl.isGun(v22) then
					local v23 = tbl.getShotsLoaded(v22)
					if v23 and v23 > 0 then
						return true
					end
				end
			end
		end

		return false
	end

	tbl.isWallBetween = function(arg, arg2, arg3)
		if not tbl.customWallCheckEnabled then
			return false
		end
		local n = arg2 - arg
		if n.Magnitude <= 0 then
			return false
		end
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local filterDescendantsInstances = {}

		for _, v22 in v4:GetPlayers() do
			if v22.Character then
				table.insert(filterDescendantsInstances, v22.Character)
			end
		end

		local zombies = v19:FindFirstChild("Zombies")

		if zombies then
			table.insert(filterDescendantsInstances, zombies)
		end

		if arg3 then
			table.insert(filterDescendantsInstances, arg3)
		end

		raycastParams.FilterDescendantsInstances = filterDescendantsInstances
		return v19:Raycast(arg, n, raycastParams) ~= nil
	end

	tbl.hasPlayerNearBomber = function(arg, arg2)
		local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart") or arg:FindFirstChild("Torso")
		if not humanoidRootPart then
			return false
		end
		local position = humanoidRootPart.Position

		for _, v22 in v4:GetPlayers() do
			if v22 == v21 then
				continue
			end
			local character = v22.Character

			if character then
				local humanoidRootPart2 = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")

				if humanoidRootPart2 then
					if (position - humanoidRootPart2.Position).Magnitude <= arg2 then
						return true
					end
				end
			end
		end

		return false
	end

	tbl.getClosestBomber = function()
		local character = v21.Character
		if not character then
			return nil, nil
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return nil, nil
		end
		local position = humanoidRootPart.Position
		local tbl6 = {}
		local camera = v19:FindFirstChild("Camera")

		if camera then
			table.insert(tbl6, camera)
		end

		local zombies = v19:FindFirstChild("Zombies")

		if zombies then
			table.insert(tbl6, zombies)
		end

		local n = 200
		local v22 = nil
		local v23 = nil

		for _, v24 in tbl6, nil, nil do
			for _, v25 in v24:GetDescendants() do
				local isModel = v25:IsA("Model")

				if isModel then
					isModel = v25.Name == "m_Zombie" or v25:GetAttribute("Type") == "Barrel" or v25:FindFirstChild("Barrel")
				end

				if isModel then
					if v25:GetAttribute("Type") == "Barrel" or v25:FindFirstChild("Barrel") then
						local barrel = v25:FindFirstChild("Barrel") or v25:FindFirstChild("Head") or v25:FindFirstChild("HumanoidRootPart")

						if not (not barrel or not barrel:IsA("BasePart")) then
							local magnitude = (barrel.Position - position).Magnitude

							if magnitude <= 200 and magnitude < n then
								if not tbl.isWallBetween(position, barrel.Position, v25) then
									n = magnitude
									v22 = barrel
									v23 = v25
								end
							end
						end
					end
				end
			end
		end

		return v22, v23
	end

	tbl.shootAtTarget = function(arg, arg2, arg3)
		if not arg3 or not arg then
			return
		end
		local v22 = tbl.getRemote(arg3)
		if not v22 then
			return
		end
		local character = v21.Character
		if not character then
			return
		end
		local model = character:FindFirstChild("Model") or character
		local serverTimeNow = v19:GetServerTimeNow()

		pcall(function()
			v22:FireServer("Fire", model, arg.Position, serverTimeNow)
		end)
	end

	tbl.customShootingLoop = function()
		tbl.customShootingRunning = true
		local v22, v23, character, v24

		while true do
			local customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
			local exitTo = nil
			local flag, flag2, flag3

			while customShootingRunning do
				local flag4, flag5, backpack, isTool, flag6

				if not tbl.hasAnyAmmo() then
					task.wait(0.5)

					while tbl.customBlackGunEnabled and not tbl.hasAnyAmmo() do
						task.wait(0.5)
					end

					if tbl.customBlackGunEnabled then
						v22, v23 = tbl.getClosestBomber()
						flag4 = not v22
						flag5 = flag4 or not v23

						if flag5 then
							exitTo = 8
							break
						elseif not tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
							exitTo = 9
							break
						else
							character = v21.Character

							if not character then
								exitTo = 10
								break
							else
								v24 = tbl.getAnyGun()

								if not v24 then
									if not tbl.customBlackGunNoEquip then
										backpack = v21:FindFirstChild("Backpack")

										if backpack then
											for _, v25 in backpack:GetChildren() do
												isTool = v25:IsA("Tool") and tbl.isGun(v25)

												if isTool then
													flag6 = tbl.getShotsLoaded(v25)
													flag6 = flag6 and flag6 > 0

													if flag6 then
														v25.Parent = character
														task.wait(0.1)
														v24 = v25
														break
													end
												end
											end
										end
									end

									if not v24 then
										exitTo = 13
										break
									else
										flag = not tbl.customBlackGunNoEquip
										flag2 = flag and v24.Parent ~= character

										if flag2 then
											v24.Parent = character
											task.wait(0.1)

											if v24.Parent ~= character then
												task.wait(0.1)
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											elseif tbl.getShotsLoaded(v24) == 0 then
												task.wait(0.1)
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											else
												task.wait(tbl.customBlackGunEquipDelay)
												flag3 = not v22.Parent or not v23.Parent

												if flag3 then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												elseif not tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												elseif tbl.getShotsLoaded(v24) == 0 then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												else
													tbl.shootAtTarget(v22, v23, v24)
													task.wait(tbl.customBlackGunCooldown)
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												end
											end
										elseif tbl.getShotsLoaded(v24) == 0 then
											task.wait(0.1)
											customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
										else
											task.wait(tbl.customBlackGunEquipDelay)
											flag3 = not v22.Parent or not v23.Parent

											if flag3 then
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											elseif not tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											elseif tbl.getShotsLoaded(v24) == 0 then
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											else
												tbl.shootAtTarget(v22, v23, v24)
												task.wait(tbl.customBlackGunCooldown)
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											end
										end

										continue
									end
								else
									flag = not tbl.customBlackGunNoEquip
									flag2 = flag and v24.Parent ~= character

									if flag2 then
										v24.Parent = character
										task.wait(0.1)

										if v24.Parent ~= character then
											exitTo = 12
											break
										else
											if tbl.getShotsLoaded(v24) == 0 then
												task.wait(0.1)
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											else
												task.wait(tbl.customBlackGunEquipDelay)
												flag3 = not v22.Parent or not v23.Parent

												if flag3 then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												elseif not tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												elseif tbl.getShotsLoaded(v24) == 0 then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												else
													tbl.shootAtTarget(v22, v23, v24)
													task.wait(tbl.customBlackGunCooldown)
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												end
											end

											continue
										end
									else
										exitTo = 11
										break
									end
								end
							end
						end
					end
				else
					v22, v23 = tbl.getClosestBomber()
					flag4 = not v22
					flag5 = flag4 or not v23

					if flag5 then
						exitTo = 1
						break
					elseif not tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
						exitTo = 2
						break
					else
						character = v21.Character

						if not character then
							exitTo = 3
							break
						else
							v24 = tbl.getAnyGun()

							if not v24 then
								if not tbl.customBlackGunNoEquip then
									backpack = v21:FindFirstChild("Backpack")

									if backpack then
										for _, v25 in backpack:GetChildren() do
											isTool = v25:IsA("Tool") and tbl.isGun(v25)

											if isTool then
												flag6 = tbl.getShotsLoaded(v25)
												flag6 = flag6 and flag6 > 0

												if flag6 then
													v25.Parent = character
													task.wait(0.1)
													v24 = v25
													break
												end
											end
										end
									end
								end

								if not v24 then
									exitTo = 5
									break
								else
									flag = not tbl.customBlackGunNoEquip
									flag2 = flag and v24.Parent ~= character

									if flag2 then
										v24.Parent = character
										task.wait(0.1)

										if v24.Parent ~= character then
											exitTo = 7
											break
										else
											if tbl.getShotsLoaded(v24) == 0 then
												task.wait(0.1)
												customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
											else
												task.wait(tbl.customBlackGunEquipDelay)
												flag3 = not v22.Parent or not v23.Parent

												if flag3 then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												elseif not tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												elseif tbl.getShotsLoaded(v24) == 0 then
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												else
													tbl.shootAtTarget(v22, v23, v24)
													task.wait(tbl.customBlackGunCooldown)
													customShootingRunning = tbl.customBlackGunEnabled and tbl.customShootingRunning
												end
											end

											continue
										end
									else
										exitTo = 6
										break
									end
								end
							else
								exitTo = 4
								break
							end
						end
					end
				end

				break
			end

			if exitTo == 1 then
				task.wait(0.15)
				continue
			end

			if exitTo == 2 then
				task.wait(0.15)
				continue
			end

			if exitTo == 3 then
				task.wait(0.15)
				continue
			end

			if exitTo == 4 then
				flag = not tbl.customBlackGunNoEquip
				flag2 = flag and v24.Parent ~= character

				if flag2 then
					v24.Parent = character
					task.wait(0.1)

					if v24.Parent ~= character then
						task.wait(0.1)
					elseif tbl.getShotsLoaded(v24) == 0 then
						task.wait(0.1)
					else
						task.wait(tbl.customBlackGunEquipDelay)
						flag3 = not v22.Parent or not v23.Parent

						if not flag3 then
							if tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
								if tbl.getShotsLoaded(v24) ~= 0 then
									tbl.shootAtTarget(v22, v23, v24)
									task.wait(tbl.customBlackGunCooldown)
								end
							end
						end
					end
				elseif tbl.getShotsLoaded(v24) == 0 then
					task.wait(0.1)
				else
					task.wait(tbl.customBlackGunEquipDelay)
					flag3 = not v22.Parent or not v23.Parent

					if not flag3 then
						if tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
							if tbl.getShotsLoaded(v24) ~= 0 then
								tbl.shootAtTarget(v22, v23, v24)
								task.wait(tbl.customBlackGunCooldown)
							end
						end
					end
				end

				continue
			end

			if exitTo == 5 then
				task.wait(0.3)
				continue
			end

			if exitTo == 6 then
				if tbl.getShotsLoaded(v24) == 0 then
					task.wait(0.1)
				else
					task.wait(tbl.customBlackGunEquipDelay)
					flag3 = not v22.Parent or not v23.Parent

					if not flag3 then
						if tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
							if tbl.getShotsLoaded(v24) ~= 0 then
								tbl.shootAtTarget(v22, v23, v24)
								task.wait(tbl.customBlackGunCooldown)
							end
						end
					end
				end

				continue
			end

			if exitTo == 7 then
				task.wait(0.1)
				continue
			end

			if exitTo == 8 then
				task.wait(0.15)
				continue
			end

			if exitTo == 9 then
				task.wait(0.15)
				continue
			end

			if exitTo == 10 then
				task.wait(0.15)
				continue
			end

			if exitTo == 11 then
				if tbl.getShotsLoaded(v24) == 0 then
					task.wait(0.1)
				else
					task.wait(tbl.customBlackGunEquipDelay)
					flag3 = not v22.Parent or not v23.Parent

					if not flag3 then
						if tbl.hasPlayerNearBomber(v23, tbl.customBlackGunBarrelDistance) then
							if tbl.getShotsLoaded(v24) ~= 0 then
								tbl.shootAtTarget(v22, v23, v24)
								task.wait(tbl.customBlackGunCooldown)
							end
						end
					end
				end

				continue
			end

			if exitTo == 12 then
				task.wait(0.1)
				continue
			end

			if exitTo == 13 then
				task.wait(0.3)
				continue
			end
			break
		end

		tbl.customShootingRunning = false

		if tbl.customShootingThread then
			tbl.customShootingThread = nil
		end
	end

	tbl.startCustomShooting = function()
		if tbl.customShootingThread then
			task.cancel(tbl.customShootingThread)
			tbl.customShootingThread = nil
		end

		tbl.customShootingRunning = false
		tbl.customShootingThread = task.spawn(tbl.customShootingLoop)
	end

	tbl.stopCustomShooting = function()
		tbl.customBlackGunEnabled = false
		tbl.customShootingRunning = false

		if tbl.customShootingThread then
			task.cancel(tbl.customShootingThread)
			tbl.customShootingThread = nil
		end
	end

	tbl.radiusCircle = { enabled = false, visuals = {}, updateConn = nil, zombieAddedDisposer = nil }
	tbl.radiusCircle._lastColorCheck = setmetatable({}, { __mode = "k" })
	local brickColor = BrickColor.new("Bright red")
	local brickColor2 = BrickColor.new("Bright green")

	tbl.radiusCircle.createCircle = function(arg)
		if tbl.radiusCircle.visuals[arg] then
			pcall(tbl.radiusCircle.visuals[arg].Destroy, tbl.radiusCircle.visuals[arg])
			tbl.radiusCircle.visuals[arg] = nil
		end

		if not (arg:FindFirstChild("HumanoidRootPart") or arg:FindFirstChild("Torso")) then
			return nil
		end
		local customBlackGunBarrelDistance = tbl.customBlackGunBarrelDistance or 10
		local part = Instance.new("Part")
		part.Name = "RadiusCircle"
		part.Shape = Enum.PartType.Cylinder
		part.Size = vector(0.3, customBlackGunBarrelDistance * 2, customBlackGunBarrelDistance * 2)
		part.BrickColor = brickColor
		part.Material = Enum.Material.Neon
		part.Transparency = 0.6
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = v19
		return part
	end

	tbl.radiusCircle.updateVisual = function(arg, arg2)
		if not arg2 or not arg or not arg2.Parent then
			return
		end
		local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart") or arg:FindFirstChild("Torso")
		if not humanoidRootPart then
			return
		end
		local position = humanoidRootPart.Position
		arg2.CFrame = cframe(position.X, position.Y - 2.5, position.Z) * CFrame.Angles(0, 0, 1.5707963267948966)
		local customBlackGunBarrelDistance = tbl.customBlackGunBarrelDistance or 10

		if abs(arg2.Size.Y - customBlackGunBarrelDistance * 2) > 0.01 then
			arg2.Size = vector(0.3, customBlackGunBarrelDistance * 2, customBlackGunBarrelDistance * 2)
		end

		local v22 = clock2()
		if v22 - (tbl.radiusCircle._lastColorCheck[arg2] or 0) < 0.1 then
			return
		end
		tbl.radiusCircle._lastColorCheck[arg2] = v22
		local flag = false

		for _, v23 in v4:GetPlayers() do
			if v23 ~= localPlayer then
				local character = v23.Character

				if character then
					local humanoidRootPart2 = character:FindFirstChild("HumanoidRootPart")

					if humanoidRootPart2 then
						if (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude <= customBlackGunBarrelDistance then
							flag = true
							break
						end
					end
				end
			end
		end

		arg2.BrickColor = flag and brickColor2 or brickColor
	end

	tbl.radiusCircle.updateAll = function()
		for k, v22 in tbl.radiusCircle.visuals, nil, nil do
			if k and k.Parent and v22 and v22.Parent then
				tbl.radiusCircle.updateVisual(k, v22)
			else
				if v22 then
					pcall(v22.Destroy, v22)
				end

				tbl.radiusCircle.visuals[k] = nil
			end
		end
	end

	tbl.radiusCircle.addZombie = function(arg)
		if not tbl.radiusCircle.enabled then
			return
		end

		if not arg:IsA("Model") then
			return
		end

		if not (arg:GetAttribute("Type") == "Barrel" or arg:FindFirstChild("Barrel")) then
			return
		end

		if tbl.radiusCircle.visuals[arg] then
			return
		end
		local v22 = tbl.radiusCircle.createCircle(arg)

		if v22 then
			tbl.radiusCircle.visuals[arg] = v22
			tbl.radiusCircle.updateVisual(arg, v22)
		end
	end

	tbl.radiusCircle.onZombieAdded = function(arg)
		if not tbl.radiusCircle.enabled or not arg:IsA("Model") then
			return
		end

		task.spawn(function()
			local barrel = arg:GetAttribute("Type") == "Barrel" or arg:FindFirstChild("Barrel")

			if not barrel and arg.Parent then
				task.wait(0.5)
				barrel = arg.Parent and (arg:GetAttribute("Type") == "Barrel" or arg:FindFirstChild("Barrel"))
			end

			if barrel and arg.Parent then
				tbl.radiusCircle.addZombie(arg)
			end
		end)
	end

	tbl.radiusCircle.start = function()
		if tbl.radiusCircle.updateConn then
			return
		end
		tbl.radiusCircle.enabled = true

		for _, v22 in v19:GetDescendants() do
			if v22.Name == "RadiusCircle" then
				v22:Destroy()
			end
		end

		tbl.radiusCircle.visuals = {}
		tbl.ZombieWatch.start()

		tbl.radiusCircle.zombieAddedDisposer = tbl.ZombieWatch.onAdded(function(arg)
			tbl.radiusCircle.onZombieAdded(arg)
		end)

		tbl.ZombieWatch.forEach(function(arg)
			tbl.radiusCircle.addZombie(arg)
		end)

		tbl.radiusCircle.updateConn = v5.RenderStepped:Connect(function()
			if tbl.radiusCircle.enabled then
				tbl.radiusCircle.updateAll()
			end
		end)
	end

	tbl.radiusCircle.stop = function()
		tbl.radiusCircle.enabled = false

		if tbl.radiusCircle.updateConn then
			tbl.radiusCircle.updateConn:Disconnect()
			tbl.radiusCircle.updateConn = nil
		end

		if tbl.radiusCircle.zombieAddedDisposer then
			tbl.radiusCircle.zombieAddedDisposer()
			tbl.radiusCircle.zombieAddedDisposer = nil
		end

		for _, v22 in tbl.radiusCircle.visuals, nil, nil do
			pcall(v22.Destroy, v22)
		end

		tbl.radiusCircle.visuals = {}
	end

	tbl.radiusCircle.updateRadius = function(customBlackGunBarrelDistance)
		tbl.customBlackGunBarrelDistance = customBlackGunBarrelDistance

		if tbl.radiusCircle.enabled then
			tbl.radiusCircle.updateAll()
		end
	end

	v20:AddToggle("CustomBlackGunToggle", {
		Text = "自动黑枪",
		Default = false,
		Tooltip = fn4("自动射击自爆僵尸"),
		Callback = function(customBlackGunEnabled)
			tbl.customBlackGunEnabled = customBlackGunEnabled

			if customBlackGunEnabled then
				tbl.startCustomShooting()
			else
				tbl.stopCustomShooting()
			end
		end,
	})

	v20:AddToggle("CustomBlackGunNoEquip", {
		Text = "无需装备武器",
		Default = false,
		Tooltip = fn4("开启后直接从背包调用枪械射击，不需要装备到手上"),
		Callback = function(customBlackGunNoEquip)
			tbl.customBlackGunNoEquip = customBlackGunNoEquip
		end,
	})

	v20:AddToggle("CustomBlackGunWallCheck", {
		Text = "墙体检测",
		Default = false,
		Tooltip = fn4("开启后不会射击被墙体遮挡的自爆"),
		Callback = function(customWallCheckEnabled)
			tbl.customWallCheckEnabled = customWallCheckEnabled
		end,
	})

	v20:AddToggle("RadiusCircleToggle", {
		Text = "显示黑枪半径",
		Default = false,
		Tooltip = fn4("显示自爆周围的检测范围圆环"),
		Callback = function(arg)
			if arg then
				tbl.radiusCircle.start()
			else
				tbl.radiusCircle.stop()
			end
		end,
	})

	v20:AddSlider("CustomBlackGunRange", {
		Text = "检测范围",
		Default = 10,
		Min = 1,
		Max = 20,
		Suffix = " 格",
		Tooltip = fn4("检测自爆附近玩家的范围（圆环大小同步变化）"),
		Callback = function(customBlackGunBarrelDistance)
			tbl.customBlackGunBarrelDistance = customBlackGunBarrelDistance
			tbl.radiusCircle.updateRadius(customBlackGunBarrelDistance)
		end,
	})
end

if not tbl.SilentAim then
	tbl.SilentAim = {}
end

do
	local silentAim = tbl.SilentAim
	silentAim.Enabled = false
	silentAim.SilentAimSelectedTypes = {}
	silentAim.SilentAimEnabledTypes = {}
	silentAim.SilentAimZombieTypes = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
	silentAim.SILENT_AIM_USE_FOV = false
	silentAim.SILENT_AIM_SHOW_FOV = false
	silentAim.SILENT_AIM_MOBILE_FOV = false
	silentAim.SILENT_AIM_FOV_SIZE = 50
	silentAim.SilentAimCurrentTarget = nil
	silentAim.SilentAimCurrentModel = nil
	silentAim.SilentAimUpdateConn = nil
	silentAim.oldFire = nil
	silentAim.CHECK_WALLS = true
	silentAim.MAX_TARGET_RANGE = 200
	silentAim.PREDICTION_ENABLED = false
	silentAim.indicatorData = nil
	silentAim.indicatorPart = nil

	for _, v20 in silentAim.SilentAimZombieTypes, nil, nil do
		silentAim.SilentAimEnabledTypes[v20] = false
	end

	local function fn7()
		return tbl.sharedGetCurrentBulletSpeed()
	end

	local function fn8()
		return tbl.sharedGetPing()
	end

	silentAim.isWorldPosInSilentAimFov = function(arg)
		local currentCamera = workspace.CurrentCamera
		if not currentCamera then
			return false
		end
		local v20, v21 = currentCamera:WorldToViewportPoint(arg)
		if not v21 then
			return false
		end
		local v22 = vector2(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y / 2)
		return (vector2(v20.X, v20.Y) - v22).Magnitude <= silentAim.SILENT_AIM_FOV_SIZE
	end

	silentAim.UpdateSilentAimFovCircle = function()
		local currentCamera = workspace.CurrentCamera

		if silentAim.SILENT_AIM_SHOW_FOV and currentCamera and not silentAim.fovCircleDrawing then
			silentAim.fovCircleDrawing = Drawing.new("Circle")
			silentAim.fovCircleDrawing.Thickness = 1.5
			silentAim.fovCircleDrawing.NumSides = 64
			silentAim.fovCircleDrawing.Filled = false
			silentAim.fovCircleDrawing.Color = color(255, 255, 255)
			silentAim.fovCircleDrawing.Visible = true
		elseif (not silentAim.SILENT_AIM_SHOW_FOV or not currentCamera) and silentAim.fovCircleDrawing then
			if silentAim.fovCircleResizeConn then
				silentAim.fovCircleResizeConn:Disconnect()
				silentAim.fovCircleResizeConn = nil
			end

			silentAim.fovCircleDrawing:Remove()
			silentAim.fovCircleDrawing = nil
		end

		if silentAim.fovCircleDrawing and currentCamera then
			silentAim.fovCircleDrawing.Radius = silentAim.SILENT_AIM_FOV_SIZE
			silentAim.fovCircleDrawing.Position = vector2(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y / 2)

			if not silentAim.fovCircleResizeConn then
				silentAim.fovCircleResizeConn = currentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					silentAim.UpdateSilentAimFovCircle()
				end)
			end
		end
	end

	local function fn9(arg)
		if not arg or not arg:IsA("Model") then
			return nil
		end
		local parent = arg.Parent
		if parent and parent.Name == "Slim" and parent.Parent and parent.Parent.Name == "Zombies" then
			return "Cuirassier"
		end
		local agent = arg:FindFirstChild("Agent")

		if agent then
			local type_ = agent:FindFirstChild("Type")

			if type_ and type_:IsA("StringValue") then
				local v20 = string.lower(type_.Value or "")
				if v20 == "normal" then
					return "Shambler"
				end

				if v20 == "barrel" then
					return "Bomber"
				end

				if v20 == "fast" then
					return "Runner"
				end

				if v20 == "sapper" then
					return "Zapper"
				end

				if v20 == "igniter" then
					return "Igniter"
				end

				if v20 == "cuirassier" then
					return "Cuirassier"
				end
			end
		end

		if typeof(arg.GetAttribute) == "function" then
			local attribute = arg:GetAttribute("Type")

			if type(attribute) == "string" then
				local v20 = string.lower(attribute)
				if v20 == "normal" then
					return "Shambler"
				end

				if v20 == "barrel" then
					return "Bomber"
				end

				if v20 == "fast" then
					return "Runner"
				end

				if v20 == "sapper" then
					return "Zapper"
				end

				if v20 == "igniter" then
					return "Igniter"
				end

				if v20 == "cuirassier" then
					return "Cuirassier"
				end
			end
		end

		if arg:FindFirstChild("Barrel", true) then
			return "Bomber"
		end

		if arg:FindFirstChild("Whale Oil Lantern", true) then
			return "Igniter"
		end

		if arg:FindFirstChild("Sword", true) then
			return "Cuirassier"
		end

		if arg:FindFirstChild("Axe", true) and arg:FindFirstChild("Head", true) then
			return "Zapper"
		end

		if arg:FindFirstChild("Eye", true) and not arg:FindFirstChild("Axe", true) then
			return "Runner"
		end
		return "Shambler"
	end

	local function fn10()
		if localPlayer.Character and localPlayer.Character.Parent then
			local head = localPlayer.Character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				return head.Position
			end
		end

		local currentCamera = workspace.CurrentCamera
		return currentCamera and currentCamera.CFrame.Position or nil
	end

	local function fn11()
		local tbl5 = {}

		for _, v20 in v4:GetPlayers() do
			local character = v20.Character

			if character and character:IsA("Model") then
				table.insert(tbl5, character)
			end
		end

		local camera = workspace:FindFirstChild("Camera")

		if camera then
			for _, v20 in camera:GetDescendants() do
				if v20 and v20:IsA("Model") and v20.Name == "m_Zombie" then
					table.insert(tbl5, v20)
				end
			end
		end

		return tbl5
	end

	local n = 0.95
	local n2 = 0.35
	local n3 = 0.4
	local n4 = 2.75
	local n5 = 0.6
	local n6 = 0.0001

	local function fn12(arg, arg2)
		if not arg or not arg.Parent then
			return {}
		end
		arg2 = arg2 or arg.Position
		local cFrame = arg.CFrame
		local size = arg.Size or Vector3.one

		local function fn13(arg3)
			local n7 = arg3 * n2

			if n7 < n3 then
				n7 = 0.4
			end

			if n4 < n7 then
				n7 = 2.75
			end

			return n7
		end

		local v20 = fn13(size.X)
		local v21 = fn13(size.Y)
		local v22 = fn13(size.Z)
		local tbl5 = {}
		local v23 = vector(0, v21, 0)
		local v24 = vector(0, -v21, 0)
		local v25 = vector(v20, 0, 0)
		local v26 = vector(-v20, 0, 0)
		local v27 = vector(0, 0, v22)
		tbl5[1] = Vector3.zero
		tbl5[2] = v23
		tbl5[3] = v24
		tbl5[4] = v25
		tbl5[5] = v26
		tbl5[6] = v27

		do
			local values = table.pack(vector(0, 0, -v22))
			table.move(values, 1, values.n, 7, tbl5)
		end

		local tbl6 = {}

		for _, v28 in tbl5, nil, nil do
			tbl6[#tbl6 + 1] = arg2 + cFrame:VectorToWorldSpace(v28)
		end

		return tbl6
	end

	local function fn13(arg, arg2, arg3, arg4)
		if not silentAim.CHECK_WALLS then
			return false
		end

		if not arg2 then
			return false
		end

		if localPlayer.Character then
			local head = localPlayer.Character:FindFirstChild("Head")

			if head and head:IsA("BasePart") then
				arg = head.Position
			end
		end

		if not arg then
			return false
		end
		local n7 = arg2 - arg
		local magnitude = n7.Magnitude
		if magnitude <= 0 then
			return false
		end
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local filterDescendantsInstances = {}

		if arg4 then
			for i = 1, #arg4 do
				filterDescendantsInstances[#filterDescendantsInstances + 1] = arg4[i]
			end
		end

		if localPlayer.Character then
			table.insert(filterDescendantsInstances, localPlayer.Character)
		end

		raycastParams.FilterDescendantsInstances = filterDescendantsInstances
		local magnitude2 = magnitude
		local v20 = arg
		local unit = n7.Unit

		for i = 1, 16 do
			local ok, result = pcall(function()
				return workspace:Raycast(v20, unit * magnitude2, raycastParams)
			end)

			if not ok or not result then
				return false
			end
			local instance = result.Instance
			if not instance then
				return false
			end

			if arg3 and instance:IsDescendantOf(arg3) then
				return false
			end
			local isBasePart = instance:IsA("BasePart")
			isBasePart = isBasePart and (not (isBasePart and instance.CanCollide) or (isBasePart and instance.Transparency or 0) >= n)
			local flag = false
			local parent

			if isBasePart then
				flag = true
				parent = instance
			else
				parent = instance
			end

			while true do
				if parent and parent.Parent then
					if parent:IsA("Model") and parent.Name == "m_Zombie" then
						flag = true
						break
					else
						parent = parent.Parent
						continue
					end
				end

				break
			end

			for _, v21 in v4:GetPlayers() do
				local character = v21.Character
				if character and instance:IsDescendantOf(character) then
					flag = true
					break
				end
			end

			if flag then
				table.insert(raycastParams.FilterDescendantsInstances, instance)
				local n8 = result.Position + unit * 0.25
				if magnitude - n6 <= (n8 - arg).Magnitude then
					return false
				end
				v20 = n8
				magnitude2 = (arg2 - v20).Magnitude
				continue
			end

			return true
		end

		return true
	end

	local function fn14(arg, arg2, arg3, arg4, arg5)
		if not silentAim.CHECK_WALLS then
			return true
		end

		if not arg or not arg2 or not arg2.Parent then
			return false
		end
		local v20 = fn12(arg2, arg5)
		if #v20 == 0 then
			return false
		end
		local v21 = max(1, ceil(#v20 * n5))
		local n7 = 0

		for _, v22 in v20, nil, nil do
			if not fn13(arg, v22, arg3, arg4) then
				n7 += 1
				if v21 <= n7 then
					return true
				end
			end
		end

		return false
	end

	local function fn15(arg)
		if not arg then
			return false
		end
		local state = arg:FindFirstChild("State")
		if state and state:IsA("StringValue") and state.Value == "Spawn" then
			return true
		end
		local agent = arg:FindFirstChild("Agent")

		if agent then
			local state2 = agent:FindFirstChild("State")
			if state2 and state2:IsA("StringValue") and state2.Value == "Spawn" then
				return true
			end
		end

		return false
	end

	local function fn16(arg)
		if not arg or not arg.Parent then
			return nil
		end
		local head = arg:FindFirstChild("Head", true)
		if head then
			return head
		end
		local torso = arg:FindFirstChild("Torso") or arg:FindFirstChild("UpperTorso") or arg:FindFirstChild("HumanoidRootPart")
		if torso then
			return torso
		end
		local barrel = arg:FindFirstChild("Barrel", true)
		if barrel then
			return barrel
		end
		return arg.PrimaryPart
	end

	local function fn17(arg)
		if not arg or not arg.Parent then
			return nil
		end
		return arg.Position
	end

	silentAim.updateIndicator = function(position, hasTarget)
		if not position then
			if silentAim.indicatorData then
				if silentAim.indicatorData.billboard then
					silentAim.indicatorData.billboard:Destroy()
				end

				silentAim.indicatorData = nil
			end

			if silentAim.indicatorPart then
				silentAim.indicatorPart:Destroy()
				silentAim.indicatorPart = nil
			end

			return
		end

		if not silentAim.indicatorPart or not silentAim.indicatorPart.Parent then
			silentAim.indicatorPart = Instance.new("Part")
			silentAim.indicatorPart.Name = "SilentAimIndicatorAnchor"
			silentAim.indicatorPart.Size = Vector3.new(0.2, 0.2, 0.2)
			silentAim.indicatorPart.Transparency = 1
			silentAim.indicatorPart.CanCollide = false
			silentAim.indicatorPart.Anchored = true
			silentAim.indicatorPart.Parent = workspace
		end

		silentAim.indicatorPart.Position = position

		if not silentAim.indicatorData or not silentAim.indicatorData.billboard or not silentAim.indicatorData.billboard.Parent then
			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Size = UDim2.new(0, 25, 0, 25)
			billboardGui.StudsOffset = Vector3.zero
			billboardGui.AlwaysOnTop = true
			billboardGui.Adornee = silentAim.indicatorPart
			billboardGui.Parent = silentAim.indicatorPart
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundTransparency = 1
			frame.Parent = billboardGui
			local frame2 = Instance.new("Frame")
			frame2.Size = UDim2.new(1, 0, 1, 0)
			frame2.BackgroundTransparency = 1
			frame2.Parent = frame
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Thickness = 1
			uiStroke.Color = color(255, 255, 255)
			uiStroke.Transparency = 0.2
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Parent = frame2
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = frame2
			local frame3 = Instance.new("Frame")
			frame3.Size = UDim2.new(0.65, 0, 0.65, 0)
			frame3.Position = UDim2.new(0.175, 0, 0.175, 0)
			frame3.BackgroundTransparency = 1
			frame3.Parent = frame
			local uiStroke2 = Instance.new("UIStroke")
			uiStroke2.Thickness = 0.7
			uiStroke2.Color = color(255, 255, 255)
			uiStroke2.Transparency = 0.35
			uiStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke2.Parent = frame3
			local uiCorner2 = Instance.new("UICorner")
			uiCorner2.CornerRadius = UDim.new(1, 0)
			uiCorner2.Parent = frame3

			silentAim.indicatorData = {
				billboard = billboardGui,
				container = frame,
				outer = frame2,
				outerStroke = uiStroke,
				inner = frame3,
				innerStroke = uiStroke2,
				hasTarget = false,
			}

			task.spawn(function()
				while silentAim.indicatorData and silentAim.indicatorData.billboard and silentAim.indicatorData.billboard.Parent do
					local hasTarget2 = silentAim.indicatorData.hasTarget
					local transparency = (math.sin(clock() * 4) + 1) / 2 * 0.2 + 0.15
					local transparency2 = (math.sin(clock() * 4 + 0.5) + 1) / 2 * 0.25 + 0.2

					if hasTarget2 then
						local v20 = color(0, floor((0.7 + (math.sin(clock() * 2) + 1) / 2 * 0.3) * 255), 80)

						if silentAim.indicatorData.outerStroke then
							silentAim.indicatorData.outerStroke.Color = v20
							silentAim.indicatorData.outerStroke.Transparency = transparency
						end

						if silentAim.indicatorData.innerStroke then
							silentAim.indicatorData.innerStroke.Color = v20
							silentAim.indicatorData.innerStroke.Transparency = transparency2
						end
					else
						local v20 = color(255, 255, 255)

						if silentAim.indicatorData.outerStroke then
							silentAim.indicatorData.outerStroke.Color = v20
							silentAim.indicatorData.outerStroke.Transparency = transparency
						end

						if silentAim.indicatorData.innerStroke then
							silentAim.indicatorData.innerStroke.Color = v20
							silentAim.indicatorData.innerStroke.Transparency = transparency2
						end
					end

					task.wait(0.02)
				end
			end)
		else
			if silentAim.indicatorData.billboard.Adornee ~= silentAim.indicatorPart then
				silentAim.indicatorData.billboard.Adornee = silentAim.indicatorPart
			end

			silentAim.indicatorData.hasTarget = hasTarget
		end
	end

	silentAim.hideIndicator = function()
		if silentAim.indicatorData then
			if silentAim.indicatorData.billboard then
				silentAim.indicatorData.billboard:Destroy()
			end

			silentAim.indicatorData = nil
		end

		if silentAim.indicatorPart then
			silentAim.indicatorPart:Destroy()
			silentAim.indicatorPart = nil
		end
	end

	silentAim.StartSilentAimLoop = function()
		if silentAim.SilentAimUpdateConn then
			return
		end

		silentAim.SilentAimUpdateConn = v5.Heartbeat:Connect(function()
			if not (silentAim.Enabled and #silentAim.SilentAimSelectedTypes > 0) then
				silentAim.SilentAimCurrentTarget = nil
				silentAim.SilentAimCurrentModel = nil
				silentAim.hideIndicator()
				return
			end

			local tool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")

			if tool then
				local animations = tool:FindFirstChild("Animations")

				if animations then
					tool = tool.Animations:FindFirstChild("Aim") or tool.Animations:FindFirstChild("Aiming")
				else
					tool = animations
				end
			end

			if not tool then
				silentAim.SilentAimCurrentTarget = nil
				silentAim.SilentAimCurrentModel = nil
				silentAim.hideIndicator()
				return
			end

			if silentAim.SilentAimSelectedTypes and #silentAim.SilentAimSelectedTypes > 0 then
				local maxTargetRange = silentAim.MAX_TARGET_RANGE
				local v20 = fn10()
				if not v20 then
					return
				end
				local v21 = fn11()
				local n7 = maxTargetRange + 1
				local tbl5 = {}

				for _, v22 in silentAim.SilentAimSelectedTypes, nil, nil do
					tbl5[v22] = true
				end

				local zombies = workspace:FindFirstChild("Zombies")
				local v22 = nil
				local n8 = nil
				local v23 = nil

				if zombies then
					v22 = nil
					v23 = nil
					n8 = nil

					for _, v24 in zombies:GetChildren() do
						if v24:IsA("Model") and not fn15(v24) then
							local v25 = fn9(v24)

							if v25 and tbl5[v25] then
								local v26 = fn16(v24)

								if v26 and v26:IsA("BasePart") then
									local v27 = fn17(v26)

									if silentAim.SILENT_AIM_USE_FOV then
										if not silentAim.isWorldPosInSilentAimFov(v27) then
											continue
										end
									end

									local magnitude = (v27 - v20).Magnitude

									if magnitude < n7 and magnitude <= maxTargetRange then
										if silentAim.CHECK_WALLS then
											if not fn14(v20, v26, v24, v21) then
												continue
											end
										end

										if silentAim.PREDICTION_ENABLED then
											local n9 = magnitude / fn7() + fn8() / 1000
											local humanoidRootPart = v24:FindFirstChild("HumanoidRootPart")

											if humanoidRootPart then
												local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity

												if not (assemblyLinearVelocity.Magnitude > 0.05) then
													n7 = magnitude
													v22 = v26
													v23 = v24
													n8 = v27
												else
													local v28 = (v27 - v20).Unit:Dot(assemblyLinearVelocity.Unit)
													local n10 = 1 - abs(v28) * 0.5
													local n11 = assemblyLinearVelocity * n9 * (0.2 + 0.8 * min(1.2, magnitude / 60)) * 1.2 * n10
													local v29 = min(magnitude * 0.15 + 2, 35)

													if v29 < n11.Magnitude then
														n11 = n11.Unit * v29
													end

													n8 = v27 + n11
													n7 = magnitude
													v22 = v26
													v23 = v24
												end
											else
												n7 = magnitude
												v22 = v26
												v23 = v24
												n8 = v27
											end
										else
											n7 = magnitude
											v22 = v26
											v23 = v24
											n8 = v27
										end
									end
								end
							end
						end
					end
				end

				if tbl.silentAim.headless then
					for _, v24 in workspace:GetDescendants() do
						if v24:IsA("Model") and tbl.isHeadlessModel(v24) then
							local humanoid = v24:FindFirstChildOfClass("Humanoid")

							if humanoid and humanoid.Health > 0 then
								local torso = v24:FindFirstChild("Torso") or v24:FindFirstChild("UpperTorso") or v24:FindFirstChild("HumanoidRootPart")

								if torso and torso:IsA("BasePart") then
									local n9

									if torso.Name == "HumanoidRootPart" then
										n9 = torso.Position + Vector3.new(0, 2.5, 0)
									else
										n9 = torso.Position
									end

									if silentAim.SILENT_AIM_USE_FOV then
										if not silentAim.isWorldPosInSilentAimFov(n9) then
											continue
										end
									end

									local magnitude = (n9 - v20).Magnitude

									if magnitude < n7 and magnitude <= maxTargetRange then
										if silentAim.CHECK_WALLS then
											if not fn14(v20, torso, v24, v21, n9) then
												continue
											end
										end

										if silentAim.PREDICTION_ENABLED then
											local n10 = magnitude / fn7() + fn8() / 1000
											local humanoidRootPart = v24:FindFirstChild("HumanoidRootPart")

											if humanoidRootPart then
												local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity

												if assemblyLinearVelocity.Magnitude > 0.05 then
													local v25 = (n9 - v20).Unit:Dot(assemblyLinearVelocity.Unit)
													local n11 = 1 - abs(v25) * 0.5
													local n12 = assemblyLinearVelocity * n10 * (0.2 + 0.8 * min(1.2, magnitude / 60)) * 1.2 * n11
													local v26 = min(magnitude * 0.15 + 2, 35)

													if v26 < n12.Magnitude then
														n12 = n12.Unit * v26
													end

													n8 = n9 + n12
													n7 = magnitude
													v22 = torso
													v23 = v24
												else
													n7 = magnitude
													v22 = torso
													v23 = v24
													n8 = n9
												end
											else
												n7 = magnitude
												v22 = torso
												v23 = v24
												n8 = n9
											end
										else
											n7 = magnitude
											v22 = torso
											v23 = v24
											n8 = n9
										end
									end
								end
							end
						end
					end
				end

				if v22 then
					if silentAim.PREDICTION_ENABLED and n8 then
						silentAim.SilentAimCurrentTarget = { Position = n8, Parent = v22.Parent or nil, IsPredicted = true }
					else
						silentAim.SilentAimCurrentTarget = v22
					end

					silentAim.SilentAimCurrentModel = v23
					silentAim.updateIndicator(silentAim.PREDICTION_ENABLED and n8 or v22.Position, true)
				else
					silentAim.SilentAimCurrentTarget = nil
					silentAim.SilentAimCurrentModel = nil
					silentAim.hideIndicator()
				end
			end
		end)
	end

	silentAim.StopSilentAimLoop = function()
		if silentAim.SilentAimUpdateConn then
			silentAim.SilentAimUpdateConn:Disconnect()
			silentAim.SilentAimUpdateConn = nil
		end

		silentAim.SilentAimCurrentTarget = nil
		silentAim.SilentAimCurrentModel = nil
		silentAim.hideIndicator()
	end

	silentAim.SetupSilentAimHooks = function()
		if silentAim.oldFire then
			return
		end

		if type(hookmetamethod) ~= "function" then
			warn("Silent Aim: hookmetamethod not available")
			return
		end

		silentAim.oldFire = hookmetamethod(game, "__namecall", function(arg, ...)
			local v20 = table.pack(...)

			if getnamecallmethod() == "FireServer" and silentAim.Enabled then
				local tbl5 = { ... }

				if tbl5[1] == "Fire" and silentAim.SilentAimCurrentTarget then
					local character = localPlayer.Character

					if character then
						local position

						if type(silentAim.SilentAimCurrentTarget) == "table" and silentAim.SilentAimCurrentTarget.IsPredicted then
							position = silentAim.SilentAimCurrentTarget.Position
						else
							if not silentAim.SilentAimCurrentTarget.Parent then
								return silentAim.oldFire(arg, table.unpack(v20, 1, v20.n))
							end
							position = silentAim.SilentAimCurrentTarget.Position
						end

						return silentAim.oldFire(arg, unpack({
							"Fire",
							tbl5[2] or character:FindFirstChild("Model") or character,
							position,
							tbl5[4] or workspace:GetServerTimeNow(),
						}))
					end
				end

				return silentAim.oldFire(arg, table.unpack(v20, 1, v20.n))
			end

			return silentAim.oldFire(arg, ...)
		end)
	end

	silentAim.RemoveSilentAimHooks = function()
		if silentAim.oldFire then
			hookmetamethod(game, "__namecall", silentAim.oldFire)
			silentAim.oldFire = nil
		end
	end

	tbl.onCharacterAdded(function()
		if silentAim.Enabled then
			silentAim.RemoveSilentAimHooks()
			task.wait(0.1)
			silentAim.SetupSilentAimHooks()
		end
	end)

	tbl.silentAim = tbl.silentAim or {}
	tbl.silentAim.bomber = false
	tbl.silentAim.cuirassier = false
	tbl.silentAim.runner = false
	tbl.silentAim.zapper = false
	tbl.silentAim.igniter = false
	tbl.silentAim.shambler = false
	tbl.silentAim.headless = false

	local function fn18()
		local silentAimSelectedTypes = {}

		if tbl.silentAim.bomber then
			table.insert(silentAimSelectedTypes, "Bomber")
		end

		if tbl.silentAim.cuirassier then
			table.insert(silentAimSelectedTypes, "Cuirassier")
		end

		if tbl.silentAim.runner then
			table.insert(silentAimSelectedTypes, "Runner")
		end

		if tbl.silentAim.zapper then
			table.insert(silentAimSelectedTypes, "Zapper")
		end

		if tbl.silentAim.igniter then
			table.insert(silentAimSelectedTypes, "Igniter")
		end

		if tbl.silentAim.shambler then
			table.insert(silentAimSelectedTypes, "Shambler")
		end

		if tbl.silentAim.headless then
			table.insert(silentAimSelectedTypes, "Headless")
		end

		silentAim.SilentAimSelectedTypes = silentAimSelectedTypes

		if #silentAimSelectedTypes > 0 then
			silentAim.Enabled = true
			silentAim.StartSilentAimLoop()
			silentAim.SetupSilentAimHooks()
		else
			silentAim.Enabled = false
			silentAim.StopSilentAimLoop()
			silentAim.RemoveSilentAimHooks()
		end
	end

	local v20 = tbl3.Main:AddGroupbox({ Side = "Left", Name = "静默自瞄", IconName = "target", Description = "自动瞄准" })
	v20:AddLabel("目标选择")

	v20:AddToggle("SilentAimBomber", {
		Text = "自瞄自爆",
		Default = false,
		Tooltip = fn4("开启后自瞄自爆僵尸"),
		Callback = function(bomber)
			tbl.silentAim.bomber = bomber
			fn18()
		end,
	})

	v20:AddToggle("SilentAimCuirassier", {
		Text = "自瞄胸甲骑兵",
		Default = false,
		Tooltip = fn4("开启后自瞄胸甲骑兵"),
		Callback = function(cuirassier)
			tbl.silentAim.cuirassier = cuirassier
			fn18()
		end,
	})

	v20:AddToggle("SilentAimRunner", {
		Text = "自瞄红眼",
		Default = false,
		Tooltip = fn4("开启后自瞄红眼僵尸"),
		Callback = function(runner)
			tbl.silentAim.runner = runner
			fn18()
		end,
	})

	v20:AddToggle("SilentAimZapper", {
		Text = "自瞄斧头僵尸",
		Default = false,
		Tooltip = fn4("开启后自瞄斧头僵尸"),
		Callback = function(zapper)
			tbl.silentAim.zapper = zapper
			fn18()
		end,
	})

	v20:AddToggle("SilentAimIgniter", {
		Text = "自瞄点火者",
		Default = false,
		Tooltip = fn4("开启后自瞄点火者"),
		Callback = function(igniter)
			tbl.silentAim.igniter = igniter
			fn18()
		end,
	})

	v20:AddToggle("SilentAimShambler", {
		Text = "自瞄普通僵尸",
		Default = false,
		Tooltip = fn4("开启后自瞄普通僵尸"),
		Callback = function(shambler)
			tbl.silentAim.shambler = shambler
			fn18()
		end,
	})

	v20:AddToggle("SilentAimHeadless", {
		Text = "自瞄无头骑士",
		Default = false,
		Callback = function(headless)
			tbl.silentAim.headless = headless

			if not headless then
				silentAim.hideIndicator()
			end

			fn18()
		end,
	})

	v20:AddDivider()
	v20:AddLabel("攻击设置")

	v20:AddToggle("SilentAimWallCheck", {
		Text = "墙体检测",
		Default = true,
		Tooltip = fn4("开启后不会瞄准被墙体遮挡的僵尸"),
		Callback = function(checkWalls)
			silentAim.CHECK_WALLS = checkWalls
		end,
	})

	tbl.noRecoilEnabled = false
	tbl.disabledRecoilConnections = nil

	tbl.toggleNoRecoil = function(arg)
		if arg then
			if not tbl.disabledRecoilConnections then
				local recoilEvent = v7:FindFirstChild("RecoilEvent")
				if not recoilEvent then
					warn("请等待复活")
					return
				end

				if type(getconnections) ~= "function" then
					return
				end
				local disabledRecoilConnections = {}

				if not pcall(function()
					for _, v21 in getconnections(recoilEvent.Event) do
						v21:Disable()
						table.insert(disabledRecoilConnections, v21)
					end
				end) or #disabledRecoilConnections == 0 then
					return
				end

				tbl.disabledRecoilConnections = disabledRecoilConnections
				tbl.noRecoilEnabled = true
			end
		else
			tbl.noRecoilEnabled = false

			if tbl.disabledRecoilConnections then
				for _, v21 in tbl.disabledRecoilConnections, nil, nil do
					pcall(function()
						v21:Enable()
					end)
				end

				tbl.disabledRecoilConnections = nil
			end
		end
	end

	tbl.onCharacterAdded(function()
		if tbl.noRecoilEnabled and tbl.disabledRecoilConnections then
			local recoilEvent = v7:FindFirstChild("RecoilEvent")

			if recoilEvent then
				for _, v21 in getconnections(recoilEvent.Event) do
					if v21.Enabled then
						v21:Disable()
						table.insert(tbl.disabledRecoilConnections, v21)
					end
				end
			end
		end
	end)

	v20:AddToggle("NoRecoilToggle", {
		Text = "无后坐力",
		Default = false,
		Tooltip = fn4("禁用枪械后坐力"),
		Callback = function(arg)
			tbl.toggleNoRecoil(arg)
		end,
	})

	v20:AddToggle("SilentAimPrediction", {
		Text = "预判射击",
		Default = false,
		Callback = function(predictionEnabled)
			silentAim.PREDICTION_ENABLED = predictionEnabled
		end,
	})

	v20:AddSlider("SilentAimRange", {
		Text = "瞄准距离",
		Default = 200,
		Min = 50,
		Max = 600,
		Rounding = 0,
		Callback = function(maxTargetRange)
			silentAim.MAX_TARGET_RANGE = maxTargetRange
		end,
	})

	v20:AddDivider()
	v20:AddLabel("FOV 设置")

	v20:AddToggle("SilentAimFOVToggle", {
		Text = "启用 FOV",
		Default = false,
		Tooltip = fn4("只在 FOV 范围内自瞄"),
		Callback = function(silentAimUseFov)
			silentAim.SILENT_AIM_USE_FOV = silentAimUseFov
			silentAim.UpdateSilentAimFovCircle()
		end,
	})

	v20:AddToggle("SilentAimShowFOV", {
		Text = "显示 FOV 圆圈",
		Default = false,
		Tooltip = fn4("显示自瞄 FOV 范围"),
		Callback = function(silentAimShowFov)
			silentAim.SILENT_AIM_SHOW_FOV = silentAimShowFov
			silentAim.UpdateSilentAimFovCircle()
		end,
	})

	v20:AddSlider("SilentAimFOVSize", {
		Text = "FOV 大小",
		Default = 50,
		Min = 10,
		Max = 120,
		Rounding = 0,
		Callback = function(silentAimFovSize)
			silentAim.SILENT_AIM_FOV_SIZE = silentAimFovSize
			silentAim.UpdateSilentAimFovCircle()
		end,
	})

	fn18()
end

tbl.engineerAutoRepairEnabled = false
tbl.autoRepairLoop = nil
tbl.repairCooldown = 0.05
tbl.autoRepairTargetMode = "Closest"
tbl.autoRepairRange = 25

do
	local remoteEvent = nil
	local n = 0
	local n2 = 2
	local v20 = nil
	local n3 = 0
	local n4 = 10

	tbl.getLookedStructure = function()
		local character = localPlayer.Character
		if not character then
			return nil
		end

		if not character:FindFirstChild("HumanoidRootPart") then
			return nil
		end
		local currentCamera = workspace.CurrentCamera
		local position = currentCamera.CFrame.Position
		local n5 = currentCamera.CFrame.LookVector * 50
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { character }
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(position, n5, raycastParams)
		if not hit then
			return nil
		end
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		if not model then
			return nil
		end
		return model:FindFirstChild("BuildingHealth") or model.Parent and model.Parent:FindFirstChild("BuildingHealth")
	end

	tbl.getHammerRemote = function()
		local now = time()

		if remoteEvent and now - n < n2 then
			if remoteEvent.Parent then
				return remoteEvent
			end
			remoteEvent = nil
		end

		local v21 = localPlayer
		local backpack = localPlayer:FindFirstChild("Backpack")

		if backpack then
			local hammer = backpack:FindFirstChild("Hammer") or backpack:FindFirstChild("Claw Hammer")

			if hammer and hammer:FindFirstChild("RemoteEvent") then
				remoteEvent = hammer.RemoteEvent
				n = now
				return remoteEvent
			end
		end

		local character = v21.Character

		if character then
			local hammer = character:FindFirstChild("Hammer") or character:FindFirstChild("Claw Hammer")

			if hammer and hammer:FindFirstChild("RemoteEvent") then
				remoteEvent = hammer.RemoteEvent
				n = now
				return remoteEvent
			end
		end

		local players = workspace:FindFirstChild("Players")

		if players then
			local v22 = players:FindFirstChild(v21.Name)

			if v22 then
				local hammer = v22:FindFirstChild("Hammer") or v22:FindFirstChild("Claw Hammer")

				if hammer then
					local remoteEvent2 = hammer:FindFirstChild("RemoteEvent")

					if remoteEvent2 then
						remoteEvent = remoteEvent2
						n = now
						return remoteEvent2
					end
				end
			end
		end

		return nil
	end

	tbl.getBuildableFolders = function()
		local now = time()
		if v20 and now - n3 < n4 then
			return v20
		end
		local tbl5 = {}

		for _, v21 in { "Buildables", "Stakes", "Barricades", "Structures", "Buildings" }, nil, nil do
			local v22 = workspace:FindFirstChild(v21)

			if v22 then
				tbl5[#tbl5 + 1] = v22
			end
		end

		for _, v21 in workspace:GetChildren() do
			if v21:IsA("Folder") or v21:IsA("Model") then
				local modes = v21:FindFirstChild("Modes")

				if modes then
					tbl5[#tbl5 + 1] = modes
				end
			end
		end

		v20 = tbl5
		n3 = now
		return tbl5
	end
end

do
	local tbl5 = {}
	local tbl6 = {}
	local n = 0
	local n2 = 40

	tbl.getRichBuildables = function()
		local character = localPlayer.Character
		if not character then
			return tbl5, 0
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return tbl5, 0
		end
		local position = humanoidRootPart.Position
		local n3 = tbl.autoRepairRange * tbl.autoRepairRange
		n = 0

		for k in tbl6, nil, nil do
			tbl6[k] = nil
		end

		local function fn7(arg)
			if n2 <= n then
				return
			end
			local position2

			if arg:IsA("BasePart") then
				position2 = arg.Position
			else
				position2 = nil

				if arg:IsA("Model") then
					local primaryPart = arg.PrimaryPart or arg:FindFirstChildWhichIsA("BasePart")
					position2 = nil

					if primaryPart then
						position2 = primaryPart.Position
					end
				end
			end

			if not position2 then
				return
			end
			local n4 = position2.X - position.X
			local n5 = position2.Y - position.Y
			local n6 = position2.Z - position.Z
			local dist = n4 * n4 + n5 * n5 + n6 * n6
			if n3 < dist then
				return
			end
			local buildingHealth = arg:FindFirstChild("BuildingHealth") or arg:FindFirstChild("ConstructHealth")

			if not buildingHealth then
				local health = arg:FindFirstChild("Health")

				if health and health:IsA("NumberValue") then
					buildingHealth = health
				end
			end

			if not buildingHealth or tbl6[buildingHealth] then
				return
			end
			tbl6[buildingHealth] = true
			local cur = buildingHealth.Value
			if not cur then
				return
			end
			local attribute = buildingHealth:GetAttribute("MaxHealth") or buildingHealth:GetAttribute("Max") or 100
			if attribute == 0 then
				return
			end

			if cur >= attribute then
				return
			end
			n += 1
			local v20 = tbl5[n]

			if v20 then
				v20.obj = buildingHealth
				v20.cur = cur
				v20.max = attribute
				v20.ratio = cur / attribute
				v20.dist = dist
			else
				tbl5[n] = { obj = buildingHealth, cur = cur, max = attribute, ratio = cur / attribute, dist = dist }
			end
		end

		for _, v20 in tbl.getBuildableFolders(), nil, nil do
			if not (n2 <= n) then
				for _, v21 in v20:GetChildren() do
					if not (n >= n2) then
						fn7(v21)

						if v21:IsA("Model") or v21:IsA("Folder") then
							for _, v22 in v21:GetChildren() do
								if not (n2 <= n) then
									fn7(v22)
									continue
								end
								break
							end
						end

						continue
					end

					break
				end

				continue
			end

			break
		end

		for i = n + 1, #tbl5 do
			tbl5[i] = nil
		end

		return tbl5, n
	end
end

tbl.fireRepairSilent = function(arg)
	if not arg then
		return
	end
	local v20 = tbl.getHammerRemote()
	if not v20 then
		return
	end

	pcall(function()
		v20:FireServer("Repair", arg)
	end)
end

tbl.doAutoRepair = function()
	if tbl.autoRepairTargetMode == "Aimed" then
		local v20 = tbl.getLookedStructure()

		if v20 then
			local value = v20.Value
			local attribute = v20:GetAttribute("MaxHealth")

			if attribute and value < attribute then
				tbl.fireRepairSilent(v20)
			end
		end

		return
	end

	if tbl.autoRepairTargetMode == "None" then
		return
	end
	local v20, v21 = tbl.getRichBuildables()
	if v21 == 0 then
		return
	end
	local obj

	if tbl.autoRepairTargetMode == "Closest" then
		local dist = v20[1].dist
		obj = v20[1].obj

		for i = 2, v21 do
			if v20[i].dist < dist then
				dist = v20[i].dist
				obj = v20[i].obj
			end
		end
	else
		obj = nil

		if tbl.autoRepairTargetMode == "LowestHealth" then
			local ratio = v20[1].ratio
			local cur = v20[1].cur
			obj = v20[1].obj

			for i = 2, v21 do
				local v22 = v20[i]

				if v22.ratio < ratio or v22.ratio == ratio and v22.cur < cur then
					ratio = v22.ratio
					cur = v22.cur
					obj = v22.obj
				end
			end
		end
	end

	if obj then
		tbl.fireRepairSilent(obj)
	end
end

tbl.autoRepairLoopFunc = function()
	while tbl.engineerAutoRepairEnabled do
		tbl.doAutoRepair()
		task.wait(tbl.repairCooldown)
	end
end

tbl.toggleEngineerAutoRepair = function(engineerAutoRepairEnabled)
	tbl.engineerAutoRepairEnabled = engineerAutoRepairEnabled

	if engineerAutoRepairEnabled then
		if tbl.autoRepairLoop then
			task.cancel(tbl.autoRepairLoop)
		end

		tbl.autoRepairLoop = task.spawn(tbl.autoRepairLoopFunc)
		tbl.notify(fn3("自动修复已开启（静默模式）"), 2)
	else
		if tbl.autoRepairLoop then
			task.cancel(tbl.autoRepairLoop)
			tbl.autoRepairLoop = nil
		end

		tbl.notify(fn3("自动修复已关闭"), 2)
	end
end

v18:AddToggle("AutoRepairToggle", {
	Text = "静默自动修建筑",
	Default = false,
	Tooltip = fn4("自动修复瞄准的建筑（无需装备锤子）"),
	Callback = function(arg)
		tbl.toggleEngineerAutoRepair(arg)
	end,
})

v18:AddDropdown("AutoRepairMode", {
	Text = "修复目标模式",
	Values = { "瞄准建筑", "最近建筑", "最低生命值建筑" },
	Value = "最近建筑",
	FormatDisplayValue = function(arg)
		return str == "English" and (tbl2[arg] or arg) or arg
	end,
	Callback = function(arg)
		if arg == "瞄准建筑" then
			tbl.autoRepairTargetMode = "Aimed"
		elseif arg == "最近建筑" then
			tbl.autoRepairTargetMode = "Closest"
		elseif arg == "最低生命值建筑" then
			tbl.autoRepairTargetMode = "LowestHealth"
		end
	end,
})

tbl.forceBrace = tbl.forceBrace or {}
tbl.forceBrace.enabled = false
tbl.forceBrace.thread = nil

tbl.forceBrace.getRemote = function()
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return nil
	end

	for _, v20 in { "Axe", "Pickaxe", "Baguette" }, nil, nil do
		local v21 = backpack:FindFirstChild(v20)

		if v21 then
			local remoteEvent = v21:FindFirstChild("RemoteEvent")
			if remoteEvent then
				return remoteEvent
			end
		end
	end

	return nil
end

tbl.forceBrace.sendBrace = function()
	local v20 = tbl.forceBrace.getRemote()

	if v20 then
		pcall(function()
			v20:FireServer("BraceBlock")
		end)
	end
end

tbl.forceBrace.loop = function()
	while tbl.forceBrace.enabled do
		tbl.forceBrace.sendBrace()
		task.wait(0.2)
	end
end

tbl.forceBrace.start = function()
	if tbl.forceBrace.enabled then
		return
	end
	tbl.forceBrace.enabled = true

	if tbl.forceBrace.thread then
		task.cancel(tbl.forceBrace.thread)
	end

	tbl.forceBrace.thread = task.spawn(tbl.forceBrace.loop)
	tbl.notify(fn3("静默格挡已开启"), 2)
end

tbl.forceBrace.stop = function()
	tbl.forceBrace.enabled = false

	if tbl.forceBrace.thread then
		task.cancel(tbl.forceBrace.thread)
		tbl.forceBrace.thread = nil
	end

	tbl.notify(fn3("静默格挡已关闭"), 2)
end

v18:AddToggle("ForceBraceToggle", {
	Text = "静默格挡",
	Default = false,
	Tooltip = fn4("自动格挡劈砍（无需手持武器）"),
	Callback = function(arg)
		if arg then
			tbl.forceBrace.start()
		else
			tbl.forceBrace.stop()
		end
	end,
})

tbl.axeStunActive = false
tbl.axeStunConnection = nil
tbl.axeStunRange = 15
tbl.axeStunCount = 5
tbl.axeStunDelay = 0
tbl.axeStunLastFire = 0

do
	local function fn7()
		local character = localPlayer.Character

		if character then
			for _, v20 in character:GetChildren() do
				if v20:GetAttribute("Melee") then
					return v20
				end
			end
		end

		local backpack = localPlayer:FindFirstChild("Backpack")

		if backpack then
			for _, v20 in backpack:GetChildren() do
				if v20:GetAttribute("Melee") then
					return v20
				end
			end
		end

		return nil
	end

	local tbl5 = { Axe = true, Pickaxe = true, Baguette = true }

	local function fn8(arg, arg2, arg3)
		arg:FireServer("BraceBlock")
		arg:FireServer("StopBraceBlock")
		arg:FireServer("FeedbackStun", arg2, arg3)
	end

	local function fn9(arg)
		local v20 = fn7()
		if not v20 or not tbl5[v20.Name] then
			return
		end
		local state = arg:FindFirstChild("State")
		if state and state.Value == "Stunned" then
			return
		end
		local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local remoteEvent = v20:FindFirstChild("RemoteEvent")
		if not remoteEvent then
			return
		end
		fn8(remoteEvent, arg, humanoidRootPart.CFrame.Position)
	end

	tbl.startAxeStun = function()
		if tbl.axeStunConnection then
			return
		end
		tbl.axeStunActive = true

		tbl.axeStunConnection = v5.Heartbeat:Connect(function()
			if not tbl.axeStunActive then
				return
			end
			local axeStunLastFire = tbl.axeStunLastFire
			if clock() - axeStunLastFire < tbl.axeStunDelay then
				return
			end
			local character = localPlayer.Character
			if not character then
				return
			end
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			local zombies = workspace:FindFirstChild("Zombies")
			if not zombies then
				return
			end
			local tbl6 = {}

			for _, v20 in zombies:GetChildren() do
				if v20:IsA("Model") and v20:FindFirstChild("HumanoidRootPart") then
					local magnitude = (v20.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude

					if magnitude <= tbl.axeStunRange then
						table.insert(tbl6, { zombie = v20, dist = magnitude })
					end
				end
			end

			table.sort(tbl6, function(arg, arg2)
				return arg.dist < arg2.dist
			end)

			for i = 1, min(tbl.axeStunCount, #tbl6) do
				fn9(tbl6[i].zombie)
			end

			tbl.axeStunLastFire = clock()
		end)
	end

	tbl.stopAxeStun = function()
		tbl.axeStunActive = false

		if tbl.axeStunConnection then
			tbl.axeStunConnection:Disconnect()
			tbl.axeStunConnection = nil
		end
	end

	tbl.onCharacterAdded(function()
		if tbl.axeStunActive then
			tbl.stopAxeStun()

			if toggles.AxeStunToggle then
				toggles.AxeStunToggle:SetValue(false)
			end
		end
	end)

	v18:AddToggle("AxeStunToggle", {
		Text = "肘击",
		Default = false,
		Tooltip = fn4("自动肘击范围15格内的僵尸"),
		Callback = function(arg)
			if arg then
				tbl.startAxeStun()
			else
				tbl.stopAxeStun()
			end
		end,
	})

	v18:AddSlider("AxeStunRange", {
		Text = "肘击距离",
		Default = 15,
		Min = 5,
		Max = 35,
		Rounding = 0,
		Suffix = " 格",
		Callback = function(axeStunRange)
			tbl.axeStunRange = axeStunRange
		end,
	})

	v18:AddSlider("AxeStunCount", {
		Text = "肘击数量",
		Default = 5,
		Min = 1,
		Max = 5,
		Rounding = 0,
		Suffix = " 个",
		Callback = function(axeStunCount)
			tbl.axeStunCount = axeStunCount
		end,
	})

	v18:AddSlider("AxeStunDelay", {
		Text = "肘击间隔",
		Default = 0,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Suffix = " 秒",
		Callback = function(axeStunDelay)
			tbl.axeStunDelay = axeStunDelay
		end,
	})

	tbl.engineerElbowEnabled = false
	tbl.engineerAnimConnection = nil
	tbl.engineerElbowRange = 50
	tbl.engineerElbowCount = 5
	local tbl6 = { "rbxassetid://15345113937" }

	tbl.getValidMelee = function()
		local character = localPlayer.Character
		if not character then
			return nil
		end
		local tool = character:FindFirstChildOfClass("Tool")
		if not tool then
			return nil
		end
		local name = tool.Name
		if name == "Pickaxe" or name == "Axe" or name == "Baguette" then
			return tool
		end
		return nil
	end

	tbl.stunAroundPlayer = function()
		if not tbl.engineerElbowEnabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local v20 = tbl.getValidMelee()
		if not v20 then
			return
		end
		local remoteEvent = v20:FindFirstChild("RemoteEvent")
		if not remoteEvent then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local position = humanoidRootPart.Position
		local zombies = workspace:FindFirstChild("Zombies")
		if not zombies then
			return
		end
		local tbl7 = {}

		for _, v21 in zombies:GetChildren() do
			if v21:IsA("Model") and v21:FindFirstChild("HumanoidRootPart") then
				if v21:GetAttribute("Type") ~= "Barrel" then
					local state = v21:FindFirstChild("State")

					if not (state and state.Value == "Spawn") then
						local humanoidRootPart2 = v21:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart2 then
							local magnitude = (humanoidRootPart2.Position - position).Magnitude

							if magnitude <= tbl.engineerElbowRange then
								if v21:FindFirstChild("State") and v21.State.Value ~= "Stunned" then
									table.insert(tbl7, { zombie = v21, root = humanoidRootPart2, dist = magnitude })
								end
							end
						end
					end
				end
			end
		end

		table.sort(tbl7, function(arg, arg2)
			return arg.dist < arg2.dist
		end)

		for i = 1, min(tbl.engineerElbowCount, #tbl7) do
			local v21 = tbl7[i]

			pcall(function()
				fn8(remoteEvent, v21.zombie, v21.root.Position)
			end)
		end
	end

	tbl.onElbowAnimationPlayed = function(arg)
		if not tbl.engineerElbowEnabled then
			return
		end
		local animationId = arg.Animation.AnimationId

		for _, v20 in tbl6, nil, nil do
			if animationId == v20 then
				tbl.stunAroundPlayer()
				break
			end
		end
	end
end

tbl.updateEngineerAnimConnection = function()
	if tbl.engineerElbowEnabled then
		if tbl.engineerAnimConnection then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			tbl.engineerAnimConnection = humanoid.AnimationPlayed:Connect(tbl.onElbowAnimationPlayed)
		end
	elseif tbl.engineerAnimConnection then
		tbl.engineerAnimConnection:Disconnect()
		tbl.engineerAnimConnection = nil
	end
end

tbl.onCharacterAdded(tbl.updateEngineerAnimConnection)

v18:AddToggle("EngineerElbowToggle", {
	Text = "肘击范围扩大",
	Default = false,
	Tooltip = fn4("扩大肘击生效范围"),
	Callback = function(engineerElbowEnabled)
		tbl.engineerElbowEnabled = engineerElbowEnabled
		tbl.updateEngineerAnimConnection()
	end,
})

v18:AddSlider("EngineerElbowRange", {
	Text = "肘击扩大距离",
	Default = 50,
	Min = 5,
	Max = 50,
	Rounding = 0,
	Suffix = " 格",
	Callback = function(engineerElbowRange)
		tbl.engineerElbowRange = engineerElbowRange
	end,
})

v18:AddSlider("EngineerElbowCount", {
	Text = "肘击扩大数量",
	Default = 5,
	Min = 1,
	Max = 5,
	Rounding = 0,
	Suffix = " 个",
	Callback = function(engineerElbowCount)
		tbl.engineerElbowCount = engineerElbowCount
	end,
})

tbl.engineerRecycleEnabled = false
tbl.recycleAnimConnection = nil

local tbl5 = {
	"rbxassetid://16663569329",
	"rbxassetid://16663563130",
	"rbxassetid://109975878922735",
	"rbxassetid://12638406999",
	"rbxassetid://94131315859283",
	"rbxassetid://12638412059",
}

tbl.recycleWeapon = function()
	if not tbl.engineerRecycleEnabled then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local name = tool.Name
	if name ~= "Pickaxe" and name ~= "Axe" and name ~= "Baguette" then
		return
	end
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end
	tool.Parent = backpack
	task.wait(0.1)

	if tbl.engineerRecycleEnabled and tool.Parent == backpack then
		tool.Parent = character
	end
end

tbl.onRecycleAnimationPlayed = function(arg)
	if not tbl.engineerRecycleEnabled then
		return
	end
	local animationId = arg.Animation.AnimationId

	for _, v20 in tbl5, nil, nil do
		if animationId == v20 then
			task.delay(animationId == "rbxassetid://12638412059" and 0.4 or 0.3, tbl.recycleWeapon)
			break
		end
	end
end

tbl.updateRecycleAnimConnection = function()
	if tbl.engineerRecycleEnabled then
		if tbl.recycleAnimConnection then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			tbl.recycleAnimConnection = humanoid.AnimationPlayed:Connect(tbl.onRecycleAnimationPlayed)
		end
	elseif tbl.recycleAnimConnection then
		tbl.recycleAnimConnection:Disconnect()
		tbl.recycleAnimConnection = nil
	end
end

tbl.onCharacterAdded(tbl.updateRecycleAnimConnection)

v18:AddToggle("EngineerRecycleToggle", {
	Text = "攻击武器回收",
	Default = false,
	Tooltip = fn4("攻击后自动卸下并重新装备武器，取消后摇"),
	Callback = function(engineerRecycleEnabled)
		tbl.engineerRecycleEnabled = engineerRecycleEnabled
		tbl.updateRecycleAnimConnection()
	end,
})

do
	local v20 = tbl3.Extra:AddGroupbox({ Side = "Right", Name = "医生", IconName = "cross", Description = "自动治疗" })
	tbl.doctor = { enabled = false, threshold = 25, range = 10, cooldown = 2, lastRequest = {}, thread = nil }

	local function fn7()
		local character = localPlayer.Character
		if not character then
			return nil
		end
		local medicalSupplies = character:FindFirstChild("Medical Supplies")
		if medicalSupplies then
			return medicalSupplies:FindFirstChild("RemoteEvent")
		end
		return nil
	end

	local function fn8(arg, arg2)
		if not arg or not arg2 then
			return
		end

		if arg2.Health / arg2.MaxHealth * 100 > tbl.doctor.threshold then
			return
		end
		local v21 = clock()
		if v21 < (tbl.doctor.lastRequest[arg] or 0) + tbl.doctor.cooldown then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local humanoidRootPart2 = arg2.Parent and (arg2.Parent:FindFirstChild("HumanoidRootPart") or arg2.Parent:FindFirstChild("Torso"))
		if not humanoidRootPart2 then
			return
		end

		if tbl.doctor.range < (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude then
			return
		end
		local v22 = fn7()
		if not v22 then
			return
		end
		tbl.doctor.lastRequest[arg] = v21

		pcall(function()
			v22:FireServer("SendRequest", arg2)
		end)
	end

	tbl.doctor.loop = function()
		while tbl.doctor.enabled do
			for _, v21 in v4:GetPlayers() do
				if v21 ~= localPlayer and v21.Character then
					local humanoid = v21.Character:FindFirstChildOfClass("Humanoid")

					if humanoid and humanoid.Health > 0 then
						pcall(fn8, v21, humanoid)
					end
				end
			end

			task.wait(0.5)
		end
	end

	tbl.doctor.start = function()
		if tbl.doctor.thread then
			return
		end
		tbl.doctor.enabled = true
		tbl.doctor.thread = task.spawn(tbl.doctor.loop)
		tbl.notify(fn3("自动治疗已开启"), 2)
	end

	tbl.doctor.stop = function()
		tbl.doctor.enabled = false

		if tbl.doctor.thread then
			task.cancel(tbl.doctor.thread)
			tbl.doctor.thread = nil
		end

		tbl.doctor.lastRequest = {}
		tbl.notify(fn3("自动治疗已关闭"), 2)
	end

	tbl.doctor.autoPickup = { enabled = false, thread = nil, range = 5 }

	tbl.doctor.autoPickup.getHRP = function(arg)
		return arg and arg:FindFirstChild("HumanoidRootPart")
	end

	tbl.doctor.autoPickup.findDrop = function(arg, arg2)
		local n = arg2 + 1
		local v21 = nil
		local v22 = nil

		for _, v23 in workspace:GetDescendants() do
			if v23:IsA("ProximityPrompt") and v23.Enabled and v23.Name == "ReplenishPrompt" then
				local parent = v23.Parent

				if parent and parent:IsA("BasePart") and parent.Name == "SupplyVisualizer" then
					local magnitude = (parent.Position - arg).Magnitude

					if magnitude < n then
						n = magnitude
						v21 = v23
						v22 = parent
					end
				end
			end
		end

		return v21, v22, n
	end

	tbl.doctor.autoPickup.loop = function()
		while tbl.doctor.autoPickup.enabled do
			local v21 = tbl.doctor.autoPickup.getHRP(localPlayer.Character)

			if v21 then
				local v22, v23, v24 = tbl.doctor.autoPickup.findDrop(v21.Position, tbl.doctor.autoPickup.range)

				if v22 and v24 <= tbl.doctor.autoPickup.range then
					pcall(function()
						fireproximityprompt(v22)
					end)

					task.wait(0.05)
				end
			end

			task.wait(0.2)
		end
	end

	tbl.doctor.autoPickup.start = function()
		if tbl.doctor.autoPickup.thread then
			return
		end
		tbl.doctor.autoPickup.enabled = true
		tbl.doctor.autoPickup.thread = task.spawn(tbl.doctor.autoPickup.loop)
		tbl.notify(fn3("自动拾取纱布已开启"), 2)
	end

	tbl.doctor.autoPickup.stop = function()
		tbl.doctor.autoPickup.enabled = false

		if tbl.doctor.autoPickup.thread then
			task.cancel(tbl.doctor.autoPickup.thread)
			tbl.doctor.autoPickup.thread = nil
		end

		tbl.notify(fn3("自动拾取纱布已关闭"), 2)
	end

	v20:AddToggle("DoctorAutoHealToggle", {
		Text = "自动治疗受伤玩家",
		Default = false,
		Tooltip = fn4("自动向低血量玩家发送治疗请求"),
		Callback = function(arg)
			if arg then
				tbl.doctor.start()
			else
				tbl.doctor.stop()
			end
		end,
	})

	v20:AddSlider("DoctorHealThreshold", {
		Text = "治疗阈值 (%)",
		Default = 25,
		Min = 1,
		Max = 100,
		Suffix = "%",
		Callback = function(threshold)
			tbl.doctor.threshold = threshold
		end,
	})

	v20:AddToggle("DoctorAutoPickupBandage", {
		Text = "自动拾取纱布",
		Default = false,
		Tooltip = fn4("自动拾取附近的纱布补给"),
		Callback = function(arg)
			if arg then
				tbl.doctor.autoPickup.start()
			else
				tbl.doctor.autoPickup.stop()
			end
		end,
	})
end

do
	local v20 = tbl3.Extra:AddGroupbox({ Side = "Right", Name = "牧师", IconName = "church", Description = "自动祝福" })
	tbl.chaplain = { enabled = false, threshold = 50, cooldown = 2, range = 15, lastRequest = {}, thread = nil }

	local function fn7()
		local character = localPlayer.Character
		if not character then
			return nil
		end
		local blessing = character:FindFirstChild("Blessing")
		if blessing and blessing:FindFirstChild("RemoteEvent") then
			return blessing.RemoteEvent
		end

		for _, v21 in character:GetChildren() do
			if v21:IsA("Tool") and v21.Name:lower():find("bless") and v21:FindFirstChild("RemoteEvent") then
				return v21.RemoteEvent
			end
		end

		return nil
	end

	local function fn8(arg)
		local character = localPlayer.Character
		if not character then
			return false
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return false
		end

		if not arg.Character then
			return false
		end
		local humanoidRootPart2 = arg.Character:FindFirstChild("HumanoidRootPart") or arg.Character:FindFirstChild("Torso")
		if not humanoidRootPart2 then
			return false
		end
		return (humanoidRootPart.Position - humanoidRootPart2.Position).Magnitude <= tbl.chaplain.range
	end

	local function fn9(arg, arg2)
		if not arg or not arg2 then
			return
		end
		local threshold = tbl.chaplain.threshold
		if tbl.getInfectionForPlayer(arg) < threshold then
			return
		end
		local v21 = clock()
		if v21 < (tbl.chaplain.lastRequest[arg] or 0) + tbl.chaplain.cooldown then
			return
		end

		if not fn8(arg) then
			return
		end
		local v22 = fn7()
		if not v22 then
			return
		end

		pcall(function()
			v22:FireServer("SendRequest", arg2)
			tbl.chaplain.lastRequest[arg] = v21
		end)
	end

	tbl.chaplain.loop = function()
		while tbl.chaplain.enabled do
			for _, v21 in v4:GetPlayers() do
				if v21 ~= localPlayer and v21.Character then
					local humanoid = v21.Character:FindFirstChildOfClass("Humanoid")

					if humanoid and humanoid.Health > 0 then
						pcall(fn9, v21, humanoid)
					end
				end
			end

			task.wait(0.5)
		end
	end

	tbl.chaplain.start = function()
		if tbl.chaplain.thread then
			return
		end
		tbl.chaplain.enabled = true
		tbl.chaplain.thread = task.spawn(tbl.chaplain.loop)
		tbl.notify(fn3("自动祝福已开启"), 2)
	end

	tbl.chaplain.stop = function()
		tbl.chaplain.enabled = false

		if tbl.chaplain.thread then
			task.cancel(tbl.chaplain.thread)
			tbl.chaplain.thread = nil
		end

		tbl.chaplain.lastRequest = {}
		tbl.notify(fn3("自动祝福已关闭"), 2)
	end

	v20:AddToggle("ChaplainAutoBlessToggle", {
		Text = "自动祝福感染玩家",
		Default = false,
		Tooltip = fn4("自动向感染值高的玩家发送祝福"),
		Callback = function(arg)
			if arg then
				tbl.chaplain.start()
			else
				tbl.chaplain.stop()
			end
		end,
	})

	v20:AddSlider("ChaplainBlessThreshold", {
		Text = "祝福阈值 (%)",
		Default = 50,
		Min = 1,
		Max = 100,
		Suffix = "%",
		Callback = function(threshold)
			tbl.chaplain.threshold = threshold
		end,
	})
end

if not tbl.Fife then
	tbl.Fife = {}
end

local v20 = tbl3.Extra:AddGroupbox({ Side = "Left", Name = "音乐家", IconName = "music", Description = "自动演奏" })
tbl.fifeAccuracyEnabled = false
tbl.fifeOldNamecall = nil
tbl.inFifeHook = false

tbl.setupFifeHook = function()
	if tbl.fifeOldNamecall then
		return
	end

	if type(hookmetamethod) ~= "function" then
		warn("Auto Fife: hookmetamethod not available")
		return
	end

	local fn7 = checkcaller or function()
		return false
	end

	pcall(function()
		tbl.fifeOldNamecall = hookmetamethod(game, "__namecall", function(arg, ...)
			if tbl.inFifeHook then
				return tbl.fifeOldNamecall(arg, ...)
			end

			if getnamecallmethod() == "FireServer" and not fn7() then
				tbl.inFifeHook = true
				local tbl6 = { ... }

				if tbl6[1] == "UpdateAccuracy" then
					tbl6[2] = 100
				end

				tbl.inFifeHook = false
				return tbl.fifeOldNamecall(arg, unpack(tbl6))
			end

			return tbl.fifeOldNamecall(arg, ...)
		end)
	end)
end

tbl.removeFifeHook = function()
	if tbl.fifeOldNamecall then
		if type(tbl.fifeOldNamecall) == "function" then
			pcall(function()
				hookmetamethod(game, "__namecall", tbl.fifeOldNamecall)
			end)
		end

		tbl.fifeOldNamecall = nil
	end
end

tbl.toggleAutoFife = function(fifeAccuracyEnabled)
	tbl.fifeAccuracyEnabled = fifeAccuracyEnabled

	if fifeAccuracyEnabled then
		tbl.setupFifeHook()
	else
		tbl.removeFifeHook()
	end
end

v20:AddToggle("AutoFifeToggle", {
	Text = "自动演奏",
	Default = false,
	Tooltip = fn4("演奏笛子时自动达到 100% 准确度"),
	Callback = function(arg)
		tbl.toggleAutoFife(arg)
	end,
})

local v21
v21 = tbl3.LocalPlayer:AddGroupbox({ Side = "Left", Name = "主要功能", IconName = "user", Description = "速度跳跃" })

do
	local v22 = tbl3.LocalPlayer:AddGroupbox({ Side = "Right", Name = "美化", IconName = "sparkles", Description = "外观特效" })

	v22:AddInput("DisguiseAppearanceInput", {
		Default = "gay",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = true,
		Text = "替换玩家名字",
		Tooltip = fn4("输入要复制装扮的玩家名"),
		Placeholder = "输入名字",
		Callback = function()
		end,
	})

	v22:AddButton({
		Text = "替换装扮",
		Func = function()
			tbl.disguise.applyAppearanceOnly(options.DisguiseAppearanceInput.Value)
		end,
		Tooltip = fn4("替换玩家外观"),
	})

	v22:AddInput("DisguiseNameInput", {
		Default = "gay",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = true,
		Text = "修改用户名",
		Tooltip = fn4("输入要改为的用户名"),
		Placeholder = "输入用户名",
		Callback = function()
		end,
	})

	v22:AddButton({
		Text = "修改名字",
		Func = function()
			tbl.disguise.changeNameOnly(options.DisguiseNameInput.Value)
		end,
		Tooltip = fn4("仅修改显示名字"),
	})

	local index = {}
	index.__index = index

	index.new = function()
		local obj = setmetatable({}, index)
		obj.Lighting = v9
		obj.Workspace = v19
		obj.TweenService = v8
		obj.LocalPlayer = v4.LocalPlayer

		obj.Config = {
			MaxParticles = 1200,
			SpawnInterval = 0.03,
			Radius = 60,
			WindX = -8,
			WindY = -12,
			WindZ = 6,
			TextureID = "rbxassetid://7456123890",
			NeonRatio = 0.35,
		}

		obj.Pool = {}
		obj.PoolIndex = 1
		obj.Folder = nil
		obj.IsRunning = false
		return obj
	end

	index.ClearSession = function(arg)
		pcall(function()
			local cherryBlossomLayer = arg.Workspace:FindFirstChild("CherryBlossom_Layer")

			if cherryBlossomLayer then
				cherryBlossomLayer:Destroy()
			end
		end)

		for _, v23 in arg.Lighting:GetChildren() do
			if v23.Name:find("BlossomFX_") then
				pcall(function()
					v23:Destroy()
				end)
			end
		end
	end

	index.ApplyLightingPipeline = function(arg)
		pcall(function()
			local level21 = Enum.QualityLevel.Level21
			settings().Rendering.QualityLevel = level21
			arg.Lighting.Technology = Enum.Technology.Future
			arg.Lighting.GlobalShadows = true
			arg.Lighting.EnvironmentDiffuseScale = 0.55
			arg.Lighting.EnvironmentSpecularScale = 0.55
		end)

		arg.Lighting.ClockTime = 20.6
		arg.Lighting.Brightness = 1.2
		arg.Lighting.Ambient = color(55, 45, 55)
		arg.Lighting.OutdoorAmbient = color(75, 65, 85)
		local atmosphere = arg.Lighting:FindFirstChildOfClass("Atmosphere")

		if not atmosphere then
			atmosphere = Instance.new("Atmosphere")
			atmosphere.Parent = arg.Lighting
		end

		atmosphere.Density = 0.38
		atmosphere.Haze = 2
		atmosphere.Color = color(255, 180, 195)
		atmosphere.Decay = color(80, 40, 55)
		atmosphere.Glare = 0.15
		local colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
		colorCorrectionEffect.Name = "BlossomFX_Color"
		colorCorrectionEffect.Brightness = 0.02
		colorCorrectionEffect.Contrast = 0.12
		colorCorrectionEffect.Saturation = 0.25
		colorCorrectionEffect.TintColor = color(255, 240, 245)
		colorCorrectionEffect.Parent = arg.Lighting
		local bloomEffect = Instance.new("BloomEffect")
		bloomEffect.Name = "BlossomFX_Bloom"
		bloomEffect.Intensity = 0.45
		bloomEffect.Size = 16
		bloomEffect.Threshold = 0.85
		bloomEffect.Parent = arg.Lighting
		local sunRaysEffect = arg.Lighting:FindFirstChildOfClass("SunRaysEffect")

		if sunRaysEffect then
			pcall(function()
				sunRaysEffect:Destroy()
			end)
		end
	end

	index.InitializeParticlePool = function(arg)
		arg.Folder = Instance.new("Folder")
		arg.Folder.Name = "CherryBlossom_Layer"
		arg.Folder.Parent = arg.Workspace

		for i = 1, arg.Config.MaxParticles do
			local part = Instance.new("Part")
			part.Size = Vector3.one
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Anchored = true
			part.CastShadow = false
			part.Transparency = 1
			part.Position = Vector3.new(0, 9999, 0)
			part.Parent = arg.Folder
			local neonRatio = arg.Config.NeonRatio
			local flag = math.random() < neonRatio
			part.Material = flag and Enum.Material.Neon or Enum.Material.SmoothPlastic
			part.Color = flag and color(255, 200, 225) or color(235, 205, 215)
			local specialMesh = Instance.new("SpecialMesh")
			specialMesh.MeshType = Enum.MeshType.Sphere
			local n = math.random(4, 8) / 10
			specialMesh.Scale = vector(n * 0.65, 0.02, n)
			specialMesh.Parent = part
			local decal = Instance.new("Decal")
			decal.Texture = arg.Config.TextureID
			decal.Face = Enum.NormalId.Top
			decal.Transparency = flag and 0.4 or 0.05
			decal.Parent = part
			local clone = decal:Clone()
			clone.Face = Enum.NormalId.Bottom
			clone.Parent = part
			arg.Pool[i] = { Part = part, TweenMove = nil, TweenFade = nil, IsNeon = flag }
		end
	end

	index.EmitPetal = function(arg, arg2)
		if not arg2 or not arg.IsRunning then
			return
		end
		local v23 = arg.Pool[arg.PoolIndex]
		arg.PoolIndex = arg.PoolIndex % arg.Config.MaxParticles + 1

		if v23.TweenMove then
			pcall(function()
				v23.TweenMove:Cancel()
			end)
		end

		if v23.TweenFade then
			pcall(function()
				v23.TweenFade:Cancel()
			end)
		end

		local part = v23.Part
		local radius = arg.Config.Radius
		local position = arg2.Position + vector(math.random(-radius * 10, radius * 10) / 10, math.random(150, 450) / 10, math.random(-radius * 10, radius * 10) / 10)
		local n = math.random(35, 60) / 10
		local windZ = arg.Config.WindZ
		local n2 = position + vector(arg.Config.WindX + math.random(-80, 80) / 10, arg.Config.WindY - math.random(50, 100) / 10, windZ + math.random(-80, 80) / 10)
		part.Position = position
		local cframe2 = CFrame.Angles
		local random = math.random
		part.CFrame = cframe(position) * cframe2(rad(math.random(0, 360)), rad(math.random(0, 360)), rad(random(0, 360)))
		part.Transparency = 1
		local n3 = v23.IsNeon and 0.1 or math.random(5, 20) / 100
		v23.TweenFade = arg.TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Transparency = n3 })
		local cframe3 = CFrame.Angles
		local random2 = math.random

		v23.TweenMove = arg.TweenService:Create(part, TweenInfo.new(n, Enum.EasingStyle.Linear), {
			CFrame = cframe(n2) * cframe3(rad(math.random(270, 720)), rad(math.random(180, 540)), rad(random2(270, 720))),
		})

		v23.TweenFade:Play()
		v23.TweenMove:Play()

		task.delay(n - 0.5, function()
			if arg.IsRunning and part and part.Parent then
				pcall(function()
					arg.TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Transparency = 1 }):Play()
				end)
			end
		end)

		task.delay(n, function()
			if part and part.Parent then
				part.Transparency = 1
				part.Position = Vector3.new(0, 9999, 0)
			end
		end)
	end

	index.Start = function(arg)
		arg:ClearSession()
		arg:ApplyLightingPipeline()
		arg:InitializeParticlePool()
		arg.IsRunning = true

		task.spawn(function()
			while arg.IsRunning do
				local character = arg.LocalPlayer.Character
				local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then
					for i = 1, 4 do
						if arg.IsRunning then
							arg:EmitPetal(humanoidRootPart)
							continue
						end
						break
					end
				end

				task.wait(arg.Config.SpawnInterval)
			end
		end)
	end

	index.Destroy = function(arg)
		arg.IsRunning = false

		for _, v23 in arg.Pool, nil, nil do
			if v23.TweenMove then
				pcall(function()
					v23.TweenMove:Cancel()
				end)
			end

			if v23.TweenFade then
				pcall(function()
					v23.TweenFade:Cancel()
				end)
			end
		end

		arg:ClearSession()
		arg.Pool = {}
	end

	_G.CherryBlossomInstance = nil

	_G.StartCherryBlossom = function()
		if _G.CherryBlossomInstance then
			_G.CherryBlossomInstance:Destroy()
		end

		_G.CherryBlossomInstance = index.new()
		_G.CherryBlossomInstance:Start()
		shared.CherryBlossomActiveSession = _G.StartCherryBlossom
	end

	_G.StopCherryBlossom = function()
		if _G.CherryBlossomInstance then
			_G.CherryBlossomInstance:Destroy()
			_G.CherryBlossomInstance = nil
		end

		shared.CherryBlossomActiveSession = nil
	end

	if shared.CherryBlossomActiveSession then
		pcall(function()
			shared.CherryBlossomActiveSession()
		end)
	end

	v22:AddToggle("CherryBlossomToggle", {
		Text = "樱花天空(无法恢复)",
		Tooltip = fn4("飘落樱花花瓣 紫色天空 记住无法恢复"),
		Default = false,
		Callback = function(arg)
			if arg then
				_G.StartCherryBlossom()
			else
				_G.StopCherryBlossom()
			end
		end,
	})

	tbl.francModifier = tbl.francModifier or {}
	tbl.francModifier.enabled = false
	tbl.francModifier.targetValue = 99999999
	tbl.francModifier.charAddedDisposer = nil

	tbl.francModifier.apply = function()
		if not tbl.francModifier.enabled then
			return
		end
		local leaderstats = localPlayer:FindFirstChild("leaderstats")

		if leaderstats then
			local francs = leaderstats:FindFirstChild("Francs")

			if francs and (francs:IsA("NumberValue") or francs:IsA("IntValue")) then
				francs.Value = tbl.francModifier.targetValue
			end
		end
	end

	tbl.francModifier.onCharacterAdded = function()
		task.wait(0.2)
		tbl.francModifier.apply()
	end

	tbl.francModifier.start = function()
		if tbl.francModifier.enabled then
			return
		end
		tbl.francModifier.enabled = true
		tbl.francModifier.apply()

		if not tbl.francModifier.charAddedDisposer then
			tbl.francModifier.charAddedDisposer = tbl.onCharacterAdded(tbl.francModifier.onCharacterAdded)
		end
	end

	tbl.francModifier.stop = function()
		tbl.francModifier.enabled = false

		if tbl.francModifier.charAddedDisposer then
			tbl.francModifier.charAddedDisposer()
			tbl.francModifier.charAddedDisposer = nil
		end
	end

	v22:AddInput("FrancAmountInput", {
		Text = "法郎数量",
		Default = "柳叶",
		Numeric = true,
		Finished = true,
		Callback = function(arg)
			local num = tonumber(arg)

			if num then
				tbl.francModifier.targetValue = floor(num)
			else
				tbl.francModifier.targetValue = 99999999
			end
		end,
	})

	v22:AddToggle("FrancModifierToggle", {
		Text = "修改法郎数量",
		Tooltip = fn4("开启后本地修改法郎"),
		Default = false,
		Callback = function(arg)
			if arg then
				tbl.francModifier.start()
			else
				tbl.francModifier.stop()
			end
		end,
	})

	tbl.zeroBeauty = tbl.zeroBeauty or {}
	tbl.zeroBeauty.enabled = false
	tbl.zeroBeauty.connection = nil

	tbl.zeroBeauty.start = function()
		if tbl.zeroBeauty.connection then
			return
		end
		tbl.zeroBeauty.enabled = true

		tbl.zeroBeauty.connection = v5.Heartbeat:Connect(function()
			if not tbl.zeroBeauty.enabled then
				return
			end
			local character = localPlayer.Character
			if not character then
				return
			end
			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			local face = character:FindFirstChild("Face")

			if face then
				local face2 = face:FindFirstChild("Face")

				if face2 and face2:IsA("Decal") then
					face2.Texture = "http://www.roblox.com/asset/?id=174259585"
				end
			end

			if character:FindFirstChild("Face") then
				character.Face.Color = color(121, 121, 121)
			end

			if character:FindFirstChild("Torso") then
				character.Torso.Color = color(121, 121, 121)
			end

			if character:FindFirstChild("Right Leg") then
				character["Right Leg"].Color = color(121, 121, 121)
			end

			if character:FindFirstChild("Right Arm") then
				character["Right Arm"].Color = color(121, 121, 121)
			end

			if character:FindFirstChild("Left Leg") then
				character["Left Leg"].Color = color(121, 121, 121)
			end

			if character:FindFirstChild("Left Arm") then
				character["Left Arm"].Color = color(121, 121, 121)
			end
		end)
	end

	tbl.zeroBeauty.stop = function()
		tbl.zeroBeauty.enabled = false

		if tbl.zeroBeauty.connection then
			tbl.zeroBeauty.connection:Disconnect()
			tbl.zeroBeauty.connection = nil
		end

		local character = localPlayer.Character
		if not character then
			return
		end
		local face = character:FindFirstChild("Face")

		if face then
			local face2 = face:FindFirstChild("Face")

			if face2 and face2:IsA("Decal") then
				face2.Texture = "rbxassetid://13815097986"
			end
		end

		if character:FindFirstChild("Face") then
			character.Face.Color = color(255, 204, 153)
		end

		if character:FindFirstChild("Torso") then
			character.Torso.Color = color(255, 204, 153)
		end

		if character:FindFirstChild("Right Leg") then
			character["Right Leg"].Color = color(255, 204, 153)
		end

		if character:FindFirstChild("Right Arm") then
			character["Right Arm"].Color = color(255, 204, 153)
		end

		if character:FindFirstChild("Left Leg") then
			character["Left Leg"].Color = color(255, 204, 153)
		end

		if character:FindFirstChild("Left Arm") then
			character["Left Arm"].Color = color(255, 204, 153)
		end
	end

	v22:AddToggle("ZeroBeautyToggle", {
		Text = "更改外观",
		Tooltip = fn4("更改玩家肤色 面部表情"),
		Default = false,
		Callback = function(arg)
			if arg then
				tbl.zeroBeauty.start()
			else
				tbl.zeroBeauty.stop()
			end
		end,
	})

	v22:AddLabel("服务器加入")

	v22:AddInput("ServerTrackerInput", {
		Text = "玩家用户名",
		Default = "",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = true,
		Placeholder = "输入玩家名",
		Callback = function()
		end,
	})

	v22:AddButton({
		Text = "加入",
		Func = function()
			local pendingSearch = options.ServerTrackerInput.Value
			if pendingSearch == "" then
				lib:Notify({ Title = fn3("错误"), Description = fn3("请输入玩家名"), Time = 3 })
				return
			end
			local serverBrowserEvent = v7:FindFirstChild("ServerBrowserEvent")
			local serverBrowserFunc = v7:FindFirstChild("ServerBrowserFunc")
			if not serverBrowserEvent then
				lib:Notify({ Title = fn3("错误"), Description = fn3("无法获取服务器事件"), Time = 3 })
				return
			end
			tbl.serverTracker.pendingSearch = pendingSearch

			if serverBrowserFunc and serverBrowserFunc:IsA("RemoteEvent") then
				serverBrowserFunc:FireServer("RequestListing")
			else
				serverBrowserEvent:FireServer("RequestListing")
			end

			lib:Notify({ Title = fn3("搜索中"), Description = fn3("请耐心等待"), Time = 2 })
		end,
		Tooltip = fn4("服务器加入"),
	})
end

if not tbl.serverTracker then
	tbl.serverTracker = { pendingSearch = nil, initialized = false }
end

local function fn7()
	return v7:FindFirstChild("ServerBrowserEvent"), (v7:FindFirstChild("ServerBrowserFunc"))
end

tbl.serverTracker.init = function()
	if tbl.serverTracker.initialized then
		return
	end
	local v22 = fn7()
	if not v22 then
		return
	end

	v22.OnClientEvent:Connect(function(arg, arg2)
		if arg == "ReturnListing" and arg2 then
			local pendingSearch = tbl.serverTracker.pendingSearch
			if not pendingSearch then
				return
			end
			tbl.serverTracker.pendingSearch = nil

			local ok, result = pcall(function()
				return v4:GetUserIdFromNameAsync(pendingSearch)
			end)

			if not (ok and result and result > 0) then
				local ok2, result2 = pcall(function()
					return v2:GetAsync("https://users.roblox.com/v1/users/search?keyword=" .. v2:UrlEncode(pendingSearch))
				end)

				local v23 = ok2 and result2
				local v24 = nil

				if v23 then
					local data = v2:JSONDecode(result2)
					local flag = data and data.data and #data.data > 0
					local v25 = nil

					if flag then
						local id = nil

						for _, v26 in data.data, nil, nil do
							if string.lower(v26.name) == string.lower(pendingSearch) then
								id = v26.id
								break
							else
								id = nil
							end
						end

						result = id or data.data[1].id
					else
						result = v25
					end
				else
					result = v24
				end
			end

			if not result then
				lib:Notify({ Title = fn3("未找到"), Description = fn3("找不到玩家 ") .. pendingSearch, Time = 3 })
				return
			end
			local v23 = nil

			for _, v24 in arg2, nil, nil do
				if v24.PlayerListing then
					for _, v25 in v24.PlayerListing, nil, nil do
						if tonumber(v25) == result then
							v23 = v24
							break
						end
					end
				end

				if not v23 then
					continue
				end
				break
			end

			if v23 then
				local jobId = v23.JobId or v23.jobId

				if jobId then
					local placeId = game.PlaceId

					pcall(function()
						v3:TeleportToPlaceInstance(placeId, jobId, localPlayer)
					end)

					lib:Notify({ Title = fn3("加入"), Description = fn3("正在传送至服务器..."), Time = 2 })
				else
					lib:Notify({ Title = fn3("错误"), Description = fn3("该服务器缺少 JobId"), Time = 3 })
				end
			else
				lib:Notify({ Title = fn3("未找到"), Description = fn3("玩家 ") .. pendingSearch .. fn3(" 不在任何公开服务器中"), Time = 3 })
			end
		end
	end)

	tbl.serverTracker.initialized = true
end

tbl.serverTracker.init()

v13:AddToggle("AnimPullGateToggle", {
	Text = "拉大门",
	Default = false,
	Tooltip = fn4("拉大门动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			tbl._animPullGate = tbl.startIdleWalk(tbl._animPullGate, "rbxassetid://101487438848164", "rbxassetid://109268182565437", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(tbl._animPullGate)
		end
	end,
})

v13:AddToggle("AnimFakeInjuredToggle", {
	Text = "残血",
	Default = false,
	Tooltip = fn4("静止播放假残血动画，移动播放假残血走路动画"),
	Callback = function(arg)
		if arg then
			tbl._animFakeInjured = tbl.startIdleWalk(tbl._animFakeInjured, "rbxassetid://14970034680", "rbxassetid://15530089342", Enum.AnimationPriority.Idle)
		else
			tbl.stopIdleWalk(tbl._animFakeInjured)
		end
	end,
})

v13:AddToggle("AnimShamblerToggle", {
	Text = "山伯乐",
	Default = false,
	Tooltip = fn4("山伯乐动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			tbl._animShambler = tbl.startIdleWalk(tbl._animShambler, "rbxassetid://12333488814", "rbxassetid://14463730540", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(tbl._animShambler)
		end
	end,
})

v13:AddToggle("AnimRunnerToggle", {
	Text = "红眼",
	Default = false,
	Tooltip = fn4("红眼动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			tbl._animRunner = tbl.startIdleWalk(tbl._animRunner, "rbxassetid://12581784105", "rbxassetid://12581785298", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(tbl._animRunner)
		end
	end,
})

v13:AddToggle("AnimCuirassierToggle", {
	Text = "胸甲骑兵1",
	Default = false,
	Tooltip = fn4("胸甲骑兵动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			tbl._animCuirassier = tbl.startIdleWalk(tbl._animCuirassier, "rbxassetid://87579228279296", "rbxassetid://102081698785465", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(tbl._animCuirassier)
		end
	end,
})

v13:AddToggle("AnimCuirassier2Toggle", {
	Text = "胸甲僵尸2",
	Default = false,
	Tooltip = fn4("静止播放动画，移动播放动画"),
	Callback = function(arg)
		if arg then
			tbl._animCuirassier2 = tbl.startIdleWalk(tbl._animCuirassier2, "rbxassetid://82800474630427", "rbxassetid://118210337289087", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(tbl._animCuirassier2)
		end
	end,
})

v13:AddToggle("AnimCavalryChargeToggle", {
	Text = "胸甲骑兵冲锋快捷栏",
	Default = false,
	Tooltip = fn4("打开小方块快捷栏执行冲锋"),
	Callback = function(arg)
		if arg then
			if _G.cavalryUI then
				_G.cavalryUI:Destroy()
			end

			local v22 = _G
			local v23 = _G

			local CavalryChargeUI, v24 = tbl.createFloatingButton("CavalryChargeUI", "冲", UDim2.new(0.5, -105, 0.3, 0), 24, function()
				task.spawn(_G.cavalryCharge)
			end)

			v22.cavalryUI = CavalryChargeUI
			v23.cavalryBtn = v24
			_G.cavalryPlaying = false

			_G.cavalryCharge = function()
				if _G.cavalryPlaying then
					return
				end
				_G.cavalryPlaying = true

				if _G.cavalryBtn then
					_G.cavalryBtn.Text = "冲锋中"
				end

				local character = localPlayer.Character

				if not character then
					_G.cavalryPlaying = false

					if _G.cavalryBtn then
						_G.cavalryBtn.Text = "冲"
					end

					return
				end

				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if not humanoid then
					_G.cavalryPlaying = false

					if _G.cavalryBtn then
						_G.cavalryBtn.Text = "冲"
					end

					return
				end

				local animator = humanoid:FindFirstChildOfClass("Animator")

				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = humanoid
				end

				for _, v25 in humanoid:GetPlayingAnimationTracks() do
					v25:Stop()
				end

				local function fn8(arg2)
					local animation = Instance.new("Animation")
					animation.AnimationId = "rbxassetid://" .. arg2
					local v25 = animator:LoadAnimation(animation)
					v25.Priority = Enum.AnimationPriority.Action4
					return v25
				end

				local function fn9(arg2, arg3)
					local flag = false

					local connection = arg2.Stopped:Once(function()
						flag = true
					end)

					local v25 = clock2()

					while not flag and arg2.IsPlaying and clock2() - v25 < arg3 do
						task.wait(0.05)
					end

					pcall(function()
						connection:Disconnect()
					end)
				end

				local v25 = fn8("105118183189738")
				local v26 = fn8("17406602570")
				local walkSpeed = humanoid.WalkSpeed
				humanoid.WalkSpeed = 1
				v25:Play()
				fn9(v25, 10)
				if not _G.cavalryPlaying then
					humanoid.WalkSpeed = walkSpeed
					return
				end
				humanoid.WalkSpeed = 28
				v26:Play()
				local n = clock2() + 5

				while true do
					if clock2() < n and v26.IsPlaying then
						task.wait()
						if _G.cavalryPlaying then
							continue
						end
					end

					break
				end

				v26:Stop()
				humanoid.WalkSpeed = walkSpeed
				if not _G.cavalryPlaying then
					return
				end
				local flag = false

				for _, v27 in v4:GetPlayers() do
					if v27 ~= localPlayer and v27.Character then
						local character2 = v27.Character
						local position = humanoid.RootPart.Position
						if (character2:GetPivot().Position - position).Magnitude < 10 then
							flag = true
							break
						end
					end
				end

				local v27 = fn8(flag and "102984581737936" or "139159672489901")

				if not flag then
					humanoid.WalkSpeed = 4
				end

				v27:Play()
				fn9(v27, 15)
				humanoid.WalkSpeed = 16
				_G.cavalryPlaying = false

				if _G.cavalryBtn then
					_G.cavalryBtn.Text = "冲"
				end
			end
		else
			if _G.cavalryUI then
				_G.cavalryUI:Destroy()
				_G.cavalryUI = nil
			end

			_G.cavalryBtn = nil
			_G.cavalryPlaying = false
		end
	end,
})

v13:AddToggle("AnimLanternToggle", {
	Text = "提灯人",
	Default = false,
	Tooltip = fn4("提灯人动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			_G._animLantern = tbl.startIdleWalk(_G._animLantern, "rbxassetid://14678879479", "rbxassetid://14678880308", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(_G._animLantern)
		end
	end,
})

v13:AddToggle("AnimAxeToggle", {
	Text = "斧头僵尸",
	Default = false,
	Tooltip = fn4("斧头僵尸动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			_G._animAxe = tbl.startIdleWalk(_G._animAxe, "rbxassetid://14498563473", "rbxassetid://14498289874", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(_G._animAxe)
		end
	end,
})

v13:AddToggle("AnimAxeSlashToggle", {
	Text = "斧头僵尸劈砍快捷栏",
	Default = false,
	Tooltip = fn4("打开小方块快捷栏执行劈砍"),
	Callback = function(arg)
		if arg then
			if _G.zapperUI then
				_G.zapperUI:Destroy()
			end

			local v22 = _G
			local v23 = _G

			local ZapperEffectUI, v24 = tbl.createFloatingButton("ZapperEffectUI", "劈砍", UDim2.new(0.5, -35, 0.4, 0), 18, function()
				task.spawn(_G.zapperSlash)
			end)

			v22.zapperUI = ZapperEffectUI
			v23.zapperBtn = v24
			_G.zapperBusy = false

			_G.zapperSlash = function()
				if _G.zapperBusy then
					return
				end
				_G.zapperBusy = true

				if _G.zapperBtn then
					_G.zapperBtn.Text = "劈砍中"
				end

				local character = localPlayer.Character

				if not character then
					_G.zapperBusy = false

					if _G.zapperBtn then
						_G.zapperBtn.Text = "劈砍"
					end

					return
				end

				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if not humanoid then
					_G.zapperBusy = false

					if _G.zapperBtn then
						_G.zapperBtn.Text = "劈砍"
					end

					return
				end

				local animator = humanoid:FindFirstChildOfClass("Animator")

				if not animator then
					local animator2 = Instance.new("Animator")
					animator2.Parent = humanoid
					animator = animator2
				end

				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://14499470197"
				local v25 = animator:LoadAnimation(animation)
				v25.Priority = Enum.AnimationPriority.Action4
				v25:Play()

				v25.Stopped:Connect(function()
					_G.zapperBusy = false

					if _G.zapperBtn then
						_G.zapperBtn.Text = "劈砍"
					end
				end)

				task.delay(5, function()
					if _G.zapperBusy then
						_G.zapperBusy = false

						if _G.zapperBtn then
							_G.zapperBtn.Text = "劈砍"
						end
					end
				end)
			end
		else
			if _G.zapperUI then
				_G.zapperUI:Destroy()
				_G.zapperUI = nil
			end

			_G.zapperBtn = nil
			_G.zapperBusy = false
		end
	end,
})

v13:AddToggle("AnimBarrelToggle", {
	Text = "自爆",
	Default = false,
	Tooltip = fn4("自爆动画（待机/行走自动切换）"),
	Callback = function(arg)
		if arg then
			_G._animBarrel = tbl.startIdleWalk(_G._animBarrel, "rbxassetid://13211198049", "rbxassetid://13211207597", Enum.AnimationPriority.Action3)
		else
			tbl.stopIdleWalk(_G._animBarrel)
		end
	end,
})

v13:AddToggle("AnimCrawlerToggle", {
	Text = "爬尸",
	Default = false,
	Tooltip = fn4("爬尸动画（爬行模式）"),
	Callback = function(arg)
		if arg then
			_G._animCrawler = tbl.startIdleWalk(_G._animCrawler, "rbxassetid://13726632691", "rbxassetid://13726634549", Enum.AnimationPriority.Action3, nil, "rbxassetid://130515356351734")
		else
			tbl.stopIdleWalk(_G._animCrawler)
			_G._animCrawler = nil
		end
	end,
})

v13:AddToggle("AnimHeavyChargeToggle", {
	Text = "重剑冲锋",
	Default = false,
	Tooltip = fn4("重剑冲锋动画（开启速度24，关闭速度16）"),
	Callback = function(arg)
		if arg then
			_G._animHeavyCharge = tbl.startIdleWalk(_G._animHeavyCharge, "rbxassetid://14284611111", "rbxassetid://17406602570", Enum.AnimationPriority.Action3, 24)
		else
			tbl.stopIdleWalk(_G._animHeavyCharge, 16)
			_G._animHeavyCharge = nil
		end
	end,
})

v13:AddToggle("AnimMusketChargeToggle", {
	Text = "滑膛枪冲锋",
	Default = false,
	Tooltip = fn4("滑膛枪冲锋动画（开启速度24，关闭速度16）"),
	Callback = function(arg)
		if arg then
			_G._animMusketCharge = tbl.startIdleWalk(_G._animMusketCharge, "rbxassetid://14292935158", "rbxassetid://14292937831", Enum.AnimationPriority.Action3, 24)
		else
			tbl.stopIdleWalk(_G._animMusketCharge, 16)
			_G._animMusketCharge = nil
		end
	end,
})

v13:AddToggle("AnimChargeToggle", {
	Text = "冲锋",
	Default = false,
	Tooltip = fn4("冲锋动画（开启速度24，关闭速度16）"),
	Callback = function(arg)
		if arg then
			_G._animCharge = tbl.startIdleWalk(_G._animCharge, "rbxassetid://14284611111", "rbxassetid://14284623849", Enum.AnimationPriority.Idle, 24)
		else
			tbl.stopIdleWalk(_G._animCharge, 16)
			_G._animCharge = nil
		end
	end,
})

tbl.onCharacterAdded(function()
	task.wait(0.2)

	local function fn8(arg)
		if not arg then
			return
		end

		if arg.idle then
			pcall(function()
				arg.idle:Stop()
			end)
		end

		if arg.walk then
			pcall(function()
				arg.walk:Stop()
			end)
		end

		if arg.sit then
			pcall(function()
				arg.sit:Stop()
			end)
		end

		if arg.conn then
			pcall(function()
				arg.conn:Disconnect()
			end)
		end
	end

	local function fn9(arg)
		local v22 = toggles[arg]

		if v22 and v22.SetValue then
			v22:SetValue(false)
		end
	end

	local tbl6 = {
		{ "_animLantern", "AnimLanternToggle" },
		{ "_animAxe", "AnimAxeToggle" },
		{ "_animBarrel", "AnimBarrelToggle" },
		{ "_animCrawler", "AnimCrawlerToggle" },
		{ "_animHeavyCharge", "AnimHeavyChargeToggle" },
		{ "_animMusketCharge", "AnimMusketChargeToggle" },
		{ "_animCharge", "AnimChargeToggle" },
		{ "boxerCtrl", "AnimBoxerToggle" },
	}

	for _, v22 in {
		{ "_animPullGate", "AnimPullGateToggle" },
		{ "_animFakeInjured", "AnimFakeInjuredToggle" },
		{ "_animShambler", "AnimShamblerToggle" },
		{ "_animRunner", "AnimRunnerToggle" },
		{ "_animCuirassier", "AnimCuirassierToggle" },
		{ "_animCuirassier2", "AnimCuirassier2Toggle" },
	}, nil, nil do
		fn8(tbl[v22[1]])
		tbl[v22[1]] = nil
		fn9(v22[2])
	end

	for _, v22 in tbl6, nil, nil do
		fn8(_G[v22[1]])
		_G[v22[1]] = nil
		fn9(v22[2])
	end
end)

v13:AddToggle("AnimBoxerToggle", {
	Text = "拳击手",
	Default = false,
	Tooltip = fn4("拳击手模式（行走/待机动画 + 左右拳按钮）"),
	Callback = function(arg)
		if arg then
			if _G.boxerActive then
				return
			end
			_G.boxerActive = true
			local character = localPlayer.Character
			if not character then
				_G.boxerActive = false
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				_G.boxerActive = false
				return
			end
			local animator = humanoid:FindFirstChildOfClass("Animator")

			if not animator then
				local animator2 = Instance.new("Animator")
				animator2.Parent = humanoid
				animator = animator2
			end

			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://124381258015151"
			local animation2 = Instance.new("Animation")
			animation2.AnimationId = "rbxassetid://127477273497271"
			local v22 = animator:LoadAnimation(animation)
			local v23 = animator:LoadAnimation(animation2)
			v22.Priority = Enum.AnimationPriority.Action3
			v23.Priority = Enum.AnimationPriority.Action3

			local function fn8()
				if humanoid.MoveDirection.Magnitude > 0 then
					if v23 and not v23.IsPlaying then
						if v22 and v22.IsPlaying then
							v22:Stop()
						end

						v23:Play()
					end
				elseif v22 and not v22.IsPlaying then
					if v23 and v23.IsPlaying then
						v23:Stop()
					end

					v22:Play()
				end
			end

			local connection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(fn8)
			fn8()
			_G.boxerCtrl = { idle = v22, walk = v23, conn = connection }
			humanoid.WalkSpeed = 17
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://0"
			sound.Looped = true
			sound.Volume = 0
			sound.Parent = character:FindFirstChild("Head") or character
			sound:Play()
			_G.boxerSound = sound

			if _G.boxerShowUI == nil or _G.boxerShowUI then
				if _G.boxerUI then
					_G.boxerUI:Destroy()
				end

				_G.boxerUI = Instance.new("ScreenGui")
				_G.boxerUI.Name = "BoxerUI"
				_G.boxerUI.ResetOnSpawn = false
				_G.boxerUI.Parent = localPlayer:WaitForChild("PlayerGui")

				local function createTextButton(text, arg2, backgroundColor3)
					local textButton = Instance.new("TextButton")
					textButton.Size = UDim2.new(0, 60, 0, 60)
					textButton.AnchorPoint = Vector2.new(0.5, 0.5)
					textButton.Position = UDim2.new(arg2, 0, 0.5, 0)
					textButton.BackgroundColor3 = backgroundColor3
					textButton.BackgroundTransparency = 0.2
					textButton.BorderSizePixel = 0
					textButton.Text = text
					textButton.TextColor3 = Color3.new(1, 1, 1)
					textButton.TextSize = 20
					textButton.Font = Enum.Font.GothamBold
					textButton.Draggable = not (_G.boxerFixed == nil or _G.boxerFixed)
					textButton.Active = true
					textButton.Parent = _G.boxerUI
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0, 12)
					uiCorner.Parent = textButton
					local uiStroke = Instance.new("UIStroke")
					uiStroke.Thickness = 2
					uiStroke.Color = color(100, 200, 255)
					uiStroke.Transparency = 0.3
					uiStroke.Parent = textButton
					local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
					uiAspectRatioConstraint.AspectRatio = 1
					uiAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
					uiAspectRatioConstraint.Parent = textButton
					return textButton
				end

				local v24 = createTextButton("左拳", 0.3, color(255, 100, 100))
				local v25 = createTextButton("右拳", 0.7, color(100, 100, 255))

				local function fn9(animationId)
					if not _G.boxerActive then
						return
					end
					local character2 = localPlayer.Character
					if not character2 then
						return
					end
					local humanoid2 = character2:FindFirstChildOfClass("Humanoid")
					if not humanoid2 then
						return
					end
					local animator2 = humanoid2:FindFirstChildOfClass("Animator")

					if not animator2 then
						animator2 = Instance.new("Animator")
						animator2.Parent = humanoid2
					end

					local animation3 = Instance.new("Animation")
					animation3.AnimationId = animationId
					local v26 = animator2:LoadAnimation(animation3)
					v26.Priority = Enum.AnimationPriority.Action4
					v26:Play()

					v26.Stopped:Connect(function()
						animation3:Destroy()
					end)
				end

				v24.MouseButton1Click:Connect(function()
					task.spawn(function()
						fn9("rbxassetid://100609705099226")
					end)
				end)

				v25.MouseButton1Click:Connect(function()
					task.spawn(function()
						fn9("rbxassetid://137400696654354")
					end)
				end)

				_G.boxerUILeft = v24
				_G.boxerUIRight = v25
			end

			if _G.boxerDeathConn then
				_G.boxerDeathConn:Disconnect()
			end

			_G.boxerDeathConn = humanoid.Died:Connect(function()
				if _G.boxerActive then
					_G.boxerActive = false

					if _G.boxerCtrl then
						if _G.boxerCtrl.idle then
							pcall(function()
								_G.boxerCtrl.idle:Stop()
							end)
						end

						if _G.boxerCtrl.walk then
							pcall(function()
								_G.boxerCtrl.walk:Stop()
							end)
						end

						if _G.boxerCtrl.conn then
							pcall(function()
								_G.boxerCtrl.conn:Disconnect()
							end)
						end

						_G.boxerCtrl = nil
					end

					local humanoid2 = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

					if humanoid2 then
						humanoid2.WalkSpeed = 16
					end

					if _G.boxerSound then
						_G.boxerSound:Stop()
						_G.boxerSound:Destroy()
						_G.boxerSound = nil
					end

					if _G.boxerUI then
						_G.boxerUI:Destroy()
						_G.boxerUI = nil
					end

					_G.boxerUILeft = nil
					_G.boxerUIRight = nil

					if _G.boxerDeathConn then
						_G.boxerDeathConn:Disconnect()
						_G.boxerDeathConn = nil
					end
				end
			end)
		else
			_G.boxerActive = false

			if _G.boxerCtrl then
				if _G.boxerCtrl.idle then
					pcall(function()
						_G.boxerCtrl.idle:Stop()
					end)
				end

				if _G.boxerCtrl.walk then
					pcall(function()
						_G.boxerCtrl.walk:Stop()
					end)
				end

				if _G.boxerCtrl.conn then
					pcall(function()
						_G.boxerCtrl.conn:Disconnect()
					end)
				end

				_G.boxerCtrl = nil
			end

			local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				humanoid.WalkSpeed = 16
			end

			if _G.boxerSound then
				_G.boxerSound:Stop()
				_G.boxerSound:Destroy()
				_G.boxerSound = nil
			end

			if _G.boxerUI then
				_G.boxerUI:Destroy()
				_G.boxerUI = nil
			end

			_G.boxerUILeft = nil
			_G.boxerUIRight = nil

			if _G.boxerDeathConn then
				_G.boxerDeathConn:Disconnect()
				_G.boxerDeathConn = nil
			end
		end
	end,
})

v13:AddToggle("AnimBoxerFixedToggle", {
	Text = "固定按钮",
	Default = true,
	Tooltip = fn4("拳击按钮不可拖动"),
	Callback = function(boxerFixed)
		_G.boxerFixed = boxerFixed

		if _G.boxerUILeft and _G.boxerUIRight then
			local draggable = not boxerFixed
			_G.boxerUILeft.Draggable = draggable
			_G.boxerUIRight.Draggable = draggable
		end
	end,
})

v13:AddToggle("AnimBoxerUIToggle", {
	Text = "显示拳击 UI",
	Default = true,
	Tooltip = fn4("显示/隐藏拳击按钮界面"),
	Callback = function(boxerShowUI)
		_G.boxerShowUI = boxerShowUI

		if _G.boxerActive then
			if boxerShowUI then
				if not _G.boxerUI then
					if not localPlayer.Character then
						return
					end
					_G.boxerUI = Instance.new("ScreenGui")
					_G.boxerUI.Name = "BoxerUI"
					_G.boxerUI.ResetOnSpawn = false
					_G.boxerUI.Parent = localPlayer:WaitForChild("PlayerGui")

					local function createTextButton(text, arg, backgroundColor3)
						local textButton = Instance.new("TextButton")
						textButton.Size = UDim2.new(0, 60, 0, 60)
						textButton.AnchorPoint = Vector2.new(0.5, 0.5)
						textButton.Position = UDim2.new(arg, 0, 0.5, 0)
						textButton.BackgroundColor3 = backgroundColor3
						textButton.BackgroundTransparency = 0.2
						textButton.BorderSizePixel = 0
						textButton.Text = text
						textButton.TextColor3 = Color3.new(1, 1, 1)
						textButton.TextSize = 20
						textButton.Font = Enum.Font.GothamBold
						textButton.Draggable = not (_G.boxerFixed == nil or _G.boxerFixed)
						textButton.Active = true
						textButton.Parent = _G.boxerUI
						local uiCorner = Instance.new("UICorner")
						uiCorner.CornerRadius = UDim.new(0, 12)
						uiCorner.Parent = textButton
						local uiStroke = Instance.new("UIStroke")
						uiStroke.Thickness = 2
						uiStroke.Color = color(100, 200, 255)
						uiStroke.Transparency = 0.3
						uiStroke.Parent = textButton
						local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
						uiAspectRatioConstraint.AspectRatio = 1
						uiAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
						uiAspectRatioConstraint.Parent = textButton
						return textButton
					end

					local v22 = createTextButton("左拳", 0.3, color(255, 100, 100))
					local v23 = createTextButton("右拳", 0.7, color(100, 100, 255))

					local function fn8(animationId)
						if not _G.boxerActive then
							return
						end
						local character = localPlayer.Character
						if not character then
							return
						end
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if not humanoid then
							return
						end
						local animator = humanoid:FindFirstChildOfClass("Animator")

						if not animator then
							animator = Instance.new("Animator")
							animator.Parent = humanoid
						end

						local animation = Instance.new("Animation")
						animation.AnimationId = animationId
						local v24 = animator:LoadAnimation(animation)
						v24.Priority = Enum.AnimationPriority.Action4
						v24:Play()

						v24.Stopped:Connect(function()
							animation:Destroy()
						end)
					end

					v22.MouseButton1Click:Connect(function()
						task.spawn(function()
							fn8("rbxassetid://100609705099226")
						end)
					end)

					v23.MouseButton1Click:Connect(function()
						task.spawn(function()
							fn8("rbxassetid://137400696654354")
						end)
					end)

					_G.boxerUILeft = v22
					_G.boxerUIRight = v23
				end

				_G.boxerUI.Enabled = true
			elseif _G.boxerUI then
				_G.boxerUI.Enabled = false
			end
		end
	end,
})

do
	local v22 = tbl3.Main:AddGroupbox({ Side = "Right", Name = "杀戮光环", IconName = "circle-dot", Description = "自动攻击" })
	local str2 = "工兵"

	v22:AddDropdown("AuraMode", {
		Values = { "工兵", "防封" },
		Default = 1,
		Multi = false,
		Text = "杀戮光环模式",
		Tooltip = fn4("选择杀戮光环模式（实时切换）"),
		Callback = function(arg)
			str2 = arg

			if auraMasterEnabled then
				if tbl.auraEnabled then
					tbl.stopAura()
				end

				if tbl.qingShuiAura and tbl.qingShuiAura.enabled then
					tbl.stopQingShuiAura()
				end

				if str2 == "工兵" then
					tbl.startAura()
				elseif str2 == "防封" then
					tbl.startQingShuiAura()
				end
			end
		end,
	})

	v22:AddDivider()

	v22:AddToggle("AuraToggle", {
		Text = "开启杀戮光环",
		Default = false,
		Tooltip = fn4("开启/关闭杀戮光环（根据下拉框选择的模式）"),
		Callback = function(arg)
			auraMasterEnabled = arg

			if tbl.auraEnabled then
				tbl.stopAura()
			end

			if tbl.qingShuiAura and tbl.qingShuiAura.enabled then
				tbl.stopQingShuiAura()
			end

			if arg then
				if str2 == "工兵" then
					tbl.startAura()
				elseif str2 == "防封" then
					tbl.startQingShuiAura()
				end

				tbl.startIndicatorUpdater()
			else
				tbl.stopIndicatorUpdater()
			end
		end,
	})
end

local v22 = tbl3.Main:AddGroupbox({ Side = "Left", Name = "飞行功能", IconName = "plane", Description = "飞行控制" })

v22:AddButton({
	Text = "飞行-无相机锁定",
	Func = function()
		tbl.FlyOriginal()
	end,
})

v22:AddButton({
	Text = "飞行-优化",
	Func = function()
		tbl.FlyNew()
	end,
})

v22:AddDivider()
v22:AddLabel("飞行-传送", true)

v22:AddToggle("WarpFlyToggle", {
	Text = "飞行-传送",
	Default = false,
	Tooltip = fn4("WASD移动，Space上升，LCtrl下降。"),
	Callback = function(arg)
		if arg then
			tbl.warpFly.start()
		else
			tbl.warpFly.stop()
		end
	end,
})

v22:AddLabel("飞行-传送 快捷键"):AddKeyPicker("WarpFlyKeybind", {
	Default = "F",
	NoUI = false,
	Text = "飞行-传送 开关",
	Callback = function()
		local warpFlyToggle = toggles.WarpFlyToggle
		warpFlyToggle:SetValue(not warpFlyToggle.Value)
	end,
})

v22:AddSlider("WarpFlySpeed", {
	Text = "飞行速度",
	Default = 35,
	Min = 10,
	Max = 200,
	Rounding = 0,
	Compact = false,
	Callback = function(flySpeed)
		tbl.warpFly.flySpeed = flySpeed
	end,
})

v22:AddButton({
	Text = "飞行-动画",
	Func = function()
		tbl.FlyAnimation()
	end,
})

v22:AddDivider()
v22:AddLabel("自由视角传送", true)

v22:AddToggle("TPFreecamToggle", {
	Text = "自由视角",
	Default = false,
	Tooltip = fn4("自由视角锚定角色，原生视角跟随鼠标/触摸"),
	Callback = function(arg)
		if arg then
			tbl.tpFreecam.start()
		else
			tbl.tpFreecam.stop()
		end
	end,
})

v22:AddLabel("自由视角传送 快捷键"):AddKeyPicker("TPFreecamKeybind", {
	Default = "G",
	NoUI = false,
	Text = "自由视角 开关",
	Callback = function()
		local tpFreecamToggle = toggles.TPFreecamToggle
		tpFreecamToggle:SetValue(not tpFreecamToggle.Value)
	end,
})

v22:AddSlider("TPFreecamSpeed", {
	Text = "视角速度",
	Default = 50,
	Min = 5,
	Max = 150,
	Rounding = 0,
	Compact = false,
	Callback = function(speed)
		tbl.tpFreecam.speed = speed
	end,
})

v22:AddButton({
	Text = "传送到视角",
	Func = function()
		tbl.tpFreecam.tpToCamera()
	end,
	Tooltip = fn4("将角色传送到当前视角位置"),
})

v22:AddInput("TPFreecamName", {
	Default = "",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = false,
	Text = "保存位置",
	Tooltip = fn4("保存当前视角或位置"),
	Placeholder = "输入名字",
	Callback = function()
	end,
})

v22:AddButton({
	Text = "保存位置",
	Func = function()
		tbl.tpFreecam.saveFromInput()
	end,
	Tooltip = fn4("保存当前视角或位置"),
})

v22:AddDropdown("TPFreecamPoints", {
	Text = "存档点",
	Values = {},
	Tooltip = fn4("选择已保存的位置"),
	Callback = function(selected)
		tbl.tpFreecam.selected = selected
	end,
})

v22:AddButton({
	Text = "传送到存档点",
	Func = function()
		tbl.tpFreecam.tpToSelected()
	end,
})

v22:AddButton({
	Text = "删除存档点",
	Func = function()
		tbl.tpFreecam.deleteSelected()
	end,
})

v22:AddButton({
	Text = "清空存档点",
	Func = function()
		tbl.tpFreecam.clearPoints()
	end,
})

v22:AddLabel("WASD/摇杆移动，空格/跳跃键上升，Ctrl下降。")

tbl.FlyOriginal = function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/wzhxll/stjnr/refs/heads/main/README.md"))()
end

tbl.FlyNew = function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/wzhxll/Sha-Bi/refs/heads/main/README.md"))()
end

tbl.warpFly = {
	enabled = false,
	flySpeed = 35,
	hrp = nil,
	head = nil,
	hum = nil,
	serverPos = nil,
	isNoclipping = false,
	microStepConn = nil,
	healthLockConn = nil,
	diedConn = nil,
	originalCanCollide = {},
	descendantConnection = nil,
	_tmp = {},
}

tbl.warpFly.detectWall = function()
	local hrp = tbl.warpFly.hrp
	if not hrp then
		return false
	end
	local position = hrp.Position
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { v4.LocalPlayer.Character }

	for i = 1, 12 do
		local n = i / 12 * 2 * 3.1415926535897931
		local v23 = math.cos(n)
		local v24 = math.sin(n)

		for i2 = -1, 1 do
			local hit = workspace:Raycast(position, vector(v23, i2 * 0.5, v24).Unit * 3.5, raycastParams)

			if hit then
				local instance = hit.Instance
				if instance and instance.CanCollide and instance.Transparency < 0.9 then
					return true
				end
			end
		end
	end

	return false
end

tbl.warpFly.enterNoClip = function()
	if tbl.warpFly.isNoclipping then
		return
	end

	if not tbl.warpFly.head or not tbl.warpFly.hrp or not tbl.warpFly.hum then
		return
	end
	tbl.warpFly.head.Anchored = true
	tbl.warpFly.hum.PlatformStand = true
	tbl.warpFly.isNoclipping = true
end

tbl.warpFly.exitNoClip = function()
	if not tbl.warpFly.isNoclipping then
		return
	end

	if not tbl.warpFly.head or not tbl.warpFly.hrp or not tbl.warpFly.hum then
		tbl.warpFly.isNoclipping = false
		return
	end
	tbl.warpFly.head.Anchored = false
	tbl.warpFly.hum.PlatformStand = false
	tbl.warpFly.isNoclipping = false
end

tbl.warpFly.clear = function()
	pcall(function()
		for k, v23 in tbl.warpFly.originalCanCollide, nil, nil do
			if k and k.Parent then
				k.CanCollide = v23
			end
		end

		table.clear(tbl.warpFly.originalCanCollide)

		if tbl.warpFly.descendantConnection then
			tbl.warpFly.descendantConnection:Disconnect()
			tbl.warpFly.descendantConnection = nil
		end

		if tbl.warpFly.microStepConn then
			task.cancel(tbl.warpFly.microStepConn)
			tbl.warpFly.microStepConn = nil
		end

		if tbl.warpFly.healthLockConn then
			task.cancel(tbl.warpFly.healthLockConn)
			tbl.warpFly.healthLockConn = nil
		end

		if tbl.warpFly.diedConn then
			tbl.warpFly.diedConn:Disconnect()
			tbl.warpFly.diedConn = nil
		end

		if tbl.warpFly.isNoclipping then
			tbl.warpFly.exitNoClip()
		end

		if tbl.warpFly.hrp and tbl.warpFly.hum then
			tbl.warpFly.hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

tbl.warpFly.microStepLoop = function()
	if not tbl.warpFly.hrp then
		return
	end
	tbl.warpFly._tmp.targetPos = tbl.warpFly.hrp.Position
	tbl.warpFly._tmp.lastTime = clock()

	while tbl.warpFly.enabled do
		if not tbl.warpFly.hrp or not tbl.warpFly.hrp.Parent or not tbl.warpFly.hum or not tbl.warpFly.hum.Parent then
			tbl.warpFly.stop()
			break
		else
			tbl.warpFly._tmp.now = clock()
			tbl.warpFly._tmp.dt = tbl.warpFly._tmp.now - tbl.warpFly._tmp.lastTime
			tbl.warpFly._tmp.lastTime = tbl.warpFly._tmp.now
			local v23 = tbl.warpFly.detectWall()

			if v23 and not tbl.warpFly.isNoclipping then
				tbl.warpFly.enterNoClip()
			elseif not v23 and tbl.warpFly.isNoclipping then
				tbl.warpFly.exitNoClip()
			end

			if not tbl.ControlModule then
				task.wait(0.1)
			else
				tbl.warpFly._tmp.mv = tbl.ControlModule:GetMoveVector()
				tbl.warpFly._tmp.cf = workspace.CurrentCamera.CFrame
				tbl.warpFly._tmp.moveDir = tbl.warpFly._tmp.cf.LookVector * -tbl.warpFly._tmp.mv.Z + tbl.warpFly._tmp.cf.RightVector * tbl.warpFly._tmp.mv.X
				tbl.warpFly._tmp.vertical = 0

				if v6:IsKeyDown(Enum.KeyCode.Space) then
					tbl.warpFly._tmp.vertical = 1
				elseif v6:IsKeyDown(Enum.KeyCode.LeftControl) then
					tbl.warpFly._tmp.vertical = -1
				end

				local flySpeed = tbl.warpFly.flySpeed
				tbl.warpFly._tmp.totalDelta = (tbl.warpFly._tmp.moveDir + vector(0, tbl.warpFly._tmp.vertical, 0)) * flySpeed * tbl.warpFly._tmp.dt
				tbl.warpFly._tmp.targetPos = tbl.warpFly._tmp.targetPos + tbl.warpFly._tmp.totalDelta
				tbl.warpFly._tmp.currentPos = tbl.warpFly.hrp.Position
				tbl.warpFly._tmp.remaining = tbl.warpFly._tmp.targetPos - tbl.warpFly._tmp.currentPos
				tbl.warpFly._tmp.distance = tbl.warpFly._tmp.remaining.Magnitude

				if tbl.warpFly._tmp.distance > 0 then
					tbl.warpFly._tmp.steps = ceil(tbl.warpFly._tmp.distance / 10)
					tbl.warpFly._tmp.stepVec = tbl.warpFly._tmp.remaining / tbl.warpFly._tmp.steps

					for i = 1, tbl.warpFly._tmp.steps do
						if tbl.warpFly.enabled then
							tbl.warpFly._tmp.currentPos = tbl.warpFly._tmp.currentPos + tbl.warpFly._tmp.stepVec
							local rotation = tbl.warpFly.hrp.CFrame.Rotation
							tbl.warpFly.hrp.CFrame = cframe(tbl.warpFly._tmp.currentPos) * rotation
							continue
						end

						break
					end
				else
					local rotation = tbl.warpFly.hrp.CFrame.Rotation
					tbl.warpFly.hrp.CFrame = cframe(tbl.warpFly._tmp.targetPos) * rotation
				end

				tbl.warpFly.hrp.AssemblyLinearVelocity = Vector3.zero
				tbl.warpFly.enabled = true
				tbl.warpFly.hum:ChangeState(Enum.HumanoidStateType.Climbing)
				task.wait()
			end
		end
	end
end

tbl.warpFly.healthLockLoop = function()
	while tbl.warpFly.enabled do
		if tbl.warpFly.hum and tbl.warpFly.hum.Health <= 0 then
			tbl.warpFly.hum.Health = tbl.warpFly.hum.MaxHealth
		end

		task.wait(0.1)
	end
end

tbl.warpFly.onDied = function()
	if tbl.warpFly.hum and tbl.warpFly.enabled then
		tbl.warpFly.hum.Health = tbl.warpFly.hum.MaxHealth
		tbl.warpFly.hum:ChangeState(Enum.HumanoidStateType.Running)

		pcall(function()
			tbl.warpFly.hum.Parent = v4.LocalPlayer.Character
		end)
	end
end

tbl.warpFly.start = function()
	if tbl.warpFly.enabled then
		return
	end

	if tbl.tpFreecam and tbl.tpFreecam.active then
		tbl.tpFreecam.stop()
	end

	tbl.warpFly._tmp.char = v4.LocalPlayer.Character
	if not tbl.warpFly._tmp.char then
		return
	end
	tbl.warpFly.hrp = tbl.warpFly._tmp.char:FindFirstChild("HumanoidRootPart")
	tbl.warpFly.head = tbl.warpFly._tmp.char:FindFirstChild("Head")
	tbl.warpFly.hum = tbl.warpFly._tmp.char:FindFirstChild("Humanoid")
	if not tbl.warpFly.hrp or not tbl.warpFly.head or not tbl.warpFly.hum then
		return
	end

	for _, v23 in tbl.warpFly._tmp.char:GetDescendants() do
		if v23:IsA("BasePart") and tbl.warpFly.originalCanCollide[v23] == nil then
			tbl.warpFly.originalCanCollide[v23] = v23.CanCollide
			v23.CanCollide = false
		end
	end

	tbl.warpFly.descendantConnection = tbl.warpFly._tmp.char.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and tbl.warpFly.originalCanCollide[descendant] == nil then
			tbl.warpFly.originalCanCollide[descendant] = descendant.CanCollide
			descendant.CanCollide = false
		end
	end)

	tbl.warpFly.enabled = true
	tbl.warpFly.isNoclipping = false
	tbl.warpFly.hum:ChangeState(Enum.HumanoidStateType.Climbing)
	tbl.warpFly.microStepConn = task.spawn(tbl.warpFly.microStepLoop)
	tbl.warpFly.healthLockConn = task.spawn(tbl.warpFly.healthLockLoop)
	tbl.warpFly.diedConn = tbl.warpFly.hum.Died:Connect(tbl.warpFly.onDied)
end

tbl.warpFly.stop = function()
	tbl.warpFly.enabled = false
	tbl.warpFly.clear()

	if toggles.WarpFlyToggle and toggles.WarpFlyToggle.Value then
		toggles.WarpFlyToggle:SetValue(false)
	end
end

tbl.warpFly.teleportAndFly = function(arg)
	tbl.warpFly.start()
	tbl.warpFly._tmp.char = v4.LocalPlayer.Character

	if tbl.warpFly._tmp.char then
		local humanoidRootPart = tbl.warpFly._tmp.char:FindFirstChild("HumanoidRootPart")

		if humanoidRootPart then
			humanoidRootPart.CFrame = cframe(arg + Vector3.new(0, 5, 0))
		end
	end

	task.delay(0.5, function()
		tbl.warpFly.stop()
	end)
end

tbl.tpFreecam = {
	active = false,
	speed = 50,
	selected = nil,
	saved = {},
	nameList = {},
	conns = {},
	listenersInstalled = false,
	circle = nil,
	soul = nil,
	hoverPos = Vector3.zero,
	oldCamType = nil,
	oldCamSubject = nil,
	origCollide = {},
	jumpUpUntil = 0,
	moveDir = Vector3.zero,
}

local n = 0.1
tbl.tpFreecam.saved = {}

pcall(function()
	if getgenv then
		getgenv().TPFreecamSaves = nil
		local cleanup = tbl.tpFreecam.cleanup
		getgenv().TPFreecamCleanup = cleanup
	end
end)

tbl.tpFreecam.getChar = function()
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not humanoidRootPart then
		return nil
	end
	return character, humanoid, humanoidRootPart
end

tbl.tpFreecam.setNoclip = function(arg)
	for _, v23 in arg:GetDescendants() do
		if v23:IsA("BasePart") then
			if tbl.tpFreecam.origCollide[v23] == nil then
				tbl.tpFreecam.origCollide[v23] = v23.CanCollide
			end

			v23.CanCollide = false
		end
	end
end

tbl.tpFreecam.restoreCollision = function()
	for k, v23 in tbl.tpFreecam.origCollide, nil, nil do
		if k and k.Parent then
			pcall(function()
				k.CanCollide = v23
			end)
		end
	end

	table.clear(tbl.tpFreecam.origCollide)
end

tbl.tpFreecam.setCircleVisible = function(arg)
	if tbl.tpFreecam.circle then
		pcall(function()
			tbl.tpFreecam.circle.Visible = (arg and tbl.tpFreecam.active) == true
		end)
	end
end

tbl.tpFreecam.restoreWorld = function()
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	character = character and character:FindFirstChild("HumanoidRootPart")
	local currentCamera = workspace.CurrentCamera

	if currentCamera then
		currentCamera.CameraType = tbl.tpFreecam.oldCamType or Enum.CameraType.Custom

		if humanoid then
			currentCamera.CameraSubject = humanoid
		elseif tbl.tpFreecam.oldCamSubject then
			currentCamera.CameraSubject = tbl.tpFreecam.oldCamSubject
		end
	end

	if character then
		character.Anchored = false
	end

	tbl.tpFreecam.restoreCollision()

	if tbl.tpFreecam.soul then
		pcall(function()
			tbl.tpFreecam.soul:Destroy()
		end)

		tbl.tpFreecam.soul = nil
	end

	pcall(function()
		if v6.MouseBehavior ~= Enum.MouseBehavior.Default then
			v6.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
end

tbl.tpFreecam.start = function()
	if tbl.tpFreecam.active then
		return
	end
	local v23, v24, v25 = tbl.tpFreecam.getChar()
	if not v23 then
		return
	end
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		return
	end

	if toggles.WarpFlyToggle and toggles.WarpFlyToggle.Value then
		toggles.WarpFlyToggle:SetValue(false)
	end

	tbl.tpFreecam.oldCamType = currentCamera.CameraType
	tbl.tpFreecam.oldCamSubject = currentCamera.CameraSubject
	tbl.tpFreecam.active = true
	v25.Anchored = true
	v25.AssemblyLinearVelocity = Vector3.zero
	v25.AssemblyAngularVelocity = Vector3.zero
	local part = Instance.new("Part")
	part.Name = "TPFreecamSoul"
	part.Size = Vector3.one
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Position = currentCamera.CFrame.Position
	part.Parent = workspace
	tbl.tpFreecam.soul = part
	tbl.tpFreecam.hoverPos = part.Position
	currentCamera.CameraType = Enum.CameraType.Custom
	currentCamera.CameraSubject = part
	tbl.tpFreecam.installListeners()
	tbl.tpFreecam.setCircleVisible(true)
end

tbl.tpFreecam.stop = function()
	if not tbl.tpFreecam.active then
		return
	end
	tbl.tpFreecam.active = false
	tbl.tpFreecam.moveDir = Vector3.zero
	tbl.tpFreecam.restoreWorld()
	tbl.tpFreecam.setCircleVisible(false)
	local tpFreecamToggle = toggles.TPFreecamToggle

	if tpFreecamToggle and tpFreecamToggle.Value then
		tpFreecamToggle:SetValue(false)
	end
end

tbl.tpFreecam.tpTo = function(cFrame)
	if not cFrame then
		return
	end
	local v23, v24, v25 = tbl.tpFreecam.getChar()
	if not v23 then
		return
	end
	v25.Anchored = true
	tbl.tpFreecam.setNoclip(v23)
	task.wait()
	v25.CFrame = cFrame
	local currentCamera = workspace.CurrentCamera

	if tbl.tpFreecam.active and currentCamera then
		currentCamera.CFrame = cFrame
	end

	task.wait()

	if not tbl.tpFreecam.active then
		v25.Anchored = false
		tbl.tpFreecam.restoreCollision()
	end
end

tbl.tpFreecam.tpToCamera = function()
	local currentCamera = workspace.CurrentCamera

	if currentCamera then
		tbl.tpFreecam.tpTo(currentCamera.CFrame)
	end
end

tbl.tpFreecam.pointNames = function()
	local tbl6 = {}

	for k, v23 in tbl.tpFreecam.saved, nil, nil do
		if v23 and v23.CFrame then
			local position = v23.CFrame.Position
			local n2 = #tbl6 + 1
			local x = position.X
			local y = position.Y
			local z = position.Z
			tbl6[n2] = format("%d. %s (%.0f,%.0f,%.0f)", k, tostring(v23.Name), x, y, z)
		end
	end

	return tbl6
end

tbl.tpFreecam.refreshDropdown = function()
	local tpFreecamPoints = options.TPFreecamPoints
	if not tpFreecamPoints then
		return
	end
	local v23 = tbl.tpFreecam.pointNames()
	tbl.tpFreecam.nameList = v23
	tpFreecamPoints:SetValues(v23)

	if #v23 > 0 then
		local selected = tbl.tpFreecam.selected
		local flag = false

		for _, v24 in v23, nil, nil do
			if v24 == selected then
				flag = true
				break
			end
		end

		if not flag then
			tbl.tpFreecam.selected = v23[1]
		end

		tpFreecamPoints:SetValue(tbl.tpFreecam.selected)
	else
		tbl.tpFreecam.selected = nil
	end
end

tbl.tpFreecam.saveCurrent = function(arg)
	local currentCamera = workspace.CurrentCamera
	local cFrame

	if tbl.tpFreecam.active and currentCamera then
		cFrame = currentCamera.CFrame
	else
		local v23, v24, v25 = tbl.tpFreecam.getChar()
		cFrame = nil

		if v25 then
			cFrame = v25.CFrame
		end

		if not cFrame and currentCamera then
			cFrame = currentCamera.CFrame
		end
	end

	if not cFrame then
		return
	end
	local str2 = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")

	if str2 == "" then
		str2 = "Pos" .. tostring(#tbl.tpFreecam.saved + 1)
	end

	table.insert(tbl.tpFreecam.saved, { Name = str2, CFrame = cFrame })
	tbl.tpFreecam.refreshDropdown()
	tbl.notify(fn3("保存位置"), 2)
end

tbl.tpFreecam.saveFromInput = function()
	local tpFreecamName = options.TPFreecamName
	tbl.tpFreecam.saveCurrent(tpFreecamName and tpFreecamName.Value or "")

	if tpFreecamName and tpFreecamName.SetValue then
		pcall(function()
			tpFreecamName:SetValue("")
		end)
	end
end

tbl.tpFreecam.tpToSelected = function()
	local selected = tbl.tpFreecam.selected
	if not selected then
		return
	end

	for k, v23 in tbl.tpFreecam.nameList, nil, nil do
		if v23 == selected then
			local v24 = tbl.tpFreecam.saved[k]

			if v24 and v24.CFrame then
				tbl.tpFreecam.tpTo(v24.CFrame)
			end

			return
		end
	end
end

tbl.tpFreecam.deleteSelected = function()
	local selected = tbl.tpFreecam.selected
	if not selected then
		return
	end

	for k, v23 in tbl.tpFreecam.nameList, nil, nil do
		if v23 == selected then
			table.remove(tbl.tpFreecam.saved, k)
			tbl.tpFreecam.refreshDropdown()
			return
		end
	end
end

tbl.tpFreecam.clearPoints = function()
	table.clear(tbl.tpFreecam.saved)
	tbl.tpFreecam.refreshDropdown()
end

tbl.tpFreecam.getControls = function()
	local controlModule = tbl.ControlModule
	if controlModule and controlModule.GetMoveVector then
		return controlModule
	end

	pcall(function()
		local playerScripts = localPlayer:FindFirstChildOfClass("PlayerScripts")
		local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")

		if playerModule then
			controlModule = require(playerModule):GetControls()

			if controlModule and controlModule.GetMoveVector then
				tbl.ControlModule = controlModule
			end
		end
	end)

	return tbl.ControlModule
end

tbl.tpFreecam.updateMoveDir = function()
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		tbl.tpFreecam.moveDir = Vector3.zero
		return
	end
	local lookVector = currentCamera.CFrame.LookVector
	local rightVector = currentCamera.CFrame.RightVector
	local vector3 = Vector3.zero

	if v6:IsKeyDown(Enum.KeyCode.W) then
		vector3 = Vector3.zero + lookVector
	end

	if v6:IsKeyDown(Enum.KeyCode.S) then
		vector3 -= lookVector
	end

	if v6:IsKeyDown(Enum.KeyCode.A) then
		vector3 -= rightVector
	end

	if v6:IsKeyDown(Enum.KeyCode.D) then
		vector3 += rightVector
	end

	if v6:IsKeyDown(Enum.KeyCode.Space) or v6:IsKeyDown(Enum.KeyCode.E) then
		vector3 += Vector3.new(0, 1, 0)
	end

	if v6:IsKeyDown(Enum.KeyCode.LeftControl) or v6:IsKeyDown(Enum.KeyCode.Q) then
		vector3 -= Vector3.new(0, 1, 0)
	end

	if vector3.Magnitude < 0.1 and v6.TouchEnabled then
		local v23 = tbl.tpFreecam.getControls()

		if v23 then
			local ok, result = pcall(function()
				return v23:GetMoveVector()
			end)

			if ok and typeof(result) == "Vector3" and result.Magnitude > 0.1 then
				vector3 += rightVector * result.X + lookVector * -result.Z
			end
		end
	end

	if clock2() < (tbl.tpFreecam.jumpUpUntil or 0) then
		vector3 += Vector3.new(0, 1, 0)
	end

	if vector3.Magnitude > 0.1 then
		tbl.tpFreecam.moveDir = vector3.Unit * tbl.tpFreecam.speed
	else
		tbl.tpFreecam.moveDir = Vector3.zero
	end
end

tbl.tpFreecam.onHeartbeat = function(arg)
	local n2 = type(arg) == "number" and arg <= 0.1 and arg or 0.016
	local currentCamera = workspace.CurrentCamera

	if tbl.tpFreecam.circle and currentCamera then
		pcall(function()
			tbl.tpFreecam.circle.Position = currentCamera.ViewportSize / 2
		end)
	end

	if not tbl.tpFreecam.active then
		return
	end
	tbl.tpFreecam.updateMoveDir()
	local soul = tbl.tpFreecam.soul

	if soul and soul.Parent then
		pcall(function()
			if tbl.tpFreecam.moveDir.Magnitude > n then
				soul.CFrame = soul.CFrame + tbl.tpFreecam.moveDir * n2
				tbl.tpFreecam.hoverPos = soul.Position
			else
				local rotation = soul.CFrame.Rotation
				soul.CFrame = cframe(tbl.tpFreecam.hoverPos) * rotation
			end
		end)
	end
end

tbl.tpFreecam.installListeners = function()
	if tbl.tpFreecam.listenersInstalled then
		return
	end
	tbl.tpFreecam.listenersInstalled = true

	pcall(function()
		if Drawing and not tbl.tpFreecam.circle then
			local circle = Drawing.new("Circle")
			circle.Visible = false
			circle.Radius = 25
			circle.Thickness = 2
			circle.Filled = false
			circle.Transparency = 1
			circle.Color = color(0, 255, 0)
			tbl.tpFreecam.circle = circle
		end
	end)

	table.insert(tbl.tpFreecam.conns, v5.Heartbeat:Connect(function(deltaTime)
		tbl.tpFreecam.onHeartbeat(deltaTime)
	end))

	table.insert(tbl.tpFreecam.conns, v6.JumpRequest:Connect(function()
		if not tbl.tpFreecam.active then
			return
		end
		tbl.tpFreecam.jumpUpUntil = clock2() + 0.3
	end))
end

tbl.tpFreecam.cleanup = function()
	tbl.tpFreecam.active = false
	tbl.tpFreecam.restoreWorld()

	for _, v23 in tbl.tpFreecam.conns, nil, nil do
		pcall(function()
			v23:Disconnect()
		end)
	end

	table.clear(tbl.tpFreecam.conns)
	tbl.tpFreecam.listenersInstalled = false

	if tbl.tpFreecam.circle then
		pcall(function()
			tbl.tpFreecam.circle:Remove()
		end)

		tbl.tpFreecam.circle = nil
	end

	pcall(function()
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		local tpFreecamGui = playerGui and playerGui:FindFirstChild("TPFreecamGui")

		if tpFreecamGui then
			tpFreecamGui:Destroy()
		end
	end)

	pcall(function()
		local flag = getgenv

		if flag then
			local cleanup = tbl.tpFreecam.cleanup
			flag = getgenv().TPFreecamCleanup == cleanup
		end

		if flag then
			getgenv().TPFreecamCleanup = nil
		end
	end)
end

tbl.onCharacterAdded(function()
	if tbl.tpFreecam.active then
		tbl.tpFreecam.stop()
	end
end)

pcall(function()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	playerGui = playerGui and playerGui:FindFirstChild("TPFreecamGui")

	if playerGui then
		playerGui:Destroy()
	end
end)

pcall(function()
	if v6.MouseBehavior ~= Enum.MouseBehavior.Default then
		v6.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

pcall(function()
	local flag = getgenv and type(getgenv().TPFreecamCleanup) == "function"

	if flag then
		local cleanup = tbl.tpFreecam.cleanup
		flag = getgenv().TPFreecamCleanup ~= cleanup
	end

	if flag then
		getgenv().TPFreecamCleanup()
	end
end)

tbl.tpFreecam.refreshDropdown()

tbl.FlyAnimation = function()
	loadstring([[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ControlModule = require(lp.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local HOVER_ANIM_ID = "rbxassetid://97171309"

local flight = {
    isFlying = false,
    flySpeed = 40,
    bv = nil,
    animCache = nil,
    hrp = nil,
    hum = nil,
    hoverTrack = nil,
    animator = nil,
}

function flight:loadAndFreezeHover()
    if not self.hum then return end
    self.animator = self.hum:FindFirstChildOfClass("Animator")
    if not self.animator then
        self.animator = Instance.new("Animator")
        self.animator.Parent = self.hum
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = HOVER_ANIM_ID
    self.hoverTrack = self.animator:LoadAnimation(anim)
    self.hoverTrack.Priority = Enum.AnimationPriority.Action4
    self.hoverTrack:Play()
    self.hoverTrack:AdjustSpeed(0)
end

function flight:clearResources()
    local char = lp.Character
    if self.animCache and char then
        self.animCache.Parent = char
    end
    if self.bv then
        self.bv:Destroy()
        self.bv = nil
    end
    if self.lvAttachment then
        self.lvAttachment:Destroy()
        self.lvAttachment = nil
    end
    if self.hoverTrack then
        self.hoverTrack:Stop()
        self.hoverTrack = nil
    end
    if self.hum and self.hum.Parent then
        self.hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    self.animator = nil
end

function flight:startFly()
    if self.isFlying then return end
    local char = lp.Character
    if not char then return end
    self.hrp = char:WaitForChild("HumanoidRootPart")
    self.hum = char:WaitForChild("Humanoid")
    local ani = char:FindFirstChild("Animate")
    if ani then
        self.animCache = ani
        ani.Parent = nil
    end
    if self.hrp:FindFirstChild("LeipzigBV") then
        self.hrp.LeipzigBV:Destroy()
    end
    local attachment = self.hrp:FindFirstChild("LeipzigAVAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "LeipzigAVAttachment"
        attachment.Parent = self.hrp
    end
    local lv = Instance.new("LinearVelocity")
    lv.Name = "LeipzigBV"
    lv.Attachment0 = attachment
    lv.MaxForce = 1e6
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VectorVelocity = Vector3.zero
    lv.Parent = self.hrp
    self.bv = lv
    self.lvAttachment = attachment
    self:loadAndFreezeHover()
    self.isFlying = true
    task.spawn(function()
        while self.isFlying and char.Parent do
            local mv = ControlModule:GetMoveVector()
            local cf = camera.CFrame
            local dir = (cf.LookVector * -mv.Z) + (cf.RightVector * mv.X)
            if mv.Magnitude > 0 then
                self.bv.VectorVelocity = dir.Unit * self.flySpeed
            else
                self.bv.VectorVelocity = Vector3.zero
            end
            self.hum:ChangeState(Enum.HumanoidStateType.Climbing)
            RunService.RenderStepped:Wait()
        end
        self:clearResources()
    end)
end

function flight:stopFly()
    if not self.isFlying then return end
    self.isFlying = false
    self:clearResources()
end

function flight:setSpeed(speed)
    self.flySpeed = mathClamp(speed, 10, 100)
end

local function bindCharacter()
    local char = lp.Character or lp.CharacterAdded:Wait()
    flight.hrp = char:WaitForChild("HumanoidRootPart")
    flight.hum = char:WaitForChild("Humanoid")
    flight:clearResources()
    char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            flight:clearResources()
            bindCharacter()
        end
    end)
end
bindCharacter()

local pgui = lp:WaitForChild("PlayerGui")
if pgui:FindFirstChild("OriginalFlightUI") then pgui.OriginalFlightUI:Destroy() end

local UI_BG = c3rgb(200, 230, 255)
local BTN_OFF = c3rgb(150, 200, 255)
local BTN_ON = c3rgb(70, 150, 255)
local DESTROY_BTN = c3rgb(110, 180, 255)
local TEXT_COLOR = c3rgb(0, 60, 120)
local SPEED_BG = c3rgb(180, 220, 255)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OriginalFlightUI"
ScreenGui.Parent = pgui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 145)
MainFrame.Position = UDim2.new(0.5, -75, 0.3, 0)
MainFrame.BackgroundColor3 = UI_BG
MainFrame.BackgroundTransparency = 0.4
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = MainFrame
    local stroke = Instance.new("UIStroke")
    stroke.Parent = MainFrame
    stroke.Color = c3rgb(120, 200, 255)
    stroke.Thickness = 3
    stroke.Transparency = 0.1

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.Size = UDim2.new(1,0,0,20)
Title.BackgroundTransparency = 1
Title.Text = "飞行-动画"
Title.TextColor3 = TEXT_COLOR
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold

    local Tip = Instance.new("TextLabel")
    Tip.Parent = MainFrame
    Tip.Size = UDim2.new(1,0,0,14)
Tip.Position = UDim2.new(0,0,0,20)
Tip.BackgroundTransparency = 1
Tip.Text = "无相机锁定"
Tip.TextColor3 = Color3.new(0.9,0,0)
Tip.TextSize = 8

    local SpeedInput = Instance.new("TextBox")
    SpeedInput.Parent = MainFrame
    SpeedInput.Size = UDim2.new(0,120,0,24)
SpeedInput.Position = UDim2.new(0.5,-60,0, 38)
SpeedInput.BackgroundColor3 = SPEED_BG
SpeedInput.BackgroundTransparency = 0.3
SpeedInput.Text = tostring(flight.flySpeed)
SpeedInput.TextColor3 = TEXT_COLOR
SpeedInput.TextSize = 11
    do
        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, 7)
        inputCorner.Parent = SpeedInput
    end

    local FlyBtn = Instance.new("TextButton")
    FlyBtn.Parent = MainFrame
    FlyBtn.Size = UDim2.new(0,120,0,26)
FlyBtn.Position = UDim2.new(0.5,-60,0, 72)
FlyBtn.BackgroundColor3 = BTN_OFF
FlyBtn.BackgroundTransparency = 0.3
FlyBtn.Text = "飞行"
FlyBtn.TextColor3 = TEXT_COLOR
FlyBtn.TextSize = 11
    do
        local flyCorner = Instance.new("UICorner")
        flyCorner.CornerRadius = UDim.new(0, 8)
        flyCorner.Parent = FlyBtn
    end

    local DestroyUI = Instance.new("TextButton")
    DestroyUI.Parent = MainFrame
    DestroyUI.Size = UDim2.new(0,120,0,26)
DestroyUI.Position = UDim2.new(0.5,-60,0, 108)
DestroyUI.BackgroundColor3 = DESTROY_BTN
DestroyUI.BackgroundTransparency = 0.3
DestroyUI.Text = "销毁UI"
DestroyUI.TextColor3 = TEXT_COLOR
DestroyUI.TextSize = 11
    do
        local destroyCorner = Instance.new("UICorner")
        destroyCorner.CornerRadius = UDim.new(0, 8)
        destroyCorner.Parent = DestroyUI
    end

local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val then
        flight:setSpeed(val)
    else
        flight:setSpeed(40)
    end
    SpeedInput.Text = tostring(flight.flySpeed)
end)

FlyBtn.MouseButton1Click:Connect(function()
    if flight.isFlying then
        flight:stopFly()
        FlyBtn.Text = "飞行"
        FlyBtn.BackgroundColor3 = BTN_OFF
    else
        flight:startFly()
        FlyBtn.Text = "飞行开"
        FlyBtn.BackgroundColor3 = BTN_ON
    end
end)

DestroyUI.MouseButton1Click:Connect(function()
    flight:stopFly()
    ScreenGui:Destroy()
end)

MainFrame.Size = UDim2.new(0,0,0,0)
MainFrame:TweenSize(UDim2.new(0,150,0,145), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true)
]])()
end

do
	local v23 = tbl3.Auto:AddRightTabbox()
	local v24 = v23:AddTab("僵尸透视")

	v24:AddToggle("ESPAxe", {
		Text = "透视斧头僵尸",
		Default = false,
		Callback = function(axe)
			tbl.zombieEspEnabled.Axe = axe

			if axe then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("ESPEye", {
		Text = "透视红眼",
		Default = false,
		Callback = function(eye)
			tbl.zombieEspEnabled.Eye = eye

			if eye then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("ESPSword", {
		Text = "透视胸甲骑兵",
		Default = false,
		Callback = function(sword)
			tbl.zombieEspEnabled.Sword = sword

			if sword then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("ESPBarrel", {
		Text = "透视自爆",
		Default = false,
		Callback = function(barrel)
			tbl.zombieEspEnabled.Barrel = barrel

			if barrel then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("ESPFTorso", {
		Text = "透视提灯人",
		Default = false,
		Callback = function(fTorso)
			tbl.zombieEspEnabled.FTorso = fTorso

			if fTorso then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("ESPNormal", {
		Text = "透视山伯乐",
		Default = false,
		Callback = function(normal)
			tbl.zombieEspEnabled.Normal = normal

			if normal then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("ESPHeadless", {
		Text = "透视无头士兵",
		Default = false,
		Callback = function(headless)
			tbl.zombieEspEnabled.Headless = headless

			if headless then
				tbl.startZombieESPHeartbeat()
			else
				tbl.stopZombieESPHeartbeat()
			end
		end,
	})

	v24:AddToggle("HeadlessHighlightToggle", {
		Text = "透视无头骑士",
		Default = false,
		Callback = function(arg)
			tbl.toggleHeadlessHighlight(arg)
		end,
	})

	v24:AddToggle("DraculaHighlightToggle", {
		Text = "透视德古拉",
		Default = false,
		Callback = function(arg)
			tbl.toggleDraculaHighlight(arg)
		end,
	})

	v24:AddToggle("BoomDrawToggle", {
		Text = "自爆倒计时显示",
		Default = false,
		Tooltip = fn4("显示自爆僵尸爆炸剩余时间"),
		Callback = function(arg)
			if arg then
				tbl.boomDraw.start()
			else
				tbl.boomDraw.stop()
			end
		end,
	})

	local v25 = v23:AddTab("玩家透视")

	v25:AddToggle("PlayerESPEnable", {
		Text = "启用玩家透视",
		Default = false,
		Tooltip = fn4("开启后对玩家高亮"),
		Callback = function(espPlayerEnabled)
			tbl.espPlayerEnabled = espPlayerEnabled

			if espPlayerEnabled then
				tbl.refreshAllPlayers()
				tbl.startPlayerESPRefresh()
			else
				tbl.stopPlayerESPRefresh()

				for _, v26 in v4:GetPlayers() do
					tbl.destroyPlayerComponents(v26)
				end
			end
		end,
	})

	v25:AddToggle("PlayerESPName", {
		Text = "显示玩家名称",
		Default = false,
		Tooltip = fn4("开启显示玩家用户名"),
		Callback = function(espShowNames)
			tbl.espShowNames = espShowNames
			tbl.refreshAllPlayers()
		end,
	})

	v25:AddToggle("PlayerESPHealth", {
		Text = "显示玩家血量",
		Default = false,
		Tooltip = fn4("开启显示玩家血量数值"),
		Callback = function(espShowHealth)
			tbl.espShowHealth = espShowHealth
			tbl.refreshAllPlayers()
		end,
	})

	v25:AddToggle("PlayerESPTeam", {
		Text = "队伍检测",
		Default = false,
		Tooltip = fn4("开启后只高亮透视敌方队伍玩家"),
		Callback = function(espTeamCheckPlayer)
			tbl.espTeamCheckPlayer = espTeamCheckPlayer
			tbl.refreshAllPlayers()
		end,
	})

	v25:AddToggle("PlayerESPInfection", {
		Text = "显示玩家感染值",
		Default = false,
		Tooltip = fn4("开启后显示其他玩家感染值"),
		Callback = function(infectionEnabled)
			tbl.infectionEnabled = infectionEnabled

			if infectionEnabled then
				tbl.startInfectionUpdating()
			else
				tbl.stopInfectionUpdating()
			end
		end,
	})

	v25:AddToggle("PlayerESPJob", {
		Text = "显示玩家职业",
		Default = false,
		Callback = function(arg)
			if arg then
				tbl.startJobUpdating()
			else
				tbl.stopJobUpdating()
			end
		end,
	})
end

local v23
v23 = tbl3.Auto:AddGroupbox({ Side = "Left", Name = "其他功能", IconName = "settings", Description = "显示提示" })
local v24 = tbl3.Minor:AddGroupbox({ Side = "Left", Name = "防护功能", IconName = "shield", Description = "防坠自救" })

v24:AddToggle("AutoEscapeToggle", {
	Text = "红眼扑倒自救",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.AutoEscape.enable()
		else
			tbl.AutoEscape.disable()
		end
	end,
})

v24:AddToggle("FallProtectionToggle", {
	Text = "防骨折",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.startFallProtection()
		else
			tbl.stopFallProtection()
		end
	end,
})

v24:AddToggle("AntiVelocityToggle", {
	Text = "骨折可移动",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.antiVelocityEnable()
		else
			tbl.antiVelocityDisable()
		end
	end,
})

v24:AddToggle("AntiGrabToggle", {
	Text = "防抓取",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.AntiGrab.start()
		else
			tbl.AntiGrab.stop()
		end
	end,
})

v24:AddToggle("DamageDisplayToggle", {
	Text = "显示受伤伤害",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.damageDisplay.start()
		else
			tbl.damageDisplay.stop()
		end
	end,
})

v24:AddToggle("RescueTeammateToggle", {
	Text = "传送救援队友",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.rescueTeammate.start()
		else
			tbl.rescueTeammate.stop()
		end
	end,
})

v24:AddToggle("ElbowZombiesToggle", {
	Text = "肘击自救",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.elbowZombies.start()
		else
			tbl.elbowZombies.stop()
		end
	end,
})

v24:AddToggle("PushBarrelProtectToggle", {
	Text = "自爆拉扯（防护）",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.pushBarrelProtect.start()
		else
			tbl.pushBarrelProtect.stop()
		end
	end,
})

v24:AddSlider("PushBarrelProtectSize", {
	Text = "拉扯范围",
	Default = 10,
	Min = 1,
	Max = 15,
	Suffix = " 格",
	Callback = function(size)
		tbl.pushBarrelProtect.size = size
	end,
})

v24:AddToggle("AutoHelpToggleMisc", {
	Text = "自动求救",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.autoHelp.start()
		else
			tbl.autoHelp.stop()
		end
	end,
})

local v25 = tbl3.Misc:AddGroupbox({ Side = "Right", Name = "获取", IconName = "package", Description = "获取装备" })

v25:AddButton({
	Text = "获取吸血鬼刀 (Voivode)",
	Func = function()
		local v26 = tbl.getPurchaseEvent()

		if v26 then
			v26:FireServer("Voivode")
			tbl.notify(fn3("已获取吸血鬼刀"), 2)
		end
	end,
})

v25:AddButton({
	Text = "获取铁桩 (Iron Stake)",
	Func = function()
		local v26 = tbl.getPurchaseEvent()

		if v26 then
			v26:FireServer("Iron Stake")
			tbl.notify(fn3("已获取铁桩"), 2)
		end
	end,
})

tbl.removeAllHats = function()
	for _, v26 in v4:GetPlayers() do
		if v26.Character then
			for _, v27 in v26.Character:GetChildren() do
				if v27:IsA("Accessory") then
					v27:Destroy()
				end
			end
		end
	end
end

tbl.removeAllShirts = function()
	for _, v26 in v4:GetPlayers() do
		if v26.Character then
			for _, v27 in v26.Character:GetChildren() do
				if v27:IsA("Shirt") or v27:IsA("ShirtGraphic") then
					v27:Destroy()
				end
			end
		end
	end
end

tbl.removeAllPants = function()
	for _, v26 in v4:GetPlayers() do
		if v26.Character then
			for _, v27 in v26.Character:GetChildren() do
				if v27:IsA("Pants") then
					v27:Destroy()
				end
			end
		end
	end
end

tbl.removeCarriages = function()
	for _, v26 in { "Carriage", "RearCarriage", "WagonPlatform", "FL_Wheel", "Horse", "Behind" }, nil, nil do
		for _, v27 in workspace:GetDescendants() do
			if v27.Name == v26 then
				pcall(function()
					v27:Destroy()
				end)
			end
		end
	end
end

v23:AddToggle("BulletDisplay", {
	Text = "显示子弹数量",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.bulletDisplay.start()
		else
			tbl.bulletDisplay.stop()
		end
	end,
})

v23:AddToggle("TracerToggle", {
	Text = "显示子弹轨迹",
	Default = false,
	Callback = function(arg)
		tbl.Tracer.toggle(arg)
	end,
})

v23:AddToggle("CannonSupplies", {
	Text = "火炮物资透视",
	Default = false,
	Callback = function(arg)
		tbl.cannonSupplies.toggle(arg)
	end,
})

v23:AddToggle("KillSound", {
	Text = "击杀音效",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.killSound.start()
		else
			tbl.killSound.stop()
		end
	end,
})

v23:AddSlider("KillSoundVol", {
	Text = "音效音量",
	Default = 7,
	Min = 1,
	Max = 10,
	Callback = function(volume)
		tbl.killSound.volume = volume
	end,
})

v23:AddDivider()

v23:AddToggle("PingDisplay", {
	Text = "显示网络延迟",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.pingDisplay.start()
		else
			tbl.pingDisplay.stop()
		end
	end,
})

tbl.noFogEnabled = false
tbl.noFogOriginal = {}
tbl.noFogOriginalsSaved = false
tbl.noFogAtmosphereBackup = {}
tbl.noFogConns = {}
tbl.noFogDebounce = false

tbl.saveNoFogOriginal = function()
	if tbl.noFogOriginalsSaved then
		return
	end

	pcall(function()
		tbl.noFogOriginal = { FogEnd = v9.FogEnd, FogStart = v9.FogStart }
		tbl.noFogOriginalsSaved = true
	end)
end

tbl.saveNoFogOriginal()

tbl.applyNoFog = function()
	pcall(function()
		v9.FogEnd = 100000
		v9.FogStart = 0
		tbl.noFogAtmosphereBackup = {}

		for _, v26 in v9:GetDescendants() do
			if v26:IsA("Atmosphere") then
				table.insert(tbl.noFogAtmosphereBackup, { Instance = v26, Parent = v26.Parent })
				v26.Parent = nil
			end
		end
	end)
end

tbl.restoreNoFog = function()
	pcall(function()
		v9.FogEnd = tbl.noFogOriginal.FogEnd or 100000
		v9.FogStart = tbl.noFogOriginal.FogStart or 0

		for _, v26 in tbl.noFogAtmosphereBackup, nil, nil do
			if v26.Instance and v26.Parent then
				v26.Instance.Parent = v26.Parent
			end
		end

		tbl.noFogAtmosphereBackup = {}
	end)
end

local function fn8()
	if not tbl.noFogEnabled or tbl.noFogDebounce then
		return
	end
	tbl.noFogDebounce = true

	task.delay(0.1, function()
		tbl.noFogDebounce = false

		if tbl.noFogEnabled then
			pcall(tbl.applyNoFog)
		end
	end)
end

tbl.startNoFogMonitor = function()
	for _, v26 in tbl.noFogConns, nil, nil do
		pcall(function()
			v26:Disconnect()
		end)
	end

	table.clear(tbl.noFogConns)

	for _, v26 in { "FogEnd", "FogStart" }, nil, nil do
		pcall(function()
			table.insert(tbl.noFogConns, v9:GetPropertyChangedSignal(v26):Connect(fn8))
		end)
	end

	pcall(function()
		table.insert(tbl.noFogConns, v9.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("Atmosphere") then
				fn8()
			end
		end))
	end)
end

tbl.stopNoFogMonitor = function()
	for _, v26 in tbl.noFogConns, nil, nil do
		pcall(function()
			v26:Disconnect()
		end)
	end

	table.clear(tbl.noFogConns)
	tbl.noFogDebounce = false
end

v23:AddToggle("InfectionRemover", {
	Text = "移除感染红色血液",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.infectionRemover.start()
		else
			tbl.infectionRemover.stop()
		end
	end,
})

v23:AddToggle("BombRange", {
	Text = "自爆范围显示",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.bombRange.start()
		else
			tbl.bombRange.stop()
		end
	end,
})

v23:AddToggle("HandMortar", {
	Text = "手炮爆炸倒计时",
	Default = false,
	Callback = function(arg)
		tbl.handMortar.setEnabled(arg)
	end,
})

v23:AddToggle("NoBarrelHit", {
	Text = "无法攻击自爆",
	Default = false,
	Callback = function(arg)
		tbl.noBarrelHit.toggle(arg)
	end,
})

v23:AddToggle("JumpLock", {
	Text = "移除跳跃限制",
	Default = false,
	Callback = function(arg)
		tbl.jumpLock.toggle(arg)
	end,
})

tbl.rollTiltEnabled = false
tbl.rollTiltSpeed = 3
tbl.rollTiltConn = nil
tbl.rollTiltHrp = nil
tbl.rollTiltRx = 0
tbl.rollTiltRz = 0
tbl.rollTiltLastUpdate = 0

tbl.rollTiltStop = function()
	if tbl.rollTiltConn then
		tbl.rollTiltConn:Disconnect()
		tbl.rollTiltConn = nil
	end

	tbl.rollTiltEnabled = false
end

tbl.rollTiltStart = function()
	if tbl.rollTiltEnabled then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	tbl.rollTiltHrp = character:FindFirstChild("HumanoidRootPart")
	if not tbl.rollTiltHrp then
		return
	end
	tbl.rollTiltEnabled = true
	tbl.rollTiltLastUpdate = 0
	tbl.rollTiltRx = 0
	tbl.rollTiltRz = 0

	tbl.rollTiltConn = v5.RenderStepped:Connect(function()
		if not tbl.rollTiltEnabled or not tbl.rollTiltHrp or not tbl.rollTiltHrp.Parent then
			tbl.rollTiltStop()
			return
		end
		local rollTiltLastUpdate = tbl.rollTiltLastUpdate

		if clock() - rollTiltLastUpdate > 0.05 then
			tbl.rollTiltLastUpdate = clock()
			local rollTiltSpeed = tbl.rollTiltSpeed
			tbl.rollTiltRx = (math.random() - 0.5) * rollTiltSpeed * 0.15
			local rollTiltSpeed2 = tbl.rollTiltSpeed
			tbl.rollTiltRz = (math.random() - 0.5) * rollTiltSpeed2 * 0.15
		end

		tbl.rollTiltHrp.CFrame = tbl.rollTiltHrp.CFrame * CFrame.Angles(tbl.rollTiltRx, 0, tbl.rollTiltRz)
	end)
end

tbl.spin = { enabled = false, speed = 5, connection = nil, animLockThread = nil }

tbl.spin.applySpinAnimationLock = function(arg)
	if not arg then
		return
	end
	local humanoid = arg:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.AutoRotate = false
	end

	if tbl.spin.animLockThread then
		task.cancel(tbl.spin.animLockThread)
		tbl.spin.animLockThread = nil
	end

	tbl.spin.animLockThread = task.spawn(function()
		local animate = arg:FindFirstChild("Animate")
		local n2 = 0

		while not animate and n2 < 3 do
			task.wait(0.1)
			n2 += 0.1
			animate = arg:FindFirstChild("Animate")
		end

		while tbl.spin.enabled and animate and animate.Parent do
			animate.Disabled = true
			task.wait(0.2)
		end
	end)
end

tbl.spin.removeSpinAnimationLock = function(arg)
	if not arg then
		return
	end
	local humanoid = arg:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.AutoRotate = true
	end

	if tbl.spin.animLockThread then
		task.cancel(tbl.spin.animLockThread)
		tbl.spin.animLockThread = nil
	end

	local animate = arg:FindFirstChild("Animate")

	if animate then
		animate.Disabled = false
	end
end

tbl.spin.start = function()
	if tbl.spin.connection then
		return
	end

	tbl.spin.connection = v5.RenderStepped:Connect(function(deltaTime)
		if not tbl.spin.enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, rad(tbl.spin.speed * 350) * deltaTime, 0)
	end)

	tbl.spin.applySpinAnimationLock(localPlayer.Character)
end

tbl.spin.stop = function()
	tbl.spin.enabled = false

	if tbl.spin.connection then
		tbl.spin.connection:Disconnect()
		tbl.spin.connection = nil
	end

	tbl.spin.removeSpinAnimationLock(localPlayer.Character)
end

tbl.thirdPerson = { enabled = false, connection = nil }

tbl.thirdPerson.apply = function()
	pcall(function()
		local v26 = localPlayer

		if v26.CameraMode ~= Enum.CameraMode.Classic then
			v26.CameraMode = Enum.CameraMode.Classic
		end

		v26.CameraMinZoomDistance = 0.5
		v26.CameraMaxZoomDistance = 200
	end)
end

tbl.thirdPerson.start = function()
	if tbl.thirdPerson.connection then
		return
	end
	tbl.thirdPerson.enabled = true
	tbl.thirdPerson.apply()

	tbl.thirdPerson.connection = v5.RenderStepped:Connect(function()
		if not tbl.thirdPerson.enabled then
			return
		end
		tbl.thirdPerson.apply()
	end)
end

tbl.thirdPerson.stop = function()
	tbl.thirdPerson.enabled = false

	if tbl.thirdPerson.connection then
		tbl.thirdPerson.connection:Disconnect()
		tbl.thirdPerson.connection = nil
	end
end

tbl.animFreeze = {
	enabled = false,
	currentAnimTrack = nil,
	originalAnimateDisabled = false,
	loopThread = nil,
	charAddedConn = nil,
}

tbl.animFreeze.cleanup = function()
	if tbl.animFreeze.loopThread then
		task.cancel(tbl.animFreeze.loopThread)
		tbl.animFreeze.loopThread = nil
	end

	if tbl.animFreeze.currentAnimTrack then
		tbl.animFreeze.currentAnimTrack:Stop()
		tbl.animFreeze.currentAnimTrack = nil
	end

	local character = localPlayer.Character

	if character and tbl.animFreeze.originalAnimateDisabled then
		local animate = character:FindFirstChild("Animate")

		if animate then
			animate.Disabled = false
			tbl.animFreeze.originalAnimateDisabled = false
		end
	end
end

tbl.animFreeze.playOnce = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not tbl.animFreeze.originalAnimateDisabled then
		local animate = character:FindFirstChild("Animate")

		if animate and not animate.Disabled then
			animate.Disabled = true
			tbl.animFreeze.originalAnimateDisabled = true
		end
	end

	local animationId = humanoid.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://27432686" or "rbxassetid://507776043"
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local v26 = animator:LoadAnimation(animation)
	v26:Play()
	v26:AdjustSpeed(0)

	if tbl.animFreeze.currentAnimTrack then
		tbl.animFreeze.currentAnimTrack:Stop()
	end

	tbl.animFreeze.currentAnimTrack = v26
end

tbl.animFreeze.loop = function()
	while tbl.animFreeze.enabled do
		pcall(function()
			tbl.animFreeze.playOnce()
		end)

		task.wait(0.1)
	end
end

tbl.animFreeze.start = function()
	if tbl.animFreeze.enabled then
		return
	end
	tbl.animFreeze.enabled = true
	tbl.animFreeze.cleanup()
	tbl.animFreeze.loopThread = task.spawn(tbl.animFreeze.loop)
end

tbl.animFreeze.stop = function()
	tbl.animFreeze.enabled = false
	tbl.animFreeze.cleanup()
end

tbl.invert = { enabled = false, conn = nil, charConn = nil }

tbl.invert.apply = function()
	if not tbl.invert.enabled then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")

	if humanoidRootPart then
		humanoidRootPart.CFrame = cframe(humanoidRootPart.Position) * CFrame.Angles(3.1415926535897931, 0, 0)
	end
end

tbl.invert.lockLoop = function()
	if tbl.invert.conn then
		return
	end

	tbl.invert.conn = v5.RenderStepped:Connect(function()
		if tbl.invert.enabled then
			tbl.invert.apply()
		end
	end)
end

tbl.invert.unlockLoop = function()
	if tbl.invert.conn then
		tbl.invert.conn:Disconnect()
		tbl.invert.conn = nil
	end
end

tbl.invert.setEnabled = function(enabled)
	tbl.invert.enabled = enabled

	if enabled then
		tbl.invert.apply()
		tbl.invert.lockLoop()
	else
		tbl.invert.unlockLoop()
		local character = localPlayer.Character

		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")

			if humanoidRootPart then
				local position = humanoidRootPart.Position
				local cFrame = humanoidRootPart.CFrame
				local v26 = math.atan2(-cFrame.LookVector.X, -cFrame.LookVector.Z)
				humanoidRootPart.CFrame = cframe(position) * CFrame.Angles(0, v26, 0)
			end
		end
	end
end

tbl.bigHead = {
	enabled = false,
	headSize = 3,
	headTrans = 0.5,
	originalProps = {},
	watchedZombies = {},
	connection = nil,
	descendantDisposer = nil,
}

tbl.bigHead.applyToZombie = function(arg)
	local head = arg:FindFirstChild("Head")
	if not head then
		return
	end

	if not tbl.bigHead.originalProps[arg] then
		tbl.bigHead.originalProps[arg] = { Size = head.Size, Transparency = head.Transparency }
	end

	head.Size = vector(tbl.bigHead.headSize, tbl.bigHead.headSize, tbl.bigHead.headSize)
	head.Transparency = tbl.bigHead.headTrans
end

tbl.bigHead.restoreZombie = function(arg)
	local v26 = tbl.bigHead.originalProps[arg]

	if v26 then
		local head = arg:FindFirstChild("Head")

		if head then
			head.Size = v26.Size
			head.Transparency = v26.Transparency
		end

		tbl.bigHead.originalProps[arg] = nil
	end
end

tbl.bigHead.clearAll = function()
	for k in tbl.bigHead.originalProps, nil, nil do
		tbl.bigHead.restoreZombie(k)
	end

	tbl.bigHead.originalProps = {}
end

tbl.bigHead.updateAllZombies = function()
	if not tbl.bigHead.enabled then
		return
	end

	for k in tbl.bigHead.watchedZombies, nil, nil do
		if k.Parent then
			tbl.bigHead.applyToZombie(k)
		else
			tbl.bigHead.watchedZombies[k] = nil
		end
	end
end

tbl.bigHead.setupListener = function()
	if tbl.bigHead.descendantDisposer then
		tbl.bigHead.descendantDisposer()
		tbl.bigHead.descendantDisposer = nil
	end

	table.clear(tbl.bigHead.watchedZombies)
	tbl.ZombieWatch.start()

	local function fn9(arg)
		local camera = workspace:FindFirstChild("Camera")
		if not camera or not arg:IsDescendantOf(camera) then
			return
		end

		if not tbl.bigHead.watchedZombies[arg] then
			tbl.bigHead.watchedZombies[arg] = true

			if tbl.bigHead.enabled then
				tbl.bigHead.applyToZombie(arg)
			end
		end
	end

	tbl.ZombieWatch.forEach(fn9)
	tbl.bigHead.descendantDisposer = tbl.ZombieWatch.onAdded(fn9)
end

tbl.bigHead.startLoop = function()
	if tbl.bigHead.connection then
		return
	end
	local n2 = 0
	local n3 = 0

	tbl.bigHead.connection = v5.RenderStepped:Connect(function(deltaTime)
		if tbl.bigHead.enabled then
			n2 += deltaTime

			if n2 >= 0.1 then
				n2 = 0
				tbl.bigHead.updateAllZombies()
			end

			local v26 = clock2()

			if v26 - n3 > 5 then
				n3 = v26

				for k in tbl.bigHead.originalProps, nil, nil do
					if not k.Parent then
						tbl.bigHead.originalProps[k] = nil
					end
				end
			end
		end
	end)
end

tbl.bigHead.stopLoop = function()
	if tbl.bigHead.connection then
		tbl.bigHead.connection:Disconnect()
		tbl.bigHead.connection = nil
	end
end

tbl.bigHead.enable = function()
	if tbl.bigHead.enabled then
		return
	end
	tbl.bigHead.enabled = true
	tbl.bigHead.setupListener()
	tbl.bigHead.updateAllZombies()
	tbl.bigHead.startLoop()
end

tbl.bigHead.disable = function()
	tbl.bigHead.enabled = false
	tbl.bigHead.clearAll()
	table.clear(tbl.bigHead.watchedZombies)

	if tbl.bigHead.descendantDisposer then
		tbl.bigHead.descendantDisposer()
		tbl.bigHead.descendantDisposer = nil
	end

	tbl.bigHead.stopLoop()
end

tbl.animLoop1205Enabled = false
tbl.animLoop1205Track = nil
tbl.animLoop1205Connection = nil

tbl.startAnimLoop1205 = function()
	if tbl.animLoop1205Connection then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://120593550434546"
	tbl.animLoop1205Track = animator:LoadAnimation(animation)
	tbl.animLoop1205Track.Priority = Enum.AnimationPriority.Action4

	tbl.animLoop1205Connection = v5.Heartbeat:Connect(function()
		if not tbl.animLoop1205Enabled then
			return
		end
		local character2 = localPlayer.Character
		if not character2 or not character2:FindFirstChildOfClass("Humanoid") then
			tbl.stopAnimLoop1205()
			return
		end

		pcall(function()
			if tbl.animLoop1205Track then
				if tbl.animLoop1205Track.IsPlaying then
					tbl.animLoop1205Track:Stop()
				end

				tbl.animLoop1205Track:Play()
			end
		end)
	end)
end

tbl.stopAnimLoop1205 = function()
	tbl.animLoop1205Enabled = false

	if tbl.animLoop1205Connection then
		tbl.animLoop1205Connection:Disconnect()
		tbl.animLoop1205Connection = nil
	end

	if tbl.animLoop1205Track then
		pcall(function()
			tbl.animLoop1205Track:Stop()
		end)

		tbl.animLoop1205Track = nil
	end
end

task.spawn(function()
	tbl.ControlModule = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)

tbl.AutoEscape = {
	enabled = false,
	active = false,
	checkThread = nil,
	heartbeatConn = nil,
	originalIndex = nil,
	camBindName = nil,
	offset = Vector3.zero,
	savedCF = nil,
	savedVel = nil,
}

tbl.AutoEscape.updateOffset = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	local head = character:FindFirstChild("Head")
	local y = humanoidRootPart.Position.Y

	if head then
		y = head.Position.Y
	end

	tbl.AutoEscape.offset = vector(0, y - humanoidRootPart.Position.Y + 5680, 0)
end

tbl.AutoEscape.start = function()
	if tbl.AutoEscape.active then
		return
	end
	tbl.AutoEscape.active = true
	local v26 = localPlayer
	local v27 = v5
	local autoEscape = tbl.AutoEscape

	autoEscape.heartbeatConn = v27.Heartbeat:Connect(function()
		if not autoEscape.active then
			return
		end

		if not v26.Character then
			return
		end
		local humanoidRootPart = v26.Character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		tbl.AutoEscape.updateOffset()
		autoEscape.savedCF = humanoidRootPart.CFrame
		autoEscape.savedVel = humanoidRootPart.AssemblyLinearVelocity
		humanoidRootPart.CFrame = humanoidRootPart.CFrame + autoEscape.offset
		humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		v27.RenderStepped:Wait()

		if v26.Character and v26.Character:FindFirstChild("HumanoidRootPart") then
			v26.Character.HumanoidRootPart.CFrame = autoEscape.savedCF
			v26.Character.HumanoidRootPart.AssemblyLinearVelocity = autoEscape.savedVel
		end
	end)

	autoEscape.originalIndex = hookmetamethod(game, "__index", newcclosure(function(arg, arg2)
		if autoEscape.active then
			if not checkcaller() then
				if arg2 == "CFrame" and v26.Character and v26.Character:FindFirstChild("HumanoidRootPart") and v26.Character:FindFirstChild("Humanoid") and v26.Character:FindFirstChild("Humanoid").Health > 0 then
					if arg == v26.Character.HumanoidRootPart then
						return (autoEscape.savedCF or cframe()) + autoEscape.offset
					end

					if arg == v26.Character.Head then
						return (autoEscape.savedCF or cframe()) + autoEscape.offset
					end
				end
			end
		end

		return autoEscape.originalIndex(arg, arg2)
	end))

	autoEscape.camBindName = "AutoEscapeCamFix_" .. tostring(math.random(100000, 999999))

	v27:BindToRenderStep(autoEscape.camBindName, Enum.RenderPriority.Camera.Value + 1, function()
		if autoEscape.active and v26.Character then
			local currentCamera = workspace.CurrentCamera

			if currentCamera then
				currentCamera.CFrame = currentCamera.CFrame - autoEscape.offset
			end
		end
	end)
end

tbl.AutoEscape.stop = function()
	if not tbl.AutoEscape.active then
		return
	end
	tbl.AutoEscape.active = false

	if tbl.AutoEscape.heartbeatConn then
		pcall(function()
			tbl.AutoEscape.heartbeatConn:Disconnect()
		end)

		tbl.AutoEscape.heartbeatConn = nil
	end

	if tbl.AutoEscape.originalIndex then
		pcall(function()
			hookmetamethod(game, "__index", tbl.AutoEscape.originalIndex)
		end)

		tbl.AutoEscape.originalIndex = nil
	end

	if tbl.AutoEscape.camBindName then
		pcall(function()
			v5:UnbindFromRenderStep(tbl.AutoEscape.camBindName)
		end)

		tbl.AutoEscape.camBindName = nil
	end

	tbl.AutoEscape.savedCF = nil
	tbl.AutoEscape.savedVel = nil
end

tbl.AutoEscape.check = function()
	if not tbl.AutoEscape.enabled then
		return
	end

	if not localPlayer.Character then
		if tbl.AutoEscape.active then
			tbl.AutoEscape.stop()
		end

		return
	end

	local players = workspace:FindFirstChild("Players")
	players = players and players:FindFirstChild(localPlayer.Name)
	local userStates = players and players:FindFirstChild("UserStates")
	local pin = userStates and userStates:FindFirstChild("Pin")
	pin = pin and tostring(pin.Value) ~= "None"

	if pin and not tbl.AutoEscape.active then
		tbl.AutoEscape.start()
	elseif not pin and tbl.AutoEscape.active then
		tbl.AutoEscape.stop()
	end
end

tbl.AutoEscape.enable = function()
	if tbl.AutoEscape.enabled then
		return
	end
	tbl.AutoEscape.enabled = true

	tbl.AutoEscape.checkThread = task.spawn(function()
		while tbl.AutoEscape.enabled do
			pcall(tbl.AutoEscape.check)
			task.wait(0.1)
		end
	end)
end

tbl.AutoEscape.disable = function()
	tbl.AutoEscape.enabled = false

	if tbl.AutoEscape.checkThread then
		pcall(function()
			task.cancel(tbl.AutoEscape.checkThread)
		end)

		tbl.AutoEscape.checkThread = nil
	end

	tbl.AutoEscape.stop()
end

tbl.fallProtectionInstances = {}
tbl.fallProtectionEnabled = false

tbl.antiVelocity = tbl.antiVelocity or {
	enabled = false,
	wasBroken = false,
	conn = nil,
	savedAnimateDisabled = nil,
	savedNormal = nil,
	lastNormalSave = 0,
	lastFix = 0,
}

local tbl6 = {
	["rbxassetid://12333490324"] = true,
	["12333490324"] = true,
	["rbxassetid://12333489072"] = true,
	["12333489072"] = true,
}

tbl.antiVelocity.snapshotTracks = function(arg)
	local tbl7 = {}

	pcall(function()
		for _, v26 in arg:GetPlayingAnimationTracks() do
			local animation = v26.Animation
			animation = animation and animation.AnimationId

			if animation and animation ~= "" then
				table.insert(tbl7, {
					id = animation,
					name = v26.Name,
					priority = v26.Priority,
					speed = v26.Speed,
					looped = v26.Looped,
					weight = v26.WeightCurrent,
				})
			end
		end
	end)

	return tbl7
end

tbl.antiVelocity.isLimpTrack = function(arg, arg2)
	local ok, result = pcall(function()
		local animation = arg.Animation
		animation = animation and animation.AnimationId or ""
		if tbl6[animation] then
			return true
		end
		local match = tostring(animation):match("%d+")
		if match and tbl6[match] then
			return true
		end

		if arg2 and animation == arg2 then
			return true
		end
		local v26 = string.lower(arg.Name or "")
		if v26:find("limp") or v26:find("fracture") or v26:find("broken") or v26:find("cripple") then
			return true
		end
		return false
	end)

	return ok and result or false
end

tbl.antiVelocity.restoreTracks = function(arg, arg2)
	if not arg2 or #arg2 == 0 then
		return
	end

	pcall(function()
		local humanoid = arg:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local animator = humanoid:FindFirstChildOfClass("Animator")

		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local tbl7 = {}

		pcall(function()
			for _, v26 in humanoid:GetPlayingAnimationTracks() do
				local animationId = v26.Animation and v26.Animation.AnimationId

				if animationId then
					tbl7[animationId] = true
				end
			end
		end)

		for _, v26 in arg2, nil, nil do
			if not tbl7[v26.id] then
				local animation = Instance.new("Animation")
				animation.AnimationId = v26.id
				local v27 = animator:LoadAnimation(animation)

				pcall(function()
					v27.Priority = v26.priority
				end)

				pcall(function()
					v27.Looped = v26.looped
				end)

				pcall(function()
					v27:Play(0.15, v26.weight or 1, v26.speed or 1)
				end)
			end
		end
	end)
end

tbl.antiVelocity.suppressLimp = function(arg)
	pcall(function()
		local humanoid = arg:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		for _, v26 in humanoid:GetPlayingAnimationTracks() do
			if tbl.antiVelocity.isLimpTrack(v26) then
				pcall(function()
					v26:Stop(0.15)
				end)
			end
		end
	end)
end

tbl.antiVelocityEnable = function()
	if tbl.antiVelocity.enabled then
		return
	end
	tbl.antiVelocity.enabled = true
	tbl.antiVelocity.wasBroken = false

	if tbl.antiVelocity.conn then
		pcall(function()
			tbl.antiVelocity.conn:Disconnect()
		end)

		tbl.antiVelocity.conn = nil
	end

	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		pcall(function()
			humanoid.AutoRotate = true
		end)
	end

	tbl.antiVelocity.conn = v5.Heartbeat:Connect(function()
		if not tbl.antiVelocity.enabled then
			return
		end
		local character2 = localPlayer.Character
		if not character2 then
			return
		end
		local humanoidRootPart = character2:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local humanoid2 = character2:FindFirstChildOfClass("Humanoid")

		if humanoid2 and not humanoid2.AutoRotate then
			pcall(function()
				humanoid2.AutoRotate = true
			end)
		end

		local killVelocity = humanoidRootPart:FindFirstChild("KillVelocity") or humanoidRootPart:FindFirstChild("LinearVelocity")

		if killVelocity and (killVelocity:IsA("BodyVelocity") or killVelocity:IsA("LinearVelocity")) then
			killVelocity.Enabled = false
		end

		local userStates = character2:FindFirstChild("UserStates")

		if userStates then
			local brokenLegs = userStates:FindFirstChild("BrokenLegs")

			if brokenLegs then
				local flag = brokenLegs.Value == true
				local v26 = clock2()
				local flag2 = not flag

				if flag2 then
					if v26 - (tbl.antiVelocity.lastNormalSave or 0) > 2 then
						local humanoid3 = character2:FindFirstChildOfClass("Humanoid")

						if humanoid3 then
							local savedNormal = {}

							for _, v27 in tbl.antiVelocity.snapshotTracks(humanoid3), nil, nil do
								if not tbl6[v27.id] then
									local v28 = string.lower(v27.name or "")

									if not (v28:find("limp") or v28:find("fracture") or v28:find("broken") or v28:find("cripple")) then
										table.insert(savedNormal, v27)
									end
								end
							end

							if #savedNormal > 0 then
								tbl.antiVelocity.savedNormal = savedNormal
								tbl.antiVelocity.lastNormalSave = v26
							end
						end
					end
				end

				if flag and not tbl.antiVelocity.wasBroken then
					tbl.antiVelocity.wasBroken = true
					tbl.antiVelocity.lastFix = 0
					local animate = character2:FindFirstChild("Animate")

					if animate and tbl.antiVelocity.savedAnimateDisabled == nil then
						tbl.antiVelocity.savedAnimateDisabled = animate.Disabled
					end

					task.spawn(function()
						local humanoid3 = character2:FindFirstChildOfClass("Humanoid")
						if not humanoid3 then
							return
						end

						pcall(function()
							humanoid3.AutoRotate = true
						end)

						local animate2 = character2:FindFirstChild("Animate")

						if animate2 and animate2.Disabled then
							pcall(function()
								animate2.Disabled = false
							end)
						end

						pcall(function()
							humanoid3:ChangeState(Enum.HumanoidStateType.Running)
						end)

						task.wait(0.3)
						if not tbl.antiVelocity.enabled or not character2.Parent then
							return
						end
						local userStates2 = character2:FindFirstChild("UserStates")
						userStates2 = userStates2 and userStates2:FindFirstChild("BrokenLegs")
						if not (userStates2 and userStates2.Value == true) then
							return
						end
						tbl.antiVelocity.suppressLimp(character2)
						tbl.antiVelocity.restoreTracks(character2, tbl.antiVelocity.savedNormal)
					end)
				end

				if flag and tbl.antiVelocity.wasBroken then
					if v26 - (tbl.antiVelocity.lastFix or 0) > 0.3 then
						tbl.antiVelocity.lastFix = v26
						tbl.antiVelocity.suppressLimp(character2)
						local humanoid3 = character2:FindFirstChildOfClass("Humanoid")

						if humanoid3 and tbl.antiVelocity.savedNormal and #tbl.antiVelocity.savedNormal > 0 then
							local flag3 = false

							pcall(function()
								for _, v27 in humanoid3:GetPlayingAnimationTracks() do
									local animationId = v27.Animation and v27.Animation.AnimationId

									if animationId and v27.IsPlaying then
										for _, v28 in tbl.antiVelocity.savedNormal, nil, nil do
											if v28.id == animationId then
												flag3 = true
												break
											end
										end
									end

									if not flag3 then
										continue
									end
									break
								end
							end)

							if not flag3 then
								tbl.antiVelocity.restoreTracks(character2, tbl.antiVelocity.savedNormal)
							end
						end

						if humanoid3 then
							pcall(function()
								local state = humanoid3:GetState()

								if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
									humanoid3:ChangeState(Enum.HumanoidStateType.Running)
								end

								if humanoid3.PlatformStand or humanoid3.Sit then
									humanoid3:ChangeState(Enum.HumanoidStateType.Running)
								end
							end)
						end
					end
				end

				if flag2 and tbl.antiVelocity.wasBroken then
					tbl.antiVelocity.wasBroken = false

					task.spawn(function()
						local humanoid3 = character2:FindFirstChildOfClass("Humanoid")
						local animate = character2:FindFirstChild("Animate")

						if animate and tbl.antiVelocity.savedAnimateDisabled ~= nil then
							pcall(function()
								animate.Disabled = tbl.antiVelocity.savedAnimateDisabled
							end)

							tbl.antiVelocity.savedAnimateDisabled = nil
						end

						if humanoid3 then
							pcall(function()
								humanoid3:ChangeState(Enum.HumanoidStateType.Running)
							end)
						end
					end)
				end
			else
				tbl.antiVelocity.wasBroken = false
			end
		else
			tbl.antiVelocity.wasBroken = false
		end
	end)
end

tbl.antiVelocityDisable = function()
	tbl.antiVelocity.enabled = false
	tbl.antiVelocity.wasBroken = false

	if tbl.antiVelocity.conn then
		pcall(function()
			tbl.antiVelocity.conn:Disconnect()
		end)

		tbl.antiVelocity.conn = nil
	end

	pcall(function()
		local character = localPlayer.Character

		if character then
			local animate = character:FindFirstChild("Animate")

			if animate and tbl.antiVelocity.savedAnimateDisabled ~= nil then
				animate.Disabled = tbl.antiVelocity.savedAnimateDisabled
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end
	end)

	tbl.antiVelocity.savedAnimateDisabled = nil
	tbl.antiVelocity.savedNormal = nil
end

do
	local n2 = 0.02
	local n3 = -5
	local n4 = 0
	local connection = nil

	local function fn9(deltaTime)
		if not tbl.fallProtectionEnabled then
			return
		end
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		character = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not character or humanoid.Health <= 0 then
			n4 = 0
			return
		end

		if not (character.AssemblyLinearVelocity.Y < n3 and not v6:IsKeyDown(Enum.KeyCode.Space)) then
			n4 = 0
			return
		end
		n4 += deltaTime

		if n2 <= n4 then
			n4 = 0

			pcall(function()
				humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
			end)
		end
	end

	tbl.startFallProtection = function()
		if tbl.fallProtectionEnabled then
			return
		end
		tbl.fallProtectionEnabled = true

		if not connection then
			connection = v5.Heartbeat:Connect(fn9)
		end
	end

	tbl.stopFallProtection = function()
		tbl.fallProtectionEnabled = false
		n4 = 0

		if connection then
			connection:Disconnect()
			connection = nil
		end
	end
end

tbl.AntiGrab = { enabled = false, connection = nil }

tbl.AntiGrab.start = function()
	if tbl.AntiGrab.connection then
		return
	end
	tbl.AntiGrab.enabled = true

	tbl.AntiGrab.connection = v5.Heartbeat:Connect(function()
		if not tbl.AntiGrab.enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			pcall(function()
				humanoid:Move(Vector3.new(0, 100000, 0))
			end)
		end
	end)
end

tbl.AntiGrab.stop = function()
	tbl.AntiGrab.enabled = false

	if tbl.AntiGrab.connection then
		tbl.AntiGrab.connection:Disconnect()
		tbl.AntiGrab.connection = nil
	end
end

tbl.damageDisplay = {
	enabled = false,
	damageQueue = {},
	isPlaying = false,
	billboard = nil,
	textLabel = nil,
	fadeTween = nil,
	fadeOutTween = nil,
	lastHealth = nil,
	healthConn = nil,
	charConn = nil,
}

tbl.damageDisplay.ensureBillboard = function()
	if tbl.damageDisplay.billboard and tbl.damageDisplay.billboard.Parent then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	tbl.damageDisplay.billboard = Instance.new("BillboardGui")
	tbl.damageDisplay.billboard.Size = UDim2.new(0, 100, 0, 50)
	tbl.damageDisplay.billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	tbl.damageDisplay.billboard.AlwaysOnTop = true
	tbl.damageDisplay.billboard.Adornee = head
	tbl.damageDisplay.billboard.Parent = character
	tbl.damageDisplay.textLabel = Instance.new("TextLabel")
	tbl.damageDisplay.textLabel.Size = UDim2.new(1, 0, 1, 0)
	tbl.damageDisplay.textLabel.BackgroundTransparency = 1
	tbl.damageDisplay.textLabel.Text = ""
	tbl.damageDisplay.textLabel.TextSize = 30
	tbl.damageDisplay.textLabel.Font = Enum.Font.GothamBold
	tbl.damageDisplay.textLabel.TextStrokeTransparency = 0.2
	tbl.damageDisplay.textLabel.TextStrokeColor3 = color(0, 0, 0)
	tbl.damageDisplay.textLabel.Parent = tbl.damageDisplay.billboard
	tbl.damageDisplay.billboard.Enabled = false
end

tbl.damageDisplay.destroyBillboard = function()
	if tbl.damageDisplay.billboard then
		tbl.damageDisplay.billboard:Destroy()
	end

	tbl.damageDisplay.billboard = nil
	tbl.damageDisplay.textLabel = nil

	if tbl.damageDisplay.fadeTween then
		tbl.damageDisplay.fadeTween:Cancel()
	end

	tbl.damageDisplay.fadeTween = nil
end

tbl.damageDisplay.showDamage = function(arg)
	if not tbl.damageDisplay.enabled then
		return
	end
	tbl.damageDisplay.ensureBillboard()
	if not tbl.damageDisplay.billboard then
		return
	end
	local flag = arg < 20 and color(0, 255, 0)
	local textColor3

	if flag then
		textColor3 = flag
	else
		textColor3 = arg < 50 and color(255, 255, 0) or color(255, 0, 0)
	end

	tbl.damageDisplay.textLabel.Text = tostring(floor(arg))
	tbl.damageDisplay.textLabel.TextColor3 = textColor3
	tbl.damageDisplay.billboard.Enabled = true

	if tbl.damageDisplay.fadeTween then
		tbl.damageDisplay.fadeTween:Cancel()
	end

	if tbl.damageDisplay.fadeOutTween then
		tbl.damageDisplay.fadeOutTween:Cancel()
		tbl.damageDisplay.fadeOutTween = nil
	end

	tbl.damageDisplay.textLabel.TextTransparency = 1
	tbl.damageDisplay.fadeTween = v8:Create(tbl.damageDisplay.textLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { TextTransparency = 0 })
	tbl.damageDisplay.fadeTween:Play()

	task.delay(1, function()
		if tbl.damageDisplay.textLabel then
			local tween = v8:Create(tbl.damageDisplay.textLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { TextTransparency = 1 })
			tbl.damageDisplay.fadeOutTween = tween
			tween:Play()
			tween.Completed:Wait()

			if tbl.damageDisplay.fadeOutTween == tween then
				tbl.damageDisplay.fadeOutTween = nil
			end

			if tbl.damageDisplay.billboard then
				tbl.damageDisplay.billboard.Enabled = false
			end
		end

		tbl.damageDisplay.isPlaying = false

		if #tbl.damageDisplay.damageQueue > 0 then
			local v26 = table.remove(tbl.damageDisplay.damageQueue, 1)
			tbl.damageDisplay.isPlaying = true
			tbl.damageDisplay.showDamage(v26)
		end

		tbl.damageDisplay.fadeTween = nil
	end)
end

tbl.damageDisplay.queueDamage = function(arg)
	if not tbl.damageDisplay.enabled then
		return
	end
	table.insert(tbl.damageDisplay.damageQueue, arg)

	if not tbl.damageDisplay.isPlaying then
		tbl.damageDisplay.isPlaying = true
		local v26 = table.remove(tbl.damageDisplay.damageQueue, 1)
		tbl.damageDisplay.showDamage(v26)
	end
end

tbl.damageDisplay.onHealthChanged = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local health = humanoid.Health
	if tbl.damageDisplay.lastHealth == nil then
		tbl.damageDisplay.lastHealth = health
		return
	end
	local n2 = tbl.damageDisplay.lastHealth - health

	if n2 > 0 then
		tbl.damageDisplay.queueDamage(n2)
	end

	tbl.damageDisplay.lastHealth = health
end

tbl.damageDisplay.start = function()
	if tbl.damageDisplay.healthConn then
		tbl.damageDisplay.healthConn:Disconnect()
	end

	if tbl.damageDisplay.charConn then
		tbl.damageDisplay.charConn()
		tbl.damageDisplay.charConn = nil
	end

	local character = localPlayer.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			tbl.damageDisplay.lastHealth = humanoid.Health
			tbl.damageDisplay.healthConn = humanoid:GetPropertyChangedSignal("Health"):Connect(tbl.damageDisplay.onHealthChanged)
		end
	end

	tbl.damageDisplay.charConn = tbl.onCharacterAdded(function(arg)
		task.wait(0.2)
		local humanoid = arg:FindFirstChildOfClass("Humanoid")

		if humanoid then
			if tbl.damageDisplay.healthConn then
				tbl.damageDisplay.healthConn:Disconnect()
			end

			tbl.damageDisplay.lastHealth = humanoid.Health
			tbl.damageDisplay.healthConn = humanoid:GetPropertyChangedSignal("Health"):Connect(tbl.damageDisplay.onHealthChanged)
		end

		tbl.damageDisplay.destroyBillboard()
		tbl.damageDisplay.ensureBillboard()
		tbl.damageDisplay.damageQueue = {}
		tbl.damageDisplay.isPlaying = false
	end)

	tbl.damageDisplay.ensureBillboard()
end

tbl.damageDisplay.stop = function()
	if tbl.damageDisplay.healthConn then
		tbl.damageDisplay.healthConn:Disconnect()
	end

	if tbl.damageDisplay.charConn then
		tbl.damageDisplay.charConn()
		tbl.damageDisplay.charConn = nil
	end

	tbl.damageDisplay.destroyBillboard()
	tbl.damageDisplay.damageQueue = {}
	tbl.damageDisplay.isPlaying = false
	tbl.damageDisplay.lastHealth = nil

	if tbl.damageDisplay.fadeTween then
		tbl.damageDisplay.fadeTween:Cancel()
	end
end

tbl.rescueTeammate = { enabled = false, thread = nil, inf = {}, busy = false }

tbl.rescueTeammate.getHRP = function(arg)
	return arg and arg:FindFirstChild("HumanoidRootPart")
end

tbl.rescueTeammate.getPin = function(arg)
	local ok, result = pcall(function()
		return workspace:FindFirstChild("Players")[arg.Name].UserStates.Pin.Value
	end)

	return ok and tostring(result) ~= "None"
end

tbl.rescueTeammate.getInf = function(arg)
	local ok, result = pcall(function()
		return workspace:FindFirstChild("Players")[arg.Name].UserStates.Infected.Value
	end)

	return ok and result or 0
end

tbl.rescueTeammate.hasZombie = function(arg, arg2)
	for _, v26 in workspace:GetDescendants() do
		if v26:IsA("Model") and v26.Name == "m_Zombie" then
			local humanoidRootPart = v26:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart and (humanoidRootPart.Position - arg).Magnitude <= arg2 then
				return true
			end
		end
	end

	return false
end

tbl.rescueTeammate.loop = function()
	while tbl.rescueTeammate.enabled do
		task.wait(0.25)

		if not tbl.rescueTeammate.busy then
			for _, v26 in v4:GetPlayers() do
				if v26 == localPlayer then
					continue
				elseif tbl.rescueTeammate.enabled then
					if tbl.rescueTeammate.inf[v26.Name] == nil then
						tbl.rescueTeammate.inf[v26.Name] = tbl.rescueTeammate.getInf(v26)
					end

					local flag

					if tbl.rescueTeammate.getPin(v26) then
						flag = true
					else
						local v27 = tbl.rescueTeammate.getInf(v26)
						local flag2 = v27 > (tbl.rescueTeammate.inf[v26.Name] or v27) and v27 > 0
						flag = false

						if flag2 then
							local character = v26.Character
							character = character and tbl.rescueTeammate.getHRP(character)
							character = character and tbl.rescueTeammate.hasZombie(character.Position, 2)
							flag = false

							if character then
								local str2 = "感染" .. floor(v27) .. "%"
								flag = true
							end
						end

						tbl.rescueTeammate.inf[v26.Name] = v27
					end

					if flag then
						tbl.rescueTeammate.busy = true
						tbl.rescueTeammate.inf[v26.Name] = tbl.rescueTeammate.getInf(v26)
						local character = localPlayer.Character
						local v27 = character and tbl.rescueTeammate.getHRP(character)

						if not v27 then
							tbl.rescueTeammate.busy = false
						else
							local position = v27.Position
							local character2 = v26.Character
							local v28 = character2 and tbl.rescueTeammate.getHRP(character2)

							if not v28 then
								tbl.rescueTeammate.busy = false
							else
								pcall(function()
									v27.CFrame = cframe(v28.Position + Vector3.new(0, 0.5, 0))
								end)

								local v29 = clock()

								while true do
									if tbl.rescueTeammate.enabled and clock() - v29 < 6 then
										task.wait(0.2)

										if clock() - v29 >= 0.8 then
											if not tbl.rescueTeammate.getPin(v26) then
												local character3 = v26.Character
												local v30 = character3 and tbl.rescueTeammate.getHRP(character3)
												if not (v30 and not tbl.rescueTeammate.hasZombie(v30.Position, 2)) then
													continue
												end
											else
												continue
											end
										else
											continue
										end
									end

									break
								end

								task.wait(0.15)
								local character3 = localPlayer.Character
								character3 = character3 and tbl.rescueTeammate.getHRP(character3)

								if character3 then
									pcall(function()
										character3.CFrame = cframe(position + Vector3.new(0, 1, 0))
									end)
								end

								tbl.rescueTeammate.busy = false
								task.wait(0.5)
							end
						end
					end

					continue
				end

				break
			end
		end
	end
end

tbl.rescueTeammate.start = function()
	if tbl.rescueTeammate.thread then
		return
	end
	tbl.rescueTeammate.enabled = true
	tbl.rescueTeammate.inf = {}
	tbl.rescueTeammate.busy = false
	tbl.rescueTeammate.thread = task.spawn(tbl.rescueTeammate.loop)
	lib:Notify(fn3("🆘 传送救援已开启"), 2)
end

tbl.rescueTeammate.stop = function()
	tbl.rescueTeammate.enabled = false

	if tbl.rescueTeammate.thread then
		task.cancel(tbl.rescueTeammate.thread)
		tbl.rescueTeammate.thread = nil
	end

	tbl.rescueTeammate.inf = {}
	tbl.rescueTeammate.busy = false
	lib:Notify(fn3("🆘 传送救援已关闭"), 2)
end

tbl.elbowZombies = {
	enabled = false,
	thread = nil,
	connections = {},
	currentWeapon = nil,
	WEAPON_LIST = { "Axe", "Baguette", "Pickaxe" },
	DETECT_RANGE = 6,
	CHECK_INTERVAL = 0.3,
}

tbl.elbowZombies.isZombie = function(arg)
	if not arg:IsA("Model") then
		return false
	end
	return arg:FindFirstChild("HumanoidRootPart") ~= nil
end

tbl.elbowZombies.getZombiesInRange = function()
	local character = localPlayer.Character
	if not character then
		return {}
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return {}
	end
	local position = humanoidRootPart.Position
	local zombies = workspace:FindFirstChild("Zombies")
	if not zombies then
		return {}
	end
	local tbl7 = {}

	for _, v26 in zombies:GetChildren() do
		if tbl.elbowZombies.isZombie(v26) then
			local humanoidRootPart2 = v26:FindFirstChild("HumanoidRootPart") or v26:FindFirstChild("Torso")

			if humanoidRootPart2 and (humanoidRootPart2.Position - position).Magnitude <= tbl.elbowZombies.DETECT_RANGE then
				table.insert(tbl7, v26)
			end
		end
	end

	return tbl7
end

tbl.elbowZombies.getBestWeapon = function()
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return nil
	end

	for _, v26 in tbl.elbowZombies.WEAPON_LIST, nil, nil do
		local v27 = backpack:FindFirstChild(v26)
		if v27 and v27:IsA("Tool") then
			return v27
		end
	end

	return nil
end

tbl.elbowZombies.equipWeapon = function(arg)
	if not arg then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end

	if arg.Parent ~= character then
		arg.Parent = character
		task.wait(0.02)
	end
end

tbl.elbowZombies.unequipWeapon = function(arg)
	if not arg then
		return
	end

	if arg.Parent == localPlayer.Character then
		arg.Parent = localPlayer.Backpack
	end
end

tbl.elbowZombies.elbowZombie = function(arg)
	local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart") or arg:FindFirstChild("Torso")
	if not humanoidRootPart then
		return
	end
	local tool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local remoteEvent = tool:FindFirstChild("RemoteEvent")
	if not remoteEvent then
		return
	end

	pcall(function()
		remoteEvent:FireServer("BraceBlock")
		remoteEvent:FireServer("StopBraceBlock")
		remoteEvent:FireServer("FeedbackStun", arg, humanoidRootPart.Position)
	end)
end

tbl.elbowZombies.elbowAll = function(arg)
	for _, v26 in arg, nil, nil do
		tbl.elbowZombies.elbowZombie(v26)
	end
end

tbl.elbowZombies.mainLoop = function()
	while tbl.elbowZombies.enabled do
		local v26 = tbl.elbowZombies.getZombiesInRange()

		if #v26 > 0 then
			local v27 = tbl.elbowZombies.getBestWeapon()

			if v27 then
				tbl.elbowZombies.equipWeapon(v27)
				tbl.elbowZombies.currentWeapon = v27
			end

			tbl.elbowZombies.elbowAll(v26)
		else
			if tbl.elbowZombies.currentWeapon and tbl.elbowZombies.currentWeapon.Parent == localPlayer.Character then
				tbl.elbowZombies.unequipWeapon(tbl.elbowZombies.currentWeapon)
			end

			tbl.elbowZombies.currentWeapon = nil
		end

		task.wait(tbl.elbowZombies.CHECK_INTERVAL)
	end
end

tbl.elbowZombies.start = function()
	if tbl.elbowZombies.thread then
		return
	end
	tbl.elbowZombies.enabled = true
	tbl.elbowZombies.thread = task.spawn(tbl.elbowZombies.mainLoop)
end

tbl.elbowZombies.stop = function()
	tbl.elbowZombies.enabled = false

	if tbl.elbowZombies.thread then
		task.cancel(tbl.elbowZombies.thread)
		tbl.elbowZombies.thread = nil
	end

	local character = localPlayer.Character

	if character then
		for _, v26 in tbl.elbowZombies.WEAPON_LIST, nil, nil do
			local v27 = character:FindFirstChild(v26)

			if v27 then
				v27.Parent = localPlayer.Backpack
			end
		end
	end

	tbl.elbowZombies.currentWeapon = nil
end

tbl.pushBarrelProtect = {
	enabled = false,
	size = 10,
	normalForce = 45,
	normalUp = 15,
	slideForce = 85,
	verticalThreshold = 3,
	thread = nil,
}

tbl.pushBarrelProtect.getRadii = function()
	local n2 = tbl.pushBarrelProtect.size / 10
	return clamp(16 * n2, 5, 25), (clamp(5 * n2, 2, 8))
end

tbl.pushBarrelProtect.isBarrel = function(arg)
	return arg:GetAttribute("Type") == "Barrel" or arg:FindFirstChild("Barrel")
end

tbl.pushBarrelProtect.getActiveBarrels = function()
	local tbl7 = {}
	local zombies = workspace:FindFirstChild("Zombies")
	if not zombies then
		return tbl7
	end

	for _, v26 in zombies:GetChildren() do
		if v26:IsA("Model") and tbl.pushBarrelProtect.isBarrel(v26) then
			local humanoidRootPart = v26:FindFirstChild("HumanoidRootPart") or v26:FindFirstChild("Torso") or v26:FindFirstChild("Head")

			if humanoidRootPart then
				table.insert(tbl7, humanoidRootPart.Position)
			end
		end
	end

	return tbl7
end

tbl.pushBarrelProtect.isPointInEllipsoid = function(arg, arg2, arg3, arg4)
	local n2 = arg.X - arg2.X
	local n3 = arg.Y - arg2.Y
	local n4 = arg.Z - arg2.Z
	return (n2 * n2 + n4 * n4) / arg3 * arg3 + n3 * n3 / arg4 * arg4 < 1
end

tbl.pushBarrelProtect.applyPush = function()
	if not tbl.pushBarrelProtect.enabled then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	local position = humanoidRootPart.Position
	local v26, v27 = tbl.pushBarrelProtect.getRadii()

	for _, v28 in tbl.pushBarrelProtect.getActiveBarrels(), nil, nil do
		if tbl.pushBarrelProtect.isPointInEllipsoid(position, v28, v26, v27) then
			local n2 = position - v28

			if tbl.pushBarrelProtect.verticalThreshold < abs(n2.Y) then
				local v29 = vector(n2.X, 0, n2.Z)
				local vector3

				if v29.Magnitude < 0.001 then
					vector3 = Vector3.new(1, 0, 0)
				else
					vector3 = v29.Unit
				end

				local n3 = vector3 * tbl.pushBarrelProtect.slideForce
				humanoidRootPart.AssemblyLinearVelocity = vector(n3.X, humanoidRootPart.AssemblyLinearVelocity.Y, n3.Z)
			else
				local unit = n2.Unit

				if unit.Magnitude < 0.001 then
					unit = Vector3.new(1, 0, 0)
				end

				humanoidRootPart.AssemblyLinearVelocity = unit * tbl.pushBarrelProtect.normalForce + vector(0, tbl.pushBarrelProtect.normalUp, 0)
			end

			break
		end
	end
end

tbl.pushBarrelProtect.loop = function()
	while tbl.pushBarrelProtect.enabled do
		tbl.pushBarrelProtect.applyPush()
		task.wait(0.05)
	end
end

tbl.pushBarrelProtect.start = function()
	if tbl.pushBarrelProtect.thread then
		return
	end
	tbl.pushBarrelProtect.enabled = true
	tbl.pushBarrelProtect.thread = task.spawn(tbl.pushBarrelProtect.loop)
end

tbl.pushBarrelProtect.stop = function()
	tbl.pushBarrelProtect.enabled = false

	if tbl.pushBarrelProtect.thread then
		task.cancel(tbl.pushBarrelProtect.thread)
		tbl.pushBarrelProtect.thread = nil
	end
end

tbl.autoHelp = { enabled = false, thread = nil }

tbl.autoHelp.getHealth = function()
	local character = localPlayer.Character
	character = character and character:FindFirstChildOfClass("Humanoid")
	return character and character.Health or 0
end

tbl.autoHelp.getMaxHealth = function()
	local character = localPlayer.Character
	character = character and character:FindFirstChildOfClass("Humanoid")
	return character and character.MaxHealth or 100
end

tbl.autoHelp.triggerHelp = function()
	local character = localPlayer.Character
	if not character then
		return false
	end
	local triggerVoice = character:FindFirstChild("TriggerVoice")

	if triggerVoice and triggerVoice:IsA("RemoteEvent") then
		pcall(function()
			triggerVoice:FireServer("CalloutGeneral", "Help")
		end)

		return true
	end

	return false
end

tbl.autoHelp.loop = function()
	while tbl.autoHelp.enabled do
		task.wait(3)

		if not (tbl.autoHelp.getHealth() / tbl.autoHelp.getMaxHealth() * 100 >= 80) then
			tbl.autoHelp.triggerHelp()
		end
	end
end

tbl.autoHelp.start = function()
	if tbl.autoHelp.thread then
		return
	end
	tbl.autoHelp.enabled = true
	tbl.autoHelp.thread = task.spawn(tbl.autoHelp.loop)
end

tbl.autoHelp.stop = function()
	tbl.autoHelp.enabled = false

	if tbl.autoHelp.thread then
		task.cancel(tbl.autoHelp.thread)
		tbl.autoHelp.thread = nil
	end
end

tbl.playerESPInstances = {}
tbl.playerESPModels = {}
tbl.espPlayerEnabled = false
tbl.espShowNames = false
tbl.espShowHealth = false
tbl.espTeamCheckPlayer = false
tbl.playerESPRefreshThread = nil
tbl.playerESPCharAddedConn = nil

tbl.getPlayerTeam = function(arg)
	if arg.Team then
		return arg.Team
	end
	local attribute = arg:GetAttribute("Team")
	if attribute then
		return attribute
	end
	local character = arg.Character

	if character then
		local teamTag = character:FindFirstChild("TeamTag") or character:FindFirstChild("Team")
		if teamTag then
			return teamTag.Value
		end
	end

	return nil
end

tbl.isSameTeam = function(arg)
	if not tbl.espTeamCheckPlayer then
		return false
	end
	local v26 = tbl.getPlayerTeam(localPlayer)
	local v27 = tbl.getPlayerTeam(arg)
	if v26 and v27 then
		return v26 == v27
	end
	return false
end

tbl.getColorsForPlayer = function(arg)
	if not tbl.espTeamCheckPlayer then
		return { highlight = color(255, 255, 255), dot = color(160, 160, 160), name = color(255, 255, 255) }
	end

	if tbl.isSameTeam(arg) then
		return { highlight = color(100, 150, 255), dot = color(0, 30, 180), name = color(100, 150, 255) }
	end
	return { highlight = color(255, 100, 100), dot = color(180, 0, 0), name = color(255, 100, 100) }
end

tbl.destroyPlayerComponents = function(arg)
	local v26 = tbl.playerESPInstances[arg]

	if v26 ~= nil then
		tbl.destroyESP(v26)
		tbl.playerESPInstances[arg] = nil
	end

	tbl.playerESPModels[arg] = nil
end

tbl.buildPlayerESPName = function(arg, arg2)
	local tbl7 = {}

	if tbl.espShowNames then
		tbl7[#tbl7 + 1] = arg.Name
	end

	if tbl.espShowHealth then
		local humanoid = arg2:FindFirstChildOfClass("Humanoid")
		tbl7[#tbl7 + 1] = (humanoid and floor(humanoid.Health / humanoid.MaxHealth * 100) or 100) .. "%"
	end

	if tbl.infectionEnabled then
		tbl7[#tbl7 + 1] = format(str == "English" and "Infection: %d%%" or "感染: %d%%", tbl.getInfectionForPlayer(arg))
	end

	if tbl.jobEnabled then
		tbl7[#tbl7 + 1] = fn3(tbl.getPlayerClass(arg))
	end

	if #tbl7 == 0 then
		return ""
	end
	return table.concat(tbl7, " | ")
end

tbl.updatePlayerESP = function(arg)
	local v26 = tbl.playerESPInstances[arg]

	if not tbl.espPlayerEnabled then
		if v26 ~= nil then
			tbl.destroyESP(v26)
			tbl.playerESPInstances[arg] = nil
			tbl.playerESPModels[arg] = nil
		end

		return
	end

	local character = arg.Character

	if not character or character == localPlayer.Character then
		if v26 ~= nil then
			tbl.destroyESP(v26)
			tbl.playerESPInstances[arg] = nil
			tbl.playerESPModels[arg] = nil
		end

		return
	end

	if not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if v26 ~= nil and (v26.Deleted or tbl.playerESPModels[arg] ~= character) then
		tbl.destroyESP(v26)
		tbl.playerESPInstances[arg] = nil
		tbl.playerESPModels[arg] = nil
		v26 = nil
	end

	local v27 = tbl.getColorsForPlayer(arg)
	local v28 = tbl.buildPlayerESPName(arg, character)

	if v26 == nil then
		local v29 = tbl.addESP({
			Name = v28,
			Model = character,
			Color = v27.highlight,
			MaxDistance = 300,
			TextSize = 14,
			ESPType = "Highlight",
			FillColor = v27.highlight,
			OutlineColor = v27.highlight,
			FillTransparency = 0.5,
			OutlineTransparency = 0,
		})

		if v29 == nil then
			return
		end
		tbl.playerESPInstances[arg] = v29
		tbl.playerESPModels[arg] = character
		return
	end

	local currentSettings = v26.CurrentSettings
	currentSettings.Name = v28
	currentSettings.Color = v27.highlight
	currentSettings.FillColor = v27.highlight
	currentSettings.OutlineColor = v27.highlight
end

tbl.refreshAllPlayers = function()
	for _, v26 in v4:GetPlayers() do
		tbl.updatePlayerESP(v26)
	end
end

tbl.startPlayerESPRefresh = function()
	if tbl.playerESPRefreshThread then
		return
	end

	tbl.playerESPRefreshThread = task.spawn(function()
		while tbl.espPlayerEnabled do
			task.wait(0.2)

			for _, v26 in v4:GetPlayers() do
				tbl.updatePlayerESP(v26)
			end
		end

		tbl.playerESPRefreshThread = nil
	end)
end

tbl.stopPlayerESPRefresh = function()
	if tbl.playerESPRefreshThread then
		task.cancel(tbl.playerESPRefreshThread)
		tbl.playerESPRefreshThread = nil
	end
end

local function fn9()
	v4.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)

			if tbl.espPlayerEnabled then
				tbl.updatePlayerESP(player)
			end
		end)

		player.CharacterRemoving:Connect(function()
			tbl.destroyPlayerComponents(player)
		end)

		if tbl.espPlayerEnabled then
			tbl.updatePlayerESP(player)
		end
	end)

	v4.PlayerRemoving:Connect(function(player)
		tbl.destroyPlayerComponents(player)
	end)

	tbl.onCharacterAdded(function()
		task.wait(0.5)

		if tbl.espPlayerEnabled then
			tbl.refreshAllPlayers()
		end
	end)
end

fn9()
tbl.infectionEnabled = false
tbl.infectionUpdateConn = nil
tbl.jobEnabled = false
tbl.jobUpdateConn = nil

tbl.createInfectionUI = function()
	return nil
end

tbl.removeInfectionUI = function()
end

tbl.updateAllInfection = function()
	tbl.refreshAllPlayers()
end

tbl.startInfectionUpdating = function()
	tbl.refreshAllPlayers()
end

tbl.getInfectionForPlayer = function(arg)
	if not arg then
		return 0
	end
	local n2 = 0

	pcall(function()
		local players = workspace:FindFirstChild("Players")

		if players then
			local v26 = players:FindFirstChild(arg.Name)

			if v26 and v26:FindFirstChild("UserStates") then
				local infected = v26.UserStates:FindFirstChild("Infected")
				if infected then
					n2 = tonumber(infected.Value) or 0
					return
				end
			end
		end

		if arg:FindFirstChild("UserStates") then
			local infected = arg.UserStates:FindFirstChild("Infected")

			if infected then
				n2 = tonumber(infected.Value) or 0
			end
		end
	end)

	return n2
end

tbl.getPlayerClass = function(arg)
	if not arg then
		return "未知"
	end
	local character = arg.Character
	local attribute = arg:GetAttribute("CurrentClass")
	local attribute2

	if not attribute or attribute == "" then
		if character then
			attribute2 = character:GetAttribute("CurrentClass")
		else
			attribute2 = attribute
		end
	else
		attribute2 = attribute
	end

	local tbl7 = {
		Officer = "军官",
		LineInfantry = "线列",
		Sapper = "工兵",
		Surgeon = "医生",
		Chaplain = "牧师",
		Musician = "乐手",
		Seaman = "水手",
		Lancer = "枪骑兵",
		Artillerist = "炮兵",
	}

	if attribute2 and tbl7[attribute2] then
		return tbl7[attribute2]
	end

	if character then
		if character:FindFirstChild("MedicalSupplies") or character:FindFirstChild("Meter") then
			return "医生"
		end

		if character:FindFirstChild("Blessing") then
			return "牧师"
		end

		if character:FindFirstChild("Hammer") or character:FindFirstChild("Pickaxe") or character:FindFirstChild("Axe") then
			return "工兵"
		end

		if character:FindFirstChild("Sabre") then
			return "军官"
		end

		if character:FindFirstChild("Musket") or character:FindFirstChild("Carbine") then
			return "线列"
		end

		if character:FindFirstChild("Fife") or character:FindFirstChild("Drum") then
			return "乐手"
		end
	end

	return "这个是gay"
end

tbl.createJobUI = function()
	return nil
end

tbl.removeJobUI = function()
end

tbl.updateAllJob = function()
	tbl.refreshAllPlayers()
end

tbl.startJobUpdating = function()
	tbl.jobEnabled = true
	tbl.refreshAllPlayers()
end

tbl.stopJobUpdating = function()
	tbl.jobEnabled = false
	tbl.refreshAllPlayers()
end

tbl.stopInfectionUpdating = function()
	tbl.refreshAllPlayers()
end

tbl.boomDraw = tbl.boomDraw or {}
tbl.boomDraw.enabled = false
tbl.boomDraw.markers = {}
tbl.boomDraw.zombieConns = {}
tbl.boomDraw.connection = nil
tbl.boomDraw.zombieAddedDisposer = nil

tbl.boomDraw.unwatchZombie = function(arg)
	local v26 = tbl.boomDraw.zombieConns[arg]

	if v26 then
		for _, v27 in v26, nil, nil do
			pcall(function()
				v27:Disconnect()
			end)
		end

		tbl.boomDraw.zombieConns[arg] = nil
	end
end

tbl.boomDraw.addMarker = function(arg)
	if tbl.boomDraw.markers[arg] then
		return
	end

	if not arg:IsA("Model") then
		return
	end

	local v26 = tbl.addESP({
		Name = "3.50",
		Model = arg,
		Color = color(255, 200, 0),
		MaxDistance = 1000,
		TextSize = 20,
		ESPType = "Text",
	})

	if v26 == nil then
		return
	end
	tbl.boomDraw.markers[arg] = { esp = v26, start = clock() }
end

tbl.boomDraw.removeMarker = function(arg)
	local v26 = tbl.boomDraw.markers[arg]

	if v26 then
		tbl.destroyESP(v26.esp)
		tbl.boomDraw.markers[arg] = nil
	end

	tbl.boomDraw.unwatchZombie(arg)
end

tbl.boomDraw.clearAllMarkers = function()
	for k, v26 in tbl.boomDraw.markers, nil, nil do
		tbl.destroyESP(v26.esp)
		tbl.boomDraw.markers[k] = nil
	end

	tbl.boomDraw.markers = {}

	for k in tbl.boomDraw.zombieConns, nil, nil do
		tbl.boomDraw.unwatchZombie(k)
	end
end

tbl.boomDraw.watchZombie = function(arg)
	if not arg:IsA("Model") then
		return
	end

	if tbl.boomDraw.zombieConns[arg] then
		return
	end
	local state = arg:FindFirstChild("State")

	if not state then
		local n2 = 0

		while not state and n2 < 5 do
			task.wait(0.25)
			n2 += 0.25
			state = arg:FindFirstChild("State")
		end

		if not state then
			return
		end
	end

	if not tbl.boomDraw.enabled or tbl.boomDraw.zombieConns[arg] then
		return
	end
	local tbl7 = {}

	tbl7[#tbl7 + 1] = state.ChildAdded:Connect(function(child)
		if child.Name == "Lit" and child:IsA("BoolValue") and tbl.boomDraw.enabled then
			tbl.boomDraw.addMarker(arg)
		end
	end)

	tbl7[#tbl7 + 1] = state.ChildRemoved:Connect(function(child)
		if child.Name == "Lit" then
			tbl.boomDraw.removeMarker(arg)
		end
	end)

	tbl.boomDraw.zombieConns[arg] = tbl7

	if state:FindFirstChild("Lit") and tbl.boomDraw.enabled then
		tbl.boomDraw.addMarker(arg)
	end
end

tbl.boomDraw.setupWatchers = function()
	tbl.ZombieWatch.start()
	local zombies = workspace:FindFirstChild("Zombies")

	local function fn10(arg)
		if zombies and arg.Parent ~= zombies then
			return
		end
		task.spawn(tbl.boomDraw.watchZombie, arg)
	end

	tbl.ZombieWatch.forEach(fn10)

	if not tbl.boomDraw.zombieAddedDisposer then
		tbl.boomDraw.zombieAddedDisposer = tbl.ZombieWatch.onAdded(fn10)
	end
end

tbl.boomDraw.start = function()
	if tbl.boomDraw.enabled then
		return
	end
	tbl.boomDraw.enabled = true
	tbl.boomDraw.clearAllMarkers()
	tbl.boomDraw.setupWatchers()

	if tbl.boomDraw.connection then
		tbl.boomDraw.connection:Disconnect()
	end

	tbl.boomDraw.connection = v5.RenderStepped:Connect(function()
		if not tbl.boomDraw.enabled then
			return
		end

		for k, v26 in tbl.boomDraw.markers, nil, nil do
			if not k or not k.Parent then
				tbl.boomDraw.removeMarker(k)
			elseif v26.esp == nil or v26.esp.Deleted then
				tbl.boomDraw.removeMarker(k)
			else
				local start = v26.start
				local n2 = 3.5 - clock() - start

				if n2 <= 0 then
					tbl.boomDraw.removeMarker(k)
				else
					local currentSettings = v26.esp.CurrentSettings
					currentSettings.Name = format("%.2f", n2)
					currentSettings.Color = color(255, floor(200 * n2 / 4), 0)
				end
			end
		end
	end)
end

tbl.boomDraw.stop = function()
	tbl.boomDraw.enabled = false

	if tbl.boomDraw.connection then
		tbl.boomDraw.connection:Disconnect()
		tbl.boomDraw.connection = nil
	end

	if tbl.boomDraw.zombieAddedDisposer then
		tbl.boomDraw.zombieAddedDisposer()
		tbl.boomDraw.zombieAddedDisposer = nil
	end

	tbl.boomDraw.clearAllMarkers()
end

tbl.bulletDisplay = {
	enabled = false,
	billboardGui = nil,
	screenGui = nil,
	billLabel = nil,
	screenLabel = nil,
	connection = nil,
	cameraConn = nil,
}

tbl.bulletDisplay.isFirstPerson = function()
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		return false
	end
	local character = localPlayer.Character
	if not character then
		return false
	end
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return false
	end
	return (currentCamera.CFrame.Position - head.Position).Magnitude < 0.7
end

tbl.bulletDisplay.createUI = function()
	if tbl.bulletDisplay.billboardGui and tbl.bulletDisplay.screenGui then
		return
	end
	local character = localPlayer.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not head then
		return
	end
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "BulletDisplay_Billboard"
	billboardGui.Size = UDim2.new(0, 100, 0, 30)
	billboardGui.StudsOffset = Vector3.new(-3, 0.3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 50
	billboardGui.Adornee = head
	billboardGui.Parent = character
	billboardGui.Enabled = false
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = fn3("子弹: 0")
	textLabel.TextColor3 = color(0, 255, 0)
	textLabel.TextSize = 16
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0.3
	textLabel.TextStrokeColor3 = color(0, 0, 0)
	textLabel.Parent = billboardGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BulletDisplay_Screen"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
	screenGui.Enabled = false
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Size = UDim2.new(0, 120, 0, 40)
	textLabel2.Position = UDim2.new(0.02, 0, 0.48, 0)
	textLabel2.AnchorPoint = Vector2.new(0, 0)
	textLabel2.BackgroundTransparency = 1
	textLabel2.Text = fn3("子弹: 0")
	textLabel2.TextColor3 = color(0, 255, 0)
	textLabel2.TextSize = 20
	textLabel2.Font = Enum.Font.GothamBold
	textLabel2.TextStrokeTransparency = 0.3
	textLabel2.TextStrokeColor3 = color(0, 0, 0)
	textLabel2.Parent = screenGui
	tbl.bulletDisplay.billboardGui = billboardGui
	tbl.bulletDisplay.screenGui = screenGui
	tbl.bulletDisplay.billLabel = textLabel
	tbl.bulletDisplay.screenLabel = textLabel2
end

tbl.bulletDisplay.destroyUI = function()
	if tbl.bulletDisplay.billboardGui then
		tbl.bulletDisplay.billboardGui:Destroy()
	end

	if tbl.bulletDisplay.screenGui then
		tbl.bulletDisplay.screenGui:Destroy()
	end

	tbl.bulletDisplay.billboardGui = nil
	tbl.bulletDisplay.screenGui = nil
	tbl.bulletDisplay.billLabel = nil
	tbl.bulletDisplay.screenLabel = nil
end

tbl.bulletDisplay.updateVisibility = function()
	if not tbl.bulletDisplay.enabled then
		return
	end

	if not tbl.bulletDisplay.billboardGui or not tbl.bulletDisplay.screenGui then
		return
	end
	local v26 = tbl.bulletDisplay.isFirstPerson()
	tbl.bulletDisplay.billboardGui.Enabled = not v26
	tbl.bulletDisplay.screenGui.Enabled = v26
end

tbl.bulletDisplay.isGun = tbl.sharedIsGun

tbl.bulletDisplay.getBullets = function()
	local character = localPlayer.Character
	if not character then
		return 0
	end
	local tool = character:FindFirstChildOfClass("Tool")
	local n2

	if tool and tbl.bulletDisplay.isGun(tool) then
		local shotsLoaded = tool:FindFirstChild("ShotsLoaded")
		local isIntValue = shotsLoaded and (shotsLoaded:IsA("IntValue") or shotsLoaded:IsA("NumberValue"))
		n2 = 0

		if isIntValue then
			n2 = shotsLoaded.Value
		end
	else
		local backpack = localPlayer:FindFirstChild("Backpack")
		n2 = 0

		if backpack then
			for _, v26 in backpack:GetChildren() do
				if v26:IsA("Tool") and tbl.bulletDisplay.isGun(v26) then
					local shotsLoaded = v26:FindFirstChild("ShotsLoaded")

					if shotsLoaded and (shotsLoaded:IsA("IntValue") or shotsLoaded:IsA("NumberValue")) then
						local value = shotsLoaded.Value

						if n2 < value then
							n2 = value
						end
					end
				end
			end
		end
	end

	return n2
end

tbl.bulletDisplay.updateLabels = function()
	if not tbl.bulletDisplay.enabled then
		return
	end
	local v26 = tbl.bulletDisplay.getBullets()
	local text = (str == "English" and "Bullets: " or "子弹: ") .. tostring(v26)
	local textColor3 = v26 > 0 and color(0, 255, 0) or color(255, 0, 0)

	if tbl.bulletDisplay.billLabel then
		tbl.bulletDisplay.billLabel.Text = text
		tbl.bulletDisplay.billLabel.TextColor3 = textColor3
	end

	if tbl.bulletDisplay.screenLabel then
		tbl.bulletDisplay.screenLabel.Text = text
		tbl.bulletDisplay.screenLabel.TextColor3 = textColor3
	end
end

tbl.bulletDisplay.update = function()
	if not tbl.bulletDisplay.enabled then
		if tbl.bulletDisplay.connection then
			tbl.bulletDisplay.connection:Disconnect()
		end

		if tbl.bulletDisplay.cameraConn then
			tbl.bulletDisplay.cameraConn:Disconnect()
		end

		return
	end

	local character = localPlayer.Character

	if not character then
		tbl.bulletDisplay.destroyUI()
		tbl.bulletDisplay.createUI()
		return
	end

	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")

	if tbl.bulletDisplay.billboardGui and tbl.bulletDisplay.billboardGui.Adornee ~= head then
		tbl.bulletDisplay.destroyUI()
		tbl.bulletDisplay.createUI()
	end

	if not tbl.bulletDisplay.billboardGui or not tbl.bulletDisplay.screenGui then
		tbl.bulletDisplay.createUI()
	end

	tbl.bulletDisplay.updateLabels()
	tbl.bulletDisplay.updateVisibility()
end

tbl.bulletDisplay.start = function()
	if tbl.bulletDisplay.enabled then
		return
	end
	tbl.bulletDisplay.enabled = true
	tbl.bulletDisplay.createUI()

	if tbl.bulletDisplay.connection then
		tbl.bulletDisplay.connection:Disconnect()
	end

	tbl.bulletDisplay.connection = v5.Heartbeat:Connect(tbl.bulletDisplay.update)

	if tbl.bulletDisplay.cameraConn then
		tbl.bulletDisplay.cameraConn:Disconnect()
	end

	tbl.bulletDisplay.cameraConn = v5.RenderStepped:Connect(function()
		if tbl.bulletDisplay.enabled then
			tbl.bulletDisplay.updateVisibility()
		end
	end)

	tbl.bulletDisplay.update()
end

tbl.bulletDisplay.stop = function()
	tbl.bulletDisplay.enabled = false

	if tbl.bulletDisplay.connection then
		tbl.bulletDisplay.connection:Disconnect()
	end

	if tbl.bulletDisplay.cameraConn then
		tbl.bulletDisplay.cameraConn:Disconnect()
	end

	tbl.bulletDisplay.destroyUI()
end

tbl.Tracer = { enabled = false, conn = nil, tracking = {} }

tbl.Tracer.toggle = function(enabled)
	tbl.Tracer.enabled = enabled

	if enabled then
		if tbl.Tracer.conn then
			tbl.Tracer.conn:Disconnect()
		end

		tbl.Tracer.conn = workspace.DescendantAdded:Connect(function(descendant)
			if not tbl.Tracer.enabled then
				return
			end

			if not descendant:IsA("PointLight") then
				return
			end

			if tbl.Tracer.tracking[descendant] then
				return
			end
			local parent = descendant.Parent
			if not parent or not parent:IsA("BasePart") then
				return
			end
			local position = parent.Position
			tbl.Tracer.tracking[descendant] = { obj = parent, pos1 = position }

			task.spawn(function()
				task.wait(0.1)
				local v26 = tbl.Tracer.tracking[descendant]
				if not v26 then
					return
				end
				local obj = v26.obj
				if not obj or not obj.Parent or not descendant.Parent then
					tbl.Tracer.tracking[descendant] = nil
					return
				end
				local position2 = obj.Position
				local n2 = position2 - position
				if n2.Magnitude < 0.3 then
					tbl.Tracer.tracking[descendant] = nil
					return
				end
				local unit = n2.Unit
				tbl.Tracer.tracking[descendant] = nil
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				local filterDescendantsInstances = { obj }

				while obj.Parent and not obj.Parent:IsA("Workspace") do
					obj = obj.Parent
					table.insert(filterDescendantsInstances, obj)
				end

				raycastParams.FilterDescendantsInstances = filterDescendantsInstances
				local hit = workspace:Raycast(position2 + unit * 2, unit * 500, raycastParams)
				hit = hit and hit.Position or position + unit * 500
				local n3 = hit - position
				local magnitude = n3.Magnitude
				if magnitude < 0.1 then
					return
				end
				local part = Instance.new("Part")
				part.Name = "_Tracer"
				part.Size = vector(0.05, 0.05, magnitude)
				part.Color = color(255, 255, 0)
				part.Material = Enum.Material.Neon
				part.Anchored = true
				part.CanCollide = false
				part.CFrame = CFrame.lookAt(position + n3 * 0.5, hit)
				part.Parent = workspace
				local v27 = clock()

				while clock() - v27 < 3 and part.Parent do
					part.Transparency = (clock() - v27) / 3
					task.wait(0.05)
				end

				pcall(part.Destroy, part)
			end)
		end)
	else
		if tbl.Tracer.conn then
			tbl.Tracer.conn:Disconnect()
			tbl.Tracer.conn = nil
		end

		tbl.Tracer.tracking = {}
	end
end

tbl.cannonSupplies = { enabled = false, highlights = {} }

tbl.cannonSupplies.createHighlightForPart = function(arg, arg2)
	local v26 = tbl.addESP({
		Name = arg2,
		Model = arg,
		Color = color(0, 255, 255),
		MaxDistance = 1000,
		TextSize = 14,
		ESPType = "Highlight",
		FillColor = color(0, 255, 255),
		OutlineColor = color(255, 255, 255),
		FillTransparency = 0.5,
		OutlineTransparency = 0.3,
	})

	if v26 ~= nil then
		table.insert(tbl.cannonSupplies.highlights, v26)
	end
end

tbl.cannonSupplies.createHighlights = function()
	tbl.cannonSupplies.removeHighlights()
	local vardohusFortress = workspace:FindFirstChild("Vardohus Fortress")
	local modes = vardohusFortress and vardohusFortress:FindFirstChild("Modes")
	modes = modes and modes:FindFirstChild("Objective")
	modes = modes and modes:FindFirstChild("CannonSupplies")
	if not modes then
		return
	end

	for _, v26 in modes:GetChildren() do
		if v26:IsA("Folder") then
			local swab = v26:FindFirstChild("Swab")
			local n12LbRoundshots = v26:FindFirstChild("12 lb. Roundshots")

			if swab then
				tbl.cannonSupplies.createHighlightForPart(swab, "Swab")
			end

			if n12LbRoundshots then
				tbl.cannonSupplies.createHighlightForPart(n12LbRoundshots, "12 lb. Roundshots")
			end
		end
	end
end

tbl.cannonSupplies.removeHighlights = function()
	for _, v26 in tbl.cannonSupplies.highlights, nil, nil do
		tbl.destroyESP(v26)
	end

	tbl.cannonSupplies.highlights = {}
end

tbl.cannonSupplies.toggle = function(enabled)
	tbl.cannonSupplies.enabled = enabled

	if enabled then
		tbl.cannonSupplies.createHighlights()
	else
		tbl.cannonSupplies.removeHighlights()
	end
end

tbl.killSound = { selectedId = "5700183626", volume = 7, enabled = false, thread = nil, lastCount = 0 }

tbl.killSound.getCurrentCount = function()
	local leaderstats = localPlayer:FindFirstChild("leaderstats")

	if leaderstats then
		local kills = leaderstats:FindFirstChild("Kills")
		if kills and (kills:IsA("IntValue") or kills:IsA("NumberValue")) then
			return kills.Value
		end
	end

	return 0
end

tbl.killSound.play = function()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tbl.killSound.selectedId
	sound.Volume = tbl.killSound.volume / 10
	sound.Parent = workspace
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
	end)

	task.delay(0.5, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

tbl.killSound.loop = function()
	while tbl.killSound.enabled do
		local v26 = tbl.killSound.getCurrentCount()

		if tbl.killSound.lastCount < v26 then
			for i = 1, v26 - tbl.killSound.lastCount do
				tbl.killSound.play()
			end

			tbl.killSound.lastCount = v26
		elseif v26 < tbl.killSound.lastCount then
			tbl.killSound.lastCount = v26
		end

		task.wait(0.1)
	end
end

tbl.killSound.start = function()
	if tbl.killSound.thread then
		return
	end
	tbl.killSound.enabled = true
	tbl.killSound.lastCount = tbl.killSound.getCurrentCount()
	tbl.killSound.thread = task.spawn(tbl.killSound.loop)
end

tbl.killSound.stop = function()
	tbl.killSound.enabled = false

	if tbl.killSound.thread then
		task.cancel(tbl.killSound.thread)
		tbl.killSound.thread = nil
	end
end

tbl.pingDisplay = { gui = nil, label = nil, conn = nil }

tbl.pingDisplay.start = function()
	if tbl.pingDisplay.gui then
		return
	end
	tbl.pingDisplay.gui = Instance.new("ScreenGui")
	tbl.pingDisplay.gui.Name = "PingDisplay"
	tbl.pingDisplay.gui.ResetOnSpawn = false
	tbl.pingDisplay.gui.Parent = localPlayer:WaitForChild("PlayerGui")
	local frame = Instance.new("Frame")
	frame.Parent = tbl.pingDisplay.gui
	frame.Size = UDim2.new(0, 120, 0, 30)
	frame.Position = UDim2.new(1, -130, 0, 10)
	frame.BackgroundColor3 = color(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = frame
	tbl.pingDisplay.label = Instance.new("TextLabel")
	tbl.pingDisplay.label.Parent = frame
	tbl.pingDisplay.label.Size = UDim2.new(1, 0, 1, 0)
	tbl.pingDisplay.label.BackgroundTransparency = 1
	tbl.pingDisplay.label.Text = fn3("延迟: -- ms")
	tbl.pingDisplay.label.TextColor3 = color(255, 255, 255)
	tbl.pingDisplay.label.TextSize = 14
	tbl.pingDisplay.label.Font = Enum.Font.GothamBold

	tbl.pingDisplay.conn = v5.Heartbeat:Connect(function()
		if not tbl.pingDisplay.gui then
			return
		end

		local ok, result = pcall(function()
			return v10.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)

		if ok and result then
			tbl.pingDisplay.label.Text = (str == "English" and "Ping: " or "延迟: ") .. floor(result) .. " ms"

			if result >= 120 then
				tbl.pingDisplay.label.TextColor3 = color(255, 80, 80)
			elseif result >= 80 then
				tbl.pingDisplay.label.TextColor3 = color(255, 255, 0)
			else
				tbl.pingDisplay.label.TextColor3 = color(0, 255, 0)
			end
		end
	end)
end

tbl.pingDisplay.stop = function()
	if tbl.pingDisplay.conn then
		tbl.pingDisplay.conn:Disconnect()
		tbl.pingDisplay.conn = nil
	end

	if tbl.pingDisplay.gui then
		tbl.pingDisplay.gui:Destroy()
		tbl.pingDisplay.gui = nil
	end

	tbl.pingDisplay.label = nil
end

tbl.infectionRemover = { enabled = false, conn = nil }

tbl.infectionRemover.start = function()
	if tbl.infectionRemover.conn then
		return
	end
	tbl.infectionRemover.enabled = true

	tbl.infectionRemover.conn = v5.Heartbeat:Connect(function()
		if not tbl.infectionRemover.enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local userStates = character:FindFirstChild("UserStates")

		if userStates then
			local infected = userStates:FindFirstChild("Infected")

			if infected then
				infected.Value = "0"
			end
		end
	end)
end

tbl.infectionRemover.stop = function()
	tbl.infectionRemover.enabled = false

	if tbl.infectionRemover.conn then
		tbl.infectionRemover.conn:Disconnect()
		tbl.infectionRemover.conn = nil
	end
end

tbl.bombRange = { enabled = false, spheres = {}, conn = nil, warned = false, damageDisplay = nil }

do
	local n2 = 10
	local v26 = color(255, 80, 80)
	local transparency = 0.6
	local n3 = 20
	local n4 = -1.5

	tbl.bombRange.getBarrelZombies = function()
		local tbl7 = {}
		local zombies = workspace:FindFirstChild("Zombies")
		if not zombies then
			return tbl7
		end

		for _, v27 in zombies:GetChildren() do
			if v27:IsA("Model") and v27:GetAttribute("Type") == "Barrel" then
				table.insert(tbl7, v27)
			end
		end

		return tbl7
	end

	tbl.bombRange.getSphereCenter = function(arg)
		local humanoidRootPart = arg:FindFirstChild("HumanoidRootPart") or arg:FindFirstChild("Torso") or arg:FindFirstChild("Head")
		if humanoidRootPart then
			return humanoidRootPart.Position + vector(0, n4, 0)
		end
		return nil
	end

	tbl.bombRange.createSphere = function(arg)
		local v27 = tbl.bombRange.getSphereCenter(arg)
		if not v27 then
			return nil
		end
		local part = Instance.new("Part")
		part.Name = "BombRangeSphere"
		part.Shape = Enum.PartType.Ball
		part.Size = vector(n2 * 2, n2 * 2, n2 * 2)
		part.Color = v26
		part.Material = Enum.Material.Neon
		part.Transparency = transparency
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Position = v27
		part.Parent = workspace
		return part
	end

	tbl.bombRange.updateSphere = function(arg, arg2)
		if not arg or not arg2 then
			return
		end
		local v27 = tbl.bombRange.getSphereCenter(arg2)

		if v27 then
			arg.Position = v27

			if arg.Size.X ~= n2 * 2 then
				arg.Size = vector(n2 * 2, n2 * 2, n2 * 2)
			end

			local character = localPlayer.Character

			if character then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then
					if (humanoidRootPart.Position - v27).Magnitude <= n2 then
						arg.Color = color(255, 0, 0)
					else
						arg.Color = color(120, 200, 120)
					end
				end
			end
		end
	end

	tbl.bombRange.updateAllSpheres = function()
		if not tbl.bombRange.enabled then
			return
		end
		local v27 = tbl.bombRange.getBarrelZombies()
		local tbl7 = {}

		for _, v28 in v27, nil, nil do
			tbl7[v28] = true
		end

		for k, v28 in tbl.bombRange.spheres, nil, nil do
			if not k.Parent or not tbl7[k] then
				if v28 then
					v28:Destroy()
				end

				tbl.bombRange.spheres[k] = nil
			end
		end

		for _, v28 in v27, nil, nil do
			if not tbl.bombRange.spheres[v28] then
				local v29 = tbl.bombRange.createSphere(v28)

				if v29 then
					tbl.bombRange.spheres[v28] = v29
				end
			else
				tbl.bombRange.updateSphere(tbl.bombRange.spheres[v28], v28)
			end
		end
	end

	tbl.bombRange.getMinDistanceToBarrelCenter = function()
		local character = localPlayer.Character
		if not character then
			return math.huge
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return math.huge
		end
		local huge = math.huge

		for _, v27 in tbl.bombRange.getBarrelZombies(), nil, nil do
			local v28 = tbl.bombRange.getSphereCenter(v27)

			if v28 then
				local magnitude = (v28 - humanoidRootPart.Position).Magnitude

				if magnitude < huge then
					huge = magnitude
				end
			end
		end

		return huge
	end

	tbl.bombRange.calculateDamage = function(arg)
		if arg >= n2 then
			return 0
		end
		return floor(10 + 90 * (1 - arg / n2))
	end

	tbl.bombRange.updateDamageDisplay = function()
		if not tbl.bombRange.enabled then
			if tbl.bombRange.damageDisplay then
				tbl.bombRange.damageDisplay:Destroy()
				tbl.bombRange.damageDisplay = nil
			end

			return
		end

		local character = localPlayer.Character

		if not character then
			if tbl.bombRange.damageDisplay then
				tbl.bombRange.damageDisplay:Destroy()
				tbl.bombRange.damageDisplay = nil
			end

			return
		end

		local v27 = tbl.bombRange.getMinDistanceToBarrelCenter()
		local n5 = 0

		if v27 <= n2 then
			n5 = tbl.bombRange.calculateDamage(v27)
		end

		if n5 > 0 then
			if tbl.bombRange.damageDisplay and not tbl.bombRange.damageDisplay.Parent then
				tbl.bombRange.damageDisplay = nil
			end

			if not tbl.bombRange.damageDisplay then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
				if not humanoidRootPart then
					return
				end
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Name = "DamageDisplay"
				billboardGui.Size = UDim2.new(0, 100, 0, 40)
				billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
				billboardGui.AlwaysOnTop = true
				billboardGui.Adornee = humanoidRootPart
				billboardGui.Parent = character
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.TextSize = 24
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextStrokeTransparency = 0.2
				textLabel.TextStrokeColor3 = color(0, 0, 0)
				textLabel.Parent = billboardGui
				tbl.bombRange.damageDisplay = billboardGui
			end

			local textLabel = tbl.bombRange.damageDisplay:FindFirstChildOfClass("TextLabel")

			if textLabel then
				textLabel.Text = tostring(n5)

				if n5 <= n3 then
					textLabel.TextColor3 = color(255, 255, 0)
				else
					textLabel.TextColor3 = color(255, 0, 0)
				end
			end
		elseif tbl.bombRange.damageDisplay then
			tbl.bombRange.damageDisplay:Destroy()
			tbl.bombRange.damageDisplay = nil
		end
	end

	tbl.bombRange.onHeartbeat = function()
		if not tbl.bombRange.enabled then
			return
		end
		tbl.bombRange.updateAllSpheres()
		tbl.bombRange.updateDamageDisplay()
		local character = localPlayer.Character
		character = character and character:FindFirstChild("HumanoidRootPart")

		if character then
			local flag = false

			for _, v27 in tbl.bombRange.spheres, nil, nil do
				if v27 and v27.Parent then
					if (character.Position - v27.Position).Magnitude <= n2 then
						flag = true
						break
					end
				end
			end

			if flag and not tbl.bombRange.warned then
				tbl.bombRange.warned = true
				tbl.notify(fn3("爆炸范围: 已进入爆炸范围内"), 3)
			elseif not flag then
				tbl.bombRange.warned = false
			end
		end
	end
end

tbl.bombRange.start = function()
	if tbl.bombRange.conn then
		return
	end
	tbl.bombRange.enabled = true
	tbl.bombRange.warned = false
	tbl.bombRange.conn = v5.Heartbeat:Connect(tbl.bombRange.onHeartbeat)
end

tbl.bombRange.stop = function()
	tbl.bombRange.enabled = false

	if tbl.bombRange.conn then
		tbl.bombRange.conn:Disconnect()
		tbl.bombRange.conn = nil
	end

	for _, v26 in tbl.bombRange.spheres, nil, nil do
		pcall(v26.Destroy, v26)
	end

	tbl.bombRange.spheres = {}

	if tbl.bombRange.damageDisplay then
		tbl.bombRange.damageDisplay:Destroy()
		tbl.bombRange.damageDisplay = nil
	end

	tbl.bombRange.warned = false
end

tbl.handMortar = {
	enabled = false,
	animIds = { ["rbxassetid://117522716162453"] = true, ["rbxassetid://83761082384320"] = true },
	gui = nil,
	conn = nil,
	cameraConn = nil,
	animConn = nil,
	endtick_ = nil,
	running = false,
}

tbl.handMortar.isFirstPerson = function()
	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		return false
	end
	local character = localPlayer.Character
	if not character then
		return false
	end
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return false
	end
	return (currentCamera.CFrame.Position - head.Position).Magnitude < 0.7
end

tbl.handMortar.createUI = function()
	if tbl.handMortar.gui then
		return
	end
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "HandMortarTimer_Billboard"
	billboardGui.Size = UDim2.new(0, 80, 0, 40)
	billboardGui.StudsOffset = Vector3.new(2.2, 0, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 200
	billboardGui.Parent = playerGui
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.2
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextSize = 20
	textLabel.Text = ""
	textLabel.Parent = billboardGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HandMortarTimer_Screen"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Size = UDim2.new(0, 120, 0, 50)
	textLabel2.Position = UDim2.new(0.55, 0, 0.45, 0)
	textLabel2.AnchorPoint = Vector2.new(0, 0)
	textLabel2.BackgroundTransparency = 1
	textLabel2.TextColor3 = Color3.new(1, 1, 1)
	textLabel2.TextStrokeTransparency = 0.2
	textLabel2.Font = Enum.Font.SourceSansBold
	textLabel2.TextSize = 28
	textLabel2.Text = ""
	textLabel2.Parent = screenGui
	tbl.handMortar.gui = { billboard = billboardGui, screen = screenGui, billLabel = textLabel, screenLabel = textLabel2 }
	billboardGui.Enabled = false
	screenGui.Enabled = false
end

tbl.handMortar.destroyUI = function()
	if tbl.handMortar.gui then
		if tbl.handMortar.gui.billboard then
			tbl.handMortar.gui.billboard:Destroy()
		end

		if tbl.handMortar.gui.screen then
			tbl.handMortar.gui.screen:Destroy()
		end

		tbl.handMortar.gui = nil
	end
end

tbl.handMortar.startTimer = function()
	if not tbl.handMortar.enabled then
		return
	end

	if tbl.handMortar.conn then
		tbl.handMortar.conn:Disconnect()
	end

	if tbl.handMortar.cameraConn then
		tbl.handMortar.cameraConn:Disconnect()
	end

	tbl.handMortar.destroyUI()
	tbl.handMortar.createUI()
	local character = localPlayer.Character

	if character and tbl.handMortar.gui and tbl.handMortar.gui.billboard then
		local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")

		if head then
			tbl.handMortar.gui.billboard.Adornee = head
		end
	end

	tbl.handMortar.endtick_ = clock() + 5
	tbl.handMortar.running = true

	local function fn10()
		if not tbl.handMortar.gui then
			return
		end
		local v26 = tbl.handMortar.isFirstPerson()
		tbl.handMortar.gui.billboard.Enabled = not v26
		tbl.handMortar.gui.screen.Enabled = v26
	end

	fn10()

	tbl.handMortar.cameraConn = v5.RenderStepped:Connect(function()
		if not tbl.handMortar.running then
			return
		end

		if tbl.handMortar.gui then
			local v26 = tbl.handMortar.isFirstPerson()
			tbl.handMortar.gui.billboard.Enabled = not v26
			tbl.handMortar.gui.screen.Enabled = v26
		end
	end)

	tbl.handMortar.conn = v5.RenderStepped:Connect(function()
		if not tbl.handMortar.running or not tbl.handMortar.gui then
			if tbl.handMortar.conn then
				tbl.handMortar.conn:Disconnect()
			end

			if tbl.handMortar.cameraConn then
				tbl.handMortar.cameraConn:Disconnect()
			end

			tbl.handMortar.destroyUI()
			tbl.handMortar.running = false
			return
		end

		local v26 = max(0, tbl.handMortar.endtick_ - clock())
		local v27 = floor(v26 * 1000 + 0.5)
		local v28 = floor(v27 / 1000)
		local v29 = format("%d.%03ds", v28, v27 - v28 * 1000)

		if tbl.handMortar.gui.billLabel then
			tbl.handMortar.gui.billLabel.Text = v29
		end

		if tbl.handMortar.gui.screenLabel then
			tbl.handMortar.gui.screenLabel.Text = v29
		end

		if v26 <= 0 then
			if tbl.handMortar.conn then
				tbl.handMortar.conn:Disconnect()
			end

			if tbl.handMortar.cameraConn then
				tbl.handMortar.cameraConn:Disconnect()
			end

			tbl.handMortar.destroyUI()
			tbl.handMortar.running = false
		end
	end)
end

tbl.handMortar.onAnimationPlayed = function(arg)
	if not tbl.handMortar.enabled then
		return
	end
	arg = arg and arg.Animation
	if not arg then
		return
	end

	if tbl.handMortar.animIds[arg.AnimationId] then
		task.delay(1, function()
			if tbl.handMortar.enabled then
				tbl.handMortar.startTimer()
			end
		end)
	end
end

tbl.handMortar.attachAnimWatcher = function()
	if tbl.handMortar.animConn then
		tbl.handMortar.animConn:Disconnect()
	end

	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		tbl.handMortar.animConn = humanoid.AnimationPlayed:Connect(tbl.handMortar.onAnimationPlayed)
	end
end

tbl.handMortar.setEnabled = function(enabled)
	tbl.handMortar.enabled = enabled

	if enabled then
		tbl.handMortar.attachAnimWatcher()
	else
		if tbl.handMortar.animConn then
			tbl.handMortar.animConn:Disconnect()
			tbl.handMortar.animConn = nil
		end

		if tbl.handMortar.conn then
			tbl.handMortar.conn:Disconnect()
			tbl.handMortar.conn = nil
		end

		if tbl.handMortar.cameraConn then
			tbl.handMortar.cameraConn:Disconnect()
			tbl.handMortar.cameraConn = nil
		end

		tbl.handMortar.destroyUI()
		tbl.handMortar.running = false
	end
end

tbl.noBarrelHit = { enabled = false, conn = nil }

tbl.noBarrelHit.toggle = function(enabled)
	tbl.noBarrelHit.enabled = enabled

	if enabled then
		local function fn10(arg)
			if not arg or not arg.Parent then
				return
			end

			for _, v26 in arg:GetDescendants() do
				if v26:IsA("BasePart") then
					v26.CanCollide = false
					v26.CanTouch = false
					v26.CanQuery = false
				end
			end
		end

		local zombies = workspace:FindFirstChild("Zombies")

		if zombies then
			for _, v26 in zombies:GetChildren() do
				if v26:IsA("Model") and (v26:GetAttribute("Type") == "Barrel" or v26:FindFirstChild("Barrel")) then
					fn10(v26)
				end
			end
		end

		task.spawn(function()
			while tbl.noBarrelHit.enabled do
				local zombies2 = workspace:FindFirstChild("Zombies")

				if zombies2 then
					for _, v26 in zombies2:GetChildren() do
						if v26:IsA("Model") and (v26:GetAttribute("Type") == "Barrel" or v26:FindFirstChild("Barrel")) then
							fn10(v26)
						end
					end
				end

				task.wait()
			end
		end)

		if tbl.noBarrelHit.conn then
			tbl.noBarrelHit.conn:Disconnect()
		end

		tbl.noBarrelHit.conn = workspace.DescendantAdded:Connect(function(descendant)
			if tbl.noBarrelHit.enabled and descendant:IsA("Model") and (descendant:GetAttribute("Type") == "Barrel" or descendant:FindFirstChild("Barrel")) then
				fn10(descendant)
			end
		end)
	elseif tbl.noBarrelHit.conn then
		tbl.noBarrelHit.conn:Disconnect()
		tbl.noBarrelHit.conn = nil
	end
end

tbl.jumpLock = { active = false, conn = nil }

tbl.jumpLock.toggle = function(active)
	tbl.jumpLock.active = active

	if active then
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.JumpPower = 30

			if tbl.jumpLock.conn then
				tbl.jumpLock.conn:Disconnect()
			end

			tbl.jumpLock.conn = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if humanoid.JumpPower ~= 30 then
					humanoid.JumpPower = 30
				end
			end)
		end
	else
		if tbl.jumpLock.conn then
			tbl.jumpLock.conn:Disconnect()
			tbl.jumpLock.conn = nil
		end

		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.JumpPower = 16
		end
	end
end

tbl.onCharacterAdded(function()
	if tbl.jumpLock and tbl.jumpLock.active then
		task.wait(0.2)
		local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.JumpPower = 30

			if tbl.jumpLock.conn then
				tbl.jumpLock.conn:Disconnect()
			end

			tbl.jumpLock.conn = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if humanoid.JumpPower ~= 30 then
					humanoid.JumpPower = 30
				end
			end)
		end
	end
end)

tbl.hitboxHighlight = {
	enabled = false,
	box = nil,
	containerPart = nil,
	charConn = nil,
	diedConn = nil,
	loopThread = nil,
	history = {},
	maxHistory = 60,
}

do
	local n2 = 0
	local n3 = 0

	local function fn10()
		local v26 = clock2()

		if v26 - n3 >= 1 then
			n3 = v26

			local ok, result = pcall(function()
				return v10.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)

			if ok and result then
				n2 = result
			end
		end

		return n2
	end

	local function fn11()
		if tbl.hitboxHighlight.box then
			pcall(function()
				tbl.hitboxHighlight.box:Destroy()
			end)

			tbl.hitboxHighlight.box = nil
		end

		if tbl.hitboxHighlight.containerPart then
			pcall(function()
				tbl.hitboxHighlight.containerPart:Destroy()
			end)

			tbl.hitboxHighlight.containerPart = nil
		end

		if tbl.hitboxHighlight.loopThread then
			task.cancel(tbl.hitboxHighlight.loopThread)
			tbl.hitboxHighlight.loopThread = nil
		end

		table.clear(tbl.hitboxHighlight.history)
	end

	tbl.hitboxHighlight.enable = function()
		if tbl.hitboxHighlight.enabled then
			return
		end
		tbl.hitboxHighlight.enabled = true
		fn11()
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end
		local part = Instance.new("Part")
		part.Name = "HitboxContainer"
		part.Size = humanoidRootPart.Size
		part.CFrame = humanoidRootPart.CFrame
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Parent = workspace
		tbl.hitboxHighlight.containerPart = part
		tbl.hitboxHighlight.box = Instance.new("SelectionBox")
		tbl.hitboxHighlight.box.Adornee = part
		tbl.hitboxHighlight.box.Color3 = color(255, 0, 0)
		tbl.hitboxHighlight.box.LineThickness = 0.15
		tbl.hitboxHighlight.box.Transparency = 0.3
		tbl.hitboxHighlight.box.Parent = part
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			if tbl.hitboxHighlight.diedConn then
				tbl.hitboxHighlight.diedConn:Disconnect()
			end

			tbl.hitboxHighlight.diedConn = humanoid.Died:Connect(function()
				fn11()
			end)
		end

		local n4 = 10
		local v26 = v5

		tbl.hitboxHighlight.loopThread = task.spawn(function()
			local v27 = clock2()

			while tbl.hitboxHighlight.enabled do
				local v28 = clock2()
				local v29 = min(v28 - v27, 0.1)
				local character2 = localPlayer.Character

				if character2 then
					local humanoidRootPart2 = character2:FindFirstChild("HumanoidRootPart")

					if humanoidRootPart2 and tbl.hitboxHighlight.containerPart then
						local history = tbl.hitboxHighlight.history
						table.insert(history, { time = v28, cframe = humanoidRootPart2.CFrame, size = humanoidRootPart2.Size })

						while #history > tbl.hitboxHighlight.maxHistory do
							table.remove(history, 1)
						end

						local n5 = v28 - fn10() / 1000
						local cframe2 = history[1].cframe
						local size = history[1].size

						for i = 1, #history do
							if n5 <= history[i].time then
								cframe2 = history[i].cframe
								size = history[i].size
								break
							end
						end

						local cFrame = tbl.hitboxHighlight.containerPart.CFrame
						local v30 = min(n4 * v29, 1)
						tbl.hitboxHighlight.containerPart.CFrame = cFrame:Lerp(cframe2, v30)
						tbl.hitboxHighlight.containerPart.Size = tbl.hitboxHighlight.containerPart.Size:Lerp(size, v30)
					end
				end

				v26.Heartbeat:Wait()
				v27 = v28
			end
		end)
	end

	tbl.hitboxHighlight.disable = function()
		if not tbl.hitboxHighlight.enabled then
			return
		end
		tbl.hitboxHighlight.enabled = false

		if tbl.hitboxHighlight.diedConn then
			tbl.hitboxHighlight.diedConn:Disconnect()
			tbl.hitboxHighlight.diedConn = nil
		end

		fn11()
	end

	tbl.hitboxHighlight.toggle = function()
		if tbl.hitboxHighlight.enabled then
			tbl.hitboxHighlight.disable()
		else
			tbl.hitboxHighlight.enable()
		end
	end

	if tbl.hitboxHighlight.charConn then
		tbl.hitboxHighlight.charConn()
	end

	tbl.hitboxHighlight.charConn = tbl.onCharacterAdded(function()
		task.wait(0.3)

		if tbl.hitboxHighlight.enabled then
			fn11()
			task.wait(0.1)
			tbl.hitboxHighlight.enabled = false
			tbl.hitboxHighlight.enable()
		end
	end)
end

v23:AddToggle("HitboxHighlightToggle", {
	Text = "玩家碰撞箱显示",
	Default = false,
	Tooltip = fn4("显示玩家碰撞箱"),
	Callback = function(arg)
		if arg then
			tbl.hitboxHighlight.enable()
		else
			tbl.hitboxHighlight.disable()
		end
	end,
})

tbl.legionPack = {
	selectedLegion = "法兰西第一掷弹兵",
	selectedClass = "线列步兵",
	legionMap = {
		["法兰西第一掷弹兵"] = { nation = "French", regimentId = 2, branch = "Infantry" },
		["英国冷溪近卫军"] = { nation = "British", regimentId = 4, branch = "Infantry" },
		["老敬卫"] = { nation = "French", regimentId = 5, branch = "Infantry" },
	},
	classMap = {
		["线列步兵"] = "LineInfantry",
		["军官"] = "Officer",
		["工兵"] = "Sapper",
		["乐手"] = "Musician",
		["水手"] = "Seaman",
	},
}

tbl.legionPack.getRemote = function()
	local events = v7 and v7:FindFirstChild("Events")
	if not events then
		return nil
	end
	local regiment = events:FindFirstChild("Regiment")
	if not regiment then
		return nil
	end
	return regiment:FindFirstChild("ChangeClass")
end

tbl.legionPack.unlock = function()
	local v26 = tbl.legionPack.getRemote()
	if not v26 then
		tbl.notify(fn3("解锁失败: 找不到ChangeClass"), 3)
		return false
	end
	local v27 = tbl.legionPack.legionMap[tbl.legionPack.selectedLegion]
	local v28 = tbl.legionPack.classMap[tbl.legionPack.selectedClass]
	if not v27 or not v28 then
		tbl.notify(fn3("解锁失败: 配置错误"), 3)
		return false
	end

	pcall(function()
		v26:FireServer(v28, v27.regimentId, v27.nation, v27.branch)
	end)

	local str2 = ": " .. tbl.legionPack.selectedLegion .. " - " .. tbl.legionPack.selectedClass
	tbl.notify(fn3("已解锁替换") .. str2, 3)
	return true
end

tbl.ZOMBIE_ESP_RANGE = 200

tbl.lightenColor = function(arg, arg2)
	local n2 = arg2 or 0.5
	return Color3.new(arg.R + (1 - arg.R) * n2, arg.G + (1 - arg.G) * n2, arg.B + (1 - arg.B) * n2)
end

tbl.ZOMBIE_TYPES = {
	Axe = {
		name = "斧头僵尸",
		color = color(180, 0, 250),
		highlightColor = tbl.lightenColor(color(180, 0, 250)),
		part = "Axe",
	},
	Eye = {
		name = "红眼",
		color = color(255, 50, 50),
		highlightColor = tbl.lightenColor(color(255, 50, 50)),
		part = "Eye",
	},
	Sword = {
		name = "胸甲骑兵",
		color = color(255, 0, 255),
		highlightColor = tbl.lightenColor(color(255, 0, 255)),
		part = "Sword",
	},
	Barrel = {
		name = "自爆",
		color = color(250, 250, 0),
		highlightColor = tbl.lightenColor(color(250, 250, 0)),
		part = "Barrel",
	},
	FTorso = {
		name = "提灯人",
		color = color(255, 120, 0),
		highlightColor = tbl.lightenColor(color(255, 120, 0)),
		part = "FTorso",
	},
	Normal = { name = "山伯乐", color = color(144, 238, 144), highlightColor = color(144, 238, 144), part = nil },
	Headless = {
		name = "无头士兵",
		color = color(255, 215, 0),
		highlightColor = color(255, 215, 0),
		matchName = "HeadlessHorseman",
	},
}

tbl.headlessHighlightEnabled = false
tbl.draculaHighlightEnabled = false
tbl.headlessHighlights = {}
tbl.headlessDescendantConn = nil

tbl.clearHeadlessHighlights = function()
	for _, v26 in tbl.headlessHighlights, nil, nil do
		tbl.destroyESP(v26)
	end

	tbl.headlessHighlights = {}
end

tbl.isHeadlessModel = function(arg)
	if not arg or not arg:IsA("Model") then
		return false
	end
	local name = arg.Name
	if name == "HeadlessHorseman" then
		return true
	end

	if name:find("Horse") or name:find("Steed") or name:find("Mount") then
		local parent = arg.Parent
		if parent and parent:IsA("Model") and parent.Name == "HeadlessHorseman" then
			return true
		end

		if name:find("Headless") then
			return true
		end
	end

	return false
end

tbl.getAttachPart = function(arg)
	return arg.PrimaryPart or arg:FindFirstChild("HumanoidRootPart") or arg:FindFirstChild("Head") or arg:FindFirstChild("Torso")
end

tbl.createHeadlessHighlight = function(arg)
	if not arg or not arg:IsA("Model") then
		return
	end

	if not tbl.isHeadlessModel(arg) then
		return
	end

	if tbl.headlessHighlights[arg] then
		return
	end

	local v26 = tbl.addESP({
		Name = fn3("无头骑士"),
		Model = arg,
		Color = color(255, 50, 50),
		MaxDistance = 1000,
		TextSize = 14,
		ESPType = "Highlight",
		FillColor = color(255, 50, 50),
		OutlineColor = color(255, 50, 50),
		FillTransparency = 0.5,
		OutlineTransparency = 0,
	})

	if v26 == nil then
		return
	end
	tbl.headlessHighlights[arg] = v26
end

tbl.updateHeadlessHighlights = function()
	if not tbl.headlessHighlightEnabled then
		tbl.clearHeadlessHighlights()
		return
	end

	for k, v26 in tbl.headlessHighlights, nil, nil do
		if not k.Parent or v26.Deleted then
			tbl.destroyESP(v26)
			tbl.headlessHighlights[k] = nil
		else
			v26.CurrentSettings.Name = fn3("无头骑士")
		end
	end

	for _, v26 in workspace:GetDescendants() do
		if v26:IsA("Model") and tbl.isHeadlessModel(v26) then
			tbl.createHeadlessHighlight(v26)
		end
	end
end

tbl.startHeadlessListener = function()
	if tbl.headlessDescendantConn then
		return
	end

	tbl.headlessDescendantConn = workspace.DescendantAdded:Connect(function(descendant)
		if tbl.headlessHighlightEnabled and descendant:IsA("Model") and tbl.isHeadlessModel(descendant) then
			task.spawn(function()
				task.wait()
				tbl.createHeadlessHighlight(descendant)
			end)
		end
	end)
end

tbl.stopHeadlessListener = function()
	if tbl.headlessDescendantConn then
		tbl.headlessDescendantConn:Disconnect()
		tbl.headlessDescendantConn = nil
	end
end

tbl.toggleHeadlessHighlight = function(headlessHighlightEnabled)
	tbl.headlessHighlightEnabled = headlessHighlightEnabled

	if headlessHighlightEnabled then
		tbl.updateHeadlessHighlights()
		tbl.startHeadlessListener()
	else
		tbl.clearHeadlessHighlights()
		tbl.stopHeadlessListener()
	end
end

tbl.draculaHighlights = {}
tbl.draculaDescendantConn = nil

tbl.clearDraculaHighlights = function()
	for _, v26 in tbl.draculaHighlights, nil, nil do
		tbl.destroyESP(v26)
	end

	tbl.draculaHighlights = {}
end

tbl.getDraculaModel = function()
	local transylvania = workspace:FindFirstChild("Transylvania")
	return transylvania and transylvania:FindFirstChild("Modes") and transylvania.Modes:FindFirstChild("Boss") and transylvania.Modes.Boss:FindFirstChild("Dracula")
end

tbl.createDraculaHighlight = function(arg)
	if not arg or not arg:IsA("Model") then
		return
	end

	if tbl.draculaHighlights[arg] then
		return
	end

	local v26 = tbl.addESP({
		Name = fn3("德古拉"),
		Model = arg,
		Color = color(255, 50, 50),
		MaxDistance = 1000,
		TextSize = 14,
		ESPType = "Highlight",
		FillColor = color(255, 50, 50),
		OutlineColor = color(255, 50, 50),
		FillTransparency = 0.5,
		OutlineTransparency = 0,
	})

	if v26 == nil then
		return
	end
	tbl.draculaHighlights[arg] = v26
end

tbl.updateDraculaHighlight = function()
	if not tbl.draculaHighlightEnabled then
		tbl.clearDraculaHighlights()
		return
	end

	for k, v26 in tbl.draculaHighlights, nil, nil do
		if not k.Parent or v26.Deleted then
			tbl.destroyESP(v26)
			tbl.draculaHighlights[k] = nil
		else
			v26.CurrentSettings.Name = fn3("德古拉")
		end
	end

	local v26 = tbl.getDraculaModel()

	if v26 then
		tbl.createDraculaHighlight(v26)
	end
end

tbl.startDraculaListener = function()
	if tbl.draculaDescendantConn then
		return
	end

	tbl.draculaDescendantConn = workspace.DescendantAdded:Connect(function(descendant)
		if tbl.draculaHighlightEnabled and descendant:IsA("Model") and descendant.Name == "Dracula" then
			task.spawn(function()
				task.wait()
				tbl.createDraculaHighlight(descendant)
			end)
		end
	end)
end

tbl.stopDraculaListener = function()
	if tbl.draculaDescendantConn then
		tbl.draculaDescendantConn:Disconnect()
		tbl.draculaDescendantConn = nil
	end
end

tbl.toggleDraculaHighlight = function(draculaHighlightEnabled)
	tbl.draculaHighlightEnabled = draculaHighlightEnabled

	if draculaHighlightEnabled then
		tbl.updateDraculaHighlight()
		tbl.startDraculaListener()
	else
		tbl.clearDraculaHighlights()
		tbl.stopDraculaListener()
	end
end

tbl.zombieEspEnabled = {
	Axe = false,
	Eye = false,
	Sword = false,
	Barrel = false,
	FTorso = false,
	Normal = false,
	Headless = false,
}

tbl.zombieEffects = {}

tbl.getZombieTypeKey = function(arg)
	for k, v26 in tbl.ZOMBIE_TYPES, nil, nil do
		if v26.part and arg:FindFirstChild(v26.part) then
			return k
		end
	end

	for k, v26 in tbl.ZOMBIE_TYPES, nil, nil do
		if v26.matchName and arg.Name == v26.matchName then
			return k
		end
	end

	if not arg:FindFirstChild("Head") then
		return "Headless"
	end
	return "Normal"
end

tbl.createZombieESP = function(arg, arg2)
	local v26 = tbl.ZOMBIE_TYPES[arg2]
	if not v26 then
		return nil
	end

	return tbl.addESP({
		Name = fn3(v26.name),
		Model = arg,
		Color = v26.highlightColor,
		MaxDistance = tbl.ZOMBIE_ESP_RANGE,
		TextSize = 14,
		ESPType = "Highlight",
		FillColor = v26.highlightColor,
		OutlineColor = v26.highlightColor,
		FillTransparency = 0.5,
		OutlineTransparency = 0,
	})
end

tbl.removeZombieEffects = function(arg)
	local v26 = tbl.zombieEffects[arg]

	if v26 then
		tbl.destroyESP(v26.esp)
		tbl.zombieEffects[arg] = nil
	end
end

tbl.clearAllZombieEffects = function()
	for k in tbl.zombieEffects, nil, nil do
		tbl.removeZombieEffects(k)
	end
end

tbl.updateZombieESP = function()
	local flag = false

	for _, v26 in tbl.zombieEspEnabled, nil, nil do
		if v26 then
			flag = true
			break
		end
	end

	if not flag then
		tbl.clearAllZombieEffects()
		return
	end
	local character = localPlayer.Character
	character = character and character:FindFirstChild("HumanoidRootPart")
	character = character and character.Position
	if not character then
		tbl.clearAllZombieEffects()
		return
	end

	for k, v26 in tbl.zombieEffects, nil, nil do
		if not k.Parent or v26.esp == nil or v26.esp.Deleted then
			tbl.removeZombieEffects(k)
		end
	end

	local tbl7 = {}
	local camera = workspace:FindFirstChild("Camera")

	if camera then
		for _, v26 in camera:GetDescendants() do
			if v26:IsA("Model") and v26.Name:find("Zombie") then
				table.insert(tbl7, v26)
			end
		end
	end

	local zombies = workspace:FindFirstChild("Zombies")

	if zombies then
		for _, v26 in zombies:GetChildren() do
			if v26:IsA("Model") and v26.Name:find("Zombie") then
				table.insert(tbl7, v26)
			end
		end
	end

	for _, v26 in tbl7, nil, nil do
		local humanoidRootPart = v26:FindFirstChild("HumanoidRootPart") or v26:FindFirstChild("Head") or v26:FindFirstChild("Torso")

		if humanoidRootPart then
			local magnitude = (humanoidRootPart.Position - character).Magnitude
			local v27 = tbl.getZombieTypeKey(v26)
			local v28 = tbl.zombieEspEnabled[v27]
			local v29 = tbl.zombieEffects[v26]

			if v28 and magnitude <= tbl.ZOMBIE_ESP_RANGE then
				local flag2 = v29 ~= nil
				local deleted

				if flag2 then
					deleted = v29.esp == nil or v29.esp.Deleted or v29.typeKey ~= v27
				else
					deleted = flag2
				end

				if deleted then
					tbl.removeZombieEffects(v26)
					v29 = nil
				end

				local v30

				if v29 == nil then
					local v31 = tbl.createZombieESP(v26, v27)

					if v31 == nil then
						v30 = v29
					else
						tbl.zombieEffects[v26] = { esp = v31, typeKey = v27 }
						v30 = tbl.zombieEffects[v26]
					end
				else
					v30 = v29
				end

				if v30 ~= nil then
					v30.esp.CurrentSettings.Name = fn3(tbl.ZOMBIE_TYPES[v27].name)
				end
			elseif v29 ~= nil then
				tbl.removeZombieEffects(v26)
			end
		end
	end
end

tbl.lastZombieESPUpdate = 0
tbl.zombieESPHeartbeatConn = nil

tbl.startZombieESPHeartbeat = function()
	if tbl.zombieESPHeartbeatConn then
		return
	end

	tbl.zombieESPHeartbeatConn = v5.Heartbeat:Connect(function()
		local v26 = clock()

		if v26 - tbl.lastZombieESPUpdate >= 0.2 then
			tbl.lastZombieESPUpdate = v26
			tbl.updateZombieESP()
		end
	end)
end

tbl.stopZombieESPHeartbeat = function()
	if tbl.zombieESPHeartbeatConn then
		tbl.zombieESPHeartbeatConn:Disconnect()
		tbl.zombieESPHeartbeatConn = nil
	end

	tbl.clearAllZombieEffects()
end

tbl.onCharacterAdded(function()
	task.wait(0.5)
	tbl.updateZombieESP()
end)

tbl.CoordSpeed = { Enabled = false, Speed = 16, Connection = nil }

do
	local function fn10()
		if tbl.CoordSpeed.Connection then
			return
		end

		tbl.CoordSpeed.Connection = v5.Heartbeat:Connect(function(deltaTime)
			if not tbl.CoordSpeed.Enabled then
				return
			end
			local character = localPlayer.Character
			if not character then
				return
			end
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoidRootPart or not humanoid then
				return
			end
			local moveDirection = humanoid.MoveDirection

			if moveDirection.Magnitude > 0 then
				humanoidRootPart.CFrame = humanoidRootPart.CFrame + moveDirection.Unit * tbl.CoordSpeed.Speed * deltaTime
			end
		end)
	end

	local function fn11()
		if tbl.CoordSpeed.Connection then
			tbl.CoordSpeed.Connection:Disconnect()
			tbl.CoordSpeed.Connection = nil
		end
	end

	v21:AddToggle("CoordSpeedToggle", {
		Text = "启用坐标加速",
		Default = false,
		Tooltip = fn4("通过CFrame实现位移"),
		Callback = function(enabled)
			tbl.CoordSpeed.Enabled = enabled

			if enabled then
				fn10()
			else
				fn11()
			end
		end,
	})
end

v21:AddSlider("CoordSpeedSlider", {
	Text = "坐标加速速度",
	Default = 16,
	Min = 1,
	Max = 150,
	Rounding = 0,
	Suffix = " 速度",
	Callback = function(speed)
		tbl.CoordSpeed.Speed = speed
	end,
})

local connection

do
	local flag = false
	local n2 = 25
	connection = nil
	local tbl7 = {}

	local function fn10(arg, walkSpeed)
		if arg and arg.Parent then
			pcall(function()
				arg.WalkSpeed = walkSpeed
			end)
		end
	end

	local function fn11(arg)
		return arg:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if flag then
				fn10(arg, n2)
			end
		end)
	end

	local function fn12(arg)
		if not arg then
			return
		end
		local humanoid = arg:FindFirstChildOfClass("Humanoid")

		if humanoid then
			if tbl7[humanoid] then
				tbl7[humanoid]:Disconnect()
			end

			tbl7[humanoid] = fn11(humanoid)
			fn10(humanoid, n2)
		end
	end

	local function fn13()
		if connection then
			return
		end

		connection = v5.Heartbeat:Connect(function()
			if not flag then
				return
			end
			local character = localPlayer.Character

			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoid then
					fn10(humanoid, n2)

					if not tbl7[humanoid] then
						tbl7[humanoid] = fn11(humanoid)
					end
				end
			end
		end)
	end

	local function fn14()
		if connection then
			connection:Disconnect()
			connection = nil
		end

		for _, v26 in tbl7, nil, nil do
			pcall(function()
				v26:Disconnect()
			end)
		end

		tbl7 = {}
		local character = localPlayer.Character

		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if humanoid then
				fn10(humanoid, 16)
			end
		end
	end

	setWalkSpeedEnabled = function(arg)
		flag = arg

		if arg then
			fn13()

			if localPlayer.Character then
				fn12(localPlayer.Character)
			end
		else
			fn14()
		end
	end

	setWalkSpeedValue = function(arg)
		n2 = clamp(arg, 16, 45)

		if flag then
			local character = localPlayer.Character

			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoid then
					fn10(humanoid, n2)
				end
			end
		end
	end

	tbl.onCharacterAdded(function(arg)
		if flag then
			task.wait(0.1)
			fn12(arg)
		end
	end)
end

v21:AddToggle("SpeedToggle", {
	Text = "启用速度调整",
	Default = false,
	Callback = function(arg)
		setWalkSpeedEnabled(arg)
	end,
})

v21:AddSlider("SpeedSlider", {
	Text = "玩家速度",
	Default = 25,
	Min = 16,
	Max = 45,
	Rounding = 0,
	Suffix = " 速度",
	Callback = function(arg)
		setWalkSpeedValue(arg)
	end,
})

tbl.AutoFace = { Enabled = false, Range = 17, SkipBarrel = false, Connection = nil }

do
	local function fn10()
		local character = localPlayer.Character
		if not character then
			return nil
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return nil
		end
		local zombies = workspace:FindFirstChild("Zombies")
		if not zombies then
			return nil
		end
		local huge = math.huge
		local v26 = nil

		for _, v27 in zombies:GetChildren() do
			if v27:IsA("Model") and v27:FindFirstChild("HumanoidRootPart") then
				if not (tbl.AutoFace.SkipBarrel and (v27:GetAttribute("Type") == "Barrel" or v27:FindFirstChild("Barrel"))) then
					local state = v27:FindFirstChild("State")

					if not (state and state.Value == "Spawn") then
						local magnitude = (v27.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude

						if magnitude <= tbl.AutoFace.Range and magnitude < huge then
							huge = magnitude
							v26 = v27
						end
					end
				end
			end
		end

		return v26
	end

	local function fn11()
		while tbl.AutoFace.Enabled do
			local v26 = fn10()

			if v26 then
				local character = localPlayer.Character

				if character then
					local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
					local humanoid = character:FindFirstChildOfClass("Humanoid")

					if humanoidRootPart and humanoid then
						local autoRotate = humanoid.AutoRotate
						humanoid.AutoRotate = false
						local position = v26.HumanoidRootPart.Position
						humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, vector(position.X, humanoidRootPart.Position.Y, position.Z))
						humanoid.AutoRotate = autoRotate
					end
				end
			end

			task.wait(0.1)
		end
	end

	v21:AddSlider("AutoFaceRange", {
		Text = "自动转向范围",
		Default = 17,
		Min = 5,
		Max = 30,
		Rounding = 0,
		Suffix = " 格",
		Callback = function(range)
			tbl.AutoFace.Range = range
		end,
	})

	v21:AddToggle("AutoFaceToggle", {
		Text = "自动转向",
		Default = false,
		Callback = function(enabled)
			tbl.AutoFace.Enabled = enabled

			if enabled then
				if tbl.AutoFace.Connection then
					task.cancel(tbl.AutoFace.Connection)
				end

				tbl.AutoFace.Connection = task.spawn(fn11)
			elseif tbl.AutoFace.Connection then
				task.cancel(tbl.AutoFace.Connection)
				tbl.AutoFace.Connection = nil
			end
		end,
	})
end

v21:AddToggle("SkipBarrelToggle", {
	Text = "跳过自爆僵尸",
	Default = false,
	Tooltip = fn4("开启后不会转向自爆"),
	Callback = function(skipBarrel)
		tbl.AutoFace.SkipBarrel = skipBarrel
	end,
})

tbl.GroundJump = { Enabled = false, Power = 60, JumpReqConn = nil }

do
	local function fn10()
		if not tbl.GroundJump.Enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		if humanoid and humanoidRootPart and humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoidRootPart.AssemblyLinearVelocity = vector(humanoidRootPart.AssemblyLinearVelocity.X, tbl.GroundJump.Power, humanoidRootPart.Velocity.Z)
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end

	local function fn11()
		if tbl.GroundJump.Enabled then
			if not tbl.GroundJump.JumpReqConn then
				tbl.GroundJump.JumpReqConn = v6.JumpRequest:Connect(fn10)
			end
		elseif tbl.GroundJump.JumpReqConn then
			tbl.GroundJump.JumpReqConn:Disconnect()
			tbl.GroundJump.JumpReqConn = nil
		end
	end

	v21:AddToggle("GroundJumpToggle", {
		Text = "控制玩家跳跃高度",
		Default = false,
		Callback = function(enabled)
			tbl.GroundJump.Enabled = enabled
			fn11()
		end,
	})
end

v21:AddSlider("GroundJumpSlider", {
	Text = "跳跃高度",
	Default = 60,
	Min = 30,
	Max = 95,
	Rounding = 0,
	Suffix = " 高度",
	Callback = function(power)
		tbl.GroundJump.Power = power
	end,
})

tbl.AutoJump = { Enabled = false, Height = 60, Connection = nil }

local function fn10()
	if tbl.AutoJump.Connection then
		tbl.AutoJump.Connection:Disconnect()
	end

	tbl.AutoJump.Connection = v5.Heartbeat:Connect(function()
		if not tbl.AutoJump.Enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		if humanoid and humanoidRootPart and humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			humanoidRootPart.AssemblyLinearVelocity = vector(humanoidRootPart.AssemblyLinearVelocity.X, tbl.AutoJump.Height, humanoidRootPart.Velocity.Z)
		end
	end)
end

v21:AddToggle("AutoJumpToggle", {
	Text = "自动跳跃",
	Default = false,
	Callback = function(enabled)
		tbl.AutoJump.Enabled = enabled

		if enabled then
			fn10()
		elseif tbl.AutoJump.Connection then
			tbl.AutoJump.Connection:Disconnect()
			tbl.AutoJump.Connection = nil
		end
	end,
})

v21:AddSlider("AutoJumpHeight", {
	Text = "自动跳跃高度",
	Default = 60,
	Min = 30,
	Max = 60,
	Rounding = 0,
	Suffix = " 高度",
	Callback = function(height)
		tbl.AutoJump.Height = height
	end,
})

tbl.JumpMod = {
	Enabled = false,
	Height = 60,
	Cooldown = 0.6,
	LastJump = 0,
	AntiFallConn = nil,
	JumpReqConn = nil,
}

do
	local function fn11()
		if tbl.JumpMod.AntiFallConn then
			return
		end

		tbl.JumpMod.AntiFallConn = v5.Heartbeat:Connect(function()
			if not tbl.JumpMod.Enabled then
				return
			end
			local character = localPlayer.Character
			if not character then
				return
			end
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoidRootPart or not humanoid then
				return
			end

			if humanoidRootPart.AssemblyLinearVelocity.Y < -5 and not v6:IsKeyDown(Enum.KeyCode.Space) then
				humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
			end

			local userStates = localPlayer:FindFirstChild("UserStates")

			if userStates then
				local brokenLegs = userStates:FindFirstChild("BrokenLegs")

				if brokenLegs then
					brokenLegs.Value = false
				end
			end
		end)
	end

	local function fn12()
		if not tbl.JumpMod.Enabled then
			return
		end
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local flag = humanoid and humanoidRootPart

		if flag then
			local lastJump = tbl.JumpMod.LastJump
			flag = clock() - lastJump >= tbl.JumpMod.Cooldown
		end

		if flag then
			tbl.JumpMod.LastJump = clock()
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			humanoidRootPart.AssemblyLinearVelocity = vector(humanoidRootPart.AssemblyLinearVelocity.X, tbl.JumpMod.Height, humanoidRootPart.Velocity.Z)
		end
	end

	local function fn13()
		if tbl.JumpMod.Enabled then
			if not tbl.JumpMod.JumpReqConn then
				tbl.JumpMod.JumpReqConn = v6.JumpRequest:Connect(fn12)
			end

			fn11()
		else
			if tbl.JumpMod.JumpReqConn then
				tbl.JumpMod.JumpReqConn:Disconnect()
				tbl.JumpMod.JumpReqConn = nil
			end

			if tbl.JumpMod.AntiFallConn then
				tbl.JumpMod.AntiFallConn:Disconnect()
				tbl.JumpMod.AntiFallConn = nil
			end

			local character = localPlayer.Character

			if character then
				local animate = character:FindFirstChild("Animate")

				if animate then
					animate.Parent = character
				end
			end
		end
	end

	v21:AddToggle("JumpModToggle", {
		Text = "无限连跳（含防骨折）",
		Default = false,
		Callback = function(enabled)
			tbl.JumpMod.Enabled = enabled
			fn13()
		end,
	})
end

v21:AddSlider("JumpModHeight", {
	Text = "跳跃高度",
	Default = 60,
	Min = 30,
	Max = 90,
	Rounding = 0,
	Suffix = " 高度",
	Callback = function(height)
		tbl.JumpMod.Height = height
	end,
})

tbl.NoSlow = { Enabled = false, WalkSpeedConn = nil, CharAddedConn = nil }

do
	local function fn11()
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid and humanoid.WalkSpeed < 16 then
			humanoid.WalkSpeed = 16
		end
	end

	local fn12 = nil

	fn12 = function()
		if tbl.NoSlow.Enabled then
			local character = localPlayer.Character

			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoid then
					if tbl.NoSlow.WalkSpeedConn then
						tbl.NoSlow.WalkSpeedConn:Disconnect()
					end

					tbl.NoSlow.WalkSpeedConn = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(fn11)
					fn11()
				end
			end

			if not tbl.NoSlow.CharAddedConn then
				tbl.NoSlow.CharAddedConn = tbl.onCharacterAdded(function()
					task.wait(0.5)
					fn12()
				end)
			end
		else
			if tbl.NoSlow.WalkSpeedConn then
				tbl.NoSlow.WalkSpeedConn:Disconnect()
				tbl.NoSlow.WalkSpeedConn = nil
			end

			if tbl.NoSlow.CharAddedConn then
				tbl.NoSlow.CharAddedConn()
				tbl.NoSlow.CharAddedConn = nil
			end
		end
	end

	v21:AddToggle("NoSlowToggle", {
		Text = "无减速",
		Default = false,
		Tooltip = fn4("移除减速效果（重生后需重新开启）"),
		Callback = function(enabled)
			tbl.NoSlow.Enabled = enabled
			fn12()
		end,
	})
end

tbl.NoFall = { Enabled = false, Connection = nil }

local function fn11()
	while tbl.NoFall.Enabled do
		local character = localPlayer.Character

		if character then
			local health = character:FindFirstChild("Health")

			if health then
				local forceSelfDamage = health:FindFirstChild("ForceSelfDamage")

				if forceSelfDamage then
					pcall(function()
						forceSelfDamage:FireServer(0)
					end)
				end
			end
		end

		task.wait(1)
	end
end

v21:AddToggle("NoFallToggle", {
	Text = "移除摔伤",
	Default = false,
	Tooltip = fn4("移除摔落伤害（注意不防骨折）"),
	Callback = function(enabled)
		tbl.NoFall.Enabled = enabled

		if enabled then
			if tbl.NoFall.Connection then
				task.cancel(tbl.NoFall.Connection)
			end

			tbl.NoFall.Connection = task.spawn(fn11)
		elseif tbl.NoFall.Connection then
			task.cancel(tbl.NoFall.Connection)
			tbl.NoFall.Connection = nil
		end
	end,
})

tbl.Backpack = { Enabled = false, ToggleConn = nil }

v21:AddToggle("BackpackToggle", {
	Text = "显示物品栏",
	Default = false,
	Tooltip = fn4("强制显示物品栏"),
	Callback = function(enabled)
		tbl.Backpack.Enabled = enabled
		local backpackGui = localPlayer:WaitForChild("PlayerGui"):WaitForChild("BackpackGui")

		if enabled then
			backpackGui.Enabled = true

			if tbl.Backpack.ToggleConn then
				tbl.Backpack.ToggleConn:Disconnect()
			end

			tbl.Backpack.ToggleConn = backpackGui:GetPropertyChangedSignal("Enabled"):Connect(function()
				if not backpackGui.Enabled then
					backpackGui.Enabled = true
				end
			end)
		elseif tbl.Backpack.ToggleConn then
			tbl.Backpack.ToggleConn:Disconnect()
			tbl.Backpack.ToggleConn = nil
		end
	end,
})

tbl.auraEnabled = false
tbl.attackThread = nil
tbl.attackCount = 2
tbl.displayRange = 17
tbl.autoEquipWeaponEnabled = false
tbl.attackAngle = 180
tbl.showRangeVisuals = false
tbl.INNER_RING_FIXED_RADIUS = 13

tbl.smartAura = {
	enabled = false,
	auraClosed = false,
	innerEntryKills = {},
	checkInterval = 0.5,
	killTimeout = 2,
	retryInterval = 2,
	retryTimer = 0,
	probeMode = false,
}

tbl.attackBarrelEnabled = false
tbl.attackDraculaEnabled = false
tbl.skipSpawningEnabled = true
tbl.currentAttackTargets = {}
tbl.indicatorData = {}
tbl.indicatorUpdateConn = nil

tbl.isHoldingMelee = function()
	local character = localPlayer.Character
	if not character then
		return false
	end

	for _, v26 in character:GetChildren() do
		if v26:IsA("Tool") then
			local str2 = v26.Name:lower()
			if str2:find("axe") or str2:find("pickaxe") or str2:find("shovel") or str2:find("spade") or str2:find("稿") or str2:find("铲") or str2:find("镐") then
				return true
			end

			if str2:find("musket") or str2:find("flintlock") or str2:find("bayonet") then
				return true
			end
		end
	end

	return false
end

tbl.getNearestNonBarrelZombie = function()
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return nil
	end
	local position = humanoidRootPart.Position
	local displayRange = tbl.displayRange
	local zombies = workspace:FindFirstChild("Zombies")
	if not zombies then
		return nil
	end
	local huge = math.huge
	local v26 = nil

	for _, v27 in zombies:GetChildren() do
		if v27:IsA("Model") and v27:FindFirstChild("HumanoidRootPart") then
			if not (v27:GetAttribute("Type") == "Barrel" or v27:FindFirstChild("Barrel")) then
				local state = v27:FindFirstChild("State")

				if not (state and tostring(state.Value) == "Spawn") then
					local magnitude = (v27.HumanoidRootPart.Position - position).Magnitude

					if magnitude <= displayRange and magnitude < huge then
						huge = magnitude
						v26 = v27
					end
				end
			end
		end
	end

	return v26
end

tbl.getZombiesInRadius = function(arg)
	local character = localPlayer.Character
	if not character then
		return {}
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return {}
	end
	local position = humanoidRootPart.Position
	local zombies = workspace:FindFirstChild("Zombies")
	if not zombies then
		return {}
	end
	local tbl7 = {}

	for _, v26 in zombies:GetChildren() do
		if v26:IsA("Model") and v26:FindFirstChild("HumanoidRootPart") then
			local state = v26:FindFirstChild("State")

			if not (state and tostring(state.Value) == "Spawn") then
				if (v26.HumanoidRootPart.Position - position).Magnitude <= arg then
					table.insert(tbl7, v26)
				end
			end
		end
	end

	return tbl7
end

tbl.fireMeleeHit = function(arg, arg2, arg3, arg4, arg5)
	if not arg or not arg3 or not arg3.Parent then
		return
	end

	if arg2 then
		local orig = arg3:FindFirstChild("Orig")
		orig = orig and orig.Value or arg3
		arg:FireServer("ThrustBayonet")
		arg:FireServer("Bayonet_HitZombie", orig, arg4, true, "Head", "Down")
		orig:SetAttribute("WepHitID", clock2())
		orig:SetAttribute("WepHitDirection", arg5 * 10)
		orig:SetAttribute("WepHitPos", arg4)
	else
		arg:FireServer("Swing", "Thrust")
		arg:FireServer("PrepareSwing")
		arg:FireServer("HitZombieM", arg3, arg4, true, arg4, "Head", arg5)
	end
end

tbl.sendSingleAttack = function(arg)
	if not arg or not arg.Parent then
		return false
	end
	local character = localPlayer.Character
	if not character then
		return false
	end
	local v26 = nil

	for _, v27 in character:GetChildren() do
		if v27:IsA("Tool") then
			local str2 = v27.Name:lower()

			if v27:GetAttribute("Melee") or str2:find("musket") or str2:find("flintlock") or str2:find("bayonet") then
				v26 = v27
				break
			else
				v26 = nil
			end
		else
			v26 = nil
		end
	end

	if not v26 then
		return false
	end
	local remoteEvent = v26:FindFirstChild("RemoteEvent")
	if not remoteEvent then
		return false
	end
	local str2 = v26.Name:lower()
	local pos = str2:find("musket") or str2:find("flintlock") or str2:find("bayonet")
	local head = arg:FindFirstChild("Head")
	if not head then
		return false
	end
	local head2 = character:FindFirstChild("Head")
	local position = head.Position
	local unit = head2 and (position - head2.Position).Unit or Vector3.new(0, 1, 0)

	pcall(function()
		tbl.fireMeleeHit(remoteEvent, pos, arg, position, unit)
	end)

	return true
end

tbl.getCurrentKills = function()
	local leaderstats = localPlayer:FindFirstChild("leaderstats")

	if leaderstats then
		local kills = leaderstats:FindFirstChild("Kills")
		if kills and (kills:IsA("IntValue") or kills:IsA("NumberValue")) then
			return kills.Value
		end
	end

	return 0
end

tbl.updateSmartAura = function()
	if not tbl.smartAura.enabled then
		return
	end

	if not tbl.isHoldingMelee() then
		if tbl.smartAura.auraClosed then
			tbl.smartAura.auraClosed = false
			tbl.smartAura.probeMode = false
			tbl.smartAura.innerEntryKills = {}

			if not tbl.auraEnabled then
				tbl.startAura()
			end
		end

		return
	end

	local v26 = min(tbl.displayRange, tbl.INNER_RING_FIXED_RADIUS)
	local v27 = tbl.getZombiesInRadius(v26)
	local v28 = clock()
	local v29 = tbl.getCurrentKills()

	if not tbl.smartAura.auraClosed then
		local tbl7 = {}

		for _, v30 in v27, nil, nil do
			tbl7[v30] = true

			if not tbl.smartAura.innerEntryKills[v30] then
				tbl.smartAura.innerEntryKills[v30] = { time = v28, kills = v29 }
			end
		end

		for k in tbl.smartAura.innerEntryKills, nil, nil do
			if not tbl7[k] or not k.Parent then
				tbl.smartAura.innerEntryKills[k] = nil
			end
		end

		for k, v30 in tbl.smartAura.innerEntryKills, nil, nil do
			if k and k.Parent then
				local humanoid = k:FindFirstChildOfClass("Humanoid")

				if humanoid and humanoid.Health > 0 then
					if tbl.smartAura.killTimeout <= v28 - v30.time then
						local kills = v30.kills

						if tbl.getCurrentKills() == kills then
							tbl.smartAura.auraClosed = true
							tbl.smartAura.probeMode = true
							tbl.smartAura.retryTimer = 0
							tbl.smartAura.innerEntryKills = {}

							if tbl.auraEnabled then
								tbl.stopAura()
							end

							break
						else
							tbl.smartAura.innerEntryKills[k] = nil
						end
					end
				else
					tbl.smartAura.innerEntryKills[k] = nil
				end
			else
				tbl.smartAura.innerEntryKills[k] = nil
			end
		end

		return
	end

	if tbl.smartAura.probeMode then
		if v28 - tbl.smartAura.retryTimer >= tbl.smartAura.retryInterval then
			tbl.smartAura.retryTimer = v28
			local v30 = tbl.getNearestNonBarrelZombie()

			if v30 then
				local v31 = tbl.getCurrentKills()
				tbl.sendSingleAttack(v30)
				task.wait(2)

				if v31 < tbl.getCurrentKills() then
					tbl.smartAura.auraClosed = false
					tbl.smartAura.probeMode = false
					tbl.smartAura.innerEntryKills = {}

					if not tbl.auraEnabled then
						tbl.startAura()
					end
				end
			else
				tbl.smartAura.auraClosed = false
				tbl.smartAura.probeMode = false

				if not tbl.auraEnabled then
					tbl.startAura()
				end
			end
		end
	end
end

tbl.smartAuraThread = nil

tbl.startSmartAuraThread = function()
	if tbl.smartAuraThread then
		return
	end

	tbl.smartAuraThread = task.spawn(function()
		while tbl.smartAura.enabled do
			pcall(tbl.updateSmartAura)
			task.wait(tbl.smartAura.checkInterval)
		end
	end)
end

tbl.stopSmartAuraThread = function()
	if tbl.smartAuraThread then
		task.cancel(tbl.smartAuraThread)
		tbl.smartAuraThread = nil
	end

	tbl.smartAura.auraClosed = false
	tbl.smartAura.probeMode = false
	tbl.smartAura.innerEntryKills = {}
	tbl.smartAura.retryTimer = 0
end

tbl.attackLoop = function()
	while tbl.auraEnabled do
		if tbl.smartAura.enabled and tbl.smartAura.auraClosed then
			task.wait(0.1)
		else
			local v26 = tbl.getHeldMelee()

			if v26 then
				local str2 = v26.Name:lower()
				local pos = str2:find("musket") or str2:find("flintlock") or str2:find("bayonet")
				local remoteEvent = v26:FindFirstChild("RemoteEvent")
				local character = localPlayer.Character
				character = character and character:FindFirstChild("Head")
				local v27 = tbl.buildAttackTargets()

				if remoteEvent then
					for _, v28 in v27, nil, nil do
						local zombie = v28.zombie

						if zombie and zombie.Parent then
							local head = zombie:FindFirstChild("Head")

							if head then
								local position = head.Position
								local unit = character and (position - character.Position).Unit or Vector3.new(0, 1, 0)

								pcall(function()
									tbl.fireMeleeHit(remoteEvent, pos, zombie, position, unit)
								end)
							end
						end
					end
				end

				if #v27 > 0 then
					local currentAttackTargets = {}

					for _, v28 in v27, nil, nil do
						table.insert(currentAttackTargets, v28.zombie)
					end

					tbl.currentAttackTargets = currentAttackTargets
				else
					tbl.currentAttackTargets = {}
				end
			else
				tbl.currentAttackTargets = {}
			end

			task.wait(0.05)
		end
	end
end

tbl.startAura = function()
	if tbl.auraEnabled then
		return
	end
	tbl.auraEnabled = true

	if tbl.attackThread then
		task.cancel(tbl.attackThread)
	end

	tbl.attackThread = task.spawn(tbl.attackLoop)
end

tbl.stopAura = function()
	tbl.auraEnabled = false

	if tbl.attackThread then
		task.cancel(tbl.attackThread)
		tbl.attackThread = nil
	end

	tbl.currentAttackTargets = {}
end

tbl.rangeVisuals = {
	outerRingParts = {},
	outerRingBeams = {},
	innerRingParts = {},
	innerRingBeams = {},
	rayParts = {},
	rayEndParts = {},
	active = false,
	updateConn = nil,
	folder = nil,
	charAddedConn = nil,
	time = 0,
}

tbl.clearRangeVisuals = function()
	if tbl.rangeVisuals.folder then
		tbl.rangeVisuals.folder:Destroy()
		tbl.rangeVisuals.folder = nil
	end

	tbl.rangeVisuals.outerRingParts = {}
	tbl.rangeVisuals.outerRingBeams = {}
	tbl.rangeVisuals.innerRingParts = {}
	tbl.rangeVisuals.innerRingBeams = {}
	tbl.rangeVisuals.rayParts = {}
	tbl.rangeVisuals.rayEndParts = {}
	tbl.rangeVisuals.lastOuterColor = nil
	tbl.rangeVisuals.lastInnerColor = nil
	tbl.rangeVisuals.lastRayColor = nil
	tbl.rangeVisuals.lastShowRays = nil
	tbl.rangeVisuals.innerBeamsEnabled = nil

	if tbl.rangeVisuals.meleeCheckConn then
		tbl.rangeVisuals.meleeCheckConn:Disconnect()
		tbl.rangeVisuals.meleeCheckConn = nil
	end

	if tbl.rangeVisuals.ancestryConn then
		tbl.rangeVisuals.ancestryConn:Disconnect()
		tbl.rangeVisuals.ancestryConn = nil
	end

	tbl.rangeVisuals.cachedHoldingMelee = nil
end

tbl.createRangeVisuals = function()
	tbl.clearRangeVisuals()
	local folder = Instance.new("Folder")
	folder.Name = "KillAuraRangeVisuals"
	folder.Parent = workspace
	local outerRingParts = {}

	for i = 1, 24 do
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.7, 0.7, 0.7)
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 0.1
		part.Color = color(0, 255, 100)
		part.Parent = folder
		table.insert(outerRingParts, part)
	end

	local outerRingBeams = {}

	for i = 1, 24 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = outerRingParts[i]
		local attachment2 = Instance.new("Attachment")
		attachment2.Parent = outerRingParts[i % 24 + 1]
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachment
		beam.Attachment1 = attachment2
		beam.Color = ColorSequence.new(color(0, 255, 100))
		beam.Width0 = 0.15
		beam.Width1 = 0.15
		beam.FaceCamera = true
		beam.Parent = folder
		table.insert(outerRingBeams, { beam = beam, att0 = attachment, att1 = attachment2 })
	end

	local innerRingParts = {}

	for i = 1, 12 do
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 0.2
		part.Color = color(0, 255, 100)
		part.Parent = folder
		table.insert(innerRingParts, part)
	end

	local innerRingBeams = {}

	for i = 1, 12 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = innerRingParts[i]
		local attachment2 = Instance.new("Attachment")
		attachment2.Parent = innerRingParts[i % 12 + 1]
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachment
		beam.Attachment1 = attachment2
		beam.Color = ColorSequence.new(color(0, 255, 100))
		beam.Width0 = 0.1
		beam.Width1 = 0.1
		beam.FaceCamera = true
		beam.Parent = folder
		table.insert(innerRingBeams, { beam = beam, att0 = attachment, att1 = attachment2 })
	end

	local rayParts = {}
	local rayEndParts = {}

	for i = 1, 2 do
		local attachment = Instance.new("Attachment")
		attachment.Parent = folder
		local attachment2 = Instance.new("Attachment")
		attachment2.Parent = folder
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachment
		beam.Attachment1 = attachment2
		beam.Color = ColorSequence.new(color(0, 255, 100))
		beam.Width0 = 0.25
		beam.Width1 = 0.15
		beam.FaceCamera = true
		beam.Parent = folder
		table.insert(rayParts, { start = attachment, finish = attachment2, beam = beam })
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 0.15
		part.Color = color(0, 255, 100)
		part.Parent = folder
		table.insert(rayEndParts, part)
	end

	tbl.rangeVisuals.folder = folder
	tbl.rangeVisuals.outerRingParts = outerRingParts
	tbl.rangeVisuals.outerRingBeams = outerRingBeams
	tbl.rangeVisuals.innerRingParts = innerRingParts
	tbl.rangeVisuals.innerRingBeams = innerRingBeams
	tbl.rangeVisuals.rayParts = rayParts
	tbl.rangeVisuals.rayEndParts = rayEndParts
end

local function fn12(arg, arg2, arg3, arg4)
	local n2 = arg4 / 2
	local zombies = workspace:FindFirstChild("Zombies")

	if zombies then
		for _, v26 in zombies:GetChildren() do
			if v26:IsA("Model") and v26:FindFirstChild("HumanoidRootPart") then
				local position = v26.HumanoidRootPart.Position
				if not ((position - arg).Magnitude <= arg3) then
					continue
				end

				if arg4 >= 360 then
					return true
				end

				if math.deg(math.acos(clamp(arg2:Dot((position - arg).Unit), -1, 1))) <= n2 then
					return true
				end
			end
		end
	end

	if tbl.attackDraculaEnabled then
		local transylvania = fn2(workspace, "Transylvania", "Modes", "Boss", "Dracula")

		if transylvania and transylvania:FindFirstChild("HumanoidRootPart") then
			local position = transylvania.HumanoidRootPart.Position

			if (position - arg).Magnitude <= arg3 then
				if arg4 >= 360 then
					return true
				end

				if math.deg(math.acos(clamp(arg2:Dot((position - arg).Unit), -1, 1))) <= n2 then
					return true
				end
			end
		end
	end

	return false
end

tbl.updateRangeVisuals = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	local position = humanoidRootPart.Position
	local lookVector = humanoidRootPart.CFrame.LookVector
	local attackAngle = tbl.attackAngle
	local n2 = attackAngle / 2
	local displayRange = tbl.displayRange
	local innerRingFixedRadius = tbl.INNER_RING_FIXED_RADIUS
	tbl.rangeVisuals.time = (tbl.rangeVisuals.time or 0) + 0.016
	local time_ = tbl.rangeVisuals.time
	local cachedHoldingMelee = tbl.rangeVisuals.cachedHoldingMelee

	if cachedHoldingMelee == nil then
		cachedHoldingMelee = tbl.isHoldingMelee()
		tbl.rangeVisuals.cachedHoldingMelee = cachedHoldingMelee
	end

	cachedHoldingMelee = displayRange > innerRingFixedRadius and cachedHoldingMelee
	local transparency = fn12(position, lookVector, displayRange, attackAngle)
	local transparency2 = false

	if cachedHoldingMelee then
		transparency2 = fn12(position, lookVector, innerRingFixedRadius, attackAngle)
	end

	local v26 = transparency and color(255, 50, 50) or color(0, 255, 100)
	local v27 = transparency2 and color(255, 50, 50) or color(0, 255, 100)
	local n3 = math.sin(time_ * 1) * 0.3
	local n4 = time_ * 0.3
	local n5 = time_ * 0.6 + 0.8
	local outerRingParts = tbl.rangeVisuals.outerRingParts
	local n6 = #outerRingParts
	transparency = transparency and 0.08 or 0.15

	for i = 1, n6 do
		local n7 = i / n6 * 2 * 3.1415926535897931 + n4
		local sin = math.sin
		local n8 = position + vector(math.cos(n7), 0, sin(n7)) * displayRange
		outerRingParts[i].Position = vector(n8.X, position.Y + n3, n8.Z)
		outerRingParts[i].Color = v26
		outerRingParts[i].Transparency = transparency
	end

	if tbl.rangeVisuals.lastOuterColor ~= v26 then
		tbl.rangeVisuals.lastOuterColor = v26
		local colorSequence = ColorSequence.new(v26)

		for _, v28 in tbl.rangeVisuals.outerRingBeams, nil, nil do
			v28.beam.Color = colorSequence
		end
	end

	local innerRingParts = tbl.rangeVisuals.innerRingParts
	local n7 = #innerRingParts
	local n8 = math.sin(time_ * 1 + 1.2) * 0.3

	if cachedHoldingMelee then
		transparency2 = transparency2 and 0.12 or 0.25

		for i = 1, n7 do
			local n9 = i / n7 * 2 * 3.1415926535897931 + n5
			local sin = math.sin
			local n10 = position + vector(math.cos(n9), 0, sin(n9)) * innerRingFixedRadius
			innerRingParts[i].Position = vector(n10.X, position.Y + n8, n10.Z)
			innerRingParts[i].Color = v27
			innerRingParts[i].Transparency = transparency2
		end

		if tbl.rangeVisuals.lastInnerColor ~= v27 or not tbl.rangeVisuals.innerBeamsEnabled then
			tbl.rangeVisuals.lastInnerColor = v27
			tbl.rangeVisuals.innerBeamsEnabled = true
			local colorSequence = ColorSequence.new(v27)

			for _, v28 in tbl.rangeVisuals.innerRingBeams, nil, nil do
				v28.beam.Color = colorSequence
				v28.beam.Enabled = true
			end
		end
	elseif tbl.rangeVisuals.innerBeamsEnabled ~= false then
		tbl.rangeVisuals.innerBeamsEnabled = false
		tbl.rangeVisuals.lastInnerColor = nil

		for i = 1, n7 do
			innerRingParts[i].Color = color(0, 0, 0)
			innerRingParts[i].Transparency = 1
		end

		for _, v28 in tbl.rangeVisuals.innerRingBeams, nil, nil do
			v28.beam.Enabled = false
		end
	end

	local lastShowRays = attackAngle < 360

	if lastShowRays ~= tbl.rangeVisuals.lastShowRays then
		tbl.rangeVisuals.lastShowRays = lastShowRays

		if not lastShowRays then
			for k, v28 in tbl.rangeVisuals.rayParts, nil, nil do
				v28.beam.Enabled = false

				if tbl.rangeVisuals.rayEndParts[k] then
					tbl.rangeVisuals.rayEndParts[k].Transparency = 1
				end
			end
		end
	end

	if lastShowRays then
		for k, v28 in tbl.rangeVisuals.rayParts, nil, nil do
			local n9 = k == 1 and -n2 or n2
			local cframe2 = CFrame.Angles
			local n10 = position + (cframe(Vector3.zero, lookVector) * cframe2(0, rad(n9), 0)).LookVector * displayRange
			local v29 = vector(n10.X, position.Y, n10.Z)
			v28.start.Position = vector(position.X, position.Y, position.Z)
			v28.finish.Position = v29
			v28.beam.Enabled = true

			if tbl.rangeVisuals.rayEndParts[k] then
				local v30 = tbl.rangeVisuals.rayEndParts[k]
				v30.Position = v29
				v30.Transparency = 0.15
			end
		end

		if tbl.rangeVisuals.lastOuterColor ~= tbl.rangeVisuals.lastRayColor then
			tbl.rangeVisuals.lastRayColor = v26
			local colorSequence = ColorSequence.new(v26)

			for k, v28 in tbl.rangeVisuals.rayParts, nil, nil do
				v28.beam.Color = colorSequence

				if tbl.rangeVisuals.rayEndParts[k] then
					tbl.rangeVisuals.rayEndParts[k].Color = v26
				end
			end
		end
	end
end

tbl.startRangeVisuals = function()
	if tbl.rangeVisuals.active then
		return
	end
	tbl.rangeVisuals.active = true
	tbl.rangeVisuals.time = 0
	tbl.createRangeVisuals()

	if tbl.rangeVisuals.updateConn then
		tbl.rangeVisuals.updateConn:Disconnect()
	end

	tbl.rangeVisuals.updateConn = v5.RenderStepped:Connect(function()
		local active = tbl.rangeVisuals.active
		local showRangeVisuals

		if active then
			showRangeVisuals = tbl.showRangeVisuals or false
		else
			showRangeVisuals = active
		end

		if showRangeVisuals then
			tbl.updateRangeVisuals()
		end
	end)

	if tbl.rangeVisuals.charAddedConn then
		tbl.rangeVisuals.charAddedConn:Disconnect()
	end

	local v26 = localPlayer

	local function fn13(arg)
		if tbl.rangeVisuals.meleeCheckConn then
			tbl.rangeVisuals.meleeCheckConn:Disconnect()
			tbl.rangeVisuals.meleeCheckConn = nil
		end

		tbl.rangeVisuals.cachedHoldingMelee = tbl.isHoldingMelee()

		local connection2 = arg.ChildAdded:Connect(function()
			tbl.rangeVisuals.cachedHoldingMelee = nil
		end)

		local connection3 = arg.ChildRemoved:Connect(function()
			tbl.rangeVisuals.cachedHoldingMelee = nil
		end)

		tbl.rangeVisuals.meleeCheckConn = { Disconnect = function()
			connection2:Disconnect()
			connection3:Disconnect()
		end }
	end

	if v26.Character then
		fn13(v26.Character)
	end

	tbl.rangeVisuals.charAddedConn = tbl.onCharacterAdded(function(arg)
		task.wait(0.2)

		if tbl.rangeVisuals.active then
			tbl.createRangeVisuals()
			fn13(arg)
		end
	end)

	if tbl.rangeVisuals.ancestryConn then
		tbl.rangeVisuals.ancestryConn:Disconnect()
		tbl.rangeVisuals.ancestryConn = nil
	end

	local function fn14()
		tbl.clearRangeVisuals()
	end

	if v26.Character then
		tbl.rangeVisuals.ancestryConn = v26.Character.AncestryChanged:Connect(function(child, parent)
			if not parent then
				fn14()
			end
		end)
	end
end

tbl.stopRangeVisuals = function()
	tbl.rangeVisuals.active = false

	if tbl.rangeVisuals.updateConn then
		tbl.rangeVisuals.updateConn:Disconnect()
		tbl.rangeVisuals.updateConn = nil
	end

	if tbl.rangeVisuals.charAddedConn then
		tbl.rangeVisuals.charAddedConn()
		tbl.rangeVisuals.charAddedConn = nil
	end

	tbl.clearRangeVisuals()
end

tbl.createIndicator = function(parent)
	if not parent or not parent.Parent then
		return nil
	end
	local humanoidRootPart = parent:FindFirstChild("HumanoidRootPart") or parent:FindFirstChild("Torso")
	if not humanoidRootPart then
		return nil
	end
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "AttackTargetIndicator"
	billboardGui.Size = UDim2.new(0, 100, 0, 100)
	billboardGui.StudsOffset = Vector3.zero
	billboardGui.AlwaysOnTop = true
	billboardGui.Adornee = humanoidRootPart
	billboardGui.Parent = parent
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = billboardGui
	local frame2 = Instance.new("Frame")
	frame2.Size = UDim2.new(1, 0, 1, 0)
	frame2.BackgroundTransparency = 1
	frame2.Parent = frame
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 2
	uiStroke.Color = color(255, 255, 255)
	uiStroke.Transparency = 0.6
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = frame2
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = frame2
	local frame3 = Instance.new("Frame")
	frame3.Size = UDim2.new(0, 1.5, 0, 45)
	frame3.BackgroundColor3 = color(255, 255, 255)
	frame3.BackgroundTransparency = 0.7
	frame3.Position = UDim2.new(0.5, -0.75, 0.5, -22.5)
	frame3.Parent = frame
	local uiGradient = Instance.new("UIGradient")
	local new = NumberSequenceKeypoint.new
	uiGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), new(1, 0.2) })
	uiGradient.Rotation = 90
	uiGradient.Parent = frame3
	local uiCorner2 = Instance.new("UICorner")
	uiCorner2.CornerRadius = UDim.new(0, 2)
	uiCorner2.Parent = frame3
	local frame4 = Instance.new("Frame")
	frame4.Size = UDim2.new(0.7, 0, 0.7, 0)
	frame4.BackgroundTransparency = 1
	frame4.Parent = frame
	frame4.Position = UDim2.new(0.15, 0, 0.15, 0)
	local uiStroke2 = Instance.new("UIStroke")
	uiStroke2.Thickness = 1.5
	uiStroke2.Color = color(255, 215, 0)
	uiStroke2.Transparency = 0.6
	uiStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke2.Parent = frame4
	local uiCorner3 = Instance.new("UICorner")
	uiCorner3.CornerRadius = UDim.new(1, 0)
	uiCorner3.Parent = frame4
	local n2 = 6
	local n3 = 0.45

	local function createFrame(parent2, arg, arg2, rotation)
		local frame5 = Instance.new("Frame")
		frame5.Size = UDim2.new(0, 6, 0, 6)
		frame5.BackgroundTransparency = 1
		frame5.Position = UDim2.new(0.5 + arg * n3, -n2 / 2, 0.5 + arg2 * n3, -n2 / 2)
		frame5.Rotation = rotation
		frame5.Parent = parent2
		local frame6 = Instance.new("Frame")
		frame6.Size = UDim2.new(1, 0, 0, 1.5)
		frame6.BackgroundColor3 = color(255, 255, 255)
		frame6.BackgroundTransparency = 0.3
		frame6.Position = UDim2.new(0, 0, 0, 0)
		frame6.Parent = frame5
		local frame7 = Instance.new("Frame")
		frame7.Size = UDim2.new(0, 1.5, 1, 0)
		frame7.BackgroundColor3 = color(255, 255, 255)
		frame7.BackgroundTransparency = 0.3
		frame7.Position = UDim2.new(0, 0, 0, 0)
		frame7.Parent = frame5
		return frame5
	end

	local tbl7 = {}

	for _, v26 in { { -1, -1, 0 }, { 1, -1, 90 }, { -1, 1, -90 }, { 1, 1, 180 } }, nil, nil do
		local v27 = createFrame(frame, v26[1], v26[2], v26[3])
		table.insert(tbl7, v27)
	end

	local frame5 = Instance.new("Frame")
	frame5.Size = UDim2.new(0, 10, 0, 10)
	frame5.BackgroundTransparency = 1
	frame5.Position = UDim2.new(0.5, -5, 0.5, -5)
	frame5.Parent = frame
	local frame6 = Instance.new("Frame")
	frame6.Size = UDim2.new(1, 0, 0, 1.5)
	frame6.BackgroundColor3 = color(255, 255, 255)
	frame6.BackgroundTransparency = 0.4
	frame6.Position = UDim2.new(0, 0, 0.5, -0.75)
	frame6.Parent = frame5
	local frame7 = Instance.new("Frame")
	frame7.Size = UDim2.new(0, 1.5, 1, 0)
	frame7.BackgroundColor3 = color(255, 255, 255)
	frame7.BackgroundTransparency = 0.4
	frame7.Position = UDim2.new(0.5, -0.75, 0, 0)
	frame7.Parent = frame5

	return {
		gui = billboardGui,
		container = frame,
		outerFrame = frame2,
		outerStroke = uiStroke,
		innerFrame = frame4,
		innerStroke = uiStroke2,
		scanLine = frame3,
		corners = tbl7,
		crossGroup = frame5,
		currentAlpha = 0.8,
		targetAlpha = 0,
		currentSize = 100,
		targetSize = 50,
		normalSize = 50,
		state = "fadein",
	}
end

tbl.startIndicatorUpdater = function()
	if tbl.indicatorUpdateConn then
		return
	end

	tbl.indicatorUpdateConn = v5.RenderStepped:Connect(function(deltaTime)
		local currentAttackTargets = tbl.currentAttackTargets or {}
		local indicatorData = tbl.indicatorData
		local tbl7 = {}

		for _, v26 in currentAttackTargets, nil, nil do
			if v26 and v26.Parent then
				tbl7[v26] = true
			end
		end

		for k, v26 in indicatorData, nil, nil do
			if not k.Parent or not tbl7[k] then
				if v26.state ~= "fadeout" then
					v26.state = "fadeout"
					v26.targetAlpha = 0.8
					v26.targetSize = v26.normalSize * 2
				end
			elseif v26.state == "fadeout" then
				v26.state = "active"
				v26.targetAlpha = 0
				v26.targetSize = v26.normalSize
			elseif v26.state == "fadein" and v26.currentAlpha <= 0.02 and abs(v26.currentSize - v26.normalSize) < 0.5 then
				v26.state = "active"
			else
				v26.state = "active"
				v26.targetAlpha = 0
				v26.targetSize = v26.normalSize
			end

			if v26.state == "active" then
				v26.targetSize = v26.normalSize + math.sin(clock() * 2.5) * 1.5

				if v26.scanLine then
					v26.scanLine.Rotation = (v26.scanLine.Rotation or 0) + deltaTime * 120
				end

				v26.innerFrame.Rotation = (v26.innerFrame.Rotation or 0) + deltaTime * 80
				v26.innerStroke.Color = Color3.fromHSV(clock() % 3 / 3, 1, 1)
				v26.outerStroke.Transparency = math.sin(clock() * 2) * 0.3 + 0.6
				local backgroundTransparency = math.sin(clock() * 1.8 + 1) * 0.3 + 0.5

				for _, v27 in v26.corners, nil, nil do
					for _, v28 in v27:GetChildren() do
						if v28:IsA("Frame") then
							v28.BackgroundTransparency = backgroundTransparency
						end
					end
				end

				local backgroundTransparency2 = math.sin(clock() * 2.2 + 0.5) * 0.2 + 0.4

				if v26.crossGroup then
					for _, v27 in v26.crossGroup:GetChildren() do
						if v27:IsA("Frame") then
							v27.BackgroundTransparency = backgroundTransparency2
						end
					end
				end

				if v26.scanLine then
					v26.scanLine.BackgroundTransparency = math.sin(clock() * 4) * 0.2 + 0.6
				end
			elseif v26.state == "fadein" or v26.state == "fadeout" then
				v26.innerStroke.Color = color(255, 215, 0)
				v26.outerStroke.Transparency = 0.8

				if v26.scanLine then
					v26.scanLine.Rotation = 0
					v26.scanLine.BackgroundTransparency = 0.7
				end

				for _, v27 in v26.corners, nil, nil do
					for _, v28 in v27:GetChildren() do
						if v28:IsA("Frame") then
							v28.BackgroundTransparency = 0.3
						end
					end
				end

				if v26.crossGroup then
					for _, v27 in v26.crossGroup:GetChildren() do
						if v27:IsA("Frame") then
							v27.BackgroundTransparency = 0.4
						end
					end
				end
			end

			if v26.currentAlpha < v26.targetAlpha then
				v26.currentAlpha = min(v26.currentAlpha + 3 * deltaTime, v26.targetAlpha)
			elseif v26.targetAlpha < v26.currentAlpha then
				v26.currentAlpha = max(v26.currentAlpha - 3 * deltaTime, v26.targetAlpha)
			end

			if v26.currentSize < v26.targetSize then
				v26.currentSize = min(v26.currentSize + 180 * deltaTime, v26.targetSize)
			elseif v26.targetSize < v26.currentSize then
				v26.currentSize = max(v26.currentSize - 180 * deltaTime, v26.targetSize)
			end

			if v26.gui and v26.gui.Parent then
				local v27 = max(v26.currentSize, 1)
				v26.gui.Size = UDim2.new(0, v27, 0, v27)
			end

			if v26.state == "fadeout" and v26.currentAlpha >= 0.78 and v26.currentSize >= v26.normalSize * 1.9 then
				if v26.gui and v26.gui.Parent then
					v26.gui:Destroy()
				end

				indicatorData[k] = nil
			end
		end

		for _, v26 in currentAttackTargets, nil, nil do
			if v26 and v26.Parent and not indicatorData[v26] then
				local v27 = tbl.createIndicator(v26)

				if v27 then
					indicatorData[v26] = v27
				end
			end
		end
	end)
end

tbl.stopIndicatorUpdater = function()
	if tbl.indicatorUpdateConn then
		tbl.indicatorUpdateConn:Disconnect()
		tbl.indicatorUpdateConn = nil
	end

	for _, v26 in tbl.indicatorData, nil, nil do
		if v26.gui and v26.gui.Parent then
			v26.gui:Destroy()
		end
	end

	tbl.indicatorData = {}
	tbl.currentAttackTargets = {}
end

do
	local function fn13()
		return tbl.displayRange
	end

	local function fn14()
		local character = localPlayer.Character
		if not character then
			return false
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return false
		end
		local zombies = workspace:FindFirstChild("Zombies")
		if not zombies then
			return false
		end
		local position = humanoidRootPart.Position

		for _, v26 in zombies:GetChildren() do
			if v26:IsA("Model") and v26:FindFirstChild("HumanoidRootPart") then
				if (v26.HumanoidRootPart.Position - position).Magnitude <= 20 then
					return true
				end
			end
		end

		return false
	end

	tbl.getHeldMelee = function()
		local character = localPlayer.Character
		if not character then
			return nil
		end

		for _, v26 in character:GetChildren() do
			if v26:IsA("Tool") then
				local str2 = v26.Name:lower()
				if v26:GetAttribute("Melee") or str2:find("musket") or str2:find("flintlock") or str2:find("bayonet") then
					return v26
				end
			end
		end

		if tbl.autoEquipWeaponEnabled and fn14() then
			local backpack = localPlayer:FindFirstChild("Backpack")

			if backpack then
				for _, v26 in backpack:GetChildren() do
					if v26:IsA("Tool") then
						local str2 = v26.Name:lower()

						if v26:GetAttribute("Melee") or str2:find("musket") or str2:find("flintlock") or str2:find("bayonet") then
							v26.Parent = character
							task.wait(0.05)
							return v26
						end
					end
				end
			end
		end

		return nil
	end

	local function fn15(arg)
		local flag = arg:GetAttribute("Type") == "Barrel" or arg:FindFirstChild("Barrel") ~= nil
		return tbl.attackBarrelEnabled or not flag
	end

	local function fn16(arg, arg2)
		if tbl.attackAngle >= 360 then
			return true
		end
		local unit = (arg2 - arg.Position).Unit
		local lookVector = arg.CFrame.LookVector
		local n2 = tbl.attackAngle / 2
		return math.deg(math.acos(clamp(lookVector:Dot(unit), -1, 1))) <= n2
	end

	tbl.buildAttackTargets = function()
		local character = localPlayer.Character
		if not character then
			return {}
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return {}
		end
		local v26 = fn13()
		local tbl7 = {}
		local tbl8 = {}
		local zombies = workspace:FindFirstChild("Zombies")
		if not zombies then
			return {}
		end

		for _, v27 in zombies:GetChildren() do
			if v27:IsA("Model") and v27:FindFirstChild("HumanoidRootPart") then
				if tbl.skipSpawningEnabled then
					local state = v27:FindFirstChild("State")
					if state and tostring(state.Value) == "Spawn" then
						continue
					end
				end

				local flag = v27:GetAttribute("Type") == "Barrel" or v27:FindFirstChild("Barrel") ~= nil

				if not (not tbl.attackBarrelEnabled and flag) then
					local position = v27.HumanoidRootPart.Position
					local magnitude = (position - humanoidRootPart.Position).Magnitude

					if magnitude <= v26 and fn16(humanoidRootPart, position) then
						local tbl9 = { zombie = v27, dist = magnitude }

						if flag then
							table.insert(tbl7, tbl9)
						else
							table.insert(tbl8, tbl9)
						end
					end
				end
			end
		end

		table.sort(tbl7, function(arg, arg2)
			return arg.dist < arg2.dist
		end)

		table.sort(tbl8, function(arg, arg2)
			return arg.dist < arg2.dist
		end)

		local tbl9 = {}
		local attackCount = tbl.attackCount or 2

		if attackCount >= 2 and #tbl7 > 0 and tbl.attackBarrelEnabled then
			table.insert(tbl9, tbl7[1])

			for i = 1, min(#tbl8, attackCount - 1) do
				table.insert(tbl9, tbl8[i])
			end
		else
			local tbl10

			if tbl.attackBarrelEnabled then
				tbl10 = {}

				for _, v27 in tbl7, nil, nil do
					table.insert(tbl10, v27)
				end

				for _, v27 in tbl8, nil, nil do
					table.insert(tbl10, v27)
				end

				table.sort(tbl10, function(arg, arg2)
					return arg.dist < arg2.dist
				end)
			else
				tbl10 = tbl8
			end

			for i = 1, min(#tbl10, attackCount) do
				table.insert(tbl9, tbl10[i])
			end
		end

		if tbl.attackDraculaEnabled then
			local transylvania = fn2(workspace, "Transylvania", "Modes", "Boss", "Dracula")

			if transylvania then
				local humanoidRootPart2 = transylvania:FindFirstChild("HumanoidRootPart")
				local head = transylvania:FindFirstChild("Head")

				if humanoidRootPart2 and head then
					local position = humanoidRootPart2.Position
					local magnitude = (position - humanoidRootPart.Position).Magnitude

					if magnitude <= v26 and fn16(humanoidRootPart, position) then
						table.insert(tbl9, { zombie = transylvania, dist = magnitude })
					end
				end
			end
		end

		return tbl9
	end

	local v26 = tbl3.Main:AddRightTabbox()
	local v27 = v26:AddTab("目标选择")
	local v28 = v26:AddTab("攻击设置")
	local v29 = v26:AddTab("命中特效")

	v27:AddToggle("AttackBarrelToggle", {
		Text = "攻击自爆",
		Default = false,
		Tooltip = fn4("开启后杀戮光环会攻击自爆僵尸"),
		Callback = function(attackBarrelEnabled)
			tbl.attackBarrelEnabled = attackBarrelEnabled
		end,
	})

	v27:AddToggle("AttackDraculaToggle", {
		Text = "攻击德古拉",
		Default = false,
		Tooltip = fn4("开启后杀戮光环会同时攻击德古拉Boss"),
		Callback = function(attackDraculaEnabled)
			tbl.attackDraculaEnabled = attackDraculaEnabled
		end,
	})

	v27:AddToggle("SkipSpawningToggle", {
		Text = "跳过正在生成的僵尸",
		Default = true,
		Tooltip = fn4("开启后不会攻击正在生成的僵尸（减少误判）"),
		Callback = function(skipSpawningEnabled)
			tbl.skipSpawningEnabled = skipSpawningEnabled
		end,
	})

	v27:AddToggle("ShowRangeToggle", {
		Text = "显示攻击范围",
		Default = false,
		Callback = function(showRangeVisuals)
			tbl.showRangeVisuals = showRangeVisuals

			if showRangeVisuals then
				tbl.startRangeVisuals()
			else
				tbl.stopRangeVisuals()
			end
		end,
	})

	v27:AddToggle("SmartAuraToggle", {
		Text = "智能光环（卡伤检测）",
		Default = false,
		Tooltip = fn4("检测内环僵尸2秒未击杀则自动关闭光环，探测击杀后自动恢复（仅手持斧头/稿子/战壕铲生效）"),
		Callback = function(enabled)
			tbl.smartAura.enabled = enabled

			if enabled then
				tbl.startSmartAuraThread()
			else
				tbl.stopSmartAuraThread()

				if tbl.smartAura.auraClosed then
					tbl.smartAura.auraClosed = false
					tbl.smartAura.probeMode = false

					if not tbl.auraEnabled then
						tbl.startAura()
					end
				end
			end
		end,
	})

	v27:AddToggle("AutoEquipToggle", {
		Text = "自动装备武器",
		Default = false,
		Tooltip = fn4("靠近设定范围自动装备武器"),
		Callback = function(autoEquipWeaponEnabled)
			tbl.autoEquipWeaponEnabled = autoEquipWeaponEnabled
		end,
	})

	v28:AddSlider("AuraRange", {
		Text = "攻击距离",
		Default = 35,
		Min = 10,
		Max = 35,
		Rounding = 0,
		Suffix = " 格",
		Callback = function(arg)
			local displayRange = floor(arg * 0.5 + 0.5)

			if displayRange < 10 then
				displayRange = 10
			end

			if displayRange > 35 then
				displayRange = 35
			end

			tbl.displayRange = displayRange
		end,
	})

	v28:AddSlider("AuraAngle", {
		Text = "攻击角度",
		Default = 180,
		Min = 50,
		Max = 360,
		Rounding = 0,
		Suffix = "°",
		Callback = function(attackAngle)
			tbl.attackAngle = attackAngle
		end,
	})

	v28:AddSlider("AuraCount", {
		Text = "攻击数量",
		Default = 2,
		Min = 1,
		Max = 5,
		Rounding = 0,
		Suffix = " 个",
		Callback = function(attackCount)
			tbl.attackCount = attackCount
		end,
	})

	tbl.headshotEnabled = false
	tbl.removeBloodEnabled = false
	tbl.hookInstalled = false
	tbl.originalBayonetHitCheck = nil
	tbl.originalMeleeHitCheck = nil
	tbl.lastZombieHitTime = {}
	tbl.ZOMBIE_HIT_COOLDOWN = 0.1

	local function fn17(arg)
		if not arg then
			return nil
		end
		local parent = arg.Parent

		for i = 1, 5 do
			if not parent then
				break
			end

			if parent:IsA("Model") and (parent.Name == "m_Zombie" or parent:FindFirstChild("Orig")) then
				return parent
			end
			parent = parent.Parent
		end

		return nil
	end

	local function fn18(arg)
		if not arg then
			return nil
		end

		for _, v30 in arg:GetChildren() do
			if v30.Name == "Head" and (v30:IsA("Part") or v30:IsA("MeshPart")) then
				return v30
			end
		end

		return nil
	end

	tbl.unifiedBayonetHitCheck = function(arg, arg2, arg3, arg4, arg5)
		local hit = workspace:Raycast(arg2, arg3, type(arg4) == "table" and arg4.ray or arg4)

		if hit then
			local instance = hit.Instance
			local v30 = fn17(instance)

			if v30 then
				local v31 = clock()
				if tbl.lastZombieHitTime[v30] and v31 - tbl.lastZombieHitTime[v30] < tbl.ZOMBIE_HIT_COOLDOWN then
					return 0
				end
				local orig = v30:FindFirstChild("Orig")

				if orig then
					local v32 = fn18(v30)

					if v32 then
						local value = orig.Value
						local position = v32.Position
						local str2

						if tbl.headshotEnabled then
							str2 = "Head"
						elseif instance == v32 then
							str2 = "Head"
						else
							str2 = "Torso"
						end

						local n2

						if tbl.removeBloodEnabled then
							local humanoidRootPart = v30:FindFirstChild("HumanoidRootPart") or v30:FindFirstChild("Torso")

							if humanoidRootPart then
								n2 = humanoidRootPart.Position + Vector3.new(0, -9999, 0)
							else
								n2 = position
							end
						else
							n2 = position
						end

						arg.remoteEvent:FireServer("Bayonet_HitZombie", value, n2, true, str2, arg.swingType)
						value:SetAttribute("WepHitID", clock())
						value:SetAttribute("WepHitDirection", arg3 * 10)
						value:SetAttribute("WepHitPos", n2)
						tbl.lastZombieHitTime[v30] = v31
						return 1
					end
				end
			end
		end

		if tbl.originalBayonetHitCheck then
			return tbl.originalBayonetHitCheck(arg, arg2, arg3, arg4, arg5)
		end
		return 0
	end

	tbl.unifiedMeleeHitCheck = function(arg, arg2, arg3, arg4, arg5, arg6)
		local hit = workspace:Raycast(arg2, arg3, type(arg4) == "table" and arg4.ray or arg4)

		if hit then
			local instance = hit.Instance
			local v30 = fn17(instance)

			if v30 then
				local v31 = clock()
				if tbl.lastZombieHitTime[v30] and v31 - tbl.lastZombieHitTime[v30] < tbl.ZOMBIE_HIT_COOLDOWN then
					return 0
				end
				local orig = v30:FindFirstChild("Orig")

				if orig then
					local v32 = fn18(v30)

					if v32 then
						local value = orig.Value
						local position = v32.Position
						local str2

						if tbl.headshotEnabled then
							str2 = "Head"
						elseif instance == v32 then
							str2 = "Head"
						else
							str2 = "Torso"
						end

						if tbl.removeBloodEnabled then
							local humanoidRootPart = v30:FindFirstChild("HumanoidRootPart") or v30:FindFirstChild("Torso")

							if humanoidRootPart then
								position = humanoidRootPart.Position + Vector3.new(0, -9999, 0)
							end
						end

						local character = localPlayer.Character
						local head = character and character:FindFirstChild("Head")
						head = head and (position - head.Position).Unit or Vector3.new(0, 1, 0)

						if arg6 then
							arg.remoteEvent:FireServer("ThrustCharge", value, position, hit.Normal)
						else
							arg.remoteEvent:FireServer("HitZombieM", value, position, true, position, str2, head)
						end

						tbl.lastZombieHitTime[v30] = v31
						return 1
					end
				end
			end
		end

		if tbl.originalMeleeHitCheck then
			return tbl.originalMeleeHitCheck(arg, arg2, arg3, arg4, arg5, arg6)
		end
		return 0
	end

	tbl.updateHitHooks = function()
		local headshotEnabled = tbl.headshotEnabled or tbl.removeBloodEnabled
		local v30 = v7
		local weapons = v7:FindFirstChild("Modules") and v30.Modules:FindFirstChild("Weapons")
		local flag = type(hookfunction) == "function"

		if headshotEnabled and not tbl.hookInstalled then
			if weapons then
				local ok, result = pcall(require, weapons:FindFirstChild("Flintlock"))

				if ok and result and result.BayonetHitCheck then
					if flag then
						if not tbl.originalBayonetHitCheck then
							tbl.originalBayonetHitCheck = hookfunction(result.BayonetHitCheck, tbl.unifiedBayonetHitCheck)
						else
							hookfunction(result.BayonetHitCheck, tbl.unifiedBayonetHitCheck)
						end
					else
						if not tbl.originalBayonetHitCheck then
							tbl.originalBayonetHitCheck = result.BayonetHitCheck
						end

						result.BayonetHitCheck = tbl.unifiedBayonetHitCheck
					end
				end

				local ok2, result2 = pcall(require, weapons:FindFirstChild("MeleeBase"))

				if ok2 and result2 and result2.MeleeHitCheck then
					if flag then
						if not tbl.originalMeleeHitCheck then
							tbl.originalMeleeHitCheck = hookfunction(result2.MeleeHitCheck, tbl.unifiedMeleeHitCheck)
						else
							hookfunction(result2.MeleeHitCheck, tbl.unifiedMeleeHitCheck)
						end
					else
						if not tbl.originalMeleeHitCheck then
							tbl.originalMeleeHitCheck = result2.MeleeHitCheck
						end

						result2.MeleeHitCheck = tbl.unifiedMeleeHitCheck
					end
				end
			end

			tbl.hookInstalled = true
		elseif not headshotEnabled and tbl.hookInstalled then
			if weapons then
				if tbl.originalBayonetHitCheck then
					local ok, result = pcall(require, weapons:FindFirstChild("Flintlock"))

					if ok and result and result.BayonetHitCheck then
						if flag then
							hookfunction(result.BayonetHitCheck, tbl.originalBayonetHitCheck)
						else
							result.BayonetHitCheck = tbl.originalBayonetHitCheck
						end
					end
				end

				if tbl.originalMeleeHitCheck then
					local ok, result = pcall(require, weapons:FindFirstChild("MeleeBase"))

					if ok and result then
						if flag then
							hookfunction(result.MeleeHitCheck, tbl.originalMeleeHitCheck)
						else
							result.MeleeHitCheck = tbl.originalMeleeHitCheck
						end
					end
				end
			end

			tbl.hookInstalled = false
		end
	end

	tbl.onCharacterAdded(function()
		task.wait(1)
		tbl.updateHitHooks()
	end)

	v29:AddToggle("RemoveBloodToggle", {
		Text = "移除血液粒子",
		Default = false,
		Tooltip = fn4("将血迹生成位置移到僵尸脚下不可见处，不影响伤害"),
		Callback = function(removeBloodEnabled)
			tbl.removeBloodEnabled = removeBloodEnabled
			tbl.updateHitHooks()
		end,
	})

	v29:AddToggle("HeadshotToggle", {
		Text = "强制爆头",
		Default = false,
		Tooltip = fn4("强制所有近战/刺刀攻击命中头部"),
		Callback = function(headshotEnabled)
			tbl.headshotEnabled = headshotEnabled
			tbl.updateHitHooks()
		end,
	})

	tbl.zombieHitboxEnabled = false
	tbl.zombieHitboxSize = 10
	tbl.zombieHitboxAddedParts = {}

	local function fn19(parent)
		if not tbl.zombieHitboxEnabled then
			return
		end

		if tbl.zombieHitboxAddedParts[parent] then
			return
		end
		local humanoidRootPart = parent:FindFirstChild("HumanoidRootPart")
		local head = parent:FindFirstChild("Head")
		if not humanoidRootPart or not head then
			return
		end
		local part = Instance.new("Part")
		part.Name = "ZombieHitbox_Outer"
		part.Size = vector(tbl.zombieHitboxSize, tbl.zombieHitboxSize, tbl.zombieHitboxSize)
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = true
		part.Massless = true
		part.Anchored = false
		part.CFrame = humanoidRootPart.CFrame
		part.Parent = parent
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Part0 = humanoidRootPart
		weldConstraint.Part1 = part
		weldConstraint.Parent = part
		local part2 = Instance.new("Part")
		part2.Name = "ZombieHitbox_Head"
		part2.Size = vector(tbl.zombieHitboxSize / 2, tbl.zombieHitboxSize / 2, tbl.zombieHitboxSize / 2)
		part2.Transparency = 1
		part2.CanCollide = false
		part2.CanTouch = true
		part2.Massless = true
		part2.Anchored = false
		part2.CFrame = head.CFrame
		part2.Parent = parent
		local weldConstraint2 = Instance.new("WeldConstraint")
		weldConstraint2.Part0 = head
		weldConstraint2.Part1 = part2
		weldConstraint2.Parent = part2
		tbl.zombieHitboxAddedParts[parent] = { outer = part, head = part2 }
	end

	local function fn20(arg)
		local v30 = tbl.zombieHitboxAddedParts[arg]

		if v30 then
			if v30.outer then
				v30.outer:Destroy()
			end

			if v30.head then
				v30.head:Destroy()
			end

			tbl.zombieHitboxAddedParts[arg] = nil
		else
			for _, v31 in arg:GetChildren() do
				if v31.Name == "ZombieHitbox_Outer" or v31.Name == "ZombieHitbox_Head" then
					v31:Destroy()
				end
			end
		end
	end

	local function fn21()
		if not tbl.zombieHitboxEnabled then
			local tbl7 = {}

			for k in tbl.zombieHitboxAddedParts, nil, nil do
				table.insert(tbl7, k)
			end

			for _, v30 in tbl7, nil, nil do
				fn20(v30)
			end

			tbl.zombieHitboxAddedParts = {}
			return
		end

		local tbl7 = {}

		for _, v30 in tbl.ZombieWatch.getAll() do
			table.insert(tbl7, v30)
		end

		local tbl8 = {}

		for k in tbl.zombieHitboxAddedParts, nil, nil do
			local flag = false

			for _, v30 in tbl7, nil, nil do
				if v30 == k then
					flag = true
					break
				end
			end

			if not flag then
				table.insert(tbl8, k)
			end
		end

		for _, v30 in tbl8, nil, nil do
			fn20(v30)
		end

		for _, v30 in tbl7, nil, nil do
			if not tbl.zombieHitboxAddedParts[v30] then
				fn19(v30)
			end
		end
	end

	local function fn22()
		if not tbl.zombieHitboxEnabled then
			return
		end

		for _, v30 in tbl.zombieHitboxAddedParts, nil, nil do
			if v30.outer and v30.outer.Parent then
				v30.outer.Size = vector(tbl.zombieHitboxSize, tbl.zombieHitboxSize, tbl.zombieHitboxSize)
			end

			if v30.head and v30.head.Parent then
				v30.head.Size = vector(tbl.zombieHitboxSize / 2, tbl.zombieHitboxSize / 2, tbl.zombieHitboxSize / 2)
			end
		end
	end

	local function fn23(arg)
		if tbl.zombieHitboxEnabled and arg:IsA("Model") then
			task.wait(0.1)
			fn19(arg)
		end
	end

	tbl.ZombieWatch.start()
	tbl.ZombieWatch.onAdded(fn23)

	task.spawn(function()
		while true do
			task.wait(2)

			if tbl.zombieHitboxEnabled then
				fn21()
			end
		end
	end)

	v29:AddToggle("ZombieHitboxToggle", {
		Text = "僵尸碰撞箱扩展",
		Default = false,
		Tooltip = fn4("为僵尸添加更大的命中箱"),
		Callback = function(zombieHitboxEnabled)
			tbl.zombieHitboxEnabled = zombieHitboxEnabled

			if zombieHitboxEnabled then
				fn21()
			else
				local tbl7 = {}

				for k in tbl.zombieHitboxAddedParts, nil, nil do
					table.insert(tbl7, k)
				end

				for _, v30 in tbl7, nil, nil do
					fn20(v30)
				end

				tbl.zombieHitboxAddedParts = {}
			end
		end,
	})

	tbl.attackSpeedEnabled = false
	tbl.attackSpeedMultiplier = 1
	tbl.attackSpeedConn = nil

	tbl.MELEE_WEAPON_SET = {
		Sabre = true,
		["Le Revenant"] = true,
		Voivode = true,
		Axe = true,
		["Hand Axe"] = true,
		["Heavy Sabre"] = true,
		["Boarding Axe"] = true,
		Stake = true,
		Pickaxe = true,
		Spade = true,
		["Delicious Leg"] = true,
		Spontoon = true,
		Lance = true,
		Baguette = true,
		["Sword Bayonet"] = true,
	}

	tbl.isMeleeOrBayonet = function(arg)
		if not arg or not arg:IsA("Tool") then
			return false
		end

		if tbl.MELEE_WEAPON_SET[arg.Name] then
			return true
		end

		if arg:GetAttribute("Melee") == true then
			return true
		end
		local str2 = arg.Name:lower()
		if str2:find("sabre") or str2:find("sword") or str2:find("axe") or str2:find("pickaxe") or str2:find("spade") or str2:find("shovel") or str2:find("stake") or str2:find("lance") or str2:find("pike") or str2:find("spontoon") or str2:find("baguette") or str2:find("bayonet") or str2:find("revanant") or str2:find("voivode") or str2:find("leg") or str2:find("稿") or str2:find("铲") or str2:find("镐") then
			return true
		end
		return false
	end

	local function fn24(arg)
		if not arg then
			return
		end

		for _, v30 in arg:GetChildren() do
			if v30:IsA("Tool") then
				local swingSpeedBuff = v30:FindFirstChild("SwingSpeedBuff")

				if swingSpeedBuff then
					swingSpeedBuff:Destroy()
				end
			end
		end
	end

	tbl.updateAttackSpeed = function()
		if not tbl.attackSpeedEnabled then
			if tbl.attackSpeedConn then
				tbl.attackSpeedConn:Disconnect()
				tbl.attackSpeedConn = nil
			end

			local character = localPlayer.Character
			local backpack = localPlayer:FindFirstChild("Backpack")
			fn24(character)
			fn24(backpack)
			return
		end

		if not tbl.attackSpeedConn then
			tbl.attackSpeedConn = v5.Heartbeat:Connect(function()
				if not tbl.attackSpeedEnabled then
					return
				end
				local character = localPlayer.Character
				local backpack = localPlayer:FindFirstChild("Backpack")

				for _, v30 in { character, backpack }, nil, nil do
					if v30 then
						for _, v31 in v30:GetChildren() do
							if v31:IsA("Tool") then
								if tbl.isMeleeOrBayonet(v31) then
									local swingSpeedBuff = v31:FindFirstChild("SwingSpeedBuff")

									if not swingSpeedBuff then
										swingSpeedBuff = Instance.new("NumberValue")
										swingSpeedBuff.Name = "SwingSpeedBuff"
										swingSpeedBuff.Parent = v31
									end

									swingSpeedBuff.Value = tbl.attackSpeedMultiplier
								else
									local swingSpeedBuff = v31:FindFirstChild("SwingSpeedBuff")

									if swingSpeedBuff then
										swingSpeedBuff:Destroy()
									end
								end
							end
						end
					end
				end
			end)
		end
	end

	tbl.toggleAttackSpeed = function(attackSpeedEnabled)
		tbl.attackSpeedEnabled = attackSpeedEnabled
		tbl.updateAttackSpeed()
	end

	v29:AddToggle("AttackSpeedToggle", {
		Text = "加快攻击速度",
		Default = false,
		Callback = function(arg)
			tbl.toggleAttackSpeed(arg)
		end,
	})

	v29:AddSlider("ZombieHitboxSize", {
		Text = "碰撞箱大小",
		Default = 10,
		Min = 1,
		Max = 30,
		Rounding = 0,
		Suffix = " 单位",
		Callback = function(arg)
			tbl.zombieHitboxSize = clamp(arg, 1, 30)

			if tbl.zombieHitboxEnabled then
				fn22()
				fn21()
			end
		end,
	})

	v29:AddSlider("AttackSpeedMultiplier", {
		Text = "攻击速度倍数",
		Default = 0.5,
		Min = 0.5,
		Max = 10,
		Suffix = " 倍",
		Rounding = 1,
		Callback = function(attackSpeedMultiplier)
			tbl.attackSpeedMultiplier = attackSpeedMultiplier

			if tbl.attackSpeedEnabled then
				tbl.updateAttackSpeed()
			end
		end,
	})

	if not tbl.qingShuiAura then
		tbl.qingShuiAura = {}
	end

	tbl.qingShuiAura.enabled = false
	tbl.qingShuiAura.thread = nil
	tbl.qingShuiAura.lastAttackTime = {}

	tbl.startQingShuiAura = function()
		if tbl.qingShuiAura.thread then
			return
		end
		tbl.qingShuiAura.enabled = true

		tbl.qingShuiAura.thread = task.spawn(function()
			while tbl.qingShuiAura.enabled do
				local v30 = tbl.getHeldMelee()

				if v30 then
					local character = localPlayer.Character

					if character then
						local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart then
							local v31 = fn13()
							local tbl7 = {}
							local zombies = workspace:FindFirstChild("Zombies")

							if zombies then
								for _, v32 in zombies:GetChildren() do
									if v32:IsA("Model") and v32:FindFirstChild("HumanoidRootPart") then
										if tbl.skipSpawningEnabled then
											local state = v32:FindFirstChild("State")
											if state and tostring(state.Value) == "Spawn" then
												continue
											end
										end

										if fn15(v32) then
											local position = v32.HumanoidRootPart.Position
											local magnitude = (position - humanoidRootPart.Position).Magnitude

											if magnitude <= v31 and fn16(humanoidRootPart, position) then
												table.insert(tbl7, { zombie = v32, dist = magnitude })
											end
										end
									end
								end
							end

							if tbl.attackDraculaEnabled then
								local transylvania = fn2(workspace, "Transylvania", "Modes", "Boss", "Dracula")

								if transylvania then
									local humanoidRootPart2 = transylvania:FindFirstChild("HumanoidRootPart")
									local head = transylvania:FindFirstChild("Head")

									if humanoidRootPart2 and head then
										local position = humanoidRootPart2.Position
										local magnitude = (position - humanoidRootPart.Position).Magnitude

										if magnitude <= v31 and fn16(humanoidRootPart, position) then
											table.insert(tbl7, { zombie = transylvania, dist = magnitude })
										end
									end
								end
							end

							table.sort(tbl7, function(arg, arg2)
								return arg.dist < arg2.dist
							end)

							local v32 = min(tbl.attackCount, #tbl7)
							local v33 = clock()

							for i = 1, v32 do
								local zombie = tbl7[i].zombie

								if not tbl.qingShuiAura.lastAttackTime[zombie] or v33 - tbl.qingShuiAura.lastAttackTime[zombie] > 0.05 then
									local remoteEvent = v30:FindFirstChild("RemoteEvent")

									if remoteEvent then
										local head = zombie:FindFirstChild("Head")

										if head then
											local character2 = localPlayer.Character
											character2 = character2 and character2:FindFirstChild("Head")
											local position = head.Position
											character2 = character2 and (position - character2.Position).Unit or Vector3.new(0, 1, 0)
											remoteEvent:FireServer("Swing", "Thrust")
											remoteEvent:FireServer("PrepareSwing")
											remoteEvent:FireServer("HitZombieM", zombie, position, true, position, "Head", character2)
											tbl.qingShuiAura.lastAttackTime[zombie] = v33
										end
									end
								end
							end

							if v32 > 0 then
								local currentAttackTargets = {}

								for i = 1, v32 do
									if tbl7[i] then
										table.insert(currentAttackTargets, tbl7[i].zombie)
									end
								end

								tbl.currentAttackTargets = currentAttackTargets
							else
								tbl.currentAttackTargets = {}
							end
						end
					end
				else
					tbl.currentAttackTargets = {}
				end

				task.wait(0.2)
			end
		end)
	end
end

tbl.stopQingShuiAura = function()
	tbl.qingShuiAura.enabled = false

	if tbl.qingShuiAura.thread then
		task.cancel(tbl.qingShuiAura.thread)
		tbl.qingShuiAura.thread = nil
	end

	tbl.qingShuiAura.lastAttackTime = {}
end

tbl.onCharacterAdded(function()
	task.wait(0.5)

	if tbl.showRangeVisuals then
		tbl.startRangeVisuals()
	end
end)

lib:OnUnload(function()
	tbl.stopRangeVisuals()
	tbl.stopIndicatorUpdater()
	tbl.stopSmartAuraThread()

	if tbl.auraEnabled then
		tbl.stopAura()
	end

	if tbl.qingShuiAura and tbl.qingShuiAura.enabled then
		tbl.stopQingShuiAura()
	end
end)

local v26 = tbl3.Settings:AddLeftGroupbox("菜单")

v26:AddDropdown("InterfaceLanguage", {
	Text = "语言 / Language",
	Values = { "中文", "English" },
	Default = 1,
	Callback = function(arg)
		fn5(arg)
	end,
})

options.InterfaceLanguage:OnChanged(function()
	fn5(options.InterfaceLanguage.Value)
end)

lib:OnUnload(function()
	getgenv().SkinHubLoaded = nil

	local function fn13(arg)
		if arg and typeof(arg) == "RBXScriptConnection" and arg.Connected then
			arg:Disconnect()
		end
	end

	fn13(tbl.autoCollectConnection)
	fn13(tbl.autoCannon and tbl.autoCannon.connection)
	fn13(tbl.autoBell and tbl.autoBell.conn)
	fn13(tbl.LondonBoardAuto and tbl.LondonBoardAuto.heartbeat)
	fn13(tbl4 and tbl4.meleeConn)
	fn13(tbl.SilentAim and tbl.SilentAim.SilentAimUpdateConn)
	fn13(tbl.axeStunConnection)
	fn13(tbl.rollTiltConn)
	fn13(tbl.spin and tbl.spin.connection)
	fn13(tbl.thirdPerson and tbl.thirdPerson.connection)
	fn13(tbl.invert and tbl.invert.conn)
	fn13(tbl.bigHead and tbl.bigHead.connection)
	fn13(tbl.animLoop1205Connection)
	fn13(tbl.AutoEscape and tbl.AutoEscape.suspendConn)
	fn13(tbl.AntiGrab and tbl.AntiGrab.connection)
	fn13(tbl.infectionUpdateConn)
	fn13(tbl.jobUpdateConn)
	fn13(tbl.boomDraw and tbl.boomDraw.connection)
	fn13(tbl.bulletDisplay and tbl.bulletDisplay.connection)
	fn13(tbl.bulletDisplay and tbl.bulletDisplay.cameraConn)
	fn13(tbl.pingDisplay and tbl.pingDisplay.conn)
	fn13(tbl.infectionRemover and tbl.infectionRemover.conn)
	fn13(tbl.bombRange and tbl.bombRange.conn)
	fn13(tbl.handMortar and tbl.handMortar.cameraConn)
	fn13(tbl.handMortar and tbl.handMortar.conn)
	fn13(tbl.zombieESPHeartbeatConn)

	pcall(function()
		if lib4 then
			lib4:Clear()
		end
	end)

	fn13(tbl.CoordSpeed and tbl.CoordSpeed.Connection)
	fn13(connection)
	fn13(tbl.AutoJump and tbl.AutoJump.Connection)
	fn13(tbl.JumpMod and tbl.JumpMod.AntiFallConn)

	pcall(function()
		if tbl.tpFreecam then
			tbl.tpFreecam.cleanup()
		end
	end)

	pcall(function()
		if tbl.oneClick and tbl.oneClick.ui then
			tbl.oneClick.ui:Destroy()
		end
	end)

	pcall(function()
		if tbl.flyAway and tbl.flyAway.screenGui then
			tbl.flyAway.screenGui:Destroy()
		end
	end)

	pcall(function()
		if tbl.invisTool and tbl.invisTool.ui then
			tbl.invisTool.ui:Destroy()
		end
	end)

	pcall(function()
		if _G.boxerUI then
			_G.boxerUI:Destroy()
		end
	end)

	pcall(function()
		if _G.cavalryUI then
			_G.cavalryUI:Destroy()
		end
	end)

	pcall(function()
		if _G.zapperUI then
			_G.zapperUI:Destroy()
		end
	end)

	pcall(function()
		if tbl.toggleNewAnimUI then
			tbl.toggleNewAnimUI(false)
		end
	end)

	pcall(function()
		if tbl.toggleAnim17871770160UI then
			tbl.toggleAnim17871770160UI(false)
		end
	end)
end)

v26:AddButton("卸载脚本", function()
	pcall(function()
		if toggles then
			for _, toggle in pairs(toggles) do
				if toggle and toggle.Value == true and toggle.SetValue then
					pcall(function()
						toggle:SetValue(false)
					end)
				end
			end
		end
	end)

	lib:Unload()
end)

v26:AddLabel("菜单快捷键"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
lib.ToggleKeybind = options.MenuKeybind
lib2:SetLibrary(lib)
lib3:SetLibrary(lib)
lib3:IgnoreThemeSettings()
lib2:SetFolder("MyScriptTheme")
lib3:SetFolder("MyScriptConfig")
lib3:BuildConfigSection(tbl3.Settings)
lib2:ApplyToTab(tbl3.Settings)
lib.Scheme.BackgroundColor = color(8, 14, 26)
lib.Scheme.MainColor = color(18, 32, 56)
lib.Scheme.AccentColor = color(80, 200, 255)
lib.Scheme.OutlineColor = color(45, 90, 140)
lib.Scheme.DarkColor = color(4, 8, 16)
lib.Scheme.RedColor = color(255, 90, 90)
lib.Scheme.DestructiveColor = color(230, 60, 60)
lib.Scheme.WhiteColor = Color3.new(1, 1, 1)
lib.Scheme.FontColor = Color3.new(1, 1, 1)
lib.CornerRadius = 10

if options.FontFace then
	options.FontFace:SetValue("RobotoMono")
end

if options.BackgroundColor then
	options.BackgroundColor:SetValue(lib.Scheme.BackgroundColor)
end

if options.MainColor then
	options.MainColor:SetValue(lib.Scheme.MainColor)
end

if options.AccentColor then
	options.AccentColor:SetValue(lib.Scheme.AccentColor)
end

if options.OutlineColor then
	options.OutlineColor:SetValue(lib.Scheme.OutlineColor)
end

lib:UpdateColorsUsingRegistry()

task.defer(function()
	if tbl.bootLanguagePicked then
		options.InterfaceLanguage:SetValue(tbl.bootLanguage)
	else
		fn5(options.InterfaceLanguage.Value)
	end
end)

v4 = v(game:GetService("Players"))
localPlayer = v4.LocalPlayer

playIdentityAnimation = function()
	local character = localPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")

	local ok, result = pcall(function()
		animation.AnimationId = "rbxassetid://507766666"
	end)

	if not ok then
		warn("playIdentityAnimation: failed to set AnimationId:", result)
		return
	end
	local v27 = animator:LoadAnimation(animation)
	v27.Looped = true
	v27:Play()
	v27:AdjustSpeed(1)
	_G._identityTrack = v27
end

onCharacterAdded = function()
	task.wait(0.5)
	playIdentityAnimation()
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

if localPlayer.Character then
	onCharacterAdded()
end

tbl.voteMonitor = { enabled = false, conns = {}, voter = nil, target = nil, votes = {}, inProgress = false }

tbl.voteMonitor.start = function()
	if tbl.voteMonitor.enabled then
		return
	end
	tbl.voteMonitor.enabled = true
	local v27 = v(game:GetService("ReplicatedStorage"))
	local playerVote = v27:FindFirstChild("GameStates") and v27.GameStates:FindFirstChild("PlayerVote")
	if not playerVote then
		warn("[投票监听] 找不到 PlayerVote")
		return
	end
	local voted = playerVote:FindFirstChild("Voted")
	if not voted then
		warn("[投票监听] 找不到 Voted")
		return
	end

	for _, v28 in tbl.voteMonitor.conns, nil, nil do
		v28:Disconnect()
	end

	table.clear(tbl.voteMonitor.conns)

	local function fn13()
		if playerVote:GetAttribute("InProgress") then
			tbl.voteMonitor.inProgress = true
			tbl.voteMonitor.voter = playerVote:GetAttribute("Voter")
			tbl.voteMonitor.target = playerVote:GetAttribute("Target")
			tbl.voteMonitor.votes = {}

			if tbl.voteMonitor.voter and tbl.voteMonitor.target then
				local voter = tbl.voteMonitor.voter
				local target = tbl.voteMonitor.target
				lib:Notify(format(fn3("[投票] %s 发起对 %s 的投票"), voter, target), 3)
			end
		else
			tbl.voteMonitor.inProgress = false
			tbl.voteMonitor.voter = nil
			tbl.voteMonitor.target = nil
			tbl.voteMonitor.votes = {}
		end
	end

	local function fn14(attribute)
		if not tbl.voteMonitor.inProgress then
			return
		end
		local attribute2 = voted:GetAttribute(attribute)

		if attribute and attribute2 ~= nil then
			local v28 = attribute2 and fn3("同意") or fn3("反对")
			lib:Notify(format(fn3("[投票] %s %s"), attribute, v28), 2)
		end
	end

	table.insert(tbl.voteMonitor.conns, playerVote:GetAttributeChangedSignal("InProgress"):Connect(fn13))
	table.insert(tbl.voteMonitor.conns, voted.AttributeChanged:Connect(fn14))

	if playerVote:GetAttribute("InProgress") then
		fn13()
	end

	lib:Notify(fn3("投票显示已开启"), 2)
end

tbl.voteMonitor.stop = function()
	tbl.voteMonitor.enabled = false

	for _, v27 in tbl.voteMonitor.conns, nil, nil do
		v27:Disconnect()
	end

	table.clear(tbl.voteMonitor.conns)
	tbl.voteMonitor.voter = nil
	tbl.voteMonitor.target = nil
	tbl.voteMonitor.votes = {}
	tbl.voteMonitor.inProgress = false
	lib:Notify(fn3("投票显示已关闭"), 2)
end

v23:AddToggle("VoteMonitorToggle", {
	Text = "投票显示",
	Default = false,
	Callback = function(arg)
		if arg then
			tbl.voteMonitor.start()
		else
			tbl.voteMonitor.stop()
		end
	end,
})

lib:OnUnload(function()
	tbl.voteMonitor.stop()
end)

lib:UpdateColorsUsingRegistry()

do
	local accentColor = lib.Scheme.AccentColor
	local outlineColor = lib.Scheme.OutlineColor
	local mainColor = lib.Scheme.MainColor
	local backgroundColor = lib.Scheme.BackgroundColor
	Color3.fromRGB(math.floor(accentColor.R * 255 * 0.55), math.floor(accentColor.G * 255 * 0.55), math.floor(accentColor.B * 255 * 0.55))
	local min2 = math.min
	local n2 = outlineColor.B * 255 + 45
	local color2 = Color3.fromRGB(math.min(255, outlineColor.R * 255 + 30), math.min(255, outlineColor.G * 255 + 30), min2(255, n2))
	local min3 = math.min
	local n3 = mainColor.B * 255 + 18
	local color3 = Color3.fromRGB(math.min(255, mainColor.R * 255 + 12), math.min(255, mainColor.G * 255 + 12), min3(255, n3))

	local function fn13(arg, parent)
		local instance = parent:FindFirstChildOfClass(arg)

		if not instance then
			instance = Instance.new(arg)
			instance.Parent = parent
		end

		return instance
	end

	local function fn14(arg, arg2, arg3, rotation)
		local UIGradient = fn13("UIGradient", arg)
		UIGradient.Color = ColorSequence.new(arg2, arg3)
		UIGradient.Rotation = rotation or 90
	end

	local function fn15(arg, color4, thickness, transparency)
		local UIStroke = fn13("UIStroke", arg)
		UIStroke.Color = color4
		UIStroke.Thickness = thickness or 1
		UIStroke.Transparency = transparency or 0
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return UIStroke
	end

	local function fn16(arg, arg2)
		local UICorner = fn13("UICorner", arg)
		UICorner.CornerRadius = UDim.new(0, arg2)
		return UICorner
	end

	local function fn17(arg)
		if not arg.Parent then
			return
		end

		if arg:IsA("TextButton") and arg.Size.X.Scale == 1 and arg.Size.Y.Offset >= 34 and arg.Size.Y.Offset <= 44 then
			if not arg:GetAttribute("SkinHub_Tab") then
				arg:SetAttribute("SkinHub_Tab", true)
				fn15(arg, color2, 1, 0.55)
				fn14(arg, mainColor, Color3.fromRGB(math.min(255, mainColor.R * 255 + 8), math.min(255, mainColor.G * 255 + 8), math.min(255, mainColor.B * 255 + 14)), 90)
			end

			return
		end

		if (arg:IsA("TextButton") or arg:IsA("TextBox")) and arg.Size.Y.Offset >= 18 and arg.Size.Y.Offset <= 25 and arg.BackgroundTransparency < 1 and arg.BackgroundColor3 ~= Color3.new(1, 1, 1) then
			if not arg:GetAttribute("SkinHub_Ctrl") then
				arg:SetAttribute("SkinHub_Ctrl", true)
				fn16(arg, 6)
				fn15(arg, outlineColor, 1, 0.1)

				if arg.BackgroundColor3 == mainColor or arg.BackgroundColor3 == backgroundColor then
					local min4 = math.min
					local n4 = arg.BackgroundColor3.B * 255 + 16
					fn14(arg, arg.BackgroundColor3, Color3.fromRGB(math.min(255, arg.BackgroundColor3.R * 255 + 10), math.min(255, arg.BackgroundColor3.G * 255 + 10), min4(255, n4)), 90)
				end

				local backgroundColor3 = arg.BackgroundColor3

				arg.MouseEnter:Connect(function()
					if arg:GetAttribute("SkinHub_Dis") then
						return
					end
					local tbl7 = { BackgroundColor3 = color3 }
					v8:Create(arg, TweenInfo.new(0.15), tbl7):Play()
				end)

				arg.MouseLeave:Connect(function()
					if arg:GetAttribute("SkinHub_Dis") then
						return
					end
					local tbl7 = { BackgroundColor3 = backgroundColor3 }
					v8:Create(arg, TweenInfo.new(0.15), tbl7):Play()
				end)
			end

			return
		end

		if arg:IsA("Frame") and arg.BackgroundTransparency == 0 then
			if arg:FindFirstChildOfClass("UICorner") and arg:FindFirstChildOfClass("UIStroke") then
				if not arg:GetAttribute("SkinHub_Box") then
					arg:SetAttribute("SkinHub_Box", true)
					local uiStroke = arg:FindFirstChildOfClass("UIStroke")

					if uiStroke then
						uiStroke.Color = color2
						uiStroke.Transparency = 0.55
						uiStroke.Thickness = 1
					end
				end
			end
		end
	end

	task.defer(function()
		local screenGui = lib.ScreenGui
		if not screenGui then
			return
		end

		for _, v27 in screenGui:GetDescendants() do
			pcall(fn17, v27)
		end

		screenGui.DescendantAdded:Connect(function(descendant)
			task.defer(function()
				pcall(fn17, descendant)
			end)
		end)
	end)
end

local function fn13(arg)
	if arg:IsA("TextLabel") or arg:IsA("TextButton") or arg:IsA("TextBox") then
		if arg.TextTransparency ~= 0 then
			arg.TextTransparency = 0
		end
	end
end

task.defer(function()
	local screenGui = lib.ScreenGui
	if not screenGui then
		return
	end

	for _, v27 in screenGui:GetDescendants() do
		fn13(v27)
	end

	screenGui.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			task.defer(function()
				descendant.TextTransparency = 0
			end)
		end
	end)

	local n2 = 0

	v5.Heartbeat:Connect(function()
		local now = os.clock()
		if now - n2 < 0.15 then
			return
		end
		n2 = now

		for _, v27 in screenGui:GetDescendants() do
			fn13(v27)
		end
	end)
end)

local function fn14()
	local mainFrame = lib.Window and lib.Window.MainFrame
	if not mainFrame then
		return nil
	end

	for _, v27 in mainFrame:GetDescendants() do
		if v27:IsA("TextLabel") and v27.Text and (v27.Text == "Skin HUB v4.2" or v27.Text:find("Skin HUB")) then
			return v27
		end
	end

	return nil
end

task.spawn(function()
	local v27

	while true do
		v27 = fn14()

		if not v27 then
			task.wait(0.2)
		end

		if not v27 then
			continue
		end
		break
	end

	v27.FontFace = Font.fromEnum(Enum.Font.SciFi)
	v27.TextSize = 22
	local uiGradient = v27:FindFirstChildOfClass("UIGradient")

	if not uiGradient then
		uiGradient = Instance.new("UIGradient")
		uiGradient.Parent = v27
	end

	local colorSequence = ColorSequence.new
	local tbl7 = {}
	local v28 = ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 255))
	local v29 = ColorSequenceKeypoint.new(0.25, Color3.fromRGB(200, 245, 255))
	local v30 = ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255))
	local v31 = ColorSequenceKeypoint.new(0.75, Color3.fromRGB(140, 220, 255))
	tbl7[1] = v28
	tbl7[2] = v29
	tbl7[3] = v30
	tbl7[4] = v31

	do
		local values = table.pack(ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 220, 255)))
		table.move(values, 1, values.n, 5, tbl7)
	end

	uiGradient.Color = colorSequence(tbl7)
	uiGradient.Rotation = 0
	v27.TextStrokeColor3 = Color3.fromRGB(30, 120, 200)
	v27.TextStrokeTransparency = 0.3
	local now = os.clock()

	while v27.Parent do
		uiGradient.Rotation = (os.clock() - now) * 60 % 360
		v5.RenderStepped:Wait()
	end
end)
