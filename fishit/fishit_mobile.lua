--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                     KAIZEN HUB V2                        ║
    ║                    FISH IT EDITION                       ║
    ║                                                          ║
    ║  Fishing  | Farming | Teleport | Shop | Quest | Config  ║
    ╚══════════════════════════════════════════════════════════╝

    PlaceId:
        121864768012064

    Keybind:
        RightControl = Show / Hide
    Touch:
        Top-right button = Collapse
        Floating button = Expand

    Config:
        KAIZEN_HUB/
            config.json
]]

--//========================================================//--
--// SERVICES
--//========================================================//--

local Players            = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local RunService          = game:GetService("RunService")
local HttpService         = game:GetService("HttpService")
local CoreGui             = game:GetService("CoreGui")
local TeleportService     = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

--//========================================================//--
--// GAME CHECK
--//========================================================//--

if game.PlaceId ~= 121864768012064 then
    warn("[KAIZEN HUB] Wrong game.")
    return
end

--//========================================================//--
--// CONFIG
--//========================================================//--

local CONFIG_FOLDER = "KAIZEN_HUB"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local DefaultConfig = {
    AutoFish = false,
    InstantFish = true,
    AutoSell = false,

    FishDelay = 0.15,
    SellDelay = 10,

    Rarity = "All",

    AutoBuyRod = false,
    SelectedRod = "",

    AutoQuest = false,

    Notifications = true,

    SelectedIsland = "",
    SelectedNPC = "",

    WindowVisible = true
}

local Config = {}

for k, v in pairs(DefaultConfig) do
    Config[k] = v
end

--//========================================================//--
--// FILE API
--//========================================================//--

local function FileSupported()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function MakeFolderSafe()
    if type(makefolder) ~= "function" then
        return
    end

    pcall(function()
        makefolder(CONFIG_FOLDER)
    end)
end

local function SaveConfig()
    if not FileSupported() then
        return false
    end

    MakeFolderSafe()

    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)

    return ok
end

local function LoadConfig()
    if not FileSupported() then
        return false
    end

    if not isfile(CONFIG_FILE) then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if not ok or type(data) ~= "table" then
        return false
    end

    for k, v in pairs(DefaultConfig) do
        if data[k] ~= nil then
            Config[k] = data[k]
        else
            Config[k] = v
        end
    end

    return true
end

local function ResetConfig()
    for k, v in pairs(DefaultConfig) do
        Config[k] = v
    end

    SaveConfig()
end

LoadConfig()

--//========================================================//--
--// STATE
--//========================================================//--

local State = {
    Alive = true,
    Generation = 0,

    FishCaught = 0,
    LastInventoryCount = 0,

    Fishing = false,
    Selling = false,
    Buying = false,
    Questing = false,

    SelectedTab = "Fishing",

    Islands = {},
    NPCs = {},
    Rods = {},
    Quests = {},

    Status = "Ready"
}

local function NewGeneration()
    State.Generation += 1
    return State.Generation
end

local function GenerationValid(id)
    return State.Alive and id == State.Generation
end

local function StopEverything()
    Config.AutoFish = false
    Config.AutoSell = false
    Config.AutoBuyRod = false
    Config.AutoQuest = false

    State.Fishing = false
    State.Selling = false
    State.Buying = false
    State.Questing = false

    NewGeneration()

    State.Status = "Stopped"
end

--//========================================================//--
--// NOTIFICATION
--//========================================================//--

local NotificationHolder

local function Notify(title, text, duration)
    if not Config.Notifications then
        return
    end

    if not NotificationHolder then
        return
    end

    duration = duration or 3

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 72)
    Frame.BackgroundColor3 = Color3.fromRGB(19, 22, 30)
    Frame.BorderSizePixel = 0
    Frame.BackgroundTransparency = 0.04
    Frame.Parent = NotificationHolder

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(95, 100, 125)
    Stroke.Transparency = 0.5
    Stroke.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 14, 0, 9)
    Title.Size = UDim2.new(1, -28, 0, 22)
    Title.Font = Enum.Font.GothamBold
    Title.Text = title
    Title.TextSize = 14
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local Body = Instance.new("TextLabel")
    Body.BackgroundTransparency = 1
    Body.Position = UDim2.new(0, 14, 0, 31)
    Body.Size = UDim2.new(1, -28, 0, 32)
    Body.Font = Enum.Font.Gotham
    Body.Text = text
    Body.TextSize = 12
    Body.TextColor3 = Color3.fromRGB(175, 180, 195)
    Body.TextWrapped = true
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.Parent = Frame

    Frame.Position = UDim2.new(1, 320, 0, 0)

    TweenService:Create(
        Frame,
        TweenInfo.new(0.25),
        {
            Position = UDim2.new(0, 0, 0, 0)
        }
    ):Play()

    task.delay(duration, function()
        if Frame and Frame.Parent then
            local tween = TweenService:Create(
                Frame,
                TweenInfo.new(0.25),
                {
                    Position = UDim2.new(1, 320, 0, 0)
                }
            )

            tween:Play()
            tween.Completed:Wait()

            if Frame then
                Frame:Destroy()
            end
        end
    end)
end

--//========================================================//--
--// REMOTE RESOLVER
--//========================================================//--

local function FindNet()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")

    if not Packages then
        return nil
    end

    local Index = Packages:FindFirstChild("_Index")

    if not Index then
        return nil
    end

    local NetPackage = Index:FindFirstChild("sleitnick_net@0.2.0")

    if NetPackage then
        local Net = NetPackage:FindFirstChild("net")

        if Net then
            return Net
        end
    end

    for _, obj in ipairs(Index:GetChildren()) do
        local Net = obj:FindFirstChild("net")

        if Net then
            return Net
        end
    end

    return nil
end

local Net = FindNet()

local function FindRemote(name)
    if not Net then
        Net = FindNet()
    end

    if not Net then
        return nil
    end

    return Net:FindFirstChild(name)
end

local function FindRemoteByPatterns(patterns)
    if not Net then
        Net = FindNet()
    end

    if not Net then
        return nil
    end

    for _, obj in ipairs(Net:GetChildren()) do
        local name = string.lower(obj.Name)

        for _, pattern in ipairs(patterns) do
            if string.find(name, string.lower(pattern), 1, true) then
                return obj
            end
        end
    end

    return nil
end

local EquipRemote = function()
    return FindRemote("RE/EquipToolFromHotbar")
end

local ChargeRemote = function()
    return FindRemote("RF/ChargeFishingRod")
end

local StartRemote = function()
    return FindRemote("RF/RequestFishingMinigameStarted")
