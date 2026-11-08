local function elevate()
    if setthreadidentity then pcall(setthreadidentity, 8) end
end
elevate()

local rawSpawn = task.spawn
local function spawnTask(fn)
    return rawSpawn(function()
        elevate()
        fn()
    end)
end

local RELOAD_STATE = STATE
local ENV = (getgenv and getgenv()) or _G
ENV.__MuscleLegendsFarm = ENV.__MuscleLegendsFarm or {}
local SESSION = ENV.__MuscleLegendsFarm

local GEN_HOST = game:GetService("CoreGui")
local GEN_ATTR = "__MuscleLegendsFarmGeneration"
local MY_GENERATION = (GEN_HOST:GetAttribute(GEN_ATTR) or 0) + 1
GEN_HOST:SetAttribute(GEN_ATTR, MY_GENERATION)
SESSION.generation = MY_GENERATION

local function generationAlive()
    return GEN_HOST:GetAttribute(GEN_ATTR) == MY_GENERATION
end

local GuiLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/SoldoxD/libery/refs/heads/main/main"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local rEvents = ReplicatedStorage:WaitForChild("rEvents")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local GF = require(sharedFolder.modules.GlobalFunctions)
local Data = require(ReplicatedStorage.packages.ReplicatorClient).get("Data")

local muscleEvent = LocalPlayer:WaitForChild("muscleEvent")
local machineInUse = LocalPlayer:WaitForChild("machineInUse")
local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Strength = leaderstats:WaitForChild("Strength")
local Rebirths = leaderstats:WaitForChild("Rebirths")
local Agility = LocalPlayer:WaitForChild("Agility")
local Durability = LocalPlayer:WaitForChild("Durability")
local Gems = LocalPlayer:WaitForChild("Gems")
local Tokens = LocalPlayer:WaitForChild("Tokens")

local Remotes = {
    Machine   = rEvents:WaitForChild("machineInteractRemote"),
    Rebirth   = rEvents:WaitForChild("rebirthRemote"),
    Crystal   = rEvents:WaitForChild("openCrystalRemote"),
    Chest     = rEvents:WaitForChild("checkChestRemote"),
    Group     = rEvents:WaitForChild("groupRemote"),
    Gift      = rEvents:WaitForChild("freeGiftClaimRemote"),
    Wheel     = rEvents:WaitForChild("openFortuneWheelRemote"),
    Quests    = rEvents:WaitForChild("questsEvent"),
    EquipPet  = rEvents:WaitForChild("equipPetEvent"),
    SellPet   = rEvents:WaitForChild("sellPetEvent"),
    PetEvolve = rEvents:WaitForChild("petEvolveEvent"),
    Area      = rEvents:WaitForChild("areaTravelRemote"),
    Rejoin    = rEvents:WaitForChild("rejoinServerEvent"),
    Ultimates = rEvents:WaitForChild("ultimatesRemote"),
}

local machinesFolder = workspace:WaitForChild("machinesFolder")
local treadmillsFolder = workspace:WaitForChild("Treadmills")
local areaTeleportParts = workspace:WaitForChild("areaTeleportParts")
local kingsGymPart = areaTeleportParts:WaitForChild("beachToMuscleKing")
local crystalPrices = sharedFolder.catalogs.crystalPrices
local gameUltimates = sharedFolder.catalogs.gameUltimatesFolder
local fortuneWheel = sharedFolder.catalogs.fortuneWheelChances["Fortune Wheel"]
local questCatalog = sharedFolder.catalogs:WaitForChild("Quests")
local questsNpcs = workspace:WaitForChild("questsNpcs")

local CHEST_NAMES = {"Golden Chest", "Enchanted Chest", "Magma Chest", "Mythical Chest", "Legends Chest", "Jungle Chest"}

local TOOL_STATS = {
    Weight     = {strengthGain = true},
    Situps     = {strengthGain = true, agilityGain = true},
    Pushups    = {strengthGain = true, agilityGain = true, durabilityGain = true},
    Handstands = {strengthGain = true, durabilityGain = true},
}

local TIMED_BOOSTS = {["Protein Egg"] = "Protein Egg", ["Tropical Shake"] = "Tropical Shake"}
local BOOST_ACTIONS = {
    ["Protein Bar"]    = "proteinBar",
    ["Protein Shake"]  = "proteinShake",
    ["Protein Egg"]    = "proteinEgg",
    ["Energy Bar"]     = "energyBar",
    ["Energy Shake"]   = "energyShake",
    ["TOUGH Bar"]      = "toughBar",
    ["ULTRA Shake"]    = "ultraShake",
    ["Tropical Shake"] = "tropicalShake",
}
local INSTANT_BOOSTS = {
    ["Protein Bar"] = true, ["Protein Shake"] = true, ["TOUGH Bar"] = true,
    ["ULTRA Shake"] = true, ["Energy Bar"] = true, ["Energy Shake"] = true,
}
local SAVED_FOR_PUSH = {["ULTRA Shake"] = true, ["TOUGH Bar"] = true}

local PERK_PETS = {
    ["Swift Samurai"]   = 6000,
    ["Powercore Hound"] = 5000,
    ["Tribal Overlord"] = 4000,
    ["Titanium Hydra"]  = 3000,
    ["Speedy Sally"]    = 2000,
}

local PET_PRIORITY = {
    ["Farm speed"] = {["Swift Samurai"] = 6, ["Powercore Hound"] = 5, ["Tribal Overlord"] = 4, ["Titanium Hydra"] = 3, ["Speedy Sally"] = 2},
    ["Rebirths"]   = {["Tribal Overlord"] = 6, ["Speedy Sally"] = 5, ["Titanium Hydra"] = 4, ["Swift Samurai"] = 3, ["Powercore Hound"] = 2},
    ["Raw stats"]  = {},
}
local RARITY_ORDER = {Basic = 1, Rare = 2, Epic = 3, Unique = 4, Advanced = 5}

local ULTIMATE_PRIORITY = {
    Speed    = {"Galaxy Gains", "+5% Rep Speed", "Golden Rebirth"},
    Balanced = {"Galaxy Gains", "+5% Rep Speed", "Jungle Swift", "Muscle Mind", "Golden Rebirth"},
    Rebirth  = {"Golden Rebirth", "Galaxy Gains", "+5% Rep Speed"},
    Everything = {"Galaxy Gains", "+5% Rep Speed", "Golden Rebirth", "+1 Pet Slot", "x2 Quest Rewards", "x2 Chest Rewards", "+1 Daily Spin", "Jungle Swift", "Muscle Mind", "+10 Item Capacity", "Infernal Health", "Demon Damage"},
}

local State = {
    Running = true,
    FarmMode = "Off",
    RepDelay = 0.06,
    AutoBenchmark = false,
    BenchmarkSeconds = 12,
    BenchmarkEvery = 600,
    SourcePreference = "Auto (fastest)",
    StrengthSource = "Auto (Fastest)",
    RotateSeconds = 120,
    AutoRebirth = false,
    AutoBoosts = false,
    SaveBigBoosts = false,
    AutoUltimates = false,
    UltimatePlan = "Speed",
    KeepRebirths = 0,
    AutoChests = false,
    AutoGroup = false,
    AutoGifts = false,
    AutoWheel = false,
    AutoQuests = false,
    AutoHatch = false,
    HatchCrystal = "Blue Crystal",
    KeepCurrency = 0,
    HatchDelay = 0.4,
    AutoEquipPets = false,
    PetPriority = "Farm speed",
    AutoSellPets = false,
    SellRarities = {},
    AutoDeletePets = false,
    DeletePetNames = {},
    AutoEvolvePets = false,
    AlwaysKingsGym = false,
    AntiAFK = true,
    Notify = true,
}

local Runtime = {
    Status = "空闲",
    Target = "无",
    Bench = "未运行",
    FarmToken = 0,
    Reps = 0,
    Hatched = 0,
    Claimed = 0,
    Boosts = 0,
    Upgrades = 0,
    Evolved = 0,
    RebirthCount = 0,
    RebirthBusy = false,
    KingLockedUntil = 0,
    Heartbeat = 0,
    Rates = {},
    RatesStamp = 0,
    RatesRebirth = -1,
    StartClock = os.clock(),
    StartStats = {Strength = Strength.Value, Agility = Agility.Value, Durability = Durability.Value},
    Blacklist = {},
}

