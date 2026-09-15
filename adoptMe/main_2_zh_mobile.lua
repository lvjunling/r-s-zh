if getgenv().PerformanceFarmerCleanup then
    pcall(getgenv().PerformanceFarmerCleanup)
end

if getgenv().AutoBaby == nil then getgenv().AutoBaby = true end
if getgenv().AutoCompleteTasks == nil then getgenv().AutoCompleteTasks = true end
if getgenv().AutoSwapFullGrown == nil then getgenv().AutoSwapFullGrown = false end
if getgenv().SelectedPetKind == nil then getgenv().SelectedPetKind = "cat" end
if getgenv().FPSCap == nil then getgenv().FPSCap = 15 end
if getgenv().UltraLowGFX == nil then getgenv().UltraLowGFX = true end
if getgenv().MuteAudio == nil then getgenv().MuteAudio = true end
if getgenv().Disable3DRendering == nil then getgenv().Disable3DRendering = true end
if getgenv().WebhookEnabled == nil then getgenv().WebhookEnabled = false end
if getgenv().WebhookURL == nil then getgenv().WebhookURL = "" end
if getgenv().WebhookInterval == nil then getgenv().WebhookInterval = 5 end
if getgenv().WebhookOnTask == nil then getgenv().WebhookOnTask = false end

local function elevate()
    if setthreadidentity then
        setthreadidentity(8)
    elseif setidentity then
        setidentity(8)
    end
end

elevate()

local function rename(remotename, hashedremote)
    pcall(function()
        if typeof(hashedremote) == "Instance" then
            hashedremote.Name = remotename
        end
    end)
end

local getup = getupvalue or (debug and debug.getupvalue)
local getups = getupvalues or (debug and debug.getupvalues)
local AC_MODULE = game:GetService("ReplicatedStorage").ClientModules.Core.RouterClient.RouterClient
local initFunction = require(AC_MODULE).init
local upvalueTable = nil

if getup then
    pcall(function()
        upvalueTable = getup(initFunction, 7)
    end)
end

if type(upvalueTable) ~= "table" and getups then
    pcall(function()
        for _, u in ipairs(getups(initFunction)) do
            if type(u) == "table" and (u["TeamAPI/ChooseTeam"] ~= nil or u["HousingAPI/ActivateFurniture"] ~= nil) then
                upvalueTable = u
                break
            end
        end
    end)
end

if type(upvalueTable) == "table" then
    for k, v in pairs(upvalueTable) do
        rename(k, v)
    end
else
    print("patch rip")
end

if getgenv().AdoptMeHubCleanup then
    pcall(getgenv().AdoptMeHubCleanup)
end

if getgenv().AdoptMeHub then
    pcall(function()
        if getgenv().AdoptMeHub.Root and getgenv().AdoptMeHub.Root.Parent then
            getgenv().AdoptMeHub.Root.Parent:Destroy()
        end
        getgenv().AdoptMeHub:Destroy()
    end)
end

local hubActive = true
getgenv().AdoptMeHubCleanup = function()
    hubActive = false
    pcall(function()
        if getgenv().AdoptMeHub and getgenv().AdoptMeHub.Root and getgenv().AdoptMeHub.Root.Parent then
            getgenv().AdoptMeHub.Root.Parent:Destroy()
        end
    end)
end

if hookmetamethod and not getgenv().AdoptMeCameraHooked then
    pcall(function()
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", function(t, k, v)
            if tostring(k) == "CameraMinZoomDistance" and tonumber(v) and tonumber(v) >= 5 then
                return oldNewIndex(t, k, 0.5)
            end
            return oldNewIndex(t, k, v)
        end)
        getgenv().AdoptMeCameraHooked = true
    end)
end



local farmerActive = true
local currentActivity = "监控需求中"
local updateStatsUI
local function setActivity(act)
    currentActivity = act or "监控需求中"
    if updateStatsUI then
        pcall(updateStatsUI)
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local lp = LP

pcall(function()
    for _, v in pairs(getconnections(lp.Idled)) do
        pcall(function() v:Disable() end)
        pcall(function() v:Disconnect() end)
    end
end)

local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local RouterClient = Fsys.load("RouterClient")
local ClientData = Fsys.load("ClientData")
local InteriorsM = Fsys.load("InteriorsM")
local EquippedPets = Fsys.load("EquippedPets")
local PetActions = Fsys.load("PetActions")
local CameraUtil = Fsys.load("CameraUtil")

pcall(function()
    setthreadidentity(2)
    local UIManager = Fsys.load("UIManager")
    local fpa = UIManager and UIManager.apps and UIManager.apps.FocusPetApp
    if fpa then
        local mod = game:GetService("ReplicatedStorage").ClientModules.Core.UIManager.Apps.FocusPetApp.FocusPetApp
        local orig = require(mod)
        fpa.capture_focus = orig.capture_focus
        fpa.release_focus = orig.release_focus
        if fpa.camera then
            fpa.camera.capture_focus = function() return end
            fpa.camera.update = function() return end
        end
        if fpa.instance then
            fpa.instance.Enabled = false
        end
    end
    setthreadidentity(8)
end)

local CFG = {
    AutoBaby = true,
    AutoCompleteTasks = true,
    AutoSwapFullGrown = false,
    SelectedPetKind = "cat",
    AutoDoQuests = false,
    AutoClaimQuests = false,
    AutoClaimTabBonus = false,
    AutoClaimDailyLogin = false,
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookInterval = 5,
    WebhookOnTask = false
}

local lastWebhookSendTime = 0

local taskDisplayNames = {
    sleepy = "困倦（需要床或婴儿床）",
    hungry = "饥饿（需要食物）",
    thirsty = "口渴（需要水或饮料）",
    dirty = "脏了（需要洗澡）",
    toilet = "如厕（需要马桶）",
    bored = "无聊（前往游乐场）",
    school = "上学（前往学校）",
    salon = "沙龙（前往沙龙）",
    pizza_party = "披萨派对（前往披萨店）",
    camping = "露营（前往营地）",
    beach_party = "海滩派对（前往海滩）",
    pool_party = "泳池派对（前往泳池）",
    sick = "生病（使用治疗苹果）",
    pet_me = "抚摸（与宠物互动）",
    mystery = "选择（神秘需求）",
    ride = "骑乘（骑宠物）",
    walk = "散步（带宠物散步）",
    play = "玩耍（给宠物扔玩具）",
    party_zone = "派对（管理员活动）"
}

local outdoorLocations = {
    bored = CFrame.new(-401.63, 31, -1760.05),
    beach_party = CFrame.new(-670.98, 35.5, -1413.08),
    camping = CFrame.new(-18.44, 35.5, -1046.0),
    pool_party = CFrame.new(-670.98, 35.5, -1413.08)
}

local interiorLocations = {
    school = { dest = "School", door = "MainDoor" },
    salon = { dest = "Salon", door = "MainDoor" },
    pizza_party = { dest = "PizzaShop", door = "MainDoor" }
}

local function notify(data)
    elevate()
end

local function resetCameraZoom(targetDist)
    pcall(function()
        LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        LP.CameraMinZoomDistance = 0.5
        LP.CameraMaxZoomDistance = 128
        local cam = workspace.CurrentCamera
        local char = LP.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if cam and hum and cam.CameraSubject ~= hum then
            cam.CameraSubject = hum
        end
        local desiredDist = targetDist or 25
        if CameraUtil and CameraUtil.set_zoom_distance then
            CameraUtil.set_zoom_distance(desiredDist)
        end
    end)
end

pcall(function()
    if CameraUtil and CameraUtil.set_zoom_distance then
        local originalSetZoom = CameraUtil.set_zoom_distance
        CameraUtil.set_zoom_distance = function(dist, ...)
            if tonumber(dist) and tonumber(dist) < 15 then
                dist = 22
            end
            return originalSetZoom(dist, ...)
        end
    end
end)

pcall(function()
    LP:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(function()
        if LP.CameraMinZoomDistance > 1 then
            LP.CameraMinZoomDistance = 0.5
        end
    end)
    LP:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
        if LP.CameraMaxZoomDistance < 15 then
            LP.CameraMaxZoomDistance = 128
        end
    end)
end)

task.spawn(function()
    while farmerActive do
        task.wait(3)
        pcall(function()
            LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
            if LP.CameraMaxZoomDistance < 15 then
                LP.CameraMaxZoomDistance = 128
            end
            if LP.CameraMinZoomDistance > 1 then
                LP.CameraMinZoomDistance = 0.5
            end
            local cam = workspace.CurrentCamera
            if cam then
                local char = LP.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum and cam.CameraSubject and cam.CameraSubject ~= hum then
                    local isSeat = cam.CameraSubject:IsA("Seat") or cam.CameraSubject:IsA("VehicleSeat")
                    if not isSeat then
                        cam.CameraSubject = hum
                    end
                end
                local currentDist = (cam.CFrame.Position - cam.Focus.Position).Magnitude
                if currentDist < 8 then
                    if CameraUtil and CameraUtil.set_zoom_distance then
                        CameraUtil.set_zoom_distance(22)
                    end
                end
            end
        end)
    end
end)