end

local CompleteRemote = function()
    return FindRemote("RE/FishingCompleted")
end

local SellRemote = function()
    return FindRemote("RF/SellAllItems")
end

--//========================================================//--
--// CHARACTER
--//========================================================//--

local function GetCharacter()
    return LocalPlayer.Character
        or LocalPlayer.CharacterAdded:Wait()
end

local function GetRoot()
    local Character = GetCharacter()

    return Character:FindFirstChild("HumanoidRootPart")
        or Character:WaitForChild("HumanoidRootPart", 3)
end

--//========================================================//--
--// FISHING
--//========================================================//--

local function PerformFishing()
    local Equip = EquipRemote()
    local Charge = ChargeRemote()
    local Start = StartRemote()
    local Complete = CompleteRemote()

    if not Equip or not Charge or not Start or not Complete then
        State.Status = "Fishing remotes not found"
        return false
    end

    local ok = pcall(function()

        Equip:FireServer()

        if Config.FishDelay > 0 then
            task.wait(math.min(Config.FishDelay, 1))
        end

        Charge:InvokeServer(1)

        if Config.FishDelay > 0 then
            task.wait(math.min(Config.FishDelay, 1))
        end

        Start:InvokeServer(1, 1)

        if Config.InstantFish then
            Complete:FireServer()
        end
    end)

    if ok then
        State.FishCaught += 1
        State.Status = "Fishing..."
        return true
    end

    return false
end

local function StartFishing()
    if State.Fishing then
        return
    end

    Config.AutoFish = true

    local generation = NewGeneration()

    State.Fishing = true
    State.Status = "Fishing..."

    task.spawn(function()

        while GenerationValid(generation)
            and Config.AutoFish do

            PerformFishing()

            task.wait(
                math.max(
                    tonumber(Config.FishDelay) or 0.15,
                    0.03
                )
            )
        end

        State.Fishing = false

        if GenerationValid(generation) then
            State.Status = "Ready"
        end
    end)
end

local function StopFishing()
    Config.AutoFish = false
    State.Fishing = false
    NewGeneration()
    State.Status = "Ready"
end

--//========================================================//--
--// AUTO SELL
--//========================================================//--

local function StartAutoSell()
    if State.Selling then
        return
    end

    Config.AutoSell = true

    local generation = NewGeneration()

    State.Selling = true

    task.spawn(function()

        while GenerationValid(generation)
            and Config.AutoSell do

            local Sell = SellRemote()

            if Sell then
                pcall(function()
                    Sell:InvokeServer()
                end)

                State.Status = "Sold"
            else
                State.Status = "Sell remote not found"
            end

            task.wait(
                math.max(
                    tonumber(Config.SellDelay) or 10,
                    1
                )
            )
        end

        State.Selling = false

        if GenerationValid(generation) then
            State.Status = "Ready"
        end
    end)
end

local function StopAutoSell()
    Config.AutoSell = false
    State.Selling = false
    NewGeneration()
    State.Status = "Ready"
end

--//========================================================//--
--// OBJECT SCANNER
--//========================================================//--

local function GetBestPart(object)
    if object:IsA("BasePart") then
        return object
    end

    if object:IsA("Model") then
        if object.PrimaryPart then
            return object.PrimaryPart
        end

        local root = object:FindFirstChild("HumanoidRootPart")

        if root and root:IsA("BasePart") then
            return root
        end

        for _, child in ipairs(object:GetDescendants()) do
            if child:IsA("BasePart") then
                return child
            end
        end
    end

    return nil
end

local function TeleportToObject(object)
    local Root = GetRoot()

    if not Root or not object then
        return false
    end

    local Part = GetBestPart(object)

    if not Part then
        return false
    end

    pcall(function()
        Root.CFrame = Part.CFrame + Vector3.new(0, 4, 0)
    end)

    return true
end

--//========================================================//--
--// ISLAND SCANNER
--//========================================================//--

local IslandKeywords = {
    "island",
    "isle",
    "islands",
    "zone",
    "area"
}

