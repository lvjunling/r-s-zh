--!nocheck
--[[
  Chicken Auto Hub - Obsidian / LinoriaLib UI
  (Full English Edition: Automation, Event Mob Tracking & Hover, Target Maxing, Expand Coop, Smart Tower & Incubator)
]]

-- Terminate previous script instances
if _G.__AutoFarmRebirthRunning then
	_G.__AutoFarmRebirthStop = true
	_G.__AutoFarmRebirthRunning = false
	task.wait(0.3)
end
_G.__AutoFarmRebirthRunning = true
_G.__AutoFarmRebirthStop = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)

-- Load Obsidian UI Library & Addons
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local CONFIG = {
	enabled = true,
	autoUpgrade = true,
	autoTowerAndRebirth = true,
	upgradeAllAtOnce = true,   -- false: Sequential 1-by-1 | true: Upgrade All Simultaneously
	autoClaimIncubator = true,
	maxGenerators = 6,          -- Configurable from 1 to 6
	upgradeInterval = 0.10,     -- Turbo Delay (0.10s)
	towerRestartInterval = 16,
	rebirthCheckInterval = 5,
	incubatorInterval = 180,    -- 3 Minutes
	cooldownBeforeTower = 6,
	cooldownAfterRebirth = 8,

	-- Anti-AFK Configuration
	autoAntiAFK = true,
	antiAFKInterval = 600,     -- 10 Minutes (600s)

	-- Nest Egg Collection Configuration
	autoCollectNestEggs = true,
	nestEggCheckInterval = 3,  -- Every 3 seconds

	-- Golden Goose Tracker Configuration
	autoTrackGoldenGoose = false,
	autoAttackGoldenGoose = false,
	goldenGooseHoverHeight = 6,
	goldenGooseTeleportInterval = 3, -- Teleport once every 3 seconds (Anti-Kick)

	-- Arena Fight Configuration
	autoArenaFight = false,
	arenaFightInterval = 5,    -- Every 5 seconds
}

local sessionId = 0
local isLoopRunning = false
local currentGeneratorTarget = 1
local goldenGooseConnection = nil

---------------------------------------------------------
-- 🛡️ SAFE ANTI-AFK (Human-like Walk Simulation Every 10 Mins)
---------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(CONFIG.antiAFKInterval or 600)
		if _G.__AutoFarmRebirthStop then break end
		if CONFIG.autoAntiAFK then
			pcall(function()
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local hrp = char and char:FindFirstChild("HumanoidRootPart")

				if hum and hrp and hum.Health > 0 then
					local startPos = hrp.Position

					-- 1. Walk forward 3 studs
					hum:MoveTo(startPos + (hrp.CFrame.LookVector * 3))
					task.wait(0.6)

					-- 2. Walk back to starting position
					hum:MoveTo(startPos)
					task.wait(0.6)

					-- 3. Stop movement
					hum:Move(Vector3.zero)
				end
			end)
		end
	end
end)

local function smartWait(duration, currentSession)
	local start = tick()
	while tick() - start < duration do
		if not CONFIG.enabled or _G.__AutoFarmRebirthStop or sessionId ~= currentSession then
			return false
		end
		task.wait(0.2)
	end
	return true
end

---------------------------------------------------------
-- REMOTE INITIALIZATION & CACHING
---------------------------------------------------------
local validRemotes = {}
local function initRemotesOnce()
	if RemotesFolder then
		for _, r in ipairs(RemotesFolder:GetChildren()) do
			if r:IsA("RemoteFunction") or r:IsA("RemoteEvent") then
				validRemotes[r.Name] = r
			end
		end
	end

	if getnilinstances then
		for _, v in pairs(getnilinstances()) do
			if (v.ClassName == "RemoteFunction" or v.ClassName == "RemoteEvent") and not validRemotes[v.Name] then
				validRemotes[v.Name] = v
			end
		end
	end
end
initRemotesOnce()

local okReq, CoreRemotes = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Core", 3):WaitForChild("Remotes", 3))
end)

local function safeInvoke(remoteName, ...)
	if _G.__AutoFarmRebirthStop then return false end

	local remote = validRemotes[remoteName] or (RemotesFolder and RemotesFolder:FindFirstChild(remoteName))
	if remote then
		local ok, res = pcall(function(...)
			if remote:IsA("RemoteFunction") then
				return remote:InvokeServer(...)
			elseif remote:IsA("RemoteEvent") then
				remote:FireServer(...)
				return "Fired"
			end
		end, ...)
		if ok then return true, res end
	end

	if okReq and CoreRemotes and CoreRemotes.defs and CoreRemotes.defs[remoteName] then
		local ok, res = pcall(function(...)
			return CoreRemotes.invoke(CoreRemotes.defs[remoteName], ...)
		end, ...)
		if ok then return true, res end
	end

	return false, nil
end

---------------------------------------------------------
-- 🔄 REBIRTH READY LOGIC (DIRECT DATA & STEALTH UI)
---------------------------------------------------------
local DataController = nil
local RebirthBonus = nil
pcall(function()
	local playerScripts = LocalPlayer:FindFirstChildOfClass("PlayerScripts") or LocalPlayer:FindFirstChild("PlayerScripts")
	if playerScripts then
		local coreData = playerScripts:FindFirstChild("Core", true)
		if coreData then
			local dc = coreData:FindFirstChild("DataController", true)
			if dc then DataController = require(dc) end
		end
	end
	if ReplicatedStorage:FindFirstChild("Core") and ReplicatedStorage.Core:FindFirstChild("Progression") then
		local rb = ReplicatedStorage.Core.Progression:FindFirstChild("RebirthBonus")
		if rb then RebirthBonus = require(rb) end
	end
end)

---------------------------------------------------------
-- 📡 REAL-TIME DATASERVICE PACKET LISTENER
---------------------------------------------------------
local cachedServerData = {
	coop = nil,
	rebirth = nil,
	tower = nil,
	lastUpdate = 0
}