local char, hum, hrp
local restartFarm

local function gf(name, ...)
    local packed = table.pack(pcall(GF[name], ...))
    elevate()
    if packed[1] then return table.unpack(packed, 2, packed.n) end
    return nil
end

local function invoke(remote, ...)
    local packed = table.pack(pcall(remote.InvokeServer, remote, ...))
    elevate()
    if packed[1] then return table.unpack(packed, 2, packed.n) end
    return nil
end

local function fire(remote, ...)
    pcall(remote.FireServer, remote, ...)
    elevate()
end

local function dataIndex(...)
    local ok, v = pcall(function(...) return Data:TryIndex({...}) end, ...)
    elevate()
    if ok then return v end
    return nil
end

local function running()
    if not State.Running then return false end
    if not generationAlive() then return false end
    if RELOAD_STATE and RELOAD_STATE.alive and not RELOAD_STATE.alive() then return false end
    return true
end

local function farming(token)
    return running() and State.FarmMode ~= "Off" and token == Runtime.FarmToken
end

local function notify(title, message, kind, duration)
    if not State.Notify then return end
    elevate()
    pcall(function() GuiLibrary:CreateNotification(title, message, duration or 3, kind or "info") end)
end

local function bindCharacter(c)
    char = c
    hum = c:WaitForChild("Humanoid", 10)
    hrp = c:WaitForChild("HumanoidRootPart", 10)
end

if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end

LocalPlayer.CharacterAdded:Connect(function(c)
    bindCharacter(c)
    Runtime.Blacklist = {}
    Runtime.Heartbeat = os.clock()
    if State.FarmMode ~= "Off" and not Runtime.RebirthBusy and restartFarm then restartFarm() end
end)

local function alive()
    return char and char.Parent and hum and hrp and hrp.Parent and hum.Health > 0
end

local function short(n)
    local s = gf("shortenNumber", n)
    if s then return s end
    return tostring(n)
end

local function statValue(gainKey)
    if gainKey == "strengthGain" then return Strength.Value end
    if gainKey == "agilityGain" then return Agility.Value end
    return Durability.Value
end

local function repsCounter()
    local quests = LocalPlayer:FindFirstChild("Quests")
    if not quests then return nil end
    for _, group in ipairs(quests:GetChildren()) do
        for _, quest in ipairs(group:GetChildren()) do
            local req = quest:FindFirstChild("requirements")
            local reps = req and req:FindFirstChild("Reps")
            local progress = reps and reps:FindFirstChild("progress")
            if progress then return progress end
        end
    end
    return nil
end

local function beat()
    Runtime.Heartbeat = os.clock()
end

local function beatWait(seconds)
    local t0 = os.clock()
    while os.clock() - t0 < seconds do
        beat()
        task.wait(0.2)
    end
end

local function anchorAt(cf)
    if not alive() then return end
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function isMounted()
    return char and (char:GetAttribute("MachineStandingMount") == true
        or char:GetAttribute("MachineScaleFrozen") == true
        or (hum and hum.SeatPart ~= nil))
end

local function unseat()
    if not hum then return end
    pcall(function() hum.Sit = false end)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    if hum.SeatPart then
        for _, w in ipairs(hum.SeatPart:GetChildren()) do
            if w:IsA("Weld") and w.Name == "SeatWeld" then pcall(function() w:Destroy() end) end
        end
    end
end

local function leaveMachine()
    invoke(Remotes.Machine, "leaveMachine")
    unseat()
    local t = os.clock()
    while isMounted() and os.clock() - t < 4 do
        beat()
        unseat()
        task.wait(0.15)
    end
    task.wait(0.15)
    beat()
    return not isMounted()
end

local function blacklisted(inst)
    local until_ = Runtime.Blacklist[inst]
    return until_ ~= nil and until_ > os.clock()
end

local function meetsRequirements(inst)
    local req = inst:FindFirstChild("requirements")
    if not req then return true end
    return gf("checkIfPlayerCanUseMachine", LocalPlayer, req) == true
end

local function findTool(name)
    return LocalPlayer.Backpack:FindFirstChild(name) or (char and char:FindFirstChild(name))
end

local function toolUsable(name)
    local tool = findTool(name)
    if not tool then return false end
    local amount = tool:FindFirstChild("requiredAmount")
    local kind = tool:FindFirstChild("requiredType")
    if not amount or not kind then return true end
    local have = Strength.Value
    if kind.Value == "Agility" then have = Agility.Value
    elseif kind.Value == "Durability" then have = Durability.Value end
    return have >= amount.Value
end

local function equipTool(name)
    local tool = findTool(name)
    if not tool or not hum then return false end
    pcall(function() hum:EquipTool(tool) end)
    return true
end

local function heldTool()
    local t = char and char:FindFirstChildOfClass("Tool")
    return t and t.Name or nil
end

local function machineSources(gainKey)
    local list = {}
    for _, m in ipairs(machinesFolder:GetChildren()) do
        local gain = m:FindFirstChild(gainKey)
        local seat = m.PrimaryPart
        local repTime = m:FindFirstChild("repTime")
        local kingLocked = m:GetAttribute("IsKingMachine") == true
            and (Runtime.KingLockedUntil or 0) > os.clock()
        if gain and seat and seat:IsA("Seat") and not kingLocked and not blacklisted(m) and meetsRequirements(m) then
            local rt = repTime and repTime.Value or 1
            if rt <= 0 then rt = 1 end
            table.insert(list, {
                kind = "machine", key = "M:" .. m.Name, model = m, seat = seat,
                gain = gain.Value, repTime = rt, estimate = gain.Value / rt,
                label = m.Name .. " (+" .. gain.Value .. "/" .. rt .. "s)",
            })
        end
    end
    table.sort(list, function(a, b) return a.estimate > b.estimate end)
    return list
end

local function toolSources(gainKey)
    local list = {}
    for name, stats in pairs(TOOL_STATS) do
        if stats[gainKey] and toolUsable(name) then
            local tool = findTool(name)
            local gain = tool and tool:FindFirstChild(gainKey)
            local repTime = tool and tool:FindFirstChild("repTime")
            local rt = repTime and repTime.Value or 1
            if rt <= 0 then rt = 1 end
            table.insert(list, {
                kind = "tool", key = "T:" .. name, toolName = name,
                gain = gain and gain.Value or 0, repTime = rt,
                estimate = (gain and gain.Value or 0) / rt,
                label = name .. " 工具",
            })
        end
    end
    table.sort(list, function(a, b) return a.estimate > b.estimate end)
    return list
end