local function LooksLikeIsland(name)
    local n = string.lower(name)

    for _, keyword in ipairs(IslandKeywords) do
        if string.find(n, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function ScanIslands()
    local result = {}
    local seen = {}

    local Workspace = workspace

    for _, obj in ipairs(Workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("Folder"))
            and LooksLikeIsland(obj.Name) then

            if not seen[obj.Name] then
                seen[obj.Name] = true
                table.insert(result, {
                    Name = obj.Name,
                    Object = obj
                })
            end
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    State.Islands = result

    return result
end

--//========================================================//--
--// NPC SCANNER
--//========================================================//--

local NPCKeywords = {
    "npc",
    "seller",
    "sell",
    "merchant",
    "shop",
    "quest",
    "rod",
    "bait",
    "dealer",
    "angler",
    "fisher",
    "fisherman"
}

local function LooksLikeNPC(name)
    local n = string.lower(name)

    for _, keyword in ipairs(NPCKeywords) do
        if string.find(n, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function ScanNPCs()
    local result = {}
    local seen = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model")
            and LooksLikeNPC(obj.Name)
            and GetBestPart(obj) then

            if not seen[obj.Name] then
                seen[obj.Name] = true

                table.insert(result, {
                    Name = obj.Name,
                    Object = obj
                })
            end
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    State.NPCs = result

    return result
end

--//========================================================//--
--// ROD REMOTE SCANNER
--//========================================================//--

local function ScanRodRemotes()
    local result = {}

    local patterns = {
        "rod",
        "buyrod",
        "purchaserod",
        "purchasefishingrod",
        "fishingrod"
    }

    if not Net then
        Net = FindNet()
    end

    if Net then
        for _, obj in ipairs(Net:GetChildren()) do
            local lower = string.lower(obj.Name)

            for _, pattern in ipairs(patterns) do
                if string.find(lower, pattern, 1, true) then

                    table.insert(result, {
                        Name = obj.Name,
                        Object = obj
                    })

                    break
                end
            end
        end
    end

    State.Rods = result

    return result
end

--//========================================================//--
--// AUTO BUY ROD
--//========================================================//--

local function TryBuyRod()
    if not Config.SelectedRod
        or Config.SelectedRod == "" then
        return false
    end

    if not Net then
        Net = FindNet()
    end

    if not Net then
        return false
    end

    local Remote

    local patterns = {
        "purchaserod",
        "buyrod",
        "purchasefishingrod",
        "rodpurchase",
        "purchase"
    }

    Remote = FindRemoteByPatterns(patterns)

    if not Remote then
        return false
    end

    local ok = false

    pcall(function()

        if Remote:IsA("RemoteFunction") then
            Remote:InvokeServer(Config.SelectedRod)
            ok = true

        elseif Remote:IsA("RemoteEvent") then
            Remote:FireServer(Config.SelectedRod)
            ok = true
        end

    end)

    return ok
end

local function StartAutoBuy()
    if State.Buying then
        return
    end

    Config.AutoBuyRod = true

    local generation = NewGeneration()

    State.Buying = true

    task.spawn(function()

        while GenerationValid(generation)
            and Config.AutoBuyRod do

            TryBuyRod()

            task.wait(15)
        end

        State.Buying = false
    end)
end

local function StopAutoBuy()
    Config.AutoBuyRod = false
    State.Buying = false
    NewGeneration()
end

--//========================================================//--
--// QUEST SCANNER
--//========================================================//--

local function ScanQuests()
    local result = {}
    local seen = {}

    local function AddQuest(name, source)
        if not name or name == "" then
            return
        end

        local clean = tostring(name)
        clean = clean:gsub("%s+", " ")

        if #clean < 3 then
            return
        end

        if not seen[clean] then
            seen[clean] = true

            table.insert(result, {
                Name = clean,
                Source = source
            })
        end
    end

    -- GUI scanner
    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

    if PlayerGui then
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel")
                or obj:IsA("TextButton")
                or obj:IsA("TextBox") then

                local text = obj.Text or ""
                local lower = string.lower(text)

                if string.find(lower, "quest", 1, true)
                    or string.find(lower, "mission", 1, true)
                    or string.find(lower, "objective", 1, true) then

                    AddQuest(text, "GUI")
                end
            end
        end
    end

    -- Workspace quest objects
    for _, obj in ipairs(workspace:GetDescendants()) do
        local name = string.lower(obj.Name)

        if string.find(name, "quest", 1, true)
            or string.find(name, "mission", 1, true) then

            AddQuest(obj.Name, "Workspace")
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    State.Quests = result

    return result
end

-- Safe quest mode:
-- scanner/teleport only, because quest server arguments
-- can change and shouldn't be fabricated.
local function StartAutoQuest()
    if State.Questing then
        return
    end

    Config.AutoQuest = true

    local generation = NewGeneration()

    State.Questing = true

    task.spawn(function()

        while GenerationValid(generation)
            and Config.AutoQuest do

            ScanQuests()

            State.Status = "Scanning quests..."

            task.wait(5)
        end

        State.Questing = false
    end)
end

local function StopAutoQuest()
    Config.AutoQuest = false
    State.Questing = false
    NewGeneration()
end

--//========================================================//--
--// FISH COUNTER
--//========================================================//--

local function CountInventoryItems()
    local total = 0

    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    if Backpack then
        for _, item in ipairs(Backpack:GetChildren()) do
            total += 1
        end
    end

    local Character = LocalPlayer.Character

    if Character then
        for _, item in ipairs(Character:GetChildren()) do
            if item:IsA("Tool") then
                total += 1
            end
        end
    end

    return total
end

local function StartFishCounter()
    task.spawn(function()

        local previous = CountInventoryItems()

        while State.Alive do

            task.wait(1)

            local current = CountInventoryItems()

            if current > previous then
                State.FishCaught += current - previous
            end

            previous = current
            State.LastInventoryCount = current
        end
    end)
end

--//========================================================//--
--// UI
--//========================================================//--

local Existing = CoreGui:FindFirstChild("KAIZEN_HUB_V2")

if Existing then
    Existing:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KAIZEN_HUB_V2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Notification holder
NotificationHolder = Instance.new("Frame")
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Position = UDim2.new(1, -305, 0, 20)
NotificationHolder.Size = UDim2.new(0, 290, 1, -40)
NotificationHolder.ZIndex = 20
NotificationHolder.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Padding = UDim.new(0, 8)
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotificationLayout.Parent = NotificationHolder

-- Main
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(790, 500)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(13, 15, 21)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 75)
MainStroke.Transparency = 0.25
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 65)
TopBar.BackgroundColor3 = Color3.fromRGB(17, 20, 28)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 16)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 22, 0, 10)
Title.Size = UDim2.new(0, 300, 0, 27)
Title.Font = Enum.Font.GothamBold
Title.Text = "🎣  KAIZEN HUB"
Title.TextSize = 21
Title.TextColor3 = Color3.fromRGB(245, 247, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 24, 0, 36)
Subtitle.Size = UDim2.new(0, 300, 0, 17)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "Fish It  •  Premium Edition  •  v2.0"
Subtitle.TextSize = 11
Subtitle.TextColor3 = Color3.fromRGB(120, 126, 145)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(1, -270, 0, 19)
StatusLabel.Size = UDim2.new(0, 200, 0, 27)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "●  READY"
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = Color3.fromRGB(110, 220, 150)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
StatusLabel.Parent = TopBar

local CollapseButton = Instance.new("TextButton")
CollapseButton.Name = "CollapseButton"
CollapseButton.Position = UDim2.new(1, -54, 0, 11)
CollapseButton.Size = UDim2.fromOffset(44, 44)
CollapseButton.BackgroundColor3 = Color3.fromRGB(35, 40, 53)
CollapseButton.BorderSizePixel = 0
CollapseButton.Font = Enum.Font.GothamBold
CollapseButton.Text = "−"
CollapseButton.TextSize = 24
CollapseButton.TextColor3 = Color3.fromRGB(235, 238, 248)
CollapseButton.Parent = TopBar

local CollapseCorner = Instance.new("UICorner")
CollapseCorner.CornerRadius = UDim.new(0, 10)
CollapseCorner.Parent = CollapseButton

local ExpandButton = Instance.new("TextButton")
ExpandButton.Name = "ExpandButton"
ExpandButton.Position = UDim2.fromOffset(12, 12)
ExpandButton.Size = UDim2.fromOffset(54, 54)
ExpandButton.BackgroundColor3 = Color3.fromRGB(35, 40, 53)
ExpandButton.BorderSizePixel = 0
ExpandButton.Font = Enum.Font.GothamBold
ExpandButton.Text = "🎣"
ExpandButton.TextSize = 23
ExpandButton.TextColor3 = Color3.fromRGB(235, 238, 248)
ExpandButton.Visible = false
ExpandButton.Parent = ScreenGui

local ExpandCorner = Instance.new("UICorner")
ExpandCorner.CornerRadius = UDim.new(0, 14)
ExpandCorner.Parent = ExpandButton