pcall(function()
	local packages = ReplicatedStorage:FindFirstChild("Packages", true)
	if packages then
		local remotes = packages:FindFirstChild("_remotes", true)
		if remotes then
			local ds = remotes:FindFirstChild("DataService", true)
			if ds then
				local remoteEvent = ds:FindFirstChild("RemoteEvent")
				if remoteEvent then
					remoteEvent.OnClientEvent:Connect(function(actionType, path, data)
						if type(path) == "table" and #path > 0 then
							local category = tostring(path[1]):lower()
							cachedServerData[category] = data
							cachedServerData.lastUpdate = tick()
						end
					end)
				end
			end
		end
	end
end)

local WindowStateModule = nil
pcall(function()
	local playerScripts = LocalPlayer:FindFirstChildOfClass("PlayerScripts") or LocalPlayer:FindFirstChild("PlayerScripts")
	if playerScripts then
		local uiFolder = playerScripts:FindFirstChild("UI", true)
		if uiFolder then
			local hud = uiFolder:FindFirstChild("HUD", true)
			if hud then
				local ws = hud:FindFirstChild("WindowState")
				if ws then WindowStateModule = require(ws) end
			end
		end
	end
end)

local function hideRebirthGuiStealth(gui)
	if not gui then return end
	pcall(function()
		local frame = gui:FindFirstChild("Frame") or gui:FindFirstChildWhichIsA("Frame", true)
		if frame then
			-- Shift UI off-screen so human player never sees it on display
			frame.Position = UDim2.new(100, 0, 100, 0)
		end
	end)
end

local function isRebirthReadyFromData()
	if RebirthBonus then
		-- 1. Try reading from cached real-time server packets first
		local okCache, readyCache = pcall(function()
			local rebCount = 0
			if cachedServerData.rebirth and type(cachedServerData.rebirth) == "table" then
				rebCount = cachedServerData.rebirth.count or 0
			elseif DataController then
				local reb = DataController.rebirth()
				rebCount = if reb then (reb.count or 0) else 0
			end

			local towerBest = 0
			if cachedServerData.tower and type(cachedServerData.tower) == "table" then
				towerBest = cachedServerData.tower.best or cachedServerData.tower.maxFloor or 0
			elseif DataController then
				towerBest = DataController.towerBest() or 0
			end

			if towerBest > 0 then
				return RebirthBonus.ready(towerBest, rebCount)
			end
		end)
		if okCache and readyCache ~= nil then
			return readyCache
		end
	end

	-- 2. Fallback to DataController directly
	if DataController and RebirthBonus then
		local ok, ready = pcall(function()
			local reb = DataController.rebirth()
			local count = if reb then (reb.count or 0) else 0
			local towerBest = DataController.towerBest() or 0
			return RebirthBonus.ready(towerBest, count)
		end)
		if ok and ready ~= nil then
			return ready
		end
	end
	return nil
end

local function openRebirthUI()
	if WindowStateModule and WindowStateModule.rebirth then
		pcall(function()
			WindowStateModule.rebirth(true)
		end)
	end
end

local function getRebirthBar(autoOpenIfMissing)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	-- Search 1: Direct ScreenGui named "Rebirth"
	local rebirthGui = playerGui:FindFirstChild("Rebirth")
	if rebirthGui then
		hideRebirthGuiStealth(rebirthGui)
		local reqCard = rebirthGui:FindFirstChild("reqCard", true)
		if reqCard then
			local bar = reqCard:FindFirstChild("bar", true)
			if bar and bar:IsDescendantOf(playerGui) then return bar end
		end
	end

	-- Search 2: Direct path provided
	local ok, bar = pcall(function()
		local children = playerGui:GetChildren()
		if children[11] then
			hideRebirthGuiStealth(children[11])
			return children[11].Frame.window.panel.face.content.content.body.reqCard.face.content.bar
		end
	end)
	if ok and bar and bar:IsDescendantOf(playerGui) then return bar end

	-- Search 3: Dynamic search across all ScreenGuis in PlayerGui
	for _, gui in ipairs(playerGui:GetChildren()) do
		local reqCard = gui:FindFirstChild("reqCard", true)
		if reqCard then
			hideRebirthGuiStealth(gui)
			local foundBar = reqCard:FindFirstChild("bar", true)
			if foundBar then
				return foundBar
			end
		end
	end

	-- Search 4: If UI window is closed and autoOpenIfMissing is true, open in stealth mode!
	if autoOpenIfMissing and WindowStateModule and WindowStateModule.rebirth then
		pcall(function() WindowStateModule.rebirth(true) end)
		task.wait(0.15)
		local rGui = playerGui:FindFirstChild("Rebirth")
		if rGui then
			hideRebirthGuiStealth(rGui)
			local reqCard = rGui:FindFirstChild("reqCard", true)
			if reqCard then
				local foundBar = rGui:FindFirstChild("bar", true)
				if foundBar then return foundBar end
			end
		end
	end

	return nil
end

local function isRebirthReadyFromUI(autoOpenIfMissing)
	-- 1. Try Direct Data check first (100% silent & stealth, no UI popups needed!)
	local dataReady = isRebirthReadyFromData()
	if dataReady ~= nil then
		return dataReady
	end

	-- 2. Fallback to Stealth UI check & bar color check
	local bar = getRebirthBar(autoOpenIfMissing)
	if not bar then return nil end

	-- Collect candidate colors from bar and its descendants
	local candidateColors = {}
	if bar:IsA("GuiObject") then
		table.insert(candidateColors, bar.BackgroundColor3)
		if bar:IsA("ImageLabel") or bar:IsA("ImageButton") then
			table.insert(candidateColors, bar.ImageColor3)
		end
	end

	for _, child in ipairs(bar:GetDescendants()) do
		if child:IsA("GuiObject") then
			table.insert(candidateColors, child.BackgroundColor3)
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				table.insert(candidateColors, child.ImageColor3)
			end
		end
	end

	for _, color in ipairs(candidateColors) do
		local r = math.floor(color.R * 255 + 0.5)
		local g = math.floor(color.G * 255 + 0.5)
		local b = math.floor(color.B * 255 + 0.5)

		-- Ready color: RGB (8, 78, 15) - Greenish
		if (math.abs(r - 8) <= 12 and math.abs(g - 78) <= 15 and math.abs(b - 15) <= 12) or (g > r + 30 and g > b + 30) then
			return true
		end

		-- Not ready color: RGB (0, 57, 89) - Blueish
		if (math.abs(r - 0) <= 12 and math.abs(g - 57) <= 15 and math.abs(b - 89) <= 15) or (b > r + 30 and b > g + 10) then
			return false
		end
	end

	return nil