local function candidateSources(gainKey)
    local machines = machineSources(gainKey)
    local tools = toolSources(gainKey)
    if #machines == 0 and #tools == 0 and next(Runtime.Blacklist) then
        Runtime.Blacklist = {}
        machines = machineSources(gainKey)
        tools = toolSources(gainKey)
    end
    local out = {}
    local preference = gainKey == "strengthGain" and State.StrengthSource or State.SourcePreference
    local toolsOnly = preference == "Tools only" or preference == "Tools (Hotbar)"
    local machinesOnly = preference == "Machines only" or preference == "Machines"
    if not toolsOnly then
        for i = 1, math.min(2, #machines) do table.insert(out, machines[i]) end
    end
    if not machinesOnly then
        for i = 1, math.min(2, #tools) do table.insert(out, tools[i]) end
    end
    if #out == 0 then
        for i = 1, math.min(1, #machines) do table.insert(out, machines[i]) end
        for i = 1, math.min(1, #tools) do table.insert(out, tools[i]) end
    end
    return out
end

local function engageMachine(source)
    if not alive() then return false end
    if isMounted() and not leaveMachine() then
        Runtime.Status = "卡在器械上，正在重试"
        task.wait(0.1)
        return false
    end
    for _ = 1, 3 do
        if not alive() then return false end
        beat()
        anchorAt(source.seat.CFrame * CFrame.new(0, 5, 0))
        task.wait(0.05)
    end
    local res, reason = invoke(Remotes.Machine, "useMachine", source.seat)
    if res ~= true then
        if reason == "isKingMachine" or source.model:GetAttribute("IsKingMachine") == true then
            Runtime.KingLockedUntil = os.clock() + 120
        else
            Runtime.Blacklist[source.model] = os.clock() + 180
        end
        return false
    end
    local deadline = os.clock() + 0.6
    while machineInUse.Value ~= source.seat and os.clock() < deadline do
        beat()
        task.wait(0.03)
    end
    return machineInUse.Value == source.seat
end

local function engageTool(source)
    if isMounted() and not leaveMachine() then
        Runtime.Status = "卡在器械上，正在重试"
        task.wait(0.5)
        return false
    end
    beat()
    equipTool(source.toolName)
    beatWait(0.5)
    return heldTool() == source.toolName
end

local function engage(source)
    if source.kind == "machine" then return engageMachine(source) end
    return engageTool(source)
end

local function repOnce(source)
    if source.kind == "machine" then
        muscleEvent:FireServer("rep", source.seat)
    else
        muscleEvent:FireServer("rep")
    end
    Runtime.Reps = Runtime.Reps + 1
end

local function sourceHealthy(source)
    if source.kind == "machine" then return machineInUse.Value == source.seat end
    return heldTool() == source.toolName and not isMounted()
end

local function measureSource(source, gainKey, token)
    if not engage(source) then return -1 end
    local counter = repsCounter()
    local prime = os.clock()
    while os.clock() - prime < 2 and farming(token) do
        beat()
        repOnce(source)
        task.wait(State.RepDelay)
    end
    local before = statValue(gainKey)
    local beforeReps = counter and counter.Value or 0
    local seconds = math.max(6, State.BenchmarkSeconds)
    local t0 = os.clock()
    while os.clock() - t0 < seconds and farming(token) do
        if not sourceHealthy(source) then break end
        beat()
        repOnce(source)
        task.wait(State.RepDelay)
    end
    if not farming(token) then return -1 end
    local window = os.clock() - t0
    beatWait(8)
    local delta = statValue(gainKey) - before
    local landed = counter and (counter.Value - beforeReps) or nil
    if delta <= 0 and (landed == nil or landed <= 0) then return -1 end
    return delta / window
end

local function runBenchmark(gainKey, token, list, onlyMissing)
    local todo = {}
    for _, source in ipairs(list) do
        if not onlyMissing or Runtime.Rates[source.key] == nil then table.insert(todo, source) end
    end
    if #todo == 0 then return end
    for _, source in ipairs(todo) do
        if not farming(token) then return end
        Runtime.Status = "正在测试基准 " .. source.label
        Runtime.Rates[source.key] = measureSource(source, gainKey, token)
    end
    if not onlyMissing then Runtime.RatesStamp = os.clock() end
    local parts = {}
    for _, source in ipairs(list) do
        local r = Runtime.Rates[source.key]
        parts[#parts + 1] = ("%s %s"):format(source.label, r and (r < 0 and "已锁" or string.format("%.0f/s", r)) or "?")
    end
    Runtime.Bench = table.concat(parts, "  |  ")
end

local function pickSource(gainKey, token)
    local list = candidateSources(gainKey)
    if #list == 0 then return nil end
    if State.AutoBenchmark and gainKey ~= "strengthGain" then
        local full = os.clock() - Runtime.RatesStamp > State.BenchmarkEvery
        if full then Runtime.Rates = {} end
        runBenchmark(gainKey, token, list, not full)
        if token ~= Runtime.FarmToken then return nil end
    end
    local best, bestScore
    for _, source in ipairs(list) do
        local score = Runtime.Rates[source.key]
        if score == nil then score = source.estimate end
        if not bestScore or score > bestScore then best, bestScore = source, score end
    end
    if bestScore and bestScore < 0 then
        Runtime.Blacklist = {}
        Runtime.Rates = {}
        Runtime.Bench = "所有来源均失败，按预估值重试"
        best, bestScore = nil, nil
        for _, source in ipairs(candidateSources(gainKey)) do
            if not bestScore or source.estimate > bestScore then best, bestScore = source, source.estimate end
        end
    end
    return best
end

local function rebirthTarget()
    local need = gf("calculateRequiredRebirthStrength", Rebirths.Value, LocalPlayer)
    if type(need) == "number" then return need end
    return math.huge
end

local function canRebirth()
    if char and char:GetAttribute("IsRebirthing") == true then return false end
    if LocalPlayer:GetAttribute("LastMapCFrame") ~= nil then return false end
    return Strength.Value >= rebirthTarget()
end

local function boostActive(name)
    local folder = LocalPlayer:FindFirstChild("boostTimersFolder")
    local entry = folder and folder:FindFirstChild(name)
    return entry ~= nil and entry.Value > 0
end

local function boostAction(name)
    local known = BOOST_ACTIONS[name]
    if known then return known end
    local parts = {}
    for word in tostring(name):gmatch("%S+") do
        if #parts == 0 then
            parts[1] = word:lower()
        else
            parts[#parts + 1] = word:sub(1, 1):upper() .. word:sub(2):lower()
        end
    end
    return table.concat(parts)
end

local function useConsumable(tool)
    if not hum or not char or not tool or not tool.Parent then return false end
    beat()
    local consumables = LocalPlayer:FindFirstChild("consumablesFolder")
    local before = consumables and #consumables:GetChildren() or 0
    pcall(function() hum:EquipTool(tool) end)
    local t = os.clock()
    while char:FindFirstChildOfClass("Tool") ~= tool and os.clock() - t < 1.5 do
        beat()
        task.wait(0.1)
    end
    if char:FindFirstChildOfClass("Tool") ~= tool then return false end
    fire(muscleEvent, boostAction(tool.Name), tool)
    local t2 = os.clock()
    local function consumed()
        if tool.Parent == nil then return true end
        return consumables ~= nil and #consumables:GetChildren() < before
    end
    while not consumed() and os.clock() - t2 < 2.5 do
        beat()
        task.wait(0.15)
    end
    if not consumed() then return false end
    Runtime.Boosts = Runtime.Boosts + 1
    return true
end

local function useBoosts(forPush)
    if isMounted() then leaveMachine() end
    local used, failed = 0, 0
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if not running() then break end
        if tool.Parent and TIMED_BOOSTS[tool.Name] and not boostActive(tool.Name) then
            if useConsumable(tool) then
                used = used + 1
                notify("加成", "已激活 " .. tool.Name, "success")
            else
                failed = failed + 1
            end
        end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if not running() then break end
        if tool.Parent and INSTANT_BOOSTS[tool.Name] then
            local hold = State.SaveBigBoosts and SAVED_FOR_PUSH[tool.Name] and not forPush
            if not hold then
                if useConsumable(tool) then used = used + 1 else failed = failed + 1 end
            end
        end
    end
    if hum then pcall(function() hum:UnequipTools() end) end
    if used > 0 then
        notify("加成", "已使用 " .. used .. " 个消耗品", "success")
    elseif failed > 0 then
        notify("加成", "未能使用 (" .. failed .. " 个被拒绝)", "warning")
    end
    return used, failed
end

local function upgradeUltimates()
    local plan = ULTIMATE_PRIORITY[State.UltimatePlan] or ULTIMATE_PRIORITY.Speed
    local done = 0
    for _, name in ipairs(plan) do
        if not running() then break end
        local entry = gameUltimates:FindFirstChild(name)
        if entry then
            local maxUp = entry:FindFirstChild("maxUpgrades")
            local level = dataIndex("ultimatesFolder", name) or 0
            if type(level) ~= "number" then level = 0 end
            if not maxUp or level < maxUp.Value then
                local cost = gf("calculateUltimateRebirthCost", entry, level)
                if type(cost) == "number" and Rebirths.Value - cost >= State.KeepRebirths then
                    if invoke(Remotes.Ultimates, "upgradeUltimate", name) == true then
                        done = done + 1
                        Runtime.Upgrades = Runtime.Upgrades + 1
                        notify("终极天赋", name .. " -> 等级 " .. (level + 1), "success")
                        task.wait(0.4)
                    end
                end
            end
        end
    end
    return done
end

local function doRebirth()
    if State.AutoBoosts and State.SaveBigBoosts and Strength.Value < rebirthTarget() then
        useBoosts(true)
    end
    if isMounted() then leaveMachine() end
    local beforeStrength = Strength.Value
    local res = invoke(Remotes.Rebirth, "rebirthRequest")
    if res == true then
        Runtime.RebirthCount = Runtime.RebirthCount + 1
        notify("转生", "转生 " .. tostring(Rebirths.Value) .. " 次完成", "success")
    end
    local t = os.clock()
    while res == true and os.clock() - t < 8 do
        beat()
        if Strength.Value < beforeStrength and alive() and char:GetAttribute("IsRebirthing") ~= true then break end
        task.wait(0.03)
    end
    Runtime.Blacklist = {}
    if State.AutoUltimates then pcall(upgradeUltimates) end
    return res == true
end

local function rebirthChain(maxCount, spendBoosts)
    maxCount = maxCount or 50
    local gained = 0
    for _ = 1, maxCount do
        if not running() then break end
        if not canRebirth() and spendBoosts then
            local before = Strength.Value
            Runtime.Status = "正在准备转生补充力量"
            useBoosts(true)
            if Strength.Value <= before then break end
        end
        if not canRebirth() then break end
        Runtime.Status = "正在转生 (" .. (gained + 1) .. ")"
        if not doRebirth() then break end
        gained = gained + 1
        task.wait()
    end
    if gained >  1 then
        notify("转生", "已连续转生 " .. gained .. " 次", "success", 5)
    end
    return gained
end

local function requestAutoRebirth()
    if not running() or not State.AutoRebirth or Runtime.RebirthBusy or not canRebirth() then return false end
    Runtime.RebirthBusy = true
    Runtime.FarmToken = Runtime.FarmToken + 1
    spawnTask(function()
        local gained = rebirthChain(50, false)
        Runtime.RebirthBusy = false
        if State.FarmMode ~= "Off" and restartFarm then restartFarm() end
    end)
    return true
end

Strength.Changed:Connect(function()
    if running() and State.AutoRebirth then requestAutoRebirth() end
end)

spawnTask(function()
    while running() do
        if State.AutoRebirth then requestAutoRebirth() end
        task.wait(0.25)
    end
end)

local function resolveMode()
    if State.FarmMode ~= "Rotate" then return State.FarmMode end
    local order = {"Strength", "Agility", "Durability"}
    local span = math.max(State.RotateSeconds, 15)
    return order[(math.floor(os.clock() / span) % #order) + 1]
end

local GAIN_KEY = {Strength = "strengthGain", Agility = "agilityGain", Durability = "durabilityGain"}

local function bestTreadmill()
    local best
    for _, t in ipairs(treadmillsFolder:GetChildren()) do
        local gain = t:FindFirstChild("agilityAmount")
        local part = t:FindFirstChild("treadmillPart")
        if gain and part and not blacklisted(t) and meetsRequirements(t) then
            if not best or gain.Value > best.gain then
                best = {model = t, part = part, gain = gain.Value}
            end
        end
    end
    return best
end

local function bestRock()
    local best
    for _, m in ipairs(machinesFolder:GetChildren()) do
        local rock = m:FindFirstChild("Rock")
        local gain = m:FindFirstChild("durabilityGain")
        local need = m:FindFirstChild("neededDurability")
        if rock and gain and not blacklisted(m) and Durability.Value >= (need and need.Value or 0) then
            if not best or gain.Value > best.gain then
                best = {model = m, rock = rock, gain = gain.Value, estimate = gain.Value / 1.4}
            end
        end
    end
    return best
end

local function farmTreadmill(token, mode)
    local entry = bestTreadmill()
    if not entry then return false end
    leaveMachine()
    local part = entry.part
    Runtime.Target = entry.model.Name .. " 跑步机 (+" .. entry.gain .. ")"
    Runtime.Status = "正在跑步机上运行"
    local nextScan = os.clock() + 15
    while farming(token) and resolveMode() == mode do
        if not alive() then return true end
        Runtime.Heartbeat = os.clock()
        anchorAt(part.CFrame * CFrame.new(0, part.Size.Y / 2 + hum.HipHeight + hrp.Size.Y / 2 + 0.4, 0))
        if os.clock() > nextScan then
            nextScan = os.clock() + 15
            local better = bestTreadmill()
            if better and better.model ~= entry.model and better.gain > entry.gain then return true end
        end
        task.wait(0.1)
    end
    return true
end

local function farmRock(token, mode)
    local entry = bestRock()
    if not entry then return false end
    leaveMachine()
    local rock = entry.rock
    local reach = math.max(rock.Size.X, rock.Size.Z) / 2 - 4
    local stand = CFrame.new(rock.Position - Vector3.new(0, 0, reach), rock.Position)
    equipTool("Punch")
    Runtime.Target = entry.model.Name .. " (每次+ " .. entry.gain .. ")"
    Runtime.Status = "正在击打岩石"
    local flip = false
    while farming(token) and resolveMode() == mode do
        if not alive() then return true end
        Runtime.Heartbeat = os.clock()
        anchorAt(stand)
        flip = not flip
        muscleEvent:FireServer("punch", flip and "rightHand" or "leftHand")
        Runtime.Reps = Runtime.Reps + 1
        task.wait(0.12)
    end
    return true
end

local function farmStat(token, mode)
    if not farming(token) then return true end
    local gainKey = GAIN_KEY[mode]
    local source = pickSource(gainKey, token)
    if not farming(token) then return true end

    if mode == "Agility" then
        local treadmill = bestTreadmill()
        local treadRate = treadmill and (treadmill.gain / 3.3) or 0
        local sourceRate = source and (Runtime.Rates[source.key] or source.estimate) or 0
        if treadmill and treadRate > sourceRate and State.SourcePreference ~= "Tools only" then
            return farmTreadmill(token, mode)
        end
    end

    if mode == "Durability" and State.SourcePreference == "Rocks only" then
        return farmRock(token, mode)
    end

    if not source then
        if mode == "Durability" and farmRock(token, mode) then return true end
        Runtime.Status = "没有可用的 " .. mode .. " 挂机来源"
        Runtime.Target = "无"
        task.wait(2)
        return true
    end

    if not farming(token) then return true end
    if not engage(source) then
        Runtime.Status = "被锁住，尝试下一个: " .. source.label
        Runtime.Target = "切换中"
        task.wait(0.2)
        return true
    end

    local rate = Runtime.Rates[source.key]
    Runtime.Target = source.label .. (rate and (" ~ " .. string.format("%.0f", rate) .. "/s") or "")
    Runtime.Status = (source.kind == "machine") and "正在使用器械" : "正在锻炼"

    local chore = os.clock() + 90
    while farming(token) and resolveMode() == mode do
        if not alive() then return true end
        if not sourceHealthy(source) then return true end
        Runtime.Heartbeat = os.clock()
        repOnce(source)
        if requestAutoRebirth() then
            return true
        end
        if os.clock() > chore then return true end
        task.wait(State.RepDelay)
    end
    return true
end

local function teleportToKingsGym()
    if not alive() or not kingsGymPart then return false end
    if (hrp.Position - kingsGymPart.Position).Magnitude < 500 then return true end
    if isMounted() then leaveMachine() end
    for _ = 1, 3 do
        if not alive() then return false end
        anchorAt(kingsGymPart.CFrame * CFrame.new(0, 6, 0))
        task.wait(0.05)
    end
    return (hrp.Position - kingsGymPart.Position).Magnitude < 500
end

local function startFarm()
    Runtime.FarmToken = Runtime.FarmToken + 1
    local token = Runtime.FarmToken
    Runtime.Heartbeat = os.clock()
    spawnTask(function()
        local nextBoost, nextUlt = 0, 0
        while farming(token) do
            elevate()
            Runtime.Heartbeat = os.clock()
            if State.AutoBoosts and os.clock() > nextBoost then
                nextBoost = os.clock() + 45
                pcall(useBoosts, false)
            end
            if State.AutoUltimates and os.clock() > nextUlt then
                nextUlt = os.clock() + 60
                pcall(upgradeUltimates)
            end
            local mode = resolveMode()
            if not alive() then
                Runtime.Status = "等待角色复活"
                task.wait(1)
            elseif GAIN_KEY[mode] then
                farmStat(token, mode)
            else
                task.wait(0.5)
            end
            task.wait(0.05)
        end
        Runtime.Exited = token
        if token == Runtime.FarmToken then
            Runtime.Status = "空闲"
            Runtime.Target = "无"
            pcall(leaveMachine)
        end
    end)
end

restartFarm = startFarm

local function stopFarm(reason)
    local old = Runtime.FarmToken
    State.FarmMode = "Off"
    Runtime.FarmToken = old + 1
    Runtime.Target = "无"
    Runtime.Status = "正在停止"
    spawnTask(function()
        local t = os.clock()
        while Runtime.Exited ~= old and os.clock() - t < 6 do task.wait(0.1) end
        leaveMachine()
        local t2 = os.clock()
        while isMounted() and os.clock() - t2 < 3 do
            leaveMachine()
            task.wait(0.2)
        end
        if State.FarmMode == "Off" then
            Runtime.Status = reason or "空闲"
            Runtime.Target = "无"
        end
    end)
end

spawnTask(function()
    while running() do
        elevate()
        if State.FarmMode ~= "Off" and os.clock() - (Runtime.Heartbeat or 0) > 25 then
            Runtime.Status = "看门狗重启中"
            startFarm()
        end
        task.wait(5)
    end
end)

local function claimChests()
    for _, name in ipairs(CHEST_NAMES) do
        if invoke(Remotes.Chest, name) == true then
            Runtime.Claimed = Runtime.Claimed + 1
            notify("宝箱", name .. " 已领取", "success")
        end
        task.wait(0.25)
    end
end

local function claimGroup()
    if invoke(Remotes.Group, "groupRewards") == true then
        Runtime.Claimed = Runtime.Claimed + 1
        notify("群组", "群组奖励已领取", "success")
    end
end

local function claimGifts()
    for n = 1, 8 do
        if invoke(Remotes.Gift, "claimGift", n) == true then
            Runtime.Claimed = Runtime.Claimed + 1
            notify("免费礼物", "礼物 " .. n .. " 已领取", "success")
        end
        task.wait(0.25)
    end
end

local function spinWheel()
    local spins = dataIndex("freeWheelSpins")
    if type(spins) ~= "number" then return end
    while spins > 0 do
        local res = invoke(Remotes.Wheel, "openFortuneWheel", fortuneWheel)
        if type(res) ~= "table" then break end
        Runtime.Claimed = Runtime.Claimed + 1
        notify("幸运转盘", tostring(res.name) .. " (" .. tostring(res.rarity) .. ")", "success")
        spins = spins - 1
        task.wait(1)
    end
end

local function collectQuests()
    local root = LocalPlayer:FindFirstChild("Quests")
    if not root then return end

    for _, quest in ipairs(root:GetDescendants()) do
        if quest:IsA("Folder") and quest:FindFirstChild("requirements") then
            if gf("checkForCompleteQuest", quest) == true then
                fire(Remotes.Quests, "collectQuest", quest)
                Runtime.Claimed = Runtime.Claimed + 1
                notify("任务", quest.Name .. " 已收集奖励", "success")
                task.wait(0.4)
            end
        end
    end
end

local questAcceptCooldown = {}

local function nextNpcQuest(questLine)
    local root = LocalPlayer:FindFirstChild("Quests")
    local story = root and root:FindFirstChild("Story Quests")
    local completed = root and root:FindFirstChild("completedQuests")
    local catalogQuests = questLine and questLine:FindFirstChild("Quests")
    if not root or not story or not completed or not catalogQuests then return nil end

    if story:FindFirstChild(questLine.Name) then return nil end

    local finished = completed:FindFirstChild(questLine.Name)
    local numbers = {}
    for _, quest in ipairs(catalogQuests:GetChildren()) do
        local number = tonumber(quest.Name)
        if number then table.insert(numbers, number) end
    end
    table.sort(numbers)

    if not finished then return catalogQuests:FindFirstChild("1") end
    for _, number in ipairs(numbers) do
        local name = tostring(number)
        if not finished:FindFirstChild(name) then
            return catalogQuests:FindFirstChild(name)
        end
    end

    if questLine.Name == "Industrial Gains" then
        local industrial = root:FindFirstChild("Industrial Daily")
        if industrial and #industrial:GetChildren() > 0 then return nil end
        local lastDaily = dataIndex("quests", "industrialDailyQuestTime")
        if type(lastDaily) == "number" and os.time() - lastDaily < 86400 then return nil end
        local daily = questCatalog:FindFirstChild("Industrial Daily")
        local today = daily and daily:FindFirstChild(os.date("!%A"))
        return today and today:GetChildren()[1] or nil
    end
    return nil
end

local function acceptNpcQuests()
    for _, npc in ipairs(questsNpcs:GetChildren()) do
        local link = npc:FindFirstChild("questLink")
        local questLine = link and link:IsA("ObjectValue") and link.Value or nil
        local required = questLine and questLine:FindFirstChild("Rebirths")
        if questLine and (not required or required.Value <= Rebirths.Value) then
            local quest = nextNpcQuest(questLine)
            local lastRequest = quest and questAcceptCooldown[quest] or 0
            if quest and os.clock() - lastRequest >= 8 then
                questAcceptCooldown[quest] = os.clock()
                local action = quest.Parent and quest.Parent.Parent and quest.Parent.Parent.Name == "Industrial Daily"
                    and "createNewIndustrialDaily" or "createNewStoryQuest"
                fire(Remotes.Quests, action, quest)
                notify("任务", npc.Name .. " 任务已接取", "success")
                task.wait(0.4)
            end
        end
    end
end

local function updateNpcQuests()
    collectQuests()
    task.wait(0.6)
    acceptNpcQuests()
end

local function crystalCost(name)
    local entry = crystalPrices:FindFirstChild(name)
    if not entry then return nil end
    local price = entry:FindFirstChild("price")
    local kind = entry:FindFirstChild("priceType")
    return price and price.Value or 0, kind and kind.Value or "Gems"
end

local function currencyValue(kind)
    if kind == "Tokens" then return Tokens.Value end
    return Gems.Value
end

local function hatchOnce(name)
    local price, kind = crystalCost(name)
    if not price then return false, "未知水晶" end
    if currencyValue(kind) - price < State.KeepCurrency then return false, "正在保留 " .. kind end
    local pet, rarity = invoke(Remotes.Crystal, "openCrystal", name)
    if type(pet) == "string" then
        Runtime.Hatched = Runtime.Hatched + 1
        return true, pet .. " (" .. tostring(rarity) .. ")"
    end
    return false, "被拒绝"
end

local function petPerkStat(pet, name)
    local perks = pet:FindFirstChild("perksFolder")
    local v = perks and perks:FindFirstChild(name)
    if v then return v.Value end
    local direct = pet:FindFirstChild(name)
    return direct and direct.Value or 0
end

local function allPets()
    local list = {}
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if not folder then return list end
    local weights = PET_PRIORITY[State.PetPriority] or PET_PRIORITY["Farm speed"]
    local statKey = "strength"
    if State.FarmMode == "Agility" then statKey = "agility"
    elseif State.FarmMode == "Durability" then statKey = "durability" end
    for _, rarityFolder in ipairs(folder:GetChildren()) do
        for _, pet in ipairs(rarityFolder:GetChildren()) do
            local levelValue = pet:FindFirstChild("level")
            table.insert(list, {
                pet = pet,
                rarity = rarityFolder.Name,
                perk = weights[pet.Name] or 0,
                keep = PERK_PETS[pet.Name] ~= nil,
                rank = RARITY_ORDER[rarityFolder.Name] or 0,
                power = petPerkStat(pet, statKey),
                level = levelValue and levelValue.Value or 1,
            })
        end
    end
    table.sort(list, function(a, b)
        if a.perk ~= b.perk then return a.perk > b.perk end
        if a.power ~= b.power then return a.power > b.power end
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.level > b.level
    end)
    return list
end

local function inventoryPetNames()
    local names, seen = {}, {}
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if not folder then return names end
    for _, rarityFolder in ipairs(folder:GetChildren()) do
        for _, pet in ipairs(rarityFolder:GetChildren()) do
            if not seen[pet.Name] then
                seen[pet.Name] = true
                names[#names + 1] = pet.Name
            end
        end
    end
    table.sort(names)
    return names
end

local function selectedName(selection, name)
    if type(selection) ~= "table" then return false end
    if selection[name] == true then return true end
    for _, value in pairs(selection) do
        if value == name then return true end
    end
    return false
end

local function equippedSet()
    local set, slots = {}, 0
    local folder = LocalPlayer:FindFirstChild("equippedPets")
    if not folder then return set, 0 end
    for _, slot in ipairs(folder:GetChildren()) do
        slots = slots + 1
        local ref = slot:FindFirstChild("petReference")
        if ref and ref.Value then set[ref.Value] = true end
    end
    return set, slots
end

local function equipBestPets()
    local list = allPets()
    if #list == 0 then return end

    local rankOf, allowed = {}, {}
    for i, entry in ipairs(list) do
        rankOf[entry.pet] = i
        if gf("checkIfPlayerHasEnoughStatsForPet", LocalPlayer, entry.pet) ~= false then
            allowed[#allowed + 1] = entry.pet
        end
    end
    if #allowed == 0 then return end

    local equipped, slots = equippedSet()
    if slots == 0 then return end

    for _, pet in ipairs(allowed) do
        equipped = equippedSet()
        local filled = 0
        for _ in pairs(equipped) do filled = filled + 1 end
        if filled >= slots then break end
        if not equipped[pet] then
            fire(Remotes.EquipPet, "equipPet", pet)
            task.wait(0.35)
            if not equippedSet()[pet] then break end
        end
    end

    for _ = 1, 12 do
        equipped = equippedSet()
        local best
        for _, pet in ipairs(allowed) do
            if not equipped[pet] then best = pet break end
        end
        if not best then break end
        local worst, worstRank
        for pet in pairs(equipped) do
            local r = rankOf[pet] or math.huge
            if not worstRank or r > worstRank then worst, worstRank = pet, r end
        end
        if not worst or (rankOf[best] or math.huge) >= worstRank then break end
        fire(Remotes.EquipPet, "unequipPet", worst)
        task.wait(0.45)
        fire(Remotes.EquipPet, "equipPet", best)
        task.wait(0.45)
        if not equippedSet()[best] then break end
    end
end

local function sellJunkPets()
    local selected = State.SellRarities
    if type(selected) ~= "table" then return end
    local any = false
    for _, v in pairs(selected) do if v then any = true break end end
    if not any then return end
    local equipped = equippedSet()
    for _, entry in ipairs(allPets()) do
        if selected[entry.rarity] and not entry.keep and not equipped[entry.pet] then
            fire(Remotes.SellPet, "sellPet", entry.pet)
            task.wait(0.2)
        end
    end
end

local function deleteSelectedPets()
    local selected = State.DeletePetNames
    if type(selected) ~= "table" then return 0 end
    local equipped = equippedSet()
    local deleted = 0
    for _, entry in ipairs(allPets()) do
        if selectedName(selected, entry.pet.Name)
            and not entry.keep
            and not equipped[entry.pet] then
            fire(Remotes.SellPet, "sellPet", entry.pet)
            deleted = deleted + 1
            task.wait(0.2)
        end
    end
    return deleted
end

local function unevolvedPetCounts()
    local counts = {}
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if not folder then return counts end
    for _, rarityFolder in ipairs(folder:GetChildren()) do
        for _, pet in ipairs(rarityFolder:GetChildren()) do
            if pet:IsA("StringValue") and pet:FindFirstChild("evolved") == nil then
                counts[pet.Name] = (counts[pet.Name] or 0) + 1
            end
        end
    end
    return counts
end

local function evolveReadyPets()
    local evolved = 0
    local counts = unevolvedPetCounts()
    local names = {}
    for name, count in pairs(counts) do
        if count >= 5 then names[#names + 1] = name end
    end
    table.sort(names)

    for _, name in ipairs(names) do
        local count = counts[name] or 0
        while count >= 5 and running() do
            fire(Remotes.PetEvolve, "evolvePet", name)
            task.wait(0.8)
            local after = unevolvedPetCounts()[name] or 0
            if after >= count then break end
            evolved = evolved + 1
            Runtime.Evolved = Runtime.Evolved + 1
            count = after
        end
    end
    return evolved
end

spawnTask(function()
    local nextChest, nextGroup, nextGift, nextWheel, nextQuest = 0, 0, 0, 0, 0
    while running() do
        elevate()
        local now = os.clock()
        if State.AutoChests and now > nextChest then nextChest = now + 90 pcall(claimChests) end
        if State.AutoGroup and now > nextGroup then nextGroup = now + 120 pcall(claimGroup) end
        if State.AutoGifts and now > nextGift then nextGift = now + 60 pcall(claimGifts) end
        if State.AutoWheel and now > nextWheel then nextWheel = now + 60 pcall(spinWheel) end
        if State.AutoQuests and now > nextQuest then nextQuest = now + 10 pcall(updateNpcQuests) end
        task.wait(2)
    end
end)

spawnTask(function()
    local nextPets = 0
    while running() do
        elevate()
        if State.AutoHatch then
            local ok = hatchOnce(State.HatchCrystal)
            task.wait(ok and State.HatchDelay or 3)
        else
            task.wait(1)
        end
        if (State.AutoEquipPets or State.AutoSellPets or State.AutoDeletePets or State.AutoEvolvePets) and os.clock() > nextPets then
            nextPets = os.clock() + 15
            if State.AutoSellPets then pcall(sellJunkPets) end
            if State.AutoDeletePets then pcall(deleteSelectedPets) end
            if State.AutoEvolvePets then pcall(evolveReadyPets) end
            if State.AutoEquipPets then pcall(equipBestPets) end
        end
    end
end)

spawnTask(function()
    while running() do
        elevate()
        if State.AlwaysKingsGym
            and State.FarmMode == "Strength"
            and State.StrengthSource == "Tools (Hotbar)"
        then
            pcall(teleportToKingsGym)
        end
        task.wait(1)
    end
end)

LocalPlayer.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

for _, gui in ipairs(game.CoreGui:GetChildren()) do
    if gui.Name == "GuiLibraryUI" or gui.Name == "NotificationGui" then
        pcall(function() gui:Destroy() end)
    end
end

if RELOAD_STATE and RELOAD_STATE.onCleanup then
    RELOAD_STATE.onCleanup(function()
        State.Running = false
        State.FarmMode = "Off"
        Runtime.FarmToken = Runtime.FarmToken + 1
        for _, gui in ipairs(game.CoreGui:GetChildren()) do
            if gui.Name == "GuiLibraryUI" or gui.Name == "NotificationGui" then
                pcall(function() gui:Destroy() end)
            end
        end
    end)
end

local Window = GuiLibrary:CreateWindow("肌肉传奇 | 自动挂机 | 作者: cyber_modz", UDim2.new(0, 640, 0, 480))

local FarmTab    = GuiLibrary:CreateTab(Window, "挂机")
local BoostTab   = GuiLibrary:CreateTab(Window, "加成")
local CollectTab = GuiLibrary:CreateTab(Window, "收集")
local PetsTab    = GuiLibrary:CreateTab(Window, "宠物")
local StatsTab   = GuiLibrary:CreateTab(Window, "属性")
local MiscTab    = GuiLibrary:CreateTab(Window, "其他")

GuiLibrary:CreateSection(FarmTab, "挂机")

local statusLabel = GuiLibrary:CreateLabel(FarmTab, "状态: 空闲")
local targetLabel = GuiLibrary:CreateLabel(FarmTab, "目标: 无")
local benchLabel  = nil

local farmModeDropdown = GuiLibrary:CreateDropdown(FarmTab, "选择要挂机的属性", {"关闭", "力量", "敏捷", "耐久", "轮换"}, function(v)
    local modeMap = {["关闭"] = "Off", ["力量"] = "Strength", ["敏捷"] = "Agility", ["耐久"] = "Durability", ["轮换"] = "Rotate"}
    local internalMode = modeMap[v] or "Off"
    if internalMode == "Off" then
        stopFarm()
        notify("自动挂机", "已停止", "warning")
    else
        State.FarmMode = internalMode
        startFarm()
        notify("自动挂机", "模式已设置为 " .. v, "info")
    end
end)

GuiLibrary:CreateDropdown(FarmTab, "力量获取方式", {"自动 (最快)", "器械", "工具 (最适合转生)"}, function(v)
    local sourceMap = {["自动 (最快)"] = "Auto (Fastest)", ["器械"] = "Machines", ["工具 (最适合转生)"] = "Tools (Best for Rebirth)"}
    State.StrengthSource = sourceMap[v] or "Auto (Fastest)"
    Runtime.Rates = {}
    Runtime.Blacklist = {}
    if State.FarmMode == "Strength" then startFarm() end
end)

local function setFarmMode(mode)
    if farmModeDropdown and farmModeDropdown.SetValue then
        pcall(farmModeDropdown.SetValue, mode == "Off" and "关闭" or (mode == "Strength" and "力量" or (mode == "Agility" and "敏捷" or (mode == "Durability" and "耐久" or "轮换"))))
    elseif mode == "Off" then
        stopFarm()
    else
        State.FarmMode = mode
        startFarm()
    end
end

if State.FarmMode ~= "Off" then setFarmMode("Off") end

GuiLibrary:CreateLabel(FarmTab, "轮换模式会自动在力量、敏捷和耐久之间切换。")
GuiLibrary:CreateLabel(FarmTab, "快速转生请选择工具(快捷栏)。程序会自动选择最高收益来源。")

GuiLibrary:CreateSection(FarmTab, "自动转生")

local rebirthLabel = GuiLibrary:CreateLabel(FarmTab, "下一次转生所需: ?")

GuiLibrary:CreateToggle(FarmTab, "自动转生", false, function(v)
    State.AutoRebirth = v
    if v then requestAutoRebirth() end
end)

GuiLibrary:CreateButton(FarmTab, "立即转生", function()
    spawnTask(function()
        local wasFarming = State.FarmMode
        Runtime.FarmToken = Runtime.FarmToken + 1
        local gained = rebirthChain(50, true)
        notify("转生", gained > 0 and (gained .. " 次转生") or "拒绝 (力量不足)",
            gained > 0 and "success" or "error")
        if wasFarming ~= "Off" then startFarm() end
    end)
end)

GuiLibrary:CreateButton(FarmTab, "停止挂机 / 解除角色卡住", function()
    setFarmMode("Off")
end)

GuiLibrary:CreateSection(BoostTab, "消耗品")

local boostLabel = GuiLibrary:CreateLabel(BoostTab, "背包持有: -")

GuiLibrary:CreateLabel(BoostTab, "自动使用背包中的加成道具。")
GuiLibrary:CreateToggle(BoostTab, "自动使用加成", false, function(v) State.AutoBoosts = v end)
GuiLibrary:CreateButton(BoostTab, "立即使用所有加成", function() spawnTask(function() useBoosts(true) end) end)

local ultLabel = nil

GuiLibrary:CreateSection(CollectTab, "自动领取")
GuiLibrary:CreateLabel(CollectTab, "开启你想自动领取的奖励。")

GuiLibrary:CreateToggle(CollectTab, "自动宝箱 (6小时间隔)", false, function(v) State.AutoChests = v end)
GuiLibrary:CreateToggle(CollectTab, "自动群组奖励", false, function(v) State.AutoGroup = v end)
GuiLibrary:CreateToggle(CollectTab, "自动免费礼物 (在线时长)", false, function(v) State.AutoGifts = v end)
GuiLibrary:CreateToggle(CollectTab, "自动幸运转盘 (免费次数)", false, function(v) State.AutoWheel = v end)
GuiLibrary:CreateToggle(CollectTab, "自动接取并完成NPC任务", false, function(v)
    State.AutoQuests = v
    if v then spawnTask(updateNpcQuests) end
end)

GuiLibrary:CreateSection(CollectTab, "手动操作")

GuiLibrary:CreateButton(CollectTab, "立即领取所有宝箱", function() spawnTask(claimChests) end)
GuiLibrary:CreateButton(CollectTab, "立即领取群组奖励", function() spawnTask(claimGroup) end)
GuiLibrary:CreateButton(CollectTab, "立即领取免费礼物", function() spawnTask(claimGifts) end)
GuiLibrary:CreateButton(CollectTab, "立即转动幸运转盘", function() spawnTask(spinWheel) end)
GuiLibrary:CreateButton(CollectTab, "立即接取/完成NPC任务", function() spawnTask(updateNpcQuests) end)

GuiLibrary:CreateSection(PetsTab, "宠物孵化")
GuiLibrary:CreateLabel(PetsTab, "选择一个水晶，然后使用自动孵化或手动孵化按钮。")

local crystalNames = {}
for _, c in ipairs(crystalPrices:GetChildren()) do table.insert(crystalNames, c.Name) end
table.sort(crystalNames)

local hatchLabel = GuiLibrary:CreateLabel(PetsTab, "已选择: Blue Crystal")

GuiLibrary:CreateDropdown(PetsTab, "水晶", crystalNames, function(v)
    State.HatchCrystal = v
    local price, kind = crystalCost(v)
    if hatchLabel then hatchLabel.SetText(("已选择: %s  |  %s %s"):format(v, short(price or 0), kind or "Gems")) end
end)

GuiLibrary:CreateToggle(PetsTab, "自动孵化", false, function(v) State.AutoHatch = v end)

GuiLibrary:CreateButton(PetsTab, "孵化 x1", function()
    spawnTask(function()
        local ok, info = hatchOnce(State.HatchCrystal)
        notify("孵化", ok and info or ("失败: " .. tostring(info)), ok and "success" or "error")
    end)
end)

GuiLibrary:CreateButton(PetsTab, "孵化 x10", function()
    spawnTask(function()
        local got = 0
        for _ = 1, 10 do
            if hatchOnce(State.HatchCrystal) then got = got + 1 else break end
            task.wait(0.3)
        end
        notify("孵化", "成功孵化 " .. got .. " 只宠物", got > 0 and "success" or "warning")
    end)
end)

GuiLibrary:CreateSection(PetsTab, "宠物管理")

GuiLibrary:CreateLabel(PetsTab, "加成宠物排在最前且不会被自动出售：")
GuiLibrary:CreateLabel(PetsTab, "Swift Samurai +15% 挥动速度  |  Powercore Hound +25% 力量, +15% 耐久")
GuiLibrary:CreateLabel(PetsTab, "Tribal Overlord 每次+2转生  |  Speedy Sally 降低转生要求")

GuiLibrary:CreateToggle(PetsTab, "自动装备最佳宠物", false, function(v) State.AutoEquipPets = v end)
GuiLibrary:CreateButton(PetsTab, "立即装备最佳宠物", function() spawnTask(equipBestPets) end)

GuiLibrary:CreateMultiSelect(PetsTab, "自动出售稀有度", {"Basic", "Rare", "Epic", "Unique", "Advanced"}, {}, function(sel)
    State.SellRarities = sel or {}
end)

GuiLibrary:CreateToggle(PetsTab, "自动出售选中稀有度的宠物", false, function(v) State.AutoSellPets = v end)
GuiLibrary:CreateButton(PetsTab, "立即出售选中稀有度宠物", function() spawnTask(sellJunkPets) end)

local currentPetNames = inventoryPetNames()
if #currentPetNames == 0 then currentPetNames = {"未找到宠物"} end

GuiLibrary:CreateLabel(PetsTab, "精确名称删除会清除所有未装备的同名宠物副本；已装备和加成宠物受保护。")
GuiLibrary:CreateMultiSelect(PetsTab, "自动删除宠物名称", currentPetNames, {}, function(sel)
    State.DeletePetNames = sel or {}
end)
GuiLibrary:CreateToggle(PetsTab, "自动删除选中的宠物", false, function(v) State.AutoDeletePets = v end)
GuiLibrary:CreateButton(PetsTab, "立即删除选中宠物", function()
    spawnTask(function()
        local n = deleteSelectedPets()
        notify("宠物", "已删除 " .. n .. " 只宠物", n > 0 and "success" or "warning")
    end)
end)

GuiLibrary:CreateSection(PetsTab, "宠物进化")
GuiLibrary:CreateLabel(PetsTab, "自动进化会将每 5 只相同的未进化宠物进行合成。")
GuiLibrary:CreateToggle(PetsTab, "自动进化所有准备就绪的宠物", false, function(v) State.AutoEvolvePets = v end)
GuiLibrary:CreateButton(PetsTab, "立即进化所有就绪宠物", function()
    spawnTask(function()
        local n = evolveReadyPets()
        notify("宠物进化", "已进化 " .. n .. " 只宠物", n > 0 and "success" or "warning")
    end)
end)

GuiLibrary:CreateSection(StatsTab, "实时属性")

local sStrength   = GuiLibrary:CreateLabel(StatsTab, "力量: -")
local sAgility    = GuiLibrary:CreateLabel(StatsTab, "敏捷: -")
local sDurability = GuiLibrary:CreateLabel(StatsTab, "耐久: -")
local sCurrency   = GuiLibrary:CreateLabel(StatsTab, "钻石: -")
local sRebirths   = GuiLibrary:CreateLabel(StatsTab, "转生: -")

GuiLibrary:CreateProgressBar(StatsTab, "转生进度", function()
    local need = rebirthTarget()
    if need <= 0 or need == math.huge then return 0 end
    return Strength.Value / need
end)

GuiLibrary:CreateSection(StatsTab, "会话统计")

local sRate    = GuiLibrary:CreateLabel(StatsTab, "每分钟收益: -")
local sSession = GuiLibrary:CreateLabel(StatsTab, "会话详情: -")

GuiLibrary:CreateButton(StatsTab, "重置会话计数器", function()
    Runtime.Reps, Runtime.Hatched, Runtime.Claimed = 0, 0, 0
    Runtime.RebirthCount, Runtime.Boosts, Runtime.Upgrades, Runtime.Evolved = 0, 0, 0, 0
    Runtime.StartClock = os.clock()
    Runtime.StartStats = {Strength = Strength.Value, Agility = Agility.Value, Durability = Durability.Value}
end)

GuiLibrary:CreateSection(MiscTab, "实用工具")
GuiLibrary:CreateLabel(MiscTab, "防挂机与通知功能已自动启用。")
GuiLibrary:CreateToggle(MiscTab, "在肌肉国王健身房保持工具挂机", false, function(v)
    State.AlwaysKingsGym = v
    if v then spawnTask(teleportToKingsGym) end
end)

GuiLibrary:CreateSection(MiscTab, "传送")

local areaParts = areaTeleportParts
local areaNames = {}
if areaParts then
    for _, p in ipairs(areaParts:GetChildren()) do table.insert(areaNames, p.Name) end
    table.sort(areaNames)
end
if #areaNames == 0 then areaNames = {"无"} end

local selectedArea = areaNames[1]
GuiLibrary:CreateDropdown(MiscTab, "区域传送点", areaNames, function(v) selectedArea = v end)

GuiLibrary:CreateButton(MiscTab, "传送到区域", function()
    spawnTask(function()
        if not areaParts then return end
        local part = areaParts:FindFirstChild(selectedArea)
        if not part or not alive() then return end
        Runtime.FarmToken = Runtime.FarmToken + 1
        leaveMachine()
        for _ = 1, 10 do anchorAt(part.CFrame * CFrame.new(0, 6, 0)) task.wait(0.1) end
        if State.FarmMode ~= "Off" then startFarm() end
    end)
end)

GuiLibrary:CreateButton(MiscTab, "重新加入服务器", function()
    pcall(function() Remotes.Rejoin:FireServer() end)
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
end)

GuiLibrary:CreateSection(MiscTab, "会话控制")

GuiLibrary:CreateButton(MiscTab, "停止所有自动化", function()
    State.AutoHatch, State.AutoBoosts, State.AutoUltimates = false, false, false
    State.AutoChests, State.AutoGroup, State.AutoGifts, State.AutoWheel, State.AutoQuests = false, false, false, false, false
    State.AutoEquipPets, State.AutoSellPets, State.AutoDeletePets = false, false, false
    State.AutoEvolvePets, State.AutoRebirth, State.AlwaysKingsGym = false, false, false
    setFarmMode("Off")
    notify("自动挂机", "所有自动化已停止", "warning")
end)

spawnTask(function()
    local repsProgress = repsCounter()
    local lastReps = repsProgress and repsProgress.Value or 0
    local repsStart = lastReps
    while running() do
        elevate()
        local elapsed = math.max(os.clock() - Runtime.StartClock, 1)
        local perMin = 60 / elapsed
        if statusLabel then statusLabel.SetText("状态: " .. Runtime.Status) end
        if targetLabel then targetLabel.SetText("目标: " .. Runtime.Target) end
        if benchLabel then benchLabel.SetText("基准测试: " .. Runtime.Bench) end
        if rebirthLabel then
            rebirthLabel.SetText(("下一次转生: %s 力量 (当前有 %s)"):format(short(rebirthTarget()), short(Strength.Value)))
        end
        if boostLabel then
            local counts = {}
            for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if TIMED_BOOSTS[tool.Name] or INSTANT_BOOSTS[tool.Name] then
                    counts[tool.Name] = (counts[tool.Name] or 0) + 1
                end
            end
            local parts = {}
            for name, n in pairs(counts) do parts[#parts + 1] = name .. " x" .. n end
            boostLabel.SetText("背包持有: " .. (#parts > 0 and table.concat(parts, ", ") or "无"))
        end
        if ultLabel then
            local owned, total = 0, 0
            for _, u in ipairs(gameUltimates:GetChildren()) do
                local maxUp = u:FindFirstChild("maxUpgrades")
                local lvl = dataIndex("ultimatesFolder", u.Name)
                if type(lvl) ~= "number" then lvl = 0 end
                owned = owned + lvl
                total = total + (maxUp and maxUp.Value or 0)
            end
            ultLabel.SetText(("终极天赋: %d/%d 级  |  可用转生点: %s"):format(owned, total, short(Rebirths.Value)))
        end
        if sStrength then sStrength.SetText("力量: " .. short(Strength.Value)) end
        if sAgility then sAgility.SetText("敏捷: " .. short(Agility.Value)) end
        if sDurability then sDurability.SetText("耐久: " .. short(Durability.Value)) end
        if sCurrency then sCurrency.SetText(("钻石: %s   代币: %s"):format(short(Gems.Value), short(Tokens.Value))) end
        if sRebirths then sRebirths.SetText("转生次数: " .. short(Rebirths.Value)) end
        if sRate then
            sRate.SetText(("每分钟收益  力量 %s  敏捷 %s  耐久 %s"):format(
                short(math.floor((Strength.Value - Runtime.StartStats.Strength) * perMin)),
                short(math.floor((Agility.Value - Runtime.StartStats.Agility) * perMin)),
                short(math.floor((Durability.Value - Runtime.StartStats.Durability) * perMin))))
        end
        if sSession then
            local landed = repsProgress and (repsProgress.Value - repsStart) or 0
            sSession.SetText(("达成次数: %d (%.1f/s)   发送: %d   孵化: %d   进化: %d   领取: %d   加成: %d   升级: %d   转生: %d")
                :format(landed, landed / elapsed, Runtime.Reps, Runtime.Hatched, Runtime.Evolved,
                        Runtime.Claimed, Runtime.Boosts, Runtime.Upgrades, Runtime.RebirthCount))
        end
        task.wait(0.5)
    end
end)

SESSION.State = State
SESSION.Runtime = Runtime
SESSION.api = {
    startFarm = function() startFarm() end,
    setMode = setFarmMode,
    stopFarm = stopFarm,
    generation = MY_GENERATION,
    generationAlive = generationAlive,
    ui = {farmMode = farmModeDropdown},
    candidateSources = candidateSources,
    teleportToKingsGym = teleportToKingsGym,
    machineSources = machineSources,
    toolSources = toolSources,
    rebirthTarget = rebirthTarget,
    useBoosts = useBoosts,
    upgradeUltimates = upgradeUltimates,
    claimChests = claimChests,
    claimGifts = claimGifts,
    collectQuests = collectQuests,
    acceptNpcQuests = acceptNpcQuests,
    equipBestPets = equipBestPets,
    deleteSelectedPets = deleteSelectedPets,
    evolveReadyPets = evolveReadyPets,
    hatchOnce = hatchOnce,
    rebirthChain = rebirthChain,
}

notify("肌肉传奇", "自动挂机 v2 已加载", "success", 4)