local ExpandStroke = Instance.new("UIStroke")
ExpandStroke.Color = Color3.fromRGB(90, 110, 155)
ExpandStroke.Transparency = 0.25
ExpandStroke.Parent = ExpandButton

-- Sidebar
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Position = UDim2.new(0, 12, 0, 77)
Sidebar.Size = UDim2.new(0, 155, 1, -89)
Sidebar.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 13)
SidebarCorner.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 12)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

local Content
local TabButtons

local function UpdateLayout()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local width = math.max(1, math.min(790, viewport.X - 24))
    local height = math.max(1, math.min(500, viewport.Y - 72))
    local mobile = viewport.X < 650
        or (UserInputService.TouchEnabled and viewport.X < 850)

    local notificationWidth = math.max(1, math.min(290, viewport.X - 24))
    NotificationHolder.Size = UDim2.new(0, notificationWidth, 1, -40)
    NotificationHolder.Position = UDim2.new(1, -notificationWidth - 12, 0, 20)

    Main.Size = UDim2.fromOffset(width, height)
    Main.Position = UDim2.fromScale(0.5, 0.5)

    if mobile then
        Sidebar.Position = UDim2.fromOffset(12, 72)
        Sidebar.Size = UDim2.new(1, -24, 0, 50)
        Sidebar.ScrollingDirection = Enum.ScrollingDirection.X
        SidebarLayout.FillDirection = Enum.FillDirection.Horizontal
        SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        SidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        SidebarPadding.PaddingTop = UDim.new(0, 4)
        SidebarPadding.PaddingBottom = UDim.new(0, 4)
        Content.Position = UDim2.fromOffset(12, 132)
        Content.Size = UDim2.new(1, -24, 1, -144)
        StatusLabel.Visible = false
        Subtitle.Visible = width >= 380
        Title.Size = UDim2.new(1, -90, 0, 27)
        Title.Text = width < 380 and "🎣  KAIZEN" or "🎣  KAIZEN HUB"
        Title.TextSize = width < 380 and 18 or 21
    else
        Sidebar.Position = UDim2.fromOffset(12, 77)
        Sidebar.Size = UDim2.new(0, 155, 1, -89)
        Sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
        SidebarLayout.FillDirection = Enum.FillDirection.Vertical
        SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        SidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        SidebarPadding.PaddingTop = UDim.new(0, 12)
        SidebarPadding.PaddingBottom = UDim.new(0, 0)
        Content.Position = UDim2.new(0, 180, 0, 77)
        Content.Size = UDim2.new(1, -192, 1, -89)
        StatusLabel.Visible = true
        Subtitle.Visible = true
        Title.Size = UDim2.new(0, 300, 0, 27)
        Title.Text = "🎣  KAIZEN HUB"
        Title.TextSize = 21
    end

    for _, button in pairs(TabButtons or {}) do
        button.Size = mobile and UDim2.fromOffset(105, 40)
            or UDim2.new(1, 0, 0, 39)
    end

    Sidebar.CanvasSize = mobile
        and UDim2.fromOffset(SidebarLayout.AbsoluteContentSize.X + 16, 0)
        or UDim2.fromOffset(0, SidebarLayout.AbsoluteContentSize.Y + 24)
end

-- Content
Content = Instance.new("Frame")
Content.Position = UDim2.new(0, 180, 0, 77)
Content.Size = UDim2.new(1, -192, 1, -89)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageTransparency = 0.5
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Parent = Content

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 10)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Page

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 2)
    Padding.PaddingRight = UDim.new(0, 6)
    Padding.PaddingTop = UDim.new(0, 2)
    Padding.PaddingBottom = UDim.new(0, 12)
    Padding.Parent = Page

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(
            0,
            0,
            0,
            Layout.AbsoluteContentSize.Y + 20
        )
    end)

    Pages[name] = Page

    return Page
end

local FishingPage = CreatePage("Fishing")
local FarmingPage = CreatePage("Farming")
local TeleportPage = CreatePage("Teleport")
local ShopPage = CreatePage("Shop")
local QuestPage = CreatePage("Quest")
local SettingsPage = CreatePage("Settings")
local ConfigPage = CreatePage("Config")

--//========================================================//--
--// UI HELPERS
--//========================================================//--

local function CreateCard(parent, height)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, height)
    Card.BackgroundColor3 = Color3.fromRGB(19, 22, 30)
    Card.BorderSizePixel = 0
    Card.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Card

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(45, 49, 62)
    Stroke.Transparency = 0.35
    Stroke.Parent = Card

    return Card
end

local function CreateSectionTitle(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 26)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.Text = text
    Label.TextSize = 14
    Label.TextColor3 = Color3.fromRGB(235, 238, 248)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent

    return Label
end

local function CreateButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.BackgroundColor3 = Color3.fromRGB(27, 31, 42)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.GothamMedium
    Button.Text = text
    Button.TextSize = 12
    Button.TextColor3 = Color3.fromRGB(220, 224, 235)
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Button

    Button.MouseEnter:Connect(function()
        TweenService:Create(
            Button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = Color3.fromRGB(35, 40, 53)
            }
        ):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(
            Button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = Color3.fromRGB(27, 31, 42)
            }
        ):Play()
    end)

    Button.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    return Button
end

local function CreateToggle(parent, text, getter, setter)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 48)
    Button.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Text = ""
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Button

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.Size = UDim2.new(1, -85, 1, 0)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = text
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(225, 228, 238)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.fromOffset(42, 22)
    Switch.Position = UDim2.new(1, -56, 0.5, -11)
    Switch.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    Switch.BorderSizePixel = 0
    Switch.Parent = Button

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.fromOffset(16, 16)
    Dot.Position = UDim2.new(0, 3, 0.5, -8)
    Dot.BackgroundColor3 = Color3.fromRGB(180, 184, 195)
    Dot.BorderSizePixel = 0
    Dot.Parent = Switch

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = Dot

    local function Refresh()
        local enabled = getter()

        if enabled then
            Switch.BackgroundColor3 = Color3.fromRGB(82, 145, 255)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

            TweenService:Create(
                Dot,
                TweenInfo.new(0.15),
                {
                    Position = UDim2.new(1, -19, 0.5, -8)
                }
            ):Play()
        else
            Switch.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
            Dot.BackgroundColor3 = Color3.fromRGB(180, 184, 195)

            TweenService:Create(
                Dot,
                TweenInfo.new(0.15),
                {
                    Position = UDim2.new(0, 3, 0.5, -8)
                }
            ):Play()
        end
    end

    Button.MouseButton1Click:Connect(function()
        local newValue = not getter()

        setter(newValue)
        Refresh()
    end)

    Refresh()

    return {
        Button = Button,
        Refresh = Refresh
    }