end

---------------------------------------------------------
-- ⚙️ GENERATOR MAX & PURCHASE STATE TRACKING
---------------------------------------------------------
local maxedGenerators = {}
local boughtGenerators = {}
local expandedCoopTier = {}

local function resetGeneratorStates()
	maxedGenerators = {}
	boughtGenerators = {}
	expandedCoopTier = {}
	currentGeneratorTarget = 1
end

local function isAllGeneratorsMaxed()
	for i = 1, CONFIG.maxGenerators do
		if not maxedGenerators[i] then
			return false
		end
	end
	return true
end

-- Progressive Generator Upgrade & Step-by-Step Coop Expansion (Support for 6 Machines)
local function tryBuyAndUpgradeGenerators()
	if not CONFIG.enabled or _G.__AutoFarmRebirthStop then return end
	if isRebirthReadyFromUI() == true then return end

	-- 0. If all target generators (1 to maxGenerators) are maxed out, STOP firing remotes completely!
	if isAllGeneratorsMaxed() then
		return
	end

	if CONFIG.upgradeAllAtOnce then
		-- Mode: Upgrade All Generators Simultaneously (Round-Robin for machines 1..maxGenerators)
		for i = 1, CONFIG.maxGenerators do
			if not CONFIG.enabled or _G.__AutoFarmRebirthStop then break end
			if isRebirthReadyFromUI() == true then break end

			if not maxedGenerators[i] then
				-- Auto-expand coop for generator slot 3 and above
				if i >= 3 then
					safeInvoke("ExpandCoop")
				end

				-- Fire BuyGenerator and UpgradeGenerator remotes with machine index (1 to 6)
				local okBuy, resBuy = safeInvoke("BuyGenerator", i)
				local okUpg, resUpg = safeInvoke("UpgradeGenerator", i)

				local ok = okBuy or okUpg
				local res = resBuy or resUpg
				boughtGenerators[i] = true

				if ok and type(res) == "table" and res.error then
					local err = tostring(res.error):lower()
					if string.find(err, "coop") then
						-- Server requires coop expansion: invoke ExpandCoop immediately
						safeInvoke("ExpandCoop")
					elseif (string.find(err, "max") or string.find(err, "full")) and not string.find(err, "money") and not string.find(err, "cash") and not string.find(err, "afford") then
						maxedGenerators[i] = true
					end
				end
				task.wait(0.02)
			end
		end
	else
		-- Mode: Sequential Upgrade (1-by-1 to Max Level for machines 1..maxGenerators)
		while currentGeneratorTarget <= CONFIG.maxGenerators and maxedGenerators[currentGeneratorTarget] do
			currentGeneratorTarget = currentGeneratorTarget + 1
		end

		if currentGeneratorTarget > CONFIG.maxGenerators then
			return -- All generators up to maxGenerators are maxed!
		end

		-- 1. If target is generator 3 or higher, attempt coop expansion
		if currentGeneratorTarget >= 3 then
			safeInvoke("ExpandCoop")
		end

		-- 2. Turbo Buy & Upgrade current target generator (1 to 6)
		for _ = 1, 3 do
			if isRebirthReadyFromUI() == true then break end

			-- Fire BuyGenerator (game's updated remote) and UpgradeGenerator for current generator slot
			local okBuy, resBuy = safeInvoke("BuyGenerator", currentGeneratorTarget)
			local okUpg, resUpg = safeInvoke("UpgradeGenerator", currentGeneratorTarget)

			local ok = okBuy or okUpg
			local res = resBuy or resUpg
			boughtGenerators[currentGeneratorTarget] = true

			local isMax = false
			if ok and type(res) == "table" and res.error then
				local err = tostring(res.error):lower()
				if string.find(err, "coop") then
					-- Server requires coop expansion: invoke ExpandCoop immediately
					safeInvoke("ExpandCoop")
				elseif (string.find(err, "max") or string.find(err, "full")) and not string.find(err, "money") and not string.find(err, "cash") and not string.find(err, "afford") then
					isMax = true
				end
			end

			if isMax then
				maxedGenerators[currentGeneratorTarget] = true
				if currentGeneratorTarget < CONFIG.maxGenerators then
					currentGeneratorTarget = currentGeneratorTarget + 1
					if currentGeneratorTarget >= 3 then
						safeInvoke("ExpandCoop")
					end
				end
				break
			end
			task.wait(0.04)
		end
	end
end

local function getTowerTargets()
	local highestBeaten = 0
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local stat = leaderstats:FindFirstChild("Tower") or leaderstats:FindFirstChild("MaxTower") or leaderstats:FindFirstChild("Floor")
		if stat then
			highestBeaten = tonumber(stat.Value) or 0
		end
	end

	local nextFloor = highestBeaten + 1
	local checkpointFloor = math.floor(highestBeaten / 5) * 5
	if checkpointFloor < 5 then checkpointFloor = 5 end

	return nextFloor, checkpointFloor
end

local function startTower(skipCooldown, currentSession)
	if not CONFIG.enabled or _G.__AutoFarmRebirthStop or sessionId ~= currentSession then return end
	if isRebirthReadyFromUI() == true then
		safeInvoke("TowerSurrender")
		return
	end

	if not skipCooldown and CONFIG.cooldownBeforeTower > 0 then
		if not smartWait(CONFIG.cooldownBeforeTower, currentSession) then return end
	end

	if not CONFIG.enabled or _G.__AutoFarmRebirthStop or sessionId ~= currentSession then return end
	if isRebirthReadyFromUI() == true then
		safeInvoke("TowerSurrender")
		return
	end

	safeInvoke("TowerContinueDecline")
	task.wait(0.1)

	local nextFloor, checkpointFloor = getTowerTargets()

	safeInvoke("TowerElevator", nextFloor)
	task.wait(0.15)

	if checkpointFloor ~= nextFloor then
		safeInvoke("TowerElevator", checkpointFloor)
		task.wait(0.15)
	end

	safeInvoke("TowerStart")
end

local function tryRebirth()
	local uiReady = isRebirthReadyFromUI()
	if uiReady == false then
		-- Rebirth requirement is explicitly NOT ready yet according to UI bar color (0, 57, 89)
		return false, "UI bar indicates not ready (color 0, 57, 89)"
	end

	local ok, result = safeInvoke("Rebirth")
	if ok then
		if type(result) == "table" and result.ok == false then return false, result.error or "ok=false" end
		if result ~= false then return true, result end
	end

	if okReq and CoreRemotes and CoreRemotes.defs and CoreRemotes.defs.Rebirth then
		local okCore, resultCore = pcall(function()
			return CoreRemotes.invoke(CoreRemotes.defs.Rebirth)
		end)
		if okCore then
			if type(resultCore) == "table" and resultCore.ok == false then return false, resultCore.error or "ok=false" end
			if resultCore ~= false then return true, resultCore end
		end
	end

	return false, tostring(result)
end

---------------------------------------------------------
-- 🥚 AUTOMATED NEST EGG COLLECTION LOGIC
---------------------------------------------------------
local function tryCollectNestEggs()
	if not CONFIG.autoCollectNestEggs or _G.__AutoFarmRebirthStop then return end

	local folder = workspace:FindFirstChild("NestEggs")
	if not folder then return end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	for _, nestEgg in ipairs(folder:GetChildren()) do
		if not CONFIG.enabled or _G.__AutoFarmRebirthStop then break end

		local ownerAttr = nestEgg:GetAttribute("owner")
		local isMyEgg = false

		if ownerAttr then
			if tonumber(ownerAttr) == LocalPlayer.UserId or tostring(ownerAttr) == tostring(LocalPlayer.UserId) or tostring(ownerAttr) == LocalPlayer.Name then
				isMyEgg = true
			end
		else
			isMyEgg = true
		end

		if isMyEgg then
			-- 1. Fire Remote collection if available
			local eggId = nestEgg:GetAttribute("eggId")
			if eggId then
				safeInvoke("CollectNestEgg", eggId)
				safeInvoke("ClaimNestEgg", eggId)
				safeInvoke("CollectEgg", eggId)
			end
			safeInvoke("CollectNestEgg", nestEgg)

			-- 2. Touch Interest collection (firetouchinterest)
			if hrp then
				local targetPart = nestEgg:IsA("BasePart") and nestEgg or nestEgg:FindFirstChildWhichIsA("BasePart", true)
				if targetPart then
					if firetouchinterest then
						pcall(function()
							firetouchinterest(hrp, targetPart, 0)
							task.wait(0.02)
							firetouchinterest(hrp, targetPart, 1)
						end)
					end
				end
			end
		end
	end
end

---------------------------------------------------------
-- ⚔️ AUTOMATED ARENA FIGHT LOGIC
---------------------------------------------------------
local function tryArenaFight()
	if not CONFIG.autoArenaFight or _G.__AutoFarmRebirthStop then return end
	safeInvoke("ArenaFight")
end

---------------------------------------------------------
-- 🐔 GOLDEN GOOSE STRICT TARGETING & TRACKING LOGIC
---------------------------------------------------------
local function findRootPart(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then return inst end
	if inst:IsA("Model") then
		if inst.PrimaryPart then return inst.PrimaryPart end
		local hrp = inst:FindFirstChild("HumanoidRootPart", true) or inst:FindFirstChild("Head", true) or inst:FindFirstChild("Torso", true) or inst:FindFirstChildWhichIsA("BasePart", true)
		if hrp then return hrp end
	end
	return inst:FindFirstChildWhichIsA("BasePart", true)
end

local lastDebugNotifyTime = 0
local lastFoundTargetName = ""
local lastPrintLogTime = 0

local function isGoldenGooseMob(npc)
	if not npc then return false end

	-- Must be a Model or BasePart inside workspace.ChickenBodies
	if not (npc:IsA("Model") or npc:IsA("BasePart")) then
		return false
	end

	local name = npc.Name:lower()

	-- 1. Exclude coop chickens and tower rivals
	if name:find("coop") or name:find("tower") or name:find("rival") then
		return false
	end

	-- 2. Check ovName attribute: MUST NOT be "Chicken Boss"
	local ovName = npc:GetAttribute("ovName")
	if ovName then
		local ovStr = tostring(ovName):lower()
		if ovStr:find("boss") or ovStr:find("chicken boss") then
			return false
		end
		if ovStr:find("golden") or ovStr:find("goose") then
			print("[Goose Tracker Debug] MATCHED by ovName 'Golden Goose': " .. npc.Name)
			return true
		end
	end

	-- 3. Check ovNameKey attribute: MUST NOT be boss.chickenBoss
	local ovNameKey = npc:GetAttribute("ovNameKey")
	if ovNameKey then
		local keyStr = tostring(ovNameKey):lower()
		if keyStr:find("boss") then
			return false
		end
		if keyStr:find("golden") or keyStr:find("goose") then
			print("[Goose Tracker Debug] MATCHED by ovNameKey: " .. npc.Name)
			return true
		end
	end

	-- 4. Check cos_color attribute: Must contain "golden"
	local cosColor = npc:GetAttribute("cos_color")
	if cosColor and tostring(cosColor):lower():find("golden") then
		print("[Goose Tracker Debug] MATCHED by cos_color 'golden': " .. npc.Name)
		return true
	end

	-- 5. Direct child GooseDamagePodium (GooseDamagePodium is UNIQUE to Golden Goose!)
	if npc:FindFirstChild("GooseDamagePodium") then
		print("[Goose Tracker Debug] MATCHED by GooseDamagePodium: " .. npc.Name)
		return true
	end

	return false
end

local function getTargetGoldenGoose()
	local folder = workspace:FindFirstChild("ChickenBodies")
	if not folder then
		print("[Goose Tracker Debug] workspace.ChickenBodies folder does not exist!")
		return nil, nil, 0
	end

	local children = folder:GetChildren()
	local checkedCount = #children

	for _, npc in ipairs(children) do
		if isGoldenGooseMob(npc) then
			local root = findRootPart(npc)
			if root then
				if npc.Name ~= lastFoundTargetName and tick() - lastDebugNotifyTime > 3 then
					lastFoundTargetName = npc.Name
					lastDebugNotifyTime = tick()
					Library:Notify("[金鹅调试] 已锁定目标：" .. npc.Name, 3)
					print(string.format("[Goose Tracker Debug] >>> TARGET ACQUIRED: workspace.ChickenBodies['%s'] (Root: %s, Pos: %.1f, %.1f, %.1f)", npc.Name, root.Name, root.Position.X, root.Position.Y, root.Position.Z))
				end
				return npc, root, checkedCount
			end
		end
	end

	return nil, nil, checkedCount
end

local GoldenGooseStatusLabel = nil
local trackerSessionId = 0

local function updateGoldenGooseTracker(enable)
	_G.__GoldenGooseTrackerActive = enable
	trackerSessionId = trackerSessionId + 1
	local currentTrackerSession = trackerSessionId

	print("[Goose Tracker Debug] updateGoldenGooseTracker state changed to: " .. tostring(enable))

	if not enable then
		if GoldenGooseStatusLabel then GoldenGooseStatusLabel:SetText("状态：追踪已关闭") end
		return
	end

	task.spawn(function()
		while CONFIG.autoTrackGoldenGoose and _G.__GoldenGooseTrackerActive and not _G.__AutoFarmRebirthStop and trackerSessionId == currentTrackerSession do
			pcall(function()
				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				if hrp and hum and hum.Health > 0 then
					local targetNpc, targetRoot, checkedCount = getTargetGoldenGoose()
					if targetRoot then
						local displayName = targetNpc:GetAttribute("ovName") or targetNpc.Name
						if GoldenGooseStatusLabel then
							GoldenGooseStatusLabel:SetText("状态：每 3 秒传送至 " .. tostring(displayName) .. " (" .. targetNpc.Name .. ")")
						end

						print(string.format("[Goose Tracker Debug] >>> Teleporting player to Golden Goose '%s' (%s) at CFrame Pos: %.1f, %.1f, %.1f", tostring(displayName), targetNpc.Name, targetRoot.Position.X, targetRoot.Position.Y + CONFIG.goldenGooseHoverHeight, targetRoot.Position.Z))

						-- 1. Teleport player once every 3 seconds above Golden Goose
						hrp.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, CONFIG.goldenGooseHoverHeight, 0))

						-- 2. Remote Attacks
						local fired = safeInvoke("SetChickenOrder", "chaos")
						if fired then
							print("[Goose Tracker Debug] Fired Remote 'SetChickenOrder' ('chaos')")
						end

						if CONFIG.autoAttackGoldenGoose and targetNpc then
							safeInvoke("AttackMob", targetNpc)
							safeInvoke("HitMob", targetNpc)
							safeInvoke("DamageMob", targetNpc)
						end
					else
						print(string.format("[Goose Tracker Debug] Searching... Checked %d items in ChickenBodies. No Golden Goose target active.", checkedCount))
						if GoldenGooseStatusLabel then
							GoldenGooseStatusLabel:SetText("状态：正在 ChickenBodies 中搜索（" .. tostring(checkedCount) .. " 个对象已检查）……")
						end
					end
				end
			end)

			task.wait(CONFIG.goldenGooseTeleportInterval or 3)
		end
	end)