local function formatTaskName(raw)
    return taskDisplayNames[raw] or (raw:sub(1, 1):upper() .. raw:sub(2):gsub("_", " "))
end

local function getCurrentTeam()
    local team = ClientData.get("team")
    if team then return team end
    return (LP.Team and LP.Team.Name) or "None"
end

local function switchToRole(roleName)
    elevate()
    local s, err = pcall(function()
        RouterClient.get("TeamAPI/ChooseTeam"):InvokeServer(roleName, {
            dont_respawn = true,
            source_for_logging = "avatar_editor"
        })
    end)
    return s, err
end

local function ensureBaby()
    elevate()
    if getCurrentTeam() ~= "Babies" then
        setActivity("正在切换为宝宝")
        switchToRole("Babies")
        notify({
            Title = "身份已更新",
            Content = "已切换为宝宝！",
            Duration = 2.5
        })
    end
end

local function getEquippedPetWrapper()
    local myPets = EquippedPets.get_my_equipped()
    local pet = myPets and myPets[1]
    if pet then
        return EquippedPets.get_wrapper_from_item(pet)
    end
    return nil
end

local function getActivePetModel()
    local wrapper = getEquippedPetWrapper()
    if wrapper and wrapper.char then
        return wrapper.char
    end
    local petsFolder = workspace:FindFirstChild("Pets")
    if petsFolder then
        local first = petsFolder:FindFirstChildOfClass("Model")
        if first then return first end
    end
    return nil
end

local function getPetDisplayName(kind)
    local name = nil
    pcall(function()
        setthreadidentity(2)
        local InventoryDB = Fsys.load("InventoryDB")
        if InventoryDB and InventoryDB.pets and InventoryDB.pets[kind] then
            name = InventoryDB.pets[kind].name
        end
        setthreadidentity(8)
    end)
    if not name or name == "" then
        name = kind:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    end
    return name
end

local function getOwnedPetKinds()
    local kinds = {}
    local myData = ClientData.get_data()[LP.Name] or {}
    local pets = myData.inventory and myData.inventory.pets or {}
    for _, info in pairs(pets) do
        local k = info.kind
        if k and not table.find(kinds, k) then
            table.insert(kinds, k)
        end
    end
    table.sort(kinds, function(a, b)
        return getPetDisplayName(a):lower() < getPetDisplayName(b):lower()
    end)
    return kinds
end

local petKindByDisplayName = {}
local function getPetDropdownValues()
    local values = { "Current / Equipped", "Any Pet (Auto Swap)" }
    petKindByDisplayName = {
        ["Current / Equipped"] = "current",
        ["Any Pet (Auto Swap)"] = "any"
    }

    local kinds = getOwnedPetKinds()
    for _, kind in ipairs(kinds) do
        local disp = getPetDisplayName(kind)
        if not table.find(values, disp) then
            table.insert(values, disp)
            petKindByDisplayName[disp] = kind
        else
            local dispWithKind = disp .. " (" .. kind .. ")"
            table.insert(values, dispWithKind)
            petKindByDisplayName[dispWithKind] = kind
        end
    end

    return values
end

local function findPetToEquip(targetKindFilter, requireNotFullGrown)
    local myData = ClientData.get_data()[LP.Name] or {}
    local pets = myData.inventory and myData.inventory.pets or {}

    local myEquipped = nil
    pcall(function()
        setthreadidentity(2)
        myEquipped = EquippedPets.get_my_equipped()
        setthreadidentity(8)
    end)
    local currentUnique = myEquipped and myEquipped[1] and myEquipped[1].unique

    if targetKindFilter and targetKindFilter ~= "" and targetKindFilter ~= "any" and targetKindFilter ~= "current" then
        for unique, info in pairs(pets) do
            if unique ~= currentUnique and info.kind == targetKindFilter then
                return unique, info
            end
        end
    end

    if requireNotFullGrown then
        for unique, info in pairs(pets) do
            if unique ~= currentUnique then
                local age = (info.properties and info.properties.age) or 1
                if age < 6 then
                    return unique, info
                end
            end
        end
    end

    return nil, nil
end

local function swapToPet(unique, petInfo)
    elevate()
    local s = pcall(function()
        RouterClient.get("ToolAPI/Equip"):InvokeServer(unique, {})
    end)
    if s then
        task.wait(0.5)
        local name = (petInfo and petInfo.properties and petInfo.properties.name) or (petInfo and petInfo.kind and getPetDisplayName(petInfo.kind)) or "Pet"
        local age = (petInfo and petInfo.properties and petInfo.properties.age) or 1
        local ageStages = { "新生", "幼年", "少年", "青年", "Post-青年", "完全长大" }
        local ageName = ageStages[age] or ("年龄 " .. tostring(age))
        notify({
            Title = "宠物已装备",
            Content = "当前培养：" .. name .. " (" .. ageName .. ")",
            Duration = 3
        })
        pcall(updateDashboardDisplay)
        return true
    end
    return false
end

local lastAutoSwapCheck = 0
local function checkAndAutoSwapPet()
    if not CFG.AutoSwapFullGrown and (CFG.SelectedPetKind == "current" or not CFG.SelectedPetKind) then
        return
    end

    if tick() - lastAutoSwapCheck < 4 then return end
    lastAutoSwapCheck = tick()

    elevate()
    local myPets = nil
    pcall(function()
        setthreadidentity(2)
        myPets = EquippedPets.get_my_equipped()
        setthreadidentity(8)
    end)

    local currentPet = myPets and myPets[1]
    local myData = ClientData.get_data()[LP.Name] or {}
    local pets = myData.inventory and myData.inventory.pets or {}

    local targetKind = CFG.SelectedPetKind
    local targetKindActual = (targetKind ~= "current" and targetKind ~= "any") and targetKind or nil

    if not currentPet then
        local u, info = findPetToEquip(targetKindActual, CFG.AutoSwapFullGrown)
        if u and info then
            swapToPet(u, info)
        end
        return
    end

    local currentInfo = pets[currentPet.unique] or currentPet
    local current年龄 = (currentInfo.properties and currentInfo.properties.age) or 1
    local currentKind = currentInfo.kind

    local isFullGrown = (current年龄 >= 6)
    local wrongKind = targetKindActual and (currentKind ~= targetKindActual)

    if (CFG.AutoSwapFullGrown and isFullGrown) or wrongKind then
        local u, info = findPetToEquip(targetKindActual, CFG.AutoSwapFullGrown)
        if u and info then
            swapToPet(u, info)
        elseif CFG.AutoSwapFullGrown and isFullGrown and targetKindActual then
            local fallbackU, fallbackInfo = findPetToEquip(nil, true)
            if fallbackU and fallbackInfo then
                swapToPet(fallbackU, fallbackInfo)
            end
        end
    end
end

local function ensureFarmPlatform()
    local platform = workspace:FindFirstChild("AdoptMeFarmPlatform")
    local defaultBasePos = Vector3.new(-5986, 3920, -9014)

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Position.Y > 3000 then
        defaultBasePos = Vector3.new(hrp.Position.X, 3920, hrp.Position.Z)
    end

    if not platform then
        platform = Instance.new("Part")
        platform.Name = "AdoptMeFarmPlatform"
        platform.Size = Vector3.new(120, 2, 120)
        platform.Position = defaultBasePos
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = Enum.Material.SmoothPlastic
        platform.BrickColor = BrickColor.new("Medium stone grey")
        platform.Parent = workspace
    else
        if platform.Position.Y > 3950 then
            platform.Position = Vector3.new(platform.Position.X, 3920, platform.Position.Z)
        end
    end
    return platform
end

local function teleportToPlatform()
    elevate()
    local platform = ensureFarmPlatform()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and platform then
        hrp.CFrame = CFrame.new(platform.Position + Vector3.new(0, 4, 0))
    end
end

local function ensureInsideHouse()
    elevate()
    local curLoc = InteriorsM.get_current_location()
    if not (curLoc and curLoc.destination_id == "housing") then
        pcall(function()
            setthreadidentity(2)
            InteriorsM.enter("housing", "MainDoor", { house_owner = LP })
            elevate()
        end)
        local t0 = tick()
        repeat
            task.wait(0.5)
            curLoc = InteriorsM.get_current_location()
        until (curLoc and curLoc.destination_id == "housing") or (tick() - t0 > 8)
    end
    if curLoc and curLoc.destination_id == "housing" then
        task.wait(0.4)
        teleportToPlatform()
    end
    return curLoc and curLoc.destination_id == "housing"
end

pcall(function()
    InteriorsM.on_location_changed:Connect(function(loc)
        resetCameraZoom()
        if loc and loc.destination_id == "housing" then
            task.wait(0.6)
            teleportToPlatform()
            resetCameraZoom()
        end
    end)
end)

local function enterBuilding(destName, doorName)
    elevate()
    local s, err = pcall(function()
        setthreadidentity(2)
        InteriorsM.enter(destName, doorName or "MainDoor")
        elevate()
    end)
    return s, err
end