end

local function CreateSlider(parent, text, min, max, getter, setter)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 65)
    Holder.BackgroundTransparency = 1
    Holder.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(0.7, 0, 0, 22)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = text
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(225, 228, 238)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Value = Instance.new("TextLabel")
    Value.BackgroundTransparency = 1
    Value.Position = UDim2.new(0.7, 0, 0, 0)
    Value.Size = UDim2.new(0.3, 0, 0, 22)
    Value.Font = Enum.Font.GothamMedium
    Value.TextSize = 12
    Value.TextColor3 = Color3.fromRGB(130, 175, 255)
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Position = UDim2.new(0, 0, 0, 36)
    Bar.Size = UDim2.new(1, 0, 0, 5)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 43, 54)
    Bar.BorderSizePixel = 0
    Bar.Parent = Holder

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = Bar

    local HitArea = Instance.new("Frame")
    HitArea.Position = UDim2.new(0, 0, 0, 23)
    HitArea.Size = UDim2.new(1, 0, 0, 32)
    HitArea.BackgroundTransparency = 1
    HitArea.Active = true
    HitArea.ZIndex = 2
    HitArea.Parent = Holder

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(88, 150, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Size = UDim2.fromOffset(14, 14)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Bar

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local dragging = false
    local touchInput

    local function Refresh(value)
        value = math.clamp(value, min, max)

        local alpha = (value - min) / (max - min)

        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        Knob.Position = UDim2.new(alpha, 0, 0.5, 0)

        Value.Text = string.format("%.2f", value)

        setter(value)
    end

    local function SetFromX(x)
        if Bar.AbsoluteSize.X <= 0 then
            return
        end

        local alpha = math.clamp(
            (x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
            0,
            1
        )

        local value = min + (max - min) * alpha

        Refresh(value)
    end

    HitArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            touchInput = input.UserInputType == Enum.UserInputType.Touch
                and input or nil
            SetFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging
            and (input == touchInput
                or (not touchInput and input.UserInputType == Enum.UserInputType.MouseMovement)) then

            SetFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == touchInput
            or (not touchInput and input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false
            touchInput = nil
        end
    end)

    Refresh(getter())

    return Holder
end

local function CreateDropdown(parent, text, options, getter, setter)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 58)
    Holder.BackgroundTransparency = 1
    Holder.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = text
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(225, 228, 238)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Button = Instance.new("TextButton")
    Button.Position = UDim2.new(0, 0, 0, 25)
    Button.Size = UDim2.new(1, 0, 0, 32)
    Button.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 11
    Button.TextColor3 = Color3.fromRGB(220, 224, 235)
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Parent = Holder

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 12)
    Padding.Parent = Button

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Arrow = Instance.new("TextLabel")
    Arrow.BackgroundTransparency = 1
    Arrow.Position = UDim2.new(1, -35, 0, 0)
    Arrow.Size = UDim2.new(0, 30, 1, 0)
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Text = "▼"
    Arrow.TextSize = 10
    Arrow.TextColor3 = Color3.fromRGB(130, 135, 150)
    Arrow.Parent = Button

    local Open = false
    local Menu

    local function Refresh()
        Button.Text = tostring(getter() or options[1] or "None")
    end

    local function Close()
        Open = false

        if Menu then
            Menu:Destroy()
            Menu = nil
        end
    end

    local function OpenMenu()
        Close()

        Open = true

        Menu = Instance.new("Frame")
        Menu.ZIndex = 100
        Menu.Size = UDim2.new(1, 0, 0, math.min(#options * 31, 155))
        Menu.Position = UDim2.new(
            0,
            0,
            0,
            60
        )
        Menu.BackgroundColor3 = Color3.fromRGB(25, 29, 39)
        Menu.BorderSizePixel = 0
        Menu.Parent = Holder

        local Corner2 = Instance.new("UICorner")
        Corner2.CornerRadius = UDim.new(0, 8)
        Corner2.Parent = Menu

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Menu

        for _, option in ipairs(options) do

            local Item = Instance.new("TextButton")
            Item.ZIndex = 101
            Item.Size = UDim2.new(1, 0, 0, 31)
            Item.BackgroundTransparency = 1
            Item.BorderSizePixel = 0
            Item.AutoButtonColor = false
            Item.Font = Enum.Font.Gotham
            Item.Text = option
            Item.TextSize = 11
            Item.TextColor3 = Color3.fromRGB(210, 214, 225)
            Item.Parent = Menu

            Item.MouseEnter:Connect(function()
                Item.BackgroundTransparency = 0
                Item.BackgroundColor3 = Color3.fromRGB(38, 43, 56)
            end)

            Item.MouseLeave:Connect(function()
                Item.BackgroundTransparency = 1
            end)

            Item.MouseButton1Click:Connect(function()
                setter(option)
                Refresh()
                Close()
            end)
        end
    end

    Button.MouseButton1Click:Connect(function()
        if Open then
            Close()
        else
            OpenMenu()
        end
    end)

    Refresh()

    return Holder
end

--//========================================================//--
--// SIDEBAR
--//========================================================//--

local Tabs = {
    {"🎣", "Fishing"},
    {"💰", "Farming"},
    {"📍", "Teleport"},
    {"🛒", "Shop"},
    {"🎯", "Quest"},
    {"⚙", "Settings"},
    {"💾", "Config"}
}

TabButtons = {}

local function ShowPage(name)
    State.SelectedTab = name

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for tabName, button in pairs(TabButtons) do
        if tabName == name then
            button.BackgroundColor3 = Color3.fromRGB(45, 53, 70)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
            button.TextColor3 = Color3.fromRGB(150, 155, 170)
        end
    end
end

for index, data in ipairs(Tabs) do
    local icon = data[1]
    local name = data[2]

    local Button = Instance.new("TextButton")
    Button.LayoutOrder = index
    Button.Size = UDim2.new(1, 0, 0, 39)
    Button.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.GothamMedium
    Button.Text = icon .. "   " .. name
    Button.TextSize = 11
    Button.TextColor3 = Color3.fromRGB(150, 155, 170)
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Parent = Sidebar

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 12)
    Padding.Parent = Button

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    Button.MouseButton1Click:Connect(function()
        ShowPage(name)
    end)

    TabButtons[name] = Button
end

SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local mobile = SidebarLayout.FillDirection == Enum.FillDirection.Horizontal
    Sidebar.CanvasSize = mobile
        and UDim2.fromOffset(SidebarLayout.AbsoluteContentSize.X + 16, 0)
        or UDim2.fromOffset(0, SidebarLayout.AbsoluteContentSize.Y + 24)
end)