end

local function stopAll()
	CONFIG.enabled = false
	_G.__AutoFarmRebirthStop = true
	_G.__AutoFarmRebirthRunning = false
	_G.__GoldenGooseTrackerActive = false
	isLoopRunning = false
	sessionId = sessionId + 1
	trackerSessionId = trackerSessionId + 1
end

local function startLoops()
	if isLoopRunning then return end
	isLoopRunning = true

	CONFIG.enabled = true
	_G.__AutoFarmRebirthStop = false
	_G.__AutoFarmRebirthRunning = true

	sessionId = sessionId + 1
	local currentSession = sessionId

	if CONFIG.autoTrackGoldenGoose then
		updateGoldenGooseTracker(true)
	end

	task.spawn(function()
		tryBuyAndUpgradeGenerators()
		tryCollectNestEggs()
		if CONFIG.autoClaimIncubator then
			safeInvoke("IncubatorClaim")
		end
		if CONFIG.autoTowerAndRebirth then
			startTower(false, currentSession)
		end
		if CONFIG.autoArenaFight then
			tryArenaFight()
		end
	end)

	-- 1. Loop Auto Buy/Upgrade Feeder
	task.spawn(function()
		while CONFIG.enabled and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
			if CONFIG.autoUpgrade then
				safeInvoke("TowerContinueDecline")
				tryBuyAndUpgradeGenerators()
			end
			if not smartWait(CONFIG.upgradeInterval, currentSession) then break end
		end
	end)

	-- 2. Loop Tower Keep-Alive
	task.spawn(function()
		while CONFIG.enabled and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
			if not smartWait(CONFIG.towerRestartInterval, currentSession) then break end
			if CONFIG.enabled and CONFIG.autoTowerAndRebirth and not _G.__AutoFarmRebirthStop and sessionId == currentSession then
				startTower(true, currentSession)
			end
		end
	end)

	-- 3. Loop Auto Incubator Claim
	task.spawn(function()
		while CONFIG.enabled and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
			if not smartWait(CONFIG.incubatorInterval, currentSession) then break end
			if CONFIG.enabled and CONFIG.autoClaimIncubator and not _G.__AutoFarmRebirthStop and sessionId == currentSession then
				safeInvoke("IncubatorClaim")
			end
		end
	end)

	-- 4. Loop Auto Rebirth
	task.spawn(function()
		while CONFIG.enabled and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
			if CONFIG.autoTowerAndRebirth then
				local uiReady = isRebirthReadyFromUI(true)

				if uiReady == true then
					-- 1. Stop tower & exit/surrender immediately so player comes down
					safeInvoke("TowerSurrender")
					task.wait(0.5)

					-- 2. Once down, stop doing everything else and spam Rebirth until bar color turns to 0, 57, 89
					while CONFIG.enabled and CONFIG.autoTowerAndRebirth and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
						local currentState = isRebirthReadyFromUI()
						if currentState == false then
							-- Bar turned into 0, 57, 89 (Not ready) -> Rebirth success!
							break
						end

						-- Fire Rebirth remotes repeatedly
						safeInvoke("Rebirth")
						if okReq and CoreRemotes and CoreRemotes.defs and CoreRemotes.defs.Rebirth then
							pcall(function() CoreRemotes.invoke(CoreRemotes.defs.Rebirth) end)
						end
						task.wait(0.2)
					end

					-- 3. Post-Rebirth milestone claim & restart sequence
					safeInvoke("TowerSurrender")

					if okReq and CoreRemotes and CoreRemotes.defs and (CoreRemotes.defs.ClaimRebirthMilestones or CoreRemotes.defs.ClaimRebirthMilestone) then
						local def = CoreRemotes.defs.ClaimRebirthMilestones or CoreRemotes.defs.ClaimRebirthMilestone
						pcall(function() CoreRemotes.invoke(def) end)
					else
						safeInvoke("ClaimRebirthMilestones")
					end

					resetGeneratorStates()

					task.wait(1.0)
					tryBuyAndUpgradeGenerators()

					if not smartWait(CONFIG.cooldownAfterRebirth, currentSession) then break end

					if CONFIG.enabled and CONFIG.autoTowerAndRebirth and not _G.__AutoFarmRebirthStop and sessionId == currentSession then
						startTower(false, currentSession)
					end
				else
					local ok, _ = tryRebirth()

					if ok then
						safeInvoke("TowerSurrender")

						if okReq and CoreRemotes and CoreRemotes.defs and (CoreRemotes.defs.ClaimRebirthMilestones or CoreRemotes.defs.ClaimRebirthMilestone) then
							local def = CoreRemotes.defs.ClaimRebirthMilestones or CoreRemotes.defs.ClaimRebirthMilestone
							pcall(function() CoreRemotes.invoke(def) end)
						else
							safeInvoke("ClaimRebirthMilestones")
						end

						resetGeneratorStates()

						task.wait(1.0)
						tryBuyAndUpgradeGenerators()

						if not smartWait(CONFIG.cooldownAfterRebirth, currentSession) then break end

						if CONFIG.enabled and CONFIG.autoTowerAndRebirth and not _G.__AutoFarmRebirthStop and sessionId == currentSession then
							startTower(false, currentSession)
						end
					end
				end
			end

			if not smartWait(CONFIG.rebirthCheckInterval, currentSession) then break end
		end
		if sessionId == currentSession then
			isLoopRunning = false
			_G.__AutoFarmRebirthRunning = false
		end
	end)

	-- 5. Loop Auto Collect Nest Eggs
	task.spawn(function()
		while CONFIG.enabled and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
			if CONFIG.autoCollectNestEggs then
				tryCollectNestEggs()
			end
			if not smartWait(CONFIG.nestEggCheckInterval or 3, currentSession) then break end
		end
	end)

	-- 6. Loop Auto Arena Fight
	task.spawn(function()
		while CONFIG.enabled and not _G.__AutoFarmRebirthStop and sessionId == currentSession do
			if CONFIG.autoArenaFight then
				tryArenaFight()
			end
			if not smartWait(CONFIG.arenaFightInterval or 5, currentSession) then break end
		end
	end)