local function findCampBed()
    local sm = workspace:FindFirstChild("StaticMap")
    local camp = sm and sm:FindFirstChild("Campsite")
    if camp then
        for _, desc in ipairs(camp:GetDescendants()) do
            if desc:IsA("Model") and (desc.Name:lower():find("bed") or desc.Name:lower():find("cot") or desc.Name:lower():find("tent") or desc.Name:lower():find("sleepingbag") or desc.Name:lower():find("sleep")) then
                local ub = desc:FindFirstChild("UseBlocks")
                if ub and #ub:GetChildren() > 0 then
                    return desc, ub:GetChildren()[1]
                end
                local seat = desc:FindFirstChildWhichIsA("Seat")
                if seat then
                    return desc, seat
                end
            end
        end
        for _, desc in ipairs(camp:GetDescendants()) do
            if desc:IsA("Seat") then
                return desc.Parent, desc
            end
        end
    end
    return nil, nil
end

local function teleportToOutdoor(targetCFrame, taskName)
    elevate()
    pcall(function()
        setthreadidentity(2)
        InteriorsM.enter("MainMap", "NeighborhoodDoor")
        task.wait(1.5)
        elevate()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dest = targetCFrame
            local sm = workspace:FindFirstChild("StaticMap")
            if sm then
                if taskName == "bored" or dest == outdoorLocations.bored then
                    local park = sm:FindFirstChild("Park")
                    local target = park and (park:FindFirstChild("BoredAilmentTarget") or park:FindFirstChild("AilmentTarget"))
                    if target then
                        dest = target.CFrame + Vector3.new(0, 3, 0)
                    end
                elseif taskName == "camping" or dest == outdoorLocations.camping then
                    local camp = sm:FindFirstChild("Campsite")
                    local origin = camp and camp:FindFirstChild("CampsiteOrigin")
                    if origin then
                        dest = origin.CFrame + Vector3.new(0, 2.5, 0)
                    end
                elseif taskName == "beach_party" or taskName == "pool_party" or dest == outdoorLocations.beach_party or dest == outdoorLocations.pool_party then
                    local beach = sm:FindFirstChild("Beach")
                    local target = beach and (beach:FindFirstChild("BeachPartyAilmentTarget") or beach:FindFirstChild("BeachPartyNavTarget"))
                    if target then
                        dest = target.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
            hrp.CFrame = dest

            if taskName == "camping" or dest == outdoorLocations.camping then
                task.spawn(function()
                    task.wait(1)
                    local campModel, campPart = findCampBed()
                    if campPart and campModel then
                        local wrapper = getEquippedPetWrapper()
                        local petChar = wrapper and (wrapper.char or wrapper.character)
                        if not petChar then petChar = getActivePetModel() end
                        if petChar then
                            pcall(function()
                                RouterClient.get("HousingAPI/ActivateFurniture"):InvokeServer(
                                    LP,
                                    campModel:GetAttribute("furniture_unique") or campModel.Name,
                                    campPart.Name,
                                    { cframe = campPart.CFrame },
                                    petChar
                                )
                            end)
                        end
                        local currentChar = LP.Character
                        local hum = currentChar and currentChar:FindFirstChild("Humanoid")
                        if hum and campPart:IsA("Seat") then
                            pcall(function() campPart:Sit(hum) end)
                        elseif currentChar then
                            pcall(function()
                                RouterClient.get("HousingAPI/ActivateFurniture"):InvokeServer(
                                    LP,
                                    campModel:GetAttribute("furniture_unique") or campModel.Name,
                                    campPart.Name,
                                    { cframe = campPart.CFrame },
                                    currentChar
                                )
                            end)
                        end
                    end
                end)
            end
        end
    end)
end

local activeFurnitureInUse = {}

local function isFurnitureExcluded(unique, exclude)
    if not exclude then return false end
    if type(exclude) == "string" then return unique == exclude end
    if type(exclude) == "table" then return exclude[unique] ~= nil end
    if type(exclude) == "function" then return exclude(unique) end
    return false
end

local function findHouseFurniture(filterFn, excludeUnique)
    local house = workspace:FindFirstChild("HouseInteriors")
    local furn = house and house:FindFirstChild("furniture")
    if furn then
        for _, folder in ipairs(furn:GetChildren()) do
            for _, item in ipairs(folder:GetChildren()) do
                if filterFn(item.Name:lower()) then
                    local ub = item:FindFirstChild("UseBlocks")
                    if ub and #ub:GetChildren() > 0 then
                        local unique = item:GetAttribute("furniture_unique") or folder.Name:match("([^/]+)$")
                        if not isFurnitureExcluded(unique, excludeUnique) and not activeFurnitureInUse[unique] then
                            return unique, ub:GetChildren()[1], item
                        end
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function buyFreeFurniture(kindName)
    elevate()
    pcall(function()
        RouterClient.get("HousingAPI/BuyFurnitures"):InvokeServer({
            { kind = kindName, properties = { cframe = CFrame.new(0, 5, 0) } }
        })
    end)
    task.wait(1)
end

local function getBabyAilmentKeys()
    local myData = ClientData.get_data()[LP.Name] or {}
    local am = myData.ailments_manager or {}
    local ba = am.baby_ailments or {}
    local keys = {}
    for k, v in pairs(ba) do
        local key = nil
        if type(v) == "table" and v.kind then
            key = v.kind
        elseif type(v) == "table" and v.ailment_key then
            key = v.ailment_key
        elseif type(k) == "string" and not tonumber(k) then
            key = k
        elseif type(v) == "string" then
            key = v
        end
        if key then
            local normKey = tostring(key):match("^([^:]+)") or tostring(key)
            if not table.find(keys, normKey) then table.insert(keys, normKey) end
        end
    end
    return keys
end

local function getPetAilmentKeys()
    local myData = ClientData.get_data()[LP.Name] or {}
    local am = myData.ailments_manager or {}
    local petAilments = am.ailments or {}
    local keys = {}
    for _, ailments in pairs(petAilments) do
        for needKey, needData in pairs(ailments) do
            local key = (type(needData) == "table" and (needData.kind or needData.ailment_key)) or needKey
            local keyStr = tostring(key)
            local normKey = keyStr:match("^([^:]+)") or keyStr
            if not table.find(keys, normKey) then
                table.insert(keys, normKey)
            end
        end
    end
    return keys
end

local function isAilmentActive(taskKey, forBaby)
    if forBaby then
        local bKeys = getBabyAilmentKeys()
        return table.find(bKeys, taskKey) ~= nil
    else
        local pKeys = getPetAilmentKeys()
        return table.find(pKeys, taskKey) ~= nil
    end
end

local function unseatBaby()
    pcall(function()
        local char = LP.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        pcall(function()
            RouterClient.get("AdoptAPI/ExitSeatStates"):FireServer()
            RouterClient.get("AdoptAPI/MakeBabyJumpOutOfSeat"):FireServer(char)
            RouterClient.get("HousingAPI/AnimatedFurnitureExit"):FireServer()
            RouterClient.get("PetAPI/ExitFurnitureUseStates"):FireServer(char)
        end)
        if char then
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("Weld") and child.Name:lower():find("seat") then
                    child:Destroy()
                end
            end
        end
        if hum then
            hum.Sit = false
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 35, 0)
        end
    end)
end

local function completeSleep(forBaby, excludeUnique)
    elevate()
    ensureInsideHouse()
    local unique, blockPart, model = findHouseFurniture(function(name)
        if forBaby then
            return (name:find("crib") or name:find("bed")) and not name:find("pet")
        else
            return name:find("crib") or name:find("bed")
        end
    end, excludeUnique)
    if not unique then
        buyFreeFurniture("basiccrib")
        unique, blockPart, model = findHouseFurniture(function(name)
            return name:find("crib") or name:find("bed")
        end, excludeUnique)
    end
    if unique and blockPart then
        activeFurnitureInUse[unique] = forBaby and "Baby" or "Pet"
        local targetChar = forBaby and LP.Character or getActivePetModel()
        task.spawn(function()
            pcall(function()
                RouterClient.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    LP,
                    unique,
                    blockPart.Name,
                    { cframe = blockPart.CFrame },
                    targetChar
                )
            end)
        end)
        return unique
    end
    return nil
end

local function completeShower(forBaby, excludeUnique)
    elevate()
    ensureInsideHouse()
    local unique, blockPart, model = findHouseFurniture(function(name)
        if forBaby then
            return (name:find("shower") or name:find("bath") or name:find("tub")) and not name:find("pet")
        else
            return name:find("shower") or name:find("bath") or name:find("tub")
        end
    end, excludeUnique)
    if not unique then
        buyFreeFurniture("cheap_pet_bathtub")
        unique, blockPart, model = findHouseFurniture(function(name)
            return name:find("shower") or name:find("bath") or name:find("tub")
        end, excludeUnique)
    end
    if unique and blockPart then
        activeFurnitureInUse[unique] = forBaby and "Baby" or "Pet"
        local targetChar = forBaby and LP.Character or getActivePetModel()
        task.spawn(function()
            pcall(function()
                RouterClient.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    LP,
                    unique,
                    blockPart.Name,
                    { cframe = blockPart.CFrame },
                    targetChar
                )
            end)
        end)
        return unique
    end
    return nil