local viewportConnection
local function WatchViewport()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayout)
    end

    UpdateLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(WatchViewport)
WatchViewport()

--//========================================================//--
--// FISHING PAGE
--//========================================================//--

CreateSectionTitle(FishingPage, "Fishing Controls")

local FishingCard = CreateCard(FishingPage, 285)

local FishingPadding = Instance.new("UIPadding")
FishingPadding.PaddingTop = UDim.new(0, 12)
FishingPadding.PaddingBottom = UDim.new(0, 12)
FishingPadding.PaddingLeft = UDim.new(0, 14)
FishingPadding.PaddingRight = UDim.new(0, 14)
FishingPadding.Parent = FishingCard

local FishingLayout = Instance.new("UIListLayout")
FishingLayout.Padding = UDim.new(0, 7)
FishingLayout.Parent = FishingCard

CreateToggle(
    FishingCard,
    "Instant Fish",
    function()
        return Config.InstantFish
    end,
    function(v)
        Config.InstantFish = v
        SaveConfig()
    end
)

CreateToggle(
    FishingCard,
    "Auto Fish",
    function()
        return Config.AutoFish
    end,
    function(v)
        if v then
            StartFishing()
        else
            StopFishing()
        end
    end
)

CreateSlider(
    FishingCard,
    "Fish Delay",
    0.03,
    2,
    function()
        return tonumber(Config.FishDelay) or 0.15
    end,
    function(v)
        Config.FishDelay = tonumber(string.format("%.2f", v))
    end
)

CreateDropdown(
    FishingCard,
    "Rarity Filter",
    {
        "All",
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Mythic",
        "Secret"
    },
    function()
        return Config.Rarity
    end,
    function(v)
        Config.Rarity = v
        SaveConfig()
    end
)

CreateSectionTitle(FishingPage, "Session")

local SessionCard = CreateCard(FishingPage, 125)

local SessionPadding = Instance.new("UIPadding")
SessionPadding.PaddingTop = UDim.new(0, 12)
SessionPadding.PaddingBottom = UDim.new(0, 12)
SessionPadding.PaddingLeft = UDim.new(0, 14)
SessionPadding.PaddingRight = UDim.new(0, 14)
SessionPadding.Parent = SessionCard

local FishCounter = Instance.new("TextLabel")
FishCounter.BackgroundTransparency = 1
FishCounter.Size = UDim2.new(1, 0, 0, 40)
FishCounter.Font = Enum.Font.GothamBold
FishCounter.Text = "🐟 0"
FishCounter.TextSize = 28
FishCounter.TextColor3 = Color3.fromRGB(120, 175, 255)
FishCounter.TextXAlignment = Enum.TextXAlignment.Left
FishCounter.Parent = SessionCard

local SessionStatus = Instance.new("TextLabel")
SessionStatus.BackgroundTransparency = 1
SessionStatus.Position = UDim2.new(0, 0, 0, 48)
SessionStatus.Size = UDim2.new(1, 0, 0, 25)
SessionStatus.Font = Enum.Font.Gotham
SessionStatus.Text = "Status: Ready"
SessionStatus.TextSize = 11
SessionStatus.TextColor3 = Color3.fromRGB(135, 140, 155)
SessionStatus.TextXAlignment = Enum.TextXAlignment.Left
SessionStatus.Parent = SessionCard

local StopButton = CreateButton(
    FishingPage,
    "🛑  STOP ALL",
    function()
        StopEverything()
        Notify("KAIZEN HUB", "All automation stopped.", 2)
    end
)

StopButton.BackgroundColor3 = Color3.fromRGB(92, 38, 45)

--//========================================================//--
--// FARMING PAGE
--//========================================================//--

CreateSectionTitle(FarmingPage, "Farming")

local FarmingCard = CreateCard(FarmingPage, 175)

local FarmingPadding = Instance.new("UIPadding")
FarmingPadding.PaddingTop = UDim.new(0, 12)
FarmingPadding.PaddingBottom = UDim.new(0, 12)
FarmingPadding.PaddingLeft = UDim.new(0, 14)
FarmingPadding.PaddingRight = UDim.new(0, 14)
FarmingPadding.Parent = FarmingCard

local FarmingLayout = Instance.new("UIListLayout")
FarmingLayout.Padding = UDim.new(0, 7)
FarmingLayout.Parent = FarmingCard

CreateToggle(
    FarmingCard,
    "Auto Sell All",
    function()
        return Config.AutoSell
    end,
    function(v)
        if v then
            StartAutoSell()
        else
            StopAutoSell()
        end
    end
)

CreateSlider(
    FarmingCard,
    "Sell Delay",
    1,
    60,
    function()
        return tonumber(Config.SellDelay) or 10
    end,
    function(v)
        Config.SellDelay = math.floor(v)
    end
)

CreateButton(
    FarmingPage,
    "💰  Sell All Now",
    function()
        local Sell = SellRemote()

        if Sell then
            pcall(function()
                Sell:InvokeServer()
            end)

            Notify("Farming", "Sell request sent.", 2)
        else
            Notify("Farming", "Sell remote not found.", 3)
        end
    end
)

--//========================================================//--
--// TELEPORT PAGE
--//========================================================//--

CreateSectionTitle(TeleportPage, "World Teleport")

local IslandNames = {"None"}

local function RebuildIslandNames()
    ScanIslands()

    IslandNames = {"None"}

    for _, data in ipairs(State.Islands) do
        table.insert(IslandNames, data.Name)
    end
end

RebuildIslandNames()

local IslandDropdown = CreateDropdown(
    TeleportPage,
    "Island",
    IslandNames,
    function()
        return Config.SelectedIsland ~= ""
            and Config.SelectedIsland
            or "None"
    end,
    function(v)
        if v == "None" then
            Config.SelectedIsland = ""
        else
            Config.SelectedIsland = v
        end

        SaveConfig()
    end
)

CreateButton(
    TeleportPage,
    "📍  Teleport To Island",
    function()
        ScanIslands()

        for _, data in ipairs(State.Islands) do
            if data.Name == Config.SelectedIsland then
                if TeleportToObject(data.Object) then
                    Notify("Teleport", "Teleported to " .. data.Name, 2)
                else
                    Notify("Teleport", "No valid position found.", 2)
                end

                return
            end
        end

        Notify("Teleport", "Island not found. Refresh the list.", 3)
    end
)