end

---------------------------------------------------------
-- 🎪 EVENT CARD & INFO LOGIC
---------------------------------------------------------
local function getEventInfo()
	local anchor = workspace:FindFirstChild("EventCardAnchor")
	if not anchor then return "未找到活动锚点", "无", "无" end

	local eventCard = anchor:FindFirstChild("EventCard")
	if not eventCard then return "未找到活动卡片", "无", "无" end

	for _, child in ipairs(eventCard:GetChildren()) do
		if child:IsA("GuiObject") or child:IsA("CanvasGroup") or child.Name:find("@") or child.Name:find("idle") or child.Name:find("active") then
			-- Name Label (e.g. "CHICKEN BOSS")
			local nameLabel = child:FindFirstChild("name", true)
			local eventName = (nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text ~= "" and nameLabel.Text) or "未知活动"

			-- Sub Label (e.g. "UPCOMING")
			local subLabel = child:FindFirstChild("sub", true)
			local eventSub = (subLabel and subLabel:IsA("TextLabel") and subLabel.Text ~= "" and subLabel.Text) or "N/A"

			-- Time Label (e.g. time.label -> "3:32")
			local timeObj = child:FindFirstChild("time", true)
			local eventTime = "无"
			if timeObj then
				if timeObj:IsA("TextLabel") and timeObj.Text ~= "" then
					eventTime = timeObj.Text
				else
					local labelInTime = timeObj:FindFirstChild("label", true) or timeObj:FindFirstChildWhichIsA("TextLabel", true)
					if labelInTime and labelInTime:IsA("TextLabel") and labelInTime.Text ~= "" then
						eventTime = labelInTime.Text
					end
				end
			end

			return eventName, eventSub, eventTime
		end
	end

	return "当前没有活动", "无", "无"