end

local function completeToilet(forBaby, excludeUnique)
    elevate()
    ensureInsideHouse()
    local unique, blockPart, model = findHouseFurniture(function(name)
        return name:find("toilet") or name:find("potty")
    end, excludeUnique)
    if not unique then
        buyFreeFurniture("toilet")
        unique, blockPart, model = findHouseFurniture(function(name)
            return name:find("toilet") or name:find("potty")
        end, excludeUnique)
    end
    if unique and blockPart then
        activeFurnitureInUse[unique] = forBaby and "Baby" or "Pet"
        local targetChar = forBaby and LP.Character or getActivePetModel()
        task.spawn(function()
            pcall(function()
                RouterClient.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    LP,
                    unique,
                    blockPart.Name,
                    { cframe = blockPart.CFrame },
                    targetChar
                )
            end)
        end)
        return unique
    end
    return nil
end

local function getOrBuyFreeFood(itemKind, excludeUnique)
    elevate()
    local myData = ClientData.get_data()[LP.Name] or {}
    local foodInv = myData.inventory and myData.inventory.food or {}
    for _, item in pairs(foodInv) do
        if (item.kind == itemKind or item.id == itemKind) and (not excludeUnique or item.unique ~= excludeUnique) and (not item.properties or not item.properties.uses_left or item.properties.uses_left > 0) then
            return item
        end
    end
    RouterClient.get("ShopAPI/BuyItem"):InvokeServer("food", itemKind, {})
    task.wait(0.4)
    myData = ClientData.get_data()[LP.Name] or {}
    for _, item in pairs(myData.inventory and myData.inventory.food or {}) do
        if (item.kind == itemKind or item.id == itemKind) and (not excludeUnique or item.unique ~= excludeUnique) and (not item.properties or not item.properties.uses_left or item.properties.uses_left > 0) then
            return item
        end
    end
    return nil
end

local function completeHungry(forBaby)
    elevate()
    if forBaby then
        local t0 = tick()
        while isAilmentActive("hungry", true) and tick() - t0 < 25 do
            local foodItem = getOrBuyFreeFood("schospital_refresh_2023_cafeteria_sandwich")
            if not foodItem then break end
            pcall(function()
                RouterClient.get("ToolAPI/Equip"):InvokeServer(foodItem.unique, {})
                task.wait(0.4)
                for i = 1, (foodItem.uses or 3) do
                    if not isAilmentActive("hungry", true) then break end
                    RouterClient.get("ToolAPI/ServerUseTool"):InvokeServer(foodItem.unique, "START")
                    task.wait(0.3)
                    RouterClient.get("ToolAPI/ServerUseTool"):InvokeServer(foodItem.unique, "END")
                    task.wait(1.5)
                end
                RouterClient.get("ToolAPI/Unequip"):InvokeServer(foodItem.unique, {})
            end)
            task.wait(0.5)
        end
    else
        local foodItem = getOrBuyFreeFood("schospital_refresh_2023_cafeteria_sandwich")
        if foodItem then
            local wrapper = getEquippedPetWrapper()
            if wrapper and PetActions.can_feed_pet(wrapper) then
                PetActions.feed_pet(wrapper, { item = foodItem })
            end
        end
        local t0 = tick()
        while tick() - t0 < 15 do
            task.wait(1)
            if not isAilmentActive("hungry", false) then
                break
            end
        end
    end
    if forBaby then
        return not isAilmentActive("hungry", true)
    else
        return not isAilmentActive("hungry", false)
    end
end

local function completeThirsty(forBaby)
    elevate()
    if forBaby then
        local t0 = tick()
        while isAilmentActive("thirsty", true) and tick() - t0 < 25 do
            local drinkItem = getOrBuyFreeFood("water_paper_cup")
            if not drinkItem then break end
            pcall(function()
                RouterClient.get("ToolAPI/Equip"):InvokeServer(drinkItem.unique, {})
                task.wait(0.4)
                for i = 1, (drinkItem.uses or 3) do
                    if not isAilmentActive("thirsty", true) then break end
                    RouterClient.get("ToolAPI/ServerUseTool"):InvokeServer(drinkItem.unique, "START")
                    task.wait(0.3)
                    RouterClient.get("ToolAPI/ServerUseTool"):InvokeServer(drinkItem.unique, "END")
                    task.wait(1.5)
                end
                RouterClient.get("ToolAPI/Unequip"):InvokeServer(drinkItem.unique, {})
            end)
            task.wait(0.5)
        end
    else
        local drinkItem = getOrBuyFreeFood("water_paper_cup")
        if drinkItem then
            local wrapper = getEquippedPetWrapper()
            if wrapper and PetActions.can_feed_pet(wrapper) then
                PetActions.feed_pet(wrapper, { item = drinkItem })
            end
        end
        local t0 = tick()
        while tick() - t0 < 15 do
            task.wait(1)
            if not isAilmentActive("thirsty", false) then
                break
            end
        end
    end
    if forBaby then
        return not isAilmentActive("thirsty", true)
    else
        return not isAilmentActive("thirsty", false)
    end
end

local function completeSick(forBaby, excludeUnique)
    elevate()
    if forBaby then
        local t0 = tick()
        while isAilmentActive("sick", true) and tick() - t0 < 20 do
            local appleItem = getOrBuyFreeFood("healing_apple", excludeUnique)
            if not appleItem then break end
            pcall(function()
                RouterClient.get("ToolAPI/Equip"):InvokeServer(appleItem.unique, {})
                task.wait(0.4)
                RouterClient.get("ToolAPI/ServerUseTool"):InvokeServer(appleItem.unique, "START")
                task.wait(0.3)
                RouterClient.get("ToolAPI/ServerUseTool"):InvokeServer(appleItem.unique, "END")
                task.wait(1)
                RouterClient.get("ToolAPI/Unequip"):InvokeServer(appleItem.unique, {})
            end)
            task.wait(0.5)
        end
    else
        local appleItem = getOrBuyFreeFood("healing_apple", excludeUnique)
        if appleItem then
            local wrapper = getEquippedPetWrapper()
            if wrapper and PetActions.can_feed_pet(wrapper) then
                PetActions.feed_pet(wrapper, { item = appleItem })
            end
        end
        local t0 = tick()
        while tick() - t0 < 15 do
            task.wait(1)
            if not isAilmentActive("sick", false) then
                break
            end
        end
    end
    if forBaby then
        return not isAilmentActive("sick", true)
    else
        return not isAilmentActive("sick", false)
    end
end

local function completeRide()
    setActivity("宠物：骑乘中")
    elevate()
    ensureInsideHouse()
    local myData = ClientData.get_data()[LP.Name] or {}
    local strollers = myData.inventory and myData.inventory.strollers or {}
    local strollerItem = nil
    for _, s in pairs(strollers) do
        strollerItem = s
        break
    end
    if not strollerItem then return false end

    local wrapper = getEquippedPetWrapper()
    local petChar = wrapper and wrapper.char
    if not petChar then return false end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return false end

    local platform = ensureFarmPlatform()
    local platformPos = platform.Position

    teleportToPlatform()
    task.wait(0.3)

    pcall(function()
        RouterClient.get("ToolAPI/Equip"):InvokeServer(strollerItem.unique, {})
    end)
    task.wait(0.4)

    local tool = nil
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") or c.Name:lower():find("stroller") then
            tool = c
            break
        end
    end
    local touchPart = tool and tool:FindFirstChild("ModelHandle") and tool.ModelHandle:FindFirstChild("TouchToSits") and tool.ModelHandle.TouchToSits:GetChildren()[1]
    if touchPart then
        pcall(function()
            RouterClient.get("AdoptAPI/UseStroller"):InvokeServer(LP, petChar, touchPart)
        end)
    end

    local center = platformPos + Vector3.new(0, 4, 0)
    local radius = 15
    local angle = 0
    local t0 = tick()
    while isAilmentActive("ride", false) and tick() - t0 < 35 do
        angle = angle + 0.35
        local target = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        hum:MoveTo(target)
        task.wait(0.15)
    end

    pcall(function()
        RouterClient.get("AdoptAPI/UnequipStroller"):FireServer()
        RouterClient.get("ToolAPI/Unequip"):InvokeServer(strollerItem.unique, {})
    end)

    teleportToPlatform()
    return not isAilmentActive("ride", false)
end

local function completeWalk()
    setActivity("宠物：散步中")
    elevate()
    ensureInsideHouse()

    local wrapper = getEquippedPetWrapper()
    local petChar = wrapper and wrapper.char
    if not petChar then
        petChar = getActivePetModel()
    end
    if not petChar then return false end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return false end

    local platform = ensureFarmPlatform()
    local platformPos = platform.Position

    teleportToPlatform()
    task.wait(0.3)

    local center = platformPos + Vector3.new(0, 4, 0)
    local radius = 15
    local angle = 0
    local t0 = tick()
    while isAilmentActive("walk", false) and tick() - t0 < 45 do
        angle = angle + 0.35
        local target = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        hum:MoveTo(target)
        task.wait(0.15)
    end

    teleportToPlatform()
    return not isAilmentActive("walk", false)
