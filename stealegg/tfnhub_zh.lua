--[[
	████████╗███████╗███╗   ██╗    ██╗  ██╗██╗   ██╗██████╗
	╚══██╔══╝██╔════╝████╗  ██║    ██║  ██║██║   ██║██╔══██╗
	   ██║   █████╗  ██╔██╗ ██║    ███████║██║   ██║██████╔╝
	   ██║   ██╔══╝  ██║╚██╗██║    ██╔══██║██║   ██║██╔══██╗
	   ██║   ██║     ██║ ╚████║    ██║  ██║╚██████╔╝██████╔╝
	   ╚═╝   ╚═╝     ╚═╝  ╚═══╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

	TFN HUB — Steal An Egg（偷蛋）
	PlaceId 107778070777162  |  UI: WindUI (Footagesus)

	重要提示——请阅读：
	本游戏启用了反作弊（ObbyAntiTPClient、WalkSpeedGovernor、
	CharacterIntegrity、RF/RigSync/Reconcile）。使用 CFrame 传送和穿墙
	会触发 BAC-10518（“因作弊被移除”）并被踢出。
	因此 TFN HUB 默认使用正常移动：
	通过 PathfindingService + Humanoid:MoveTo，并遵循游戏
	授予的 WalkSpeed。“极速（风险）”模式存在，但默认关闭。
]]

----------------------------------------------------------------------
-- 启动 / 单例
----------------------------------------------------------------------
if _G.TFN_HUB_LOADED and _G.TFN_HUB_DESTROY then
	pcall(_G.TFN_HUB_DESTROY)
end
_G.TFN_HUB_LOADED = true

local function try(f, ...)
	local ok, r = pcall(f, ...)
	if ok then return r end
	return nil
end

----------------------------------------------------------------------
-- 服务
----------------------------------------------------------------------
local cloneref = (cloneref or clonereference or function(i) return i end)

local Players           = cloneref(game:GetService("Players"))
local RunService        = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace         = cloneref(game:GetService("Workspace"))
local CoreGui           = cloneref(game:GetService("CoreGui"))
local Pathfinding       = cloneref(game:GetService("PathfindingService"))
local StarterGui        = cloneref(game:GetService("StarterGui"))

local LP = Players.LocalPlayer

----------------------------------------------------------------------
-- 加载 WINDUI
----------------------------------------------------------------------
local WindUI
do
	local sources = {
		"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
		"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
	}
	for _, url in ipairs(sources) do
		local src = try(function() return game:HttpGet(url) end)
		if type(src) == "string" and #src > 5000 then
			local fn = (loadstring or load)(src)
			if fn then
				local ok, lib = pcall(fn)
				if ok and type(lib) == "table" and lib.CreateWindow then
					WindUI = lib
					break
				end
			end
		end
	end
end

if not WindUI then
	try(function()
		StarterGui:SetCore("SendNotification", {
			Title = "TFN HUB",
			Text = "WindUI 下载失败，请检查网络后重试。",
			Duration = 8,
		})
	end)
	warn("[TFN HUB] WindUI 加载失败。")
	return
end

----------------------------------------------------------------------
-- 配置
----------------------------------------------------------------------
local CFG = {
	-- 移动
	SafeMode        = true,   -- Pathfinding/MoveTo（不会触发反作弊）
	TurboMode       = false,  -- CFrame 步进（封禁风险）——默认关闭
	TurboSpeed      = 180,
	ReachRadius     = 8,      -- 视为“已到达”的距离
	TravelTimeout   = 45,     -- 每条路径的秒数

	-- 拾取
	AutoFarm        = false,
	AutoDeliver     = true,
	StealHoldTries  = 6,
	Delay           = 0.6,

	-- 守卫
	AvoidGuards     = true,
	GuardRadius     = 30,
	AntiRagdoll     = true,

	-- 筛选
	MinMoney        = 0,
	RarityFilter    = "全部",
	Search          = "",

	-- 视觉
	ESP             = false,
	ESPDistance     = false,

	-- 玩家
	NoclipRisky     = false,
	InfJump         = false,
}

local RARITY_COLORS = {
	common    = Color3.fromRGB(170, 178, 190),
	uncommon  = Color3.fromRGB(110, 220, 140),
	rare      = Color3.fromRGB( 90, 165, 255),
	epic      = Color3.fromRGB(190, 110, 255),
	legendary = Color3.fromRGB(255, 190,  70),
	mythic    = Color3.fromRGB(255,  95, 120),
	divine    = Color3.fromRGB(120, 255, 235),
	secret    = Color3.fromRGB(255, 255, 255),
	godly     = Color3.fromRGB(255, 140,  40),
	limited   = Color3.fromRGB(255,  80, 200),
	event     = Color3.fromRGB(255, 215,   0),
}
local RARITY_NAMES = {
	common = "普通", uncommon = "优秀", rare = "稀有", epic = "史诗",
	legendary = "传说", mythic = "神话", divine = "神圣", secret = "秘密",
	godly = "神级", limited = "限定", event = "活动",
}
local RARITY_FILTERS = {
	["全部"] = nil, ["普通"] = "Common", ["优秀"] = "Uncommon",
	["稀有"] = "Rare", ["史诗"] = "Epic", ["传说"] = "Legendary",
	["神话"] = "Mythic", ["神圣"] = "Divine", ["秘密"] = "Secret",
	["神级"] = "Godly", ["限定"] = "Limited", ["活动"] = "Event",
}
local RARITY_ORDER = {
	"全部", "普通", "优秀", "稀有", "史诗", "传说",
	"神话", "神圣", "秘密", "神级", "限定", "活动",
}

local function rarityName(raw)
	local value = tostring(raw or "Common")
	return RARITY_NAMES[value:lower()] or value
end

local ACCENT = Color3.fromHex("#8B5CF6")
local GREEN  = Color3.fromHex("#22C55E")
local RED    = Color3.fromHex("#EF4444")
local YELLOW = Color3.fromHex("#F59E0B")
local GREY   = Color3.fromHex("#83889E")

----------------------------------------------------------------------
-- 角色辅助函数
----------------------------------------------------------------------
local function char() return LP.Character end
local function hrp()
	local c = char()
	return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end