CreateButton(
    TeleportPage,
    "🔄  Refresh Islands",
    function()
        RebuildIslandNames()
        Notify("Teleport", "Island scanner refreshed.", 2)
    end
)

CreateSectionTitle(TeleportPage, "NPC Teleport")

local NPCNames = {"None"}

local function RebuildNPCNames()
    ScanNPCs()

    NPCNames = {"None"}

    for _, data in ipairs(State.NPCs) do
        table.insert(NPCNames, data.Name)
    end
end

RebuildNPCNames()

CreateDropdown(
    TeleportPage,
    "NPC",
    NPCNames,
    function()
        return Config.SelectedNPC ~= ""
            and Config.SelectedNPC
            or "None"
    end,
    function(v)
        if v == "None" then
            Config.SelectedNPC = ""
        else
            Config.SelectedNPC = v
        end

        SaveConfig()
    end
)

CreateButton(
    TeleportPage,
    "👤  Teleport To NPC",
    function()
        ScanNPCs()

        for _, data in ipairs(State.NPCs) do
            if data.Name == Config.SelectedNPC then

                if TeleportToObject(data.Object) then
                    Notify("Teleport", "Teleported to " .. data.Name, 2)
                else
                    Notify("Teleport", "NPC has no valid position.", 2)
                end

                return
            end
        end

        Notify("Teleport", "NPC not found. Refresh the list.", 3)
    end
)

CreateButton(
    TeleportPage,
    "🔄  Refresh NPCs",
    function()
        RebuildNPCNames()
        Notify("Teleport", "NPC scanner refreshed.", 2)
    end
)

--//========================================================//--
--// SHOP PAGE
--//========================================================//--

CreateSectionTitle(ShopPage, "Rod Shop")

local RodNames = {"None"}

local function RebuildRodNames()
    ScanRodRemotes()

    RodNames = {"None"}

    for _, data in ipairs(State.Rods) do
        table.insert(RodNames, data.Name)
    end
end

RebuildRodNames()

CreateDropdown(
    ShopPage,
    "Detected Rod Purchase Remote",
    RodNames,
    function()
        return Config.SelectedRod ~= ""
            and Config.SelectedRod
            or "None"
    end,
    function(v)
        if v == "None" then
            Config.SelectedRod = ""
        else
            Config.SelectedRod = v
        end

        SaveConfig()
    end
)

CreateToggle(
    ShopPage,
    "Auto Buy Rod",
    function()
        return Config.AutoBuyRod
    end,
    function(v)
        if v then
            if Config.SelectedRod == "" then
                Notify(
                    "Shop",
                    "Select a detected rod remote first.",
                    3
                )
                return
            end

            StartAutoBuy()
        else
            StopAutoBuy()
        end
    end
)

CreateButton(
    ShopPage,
    "🛒  Buy / Request Selected Rod",
    function()
        if Config.SelectedRod == "" then
            Notify("Shop", "No rod selected.", 2)
            return
        end

        if TryBuyRod() then
            Notify("Shop", "Purchase request sent.", 2)
        else
            Notify(
                "Shop",
                "No compatible purchase remote detected.",
                3
            )
        end
    end
)

CreateButton(
    ShopPage,
    "🔄  Scan Rod Remotes",
    function()
        RebuildRodNames()

        Notify(
            "Shop",
            "Detected " .. tostring(#State.Rods) .. " rod-related remote(s).",
            3
        )
    end
)

--//========================================================//--
--// QUEST PAGE
--//========================================================//--

CreateSectionTitle(QuestPage, "Quest Scanner")

local QuestCard = CreateCard(QuestPage, 190)

local QuestPadding = Instance.new("UIPadding")
QuestPadding.PaddingTop = UDim.new(0, 12)
QuestPadding.PaddingBottom = UDim.new(0, 12)
QuestPadding.PaddingLeft = UDim.new(0, 14)
QuestPadding.PaddingRight = UDim.new(0, 14)
QuestPadding.Parent = QuestCard

local QuestText = Instance.new("TextLabel")
QuestText.BackgroundTransparency = 1
QuestText.Size = UDim2.new(1, 0, 1, -55)
QuestText.Font = Enum.Font.Gotham
QuestText.Text = "No quest scanned yet."
QuestText.TextSize = 11
QuestText.TextColor3 = Color3.fromRGB(175, 180, 195)
QuestText.TextWrapped = true
QuestText.TextXAlignment = Enum.TextXAlignment.Left
QuestText.TextYAlignment = Enum.TextYAlignment.Top
QuestText.Parent = QuestCard

local function UpdateQuestText()
    if #State.Quests == 0 then
        QuestText.Text = "No quest/objective detected."
        return
    end

    local lines = {}

    for i, quest in ipairs(State.Quests) do
        if i > 8 then
            break
        end

        table.insert(
            lines,
            "• " .. quest.Name
        )
    end

    QuestText.Text = table.concat(lines, "\n")
end

CreateButton(
    QuestPage,
    "🔎  Scan Quests",
    function()
        ScanQuests()
        UpdateQuestText()

        Notify(
            "Quest",
            "Found " .. tostring(#State.Quests) .. " quest-related entry.",
            3
        )
    end
)

CreateToggle(
    QuestPage,
    "Auto Quest Scanner",
    function()
        return Config.AutoQuest
    end,
    function(v)
        if v then
            StartAutoQuest()
        else
            StopAutoQuest()
        end
    end
)

CreateButton(
    QuestPage,
    "📋  Refresh Quest Info",
    function()
        ScanQuests()
        UpdateQuestText()
    end
)

--//========================================================//--
--// SETTINGS PAGE
--//========================================================//--

CreateSectionTitle(SettingsPage, "General Settings")

local SettingsCard = CreateCard(SettingsPage, 155)

local SettingsPadding = Instance.new("UIPadding")
SettingsPadding.PaddingTop = UDim.new(0, 12)
SettingsPadding.PaddingBottom = UDim.new(0, 12)
SettingsPadding.PaddingLeft = UDim.new(0, 14)
SettingsPadding.PaddingRight = UDim.new(0, 14)
SettingsPadding.Parent = SettingsCard

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 7)
SettingsLayout.Parent = SettingsCard

CreateToggle(
    SettingsCard,
    "Notifications",
    function()
        return Config.Notifications
    end,
    function(v)
        Config.Notifications = v
        SaveConfig()
    end
)

CreateButton(
    SettingsPage,
    "🛑  Emergency Stop",
    function()
        StopEverything()

        Config.AutoFish = false
        Config.AutoSell = false
        Config.AutoBuyRod = false
        Config.AutoQuest = false

        SaveConfig()

        Notify(
            "KAIZEN HUB",
            "Emergency stop executed.",
            3
        )
    end
)

CreateButton(
    SettingsPage,
    "🔄  Refresh Game Remotes",
    function()
        Net = FindNet()

        Notify(
            "KAIZEN HUB",
            Net and "Network refreshed." or "Network not found.",
            3
        )
    end
)

--//========================================================//--
--// CONFIG PAGE
--//========================================================//--

CreateSectionTitle(ConfigPage, "Configuration")

local ConfigCard = CreateCard(ConfigPage, 210)

local ConfigPadding = Instance.new("UIPadding")
ConfigPadding.PaddingTop = UDim.new(0, 12)
ConfigPadding.PaddingBottom = UDim.new(0, 12)
ConfigPadding.PaddingLeft = UDim.new(0, 14)
ConfigPadding.PaddingRight = UDim.new(0, 14)
ConfigPadding.Parent = ConfigCard

local ConfigInfo = Instance.new("TextLabel")
ConfigInfo.BackgroundTransparency = 1
ConfigInfo.Size = UDim2.new(1, 0, 0, 50)
ConfigInfo.Font = Enum.Font.Gotham
ConfigInfo.Text =
    "KAIZEN HUB saves your fishing, farming,\n" ..
    "teleport and UI preferences."
ConfigInfo.TextSize = 11
ConfigInfo.TextColor3 = Color3.fromRGB(150, 155, 170)
ConfigInfo.TextXAlignment = Enum.TextXAlignment.Left
ConfigInfo.Parent = ConfigCard

local SaveButton = CreateButton(
    ConfigCard,
    "💾  Save Config",
    function()
        if SaveConfig() then
            Notify("Config", "Configuration saved.", 2)
        else
            Notify(
                "Config",
                "Filesystem API unavailable.",
                3
            )
        end
    end
)

local LoadButton = CreateButton(
    ConfigCard,
    "📂  Load Config",
    function()
        if LoadConfig() then
            Notify("Config", "Configuration loaded.", 2)
        else
            Notify(
                "Config",
                "No saved config found.",
                3
            )
        end
    end
)

local ResetButton = CreateButton(
    ConfigCard,
    "♻️  Reset Config",
    function()
        ResetConfig()

        Notify(
            "Config",
            "Configuration reset.",
            2
        )
    end
)

--//========================================================//--
--// WINDOW VISIBILITY
--//========================================================//--

local function SetWindowVisible(visible)
    Config.WindowVisible = visible
    Main.Visible = visible
    ExpandButton.Visible = not visible
    SaveConfig()
end

CollapseButton.MouseButton1Click:Connect(function()
    SetWindowVisible(false)
end)

ExpandButton.MouseButton1Click:Connect(function()
    SetWindowVisible(true)
end)

Main.Visible = Config.WindowVisible
ExpandButton.Visible = not Config.WindowVisible

--//========================================================//--
--// DRAG
--//========================================================//--

local Dragging = false
local DragStart
local StartPosition
local DragInput

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local position = input.Position
    local buttonPosition = CollapseButton.AbsolutePosition
    local buttonSize = CollapseButton.AbsoluteSize
    if position.X >= buttonPosition.X
        and position.X <= buttonPosition.X + buttonSize.X
        and position.Y >= buttonPosition.Y
        and position.Y <= buttonPosition.Y + buttonSize.Y then
        return
    end

    Dragging = true
    DragInput = input
    DragStart = position
    StartPosition = Main.Position
end)