end

local function completePetMe()
    setActivity("宠物：抚摸中")
    elevate()
    local wrapper = getEquippedPetWrapper()
    local petUnique = wrapper and (wrapper.pet_unique or (wrapper.item and wrapper.item.unique))
    if not petUnique then return false end

    pcall(function()
        setthreadidentity(2)
        local UIManager = Fsys.load("UIManager")
        local fpa = UIManager and UIManager.apps and UIManager.apps.FocusPetApp
        local ph = fpa and fpa.petting_handler

        if fpa and ph then
            local mod = game:GetService("ReplicatedStorage").ClientModules.Core.UIManager.Apps.FocusPetApp.FocusPetApp
            local origClass = require(mod)
            fpa.capture_focus = origClass.capture_focus
            fpa.release_focus = origClass.release_focus

            if fpa.camera then
                fpa.camera.capture_focus = function() return end
                fpa.camera.update = function() return end
            end

            local oldSetAppVis = UIManager.set_app_visibility
            UIManager.set_app_visibility = function(appName, vis)
                if appName == fpa.ClassName then return end
                return oldSetAppVis(appName, vis)
            end

            local oldShowEx = ph.show_example
            ph.show_example = function() return end

            local toggle = false
            local oldGetPos = ph.get_position
            ph.get_position = function(self)
                toggle = not toggle
                local center = workspace.CurrentCamera.ViewportSize * 0.5
                return center + Vector2.new(toggle and 20 or -20, 0)
            end

            local oldUpdateHand = ph.update_hand
            ph.update_hand = function(self, update_fn)
                local Promise = Fsys.load("package:Promise")
                return Promise.new(function(resolve, reject, onCancel)
                    while not onCancel() do
                        update_fn()
                        if ph.instance then ph.instance.Visible = false end
                        if ph.example then ph.example.Visible = false end
                        task.wait(0.03)
                    end
                end)
            end

            fpa:capture_focus(wrapper)
            if fpa.instance then fpa.instance.Enabled = false end

            task.wait(0.2)
            ph.is_holding_pet_button = true
            ph:start_petting("pet_me", true)

            local t0 = tick()
            while isAilmentActive("pet_me", false) and tick() - t0 < 6 do
                if ph.instance then ph.instance.Visible = false end
                if fpa.instance then fpa.instance.Enabled = false end
                task.wait(0.1)
            end

            fpa:release_focus()

            UIManager.set_app_visibility = oldSetAppVis
            ph.show_example = oldShowEx
            ph.get_position = oldGetPos
            ph.update_hand = oldUpdateHand
        else
            local t0 = tick()
            while isAilmentActive("pet_me", false) and tick() - t0 < 10 do
                RouterClient.get("PetAPI/PetPetted"):FireServer(petUnique, LP)
                RouterClient.get("AilmentsAPI/ProgressPetMeAilment"):FireServer(petUnique)
                task.wait(0.5)
            end
        end
        setthreadidentity(8)
    end)

    resetCameraZoom()
    return not isAilmentActive("pet_me", false)
end

local function getThrowableToy()
    elevate()
    local toys = nil
    pcall(function()
        setthreadidentity(2)
        local inv = ClientData.get and ClientData.get("inventory")
        if inv and inv.toys then
            toys = inv.toys
        end
        if not toys and ClientData.get_data then
            local allData = ClientData.get_data()
            local myD = allData and allData[LP.Name]
            toys = myD and myD.inventory and myD.inventory.toys
        end
        setthreadidentity(8)
    end)

    if toys then
        for _, item in pairs(toys) do
            local id = tostring(item.kind or item.id or ""):lower()
            if id:find("bone") or id:find("ball") or id:find("disc") or id:find("stick") or id:find("chew") then
                return item
            end
        end
        for _, item in pairs(toys) do
            return item
        end
    end

    pcall(function()
        local shopRemote = RouterClient.get("ShopAPI/BuyItem")
        if shopRemote then
            shopRemote:InvokeServer("toys", "squeaky_bone_default", {})
        end
    end)
    task.wait(0.4)

    pcall(function()
        setthreadidentity(2)
        local inv = ClientData.get and ClientData.get("inventory")
        if inv and inv.toys then
            toys = inv.toys
        end
        if not toys and ClientData.get_data then
            local allData = ClientData.get_data()
            local myD = allData and allData[LP.Name]
            toys = myD and myD.inventory and myD.inventory.toys
        end
        setthreadidentity(8)
    end)

    if toys then
        for _, item in pairs(toys) do
            return item
        end
    end
    return nil
end

local function completePlay()
    setActivity("宠物：玩耍中")
    elevate()
    local toy = getThrowableToy()
    if not toy then return false end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    pcall(function()
        local equipRemote = RouterClient.get("ToolAPI/Equip")
        if equipRemote then
            equipRemote:InvokeServer(toy.unique, {})
        end
    end)
    task.wait(0.5)

    local creatorTypes = nil
    pcall(function()
        setthreadidentity(2)
        creatorTypes = Fsys.load("AdoptMeEnums/PetEntities/PetObjectCreatorType")
        setthreadidentity(8)
    end)
    local droppableType = (creatorTypes and creatorTypes.DroppableToy) or "__Enum_PetObjectCreatorType_1"

    local t0 = tick()
    while isAilmentActive("play", false) and tick() - t0 < 25 do
        char = LP.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        local spawnCF = hrp and (hrp.CFrame + hrp.CFrame.LookVector * 8) or CFrame.new()

        pcall(function()
            local createRemote = RouterClient.get("PetObjectAPI/CreatePetObject")
            if createRemote then
                createRemote:InvokeServer(droppableType, {
                    unique_id = toy.unique,
                    reaction_name = "ThrowToyReaction",
                    spawn_cframe = spawnCF
                })
            end
        end)
        task.wait(3.5)
    end

    pcall(function()
        local unequipRemote = RouterClient.get("ToolAPI/Unequip")
        if unequipRemote then
            unequipRemote:InvokeServer(toy.unique, {})
        end
    end)
    return not isAilmentActive("play", false)
end