end

---------------------------------------------------------
-- OBSIDIAN UI SETUP
---------------------------------------------------------
local Window = Library:CreateWindow({
	Title = "小鸡格斗成长助手",
	Footer = "由 Lilsky1 制作",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("自动挂机", "user"),
	Event = Window:AddTab("活动", "sparkles"),
	AntiAFK = Window:AddTab("防挂机", "shield"),
	["UI Settings"] = Window:AddTab("界面设置", "settings"),
}

-- TAB 1: Main Automation & Event Controls
local MainLeftBox = Tabs.Main:AddLeftGroupbox("喂食器自动化")

MainLeftBox:AddToggle("AutoFeeder", {
	Text = "购买并升级喂食器",
	Default = true,
	Tooltip = "自动购买喂食器槽位、升级喂食器并扩建鸡舍。",
	Callback = function(Value)
		CONFIG.autoUpgrade = Value
	end,
})

MainLeftBox:AddToggle("UpgradeAllAtOnce", {
	Text = "同时升级所有喂食器",
	Default = false,
	Tooltip = "关闭：逐个将喂食器升至最高等级。\n开启：同时升级所有已解锁的喂食器。",
	Callback = function(Value)
		CONFIG.upgradeAllAtOnce = Value
	end,
})

MainLeftBox:AddSlider("MaxGenSlider", {
	Text = "喂食器数量上限",
	Default = 6,
	Min = 1,
	Max = 6,
	Rounding = 0,
	Compact = false,
	Tooltip = "设置需要购买和升级的喂食器最大数量。",
	Callback = function(Value)
		CONFIG.maxGenerators = math.floor(Value)
	end,
})

local MainRightBox = Tabs.Main:AddRightGroupbox("高塔与重生")

MainRightBox:AddToggle("MasterAutoFarm", {
	Text = "自动高塔与重生",
	Default = true,
	Tooltip = "自动挑战高塔并执行重生。",
	Callback = function(Value)
		CONFIG.autoTowerAndRebirth = Value
		if Value then
			if not isLoopRunning then startLoops() end
			Library:Notify("自动高塔与重生：已开启", 3)
		else
			Library:Notify("自动高塔与重生：已关闭", 3)
		end
	end,
})

local RebirthStatusLabel = MainRightBox:AddLabel("状态：加载中……")

-- Live auto-refresh loop for Rebirth Status Label
task.spawn(function()
	while true do
		task.wait(0.5)
		if _G.__AutoFarmRebirthStop then break end
		pcall(function()
			if RebirthStatusLabel then
				if RebirthStatusLabel.TextLabel then
					RebirthStatusLabel.TextLabel.RichText = true
				end

				local readyState = isRebirthReadyFromUI(true)
				if readyState == true then
					RebirthStatusLabel:SetText('状态：<font color="#00FF7F"><b>🟢 可以重生</b></font>')
				elseif readyState == false then
					RebirthStatusLabel:SetText('状态：<font color="#FF4D4D"><b>🔴 尚未满足条件</b></font>')
				else
					RebirthStatusLabel:SetText('状态：<font color="#AAAAAA"><b>⚪ 正在检查界面……</b></font>')
				end
			end
		end)
	end
end)

MainRightBox:AddToggle("AutoIncubator", {
	Text = "自动领取孵化器",
	Default = true,
	Tooltip = "自动领取孵化器中已经完成的鸡蛋。",
	Callback = function(Value)
		CONFIG.autoClaimIncubator = Value
	end,
})

MainRightBox:AddToggle("AutoCollectNestEggs", {
	Text = "自动收集巢穴鸡蛋",
	Default = true,
	Tooltip = "自动收集 workspace.NestEggs 中属于当前玩家 UserId 的鸡蛋。",
	Callback = function(Value)
		CONFIG.autoCollectNestEggs = Value
	end,
})

MainRightBox:AddDivider()

MainRightBox:AddButton({
	Text = "❌ 停止脚本并关闭界面",
	Func = function()
		stopAll()
		Library:Unload()
	end,
	Tooltip = "停止所有自动化线程并卸载界面。",
})

-- TAB 2: Event Information & Controls
local EventLeftBox = Tabs.Event:AddLeftGroupbox("活动状态与倒计时")

local EventNameLabel = EventLeftBox:AddLabel("活动：加载中……")
local EventSubLabel = EventLeftBox:AddLabel("状态：加载中……")
local EventTimeLabel = EventLeftBox:AddLabel("距离开始：加载中……")

EventLeftBox:AddDivider()

EventLeftBox:AddButton({
	Text = "🔄 刷新活动信息",
	Func = function()
		local name, sub, timeStr = getEventInfo()
		EventNameLabel:SetText("活动：" .. name)
		EventSubLabel:SetText("状态：" .. sub)
		EventTimeLabel:SetText("距离开始：" .. timeStr)
		Library:Notify("活动信息已刷新", 2)
	end,
	Tooltip = "手动从 Workspace 更新活动信息。",
})

-- Live auto-refresh loop for Event Info
task.spawn(function()
	while true do
		task.wait(1)
		if _G.__AutoFarmRebirthStop then break end
		pcall(function()
			if EventNameLabel and EventSubLabel and EventTimeLabel then
				local name, sub, timeStr = getEventInfo()
				EventNameLabel:SetText("活动：" .. name)
				EventSubLabel:SetText("状态：" .. sub)
				EventTimeLabel:SetText("距离开始：" .. timeStr)
			end
		end)
	end
end)

local ArenaBox = Tabs.Event:AddLeftGroupbox("竞技场自动战斗")

ArenaBox:AddToggle("AutoArenaFight", {
	Text = "自动参加竞技场",
	Default = false,
	Tooltip = "定期调用 ArenaFight 远程对象进入竞技场战斗。",
	Callback = function(Value)
		CONFIG.autoArenaFight = Value
		if Value then
			Library:Notify("自动竞技场：已开启", 2)
		else
			Library:Notify("自动竞技场：已关闭", 2)
		end
	end,
})

ArenaBox:AddSlider("ArenaIntervalSlider", {
	Text = "竞技场检查间隔（秒）",
	Default = 5,
	Min = 1,
	Max = 60,
	Rounding = 0,
	Compact = false,
	Tooltip = "触发竞技场战斗的时间间隔（秒）。",
	Callback = function(Value)
		CONFIG.arenaFightInterval = math.floor(Value)
	end,
})

ArenaBox:AddDivider()

ArenaBox:AddButton({
	Text = "⚔️ 立即进入竞技场",
	Func = function()
		local ok, res = safeInvoke("ArenaFight")
		if ok then
			Library:Notify("已调用竞技场远程对象", 2)
		else
			Library:Notify("竞技场远程对象调用失败", 2)
		end
	end,
	Tooltip = "立即触发 ArenaFight 远程对象。",
})

local EventRightBox = Tabs.Event:AddRightGroupbox("金鹅追踪与攻击")

EventRightBox:AddToggle("AutoTrackGoldenGoose", {
	Text = "追踪金鹅",
	Default = false,
	Tooltip = "精准锁定活动中的金鹅，并悬停在其正上方。",
	Callback = function(Value)
		CONFIG.autoTrackGoldenGoose = Value
		updateGoldenGooseTracker(Value)
		if Value then
			Library:Notify("金鹅追踪：运行中", 2)
		else
			Library:Notify("金鹅追踪：已停止", 2)
		end
	end,
})

EventRightBox:AddToggle("AutoAttackGoldenGoose", {
	Text = "自动攻击金鹅",
	Default = true,
	Tooltip = "悬停时自动派遣小鸡攻击竞技场中的金鹅。",
	Callback = function(Value)
		CONFIG.autoAttackGoldenGoose = Value
	end,
})

EventRightBox:AddSlider("GooseHoverHeightSlider", {
	Text = "悬停高度",
	Default = 10,
	Min = 4,
	Max = 35,
	Rounding = 0,
	Compact = false,
	Tooltip = "调整位于金鹅上方的垂直高度。",
	Callback = function(Value)
		CONFIG.goldenGooseHoverHeight = math.floor(Value)
	end,
})

GoldenGooseStatusLabel = EventRightBox:AddLabel("状态：追踪已关闭")

EventRightBox:AddDivider()

EventRightBox:AddButton({
	Text = "📍 传送至金鹅",
	Func = function()
		local npc, root = getTargetGoldenGoose()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if root and hrp then
			hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, CONFIG.goldenGooseHoverHeight, 0))
			local name = npc:GetAttribute("ovName") or npc.Name
			Library:Notify("已传送至 " .. tostring(name), 3)
		else
			Library:Notify("Workspace 中未找到金鹅", 3)
		end
	end,
	Tooltip = "立即传送到活动金鹅目标上方。",
})

