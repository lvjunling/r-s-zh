-- ============================================================
-- POTENT HUB - 中文免秘钥版
-- ============================================================

local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local httpService = game:GetService("HttpService")
local teleportService = game:GetService("TeleportService")
local stats = game:GetService("Stats")
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")

-- ========== 运行配置 ==========
local TARGET_PLACE_ID = 142823291
local CONFIG_FILE = "potent_hub_config.json"

-- ============================================================
-- ========== 主脚本 ==========

-- ============================================================

local function runMainScript()
	if game.PlaceId ~= TARGET_PLACE_ID then
		game.StarterGui:SetCore("SendNotification", {
			Title = "POTENT HUB",
			Text = "请进入《Murder Mystery 2》后运行！",
			Duration = 5
		})
		return
	end

	local function loadConfig()
		if not isfile or not readfile or not isfile(CONFIG_FILE) then
			return {}
		end
		local ok, data = pcall(function()
			return httpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok and type(data) == "table" then
			local defaults = {
				espAll = false, espGun = false,
				killAura = false, killAuraRange = 15,
				autoShoot = false, autoGrabGun = false,
				autoKnifeThrow = false,
				notifyMurderer = false, notifySheriff = false,
				gunSilentAim = false,
				hitboxExpand = false, hitboxSize = 4, hitboxVisible = false,
				instantRole = false,
				antiSilentAim = false,
				autoFarmCoins = false,
				godmode = false,
				speedEnabled = false, speedValue = 20,
				jumpEnabled = false, jumpValue = 50,
				noclipEnabled = false,
			}
			for key, default in pairs(defaults) do
				if data[key] == nil then data[key] = default end
			end
			return data
		end
		return {}
	end

	local function saveConfig(tbl)
		if not writefile then return end
		pcall(function()
			writefile(CONFIG_FILE, httpService:JSONEncode(tbl))
		end)
	end

	local savedConfig = loadConfig()

	local localPlayer = playersService.LocalPlayer
	local flags = {
		espAll = savedConfig.espAll == true,
		espGun = savedConfig.espGun == true,
		killAura = savedConfig.killAura == true,
		killAuraRange = savedConfig.killAuraRange or 15,
		autoShoot = savedConfig.autoShoot == true,
		autoGrabGun = savedConfig.autoGrabGun == true,
		autoKnifeThrow = savedConfig.autoKnifeThrow == true,
		notifyMurderer = savedConfig.notifyMurderer == true,
		notifySheriff = savedConfig.notifySheriff == true,
		gunSilentAim = savedConfig.gunSilentAim == true,
		hitboxExpand = savedConfig.hitboxExpand == true,
		hitboxSize = savedConfig.hitboxSize or 4,
		hitboxVisible = savedConfig.hitboxVisible == true,
		instantRole = savedConfig.instantRole == true,
		antiSilentAim = savedConfig.antiSilentAim == true,
		autoFarmCoins = savedConfig.autoFarmCoins == true,
		godmode = savedConfig.godmode == true,
		speedEnabled = savedConfig.speedEnabled == true,
		speedValue = savedConfig.speedValue or 20,
		jumpEnabled = savedConfig.jumpEnabled == true,
		jumpValue = savedConfig.jumpValue or 50,
		noclipEnabled = savedConfig.noclipEnabled == true,
	}

	local function saveAll()
		saveConfig({
			espAll = flags.espAll, espGun = flags.espGun,
			killAura = flags.killAura, killAuraRange = flags.killAuraRange,
			autoShoot = flags.autoShoot, autoGrabGun = flags.autoGrabGun,
			autoKnifeThrow = flags.autoKnifeThrow,
			notifyMurderer = flags.notifyMurderer, notifySheriff = flags.notifySheriff,
			gunSilentAim = flags.gunSilentAim,
			hitboxExpand = flags.hitboxExpand, hitboxSize = flags.hitboxSize,
			hitboxVisible = flags.hitboxVisible,
			instantRole = flags.instantRole,
			antiSilentAim = flags.antiSilentAim,
			autoFarmCoins = flags.autoFarmCoins,
			godmode = flags.godmode,
			speedEnabled = flags.speedEnabled, speedValue = flags.speedValue,
			jumpEnabled = flags.jumpEnabled, jumpValue = flags.jumpValue,
			noclipEnabled = flags.noclipEnabled,
		})
	end

	local highlights = {}
	local tagCache = {}
	local gunEsp = {}
	local roleCache = {}
	local afkTime = os.time()

	local notifiedMurderer = false
	local notifiedSheriff = false
	local lastMyRole = "FORCE_RESET"

	local autoFarmRunning = false
	local autoFarmThread = nil

	local antiSilentData = { savedCFrame = nil, savedVelocity = nil }
	local hitboxOriginal = {}
	local godmodeConnection = nil

	local virtualUser = game:GetService("VirtualUser")
	localPlayer.Idled:Connect(function()
		virtualUser:CaptureController()
		virtualUser:ClickButton2(Vector2.new())
	end)

	local function createAfkTag(character)
		local head = character:FindFirstChild("Head")
		if not head or head:FindFirstChild("AFK_Tag") then return end
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "AFK_Tag"
		billboard.Size = UDim2.new(0, 170, 0, 28)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "POTENT ANTI-AFK [00:00:00]"
		label.TextColor3 = Color3.fromRGB(138, 43, 226)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 12
		label.TextStrokeTransparency = 0.2
		label.Parent = billboard
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.4
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Parent = label
		task.spawn(function()
			while billboard and billboard.Parent do
				local elapsed = os.time() - afkTime
				local hours = math.floor(elapsed / 3600)
				local minutes = math.floor(elapsed % 3600 / 60)
				local seconds = elapsed % 60
				label.Text = string.format("POTENT ANTI-AFK [%02d:%02d:%02d]", hours, minutes, seconds)
				task.wait(1)
			end
		end)
	end

	if localPlayer.Character then createAfkTag(localPlayer.Character) end
	localPlayer.CharacterAdded:Connect(createAfkTag)

	local function getRoot(player)
		local char = player and player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getHumanoid(player)
		local char = player and player.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	local function hasTool(player, search)
		local char = player.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("Tool") and string.find(string.lower(v.Name), search) then
					return true
				end
			end
		end
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			for _, v in ipairs(backpack:GetChildren()) do
				if v:IsA("Tool") and string.find(string.lower(v.Name), search) then
					return true
				end
			end
		end
		return false
	end

	local function getPlayerRole(player)
		if not player.Character then return nil end
		if hasTool(player, "knife") or hasTool(player, "cuchillo") then
			return "Murderer"
		elseif hasTool(player, "gun") or hasTool(player, "revolver") or hasTool(player, "pistola") then
			return "Sheriff"
		end
		return "Innocent"
	end

	local function findMurderer()
		for _, plr in ipairs(playersService:GetPlayers()) do
			if plr ~= localPlayer then
				local bp = plr:FindFirstChild("Backpack")
				if bp and bp:FindFirstChild("Knife") then
					return plr
				end
				if plr.Character and plr.Character:FindFirstChild("Knife") then
					return plr
				end
			end
		end
		return nil
	end

	local function findSheriff()
		for _, plr in ipairs(playersService:GetPlayers()) do
			if plr ~= localPlayer then
				local bp = plr:FindFirstChild("Backpack")
				if bp and bp:FindFirstChild("Gun") then
					return plr
				end
				if plr.Character and plr.Character:FindFirstChild("Gun") then
					return plr
				end
			end
		end
		return nil
	end

	local function findMap()
		for _, o in ipairs(workspace:GetChildren()) do
			if o:FindFirstChild("CoinContainer") and o:FindFirstChild("Spawns") then
				return o
			end
		end
		return nil
	end

	local function removeHighlight(player)
		if highlights[player] then
			pcall(highlights[player].Destroy, highlights[player])
			highlights[player] = nil
		end
	end

	local function removeTag(player)
		if tagCache[player] then
			pcall(tagCache[player].Destroy, tagCache[player])
			tagCache[player] = nil
		end
	end

	local function createRoleTag(player, role)
		local char = player.Character
		if not char then return end
		local head = char:FindFirstChild("Head")
		if not head then return end
		removeTag(player)
		if role ~= "Murderer" and role ~= "Sheriff" then return end
		local colors = { Murderer = Color3.fromRGB(255, 0, 0), Sheriff = Color3.fromRGB(0, 100, 255) }
		local emojis = { Murderer = "🔪", Sheriff = "🔫" }
		local color = colors[role]
		local emoji = emojis[role]
		local roleText = ({Murderer = "杀手", Sheriff = "警长"})[role] or role
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "POTENT_ROLE_TAG"
		billboard.Size = UDim2.new(0, 180, 0, 35)
		billboard.StudsOffset = Vector3.new(0, 2.8, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 150
		billboard.Parent = head
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		bg.BackgroundTransparency = 0.6
		bg.BorderSizePixel = 0
		bg.Parent = billboard
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = bg
		local border = Instance.new("Frame")
		border.Size = UDim2.new(1, 0, 0, 3)
		border.BackgroundColor3 = color
		border.BorderSizePixel = 0
		border.Parent = bg
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.Position = UDim2.new(0, 0, 0, 2)
		text.BackgroundTransparency = 1
		text.Text = emoji .. " " .. roleText
		text.TextColor3 = color
		text.TextScaled = true
		text.Font = Enum.Font.GothamBold
		text.TextStrokeTransparency = 0.3
		text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		text.Parent = bg
		tagCache[player] = billboard
	end

	local function updateESP()
		for player, _ in pairs(highlights) do
			if not player or not player.Parent then
				removeHighlight(player)
				removeTag(player)
			end
		end
		if not flags.espAll then
			for player, _ in pairs(highlights) do
				removeHighlight(player)
				removeTag(player)
			end
			return
		end
		for _, player in ipairs(playersService:GetPlayers()) do
			if player == localPlayer then
				removeHighlight(player)
				removeTag(player)
				continue
			end
			local role = getPlayerRole(player)
			if role == "Murderer" then
				local hl = highlights[player] or Instance.new("Highlight")
				hl.Name = "POTENT_ESP"
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.FillTransparency = 0.4
				hl.OutlineTransparency = 0
				hl.FillColor = Color3.fromRGB(255, 0, 0)
				hl.OutlineColor = Color3.fromRGB(255, 0, 0)
				hl.Adornee = player.Character
				hl.Parent = player.Character
				hl.Enabled = true
				highlights[player] = hl
				createRoleTag(player, "Murderer")
			elseif role == "Sheriff" then
				local hl = highlights[player] or Instance.new("Highlight")
				hl.Name = "POTENT_ESP"
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.FillTransparency = 0.4
				hl.OutlineTransparency = 0
				hl.FillColor = Color3.fromRGB(0, 100, 255)
				hl.OutlineColor = Color3.fromRGB(0, 100, 255)
				hl.Adornee = player.Character
				hl.Parent = player.Character
				hl.Enabled = true
				highlights[player] = hl
				createRoleTag(player, "Sheriff")
			elseif role == "Innocent" then
				local hl = highlights[player] or Instance.new("Highlight")
				hl.Name = "POTENT_ESP"
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.FillTransparency = 0.4
				hl.OutlineTransparency = 0
				hl.FillColor = Color3.fromRGB(0, 255, 0)
				hl.OutlineColor = Color3.fromRGB(0, 255, 0)
				hl.Adornee = player.Character
				hl.Parent = player.Character
				hl.Enabled = true
				highlights[player] = hl
				removeTag(player)
			else
				removeHighlight(player)
				removeTag(player)
			end
		end
	end

	local function addGunESP(gun)
		if not gun or not gun:IsA("BasePart") then return end
		if gun:FindFirstChild("POTENT_GunHighlight") then gun.POTENT_GunHighlight:Destroy() end
		if gun:FindFirstChild("POTENT_GunLabel") then gun.POTENT_GunLabel:Destroy() end

		local hl = Instance.new("Highlight")
		hl.Name = "POTENT_GunHighlight"
		hl.Adornee = gun
		hl.FillColor = Color3.fromRGB(0, 255, 255)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = gun

		local bg = Instance.new("BillboardGui")
		bg.Name = "POTENT_GunLabel"
		bg.Adornee = gun
		bg.Size = UDim2.new(0, 150, 0, 50)
		bg.StudsOffset = Vector3.new(0, 2, 0)
		bg.AlwaysOnTop = true

		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.new(1, 0, 1, 0)
		text.TextSize = 14
		text.Font = Enum.Font.GothamBold
		text.Text = "🔫 DROPPED GUN"
		text.TextColor3 = Color3.fromRGB(0, 255, 255)
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.new(0,0,0)
		text.Parent = bg

		bg.Parent = gun
	end

	local function updateGunESP()
		for obj, hl in pairs(gunEsp) do
			if not obj or not obj.Parent then
				pcall(hl.Destroy, hl)
				gunEsp[obj] = nil
			end
		end
		if not flags.espGun then
			for obj, hl in pairs(gunEsp) do
				pcall(hl.Destroy, hl)
				gunEsp[obj] = nil
			end
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj.Name == "POTENT_GunHighlight" or obj.Name == "POTENT_GunLabel" then
					obj:Destroy()
				end
			end
			return
		end
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc.Name == "GunDrop" and desc:IsA("BasePart") then
				if not gunEsp[desc] then
					addGunESP(desc)
					gunEsp[desc] = true
				end
			end
		end
	end

	task.spawn(function()
		while true do
			pcall(updateESP)
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			pcall(updateGunESP)
			task.wait(0.3)
		end
	end)

	task.spawn(function()
		while true do
			if flags.notifyMurderer or flags.notifySheriff then
				local murderer = findMurderer()
				local sheriff = findSheriff()

				if flags.notifyMurderer and murderer and not notifiedMurderer then
					notifiedMurderer = true
					game.StarterGui:SetCore("SendNotification", {
						Title = "🔪 发现杀手！",
						Text = murderer.Name,
						Duration = 5
					})
				end

				if flags.notifySheriff and sheriff and not notifiedSheriff then
					notifiedSheriff = true
					game.StarterGui:SetCore("SendNotification", {
						Title = "🔫 发现警长！",
						Text = sheriff.Name,
						Duration = 5
					})
				end

				if not murderer then notifiedMurderer = false end
				if not sheriff then notifiedSheriff = false end
			end
			task.wait(1)
		end
	end)

	task.spawn(function()
		while true do
			if flags.instantRole then
				local char = localPlayer.Character
				if char then
					local role = getPlayerRole(localPlayer)
					if role and role ~= lastMyRole and role ~= "Innocent" then
						lastMyRole = role
						local emoji = role == "Murderer" and "🔪" or "🔫"

						game.StarterGui:SetCore("SendNotification", {
							Title = emoji .. " 你的身份是：" .. (({Murderer = "杀手", Sheriff = "警长", Innocent = "平民"})[role] or role),
							Text = "回合即将开始……",
							Duration = 4
						})
					end
				end
			end
			task.wait(0.5)
		end
	end)

	local function applyGodmode(state)
		if godmodeConnection then
			pcall(godmodeConnection.Disconnect, godmodeConnection)
			godmodeConnection = nil
		end

		if state then
			local function setupGodmode(character)
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					godmodeConnection = humanoid.HealthChanged:Connect(function(newHealth)
						if flags.godmode and newHealth < humanoid.MaxHealth then
							humanoid.Health = humanoid.MaxHealth
						end
					end)
				end
			end

			if localPlayer.Character then
				setupGodmode(localPlayer.Character)
			end
		end
	end

	local function coinsReach(state)
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
				if not hitboxOriginal[obj] then
					hitboxOriginal[obj] = obj.Size
				end
				if state then
					obj.Size = hitboxOriginal[obj] * 4
				else
					obj.Size = hitboxOriginal[obj]
				end
			end
		end
	end

	local function findCoinContainer()
		local map = findMap()
		if map then
			return map:FindFirstChild("CoinContainer") or map:FindFirstChild("Coins") or map:FindFirstChild("coinContainer")
		end
		return nil
	end

	local function getNearestCoin()
		local container = findCoinContainer()
		if not container then return nil end
		local root = getRoot(localPlayer)
		if not root then return nil end
		local nearest, nearestDist = nil, math.huge
		for _, coin in ipairs(container:GetChildren()) do
			if coin:IsA("BasePart") then
				local visual = coin:FindFirstChild("CoinVisual")
				if visual and not visual:GetAttribute("Collected") then
					local dist = (root.Position - coin.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = coin
					end
				end
			end
		end
		return nearest
	end

	local function autoFarmLoop()
		while flags.autoFarmCoins and autoFarmRunning do
			local root = getRoot(localPlayer)
			local humanoid = getHumanoid(localPlayer)
			if not root or not humanoid then
				task.wait(0.5)
				continue
			end
			if humanoid.Health <= 0 then
				autoFarmRunning = false
				break
			end

			local coin = getNearestCoin()
			if coin then
				local dist = (root.Position - coin.Position).Magnitude
				local duration = dist / 30
				if duration > 0.05 then
					humanoid:ChangeState(Enum.HumanoidStateType.Physics)
					local tween = tweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = coin.CFrame})
					tween:Play()
					tween.Completed:Wait()
				else
					root.CFrame = coin.CFrame
				end
				task.wait(0.1)
			else
				task.wait(0.5)
			end
		end
	end

	local function startAutoFarm()
		if autoFarmRunning then return end
		autoFarmRunning = true
		autoFarmThread = task.spawn(autoFarmLoop)
	end

	local function stopAutoFarm()
		autoFarmRunning = false
		if autoFarmThread then
			task.cancel(autoFarmThread)
			autoFarmThread = nil
		end
	end

	local function getPredictedPosition(target)
		if not target or not target.Character then return Vector3.new(0,0,0) end
		local hrp = target.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return Vector3.new(0,0,0) end
		local vel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.new(0,0,0)
		local ping = 0
		pcall(function()
			if localPlayer and typeof(localPlayer.GetNetworkPing) == "function" then
				ping = localPlayer:GetNetworkPing() or 0
			end
		end)
		if type(ping) ~= "number" then ping = 0 end
		if ping > 1 then ping = ping / 1000 end
		return hrp.Position + vel * (0.028 + ping)
	end

	local function gunSilentAim()
		local char = localPlayer.Character
		if not char then return end

		local target = findMurderer()
		if not target or not target.Character then return end

		local mHRP = target.Character:FindFirstChild("HumanoidRootPart")
		local lHRP = char:FindFirstChild("HumanoidRootPart")
		if not mHRP or not lHRP then return end

		if not char:FindFirstChild("Gun") then
			local backpack = localPlayer:FindFirstChild("Backpack")
			if backpack then
				local gun = backpack:FindFirstChild("Gun")
				if gun then
					local humanoid = getHumanoid(localPlayer)
					if humanoid then
						pcall(function() humanoid:EquipTool(gun) end)
						task.wait(0.1)
					end
				end
			end
		end

		local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
		if not gun then return end

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { char, target.Character }
		local direction = mHRP.Position - lHRP.Position
		local ok, res = pcall(function()
			return workspace:Raycast(lHRP.Position, direction, rayParams)
		end)
		if ok and res and not res.Instance:IsDescendantOf(target.Character) then
			return
		end

		local predPos = getPredictedPosition(target)

		local args = {
			CFrame.new(lHRP.Position, predPos),
			CFrame.new(predPos)
		}

		if gun:FindFirstChild("Shoot") then
			pcall(function()
				gun.Shoot:FireServer(unpack(args))
			end)
		end
	end

	-- ========== AUTO GRAB GUN (CORREGIDO) ==========
	local function grabGun()
		local root = getRoot(localPlayer)
		if not root then return end
		local map = findMap()
		if not map then return end

		local gunDrop = map:FindFirstChild("GunDrop")
		if not gunDrop or not gunDrop:IsA("BasePart") then return end

		-- Teletransportar encima del arma para activar el touch
		root.CFrame = gunDrop.CFrame + Vector3.new(0, 2, 0)

		task.wait(0.1)

		-- Intentar recoger también con firetouchinterest
		if firetouchinterest then
			pcall(function()
				firetouchinterest(gunDrop, root, 1)
				firetouchinterest(gunDrop, root, 0)
			end)
		end
	end

	local function executeThrowAtNearest()
		local char = localPlayer.Character
		local humanoid = getHumanoid(localPlayer)
		if not char or not humanoid then return end

		local knife = char:FindFirstChild("Knife")
		if not knife then
			local backpack = localPlayer:FindFirstChild("Backpack")
			if backpack and backpack:FindFirstChild("Knife") then
				humanoid:EquipTool(backpack.Knife)
				task.wait(0.1)
				knife = char:FindFirstChild("Knife")
			end
		end

		if not knife or not knife:FindFirstChild("Throw") then return end

		local myRoot = getRoot(localPlayer)
		if not myRoot then return end
		local myPos = myRoot.Position

		local target, dist = nil, 1000
		for _, v in ipairs(playersService:GetPlayers()) do
			if v ~= localPlayer then
				local enemyRoot = getRoot(v)
				if enemyRoot then
					local h = getHumanoid(v)
					if h and h.Health > 0 then
						local mag = (myPos - enemyRoot.Position).Magnitude
						if mag < dist then
							dist = mag
							target = enemyRoot
						end
					end
				end
			end
		end

		if target then
			local prediction = target.Position + (target.AssemblyLinearVelocity * 0.05 * (dist / 100))
			local throwCFrame = CFrame.new(myPos, prediction)
			knife.Throw:FireServer(throwCFrame, prediction)
		end
	end

	local function killAll()
		local char = localPlayer.Character
		local humanoid = getHumanoid(localPlayer)
		if not char or not humanoid then return end
		local knife = char:FindFirstChild("Knife")
		if not knife then
			local backpack = localPlayer:FindFirstChild("Backpack")
			if backpack and backpack:FindFirstChild("Knife") then
				humanoid:EquipTool(backpack.Knife)
				task.wait(0.1)
				knife = char:FindFirstChild("Knife")
			end
		end
		if not knife or not knife:IsA("Tool") then return end
		local handle = knife:FindFirstChild("Handle")
		local stab = knife:FindFirstChild("Stab")
		if not handle then return end
		for _, v in ipairs(playersService:GetPlayers()) do
			if v ~= localPlayer then
				local enemyRoot = getRoot(v)
				if enemyRoot then
					pcall(function()
						firetouchinterest(handle, enemyRoot, 1)
						firetouchinterest(handle, enemyRoot, 0)
						if stab and typeof(stab.FireServer) == "function" then
							stab:FireServer(enemyRoot.Position)
						end
					end)
					task.wait(0.1)
				end
			end
		end
	end

	local function killAura()
		local root = getRoot(localPlayer)
		local char = localPlayer.Character
		if not root or not char then return end
		local knife = char:FindFirstChild("Knife")
		if not knife then
			local backpack = localPlayer:FindFirstChild("Backpack")
			if backpack and backpack:FindFirstChild("Knife") then
				local humanoid = getHumanoid(localPlayer)
				if humanoid then
					humanoid:EquipTool(backpack.Knife)
					task.wait(0.1)
					knife = char:FindFirstChild("Knife")
				end
			end
		end
		if not knife or not knife:IsA("Tool") then return end
		local handle = knife:FindFirstChild("Handle")
		if not handle then return end
		local range = flags.killAuraRange or 15
		for _, player in ipairs(playersService:GetPlayers()) do
			if player ~= localPlayer then
				local targetRoot = getRoot(player)
				if targetRoot and (root.Position - targetRoot.Position).Magnitude <= range then
					pcall(function()
						knife:Activate()
						if firetouchinterest then
							firetouchinterest(handle, targetRoot, 1)
							firetouchinterest(targetRoot, handle, 0)
						end
					end)
				end
			end
		end
	end

	local function applyHitbox()
		for _, plr in ipairs(playersService:GetPlayers()) do
			if plr ~= localPlayer and plr.Character then
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if root then
					if flags.hitboxExpand then
						root.Size = Vector3.new(flags.hitboxSize, flags.hitboxSize, flags.hitboxSize)
						root.Transparency = flags.hitboxVisible and 0.5 or 1
						root.CanCollide = false
					else
						root.Size = Vector3.new(2, 2, 1)
						root.Transparency = 1
						root.CanCollide = false
					end
				end
			end
		end
	end

	task.spawn(function()
		while true do
			if flags.hitboxExpand then
				pcall(applyHitbox)
			end
			task.wait(0.1)
		end
	end)

	local oldIndex = nil
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if flags.antiSilentAim and not checkcaller() then
			if key == "CFrame" and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local hum = getHumanoid(localPlayer)
				if hum and hum.Health > 0 then
					if self == localPlayer.Character.HumanoidRootPart then
						return antiSilentData.savedCFrame or CFrame.new()
					elseif self == localPlayer.Character.Head then
						local root = localPlayer.Character.HumanoidRootPart
						if root and antiSilentData.savedCFrame then
							return antiSilentData.savedCFrame + Vector3.new(0, root.Size.Y/2 + 0.5, 0)
						end
					end
				end
			end
		end
		return oldIndex(self, key)
	end))

	task.spawn(function()
		while true do
			if flags.antiSilentAim then
				local char = localPlayer.Character
				if char then
					local root = char:FindFirstChild("HumanoidRootPart")
					local hum = getHumanoid(localPlayer)
					if root and hum and hum.Health > 0 then
						antiSilentData.savedCFrame = root.CFrame
						antiSilentData.savedVelocity = root.AssemblyLinearVelocity
					end
				end
			else
				antiSilentData.savedCFrame = nil
				antiSilentData.savedVelocity = nil
			end
			task.wait(0.1)
		end
	end)

	local function applyMovement()
		local humanoid = getHumanoid(localPlayer)
		if not humanoid then return end
		pcall(function()
			if flags.speedEnabled then
				humanoid.WalkSpeed = math.max(16, math.min(50, flags.speedValue))
			else
				humanoid.WalkSpeed = 16
			end
		end)
		pcall(function()
			if flags.jumpEnabled then
				humanoid.JumpPower = math.max(50, math.min(120, flags.jumpValue))
			else
				humanoid.JumpPower = 50
			end
		end)
	end

	local noclipConnection
	local function toggleNoclip(state)
		if noclipConnection then
			pcall(noclipConnection.Disconnect, noclipConnection)
			noclipConnection = nil
		end
		if state then
			noclipConnection = runService.Stepped:Connect(function()
				local char = localPlayer.Character
				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end
			end)
		else
			local char = localPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end
	end

	task.spawn(function()
		while true do
			if flags.killAura then pcall(killAura) end
			if flags.autoShoot then pcall(gunSilentAim) end
			if flags.autoKnifeThrow then
				local isMurderer = getPlayerRole(localPlayer) == "Murderer"
				if isMurderer then
					pcall(executeThrowAtNearest)
				end
			end
			pcall(applyMovement)
			task.wait(0.1)
		end
	end)

	-- Auto Grab Gun loop (corregido)
	task.spawn(function()
		while true do
			if flags.autoGrabGun then
				local root = getRoot(localPlayer)
				local map = findMap()
				if root and map then
					local gunDrop = map:FindFirstChild("GunDrop")
					if gunDrop and gunDrop:IsA("BasePart") then
						local dist = (root.Position - gunDrop.Position).Magnitude
						if dist <= 20 then
							root.CFrame = gunDrop.CFrame + Vector3.new(0, 2, 0)
							task.wait(0.1)
							if firetouchinterest then
								pcall(function()
									firetouchinterest(gunDrop, root, 1)
									firetouchinterest(gunDrop, root, 0)
								end)
							end
						end
					end
				end
			end
			task.wait(0.2)
		end
	end)

	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		if flags.noclipEnabled then toggleNoclip(true) end
		if flags.godmode then applyGodmode(true) end
		notifiedMurderer = false
		notifiedSheriff = false
		lastMyRole = "FORCE_RESET"
	end)

	playersService.PlayerRemoving:Connect(function(player)
		removeHighlight(player)
		removeTag(player)
	end)

	playersService.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.3)
			if flags.espAll then updateESP() end
		end)
	end)

	local success, WindUI = pcall(function()
		return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
	end)
	if not success or not WindUI then
		warn("WindUI 加载失败")
		return
	end

	local window = WindUI.CreateWindow(WindUI, {
		Title = "⚡ POTENT HUB",
		Author = "👑 作者：POTENT HUB",
		Folder = "POTENTHUB_MM2",
		Size = userInputService.TouchEnabled and UDim2.fromOffset(470, 420) or UDim2.fromOffset(580, 520),
		Transparent = true,
		Theme = "Dark"
	})

	local visualsTab = window:Tab({ Title = "👁️ 视觉", Icon = "eye" })
	local farmTab = window:Tab({ Title = "🪙 自动收集", Icon = "coins" })
	local combatTab = window:Tab({ Title = "⚔️ 战斗", Icon = "swords" })
	local teleportTab = window:Tab({ Title = "🌀 传送", Icon = "map-pin" })
	local playerTab = window:Tab({ Title = "👤 玩家", Icon = "user" })
	local creditsTab = window:Tab({ Title = "📜 关于", Icon = "info" })

	visualsTab:Section({ Title = "🎯 ESP" })
	visualsTab:Toggle({
		Title = "⚡ 全员透视",
		Desc = "🔴 杀手 | 🔵 警长 | 🟢 平民",
		Value = flags.espAll,
		Callback = function(state)
			flags.espAll = state
			saveAll()
			if not state then
				for player, _ in pairs(highlights) do
					removeHighlight(player)
					removeTag(player)
				end
			end
		end
	})
	visualsTab:Toggle({
		Title = "🔫 掉落手枪透视",
		Desc = "高亮地图中掉落的手枪",
		Value = flags.espGun,
		Callback = function(state)
			flags.espGun = state
			saveAll()
			if not state then
				for obj, hl in pairs(gunEsp) do
					pcall(hl.Destroy, hl)
					gunEsp[obj] = nil
				end
			end
		end
	})

	visualsTab:Section({ Title = "🔔 通知" })
	visualsTab:Toggle({
		Title = "🔪 杀手出现通知",
		Desc = "杀手出现时发送通知",
		Value = flags.notifyMurderer,
		Callback = function(state)
			flags.notifyMurderer = state
			notifiedMurderer = false
			saveAll()
		end
	})
	visualsTab:Toggle({
		Title = "🔫 警长出现通知",
		Desc = "警长出现时发送通知",
		Value = flags.notifySheriff,
		Callback = function(state)
			flags.notifySheriff = state
			notifiedSheriff = false
			saveAll()
		end
	})
	visualsTab:Toggle({
		Title = "🎭 立即显示身份",
		Desc = "回合开始时显示你的身份",
		Value = flags.instantRole,
		Callback = function(state)
			flags.instantRole = state
			lastMyRole = "FORCE_RESET"
			saveAll()
		end
	})

	farmTab:Section({ Title = "💰 自动收集" })
	farmTab:Toggle({
		Title = "🪙 自动收集金币（增强版）",
		Desc = "自动收集金币并扩大金币触碰范围",
		Value = flags.autoFarmCoins,
		Callback = function(state)
			flags.autoFarmCoins = state
			saveAll()
			if state then
				coinsReach(true)
				startAutoFarm()
			else
				stopAutoFarm()
				coinsReach(false)
			end
		end
	})

	combatTab:Section({ Title = "🔪 杀手" })
	combatTab:Toggle({
		Title = "💀 小刀攻击光环",
		Desc = "使用小刀攻击附近玩家",
		Value = flags.killAura,
		Callback = function(state)
			flags.killAura = state
			saveAll()
		end
	})

	local rangeLabel = combatTab:Paragraph({
		Title = "📊 攻击光环范围",
		Desc = "当前：" .. tostring(flags.killAuraRange) .. "（最大：50）"
	})

	combatTab:Button({
		Title = "➕ 增加范围",
		Callback = function()
			if flags.killAuraRange < 50 then
				flags.killAuraRange = flags.killAuraRange + 1
				saveAll()
				rangeLabel:SetDesc("当前：" .. tostring(flags.killAuraRange) .. "（最大：50）")
			end
		end
	})
	combatTab:Button({
		Title = "➖ 减少范围",
		Callback = function()
			if flags.killAuraRange > 5 then
				flags.killAuraRange = flags.killAuraRange - 1
				saveAll()
				rangeLabel:SetDesc("当前：" .. tostring(flags.killAuraRange) .. "（最大：50）")
			end
		end
	})

	combatTab:Button({
		Title = "💀 攻击所有玩家",
		Desc = "攻击所有玩家",
		Callback = function()
			killAll()
		end
	})

	combatTab:Toggle({
		Title = "🔪 自动投掷小刀",
		Desc = "向最近的玩家投掷小刀",
		Value = flags.autoKnifeThrow,
		Callback = function(state)
			flags.autoKnifeThrow = state
			saveAll()
		end
	})

	combatTab:Section({ Title = "🔫 警长" })
	combatTab:Toggle({
		Title = "🎯 手枪静默瞄准",
		Desc = "无需移动镜头即可瞄准杀手（需要手枪）",
		Value = flags.gunSilentAim,
		Callback = function(state)
			flags.gunSilentAim = state
			saveAll()
		end
	})

	combatTab:Toggle({
		Title = "🎯 自动射击杀手",
		Desc = "自动向杀手开枪",
		Value = flags.autoShoot,
		Callback = function(state)
			flags.autoShoot = state
			saveAll()
		end
	})

	combatTab:Toggle({
		Title = "🤚 自动拾取手枪",
		Desc = "自动拾取地图中的掉落手枪",
		Value = flags.autoGrabGun,
		Callback = function(state)
			flags.autoGrabGun = state
			saveAll()
		end
	})

	combatTab:Section({ Title = "📦 碰撞箱扩展" })
	combatTab:Toggle({
		Title = "📦 扩大碰撞箱",
		Desc = "扩大其他玩家的碰撞箱",
		Value = flags.hitboxExpand,
		Callback = function(state)
			flags.hitboxExpand = state
			saveAll()
		end
	})

	local hitboxLabel = combatTab:Paragraph({
		Title = "📊 碰撞箱大小",
		Desc = "当前：" .. tostring(flags.hitboxSize)
	})

	combatTab:Button({
		Title = "➕ 增大碰撞箱",
		Callback = function()
			if flags.hitboxSize < 20 then
				flags.hitboxSize = flags.hitboxSize + 1
				saveAll()
				hitboxLabel:SetDesc("当前：" .. tostring(flags.hitboxSize))
			end
		end
	})
	combatTab:Button({
		Title = "➖ 缩小碰撞箱",
		Callback = function()
			if flags.hitboxSize > 1 then
				flags.hitboxSize = flags.hitboxSize - 1
				saveAll()
				hitboxLabel:SetDesc("当前：" .. tostring(flags.hitboxSize))
			end
		end
	})

	combatTab:Toggle({
		Title = "📦 显示碰撞箱",
		Desc = "显示扩大的碰撞箱",
		Value = flags.hitboxVisible,
		Callback = function(state)
			flags.hitboxVisible = state
			saveAll()
		end
	})

	teleportTab:Section({ Title = "🚀 快速传送" })
	teleportTab:Button({
		Title = "⬇️ 传送到掉落手枪",
		Callback = function()
			local root = getRoot(localPlayer)
			if not root then return end
			for _, desc in ipairs(workspace:GetDescendants()) do
				if desc.Name == "GunDrop" and desc:IsA("BasePart") then
					root.CFrame = desc.CFrame + Vector3.new(0, 3, 0)
					WindUI:Notify({ Title = "传送", Content = "✅ 已传送到手枪", Duration = 2 })
					return
				end
			end
			WindUI:Notify({ Title = "传送", Content = "❌ 未找到掉落手枪", Duration = 2 })
		end
	})
	teleportTab:Button({
		Title = "🔴 传送到杀手",
		Callback = function()
			local target = findMurderer()
			local root = getRoot(localPlayer)
			local targetRoot = target and getRoot(target)
			if root and targetRoot then
				root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
				WindUI:Notify({ Title = "传送", Content = "✅ 已传送到杀手", Duration = 2 })
			else
				WindUI:Notify({ Title = "传送", Content = "❌ 未找到杀手", Duration = 2 })
			end
		end
	})
	teleportTab:Button({
		Title = "🔵 传送到警长",
		Callback = function()
			local target = findSheriff()
			local root = getRoot(localPlayer)
			local targetRoot = target and getRoot(target)
			if root and targetRoot then
				root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
				WindUI:Notify({ Title = "传送", Content = "✅ 已传送到警长", Duration = 2 })
			else
				WindUI:Notify({ Title = "传送", Content = "❌ 未找到警长", Duration = 2 })
			end
		end
	})

	playerTab:Section({ Title = "🏃 移动" })
	playerTab:Toggle({
		Title = "⚡ 自定义移动速度（最大：50）",
		Value = flags.speedEnabled,
		Callback = function(state)
			flags.speedEnabled = state
			saveAll()
			pcall(applyMovement)
		end
	})
	local speedLabel = playerTab:Paragraph({
		Title = "📊 移动速度数值",
		Desc = "当前：" .. tostring(flags.speedValue) .. "（最大：50）"
	})
	playerTab:Button({
		Title = "➕ 增加移动速度",
		Callback = function()
			if flags.speedValue < 50 then
				flags.speedValue = flags.speedValue + 1
				saveAll()
				speedLabel:SetDesc("当前：" .. tostring(flags.speedValue) .. "（最大：50）")
				if flags.speedEnabled then pcall(applyMovement) end
			end
		end
	})
	playerTab:Button({
		Title = "➖ 减少移动速度",
		Callback = function()
			if flags.speedValue > 16 then
				flags.speedValue = flags.speedValue - 1
				saveAll()
				speedLabel:SetDesc("当前：" .. tostring(flags.speedValue) .. "（最大：50）")
				if flags.speedEnabled then pcall(applyMovement) end
			end
		end
	})
	playerTab:Toggle({
		Title = "🚀 自定义跳跃力度",
		Value = flags.jumpEnabled,
		Callback = function(state)
			flags.jumpEnabled = state
			saveAll()
			pcall(applyMovement)
		end
	})
	local jumpLabel = playerTab:Paragraph({
		Title = "📊 跳跃力度数值",
		Desc = "当前：" .. tostring(flags.jumpValue)
	})
	playerTab:Button({
		Title = "➕ 增加跳跃力度",
		Callback = function()
			if flags.jumpValue < 120 then
				flags.jumpValue = flags.jumpValue + 1
				saveAll()
				jumpLabel:SetDesc("当前：" .. tostring(flags.jumpValue))
				if flags.jumpEnabled then pcall(applyMovement) end
			end
		end
	})
	playerTab:Button({
		Title = "➖ 减少跳跃力度",
		Callback = function()
			if flags.jumpValue > 50 then
				flags.jumpValue = flags.jumpValue - 1
				saveAll()
				jumpLabel:SetDesc("当前：" .. tostring(flags.jumpValue))
				if flags.jumpEnabled then pcall(applyMovement) end
			end
		end
	})

	playerTab:Section({ Title = "👻 无敌模式" })
	playerTab:Toggle({
		Title = "🌀 穿墙",
		Desc = "穿过墙壁",
		Value = flags.noclipEnabled,
		Callback = function(state)
			flags.noclipEnabled = state
			saveAll()
			toggleNoclip(state)
		end
	})
	playerTab:Toggle({
		Title = "❤️ 无敌模式",
		Desc = "自动恢复生命值",
		Value = flags.godmode,
		Callback = function(state)
			flags.godmode = state
			saveAll()
			applyGodmode(state)
			WindUI:Notify({
				Title = "无敌模式",
				Content = state and "🟢 已开启" or "🔴 已关闭",
				Duration = 2
			})
		end
	})

	playerTab:Section({ Title = "🛡️ 防护" })
	playerTab:Toggle({
		Title = "🛡️ 防静默瞄准",
		Desc = "降低其他玩家静默瞄准的影响",
		Value = flags.antiSilentAim,
		Callback = function(state)
			flags.antiSilentAim = state
			saveAll()
			WindUI:Notify({
				Title = "防静默瞄准",
				Content = state and "🟢 已开启" or "🔴 已关闭",
				Duration = 2
			})
		end
	})

	creditsTab:Section({ Title = "⚡ POTENT HUB" })
	creditsTab:Paragraph({ Title = "👑 作者", Desc = "POTENT HUB" })
	creditsTab:Paragraph({ Title = "🛠️ 制作", Desc = "POTENT HUB" })
	creditsTab:Paragraph({ Title = "🎮 游戏", Desc = "Murder Mystery 2" })
	creditsTab:Paragraph({ Title = "📚 界面库", Desc = "POTENT HUB" })
	creditsTab:Button({
		Title = "📋 复制作者名称",
		Callback = function()
			pcall(function() setclipboard("POTENT HUB") end)
			WindUI:Notify({ Title = "POTENT HUB", Content = "✅ 已复制作者名称！", Duration = 2 })
		end
	})

	WindUI:Notify({
		Title = "⚡ POTENT HUB",
		Content = "✅ Murder Mystery 2 已加载！",
		Duration = 4
	})

	print("✅ POTENT HUB | Murder Mystery 2 已加载")
	print("🤚 自动拾取手枪：已修复")
	print("❤️ 无敌模式：已启用")
	print("🛡️ 防静默瞄准：已启用")
	print("💾 配置保存至：" .. CONFIG_FILE)
end

-- ============================================================
-- ========== 启动主脚本 ==========
runMainScript()