local function completeMysteryChoice()
    elevate()
    local wrapper = getEquippedPetWrapper()
    local petUnique = wrapper and (wrapper.pet_unique or (wrapper.item and wrapper.item.unique))
    if not petUnique then return false end

    pcall(function()
        setthreadidentity(2)
        local h = require(game:GetService("ReplicatedStorage").new.modules.Ailments.Helpers.MysteryHelper)
        local myData = ClientData.get_data()[LP.Name] or {}
        local am = myData.ailments_manager or {}
        local petAilments = (am.ailments and am.ailments[petUnique]) or {}

        for ailmentId, entry in pairs(petAilments) do
            local k = type(entry) == "table" and (entry.kind or entry.ailment_key) or tostring(ailmentId)
            if k == "mystery" or tostring(ailmentId):lower():find("mystery") then
                local action = h.get_action(entry)
                local slots = action and action:_get_ailment_slots(wrapper)
                if not slots or #slots == 0 then
                    slots = { "bored", "sleepy", "dirty" }
                end
                local chosenIdx = math.random(1, #slots)
                local chosenKind = slots[chosenIdx]
                local ailmentKey = (entry.components and entry.components.mystery and entry.components.mystery.ailment_key) or "mystery"
                RouterClient.get("AilmentsAPI/ChooseMysteryAilment"):FireServer(
                    petUnique,
                    ailmentKey,
                    chosenIdx,
                    chosenKind
                )
            end
        end

        local ba = am.baby_ailments or {}
        for ailmentId, entry in pairs(ba) do
            local k = type(entry) == "table" and (entry.kind or entry.ailment_key) or tostring(ailmentId)
            if k == "mystery" or tostring(ailmentId):lower():find("mystery") then
                local action = h.get_action(entry)
                local slots = action and action:_get_ailment_slots(wrapper)
                if not slots or #slots == 0 then
                    slots = { "bored", "sleepy", "dirty" }
                end
                local chosenIdx = math.random(1, #slots)
                local chosenKind = slots[chosenIdx]
                local ailmentKey = (entry.components and entry.components.mystery and entry.components.mystery.ailment_key) or "mystery"
                RouterClient.get("AilmentsAPI/ChooseMysteryAilment"):FireServer(
                    "baby",
                    ailmentKey,
                    chosenIdx,
                    chosenKind
                )
            end
        end
        setthreadidentity(8)
    end)

    task.wait(0.6)
    return not isAilmentActive("mystery", false) and not isAilmentActive("mystery", true)
end

local function completePartyZone()
    elevate()
    local s, pz = pcall(function()
        setthreadidentity(2)
        local AdminAbuse = require(game:GetService("ReplicatedStorage").new.modules.AdminAbuse)
        local val = AdminAbuse.get_value("party_zone")
        setthreadidentity(8)
        return val
    end)

    if not s or not pz or not pz.position then
        return false
    end

    local dest = pz.destination_id or "MainMap"
    if tostring(dest):lower():find("pizza") then
        return false
    end
    local rawPos = pz.position
    local targetPos = Vector3.new(rawPos[1], rawPos[2] + 3, rawPos[3])

    if dest == "MainMap" then
        pcall(function()
            setthreadidentity(2)
            InteriorsM.enter("MainMap", "NeighborhoodDoor")
            task.wait(1.5)
            elevate()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(targetPos)
            end
        end)
    else
        enterBuilding(dest, "MainDoor")
        task.wait(1.5)
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(targetPos)
        end
    end

    local t0 = tick()
    while (isAilmentActive("party_zone", false) or isAilmentActive("party_zone", true)) and tick() - t0 < 70 do
        task.wait(1)
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - targetPos).Magnitude > 25 then
            hrp.CFrame = CFrame.new(targetPos)
        end
    end

    return not isAilmentActive("party_zone", false) and not isAilmentActive("party_zone", true)
end

local sessionStartTime = tick()
local initialMoney = nil
local tasksCompletedCount = 0
local recentCompletedSummary = nil

local isSolvingTasks = false

local function solveCurrentTasks()
    if isSolvingTasks then return end
    isSolvingTasks = true
    local prevCompletedCount = tasksCompletedCount
    local justCompletedList = {}

    local doBabyTasks = CFG.AutoBaby and (getCurrentTeam() == "Babies")
    local babyTasks = doBabyTasks and getBabyAilmentKeys() or {}
    local petTasks = getPetAilmentKeys()

    local petHouseNeeds = { "sleepy", "dirty", "toilet", "hungry", "thirsty", "sick" }
    local babyHouseNeeds = { "dirty", "sleepy", "toilet", "hungry", "thirsty", "sick" }

    local hasPetHouseNeed = false
    for _, need in ipairs(petHouseNeeds) do
        if isAilmentActive(need, false) then
            hasPetHouseNeed = true
            break
        end
    end

    local hasBabyHouseNeed = false
    if doBabyTasks then
        for _, need in ipairs(babyHouseNeeds) do
            if isAilmentActive(need, true) then
                hasBabyHouseNeed = true
                break
            end
        end
    end

    if hasPetHouseNeed or hasBabyHouseNeed then
        ensureInsideHouse()

        local petDone = not hasPetHouseNeed
        local babyDone = not hasBabyHouseNeed

        if hasPetHouseNeed then
            task.spawn(function()
                for _, need in ipairs(petHouseNeeds) do
                    if isAilmentActive(need, false) then
                        if need == "sleepy" then
                            local furn = completeSleep(false)
                            local t0 = tick()
                            while isAilmentActive("sleepy", false) and tick() - t0 < 25 do
                                task.wait(0.5)
                            end
                            if furn then activeFurnitureInUse[furn] = nil end
                            if not isAilmentActive("sleepy", false) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "🐾 Sleepy")
                            end
                        elseif need == "dirty" then
                            local furn = completeShower(false)
                            local t0 = tick()
                            while isAilmentActive("dirty", false) and tick() - t0 < 25 do
                                task.wait(0.5)
                            end
                            if furn then activeFurnitureInUse[furn] = nil end
                            if not isAilmentActive("dirty", false) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "🐾 Dirty")
                            end
                        elseif need == "toilet" then
                            local furn = completeToilet(false)
                            local t0 = tick()
                            while isAilmentActive("toilet", false) and tick() - t0 < 20 do
                                task.wait(0.5)
                            end
                            if furn then activeFurnitureInUse[furn] = nil end
                            if not isAilmentActive("toilet", false) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "🐾 Toilet")
                            end
                        elseif need == "hungry" then
                            if completeHungry(false) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "🐾 Hungry")
                            end
                        elseif need == "thirsty" then
                            if completeThirsty(false) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "🐾 Thirsty")
                            end
                        elseif need == "sick" then
                            if completeSick(false) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "🐾 Sick")
                            end
                        end
                    end
                end
                petDone = true
            end)
        end

        if hasBabyHouseNeed then
            task.spawn(function()
                for _, need in ipairs(babyHouseNeeds) do
                    if isAilmentActive(need, true) then
                        if need == "dirty" then
                            local furn = completeShower(true)
                            local t0 = tick()
                            while isAilmentActive("dirty", true) and tick() - t0 < 25 do
                                task.wait(0.5)
                            end
                            unseatBaby()
                            task.wait(0.5)
                            if furn then activeFurnitureInUse[furn] = nil end
                            if not isAilmentActive("dirty", true) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "👶 Dirty")
                            end
                        elseif need == "sleepy" then
                            local furn = completeSleep(true)
                            local t0 = tick()
                            while isAilmentActive("sleepy", true) and tick() - t0 < 25 do
                                task.wait(0.5)
                            end
                            unseatBaby()
                            task.wait(0.5)
                            if furn then activeFurnitureInUse[furn] = nil end
                            if not isAilmentActive("sleepy", true) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "👶 Sleepy")
                            end
                        elseif need == "toilet" then
                            local furn = completeToilet(true)
                            local t0 = tick()
                            while isAilmentActive("toilet", true) and tick() - t0 < 20 do
                                task.wait(0.5)
                            end
                            unseatBaby()
                            task.wait(0.5)
                            if furn then activeFurnitureInUse[furn] = nil end
                            if not isAilmentActive("toilet", true) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "👶 Toilet")
                            end
                        elseif need == "hungry" then
                            if completeHungry(true) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "👶 Hungry")
                            end
                        elseif need == "thirsty" then
                            if completeThirsty(true) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "👶 Thirsty")
                            end
                        elseif need == "sick" then
                            if completeSick(true) then
                                tasksCompletedCount = tasksCompletedCount + 1
                                table.insert(justCompletedList, "👶 Sick")
                            end
                        end
                    end
                end
                babyDone = true
            end)
        end

        local waitStart = tick()
        while (not petDone or not babyDone) and tick() - waitStart < 45 do
            task.wait(0.5)
        end

        teleportToPlatform()
    end

    if table.find(petTasks, "ride") then
        if completeRide() then
            tasksCompletedCount = tasksCompletedCount + 1
            table.insert(justCompletedList, "🐾 Ride")
        end
    end

    if table.find(petTasks, "walk") then
        if completeWalk() then
            tasksCompletedCount = tasksCompletedCount + 1
            table.insert(justCompletedList, "🐾 Walk")
        end
    end

    if table.find(petTasks, "play") then
        if completePlay() then
            tasksCompletedCount = tasksCompletedCount + 1
            table.insert(justCompletedList, "🐾 Play")
        end
    end

    if table.find(petTasks, "pet_me") then
        if completePetMe() then
            tasksCompletedCount = tasksCompletedCount + 1
            table.insert(justCompletedList, "🐾 Pet Me")
        end
    end

    if table.find(petTasks, "mystery") or table.find(babyTasks, "mystery") then
        if completeMysteryChoice() then
            tasksCompletedCount = tasksCompletedCount + 1
            table.insert(justCompletedList, "🐾 Choose (Mystery)")
        end
    end

    if table.find(petTasks, "party_zone") or table.find(babyTasks, "party_zone") then
        local bHad = table.find(babyTasks, "party_zone") ~= nil
        local pHad = table.find(petTasks, "party_zone") ~= nil
        if completePartyZone() then
            if bHad and not isAilmentActive("party_zone", true) then
                tasksCompletedCount = tasksCompletedCount + 1
                table.insert(justCompletedList, "👶 Party (Admin Event)")
            end
            if pHad and not isAilmentActive("party_zone", false) then
                tasksCompletedCount = tasksCompletedCount + 1
                table.insert(justCompletedList, "🐾 Party (Admin Event)")
            end
        end
    end

    for taskName, locData in pairs(interiorLocations) do
        local bHas = table.find(babyTasks, taskName) ~= nil
        local pHas = table.find(petTasks, taskName) ~= nil
        if bHas or pHas then
            enterBuilding(locData.dest, locData.door)
            local t0 = tick()
            while tick() - t0 < 70 do
                task.wait(1)
                local bRem = bHas and isAilmentActive(taskName, true)
                local pRem = pHas and isAilmentActive(taskName, false)
                if not bRem and not pRem then break end
            end
            if bHas and not isAilmentActive(taskName, true) then
                tasksCompletedCount = tasksCompletedCount + 1
                table.insert(justCompletedList, "👶 " .. formatTaskName(taskName))
            end
            if pHas and not isAilmentActive(taskName, false) then
                tasksCompletedCount = tasksCompletedCount + 1
                table.insert(justCompletedList, "🐾 " .. formatTaskName(taskName))
            end
            break
        end
    end

    for taskName, cf in pairs(outdoorLocations) do
        local bHas = table.find(babyTasks, taskName) ~= nil
        local pHas = table.find(petTasks, taskName) ~= nil
        if bHas or pHas then
            teleportToOutdoor(cf, taskName)
            local t0 = tick()
            while tick() - t0 < 70 do
                task.wait(1)
                local bRem = bHas and isAilmentActive(taskName, true)
                local pRem = pHas and isAilmentActive(taskName, false)
                if not bRem and not pRem then break end
            end
            if bHas and not isAilmentActive(taskName, true) then
                tasksCompletedCount = tasksCompletedCount + 1
                table.insert(justCompletedList, "👶 " .. formatTaskName(taskName))
            end
            if pHas and not isAilmentActive(taskName, false) then
                tasksCompletedCount = tasksCompletedCount + 1
                table.insert(justCompletedList, "🐾 " .. formatTaskName(taskName))
            end
            break
        end
    end

    if #justCompletedList > 0 then
        recentCompletedSummary = table.concat(justCompletedList, ", ")
    end

    if CFG.WebhookEnabled and CFG.WebhookOnTask and tasksCompletedCount > prevCompletedCount then
        task.spawn(function()
            pcall(function()
                sendWebhookReport(false)
            end)
        end)
    end

    isSolvingTasks = false
    setActivity("监控需求中")