UserInputService.InputChanged:Connect(function(input)
    if not Dragging then
        return
    end

    if input ~= DragInput
        and not (DragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement) then
        return
    end

    local delta = input.Position - DragStart
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Main.AbsoluteSize
    local limitX = math.max(0, (viewport.X - Main.AbsoluteSize.X) / 2 - 8)
    local limitY = math.max(0, (viewport.Y - Main.AbsoluteSize.Y) / 2 - 8)
    local x = math.clamp(StartPosition.X.Offset + delta.X, -limitX, limitX)
    local y = math.clamp(StartPosition.Y.Offset + delta.Y, -limitY, limitY)

    Main.Position = UDim2.new(0.5, x, 0.5, y)
end)

UserInputService.InputEnded:Connect(function(input)
    if input == DragInput then
        Dragging = false
        DragInput = nil
    end
end)

--//========================================================//--
--// RIGHT CTRL TOGGLE
--//========================================================//--

UserInputService.InputBegan:Connect(function(input, processed)

    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.RightControl then
        SetWindowVisible(not Config.WindowVisible)
    end
end)

--//========================================================//--
--// STATUS LOOP
--//========================================================//--

task.spawn(function()

    while State.Alive do

        task.wait(0.25)

        FishCounter.Text =
            "🐟  " .. tostring(State.FishCaught)

        SessionStatus.Text =
            "Status: " .. tostring(State.Status)

        local upper = string.upper(tostring(State.Status))

        if State.Fishing then
            StatusLabel.Text = "●  FISHING"
            StatusLabel.TextColor3 =
                Color3.fromRGB(100, 180, 255)

        elseif State.Selling then
            StatusLabel.Text = "●  SELLING"
            StatusLabel.TextColor3 =
                Color3.fromRGB(110, 220, 150)

        elseif State.Buying then
            StatusLabel.Text = "●  SHOP"
            StatusLabel.TextColor3 =
                Color3.fromRGB(240, 190, 100)

        elseif State.Questing then
            StatusLabel.Text = "●  QUEST"
            StatusLabel.TextColor3 =
                Color3.fromRGB(190, 140, 255)

        elseif upper == "STOPPED" then
            StatusLabel.Text = "●  STOPPED"
            StatusLabel.TextColor3 =
                Color3.fromRGB(255, 100, 110)

        else
            StatusLabel.Text = "●  READY"
            StatusLabel.TextColor3 =
                Color3.fromRGB(110, 220, 150)
        end
    end
end)

--//========================================================//--
--// RESPAWN HANDLER
--//========================================================//--

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    if Config.AutoFish then
        State.Fishing = false
        StartFishing()
    end
end)

--//========================================================//--
--// INITIALIZE
--//========================================================//--

ShowPage("Fishing")

StartFishCounter()

task.spawn(function()
    task.wait(1)

    ScanIslands()
    ScanNPCs()
    ScanRodRemotes()
    ScanQuests()

    Notify(
        "KAIZEN HUB",
        "KAIZEN HUB V2 loaded successfully.",
        3
    )
end)

print("==========================================")
print("          KAIZEN HUB V2 LOADED")
print("          FISH IT EDITION")
print("==========================================")