-- TAB 3: Anti AFK Controls
local AntiAFKLeftBox = Tabs.AntiAFK:AddLeftGroupbox("挂机保护")

AntiAFKLeftBox:AddToggle("EnableAntiAFKToggle", {
	Text = "启用防挂机",
	Default = true,
	Tooltip = "每隔 10 分钟模拟前进 3 Stud 后返回，避免挂机断开。",
	Callback = function(Value)
		CONFIG.autoAntiAFK = Value
		if Value then
			Library:Notify("防挂机行走：已开启", 2)
		else
			Library:Notify("防挂机行走：已关闭", 2)
		end
	end,
})

AntiAFKLeftBox:AddSlider("AntiAFKIntervalSlider", {
	Text = "行走间隔（分钟）",
	Default = 10,
	Min = 1,
	Max = 15,
	Rounding = 0,
	Compact = false,
	Tooltip = "设置模拟行走的间隔分钟数。",
	Callback = function(Value)
		CONFIG.antiAFKInterval = math.floor(Value) * 60
	end,
})

local AntiAFKRightBox = Tabs.AntiAFK:AddRightGroupbox("测试")

AntiAFKRightBox:AddButton({
	Text = "🚶 测试模拟行走",
	Func = function()
		pcall(function()
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")

			if hum and hrp and hum.Health > 0 then
				local startPos = hrp.Position
				hum:MoveTo(startPos + (hrp.CFrame.LookVector * 3))
				task.wait(0.6)
				hum:MoveTo(startPos)
				task.wait(0.6)
				hum:Move(Vector3.zero)
				Library:Notify("防挂机模拟行走已执行", 2)
			end
		end)
	end,
	Tooltip = "立即测试前进 3 Stud 后返回。",
})