end

local function getEquippedPetInfo()
    local myPets = nil
    pcall(function()
        setthreadidentity(2)
        myPets = EquippedPets.get_my_equipped()
        setthreadidentity(8)
    end)
    local pet = myPets and myPets[1]
    if not pet then return "None" end
    local myData = ClientData.get_data()[LP.Name] or {}
    local pets = (myData.inventory and myData.inventory.pets) or {}
    local pInfo = pets[pet.unique] or pet
    local petName = (pInfo.properties and pInfo.properties.name) or pInfo.kind or "Pet"
    local pet年龄 = (pInfo.properties and pInfo.properties.age) or 1
    local ageStages = { "新生", "幼年", "少年", "青年", "Post-青年", "完全长大" }
    local ageName = ageStages[petAge] or ("年龄 " .. tostring(petAge))
    return petName:gsub("^%l", string.upper) .. " (" .. ageName .. ")"
end

local function formatMoney(amount)
    local formatted = tostring(amount or 0)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return "$" .. formatted
end


local function sendWebhookReport(isTest)
    elevate()
    local url = CFG.WebhookURL
    if not url or url == "" then
        if isTest then
            notify({
                Title = "Webhook 错误",
                Content = "请先填写有效的 Discord Webhook 地址！",
                Duration = 3
            })
        end
        return false
    end

    local HttpService = game:GetService("HttpService")
    local fn = (syn and syn.request) or request or http_request
    if not fn then
        if isTest then
            notify({
                Title = "Webhook 错误",
                Content = "当前执行环境缺少 HTTP 请求接口！",
                Duration = 3
            })
        end
        return false
    end

    local elapsed = math.floor(tick() - sessionStartTime)
    local hours = math.floor(elapsed / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = elapsed % 60
    local uptimeStr = string.format("%02dh %02dm %02ds", hours, mins, secs)

    local myData = ClientData.get_data()[LP.Name] or {}
    local currentMoney = myData.money or 0
    if initialMoney == nil then
        initialMoney = currentMoney
    end
    local moneyEarned = currentMoney - initialMoney
    local earnedSign = (moneyEarned >= 0) and ("+" .. formatMoney(moneyEarned)) or ("-" .. formatMoney(math.abs(moneyEarned)))
    local moneyStr = formatMoney(currentMoney) .. " (" .. earnedSign .. ")"

    local petInfo = getEquippedPetInfo()
    local teamStr = getCurrentTeam()
    local roleStr = (teamStr == "Babies" and "👶 Baby") or (teamStr == "Parents" and "🧑 Parent") or teamStr

    local isBaby = (teamStr == "Babies")
    local petTasks = getPetAilmentKeys()
    local babyTasks = isBaby and getBabyAilmentKeys() or {}

    local petTaskLines = {}
    for _, t in ipairs(petTasks) do
        table.insert(petTaskLines, "• " .. formatTaskName(t))
    end
    local petTasksDisplay = (#petTaskLines > 0) and table.concat(petTaskLines, "\n") or "✅ 已全部完成！（宠物暂无需求）"

    local babyTasksDisplay
    if isBaby then
        local babyTaskLines = {}
        for _, t in ipairs(babyTasks) do
            table.insert(babyTaskLines, "• " .. formatTaskName(t))
        end
        babyTasksDisplay = (#babyTaskLines > 0) and table.concat(babyTaskLines, "\n") or "✅ 已全部完成！（宝宝暂无需求）"
    else
        babyTasksDisplay = "⚪ 未启用（当前为家长）"
    end

    local justCompletedDisplay = recentCompletedSummary or "暂无（监控中）"

    local dailyQuestsDisplay = "每日任务：已关闭"

    local currentStatus = "Idle"
    if isSolvingTasks then
        currentStatus = "正在完成需求……"
    elseif CFG.AutoCompleteTasks then
        currentStatus = "正在监控需求……"
    end

    local embedTitle = isTest and "🧪 Adopt Me! Hub — Webhook 测试" or "📊 Adopt Me! Hub — 挂机报告"
    local embedColor = isTest and 3447003 or 65440

    local payload = {
        username = "Adopt Me! Hub",
        avatar_url = "https://i.imgur.com/8f8e0mC.png",
        embeds = {
            {
                title = embedTitle,
                color = embedColor,
                fields = {
                    { name = "👤 玩家", value = string.format("%s (@%s)", LP.DisplayName, LP.Name), inline = true },
                    { name = "⏳ 本次运行时长", value = uptimeStr, inline = true },
                    { name = "🎭 当前身份", value = roleStr, inline = true },
                    { name = "💰 金钱", value = moneyStr, inline = true },
                    { name = "✅ 已完成任务", value = tostring(tasksCompletedCount) .. " solved", inline = true },
                    { name = "🐾 当前宠物", value = petInfo, inline = true },
                    { name = "🐾 宠物待办需求", value = petTasksDisplay, inline = false },
                    { name = "👶 宝宝待办需求", value = babyTasksDisplay, inline = false },
                    { name = "📋 每日任务与连续奖励", value = dailyQuestsDisplay, inline = false },
                    { name = "🎉 刚刚完成", value = justCompletedDisplay, inline = false },
                    { name = "⚙️ 脚本状态", value = currentStatus, inline = false }
                },
                footer = {
                    text = "Adopt Me! Hub • 自动追踪"
                },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }

    local body = HttpService:JSONEncode(payload)
    local s, res = pcall(function()
        return fn({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    end)

    local success = s and res and (res.StatusCode == 200 or res.StatusCode == 204)
    if isTest then
        if success then
            notify({
                Title = "Webhook 发送成功",
                Content = "测试报告已发送到 Discord！",
                Duration = 3
            })
        else
            local code = (res and res.StatusCode) or "Error"
            notify({
                Title = "Webhook 发送失败",
                Content = "发送失败（状态：" .. tostring(code) .. "). 请检查地址。",
                Duration = 4
            })
        end
    end
    if success then
        lastWebhookSendTime = tick()
    end
    return success
end


local function getOption(key, default)
    local val = getgenv()[key]
    if val ~= nil then
        return val
    end
    return default
end

local function syncCFG()
    CFG.AutoBaby = getOption("AutoBaby", true)
    CFG.AutoCompleteTasks = getOption("AutoCompleteTasks", true)
    CFG.AutoSwapFullGrown = getOption("AutoSwapFullGrown", false)
    CFG.SelectedPetKind = getOption("SelectedPetKind", "cat")
    CFG.AutoDoQuests = false
    CFG.AutoClaimQuests = false
    CFG.AutoClaimTabBonus = false
    CFG.AutoClaimDailyLogin = false
    CFG.WebhookEnabled = getOption("WebhookEnabled", false)
    CFG.WebhookURL = getOption("WebhookURL", "")
    CFG.WebhookInterval = getOption("WebhookInterval", 5)
    CFG.WebhookOnTask = getOption("WebhookOnTask", false)
end

local function equipTargetCat()
    local targetKind = getOption("SelectedPetKind", "cat")
    local myPets = nil
    pcall(function()
        setthreadidentity(2)
        myPets = EquippedPets.get_my_equipped()
        setthreadidentity(8)
    end)
    local curPet = myPets and myPets[1]
    local myData = ClientData.get_data()[LP.Name] or {}
    local pets = myData.inventory and myData.inventory.pets or {}

    local curKind = nil
    if curPet then
        local pInfo = pets[curPet.unique] or curPet
        curKind = pInfo.kind
    end

    if curKind ~= targetKind then
        for u, p in pairs(pets) do
            if p.kind == targetKind then
                swapToPet(u, p)
                break
            end
        end
    end
end

local function applyPerformanceOptimizations()
    pcall(function()
        local cap = tonumber(getOption("FPSCap", 15)) or 15
        if setfpscap and cap > 0 then
            setfpscap(cap)
        end
    end)

    if getOption("UltraLowGFX", true) then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.EditQualityLevel = Enum.QualityLevel.Level01
            settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.DefaultAuto
        end)

        pcall(function()
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 9e9
            lighting.Brightness = 0
            for _, v in ipairs(lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                    pcall(function() v.Enabled = false end)
                end
            end
        end)

        pcall(function()
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0
            end
        end)

        pcall(function()
            local function stripObject(v)
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    pcall(function() v.Enabled = false end)
                elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                    pcall(function() v.Enabled = false end)
                end
            end

            for _, v in ipairs(workspace:GetDescendants()) do
                stripObject(v)
            end

            workspace.DescendantAdded:Connect(function(v)
                if getOption("UltraLowGFX", true) then
                    stripObject(v)
                end
            end)
        end)
    end

    if getOption("MuteAudio", true) then
        pcall(function()
            local SoundService = game:GetService("SoundService")
            SoundService.RespectFilteringEnabled = true
            for _, s in ipairs(workspace:GetDescendants()) do
                if s:IsA("Sound") then
                    pcall(function() s.Volume = 0 end)
                end
            end
            workspace.DescendantAdded:Connect(function(s)
                if getOption("MuteAudio", true) and s:IsA("Sound") then
                    pcall(function() s.Volume = 0 end)
                end
            end)
        end)
    end
end

applyPerformanceOptimizations()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CablePerformanceFarmer"
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 2147483647
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Back = Instance.new("Frame")
local INNER = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TextLabel = Instance.new("TextLabel")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local water = Instance.new("TextLabel")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")

Back.Name = "Back"
Back.Parent = ScreenGui
Back.AnchorPoint = Vector2.new(0.5, 0.5)
Back.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Back.BorderColor3 = Color3.fromRGB(0, 0, 0)
Back.BorderSizePixel = 0
Back.Position = UDim2.new(0.5, 0, 0.5, 0)
Back.Size = UDim2.new(1, 200, 1, 200)
Back.ZIndex = 1000

INNER.Name = "INNER"
INNER.Parent = Back
INNER.AnchorPoint = Vector2.new(0.5, 0.5)
INNER.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
INNER.BorderColor3 = Color3.fromRGB(0, 0, 0)
INNER.BorderSizePixel = 0
INNER.Position = UDim2.new(0.5, 0, 0.5, 0)
INNER.Size = UDim2.new(0.50, 0, 0.68, 0)
INNER.ZIndex = 1001

UICorner.Parent = INNER
UICorner.CornerRadius = UDim.new(0, 14)

TextLabel.Parent = INNER
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.BorderSizePixel = 0
TextLabel.Position = UDim2.new(0.06, 0, 0.05, 0)
TextLabel.Size = UDim2.new(0.88, 0, 0.83, 0)
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.Text = "用户：" .. LP.DisplayName .. " (@" .. LP.Name .. ")\n宠物：加载中……\n状态：监控需求中\n金钱：加载中……\n任务：已完成 0 个\nWebhook：检查中……\n运行时长：0时 0分 0秒"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextScaled = true
TextLabel.TextSize = 28.000
TextLabel.TextWrapped = true
TextLabel.ZIndex = 1002

UITextSizeConstraint.Parent = TextLabel
UITextSizeConstraint.MaxTextSize = 28

water.Name = "water"
water.Parent = INNER
water.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
water.BackgroundTransparency = 1.000
water.BorderColor3 = Color3.fromRGB(0, 0, 0)
water.BorderSizePixel = 0
water.Position = UDim2.new(0.05, 0, 0.89, 0)
water.Size = UDim2.new(0.90, 0, 0.08, 0)
water.Font = Enum.Font.SourceSans
water.Text = "made by cable　•　右 Ctrl/P 或右上角按钮切换画面"
water.TextColor3 = Color3.fromRGB(180, 180, 180)
water.TextScaled = true
water.TextSize = 15.000
water.TextWrapped = true
water.TextXAlignment = Enum.TextXAlignment.Center
water.TextYAlignment = Enum.TextYAlignment.Center
water.ZIndex = 1002

UITextSizeConstraint_2.Parent = water
UITextSizeConstraint_2.MaxTextSize = 15

-- 手机端画面切换按钮；始终显示在挂机面板上方。
local ToggleRenderButton = Instance.new("TextButton")
ToggleRenderButton.Name = "ToggleRenderButton"
ToggleRenderButton.Parent = ScreenGui
ToggleRenderButton.AnchorPoint = Vector2.new(1, 0)
ToggleRenderButton.Position = UDim2.new(1, -12, 0, 12)
ToggleRenderButton.Size = UDim2.fromOffset(132, 38)
ToggleRenderButton.BackgroundColor3 = Color3.fromRGB(45, 105, 75)
ToggleRenderButton.BorderSizePixel = 0
ToggleRenderButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleRenderButton.Font = Enum.Font.SourceSansBold
ToggleRenderButton.TextSize = 16
ToggleRenderButton.ZIndex = 2005
local ToggleRenderCorner = Instance.new("UICorner")
ToggleRenderCorner.CornerRadius = UDim.new(0, 9)
ToggleRenderCorner.Parent = ToggleRenderButton

local function formatNumber(n)
    if not n then return "0" end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function formatUptime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%d时 %d分 %d秒", h, m, s)
end

local function formatCountdown(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%d时 %d分 %d秒", h, m, s)
    elseif m > 0 then
        return string.format("%d分 %d秒", m, s)
    else
        return string.format("%d秒", s)
    end
end

updateStatsUI = function()
    pcall(function()
        local currentMoney = 0
        pcall(function()
            local myData = ClientData.get_data()[LP.Name] or {}
            currentMoney = myData.money or ClientData.get("money") or 0
        end)
        if initialMoney == nil then
            initialMoney = currentMoney
        end
        local earned = math.max(0, currentMoney - initialMoney)
        local elapsedSec = tick() - sessionStartTime
        local bucksPerHour = (elapsedSec > 10) and math.floor((earned / elapsedSec) * 3600) or 0
        local uptimeStr = formatUptime(elapsedSec)
        local petStr = getEquippedPetInfo()

        local webhookStatus = "已关闭"
        if CFG.WebhookEnabled and CFG.WebhookURL and CFG.WebhookURL ~= "" then
            local intervalSec = (tonumber(CFG.WebhookInterval) or 5) * 60
            if lastWebhookSendTime == 0 then
                webhookStatus = "已启用（等待首次发送）"
            else
                local remaining = math.max(0, math.floor(intervalSec - (tick() - lastWebhookSendTime)))
                webhookStatus = string.format("已启用（%s 后发送）", formatCountdown(remaining))
            end
        end

        local bucksStr = string.format("%s (+%s | %s/hr)", formatNumber(currentMoney), formatNumber(earned), formatNumber(bucksPerHour))
        local tasksStr = string.format("已完成 %s 个", formatNumber(tasksCompletedCount or 0))

        TextLabel.Text = string.format(
            "用户：%s (@%s)\nPet: %s\n状态：%s\nBucks: %s\nTasks: %s\nWebhook: %s\nUptime: %s",
            LP.DisplayName,
            LP.Name,
            petStr,
            currentActivity,
            bucksStr,
            tasksStr,
            webhookStatus,
            uptimeStr
        )
    end)
end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if getOption("Disable3DRendering", true) then
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end

local renderingState = not getOption("Disable3DRendering", true)

local function updateRenderButton()
    ToggleRenderButton.Text = renderingState and "显示挂机面板" or "显示游戏画面"
    ToggleRenderButton.BackgroundColor3 = renderingState
        and Color3.fromRGB(55, 80, 125)
        or Color3.fromRGB(45, 105, 75)
end

local function toggleRendering()
    renderingState = not renderingState
    pcall(function()
        RunService:Set3dRenderingEnabled(renderingState)
        if setfpscap then
            if renderingState then
                setfpscap(60)
            else
                setfpscap(tonumber(getOption("FPSCap", 15)) or 15)
            end
        end
    end)
    Back.Visible = not renderingState
    updateRenderButton()
end

ToggleRenderButton.Activated:Connect(toggleRendering)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.P) then
        toggleRendering()
    end
end)

updateRenderButton()

getgenv().PerformanceFarmerCleanup = function()
    farmerActive = false
    pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)
    pcall(function()
        if setfpscap then
            setfpscap(60)
        end
    end)
    pcall(function()
        ScreenGui:Destroy()
    end)
end

local function updateDashboardDisplay()
    updateStatsUI()
end

local function updateQuestsDisplay()
    updateStatsUI()
end

task.spawn(function()
    while farmerActive do
        updateStatsUI()
        task.wait(1)
    end
end)

task.spawn(function()
    while farmerActive do
        task.wait(60)
        pcall(function()
            if collectgarbage then
                collectgarbage("collect")
            end
        end)
    end
end)

task.spawn(function()
    while farmerActive do
        task.wait(2)
        syncCFG()
        if CFG.AutoBaby then
            if getCurrentTeam() ~= "Babies" then
                ensureBaby()
            end
        end
        equipTargetCat()
        if CFG.AutoCompleteTasks then
            pcall(solveCurrentTasks)
        end
        if CFG.WebhookEnabled and CFG.WebhookURL and CFG.WebhookURL ~= "" then
            local intervalSec = (tonumber(CFG.WebhookInterval) or 5) * 60
            if tick() - lastWebhookSendTime >= intervalSec then
                pcall(function()
                    sendWebhookReport(false)
                end)
            end
        end
        pcall(resetCameraZoom)
    end
end)

if CFG.AutoBaby then
    ensureBaby()
end
equipTargetCat()
task.spawn(function()
    solveCurrentTasks()
end)
