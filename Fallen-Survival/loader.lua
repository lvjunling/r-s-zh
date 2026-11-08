	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer then
		warn("无法获取本地玩家，脚本已安全退出。")
		return
	end

	local UserInputService = game:GetService("UserInputService")

	-- 移动端检测
	local IsMobile = false
	do
		local Success, Touch, Keyboard = pcall(function()
			return UserInputService.TouchEnabled, UserInputService.KeyboardEnabled
		end)
		IsMobile = Success and Touch == true and Keyboard ~= true
	end
	if IsMobile then
		warn("检测到移动端环境，已启用移动端兼容模式。")
	end

	-- 执行器缺少 WorldToScreen 全局时使用相机投影回退
	if type(WorldToScreen) ~= "function" then
		WorldToScreen = function(Position)
			local Camera = Workspace.CurrentCamera
			if not Camera then
				return Vector2.new(0, 0), false
			end
			local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Position)
			return Vector2.new(ScreenPos.X, ScreenPos.Y), OnScreen
		end
	end

	-- 移动端没有鼠标指针，瞄准点改用屏幕中心
	local function GetAimPoint()
		if IsMobile then
			local Camera = Workspace.CurrentCamera
			local Viewport = Camera and Camera.ViewportSize or Vector2.new(0, 0)
			return Vector2.new(Viewport.X / 2, Viewport.Y / 2)
		end
		local Mouse = LocalPlayer:GetMouse()
		return Vector2.new(Mouse.X, Mouse.Y)
	end

	-- 移动端跳跃按钮监听，用于连跳
	local MobileJumpTime = 0
	if IsMobile then
		UserInputService.JumpRequest:Connect(function()
			MobileJumpTime = tick()
		end)
	end

	-- 探测绘图库是否可用（部分移动端执行器不支持 Drawing）
	local DrawingSupported = false
	do
		local Success = pcall(function()
			local Probe = Drawing.new("Text")
			Probe:Remove()
		end)
		DrawingSupported = Success
	end
	if not DrawingSupported then
		warn("当前环境不支持绘图库，FOV 圆圈、瞄准连线与 ESP 标签已禁用。")
	end

	local Flags = {}

	Flags.AimbotTargetPart = "头部"
	Flags.AimbotFovRadius = 50
	Flags.AimbotMaxDistance = 1000
	Flags.ModCheckerBehavior = "通知"
	Flags.LootEspDistance = 500
	Flags.NodeEspDistance = 500
	Flags.MiniEspDistance = 500
	Flags.PlantEspDistance = 500
	Flags.RaidEspDistance = 2000
	Flags.FovColor = Color3.fromRGB(255, 255, 255)
	Flags.FovAlpha = 1
	Flags.SnaplineColor = Color3.fromRGB(255, 255, 255)
	Flags.SnaplineAlpha = 1
	Flags.CheaterDetectorColor = Color3.fromRGB(255, 13, 13)
	Flags.CheaterDetectorAlpha = 1
	Flags.DropsColor = Color3.fromRGB(110, 149, 255)
	Flags.DropsAlpha = 1
	Flags.BodybagColor = Color3.fromRGB(255, 100, 100)
	Flags.BodybagAlpha = 1
	Flags.StoneColor = Color3.new(0.5, 0.5, 0.5)
	Flags.StoneAlpha = 1
	Flags.MetalColor = Color3.new(1, 0.6, 0.1)
	Flags.MetalAlpha = 1
	Flags.PhosphateColor = Color3.new(1, 1, 0.5)
	Flags.PhosphateAlpha = 1
	Flags.WoolColor = Color3.new(0.92, 0.92, 0.92)
	Flags.WoolAlpha = 1
	Flags.TomatoColor = Color3.new(1, 0.18, 0.18)
	Flags.TomatoAlpha = 1
	Flags.PumpkinColor = Color3.new(1, 0.62, 0.13)
	Flags.PumpkinAlpha = 1
	Flags.CornColor = Color3.new(1, 1, 0.22)
	Flags.CornAlpha = 1
	Flags.MinicopterColor = Color3.fromRGB(24, 66, 255)
	Flags.MinicopterAlpha = 1
	Flags.RaidColor = Color3.fromRGB(255, 14, 14)
	Flags.RaidAlpha = 1
	Flags.BulletThickness = 1
	Flags.FireRateMult = 1

	local BulletInfo = {
		["Pumpkin Launcher"] = { Speed = 80, Gravity = 0.16 },
		["Military M4A1"] = { Speed = 2100, Gravity = 0.55 },
		["Salvaged AK74u"] = { Speed = 1800, Gravity = 0.6 },
		["Nail Gun"] = { Speed = 165, Gravity = 0.25 },
		["Salvaged RPG"] = { Speed = 100, Gravity = 0.12 },
		["Salvaged Python"] = { Speed = 1800, Gravity = 0.6 },
		["Salvaged M14"] = { Speed = 2100, Gravity = 0.55 },
		["Salvaged SMG"] = { Speed = 1800, Gravity = 0.6 },
		["Salvaged P250"] = { Speed = 1400, Gravity = 0.6 },
		["Salvaged Sniper"] = { Speed = 2400, Gravity = 0.55 },
		["Wooden Bow"] = { Speed = 320, Gravity = 0.2 },
		["Salvaged Pipe Rifle"] = { Speed = 1700, Gravity = 0.6 },
		["Salvaged AK47"] = { Speed = 2100, Gravity = 0.55 },
		["Crossbow"] = { Speed = 420, Gravity = 0.2 },
		["Salvaged Pump Action"] = { Speed = 650, Gravity = 0.6 },
		["Military AA12"] = { Speed = 600, Gravity = 0.6 },
		["Salvaged Skorpion"] = { Speed = 1600, Gravity = 0.6 },
		["Military Barrett"] = { Speed = 2500, Gravity = 0.55 },
		["Military PKM"] = { Speed = 2400, Gravity = 0.55 },
		["Bruno's M4A1"] = { Speed = 2100, Gravity = 0.55 },
		["Military MP7"] = { Speed = 1900, Gravity = 0.6 },
		["Military USP"] = { Speed = 1500, Gravity = 0.6 },
		["Salvaged Shotgun"] = { Speed = 400, Gravity = 0.6 },
		["Salvaged Break Action"] = { Speed = 550, Gravity = 0.6 },
		["Military Grenade Launcher"] = { Speed = 85, Gravity = 0.15 },
		["Salvaged Grenade Launcher"] = { Speed = 85, Gravity = 0.15 },
		["Salvaged Double Barrel"] = { Speed = 550, Gravity = 0.6 },
		["Military M39"] = { Speed = 2400, Gravity = 0.52 },
	}

	local ModeratorIDs = {
		[51281722] = "游戏管理员",
		[7178750309] = "游戏管理员",
		[113179883] = "游戏管理员",
		[3122439095] = "游戏管理员",
		[991290934] = "游戏管理员",
		[3968854760] = "游戏管理员",
		[81993536] = "游戏管理员",
		[1004214871] = "游戏管理员",
		[3034930770] = "游戏管理员",
		[2364950171] = "游戏管理员",
		[1528346843] = "游戏管理员",
		[165053216] = "游戏管理员",
		[1127954045] = "游戏管理员",
		[3640120679] = "游戏管理员",
		[602009251] = "游戏管理员",
		[372791101] = "游戏管理员",
		[1378169111] = "游戏管理员",
		[3020799797] = "游戏管理员",
		[2567998467] = "游戏管理员",
		[4243907215] = "游戏管理员",
		[353983652] = "游戏管理员",
		[1406181681] = "游戏管理员",
		[2229169589] = "游戏管理员",
		[3004094651] = "游戏管理员",
		[839333692] = "游戏管理员",
		[979624578] = "游戏管理员",
		[1478885961] = "游戏管理员",
		[399754916] = "游戏管理员",
		[1193091081] = "游戏管理员",
		[4553863490] = "游戏管理员",
		[4225513035] = "游戏管理员",
		[41482597] = "游戏管理员",
		[2924549627] = "游戏管理员",
		[2732967856] = "游戏管理员",
		[1937516999] = "游戏管理员",
		[1374319325] = "游戏管理员",
		[1058831985] = "游戏管理员",
		[9621064456] = "游戏管理员",
		[584370127] = "游戏管理员",
		[813030262] = "游戏管理员",
		[3470393585] = "游戏管理员",
		[122915793] = "游戏管理员",
		[1534692727] = "游戏管理员",
		[7278178099] = "游戏管理员",
		[8593140875] = "游戏管理员",
		[2525997354] = "游戏管理员",
		[3126891654] = "游戏管理员",
		[1190967808] = "游戏管理员",
		[833946684] = "游戏管理员",
		[202751467] = "游戏管理员",
		[510349404] = "游戏管理员",
		[174212818] = "贡献者",
		[25548179] = "首席开发者",
		[363101315] = "首席开发者",
		[47983795] = "联合创始人",
		[16681869] = "创始人",
	}

	local HeadHitboxSize = Vector3.new(1.15, 1.16, 1.16)

	-- helper functions
	local function LoadOffsets()
		local Success, Result = pcall(function()
			local Response = game:HttpGet("https://offsets.imtheo.lol/Offsets.json")
			assert(type(Response) == "string" and #Response > 0, "empty offsets response")

			local Decoded = HttpService:JSONDecode(Response)
			assert(type(Decoded) == "table" and type(Decoded.Offsets) == "table", "invalid offsets payload")

			local LoadedOffsets = Decoded.Offsets
			assert(type(LoadedOffsets.Player) == "table", "missing Player offsets")
			assert(type(LoadedOffsets.Player.AccountAge) == "number", "missing Player.AccountAge offset")
			assert(type(LoadedOffsets.Player.UserId) == "number", "missing Player.UserId offset")
			assert(type(LoadedOffsets.BasePart) == "table", "missing BasePart offsets")
			assert(type(LoadedOffsets.BasePart.Transparency) == "number", "missing BasePart.Transparency offset")
			assert(type(LoadedOffsets.Humanoid) == "table", "missing Humanoid offsets")
			assert(type(LoadedOffsets.Humanoid.FloorMaterial) == "number", "missing Humanoid.FloorMaterial offset")
			assert(type(LoadedOffsets.Humanoid.Jump) == "number", "missing Humanoid.Jump offset")

			return LoadedOffsets
		end)
		if not Success then
			warn("加载偏移数据失败: " .. tostring(Result))
			return nil
		end
		return Result
	end

	local Offsets = LoadOffsets()
	if not Offsets then
		warn("缺少必需的偏移数据，脚本已安全退出。")
		return
	end

	local function IsValidAddress(Value)
		return type(Value) == "number" and Value >= 65536
	end

	local Cache = {}
	do
		local Success, Result = pcall(function()
			assert(type(getgc) == "function", "getgc is unavailable")
			return getgc({
				"RecoilMult",
				"RangeMult",
				"SpeedMult",
				"AimSpreadMult",
				"HipSpreadMult",
				"FireRateMult",
				"SwayMult",
			})
		end)
		if Success and type(Result) == "table" then
			Cache = Result
		else
			warn("武器修改缓存不可用: " .. tostring(Result))
		end
	end

	local function ApplyGcValue(Key, Value)
		if type(applygc) ~= "function" or next(Cache) == nil then
			return
		end
		local Success, Error = pcall(applygc, Cache, Key, Value)
		if not Success then
			warn(("应用 %s 失败: %s"):format(Key, tostring(Error)))
		end
	end

	local function EnableNoRecoil()
		ApplyGcValue("RecoilMult", -1)
	end
	local function DisableNoRecoil()
		ApplyGcValue("RecoilMult", 1)
	end
	local function EnableExtendRange()
		ApplyGcValue("RangeMult", 10)
	end
	local function DisableExtendRange()
		ApplyGcValue("RangeMult", 1)
	end
	local function EnableNoSpread()
		ApplyGcValue("AimSpreadMult", -1)
		ApplyGcValue("HipSpreadMult", -1)
	end
	local function DisableNoSpread()
		ApplyGcValue("AimSpreadMult", 1)
		ApplyGcValue("HipSpreadMult", 1)
	end
	local function EnableInstantBullet()
		ApplyGcValue("SpeedMult", 10)
	end
	local function DisableInstantBullet()
		ApplyGcValue("SpeedMult", 1)
	end
	local function ApplyFireRate(V)
		ApplyGcValue("FireRateMult", V - 1)
	end
	local function EnableNoSway()
		ApplyGcValue("SwayMult", -1)
	end
	local function DisableNoSway()
		ApplyGcValue("SwayMult", 1)
	end

	local function ResolveTargetPart(Character, Head, HumanoidRootPart)
		local MousePos = GetAimPoint()
		local TargetPartName = Flags.AimbotTargetPart

		if TargetPartName == "躯干" then
			return HumanoidRootPart or Head
		elseif TargetPartName == "最近部位" then
			local ClosestPartDist = math.huge
			local ClosestPart = Head
			for _, Part in Character:GetChildren() do
				if not Part:IsA("BasePart") then
					continue
				end
				if not Part.Position then
					continue
				end
				local PartScreen, PartOnScreen = WorldToScreen(Part.Position)
				if not PartOnScreen then
					continue
				end
				local dx = PartScreen.X - MousePos.X
				local dy = PartScreen.Y - MousePos.Y
				local PartDist = math.sqrt(dx * dx + dy * dy)
				if PartDist < ClosestPartDist then
					ClosestPartDist = PartDist
					ClosestPart = Part
				end
			end
			return ClosestPart
		else
			return Head
		end
	end

	local function FindClosestViableTarget()
		local ClosestTarget
		local ClosestDistance = math.huge
		local MousePos = GetAimPoint()
		local LocalChar = LocalPlayer.Character
		if not LocalChar then
			return
		end
		local LocalRoot = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")

		for _, Player in Players:GetPlayers() do
			if Player.Name == LocalPlayer.Name then
				continue
			end
			local Char = Player.Character
			if not Char then
				continue
			end
			local Head = Char:FindFirstChild("Head")
			if not Head then
				continue
			end
			local Humanoid = Char:FindFirstChild("Humanoid")
			if not Humanoid then
				continue
			end
			if Humanoid.Health <= 0 then
				continue
			end
			local HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart")
			if not HumanoidRootPart then
				continue
			end

			if Flags.SafezoneCheck then
				local Success, Value = pcall(function()
					return Player:GetAttribute("SafeZone")
				end)
				if not Success then
					continue
				end
				if Value then
					continue
				end
			end

			local TargetPart = ResolveTargetPart(Char, Head, HumanoidRootPart)
			if not TargetPart then
				continue
			end

			if LocalRoot and (LocalRoot.Position - TargetPart.Position).Magnitude > Flags.AimbotMaxDistance then
				continue
			end

			local ScreenPos, OnScreen = WorldToScreen(TargetPart.Position)
			if not OnScreen then
				continue
			end

			local dx = ScreenPos.X - MousePos.X
			local dy = ScreenPos.Y - MousePos.Y
			local Distance = math.sqrt(dx * dx + dy * dy)
			if Flags.AimbotFovCheck and Distance > (Flags.AimbotFovRadius or 50) then
				continue
			end

			if Distance < ClosestDistance then
				ClosestDistance = Distance
				ClosestTarget = {
					Player = Player,
					Character = Char,
					Head = Head,
					HumanoidRootPart = HumanoidRootPart,
					Humanoid = Humanoid,
					TargetPart = TargetPart,
					ScreenDistance = Distance,
					ScreenPos = Vector2.new(ScreenPos.X, ScreenPos.Y),
				}
			end
		end

		return ClosestTarget
	end

	local function IsLockedTargetValid(Target)
		return Target ~= nil
			and Target.Player ~= nil
			and Target.Player.Parent == Players
			and Target.Character ~= nil
			and Target.Character == Target.Player.Character
			and Target.Humanoid ~= nil
			and Target.Humanoid.Parent == Target.Character
			and Target.Humanoid.Health > 0
			and Target.TargetPart ~= nil
			and Target.TargetPart.Parent ~= nil
	end

	local function GetHeldWeapon(Char)
		if not Char then
			return "None"
		end
		for _, Model in Char:GetChildren() do
			if not Model:IsA("Model") then
				continue
			end
			if Model.Name == "Hair" or Model.Name == "HolsterModel" then
				continue
			end
			if
				Model:FindFirstChild("Detail")
				or Model:FindFirstChild("Main")
				or Model:FindFirstChild("Handle")
				or Model:FindFirstChild("Attachments")
				or Model:FindFirstChild("ArrowAttach")
				or Model:FindFirstChild("Attach")
			then
				return Model.Name
			end
		end
		return "None"
	end

	local function GetBulletInfo(WeaponName)
		if not WeaponName then
			return nil
		end
		return BulletInfo[WeaponName]
	end

	local function CalculateDrop(BulletSpeed, BulletGravity, Position, Origin)
		local Distance = (Origin - Position).Magnitude
		local TimeToHit = Distance / BulletSpeed
		local G = BulletGravity * -195
		local Drop = -0.5 * G * TimeToHit * TimeToHit
		if tostring(Drop):find("nan") then
			Drop = 0
		end
		return Drop
	end

	local function CalculateTargetPosition(BulletSpeed, BulletGravity, Velocity, Position, Origin)
		local MovePred = Velocity * ((Origin - Position).Magnitude / BulletSpeed)
		local Drop = CalculateDrop(BulletSpeed, BulletGravity, Position, Origin)
		return Position + Vector3.new(MovePred.X, MovePred.Y, MovePred.Z) + Vector3.new(0, Drop, 0)
	end

	local function CalculateTargetPositionNoYPred(BulletSpeed, BulletGravity, Velocity, Position, Origin)
		local MovePred = Velocity * ((Origin - Position).Magnitude / BulletSpeed)
		local Drop = CalculateDrop(BulletSpeed, BulletGravity, Position, Origin)
		return Position + Vector3.new(MovePred.X, 0, MovePred.Z) + Vector3.new(0, Drop, 0)
	end

	local function IsCheater(Player)
		if not Player or type(memory_read) ~= "function" then
			return false
		end
		local AddressSuccess, PlayerAddress = pcall(function()
			return Player.Address
		end)
		if not AddressSuccess or not IsValidAddress(PlayerAddress) then
			return false
		end

		local Success, Age = pcall(memory_read, "int", PlayerAddress + Offsets.Player.AccountAge)
		if not Success then
			warn("读取账号注册天数失败")
			return false
		end
		if type(Age) ~= "number" then
			return false
		end
		if Age <= 60 then
			return true
		end
		local Char = Player.Character
		if not Char then
			return false
		end
		local Hrp = Char:FindFirstChild("HumanoidRootPart")
		if not Hrp then
			return false
		end
		local Velocity = Hrp.Velocity
		if Velocity.Y <= -1000 or Velocity.Y >= 1000 then
			return true
		end
		return false
	end
	-- end of helper functions

	-- ui
	local function LoadUiLibrary()
		local Success, Result = pcall(function()
			local Source = game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua")
			assert(type(Source) == "string" and #Source > 0, "empty UI library response")

			local Chunk, CompileError = loadstring(Source)
			assert(type(Chunk) == "function", "UI library compilation failed: " .. tostring(CompileError))
			local LoadedLibrary = Chunk()
			return LoadedLibrary or INSui
		end)
		if Success and Result then
			return Result
		end
		warn("远程界面库加载失败: " .. tostring(Result))
		return INSui
	end

	local Lib = LoadUiLibrary()
	if not Lib then
		warn("没有可用的界面库，脚本已安全退出。")
		return
	end

	local WindowSuccess, WindowResult = pcall(function()
		return Lib:CreateWindow({
			title = "Divine.land",
			subtitle = "auto",
			size = Vector2.new(720, 540),
			menuKey = "rightshift",
			configFolder = "divineland",
			configName = "default",
			opacity = 1,
			gameInput = false,
			autoSave = true,
			startOpen = true,
		})
	end)
	if not WindowSuccess or not WindowResult then
		warn("创建界面窗口失败: " .. tostring(WindowResult))
		return
	end
	local Win = WindowResult

	local ThemeSuccess, ThemeError = pcall(function()
		Win:SetTheme({
			accentA = Color3.fromRGB(0, 217, 192),
			accentB = Color3.fromRGB(0, 168, 232),
			bg = Color3.fromRGB(6, 14, 20),
			sidebar = Color3.fromRGB(10, 22, 30),
		})
		Win:AddSettingsTab("cog")
	end)
	if not ThemeSuccess then
		warn("可选界面配置失败: " .. tostring(ThemeError))
	end

	-- 移动端没有键盘菜单键，添加可拖动的悬浮菜单按钮
	if IsMobile then
		local ButtonOk, ButtonError = pcall(function()
			local ScreenGui = Instance.new("ScreenGui")
			ScreenGui.Name = "DivineLandMobileToggle"
			ScreenGui.ResetOnSpawn = false
			ScreenGui.IgnoreGuiInset = true
			if type(gethui) == "function" then
				ScreenGui.Parent = gethui()
			else
				ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
			end

			local Button = Instance.new("TextButton")
			Button.Name = "MenuButton"
			Button.Text = "菜单"
			Button.TextSize = 16
			Button.Font = Enum.Font.SourceSansBold
			Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			Button.BackgroundColor3 = Color3.fromRGB(0, 120, 110)
			Button.BackgroundTransparency = 0.15
			Button.Size = UDim2.fromOffset(64, 44)
			Button.Position = UDim2.new(1, -76, 0.5, 40)
			Button.AutoButtonColor = true
			Button.Parent = ScreenGui

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 10)
			Corner.Parent = Button

			local Dragging = false
			local DragMoved = false
			local DragStart, StartPos

			Button.Activated:Connect(function()
				if DragMoved then
					return
				end
				pcall(function()
					Win:Toggle()
				end)
			end)

			Button.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.Touch
					or Input.UserInputType == Enum.UserInputType.MouseButton1
				then
					Dragging = true
					DragMoved = false
					DragStart = Input.Position
					StartPos = Button.Position
				end
			end)
			Button.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.Touch
					or Input.UserInputType == Enum.UserInputType.MouseButton1
				then
					Dragging = false
					task.delay(0.1, function()
						DragMoved = false
					end)
				end
			end)
			UserInputService.InputChanged:Connect(function(Input)
				if
					Dragging
					and (Input.UserInputType == Enum.UserInputType.Touch
						or Input.UserInputType == Enum.UserInputType.MouseMovement)
				then
					local Delta = Input.Position - DragStart
					if math.abs(Delta.X) > 8 or math.abs(Delta.Y) > 8 then
						DragMoved = true
					end
					Button.Position = UDim2.new(
						StartPos.X.Scale,
						StartPos.X.Offset + Delta.X,
						StartPos.Y.Scale,
						StartPos.Y.Offset + Delta.Y
					)
				end
			end)
		end)
		if not ButtonOk then
			warn("移动端悬浮菜单按钮创建失败: " .. tostring(ButtonError))
		end
	end

	-- combat
	local CombatTab = Win:Tab("战斗", "crosshair")

	local AimbotSec = CombatTab:Section("自瞄", "Left")

	local AimbotToggle = AimbotSec:Toggle("自瞄", false, function(Bool)
		Flags.Aimbot = Bool
		if not Bool then
			Flags.LockedTarget = nil
		end
	end)

	AimbotToggle:AddKeybind("MouseButton2", "Hold", function(Bool)
		Flags.AimbotActive = Bool
	end)

	if IsMobile then
		AimbotSec:Toggle("持续瞄准 (移动端)", false, function(Bool)
			Flags.AimbotActive = Bool
		end):Tooltip("移动端没有鼠标右键，开启后自瞄将一直生效。")
	end

	AimbotSec:Toggle("自动预测", false, function(Bool)
		Flags.AutoPrediction = Bool
	end):Tooltip("根据目标移动速度和手持武器自动调整弹道预测。")

	AimbotSec:Dropdown("目标部位", { "头部" }, { "头部", "躯干", "最近部位" }, false, function(v)
		Flags.AimbotTargetPart = v[1]
	end)

	AimbotSec:Slider("最大距离", 1000, 50, 50, 1500, "米", function(v)
		Flags.AimbotMaxDistance = v
	end)

	AimbotSec:Toggle("安全区检测", false, function(Bool)
		Flags.SafezoneCheck = Bool
	end)

	local FovToggle = AimbotSec:Toggle("FOV 视野检测", false, function(Bool)
		Flags.AimbotFovCheck = Bool
	end)

	FovToggle:AddColorpicker("FOV 颜色", Color3.fromRGB(255, 255, 255), function(C, A)
		Flags.FovColor = C
		Flags.FovAlpha = A
	end)

	AimbotSec:Slider("FOV 半径", 50, 1, 10, 250, "像素", function(v)
		Flags.AimbotFovRadius = v
	end)

	local SnaplineToggle = AimbotSec:Toggle("瞄准连线", false, function(Bool)
		Flags.Snapline = Bool
	end)

	SnaplineToggle:AddColorpicker("瞄准连线颜色", Color3.fromRGB(255, 255, 255), function(C, A)
		Flags.SnaplineColor = C
		Flags.SnaplineAlpha = A
	end)

	local GunModsSec = CombatTab:Section("武器修改", "Right")

	GunModsSec:Toggle("无后座", false, function(Bool)
		if Bool then
			EnableNoRecoil()
		else
			DisableNoRecoil()
		end
	end)

	GunModsSec:Toggle("延长射程", false, function(Bool)
		if Bool then
			EnableExtendRange()
		else
			DisableExtendRange()
		end
	end)

	GunModsSec:Toggle("子弹瞬发", false, function(Bool)
		if Bool then
			EnableInstantBullet()
		else
			DisableInstantBullet()
		end
	end)

	GunModsSec:Toggle("无散布", false, function(Bool)
		if Bool then
			EnableNoSpread()
		else
			DisableNoSpread()
		end
	end)

	GunModsSec:Toggle("射击速度", false, function(Bool)
		Flags.FireRate = Bool

		if Bool then
			ApplyFireRate(Flags.FireRateMult)
		else
			ApplyFireRate(1)
		end
	end)

	GunModsSec:Slider("射速倍数", 1, 0.1, 1, 1.5, "倍", function(V)
		Flags.FireRateMult = V

		if Flags.FireRate then
			ApplyFireRate(V)
		end
	end)

	GunModsSec:Toggle("无摆动", false, function(Bool)
		if Bool then
			EnableNoSway()
		else
			DisableNoSway()
		end
	end)

	GunModsSec:Toggle("子弹判定放大", false, function(Bool)
		Flags.ThickBullet = Bool
	end)

	GunModsSec:Slider("判定放大倍数", 1, 0.1, 1, 4, "倍", function(V)
		Flags.BulletThickness = V
	end)
	-- end of combat

	-- esp
	local EspTab = Win:Tab("ESP", "eye")

	local PlayerVisSec = EspTab:Section("玩家", "Left")

	PlayerVisSec:Toggle("护甲查看器", false, function(Bool)
		Flags.ArmorViewer = Bool
	end)

	local CheaterDetectorToggle = PlayerVisSec:Toggle("作弊者检测", false, function(Bool)
		Flags.CheaterDetector = Bool
	end):Tooltip("检测异常移动速度和刚注册的小号。")

	CheaterDetectorToggle:AddColorpicker("作弊者检测颜色", Color3.fromRGB(255, 13, 13), function(C, A)
		Flags.CheaterDetectorColor = C
		Flags.CheaterDetectorAlpha = A
	end)
	-- end of esp

	-- misc esp
	local LootSec = EspTab:Section("战利品", "Left")

	local ItemsToggle = LootSec:Toggle("掉落物品", false, function(Bool)
		Flags.DropsEsp = Bool
	end)

	ItemsToggle:AddColorpicker("掉落物品颜色", Color3.fromRGB(110, 149, 255), function(C, A)
		Flags.DropsColor = C
		Flags.DropsAlpha = A
	end)

	local BodybagToggle = LootSec:Toggle("尸体袋", false, function(Bool)
		Flags.BodybagEsp = Bool
	end)

	BodybagToggle:AddColorpicker("尸体袋颜色", Color3.fromRGB(255, 100, 100), function(C, A)
		Flags.BodybagColor = C
		Flags.BodybagAlpha = A
	end)

	LootSec:Slider("战利品显示距离", 500, 50, 100, 1500, "米", function(v)
		Flags.LootEspDistance = v
	end)

	local NodeSec = EspTab:Section("矿点", "Right")

	local StoneToggle = NodeSec:Toggle("石头 ESP", false, function(Bool)
		Flags.StoneEsp = Bool
	end)

	StoneToggle:AddColorpicker("石头矿点颜色", Color3.new(0.5, 0.5, 0.5), function(C, A)
		Flags.StoneColor = C
		Flags.StoneAlpha = A
	end)

	local MetalToggle = NodeSec:Toggle("金属 ESP", false, function(Bool)
		Flags.MetalEsp = Bool
	end)

	MetalToggle:AddColorpicker("金属矿点颜色", Color3.new(1, 0.6, 0.1), function(C, A)
		Flags.MetalColor = C
		Flags.MetalAlpha = A
	end)

	local PhosphateToggle = NodeSec:Toggle("磷酸盐 ESP", false, function(Bool)
		Flags.PhosphateEsp = Bool
	end)

	PhosphateToggle:AddColorpicker("磷酸盐矿点颜色", Color3.new(1, 1, 0.5), function(C, A)
		Flags.PhosphateColor = C
		Flags.PhosphateAlpha = A
	end)

	NodeSec:Slider("矿点显示距离", 500, 50, 100, 1500, "米", function(v)
		Flags.NodeEspDistance = v
	end)

	local PlantSec = EspTab:Section("植物", "Left")

	local WoolToggle = PlantSec:Toggle("羊毛 ESP", false, function(Bool)
		Flags.WoolEsp = Bool
	end)

	WoolToggle:AddColorpicker("羊毛颜色", Color3.new(0.92, 0.92, 0.92), function(C, A)
		Flags.WoolColor = C
		Flags.WoolAlpha = A
	end)

	local TomatoToggle = PlantSec:Toggle("番茄 ESP", false, function(Bool)
		Flags.TomatoEsp = Bool
	end)

	TomatoToggle:AddColorpicker("番茄颜色", Color3.new(1, 0.18, 0.18), function(C, A)
		Flags.TomatoColor = C
		Flags.TomatoAlpha = A
	end)

	local PumpkinToggle = PlantSec:Toggle("南瓜 ESP", false, function(Bool)
		Flags.PumpkinEsp = Bool
	end)

	PumpkinToggle:AddColorpicker("南瓜颜色", Color3.new(1, 0.62, 0.13), function(C, A)
		Flags.PumpkinColor = C
		Flags.PumpkinAlpha = A
	end)

	local CornToggle = PlantSec:Toggle("玉米 ESP", false, function(Bool)
		Flags.CornEsp = Bool
	end)

	CornToggle:AddColorpicker("玉米颜色", Color3.new(1, 1, 0.22), function(C, A)
		Flags.CornColor = C
		Flags.CornAlpha = A
	end)

	PlantSec:Slider("植物显示距离", 500, 50, 100, 1500, "米", function(v)
		Flags.PlantEspDistance = v
	end)

	local MiscEspSec = EspTab:Section("杂项", "Right")

	local MinicopterToggle = MiscEspSec:Toggle("迷你直升机 ESP", false, function(Bool)
		Flags.MiniEsp = Bool
	end)

	MinicopterToggle:AddColorpicker("迷你直升机颜色", Color3.fromRGB(24, 66, 255), function(C, A)
		Flags.MinicopterColor = C
		Flags.MinicopterAlpha = A
	end)

	MiscEspSec:Slider("迷你直升机显示距离", 500, 50, 100, 1500, "米", function(v)
		Flags.MiniEspDistance = v
	end)

	local RaidToggle = MiscEspSec:Toggle("突袭爆炸 ESP", false, function(Bool)
		Flags.RaidEsp = Bool
	end)

	RaidToggle:AddColorpicker("突袭爆炸颜色", Color3.fromRGB(255, 14, 14), function(C, A)
		Flags.RaidColor = C
		Flags.RaidAlpha = A
	end)

	MiscEspSec:Slider("突袭爆炸显示距离", 2000, 100, 500, 5000, "米", function(v)
		Flags.RaidEspDistance = v
	end)
	-- end of misc esp

	-- movement
	local MovementTab = Win:Tab("移动", "user")

	local MoveSec = MovementTab:Section("移动", "Left")

	MoveSec:Toggle("自动连跳 (Bunny Hop)", false, function(Bool)
		Flags.BHop = Bool
	end)
	-- end of movement

	-- misc
	local MiscTab = Win:Tab("杂项", "code")

	local ModCheckerSec = MiscTab:Section("管理员检测", "Left")

	ModCheckerSec:Toggle("管理员检测", false, function(Bool)
		Flags.ModChecker = Bool
	end)

	ModCheckerSec:Dropdown("检测行为", { "通知" }, { "通知" }, false, function(v)
		Flags.ModCheckerBehavior = v[1]
	end):Tooltip("名单内的管理员加入时向你发出通知。")
	-- end of misc
	-- end of ui

	do
		RunService.Heartbeat:Connect(function()
			local Camera = Workspace.CurrentCamera
			local LocalChar = LocalPlayer.Character

			if Flags.Aimbot and Flags.AimbotActive and Camera and LocalChar then
				if not IsLockedTargetValid(Flags.LockedTarget) then
					Flags.LockedTarget = FindClosestViableTarget()
				end

				local Target = Flags.LockedTarget
				if Target then
					local TargetPos = Target.TargetPart.Position
					local HeldWeapon = GetHeldWeapon(LocalChar)
					local Info = GetBulletInfo(HeldWeapon)
					local CameraPosition = Camera.Position

					if Info and Flags.AutoPrediction then
						if HeldWeapon == "Wooden Bow" or HeldWeapon == "Crossbow" then
							TargetPos = CalculateTargetPositionNoYPred(
								Info.Speed,
								Info.Gravity,
								Target.TargetPart.Velocity,
								TargetPos,
								CameraPosition
							)
						else
							TargetPos = CalculateTargetPosition(
								Info.Speed,
								Info.Gravity,
								Target.TargetPart.Velocity,
								TargetPos,
								CameraPosition
							)
						end
					end

					local AimSuccess = pcall(function()
						if type(Camera.lookAt) == "function" then
							Camera.lookAt(CameraPosition, TargetPos)
						else
							Camera.CFrame = CFrame.lookAt(CameraPosition, TargetPos)
						end
					end)
					if not AimSuccess then
						Flags.LockedTarget = nil
					end
				end
			else
				Flags.LockedTarget = nil
			end

			for _, Player in Players:GetPlayers() do
				if Player == LocalPlayer then
					continue
				end

				local Char = Player.Character
				if not Char then
					continue
				end

				local Head = Char:FindFirstChild("Head")
				if not Head then
					continue
				end

				local Humanoid = Char:FindFirstChild("Humanoid")
				local IsAlive = Humanoid and Humanoid.Health > 0
				local DesiredSize = HeadHitboxSize
				if Flags.ThickBullet and IsAlive then
					DesiredSize = HeadHitboxSize * Flags.BulletThickness
				end

				pcall(function()
					if Head.Size ~= DesiredSize then
						Head.Size = DesiredSize
					end
					if Flags.ThickBullet and IsAlive and type(memory_write) == "function" then
						local HeadAddress = Head.Address
						if IsValidAddress(HeadAddress) then
							memory_write("float", HeadAddress + Offsets.BasePart.Transparency, 0.99)
						end
					end
				end)
			end
		end)
	end

	if DrawingSupported then
		local FovCircle = Drawing.new("Circle")
		FovCircle.Thickness = 1
		FovCircle.NumSides = 120
		local FovCircleOutline = Drawing.new("Circle")
		FovCircleOutline.Thickness = 1
		FovCircleOutline.NumSides = 120

		local Snapline = Drawing.new("Line")
		Snapline.Thickness = 1
		local SnaplineOutline = Drawing.new("Line")
		SnaplineOutline.Thickness = 3

		RunService.RenderStepped:Connect(function()
			local MousePos = GetAimPoint()

			if Flags.AimbotFovCheck then
				FovCircleOutline.Position = MousePos
				FovCircleOutline.Radius = Flags.AimbotFovRadius + 1
				FovCircleOutline.Color = Color3.fromRGB(0, 0, 0)
				FovCircleOutline.Transparency = Flags.FovAlpha
				FovCircleOutline.Visible = true

				FovCircle.Position = MousePos
				FovCircle.Radius = Flags.AimbotFovRadius
				FovCircle.Color = Flags.FovColor
				FovCircle.Transparency = Flags.FovAlpha
				FovCircle.ZIndex = 5
				FovCircle.Visible = true
			else
				FovCircle.Visible = false
				FovCircleOutline.Visible = false
			end

			if Flags.Snapline and Flags.Aimbot and Flags.AimbotActive and IsLockedTargetValid(Flags.LockedTarget) then
				local ScreenPos, OnScreen = WorldToScreen(Flags.LockedTarget.TargetPart.Position)
				if OnScreen then
					Snapline.From = MousePos
					Snapline.To = ScreenPos
					Snapline.Color = Flags.SnaplineColor
					Snapline.Transparency = Flags.SnaplineAlpha
					Snapline.ZIndex = 5
					Snapline.Visible = true

					SnaplineOutline.From = MousePos
					SnaplineOutline.To = ScreenPos
					SnaplineOutline.Color = Color3.fromRGB(0, 0, 0)
					SnaplineOutline.Transparency = Flags.SnaplineAlpha
					SnaplineOutline.Visible = true
				else
					Snapline.Visible = false
					SnaplineOutline.Visible = false
				end
			else
				Snapline.Visible = false
				SnaplineOutline.Visible = false
			end
		end)
	end

	if DrawingSupported then
		local BoxCount = 8
		local BoxSize = 64
		local BoxSpacing = 5
		local TopMargin = 55
		local BoxRounding = 10
		local BgColor = Color3.fromRGB(71, 71, 71)
		local BgTransparency = 0.75

		local ImageCache = {}
		local ImageBaseUrl = "https://raw.githubusercontent.com/sigma4skin/matcha-fallen/main/armor_images/"

		local Cheaters = {}
		local CheaterLabels = {}

		local SlotDrawings = {}
		for i = 1, BoxCount do
			local Bg = Drawing.new("Square")
			Bg.Filled = true
			Bg.Visible = false
			Bg.Transparency = BgTransparency
			Bg.Color = BgColor
			Bg.Corner = BoxRounding
			Bg.ZIndex = 4

			local Img = Drawing.new("Image")
			Img.Visible = false
			Img.ZIndex = 5

			SlotDrawings[i] = { Bg = Bg, Img = Img, LastIcon = nil }
		end

		local function HideAllSlots()
			for i = 1, BoxCount do
				SlotDrawings[i].Bg.Visible = false
				SlotDrawings[i].Img.Visible = false
				SlotDrawings[i].LastIcon = nil
			end
		end

		local function GetOrCreateLabel(Index)
			if not CheaterLabels[Index] then
				local Label = Drawing.new("Text")
				Label.Text = "作弊者"
				Label.Color = Color3.fromRGB(255, 13, 13)
				Label.Outline = true
				Label.Font = Drawing.Fonts.UI
				Label.FontSize = 14
				Label.Center = true
				Label.Visible = false
				Label.ZIndex = 10
				CheaterLabels[Index] = Label
			end
			return CheaterLabels[Index]
		end

		local function HideAllCheaterLabels()
			for _, Label in CheaterLabels do
				Label.Visible = false
			end
		end

		local function GetImage(ArmorId)
			if not ArmorId then
				return nil
			end
			local Cached = ImageCache[ArmorId]
			if Cached ~= nil then
				return Cached or nil
			end
			ImageCache[ArmorId] = false
			local Url = ImageBaseUrl .. ArmorId .. ".png"
			task.spawn(function()
				task.wait()
				local Ok, Data = pcall(function()
					return game:HttpGet(Url)
				end)
				if not Ok or type(Data) ~= "string" or #Data == 0 then
					ImageCache[ArmorId] = false
					warn("护甲图标加载失败: ", ArmorId)
					return
				end
				ImageCache[ArmorId] = Data
			end)
			return nil
		end

		local SlotCache = {}
		local ArmorViewerTargetChar = nil

		local function RebuildSlotCache(Char)
			SlotCache = {}
			if not Char then
				return
			end
			local Seen = {}
			local Idx = 1
			for _, Child in Char:GetChildren() do
				if Idx > BoxCount then
					break
				end
				local ArmorId = Child.Name:match("^Armor_%d+")
				if ArmorId and not Seen[ArmorId] then
					Seen[ArmorId] = true
					SlotCache[Idx] = { ArmorId = ArmorId, Icon = GetImage(ArmorId) }
					Idx += 1
				end
			end
		end

		local function UpdateSlotCacheImages()
			for _, Slot in SlotCache do
				if Slot and not Slot.Icon then
					local Img = ImageCache[Slot.ArmorId]
					if Img then
						Slot.Icon = Img
					end
				end
			end
		end

		local CheaterDetectorLastUpdate = 0
		local CHEATER_DETECTOR_INTERVAL = 3
		local ArmorViewerLastUpdate = 0
		local ARMOR_VIEWER_INTERVAL = 2

		RunService.RenderStepped:Connect(function()
			local Camera = Workspace.CurrentCamera
			if not Camera then
				HideAllSlots()
				return
			end
			local Viewport = Camera.ViewportSize
			local Now = tick()

			if Flags.ArmorViewer and IsLockedTargetValid(Flags.LockedTarget) then
				local TargetChar = Flags.LockedTarget.Character
				if TargetChar ~= ArmorViewerTargetChar or Now - ArmorViewerLastUpdate >= ARMOR_VIEWER_INTERVAL then
					ArmorViewerLastUpdate = Now
					ArmorViewerTargetChar = TargetChar
					RebuildSlotCache(TargetChar)
				end
				UpdateSlotCacheImages()

				local TotalWidth = BoxCount * BoxSize + (BoxCount - 1) * BoxSpacing
				local StartX = (Viewport.X - TotalWidth) / 2
				local Y = TopMargin

				for I = 1, BoxCount do
					local Slot = SlotCache[I]
					local Draw = SlotDrawings[I]
					local X = StartX + (I - 1) * (BoxSize + BoxSpacing)
					Draw.Bg.Position = Vector2.new(X, Y)
					Draw.Bg.Size = Vector2.new(BoxSize, BoxSize)
					Draw.Bg.Visible = true

					if Slot ~= nil and Slot.Icon ~= nil then
						if Draw.LastIcon ~= Slot.Icon then
							local ImageSuccess = pcall(function()
								Draw.Img.Data = Slot.Icon
							end)
							if ImageSuccess then
								Draw.LastIcon = Slot.Icon
							else
								ImageCache[Slot.ArmorId] = false
								Slot.Icon = nil
								Draw.LastIcon = nil
							end
						end
						Draw.Img.Position = Vector2.new(X + 2, Y + 2)
						Draw.Img.Size = Vector2.new(BoxSize - 4, BoxSize - 4)
						Draw.Img.Visible = Draw.LastIcon ~= nil
					else
						Draw.Img.Visible = false
						Draw.LastIcon = nil
					end
				end
			else
				if ArmorViewerTargetChar ~= nil then
					ArmorViewerTargetChar = nil
					SlotCache = {}
				end
				HideAllSlots()
			end

			if Flags.CheaterDetector and Now - CheaterDetectorLastUpdate >= CHEATER_DETECTOR_INTERVAL then
				CheaterDetectorLastUpdate = Now
				local UpdatedCheaters = {}
				for _, Player in Players:GetPlayers() do
					if not Player or Player.Name == LocalPlayer.Name then
						continue
					end
					UpdatedCheaters[Player] = IsCheater(Player)
				end
				Cheaters = UpdatedCheaters
			end

			if Flags.CheaterDetector then
				local LabelIndex = 0
				for _, Player in Players:GetPlayers() do
					if not Player or Player.Name == LocalPlayer.Name then
						continue
					end
					if not Cheaters[Player] then
						continue
					end
					local Char = Player.Character
					if not Char then
						continue
					end
					local Head = Char:FindFirstChild("Head")
					if not Head then
						continue
					end
					local Humanoid = Char:FindFirstChild("Humanoid")
					if not Humanoid then
						continue
					end
					if Humanoid.Health <= 0 then
						continue
					end
					local ScreenPos, OnScreen = WorldToScreen(Head.Position + Vector3.new(0, 2.5, 0))
					if not OnScreen then
						continue
					end
					LabelIndex += 1
					local Label = GetOrCreateLabel(LabelIndex)
					Label.Color = Flags.CheaterDetectorColor
					Label.Transparency = Flags.CheaterDetectorAlpha
					Label.Position = Vector2.new(ScreenPos.X, ScreenPos.Y)
					Label.Visible = true
				end
				for I = LabelIndex + 1, #CheaterLabels do
					CheaterLabels[I].Visible = false
				end
			else
				HideAllCheaterLabels()
				Cheaters = {}
			end
		end)
	end

	do
		RunService.Heartbeat:Connect(function()
			if not Flags.BHop then
				return
			end
			local Char = LocalPlayer.Character
			local Humanoid = Char and Char:FindFirstChild("Humanoid")
			if
				not Humanoid
				or type(memory_read) ~= "function"
				or type(memory_write) ~= "function"
				or (not IsMobile and type(iskeypressed) ~= "function")
				or (not IsMobile and type(isrbxactive) ~= "function")
			then
				return
			end

			local AddressSuccess, HumanoidAddress = pcall(function()
				return Humanoid.Address
			end)
			if not AddressSuccess or not IsValidAddress(HumanoidAddress) then
				return
			end

			local ReadSuccess, FloorMaterial =
				pcall(memory_read, "int", HumanoidAddress + Offsets.Humanoid.FloorMaterial)
			if not ReadSuccess or FloorMaterial == nil then
				return
			end

			local InputSuccess, ShouldJump = pcall(function()
				if IsMobile then
					return FloorMaterial ~= 1792 and (tick() - MobileJumpTime) < 0.25
				end
				return FloorMaterial ~= 1792 and iskeypressed(32) and isrbxactive()
			end)
			if InputSuccess and ShouldJump then
				pcall(memory_write, "byte", HumanoidAddress + Offsets.Humanoid.Jump, 1)
			end
		end)
	end

	if DrawingSupported then
		local EspPool = {}

		local function GetOrCreateEspLabel(Index)
			if not EspPool[Index] then
				local Label = Drawing.new("Text")
				Label.Color = Color3.fromRGB(255, 255, 255)
				Label.Outline = true
				Label.Font = Drawing.Fonts.UI
				Label.FontSize = 14
				Label.Center = true
				Label.Visible = false
				Label.ZIndex = 8
				EspPool[Index] = Label
			end
			return EspPool[Index]
		end

		local function HideAllEspLabels()
			for _, Label in EspPool do
				Label.Visible = false
			end
		end

		local function GetDropEntries()
			local Entries = {}
			local Drops = workspace:FindFirstChild("Drops")
			if not Drops then
				return Entries
			end
			for _, Item in Drops:GetChildren() do
				if not Item:IsA("Model") then
					continue
				end
				local Root = Item.PrimaryPart or Item:FindFirstChildWhichIsA("BasePart")
				if not Root then
					continue
				end
				local Ok, Pos = pcall(function()
					return Root.Position
				end)
				if not Ok or not Pos then
					continue
				end
				table.insert(Entries, {
					Position = Pos,
					Text = Item.Name,
					Color = Flags.DropsColor,
					Alpha = Flags.DropsAlpha,
					MaxDistance = Flags.LootEspDistance,
				})
			end
			return Entries
		end

		local function GetBodybagEntries()
			local Entries = {}
			local Bases = Workspace:FindFirstChild("Bases")
			local Loners = Bases and Bases:FindFirstChild("Loners")
			local Bodybags = Loners and Loners:FindFirstChild("Body Bag")
			if not Bodybags then
				return Entries
			end
			for _, Bag in Bodybags:GetChildren() do
				if not Bag:IsA("Model") then
					continue
				end
				local Main = Bag:FindFirstChild("Main")
				if not Main then
					continue
				end
				table.insert(Entries, {
					Position = Main.Position + Vector3.new(0, 1, 0),
					Text = "尸体袋",
					Color = Flags.BodybagColor,
					Alpha = Flags.BodybagAlpha,
					MaxDistance = Flags.LootEspDistance,
				})
			end
			return Entries
		end

		local function GetNodeEntries()
			local Entries = {}
			local Nodes = Workspace:FindFirstChild("Nodes")
			if not Nodes then
				return Entries
			end
			for _, Node in Nodes:GetChildren() do
				if not Node:IsA("Model") then
					continue
				end
				local BasePart = Node.PrimaryPart or Node:FindFirstChildWhichIsA("BasePart")
				if not BasePart then
					continue
				end
				if Flags.StoneEsp and Node.Name == "Stone_Node" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "石头矿点",
						Color = Flags.StoneColor,
						Alpha = Flags.StoneAlpha,
						MaxDistance = Flags.NodeEspDistance,
					})
				elseif Flags.MetalEsp and Node.Name == "Metal_Node" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "金属矿点",
						Color = Flags.MetalColor,
						Alpha = Flags.MetalAlpha,
						MaxDistance = Flags.NodeEspDistance,
					})
				elseif Flags.PhosphateEsp and Node.Name == "Phosphate_Node" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "磷酸盐矿点",
						Color = Flags.PhosphateColor,
						Alpha = Flags.PhosphateAlpha,
						MaxDistance = Flags.NodeEspDistance,
					})
				end
			end
			return Entries
		end

		local function GetPlantEntries()
			local Entries = {}
			local Plants = Workspace:FindFirstChild("Plants")
			if not Plants then
				return Entries
			end
			for _, Plant in Plants:GetChildren() do
				if not Plant:IsA("Model") then
					continue
				end
				local BasePart = Plant.PrimaryPart or Plant:FindFirstChildWhichIsA("BasePart")
				if not BasePart then
					continue
				end
				if Flags.WoolEsp and Plant.Name == "Wool Plant" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "羊毛",
						Color = Flags.WoolColor,
						Alpha = Flags.WoolAlpha,
						MaxDistance = Flags.PlantEspDistance,
					})
				elseif Flags.TomatoEsp and Plant.Name == "Tomato Plant" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "番茄",
						Color = Flags.TomatoColor,
						Alpha = Flags.TomatoAlpha,
						MaxDistance = Flags.PlantEspDistance,
					})
				elseif Flags.PumpkinEsp and Plant.Name == "Pumpkin Plant" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "南瓜",
						Color = Flags.PumpkinColor,
						Alpha = Flags.PumpkinAlpha,
						MaxDistance = Flags.PlantEspDistance,
					})
				elseif Flags.CornEsp and Plant.Name == "Corn Plant" then
					table.insert(Entries, {
						Position = BasePart.Position + Vector3.new(0, 1, 0),
						Text = "玉米",
						Color = Flags.CornColor,
						Alpha = Flags.CornAlpha,
						MaxDistance = Flags.PlantEspDistance,
					})
				end
			end
			return Entries
		end

		local function GetMiniEntries()
			local Entries = {}
			local Bases = Workspace:FindFirstChild("Bases")
			local Loners = Bases and Bases:FindFirstChild("Loners")
			local Minis = Loners and Loners:FindFirstChild("Salvaged Flycopter")
			if not Minis then
				return Entries
			end
			for _, Mini in Minis:GetChildren() do
				if not Mini:IsA("Model") then
					continue
				end
				local BasePart = Mini.PrimaryPart or Mini:FindFirstChildWhichIsA("BasePart")
				if not BasePart then
					continue
				end
				table.insert(Entries, {
					Position = BasePart.Position + Vector3.new(0, 1, 0),
					Text = "迷你直升机",
					Color = Flags.MinicopterColor,
					Alpha = Flags.MinicopterAlpha,
					MaxDistance = Flags.MiniEspDistance,
				})
			end
			return Entries
		end

		local RaidCache = {}
		local RAID_EXPIRE_TIME = 30
		local RAID_SCAN_INTERVAL = 0.25
		local RaidLastScan = 0

		local function CleanRaidCache()
			local Now = tick()
			for I = #RaidCache, 1, -1 do
				if Now - RaidCache[I].Time >= RAID_EXPIRE_TIME then
					table.remove(RaidCache, I)
				end
			end
		end

		local function UpdateRaidCache()
			local Now = tick()
			if Now - RaidLastScan < RAID_SCAN_INTERVAL then
				return
			end
			RaidLastScan = Now

			local VFX = Workspace:FindFirstChild("VFX")
			if not VFX then
				return
			end
			for _, Item in VFX:GetChildren() do
				if not Item.Name:find("Explosion") then
					continue
				end
				local BasePart
				if Item:IsA("BasePart") then
					BasePart = Item
				elseif Item:IsA("Model") then
					BasePart = Item.PrimaryPart or Item:FindFirstChildWhichIsA("BasePart")
				end
				if not BasePart then
					continue
				end
				local Ok, Pos = pcall(function()
					return BasePart.Position
				end)
				if not Ok or not Pos then
					continue
				end
				local AlreadyCached = false
				for _, Cached in RaidCache do
					if Cached.Position and (Cached.Position - Pos).Magnitude < 20 then
						Cached.Time = Now
						AlreadyCached = true
						break
					end
				end
				if not AlreadyCached then
					table.insert(RaidCache, { Position = Pos, Time = Now })
				end
			end
		end

		local function GetRaidEntries()
			local Entries = {}
			CleanRaidCache()
			UpdateRaidCache()
			local Now = tick()
			for _, Cached in RaidCache do
				local TimeLeft = math.ceil(RAID_EXPIRE_TIME - (Now - Cached.Time))
				table.insert(Entries, {
					Position = Cached.Position + Vector3.new(0, 1, 0),
					Text = "突袭爆炸 (" .. TimeLeft .. "秒)",
					Color = Flags.RaidColor,
					Alpha = Flags.RaidAlpha,
					MaxDistance = Flags.RaidEspDistance,
				})
			end
			return Entries
		end

		local EspCache = {}
		local EspCacheLastUpdate = 0
		local ESP_CACHE_INTERVAL = 2
		local EspDrawLastUpdate = 0
		local ESP_DRAW_INTERVAL = 0.015

		local function RebuildEspCache()
			local NewCache = {}
			if Flags.DropsEsp then
				for _, E in GetDropEntries() do
					table.insert(NewCache, E)
				end
			end
			if Flags.BodybagEsp then
				for _, E in GetBodybagEntries() do
					table.insert(NewCache, E)
				end
			end
			if Flags.StoneEsp or Flags.MetalEsp or Flags.PhosphateEsp then
				for _, E in GetNodeEntries() do
					table.insert(NewCache, E)
				end
			end
			if Flags.WoolEsp or Flags.TomatoEsp or Flags.PumpkinEsp or Flags.CornEsp then
				for _, E in GetPlantEntries() do
					table.insert(NewCache, E)
				end
			end
			if Flags.MiniEsp then
				for _, E in GetMiniEntries() do
					table.insert(NewCache, E)
				end
			end
			EspCache = NewCache
		end

		RunService.RenderStepped:Connect(function()
			local Now = tick()
			local Char = LocalPlayer.Character
			local Root = Char and Char:FindFirstChild("HumanoidRootPart")

			local AnyEnabled = Flags.DropsEsp
				or Flags.BodybagEsp
				or Flags.StoneEsp
				or Flags.MetalEsp
				or Flags.PhosphateEsp
				or Flags.MiniEsp
				or Flags.WoolEsp
				or Flags.TomatoEsp
				or Flags.PumpkinEsp
				or Flags.CornEsp
				or Flags.RaidEsp

			if not AnyEnabled then
				HideAllEspLabels()
				EspCache = {}
				return
			end
			if not Root then
				HideAllEspLabels()
				return
			end

			if Now - EspCacheLastUpdate >= ESP_CACHE_INTERVAL then
				EspCacheLastUpdate = Now
				local Success, Error = pcall(RebuildEspCache)
				if not Success then
					warn("ESP 缓存重建失败: " .. tostring(Error))
				end
			end

			if Now - EspDrawLastUpdate < ESP_DRAW_INTERVAL then
				return
			end
			EspDrawLastUpdate = Now

			local AllEntries = {}
			for _, E in EspCache do
				table.insert(AllEntries, E)
			end
			if Flags.RaidEsp then
				for _, E in GetRaidEntries() do
					table.insert(AllEntries, E)
				end
			end

			local LabelIndex = 0
			for _, Entry in AllEntries do
				local Dist = (Root.Position - Entry.Position).Magnitude
				if Dist > Entry.MaxDistance then
					continue
				end
				local ScreenPos, OnScreen = WorldToScreen(Entry.Position)
				if not OnScreen then
					continue
				end
				LabelIndex += 1
				local Label = GetOrCreateEspLabel(LabelIndex)
				Label.Text = Entry.Text .. " (" .. math.floor(Dist) .. "米)"
				Label.Color = Entry.Color
				Label.Transparency = Entry.Alpha
				Label.Position = Vector2.new(ScreenPos.X, ScreenPos.Y)
				Label.Visible = true
			end

			for I = LabelIndex + 1, #EspPool do
				if EspPool[I] then
					EspPool[I].Visible = false
				end
			end
		end)
	end

	do
		local ModCheckerLastCheck = 0
		local MOD_CHECKER_INTERVAL = 3
		local SeenMods = {}

		RunService.Heartbeat:Connect(function()
			local Now = tick()
			if Flags.ModChecker then
				if Now - ModCheckerLastCheck >= MOD_CHECKER_INTERVAL then
					ModCheckerLastCheck = Now
					for _, Player in Players:GetPlayers() do
						if not Player or Player.Name == LocalPlayer.Name then
							continue
						end
						local AddressSuccess, PlayerAddress = pcall(function()
							return Player.Address
						end)
						if not AddressSuccess or not IsValidAddress(PlayerAddress) then
							continue
						end

						local Success, UserId =
							pcall(memory_read, "uintptr_t", PlayerAddress + Offsets.Player.UserId)
						if not Success then
							warn("管理员检测: 读取用户 ID 失败。")
						end
						if not ModeratorIDs[UserId] or SeenMods[UserId] then
							continue
						end
						if Flags.ModCheckerBehavior == "通知" then
							SeenMods[UserId] = true
							if type(notify) == "function" then
								pcall(
									notify,
									ModeratorIDs[UserId] .. " (" .. Player.Name .. ") 已加入你的对局！",
									"管理员警告",
									5
								)
							end
						end
					end
				end
			end
		end)
	end