-- TAB 4: UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("菜单设置")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "显示快捷键菜单",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "自定义鼠标指针",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "左侧", "右侧" },
	Default = "右侧",
	Text = "通知显示位置",
	Callback = function(Value)
		Library:SetNotifySide(Value == "左侧" and "Left" or "Right")
	end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("菜单快捷键"):AddKeyPicker("MenuKeybind", {
	Default = "RightControl",
	NoUI = true,
	Text = "菜单快捷键"
})

MenuGroup:AddButton("❌ 停止脚本并关闭界面", function()
	stopAll()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Theme & Config Managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("ChickenHub")
SaveManager:SetFolder("ChickenHub/specific-game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

-- Create Top-Right Window Close Button (✕) next to drag handle
task.spawn(function()
	task.wait(0.5)
	pcall(function()
		local outer = Library.Outer
		if not outer then return end

		local oldBtn = outer:FindFirstChild("HeaderCloseButton", true)
		if oldBtn then oldBtn:Destroy() end

		local topContainer = outer:FindFirstChild("TopBar") or outer:FindFirstChild("Header") or outer

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "HeaderCloseButton"
		closeBtn.Size = UDim2.new(0, 22, 0, 22)
		closeBtn.Position = UDim2.new(1, -30, 0, 4)
		closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		closeBtn.Text = "✕"
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.TextSize = 13
		closeBtn.BorderSizePixel = 0
		closeBtn.ZIndex = 99999
		closeBtn.Parent = topContainer

		local corner = Instance.new("UICorner", closeBtn)
		corner.CornerRadius = UDim.new(0, 4)

		closeBtn.MouseButton1Click:Connect(function()
			stopAll()
			Library:Unload()
		end)
	end)
end)

-- Start Automation
startLoops()