local function hum()
	local c = char()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function alive()
	local h = hum()
	return h and h.Health > 0
end

local function comma(n)
	n = tonumber(n) or 0
	local s = string.format("%d", math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	out = out:gsub("^%.", "")
	return out
end

local function short(n)
	n = tonumber(n) or 0
	local units = { {1e12,"T"}, {1e9,"B"}, {1e6,"M"}, {1e3,"K"} }
	for _, u in ipairs(units) do
		if n >= u[1] then return string.format("%.2f%s", n / u[1], u[2]) end
	end
	return comma(n)
end

local function parseNumber(txt)
	if type(txt) ~= "string" then return nil end
	local clean = txt:gsub("%s", "")
	local num, suf = clean:match("([%d%.,]+)%s*([KkMmBbTt]?)")
	if not num then return nil end
	num = num:gsub("%.(%d%d%d)", "%1"):gsub(",", ".")
	local v = tonumber(num)
	if not v then return nil end
	local mult = { k = 1e3, m = 1e6, b = 1e9, t = 1e12 }
	if suf and suf ~= "" then v = v * (mult[suf:lower()] or 1) end
	return v
end

local function notify(title, content, dur, icon)
	try(function()
		WindUI:Notify({
			Title = title or "TFN HUB",
			Content = content or "",
			Icon = icon or "egg",
			Duration = dur or 4,
		})
	end)
end

----------------------------------------------------------------------
-- 游戏远程对象（ReplicatedStorage.Packages.Networking）
----------------------------------------------------------------------
local Net = ReplicatedStorage:FindFirstChild("Packages")
Net = Net and Net:FindFirstChild("Networking")

local R = {
	Carry    = "RF/EggWorld/AskFieldEggCarry",
	Drop     = "RF/EggWorld/AskFieldEggDrop",
	Snapshot = "RF/EggWorld/AskFieldEggSnapshot",
	PlaceEgg = "RF/EggWorld/AskPlaceEgg",
	WearTool = "RF/EggWorld/AskWearTool",
	DoffTool = "RF/EggWorld/AskDoffTool",
	Hatch    = "RF/EggWorld/AskHatch",
	Finish   = "RF/EggWorld/AskFinishHatch",
	SellAll  = "RE/PetSatchel/SellEveryPet",
	BaseUp   = "RE/Homestead/AskBaseTierRaise",
	Nearby   = "RE/Homestead/AskNearbyPurchase",
}

local function remote(name)
	if not Net then return nil end
	return Net:FindFirstChild(name)
end

local function invoke(name, ...)
	local rf = remote(name)
	if not rf then return nil, "未找到远程对象" end
	if rf:IsA("RemoteFunction") then
		local ok, res = pcall(function(...) return rf:InvokeServer(...) end, ...)
		return ok and res or nil, ok and nil or tostring(res)
	elseif rf:IsA("RemoteEvent") then
		local ok, err = pcall(function(...) rf:FireServer(...) end, ...)
		return ok, ok and nil or tostring(err)
	end
	return nil, "未知类型"
end

----------------------------------------------------------------------
-- 扫描蛋
----------------------------------------------------------------------
local MONEY_KEYS = {
	"income","money","cash","earnings","profit","persecond",
	"moneypersecond","generation","rate","value","price","worth","payout",
}
local RARITY_KEYS = { "rarity","tier","grade","quality" }

local function keyMatches(key, list)
	local k = tostring(key):lower():gsub("[^%a]", "")
	for _, w in ipairs(list) do
		if k:find(w, 1, true) then return true end
	end
	return false
end

local function readFromAttributes(inst)
	local money, rarity
	local attrs = try(function() return inst:GetAttributes() end)
	if attrs then
		for k, v in pairs(attrs) do
			if not money and type(v) == "number" and keyMatches(k, MONEY_KEYS) then money = v end
			if not rarity and type(v) == "string" and keyMatches(k, RARITY_KEYS) then rarity = v end
			if not money and type(v) == "string" and keyMatches(k, MONEY_KEYS) then money = parseNumber(v) end
		end
	end
	for _, v in ipairs(inst:GetChildren()) do
		if v:IsA("ValueBase") then
			if not money and keyMatches(v.Name, MONEY_KEYS) then
				money = (type(v.Value) == "number") and v.Value or parseNumber(tostring(v.Value))
			end
			if not rarity and keyMatches(v.Name, RARITY_KEYS) then rarity = tostring(v.Value) end
		end
	end
	return money, rarity
end

local function readFromBillboards(root)
	local money, rarity, name
	local descendants = try(function() return root:GetDescendants() end) or {}
	for _, d in ipairs(descendants) do
		if d:IsA("TextLabel") or d:IsA("TextBox") then
			local t = d.Text or ""
			if t ~= "" then
				local low = t:lower()
				if not money and (t:find("%$") or low:find("/s")) then
					money = parseNumber(t)
				end
				if not rarity then
					for key in pairs(RARITY_COLORS) do
						if low:find(key, 1, true) then
							rarity = key:sub(1, 1):upper() .. key:sub(2)
							break
						end
					end
				end
				if not name and #t > 2 and not t:find("%$") and not low:find("/s") and not tonumber(t) then
					local ln = d.Name:lower()
					if ln:find("name") or ln:find("title") or ln:find("egg") then name = t end
				end
			end
		end
	end
	return money, rarity, name
end

local function isCarryPrompt(pr)
	if not pr:IsA("ProximityPrompt") then return false end
	local n = (pr.Name or ""):lower()
	if n:find("carry") or n:find("steal") then return true end
	local a = ((pr.ActionText or "") .. " " .. (pr.ObjectText or "")):lower()
	return a:find("steal") ~= nil or a:find("carry") ~= nil or a:find("pegar") ~= nil or a:find("roub") ~= nil
end

local function eggModelFromPrompt(prompt)
	local p = prompt.Parent
	local node = p
	for _ = 1, 5 do
		if not node or node == Workspace then break end
		if node:IsA("Model") then
			local hasPart = node:FindFirstChildWhichIsA("BasePart", true)
			if hasPart then return node end
		end
		node = node.Parent
	end
	local pos = (p and p:IsA("BasePart")) and p.Position or nil
	if not pos then return nil end
	local eggsFolder = Workspace:FindFirstChild("Eggs")
	if not eggsFolder then return nil end
	local best, bestD = nil, 35
	for _, m in ipairs(eggsFolder:GetChildren()) do
		local pv = try(function() return m:GetPivot().Position end)
		if pv then
			local d = (pv - pos).Magnitude
			if d < bestD then best, bestD = m, d end
		end
	end
	return best
end

local Eggs = {}

local function scanEggs()
	local list, seen = {}, {}

	local function push(model, prompt, part)
		if not model or seen[model] then return end
		seen[model] = true
		local pos = try(function()
			return (part and part.Position) or model:GetPivot().Position
		end)
		if not pos then return end

		local money, rarity = readFromAttributes(model)
		local bMoney, bRarity, bName = readFromBillboards(model)
		money  = money  or bMoney
		rarity = rarity or bRarity

		if (not money or not rarity) and prompt and prompt.Parent then
			local m2, r2 = readFromAttributes(prompt.Parent)
			money  = money  or m2
			rarity = rarity or r2
			local m3, r3 = readFromBillboards(prompt.Parent)
			money  = money  or m3
			rarity = rarity or r3
		end

		local name = model:GetAttribute("EggName") or model:GetAttribute("AssetName")
			or model:GetAttribute("DisplayName") or bName or model.Name

		table.insert(list, {
			model  = model,
			prompt = prompt,
			part   = part,
			pos    = pos,
			name   = tostring(name):gsub("^%s+", ""):gsub("%s+$", ""),
			money  = money or 0,
			rarity = rarity or "Common",
		})
	end

	-- 主要来源：携带交互提示（SmartPromptPart > CarryAreaEgg）
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") and isCarryPrompt(d) then
			local part = d.Parent
			local model = eggModelFromPrompt(d)
			push(model or part, d, (part and part:IsA("BasePart")) and part or nil)
		end
	end

	-- 备用来源：Workspace.Eggs
	local ef = Workspace:FindFirstChild("Eggs")
	if ef then
		for _, m in ipairs(ef:GetChildren()) do
			if m:IsA("Model") or m:IsA("BasePart") then
				local pr
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("ProximityPrompt") then pr = d break end
				end
				push(m, pr, m:IsA("BasePart") and m or nil)
			end
		end
	end

	table.sort(list, function(a, b)
		if a.money == b.money then return a.name < b.name end
		return a.money > b.money
	end)

	for i, e in ipairs(list) do e.id = i end
	Eggs = list
	return list
end

local function passesFilter(e)
	if e.money < (CFG.MinMoney or 0) then return false end
	if CFG.RarityFilter ~= "全部" then
		local selected = RARITY_FILTERS[CFG.RarityFilter] or CFG.RarityFilter
		if (e.rarity or ""):lower() ~= selected:lower() then return false end
	end
	if CFG.Search ~= "" then
		if not e.name:lower():find(CFG.Search:lower(), 1, true) then return false end
	end
	return true
end

local function filteredEggs()
	local out = {}
	for _, e in ipairs(Eggs) do
		if passesFilter(e) then table.insert(out, e) end
	end
	return out
end

----------------------------------------------------------------------
-- 基地 / 地块
----------------------------------------------------------------------
local function myPlot()
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return nil end
	for _, p in ipairs(plots:GetChildren()) do
		local owner = p:GetAttribute("Owner") or p:GetAttribute("OwnerUserId")
			or p:GetAttribute("OwnerId") or p:GetAttribute("Player")
		if owner and (tostring(owner) == tostring(LP.UserId) or tostring(owner) == LP.Name) then
			return p
		end
		local sign = p:FindFirstChild("PlotSign", true)
		if sign then
			for _, d in ipairs(sign:GetDescendants()) do
				if d:IsA("TextLabel") and d.Text
					and (d.Text:find(LP.Name, 1, true) or d.Text:find(LP.DisplayName, 1, true)) then
					return p
				end
			end
		end
	end
	return nil
end

local function basePosition()
	local p = myPlot()
	if p then
		local pt = p:FindFirstChild("CenterPoint") or p:FindFirstChild("SpawnPoint")
		if pt and pt:IsA("BasePart") then return pt.Position end
		local pv = try(function() return p:GetPivot().Position end)
		if pv then return pv end
	end
	local objs = Workspace:FindFirstChild("__OBJECTS")
	local dh = objs and objs:FindFirstChild("DeliveryHitbox")
	if dh and dh:IsA("BasePart") then return dh.Position end
	local areas = objs and objs:FindFirstChild("Areas")
	local sp = areas and areas:FindFirstChild("StartArea")
	if sp and sp:IsA("BasePart") then return sp.Position end
	local spawn = Workspace:FindFirstChild("SpawnLocation", true)
	if spawn and spawn:IsA("BasePart") then return spawn.Position end
	return nil
end

----------------------------------------------------------------------
-- 守卫
----------------------------------------------------------------------
local function guardModels()
	local out = {}
	local function add(folder)
		if not folder then return end
		local ds = try(function() return folder:GetDescendants() end) or {}
		for _, m in ipairs(ds) do
			if m:IsA("Model") and m ~= char() then
				local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
				if root then table.insert(out, root) end
			end
		end
	end
	add(Workspace:FindFirstChild("_Guards"))
	local objs = Workspace:FindFirstChild("__OBJECTS")
	add(objs and objs:FindFirstChild("Sentries"))
	add(Workspace:FindFirstChild("Npcs"))
	return out
end

local GuardCache, lastGuardScan = {}, 0
local function guardsNear(pos, radius)
	if tick() - lastGuardScan > 2 then
		lastGuardScan = tick()
		GuardCache = guardModels()
	end
	local near = {}
	for _, root in ipairs(GuardCache) do
		if root.Parent then
			local d = (root.Position - pos).Magnitude
			if d < radius then table.insert(near, { root = root, dist = d }) end
		end
	end
	return near
end

----------------------------------------------------------------------
-- 移动
----------------------------------------------------------------------
local Travelling, CancelTravel = false, false
local StatusFn = function() end

-- 路径上有守卫时进行侧向绕行
local function dodgeOffset(target)
	local r = hrp()
	if not r then return target end
	local near = guardsNear(r.Position, CFG.GuardRadius)
	if #near == 0 then return target end
	local away = Vector3.new()
	for _, g in ipairs(near) do
		local dir = (r.Position - g.root.Position)
		if dir.Magnitude > 0.1 then
			away = away + dir.Unit * (CFG.GuardRadius - g.dist)
		end
	end
	if away.Magnitude < 0.1 then return target end
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.1 then return target end
	return target + away.Unit * 14
end

-- 稳妥移动：PathfindingService + Humanoid:MoveTo
local function walkTo(targetPos)
	local h, r = hum(), hrp()
	if not (h and r) then return false end

	local path = Pathfinding:CreatePath({
		AgentRadius        = 3,
		AgentHeight        = 6,
		AgentCanJump       = true,
		AgentCanClimb      = false,
		WaypointSpacing    = 6,
		Costs              = {},
	})

	local ok = pcall(function() path:ComputeAsync(r.Position, targetPos) end)
	local waypoints = (ok and path.Status == Enum.PathStatus.Success) and path:GetWaypoints() or nil

	local t0 = tick()

	if waypoints and #waypoints > 1 then
		for i = 2, #waypoints do
			if CancelTravel or not alive() then return false end
			if tick() - t0 > CFG.TravelTimeout then return false end

			local wp = waypoints[i]
			local goal = wp.Position
			if CFG.AvoidGuards then goal = dodgeOffset(goal) end

			if wp.Action == Enum.PathWaypointAction.Jump then
				h:ChangeState(Enum.HumanoidStateType.Jumping)
			end

			h:MoveTo(goal)
			local reached = h.MoveToFinished:Wait()
			if not reached then
				-- 卡住时：从当前位置重新计算路径
				break
			end
		end
	end

	-- 最后一段直接接近（覆盖寻路失败及末段路径）
	while true do
		if CancelTravel or not alive() then return false end
		local rr = hrp()
		if not rr then return false end
		local dist = (Vector3.new(rr.Position.X, 0, rr.Position.Z)
			- Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
		if dist <= CFG.ReachRadius then return true end
		if tick() - t0 > CFG.TravelTimeout then return false end

		local goal = targetPos
		if CFG.AvoidGuards then goal = dodgeOffset(goal) end

		local hh = hum()
		if not hh then return false end
		hh:MoveTo(goal)
		task.wait(0.35)
	end
end

-- 极速移动（封禁风险）：使用短距离 CFrame 步进
local function turboTo(targetPos)
	local t0 = tick()
	while true do
		if CancelTravel or not alive() then return false end
		local r = hrp()
		if not r then return false end
		local delta = (targetPos + Vector3.new(0, 3, 0)) - r.Position
		local dist = delta.Magnitude
		if dist <= CFG.ReachRadius then return true end
		if tick() - t0 > CFG.TravelTimeout then return false end
		local step = math.min(CFG.TurboSpeed / 60, dist)
		r.CFrame = CFrame.new(r.Position + delta.Unit * step)
		r.AssemblyLinearVelocity = Vector3.new()
		RunService.Heartbeat:Wait()
	end
end

local function travelTo(pos)
	Travelling = true
	CancelTravel = false
	local ok
	if CFG.TurboMode then
		ok = turboTo(pos)
	else
		ok = walkTo(pos)
	end
	Travelling = false
	return ok
end

----------------------------------------------------------------------
-- 拾取 / 运送
----------------------------------------------------------------------
local Busy = false

local function isCarrying()
	local c = char()
	if not c then return false end
	for _, t in ipairs(c:GetChildren()) do
		if t:IsA("Tool") then return true end
	end
	return false
end

local function firePrompt(pr)
	if not pr or not pr.Parent then return false end
	local oldHold = pr.HoldDuration
	local oldDist = pr.MaxActivationDistance
	try(function() pr.HoldDuration = 0 end)
	try(function() pr.MaxActivationDistance = math.max(oldDist, 20) end)
	local fired = false
	if fireproximityprompt then
		try(function() fireproximityprompt(pr, 1) end)
		fired = true
	end
	try(function() pr.HoldDuration = oldHold end)
	try(function() pr.MaxActivationDistance = oldDist end)
	return fired
end

local function grabEgg(egg)
	-- 1）交互提示（游戏的常规路径，不触发标记）
	for _ = 1, CFG.StealHoldTries do
		if isCarrying() then return true end
		if egg.prompt and egg.prompt.Parent then
			firePrompt(egg.prompt)
		else
			-- 在模型中重新查找交互提示
			if egg.model and egg.model.Parent then
				for _, d in ipairs(egg.model:GetDescendants()) do
					if d:IsA("ProximityPrompt") then egg.prompt = d break end
				end
			end
		end
		task.wait(0.3)
		if egg.model and not egg.model.Parent then return true end
	end

	-- 2）备用方案：远程调用（签名未知，尝试多种参数）
	if not isCarrying() and egg.model then
		local id = egg.model:GetAttribute("Id") or egg.model:GetAttribute("EggId")
			or egg.model:GetAttribute("Guid") or egg.model:GetAttribute("Uid")
			or egg.model.Name
		invoke(R.Carry, id)
		task.wait(0.2)
		if not isCarrying() then invoke(R.Carry, egg.model) end
		task.wait(0.2)
		if not isCarrying() then invoke(R.Carry) end
	end

	return isCarrying() or (egg.model and not egg.model.Parent) or false
end

local function deliverEgg()
	local base = basePosition()
	if not base then return false, "未找到基地" end

	StatusFn("正在返回基地……", ACCENT)
	local ok = travelTo(base)
	if not ok then return false, "未到达基地" end
	task.wait(0.4)

	-- 地块内的交互提示（运送 / 放置）
	local plot = myPlot()
	if plot then
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				firePrompt(d)
				task.wait(0.15)
				if not isCarrying() then break end
			end
		end
	end

	-- 基地附近的独立交互提示
	if isCarrying() then
		local r = hrp()
		if r then
			for _, d in ipairs(Workspace:GetDescendants()) do
				if d:IsA("ProximityPrompt") and d.Parent and d.Parent:IsA("BasePart") then
					if (d.Parent.Position - r.Position).Magnitude < 25 then
						firePrompt(d)
						task.wait(0.12)
						if not isCarrying() then break end
					end
				end
			end
		end
	end

	-- 最后手段：调用放置远程对象
	if isCarrying() then
		local cf = CFrame.new(base + Vector3.new(0, 3, 0))
		invoke(R.PlaceEgg, cf)
		task.wait(0.2)
		if isCarrying() then invoke(R.PlaceEgg, cf, 1) end
	end

	return not isCarrying()
end

local function stealEgg(egg)
	if Busy then
		notify("TFN HUB", "已有操作正在进行。", 3, "clock")
		return
	end
	if not egg or not egg.model or not egg.model.Parent then
		notify("TFN HUB", "这个蛋已不存在，请刷新列表。", 4, "triangle-alert")
		return
	end
	Busy = true

	StatusFn(("正在前往 %s……"):format(egg.name), ACCENT)
	local reached = travelTo(egg.pos)
	if not reached then
		StatusFn("未能到达蛋的位置。", RED)
		Busy = false
		return
	end

	StatusFn("正在拾取……", GREEN)
	local got = grabEgg(egg)
	if not got then
		StatusFn("未能拾取这个蛋。", RED)
		Busy = false
		return
	end

	if CFG.AutoDeliver then
		local delivered = deliverEgg()
		StatusFn(delivered and ("已送达：" .. egg.name) or "已拾取，但运送失败。",
			delivered and GREEN or YELLOW)
	else
		StatusFn("已拾取：" .. egg.name, GREEN)
	end

	task.wait(CFG.Delay)
	Busy = false
end

----------------------------------------------------------------------
-- ESP
----------------------------------------------------------------------
local espFolder
local function clearESP()
	if espFolder then
		espFolder:Destroy()
		espFolder = nil
	end
end

local function refreshESP()
	clearESP()
	if not CFG.ESP then return end
	espFolder = Instance.new("Folder")
	espFolder.Name = "TFN_ESP"
	espFolder.Parent = (gethui and gethui()) or CoreGui

	for _, e in ipairs(filteredEggs()) do
		local adornee = e.part or (e.model and e.model:FindFirstChildWhichIsA("BasePart", true))
		if adornee then
			local bb = Instance.new("BillboardGui")
			bb.Name = "TFN_" .. e.name
			bb.Adornee = adornee
			bb.Size = UDim2.new(0, 210, 0, 44)
			bb.StudsOffset = Vector3.new(0, 4, 0)
			bb.AlwaysOnTop = true
			bb.MaxDistance = 800
			bb.Parent = espFolder

			local lb = Instance.new("TextLabel")
			lb.BackgroundTransparency = 1
			lb.Size = UDim2.fromScale(1, 1)
			lb.Font = Enum.Font.GothamBold
			lb.TextSize = 13
			lb.TextStrokeTransparency = 0.35
			lb.RichText = true
			lb.TextColor3 = RARITY_COLORS[(e.rarity or ""):lower()] or Color3.new(1, 1, 1)
			lb.Text = ("%s\n$%s/s"):format(e.name, short(e.money))
			lb.Parent = bb
			e.espLabel = lb
		end
	end
end

----------------------------------------------------------------------
-- 蛋的预览图（Viewport 中的 3D 模型）
----------------------------------------------------------------------
local function eggPreviewModel(egg)
	local src
	-- 1）Workspace 中蛋自身的模型
	if egg and egg.model and egg.model:IsA("Model") then
		src = egg.model
	end
	-- 2）ReplicatedStorage.Assets.Models.Eggs 中的资源
	if egg then
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local models = assets and assets:FindFirstChild("Models")
		local eggsF  = models and models:FindFirstChild("Eggs")
		if eggsF then
			local match = eggsF:FindFirstChild(egg.name) or eggsF:FindFirstChild(egg.model and egg.model.Name or "")
			if match then src = match end
		end
	end

	local clone
	if src then
		clone = try(function()
			local c = src:Clone()
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("ProximityPrompt") or d:IsA("Script") or d:IsA("LocalScript")
					or d:IsA("BillboardGui") or d:IsA("Sound") or d:IsA("ParticleEmitter") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			if c:IsA("BasePart") then
				local m = Instance.new("Model")
				c.Parent = m
				m.PrimaryPart = c
				return m
			end
			return c
		end)
	end

	if not clone then
		clone = Instance.new("Model")
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(4, 5, 4)
		p.Color = ACCENT
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.Parent = clone
		clone.PrimaryPart = p
	end

	return clone
end

----------------------------------------------------------------------
-- UI (WindUI)
----------------------------------------------------------------------
local Window = WindUI:CreateWindow({
	Title = "TFN HUB",
	Icon = "egg",
	Author = "Steal An Egg（偷蛋）",
	Folder = "TFNHub",
	Size = UDim2.fromOffset(600, 420),
	Theme = "Dark",
	Transparent = true,
	NewElements = true,
	HideSearchBar = false,
	Resizable = true,
	SideBarWidth = 190,
	Background = "",
	OpenButton = {
		Title = "TFN HUB",
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		Color = ColorSequence.new(Color3.fromHex("#8B5CF6"), Color3.fromHex("#22D3EE")),
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
})

try(function()
	Window:Tag({ Title = "v2.0", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })
	Window:Tag({ Title = "稳妥模式", Icon = "shield-check", Color = GREEN, Border = true })
end)

local SecMain   = Window:Section({ Title = "主要功能" })
local SecPlayer = Window:Section({ Title = "玩家" })
local SecInfo   = Window:Section({ Title = "关于" })

----------------------------------------------------------------------
-- 标签页：蛋
----------------------------------------------------------------------
local TabEggs = SecMain:Tab({
	Title = "蛋",
	Desc = "选择蛋后由脚本自动寻找",
	Icon = "egg",
	IconColor = ACCENT,
	IconShape = "Square",
	Border = true,
})

local Selected = nil
local EggDropdown, EggViewport, EggInfo, StatusPara

TabEggs:Section({ Title = "已选中的蛋" })

EggViewport = TabEggs:Viewport({
	Object = eggPreviewModel(nil),
	Height = 170,
	Interactive = true,
	Focused = true,
})

EggInfo = TabEggs:Paragraph({
	Title = "尚未选择蛋",
	Desc = "点击“扫描蛋”，然后在下方列表中选择。",
})

TabEggs:Space({ Columns = 2 })

local function setSelected(egg)
	Selected = egg
	if not egg then
		try(function() EggInfo:SetTitle("尚未选择蛋") end)
		try(function() EggInfo:SetDesc("点击“扫描蛋”，然后在下方列表中选择。") end)
		return
	end
	local r = hrp()
	local dist = r and math.floor((egg.pos - r.Position).Magnitude) or 0
	try(function() EggInfo:SetTitle(egg.name) end)
	try(function()
		EggInfo:SetDesc(("收益：$%s/秒   •   稀有度：%s   •   距离：%d 格")
			:format(short(egg.money), rarityName(egg.rarity), dist))
	end)
	try(function()
		EggViewport:SetObject(eggPreviewModel(egg), false)
		EggViewport:Focus()
	end)
end

local function dropdownValues()
	local list = filteredEggs()
	local vals = {}
	for _, e in ipairs(list) do
		local r = hrp()
		local dist = r and math.floor((e.pos - r.Position).Magnitude) or 0
		table.insert(vals, {
			Title = ("%s  —  $%s/s"):format(e.name, short(e.money)),
			Desc = ("%s  •  %d 格"):format(rarityName(e.rarity), dist),
			Icon = "egg",
			Callback = function() setSelected(e) end,
		})
	end
	if #vals == 0 then
		table.insert(vals, {
			Title = "未找到蛋",
			Desc = "点击“扫描蛋”或放宽筛选条件",
			Icon = "search-x",
			Callback = function() end,
		})
	end
	return vals
end

local function rebuildDropdown()
	if not EggDropdown then return end
	local vals = dropdownValues()
	local applied = try(function() EggDropdown:Refresh(vals) end)
	if applied == nil then
		try(function() EggDropdown:SetValues(vals) end)
	end
end

TabEggs:Section({ Title = "蛋列表" })

EggDropdown = TabEggs:Dropdown({
	Title = "选择蛋",
	Desc = "按收益从高到低排列",
	Icon = "list",
	Values = dropdownValues(),
	Value = nil,
	AllowNone = true,
})

TabEggs:Button({
	Title = "扫描蛋",
	Desc = "更新列表、预览图和 ESP",
	Icon = "radar",
	Callback = function()
		scanEggs()
		rebuildDropdown()
		if CFG.ESP then refreshESP() end
		notify("TFN HUB", ("找到 %d 个蛋。"):format(#Eggs), 3, "radar")
	end,
})

TabEggs:Space()

TabEggs:Button({
	Title = "拾取选中的蛋",
	Desc = "前往蛋的位置，拾取后送回基地",
	Icon = "hand-coins",
	Color = ACCENT,
	Justify = "Center",
	IconAlign = "Left",
	Callback = function()
		if not Selected then
			notify("TFN HUB", "请先选择一个蛋。", 3, "triangle-alert")
			return
		end
		task.spawn(stealEgg, Selected)
	end,
})

TabEggs:Space()

TabEggs:Button({
	Title = "拾取最值钱的蛋",
	Desc = "拾取筛选结果中 $/秒 最高的蛋",
	Icon = "trophy",
	Callback = function()
		scanEggs()
		rebuildDropdown()
		local list = filteredEggs()
		if #list == 0 then
			notify("TFN HUB", "没有蛋符合筛选条件。", 3, "search-x")
			return
		end
		setSelected(list[1])
		task.spawn(stealEgg, list[1])
	end,
})

TabEggs:Space()

TabEggs:Button({
	Title = "停止",
	Desc = "取消当前路径和自动挂机",
	Icon = "octagon-x",
	Color = RED,
	Justify = "Center",
	Callback = function()
		CancelTravel = true
		CFG.AutoFarm = false
		Busy = false
		local h = hum()
		if h then
			local r = hrp()
			if r then h:MoveTo(r.Position) end
		end
		StatusFn("已由用户停止。", YELLOW)
	end,
})

TabEggs:Space({ Columns = 2 })
TabEggs:Section({ Title = "状态" })

StatusPara = TabEggs:Paragraph({
	Title = "等待中",
	Desc = "当前没有进行中的操作。",
})

StatusFn = function(text, _color)
	try(function() StatusPara:SetTitle(text) end)
	try(function()
		StatusPara:SetDesc(("模式：%s   •   蛋：%d   •   正在携带：%s")
			:format(CFG.TurboMode and "极速（风险）" or "稳妥", #Eggs, isCarrying() and "是" or "否"))
	end)
end

----------------------------------------------------------------------
-- 标签页：自动挂机
----------------------------------------------------------------------
local TabFarm = SecMain:Tab({
	Title = "自动挂机",
	Desc = "自动循环拾取",
	Icon = "repeat",
	IconColor = GREEN,
	IconShape = "Square",
	Border = true,
})

TabFarm:Section({ Title = "循环" })

TabFarm:Toggle({
	Title = "自动挂机",
	Desc = "依次拾取筛选后的蛋，按价值从高到低排列",
	Value = false,
	Callback = function(v)
		CFG.AutoFarm = v
		if v then
			notify("TFN HUB", "自动挂机已开启。", 3, "repeat")
		end
	end,
})

TabFarm:Space()

TabFarm:Toggle({
	Title = "送回基地",
	Desc = "拾取后返回并放到自己的地块",
	Value = CFG.AutoDeliver,
	Callback = function(v) CFG.AutoDeliver = v end,
})

TabFarm:Space()

TabFarm:Slider({
	Title = "蛋之间的延迟",
	Desc = "每次拾取之间暂停的秒数",
	Step = 0.1,
	Value = { Min = 0, Max = 5, Default = CFG.Delay },
	Callback = function(v) CFG.Delay = v end,
})

TabFarm:Space({ Columns = 2 })
TabFarm:Section({ Title = "筛选" })

TabFarm:Input({
	Title = "按名称搜索",
	Desc = "留空以显示全部",
	Placeholder = "例如：Golden",
	Callback = function(v)
		CFG.Search = tostring(v or "")
		rebuildDropdown()
	end,
})

TabFarm:Space()

TabFarm:Dropdown({
	Title = "稀有度",
	Desc = "筛选列表和自动挂机目标",
	Values = RARITY_ORDER,
	Value = "全部",
	Callback = function(v)
		CFG.RarityFilter = tostring(v)
		rebuildDropdown()
		if CFG.ESP then refreshESP() end
	end,
})

TabFarm:Space()

TabFarm:Input({
	Title = "最低收益（$/秒）",
	Desc = "忽略低于此数值的蛋；支持 1k、2.5m",
	Placeholder = "0",
	Callback = function(v)
		CFG.MinMoney = parseNumber(tostring(v)) or 0
		rebuildDropdown()
		if CFG.ESP then refreshESP() end
	end,
})

TabFarm:Space({ Columns = 2 })
TabFarm:Section({ Title = "其他" })

TabFarm:Button({
	Title = "出售所有宠物",
	Desc = "RE/PetSatchel/SellEveryPet",
	Icon = "dollar-sign",
	Callback = function()
		local ok = invoke(R.SellAll)
		notify("TFN HUB", ok ~= nil and "已发送出售请求。" or "远程对象未响应。", 3, "dollar-sign")
	end,
})

TabFarm:Space()

TabFarm:Button({
	Title = "孵化地块中的蛋",
	Desc = "AskHatch + AskFinishHatch",
	Icon = "sparkles",
	Callback = function()
		invoke(R.Hatch)
		task.wait(0.3)
		invoke(R.Finish)
		notify("TFN HUB", "已发送孵化请求。", 3, "sparkles")
	end,
})

----------------------------------------------------------------------
-- 标签页：移动
----------------------------------------------------------------------
local TabMove = SecPlayer:Tab({
	Title = "移动",
	Desc = "脚本如何移动",
	Icon = "footprints",
	IconColor = Color3.fromHex("#257AF7"),
	IconShape = "Square",
	Border = true,
})

TabMove:Section({
	Title = "你之前发送的 BAC-10518 报错是反作弊处罚，并非界面错误。\n游戏会检测 CFrame 传送和穿墙，因此默认模式使用 Pathfinding 正常行走。",
	TextSize = 15,
	TextTransparency = 0.3,
	FontWeight = Enum.FontWeight.Medium,
})

TabMove:Space({ Columns = 2 })

TabMove:Toggle({
	Title = "极速（封禁风险）",
	Desc = "通过 CFrame 移动，速度快得多，但此前正是它导致你被踢出。相关后果由使用者承担。",
	Value = false,
	Callback = function(v)
		CFG.TurboMode = v
		if v then
			notify("TFN HUB", "极速模式已开启，存在触发 BAC-10518 并被踢出的风险。", 7, "triangle-alert")
		else
			notify("TFN HUB", "极速模式已关闭，稳妥移动已启用。", 3, "shield-check")
		end
	end,
})

TabMove:Space()

TabMove:Slider({
	Title = "极速模式速度",
	Desc = "每秒移动格数（仅在极速模式开启时生效）",
	Step = 10,
	Value = { Min = 60, Max = 400, Default = CFG.TurboSpeed },
	Callback = function(v) CFG.TurboSpeed = v end,
})

TabMove:Space()

TabMove:Slider({
	Title = "路径超时",
	Desc = "经过 X 秒后放弃路径",
	Step = 5,
	Value = { Min = 15, Max = 120, Default = CFG.TravelTimeout },
	Callback = function(v) CFG.TravelTimeout = v end,
})

TabMove:Space({ Columns = 2 })
TabMove:Section({ Title = "守卫 / NPC" })

TabMove:Toggle({
	Title = "绕开守卫",
	Desc = "重新规划路径，从 NPC 旁边绕行而非直接穿过",
	Value = CFG.AvoidGuards,
	Callback = function(v) CFG.AvoidGuards = v end,
})

TabMove:Space()

TabMove:Slider({
	Title = "检测半径",
	Desc = "在多远处开始绕开守卫",
	Step = 2,
	Value = { Min = 10, Max = 80, Default = CFG.GuardRadius },
	Callback = function(v) CFG.GuardRadius = v end,
})

TabMove:Space()

TabMove:Toggle({
	Title = "防布娃娃",
	Desc = "被守卫击倒后让角色重新站起（稳妥）",
	Value = CFG.AntiRagdoll,
	Callback = function(v) CFG.AntiRagdoll = v end,
})

TabMove:Space({ Columns = 2 })
TabMove:Section({ Title = "快捷操作" })

TabMove:Button({
	Title = "前往我的基地",
	Icon = "house",
	Callback = function()
		local b = basePosition()
		if not b then
			notify("TFN HUB", "未找到你的基地或地块。", 3, "triangle-alert")
			return
		end
		task.spawn(function()
			StatusFn("正在前往基地……", ACCENT)
			local ok = travelTo(b)
			StatusFn(ok and "已到达基地。" or "未到达基地。", ok and GREEN or RED)
		end)
	end,
})

TabMove:Space()

TabMove:Button({
	Title = "放下正在携带的蛋",
	Icon = "package-open",
	Callback = function()
		invoke(R.Drop)
		notify("TFN HUB", "已发送放下请求。", 3, "package-open")
	end,
})

----------------------------------------------------------------------
-- 标签页：视觉
----------------------------------------------------------------------
local TabVisual = SecPlayer:Tab({
	Title = "视觉",
	Desc = "ESP 与屏幕信息",
	Icon = "eye",
	IconColor = YELLOW,
	IconShape = "Square",
	Border = true,
})

TabVisual:Section({ Title = "ESP" })

TabVisual:Toggle({
	Title = "蛋 ESP",
	Desc = "在每个蛋上方显示名称和 $/秒（仅客户端显示）",
	Value = false,
	Callback = function(v)
		CFG.ESP = v
		if v then
			if #Eggs == 0 then scanEggs() end
			refreshESP()
		else
			clearESP()
		end
	end,
})

TabVisual:Space()

TabVisual:Toggle({
	Title = "在 ESP 中显示距离",
	Desc = "实时更新距离",
	Value = false,
	Callback = function(v) CFG.ESPDistance = v end,
})

TabVisual:Space({ Columns = 2 })
TabVisual:Section({ Title = "玩家功能（谨慎使用）" })

TabVisual:Toggle({
	Title = "穿墙（风险）",
	Desc = "穿过墙壁，可能被 CharacterIntegrity 检测；默认关闭。",
	Value = false,
	Callback = function(v)
		CFG.NoclipRisky = v
		if v then notify("TFN HUB", "穿墙已开启，存在被踢出的风险。", 6, "triangle-alert") end
	end,
})

TabVisual:Space()

TabVisual:Toggle({
	Title = "无限跳跃（风险）",
	Desc = "可在空中跳跃，也可能触发检测标记。",
	Value = false,
	Callback = function(v) CFG.InfJump = v end,
})

----------------------------------------------------------------------
-- 标签页：关于
----------------------------------------------------------------------
local TabAbout = SecInfo:Tab({
	Title = "关于",
	Desc = "信息与诊断",
	Icon = "info",
	IconColor = GREY,
	IconShape = "Square",
	Border = true,
})

TabAbout:Section({ Title = "TFN HUB" })

TabAbout:Section({
	Title = "适用于 Steal An Egg（PlaceId 107778070777162）。\n界面：WindUI。面向 Arceus X 和移动端执行器测试。\n\n此前的 \"You have been removed for cheating | CODE BAC-10518\" 并非界面错误，而是游戏反作弊对 CFrame 传送的响应。本版本默认通过 Pathfinding 行走，风险有所降低。",
	TextSize = 15,
	TextTransparency = 0.35,
	FontWeight = Enum.FontWeight.Medium,
})

TabAbout:Space({ Columns = 2 })

local DiagPara = TabAbout:Paragraph({
	Title = "诊断",
	Desc = "点击“运行诊断”。",
})

TabAbout:Button({
	Title = "运行诊断",
	Desc = "检查远程对象、地块和交互提示",
	Icon = "stethoscope",
	Callback = function()
		local lines = {}
		table.insert(lines, ("网络模块：%s"):format(Net and "正常" or "未找到"))
		for k, v in pairs(R) do
			table.insert(lines, ("%s: %s"):format(k, remote(v) and "OK" or "缺失"))
		end
		table.insert(lines, ("地块：%s"):format(myPlot() and "已找到" or "未找到"))
		table.insert(lines, ("基地：%s"):format(basePosition() and "正常" or "未找到"))
		table.insert(lines, ("扫描到的蛋：%d"):format(#Eggs))
		table.insert(lines, ("fireproximityprompt: %s"):format(fireproximityprompt and "可用" or "缺失"))
		try(function() DiagPara:SetDesc(table.concat(lines, "\n")) end)
		notify("TFN HUB", "诊断已更新。", 3, "stethoscope")
	end,
})

TabAbout:Space({ Columns = 2 })

TabAbout:Button({
	Title = "关闭 TFN HUB",
	Desc = "移除界面并停止所有循环",
	Icon = "shredder",
	Color = RED,
	Justify = "Center",
	Callback = function()
		if _G.TFN_HUB_DESTROY then _G.TFN_HUB_DESTROY() end
	end,
})

----------------------------------------------------------------------
-- 循环任务
----------------------------------------------------------------------
local Running = true
local Conns = {}

-- 防布娃娃 + 穿墙 + 无限跳跃
table.insert(Conns, RunService.Stepped:Connect(function()
	if not Running then return end

	if CFG.AntiRagdoll then
		local h = hum()
		if h then
			if h.PlatformStand then h.PlatformStand = false end
			if h.Sit then h.Sit = false end
		end
	end

	if CFG.NoclipRisky then
		local c = char()
		if c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide and p.Name ~= "HumanoidRootPart" then
					p.CanCollide = false
				end
			end
		end
	end
end))

table.insert(Conns, cloneref(game:GetService("UserInputService")).JumpRequest:Connect(function()
	if Running and CFG.InfJump then
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end))

-- 状态 + ESP 距离
task.spawn(function()
	while Running do
		task.wait(1)
		if CFG.ESPDistance and CFG.ESP then
			local r = hrp()
			if r then
				for _, e in ipairs(Eggs) do
					if e.espLabel and e.espLabel.Parent then
						local d = math.floor((e.pos - r.Position).Magnitude)
						e.espLabel.Text = ("%s\n$%s/秒  •  %d格"):format(e.name, short(e.money), d)
					end
				end
			end
		end
		if not Busy and not Travelling then
			StatusFn(CFG.AutoFarm and "自动挂机运行中……" or "等待中", ACCENT)
		end
	end
end)

-- 自动挂机
task.spawn(function()
	while Running do
		task.wait(0.5)
		if CFG.AutoFarm and not Busy and alive() then
			scanEggs()
			local list = filteredEggs()
			if #list == 0 then
				StatusFn("自动挂机：没有蛋符合筛选条件。", YELLOW)
				task.wait(3)
			else
				rebuildDropdown()
				setSelected(list[1])
				stealEgg(list[1])
			end
		end
	end
end)

-- 定期重新扫描
task.spawn(function()
	while Running do
		task.wait(12)
		if not Busy then
			scanEggs()
			rebuildDropdown()
			if CFG.ESP then refreshESP() end
		end
	end
end)

-- 重生
table.insert(Conns, LP.CharacterAdded:Connect(function()
	task.wait(2)
	CancelTravel = false
	Busy = false
end))

----------------------------------------------------------------------
-- 销毁
----------------------------------------------------------------------
_G.TFN_HUB_DESTROY = function()
	Running = false
	CFG.AutoFarm = false
	CancelTravel = true
	for _, c in ipairs(Conns) do try(function() c:Disconnect() end) end
	Conns = {}
	clearESP()
	try(function() Window:Destroy() end)
	_G.TFN_HUB_LOADED = false
end

----------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------
task.spawn(function()
	scanEggs()
	rebuildDropdown()
	local list = filteredEggs()
	if #list > 0 then setSelected(list[1]) end
	StatusFn("就绪", ACCENT)
	notify("TFN HUB", ("加载完成，找到 %d 个蛋；稳妥模式已启用。"):format(#Eggs), 6, "egg")
end)

try(function() Window:SelectTab(1) end)
