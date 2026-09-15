local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)
 
-- LocalPlayer существует только на клиенте; этот скрипт не поддерживает Script/server context.
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not playerGui then error("Solara requires a client PlayerGui") end
 
-- Forward-декларации для cross-function upvalues (см. ApplyTheme / openThemeManager)
local screenGui
local themeFabButton
local HUD = {}
local menuOpen = false
local activePointerDrag = nil
local themeDock, themeDockOpen, toggleThemeDock
local clearScreenActive, clearScreenSetState = false, nil

local runtimeAlive = true
local runtimeConnections = {}
local runtimeCleanupCallbacks = {}
local globalEnvironment

local function trackRuntimeConnection(connection)
    table.insert(runtimeConnections, connection)
    return connection
end

local function registerRuntimeCleanup(callback)
    table.insert(runtimeCleanupCallbacks, callback)
end

local function cleanupRuntime()
    if not runtimeAlive then return end
    runtimeAlive = false
    activePointerDrag = nil
    for i = #runtimeCleanupCallbacks, 1, -1 do
        pcall(runtimeCleanupCallbacks[i])
    end
    table.clear(runtimeCleanupCallbacks)
    for _, connection in ipairs(runtimeConnections) do
        if connection.Connected then connection:Disconnect() end
    end
    table.clear(runtimeConnections)
    if HUD.toasts then table.clear(HUD.toasts) end
    if screenGui and screenGui.Parent then screenGui:Destroy() end
    if globalEnvironment and globalEnvironment.__SOLARA_CLEANUP == cleanupRuntime then
        globalEnvironment.__SOLARA_CLEANUP = nil
    end
end

-- Повторная инъекция сначала корректно завершает предыдущий экземпляр.
globalEnvironment = (type(getgenv) == "function" and getgenv()) or _G
if type(globalEnvironment.__SOLARA_CLEANUP) == "function" then
    pcall(globalEnvironment.__SOLARA_CLEANUP)
end
globalEnvironment.__SOLARA_CLEANUP = cleanupRuntime

do
    local function getTargetGui()
        if type(gethui) == "function" then
            local ok, res = pcall(gethui)
            if ok and res then return res end
        end
        if type(get_hidden_gui) == "function" then
            local ok, res = pcall(get_hidden_gui)
            if ok and res then return res end
        end
        local okCore, core = pcall(function() return game:GetService("CoreGui") end)
        if okCore and core then return core end
        return playerGui
    end

    local INSTALLATION_FILE = "solara_installation.id"

    local function getOrCreateInstallationId()
        local cachedId = nil

        local hasReadFile = type(readfile) == "function"
        local hasWriteFile = type(writefile) == "function"
        local hasIsFile = type(isfile) == "function"

        if hasReadFile and (not hasIsFile or isfile(INSTALLATION_FILE)) then
            local ok, content = pcall(readfile, INSTALLATION_FILE)
            if ok and type(content) == "string" then
                local clean = string.gsub(content, "[%s\r\n]", "")
                if #clean >= 32 and #clean <= 64 and string.match(clean, "^[%w%-]+$") then
                    cachedId = clean
                end
            end
        end

        if not cachedId and type(globalEnvironment._SOLARA_INSTALLATION_ID) == "string" then
            cachedId = globalEnvironment._SOLARA_INSTALLATION_ID
        end

        if not cachedId then
            local newId = nil
            local okGuid, guid = pcall(function()
                return string.lower(HttpService:GenerateGUID(false))
            end)
            if okGuid and guid and #guid > 0 then
                newId = guid
            else
                local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
                newId = string.gsub(template, "[xy]", function(c)
                    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
                    return string.format("%x", v)
                end)
            end
            cachedId = newId

            if hasWriteFile then
                pcall(writefile, INSTALLATION_FILE, cachedId)
            end
        end

        globalEnvironment._SOLARA_INSTALLATION_ID = cachedId
        return cachedId
    end

    local function getEndpointUrl(endpoint)
        local base = string.gsub(HUD.Telemetry.Config.ApiBaseUrl or "", "/+$", "")
        local path = string.gsub(endpoint or "", "^/+", "")
        return base .. "/" .. path
    end

    local function sendHttpRequest(options)
        local reqFn = (type(request) == "function" and request)
            or (type(http_request) == "function" and http_request)
            or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
            or (type(http) == "table" and type(http.request) == "function" and http.request)

        if reqFn then
            return pcall(reqFn, {
                Url = options.Url,
                Method = options.Method or "GET",
                Headers = options.Headers or {},
                Body = options.Body,
            })
        elseif HttpService and type(HttpService.RequestAsync) == "function" then
            return pcall(function()
                return HttpService:RequestAsync({
                    Url = options.Url,
                    Method = options.Method or "GET",
                    Headers = options.Headers or {},
                    Body = options.Body,
                })
            end)
        end
        return false, "No supported HTTP client found in this environment"
    end

    local function getTelemetryHeaders()
        local key = HUD.Telemetry.Config.PublishableKey or HUD.Telemetry.Config.AnonKey or ""
        return {
            ["Content-Type"] = "application/json",
            ["apikey"] = key,
            ["Authorization"] = "Bearer " .. key,
        }
    end

    HUD.Telemetry = {
        Config = {
            Enabled = false, -- 中文离线版：关闭遥测、会话心跳和远程封禁
            ApiBaseUrl = "",
            PublishableKey = "sb_publishable_8FSsRg-XrTE0ATqDyblCng_WbqgO5SX",
            AnonKey = "sb_publishable_8FSsRg-XrTE0ATqDyblCng_WbqgO5SX",
            HeartbeatInterval = 60,
            ClientVersion = "2.1.0",
        },
        CurrentSessionId = nil,
        HeartbeatActive = false,
    }

    function HUD.Telemetry.ShowBannedScreen(customMessage)
        local target = getTargetGui()
        if not target then return end

        local oldNotice = target:FindFirstChild("SolaraBanNotice")
        if oldNotice then oldNotice:Destroy() end

        local banGui = Instance.new("ScreenGui")
        banGui.Name = "SolaraBanNotice"
        banGui.ResetOnSpawn = false
        banGui.IgnoreGuiInset = true
        banGui.DisplayOrder = 999999
        banGui.Parent = target

        local backdrop = Instance.new("Frame")
        backdrop.Name = "Backdrop"
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundColor3 = Color3.fromRGB(6, 6, 9)
        backdrop.BackgroundTransparency = 0.25
        backdrop.BorderSizePixel = 0
        backdrop.Parent = banGui

        local modal = Instance.new("Frame")
        modal.Name = "BanModal"
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.fromScale(0.5, 0.5)
        modal.Size = UDim2.fromOffset(420, 240)
        modal.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        modal.BorderSizePixel = 0
        modal.Parent = backdrop

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = modal

        local modalStroke = Instance.new("UIStroke")
        modalStroke.Color = Color3.fromRGB(239, 68, 68)
        modalStroke.Transparency = 0.4
        modalStroke.Thickness = 1.2
        modalStroke.Parent = modal

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.fromOffset(40, 40)
        icon.Position = UDim2.new(0.5, -20, 0, 22)
        icon.BackgroundTransparency = 1
        icon.Text = "⛔"
        icon.TextSize = 32
        icon.Parent = modal

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 22)
        title.Position = UDim2.new(0, 20, 0, 68)
        title.BackgroundTransparency = 1
        title.Text = "访问已被阻止"
        title.TextColor3 = Color3.fromRGB(248, 113, 113)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.Parent = modal

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -40, 0, 50)
        text.Position = UDim2.new(0, 20, 0, 96)
        text.BackgroundTransparency = 1
        text.Text = customMessage or "Вы забанены!\nОбращайтесь за помощью в Telegram"
        text.TextColor3 = Color3.fromRGB(225, 225, 235)
        text.Font = Enum.Font.GothamMedium
        text.TextSize = 13
        text.TextWrapped = true
        text.Parent = modal

        local instLabel = Instance.new("TextLabel")
        instLabel.Size = UDim2.new(1, -40, 0, 16)
        instLabel.Position = UDim2.new(0, 20, 0, 150)
        instLabel.BackgroundTransparency = 1
        local currentId = getOrCreateInstallationId()
        instLabel.Text = "安装编号：" .. string.sub(tostring(currentId or "—"), 1, 18) .. "..."
        instLabel.TextColor3 = Color3.fromRGB(110, 110, 125)
        instLabel.Font = Enum.Font.Code
        instLabel.TextSize = 10
        instLabel.Parent = modal

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(1, -40, 0, 36)
        closeBtn.Position = UDim2.new(0, 20, 1, -48)
        closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 33)
        closeBtn.Text = "关闭"
        closeBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
        closeBtn.Font = Enum.Font.GothamSemibold
        closeBtn.TextSize = 12
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = modal

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = closeBtn

        closeBtn.MouseButton1Click:Connect(function()
            banGui:Destroy()
        end)
    end

    function HUD.Telemetry.StartSession()
        if not HUD.Telemetry.Config.Enabled or not runtimeAlive then
            return { allowed = true, banned = false }
        end
        if not HUD.Telemetry.Config.ApiBaseUrl or HUD.Telemetry.Config.ApiBaseUrl:find("your%-project%-ref") then
            return { allowed = true, banned = false }
        end

        local installationId = getOrCreateInstallationId()

        local payload = {
            roblox_user_id = player.UserId,
            roblox_username = player.Name,
            place_id = game.PlaceId,
            job_id = tostring(game.JobId or ""),
            game_id = tostring(game.JobId or game.GameId or ""),
            client_version = HUD.Telemetry.Config.ClientVersion,
            installation_id = installationId,
        }

        local jsonBody = ""
        local okEncode, resEncode = pcall(function()
            return HttpService:JSONEncode(payload)
        end)
        if not okEncode then
            return { allowed = true, banned = false }
        end
        jsonBody = resEncode

        local url = getEndpointUrl("session-start")
        local okReq, response = sendHttpRequest({
            Url = url,
            Method = "POST",
            Headers = getTelemetryHeaders(),
            Body = jsonBody,
        })

        if okReq and type(response) == "table" and response.Body then
            local okDecode, decoded = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if okDecode and type(decoded) == "table" then
                if response.StatusCode == 403 or decoded.banned == true or decoded.allowed == false then
                    return {
                        allowed = false,
                        banned = true,
                        message = decoded.message or "Вы забанены!\nОбращайтесь за помощью в Telegram",
                    }
                end

                if decoded.session_id then
                    HUD.Telemetry.CurrentSessionId = decoded.session_id
                end
                return {
                    allowed = true,
                    banned = false,
                    session_id = decoded.session_id,
                }
            end
        end

        return { allowed = true, banned = false, network_error = true }
    end

    function HUD.Telemetry.SendHeartbeat()
        if not HUD.Telemetry.Config.Enabled or not runtimeAlive then return end
        if not HUD.Telemetry.Config.ApiBaseUrl or HUD.Telemetry.Config.ApiBaseUrl:find("your%-project%-ref") then
            return
        end

        local installationId = getOrCreateInstallationId()

        local payload = {
            roblox_user_id = player.UserId,
            session_id = HUD.Telemetry.CurrentSessionId,
            place_id = game.PlaceId,
            job_id = tostring(game.JobId or ""),
            game_id = tostring(game.JobId or game.GameId or ""),
            installation_id = installationId,
        }

        local jsonBody = ""
        local okEncode, resEncode = pcall(function()
            return HttpService:JSONEncode(payload)
        end)
        if not okEncode then return end
        jsonBody = resEncode

        local url = getEndpointUrl("session-heartbeat")
        local okReq, response = sendHttpRequest({
            Url = url,
            Method = "POST",
            Headers = getTelemetryHeaders(),
            Body = jsonBody,
        })

        if okReq and type(response) == "table" and response.Body then
            local okDecode, decoded = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if okDecode and type(decoded) == "table" then
                if response.StatusCode == 403 or decoded.banned == true or decoded.allowed == false then
                    HUD.Telemetry.HeartbeatActive = false
                    local banMsg = decoded.message or "Вы забанены!\nОбращайтесь за помощью в Telegram"
                    cleanupRuntime()
                    HUD.Telemetry.ShowBannedScreen(banMsg)
                end
            end
        end
    end

    function HUD.Telemetry.StartHeartbeatLoop()
        if not HUD.Telemetry.Config.Enabled then return end
        if HUD.Telemetry.HeartbeatActive then return end
        HUD.Telemetry.HeartbeatActive = true

        task.spawn(function()
            while runtimeAlive and HUD.Telemetry.HeartbeatActive do
                task.wait(HUD.Telemetry.Config.HeartbeatInterval or 60)
                if not runtimeAlive or not HUD.Telemetry.HeartbeatActive then break end
                pcall(HUD.Telemetry.SendHeartbeat)
            end
        end)
    end

    registerRuntimeCleanup(function()
        HUD.Telemetry.HeartbeatActive = false
    end)
end
local shimmerGradients = {}
local shimmerPos = -1.5
 
----------------------------------------------------------------
-- Настройки цветов и категорий
----------------------------------------------------------------
 
local TOGGLE_KEY = Enum.KeyCode.R
local MENU_TITLE = "SOLARA"

-- Обложки сопоставлены с присланными CDN-ссылками через Roblox Thumbnails API.
-- GameIcon использует universeId. Для своей картинки можно поставить rbxassetid://123456789.
HUD.gameChoices = {
    -- https://tr.rbxcdn.com/180DAY-68c92fc62a8753793f7963e146b5197f/256/256/Image/Webp/noFilter
    { id = "strongest_battlegrounds", name = "The Strongest Battlegrounds", image = "rbxthumb://type=GameIcon&id=3808081382&w=150&h=150", initials = "TSB", accent = Color3.fromRGB(228, 228, 235) },
    -- https://tr.rbxcdn.com/180DAY-2a47aa0d515687a3327888028bb96216/256/256/Image/Webp/noFilter
    { id = "conquer_world_ww2", name = "Conquer The World WW2", image = "rbxthumb://type=GameIcon&id=4983034985&w=150&h=150", initials = "WW2", accent = Color3.fromRGB(228, 228, 235) },
    -- https://tr.rbxcdn.com/180DAY-77fe21f900b63177ef2bb9dbaf91341a/256/256/Image/Webp/noFilter
    { id = "midnight_chasers", name = "Midnight Chasers", image = "rbxthumb://type=GameIcon&id=4793836769&w=150&h=150", initials = "MC", accent = Color3.fromRGB(228, 228, 235) },
    { id = "universal", name = "Universal", image = "", initials = "UNI", accent = Color3.fromRGB(228, 228, 235) },
}

function HUD.isTsbGame()
    if HUD.selectedGame and HUD.selectedGame.id == "strongest_battlegrounds" then return true end
    local pId = game.PlaceId
    local gId = game.GameId
    if pId == 10449761463 or gId == 3808081382 then return true end
    if workspace:FindFirstChild("Live") and workspace:FindFirstChild("Map") then return true end
    return false
end

function HUD.isWw2Game()
    if HUD.selectedGame and HUD.selectedGame.id == "conquer_world_ww2" then return true end
    local gId = game.GameId
    if gId == 4983034985 then return true end
    local rs = game:GetService("ReplicatedStorage")
    if workspace:FindFirstChild("Map") and rs:FindFirstChild("Cities") then return true end
    return false
end
HUD.selectedGame = nil
HUD.gameSelectionPending = false
HUD.layout = { width = 980, height = 620 }
HUD.activeCategory = "COMBAT"
HUD.categoryViews = {}
 
local MODULE_ZH = {
    ["Auto Combo"] = "自动连招",
    ["HvH"] = "对抗模式",
    ["Target Strafe"] = "环绕目标",
    ["Hitbox Expander"] = "扩大碰撞箱",
    ["Kill Player"] = "攻击玩家",
    ["Instant Dash"] = "瞬间冲刺",
    ["No Block Slow"] = "格挡减速移除",
    ["Desync Glitch"] = "不同步移动",
    ["Fast M1"] = "快速普攻",
    ["Speed"] = "车辆速度",
    ["Brakes"] = "车辆制动",
    ["Fly"] = "飞行",
    ["Handling"] = "车辆操控",
    ["Teleport to"] = "车辆传送",
    ["Smart Movement"] = "智能移动",
    ["Auto Army"] = "自动征兵",
    ["Auto Factory"] = "自动建厂",
    ["Auto Production"] = "自动生产",
    ["Auto Government"] = "自动政府",
    ["Auto Diplomacy"] = "自动外交",
    ["Auto Missiles"] = "自动导弹",
    ["Auto Naval"] = "自动海军",
    ["Auto Air Force"] = "自动空军",
    ["Auto Silo"] = "自动导弹井",
    ["Auto Research"] = "自动科研",
    ["Bunny Hop"] = "自动连跳",
    ["Infinity Jump"] = "无限跳跃",
    ["Custom Speed"] = "自定义速度",
    ["HUD"] = "状态面板",
    ["Skybox"] = "天空盒",
    ["Better FPS"] = "帧率优化",
    ["RTX Graphics"] = "RTX 画质",
    ["Weather FX"] = "天气特效",
    ["Glow Player"] = "玩家发光",
    ["Shader Hat"] = "光效帽子",
    ["Crosshair"] = "准星",
    ["Clear Screen"] = "清爽屏幕",
    ["Aspect Ratio"] = "画面比例",
    ["Hit Color"] = "命中颜色",
    ["Fullbright"] = "全亮",
    ["Ambient Color"] = "环境颜色",
    ["Cosmetics"] = "外观装饰",
    ["Glow ESP"] = "发光透视",
    ["Target ESP"] = "目标透视",
    ["Teleport"] = "传送",
    ["Pull Player"] = "拉取玩家",
    ["Fling"] = "甩飞",
    ["Anti-Fling"] = "防甩飞",
    ["Escape"] = "脱离",
    ["Admin Panel"] = "管理面板",
}

local CATEGORIES = {
    { name = "COMBAT",   icon = "⚔", modules = { "Auto Combo", "HvH", "Target Strafe", "Hitbox Expander", "Kill Player", "Instant Dash", "No Block Slow", "Desync Glitch", "Fast M1", "Speed", "Brakes", "Fly", "Handling", "Teleport to", "Smart Movement", "Auto Army", "Auto Factory", "Auto Production", "Auto Government", "Auto Diplomacy", "Auto Missiles", "Auto Naval", "Auto Air Force", "Auto Silo", "Auto Research" } },
    { name = "MOVEMENT", icon = "⚡", modules = { "Bunny Hop", "Infinity Jump", "Custom Speed", "Fly" } },
    { name = "VISUALS",  icon = "◆", modules = { "HUD", "Skybox", "Better FPS", "RTX Graphics", "Weather FX", "Glow Player", "Shader Hat", "Crosshair", "Clear Screen", "Aspect Ratio", "Hit Color", "Fullbright", "Ambient Color", "Cosmetics" } },
    { name = "PLAYER",   icon = "♟", modules = { "Glow ESP", "Target ESP", "Teleport", "Pull Player" } },
    { name = "MISC",     icon = "⚙", modules = { "Fling", "Anti-Fling", "Escape", "Admin Panel" } },
}
 
local COLORS = {
    panel      = Color3.fromRGB(9, 9, 11),
    panelAlt   = Color3.fromRGB(18, 18, 21),
    header     = Color3.fromRGB(250, 250, 252),
    text       = Color3.fromRGB(231, 231, 235),
    textDim    = Color3.fromRGB(149, 149, 159),
    stroke     = Color3.fromRGB(39, 39, 45),
    accent     = Color3.fromRGB(255, 255, 255), -- Кристально белый акцент
    off        = Color3.fromRGB(15, 15, 18),
    hover      = Color3.fromRGB(25, 25, 30),
}

local CURRENT_LANG = "ZH" -- 中文版

-- Простая система локализации
local LANGS = {
    ZH = {
        VALUE = "数值", SEARCH_PLACEHOLDER = "搜索功能", EXTRA_FUNC = "附加功能",
        KEYBIND = "快捷键", LANGUAGE = "语言", HUD_FPS = "帧率", HUD_PING = "延迟",
        HUD_TIME = "时间", HUD_PLACE = "游戏", HUD_NICK = "昵称", HUD_MODULES = "已启用",
        HUD_SETTINGS = "HUD 设置",
    },
    RU = {
        VALUE = "Значение",
            SEARCH_PLACEHOLDER = "Поиск модулей",
        EXTRA_FUNC = "Доп. функция",
        KEYBIND = "Бинд клавиши",
        LANGUAGE = "Язык",
        HUD_FPS = "ФПС",
        HUD_PING = "Пинг",
        HUD_TIME = "Время",
        HUD_PLACE = "Плейс",
        HUD_NICK = "Ник",
        HUD_MODULES = "Активно",
        HUD_SETTINGS = "Настройки HUD",
    },
    EN = {
        VALUE = "Value",
        SEARCH_PLACEHOLDER = "Search modules",
        EXTRA_FUNC = "Extra function",
        KEYBIND = "Keybind",
        LANGUAGE = "Language",
        HUD_FPS = "FPS",
        HUD_PING = "Ping",
        HUD_TIME = "Time",
        HUD_PLACE = "Place",
        HUD_NICK = "Nick",
        HUD_MODULES = "Active",
        HUD_SETTINGS = "HUD Settings",
    },
    NL = {
        VALUE = "Waarde",
        SEARCH_PLACEHOLDER = "Zoek modules",
        EXTRA_FUNC = "Extra functie",
        KEYBIND = "Toetsbinding",
        LANGUAGE = "Taal",
        HUD_FPS = "FPS",
        HUD_PING = "Ping",
        HUD_TIME = "Tijd",
        HUD_PLACE = "Plaats",
        HUD_NICK = "Nick",
        HUD_MODULES = "Actief",
        HUD_SETTINGS = "HUD-instellingen",
    }
}

local function translate(key)
    if LANGS[CURRENT_LANG] and LANGS[CURRENT_LANG][key] then
        return LANGS[CURRENT_LANG][key]
    end
    return key
end

----------------------------------------------------------------
-- THEME SYSTEM (2026 Premium Business UI)
----------------------------------------------------------------
 
local THEMES = {
    DefaultBlack = {
        label = "Solara Mono",
        desc  = "Мягкий белый, глубокий чёрный и нейтральный графит.",
        preview = { Color3.fromRGB(9,9,11), Color3.fromRGB(18,18,21), Color3.fromRGB(255,255,255), Color3.fromRGB(39,39,45), Color3.fromRGB(149,149,159) },
        panel = Color3.fromRGB(9, 9, 11), panelAlt = Color3.fromRGB(18, 18, 21),
        header = Color3.fromRGB(250, 250, 252), text = Color3.fromRGB(231, 231, 235),
        textDim = Color3.fromRGB(149, 149, 159), stroke = Color3.fromRGB(39, 39, 45),
        accent = Color3.fromRGB(255, 255, 255), off = Color3.fromRGB(15, 15, 18),
        hover = Color3.fromRGB(25, 25, 30),
        ambient = Color3.fromRGB(24, 25, 30), hit = Color3.fromRGB(255, 255, 255),
        hitEnd = Color3.fromRGB(180, 190, 205), glow = Color3.fromRGB(220, 230, 250),
        cosmetics = Color3.fromRGB(255, 255, 255),
    },
    Midnight = {
        label = "Midnight",
        desc  = "Глубокая полуночная синева с холодным акцентом.",
        preview = { Color3.fromRGB(12,16,32), Color3.fromRGB(20,26,48), Color3.fromRGB(200,214,255), Color3.fromRGB(38,48,82), Color3.fromRGB(120,138,190) },
        panel = Color3.fromRGB(12, 16, 32), panelAlt = Color3.fromRGB(20, 26, 48),
        header = Color3.fromRGB(200, 214, 255), text = Color3.fromRGB(210, 220, 245),
        textDim = Color3.fromRGB(120, 138, 180), stroke = Color3.fromRGB(38, 48, 82),
        accent = Color3.fromRGB(120, 156, 255), off = Color3.fromRGB(18, 24, 44),
        hover = Color3.fromRGB(30, 40, 70),
        ambient = Color3.fromRGB(16, 26, 56), hit = Color3.fromRGB(120, 185, 255),
        hitEnd = Color3.fromRGB(0, 220, 255), glow = Color3.fromRGB(0, 230, 255),
        cosmetics = Color3.fromRGB(120, 180, 255),
    },
    Obsidian = {
        label = "Obsidian",
        desc  = "Чёрный обсидиан с холодными фиолетовыми бликами.",
        preview = { Color3.fromRGB(14,12,18), Color3.fromRGB(22,20,28), Color3.fromRGB(240,230,255), Color3.fromRGB(42,38,54), Color3.fromRGB(150,140,170) },
        panel = Color3.fromRGB(14, 12, 18), panelAlt = Color3.fromRGB(22, 20, 28),
        header = Color3.fromRGB(240, 230, 255), text = Color3.fromRGB(235, 228, 248),
        textDim = Color3.fromRGB(150, 140, 172), stroke = Color3.fromRGB(42, 38, 54),
        accent = Color3.fromRGB(168, 130, 255), off = Color3.fromRGB(20, 18, 26),
        hover = Color3.fromRGB(34, 30, 44),
        ambient = Color3.fromRGB(28, 20, 38), hit = Color3.fromRGB(180, 130, 255),
        hitEnd = Color3.fromRGB(130, 90, 240), glow = Color3.fromRGB(168, 130, 255),
        cosmetics = Color3.fromRGB(168, 130, 255),
    },
    Graphite = {
        label = "Graphite",
        desc  = "Нейтральный графит для долгой работы.",
        preview = { Color3.fromRGB(28,30,34), Color3.fromRGB(40,42,48), Color3.fromRGB(245,246,248), Color3.fromRGB(60,62,68), Color3.fromRGB(150,152,158) },
        panel = Color3.fromRGB(28, 30, 34), panelAlt = Color3.fromRGB(40, 42, 48),
        header = Color3.fromRGB(245, 246, 248), text = Color3.fromRGB(238, 240, 244),
        textDim = Color3.fromRGB(150, 152, 162), stroke = Color3.fromRGB(60, 62, 70),
        accent = Color3.fromRGB(190, 200, 210), off = Color3.fromRGB(34, 36, 40),
        hover = Color3.fromRGB(48, 50, 56),
        ambient = Color3.fromRGB(30, 32, 36), hit = Color3.fromRGB(200, 210, 220),
        hitEnd = Color3.fromRGB(140, 150, 165), glow = Color3.fromRGB(190, 200, 210),
        cosmetics = Color3.fromRGB(190, 200, 210),
    },
    BusinessBlue = {
        label = "Ocean Blue",
        desc  = "Свежий океанический аква-синий в стиле Linear.",
        preview = { Color3.fromRGB(13,20,38), Color3.fromRGB(20,32,56), Color3.fromRGB(224,234,255), Color3.fromRGB(36,54,96), Color3.fromRGB(130,150,200) },
        panel = Color3.fromRGB(13, 20, 38), panelAlt = Color3.fromRGB(20, 32, 56),
        header = Color3.fromRGB(224, 234, 255), text = Color3.fromRGB(222, 232, 252),
        textDim = Color3.fromRGB(130, 150, 196), stroke = Color3.fromRGB(36, 54, 96),
        accent = Color3.fromRGB(64, 120, 255), off = Color3.fromRGB(18, 28, 50),
        hover = Color3.fromRGB(30, 46, 80),
        ambient = Color3.fromRGB(10, 36, 58), hit = Color3.fromRGB(0, 210, 255),
        hitEnd = Color3.fromRGB(64, 140, 255), glow = Color3.fromRGB(50, 235, 255),
        cosmetics = Color3.fromRGB(40, 200, 255),
    },
    Emerald = {
        label = "Emerald",
        desc  = "Спокойный изумрудный деловой тон.",
        preview = { Color3.fromRGB(8,20,16), Color3.fromRGB(14,30,24), Color3.fromRGB(222,255,238), Color3.fromRGB(28,56,44), Color3.fromRGB(110,180,140) },
        panel = Color3.fromRGB(8, 20, 16), panelAlt = Color3.fromRGB(14, 30, 24),
        header = Color3.fromRGB(222, 255, 238), text = Color3.fromRGB(220, 246, 232),
        textDim = Color3.fromRGB(120, 168, 140), stroke = Color3.fromRGB(28, 56, 44),
        accent = Color3.fromRGB(46, 200, 130), off = Color3.fromRGB(12, 26, 20),
        hover = Color3.fromRGB(22, 44, 34),
        ambient = Color3.fromRGB(10, 42, 28), hit = Color3.fromRGB(46, 220, 130),
        hitEnd = Color3.fromRGB(130, 255, 120), glow = Color3.fromRGB(40, 255, 180),
        cosmetics = Color3.fromRGB(46, 200, 130),
    },
    RoyalPurple = {
        label = "Royal Purple",
        desc  = "Королевский фиолетовый с благородным акцентом.",
        preview = { Color3.fromRGB(20,14,28), Color3.fromRGB(30,22,42), Color3.fromRGB(240,228,255), Color3.fromRGB(52,40,72), Color3.fromRGB(160,134,200) },
        panel = Color3.fromRGB(20, 14, 28), panelAlt = Color3.fromRGB(30, 22, 42),
        header = Color3.fromRGB(240, 228, 255), text = Color3.fromRGB(232, 222, 248),
        textDim = Color3.fromRGB(160, 134, 196), stroke = Color3.fromRGB(52, 40, 72),
        accent = Color3.fromRGB(160, 110, 255), off = Color3.fromRGB(26, 18, 36),
        hover = Color3.fromRGB(40, 28, 56),
        ambient = Color3.fromRGB(42, 16, 68), hit = Color3.fromRGB(180, 80, 255),
        hitEnd = Color3.fromRGB(255, 110, 220), glow = Color3.fromRGB(200, 120, 255),
        cosmetics = Color3.fromRGB(160, 110, 255),
    },
    Crimson = {
        label = "Crimson",
        desc  = "Тёмно-красный премиальный акцент.",
        preview = { Color3.fromRGB(26,12,14), Color3.fromRGB(38,18,20), Color3.fromRGB(255,224,226), Color3.fromRGB(70,30,34), Color3.fromRGB(200,120,128) },
        panel = Color3.fromRGB(26, 12, 14), panelAlt = Color3.fromRGB(38, 18, 20),
        header = Color3.fromRGB(255, 224, 226), text = Color3.fromRGB(248, 226, 228),
        textDim = Color3.fromRGB(190, 130, 138), stroke = Color3.fromRGB(70, 30, 34),
        accent = Color3.fromRGB(255, 70, 88), off = Color3.fromRGB(32, 14, 16),
        hover = Color3.fromRGB(52, 22, 26),
        ambient = Color3.fromRGB(58, 14, 20), hit = Color3.fromRGB(255, 45, 55),
        hitEnd = Color3.fromRGB(255, 120, 40), glow = Color3.fromRGB(255, 60, 75),
        cosmetics = Color3.fromRGB(255, 60, 80),
    },
    Sakura = {
        label = "Sakura",
        desc  = "Нежно-розовый японский акцент с лавандовыми бликами.",
        preview = { Color3.fromRGB(28,14,24), Color3.fromRGB(40,20,34), Color3.fromRGB(255,225,242), Color3.fromRGB(68,32,58), Color3.fromRGB(210,140,185) },
        panel = Color3.fromRGB(28, 14, 24), panelAlt = Color3.fromRGB(40, 20, 34),
        header = Color3.fromRGB(255, 225, 242), text = Color3.fromRGB(250, 230, 244),
        textDim = Color3.fromRGB(190, 140, 175), stroke = Color3.fromRGB(68, 32, 58),
        accent = Color3.fromRGB(255, 125, 185), off = Color3.fromRGB(32, 16, 26),
        hover = Color3.fromRGB(50, 24, 42),
        ambient = Color3.fromRGB(55, 20, 40), hit = Color3.fromRGB(255, 120, 180),
        hitEnd = Color3.fromRGB(255, 175, 220), glow = Color3.fromRGB(255, 140, 210),
        cosmetics = Color3.fromRGB(255, 150, 210),
    },
    ArcticWhite = {
        label = "Arctic White",
        desc  = "Светлый минимализм в стиле Apple / Notion.",
        preview = { Color3.fromRGB(244,246,248), Color3.fromRGB(232,236,240), Color3.fromRGB(24,28,34), Color3.fromRGB(210,214,220), Color3.fromRGB(110,116,128) },
        panel = Color3.fromRGB(244, 246, 248), panelAlt = Color3.fromRGB(232, 236, 240),
        header = Color3.fromRGB(24, 28, 34), text = Color3.fromRGB(40, 46, 54),
        textDim = Color3.fromRGB(120, 128, 140), stroke = Color3.fromRGB(210, 214, 222),
        accent = Color3.fromRGB(40, 90, 235), off = Color3.fromRGB(226, 230, 236),
        hover = Color3.fromRGB(236, 240, 244),
        ambient = Color3.fromRGB(36, 40, 50), hit = Color3.fromRGB(255, 255, 255),
        hitEnd = Color3.fromRGB(180, 215, 255), glow = Color3.fromRGB(215, 235, 255),
        cosmetics = Color3.fromRGB(235, 240, 255),
    },
    GoldExecutive = {
        label = "Gold Executive",
        desc  = "Чёрный премиум с золотым акцентом executive.",
        preview = { Color3.fromRGB(16,14,10), Color3.fromRGB(26,22,16), Color3.fromRGB(255,248,228), Color3.fromRGB(58,48,28), Color3.fromRGB(200,170,110) },
        panel = Color3.fromRGB(16, 14, 10), panelAlt = Color3.fromRGB(26, 22, 16),
        header = Color3.fromRGB(255, 248, 228), text = Color3.fromRGB(248, 240, 222),
        textDim = Color3.fromRGB(180, 162, 120), stroke = Color3.fromRGB(58, 48, 28),
        accent = Color3.fromRGB(212, 175, 80), off = Color3.fromRGB(22, 18, 12),
        hover = Color3.fromRGB(38, 32, 20),
        ambient = Color3.fromRGB(48, 38, 16), hit = Color3.fromRGB(255, 215, 80),
        hitEnd = Color3.fromRGB(255, 160, 40), glow = Color3.fromRGB(255, 200, 60),
        cosmetics = Color3.fromRGB(212, 175, 80),
    },
}
 
-- Порядок тем для отображения в Theme Manager
local THEME_ORDER = {
    "DefaultBlack", "Midnight", "Obsidian", "Graphite", "BusinessBlue",
    "Emerald", "RoyalPurple", "Crimson", "Sakura", "ArcticWhite", "GoldExecutive",
}
 
local currentTheme = "DefaultBlack"
 
----------------------------------------------------------------
-- Утилиты
----------------------------------------------------------------
 
-- Theme Bindings (объявлены ДО create() — create() их использует)
-- Слабые ключи не удерживают уничтоженные UI-объекты в памяти.
local _themeBindings = setmetatable({}, { __mode = "k" })
local function bindTheme(inst, prop, keyFn)
    if not inst then return nil end
    if not _themeBindings[inst] then _themeBindings[inst] = {} end
    _themeBindings[inst][prop] = keyFn
    return inst
end

-- Одинаковые Color3 встречаются у нескольких токенов темы. Порядок pairs()
-- нестабилен, поэтому используем явный приоритет для предсказуемого auto-bind.
local THEME_BIND_PRIORITY = {
    BackgroundColor3 = { "panel", "panelAlt", "off", "hover", "accent", "stroke", "header", "text", "textDim" },
    TextColor3 = { "textDim", "text", "header", "accent", "panel", "panelAlt", "off", "hover", "stroke" },
    ImageColor3 = { "accent", "text", "header", "textDim", "panel", "panelAlt", "off", "hover", "stroke" },
}

local function autoBindThemeColor(inst, prop, value)
    if value == nil then return end
    for _, key in ipairs(THEME_BIND_PRIORITY[prop]) do
        if value == COLORS[key] then
            bindTheme(inst, prop, key)
            return
        end
    end
end
 
local function create(className, props)
    local okInst, inst = pcall(function() return Instance.new(className) end)
    if not okInst or not inst then
        inst = Instance.new("Frame")
    end
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    local doAutoBind = props.themeBind ~= false
    for prop, value in pairs(props) do
        if prop ~= "themeBind" then
            pcall(function() inst[prop] = value end)
        end
    end
    -- Авто-регистрация цветов в Theme Engine.
    -- Ищем значение цвета, которое совпадает с одним из ключей COLORS,
    -- и связываем его через bindTheme (сравнение по == для Color3 корректно
    -- именно при регистрации — мы кладём прямую ссылку на сам объект цвета).
    if doAutoBind and className ~= "UICorner" then
        autoBindThemeColor(inst, "BackgroundColor3", props.BackgroundColor3)
        autoBindThemeColor(inst, "TextColor3", props.TextColor3)
        autoBindThemeColor(inst, "ImageColor3", props.ImageColor3)
    end
    return inst
end
 
local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end
 
local function stroke(parent, color, thickness)
    local resolvedColor = color or COLORS.stroke
    local s = create("UIStroke", {
        Color = resolvedColor,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    if color == nil or resolvedColor == COLORS.stroke then
        bindTheme(s, "Color", "stroke")
    elseif resolvedColor == COLORS.accent then
        bindTheme(s, "Color", "accent")
    end
    return s
end

local animationsEnabled = true

local function tween(inst, props, time, style, dir)
    if not inst then
        local dummyCompleted = {}
        function dummyCompleted:Connect(fn) if fn then task.defer(fn) end end
        return { Completed = dummyCompleted }
    end
    local realTime = animationsEnabled and (time or 0.15) or 0.001
    local tInfo = TweenInfo.new(realTime, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)

    if props.GroupTransparency ~= nil then
        local hasGroupTransp = pcall(function() return inst.GroupTransparency end)
        if not hasGroupTransp then
            -- Не подменяем групповую прозрачность прозрачностью фона Frame:
            -- fade-in иначе превращает прозрачный контейнер в серую плашку.
            props.GroupTransparency = nil
        end
    end

    local ok, t = pcall(function() return TweenService:Create(inst, tInfo, props) end)
    if ok and t then
        t:Play()
        return t
    end
    local dummyCompleted = {}
    function dummyCompleted:Connect(fn) if fn then task.defer(fn) end end
    return { Completed = dummyCompleted }
end

-- Единый dispatcher для drag-жестов. Панели могут создаваться и уничтожаться
-- многократно, но глобальные InputChanged/InputEnded подключаются только один раз.
activePointerDrag = nil

local function beginPointerDrag(owner, input, onMove)
    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then return end
    activePointerDrag = {
        owner = owner,
        touchInput = inputType == Enum.UserInputType.Touch and input or nil,
        onMove = onMove,
    }
    onMove(input.Position)
end

local function bindPointerDrag(owner, onMove)
    return owner.InputBegan:Connect(function(input)
        beginPointerDrag(owner, input, onMove)
    end)
end

trackRuntimeConnection(UserInputService.InputChanged:Connect(function(input)
    local drag = activePointerDrag
    if not drag then return end
    if not drag.owner.Parent then
        activePointerDrag = nil
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == drag.touchInput then
        drag.onMove(input.Position)
    end
end))

trackRuntimeConnection(UserInputService.InputEnded:Connect(function(input)
    local drag = activePointerDrag
    if not drag then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.touchInput then
        activePointerDrag = nil
    end
end))

-- =========================================================================
-- SPOTYHUB STATE VARIABLES & HELPERS
-- =========================================================================
-- Единое хранилище gameplay-настроек также не расходует по одному регистру
-- главного chunk на каждое значение (у Luau жёсткий лимит в 200 local).
local gameplayConfig = {
    hvhTarget = "", strafeTarget = "", killTarget = "", autoComboTarget = "",
    tsbDashSpeed = 180, tsbDashKey = Enum.KeyCode.Z, tsbDashEnabled = false,
    tsbNoBlockSlow = false, tsbDesync = false, tsbFastM1 = false, tsbAttackDelay = 100,
    noBlockSlowConn = nil, tsbFastM1Conn = nil,
    strafeRadius = 8, strafeSpeed = 180, hitboxSize = 6,
    bhopSpeed = 50, bhopJumpHeight = 50, customSpeed = 50, flySpeed = 60,
    vehicleSpeed = 25, vehicleBrakes = 25, vehicleHandling = 25, vehicleFlySpeed = 60,
    vehicleTpTarget = "",
    vehicleSpeedEnabled = false, vehicleBrakesEnabled = false, vehicleHandlingEnabled = false, vehicleFlyEnabled = false,
    targetEspName = "", targetEspSize = 3, targetEspSpin = 2,
    teleportTarget = "", pullTarget = "", flingTarget = "",
    escapeHealth = 25, escapeDistance = 80,
    cosmeticScale = 1, cosmeticSpeed = 1, cosmeticHeight = 20,
    crosshairSize = 16, crosshairThickness = 2, crosshairGap = 3, crosshairOpacity = 0,
    shaderHatScale = 1, shaderHatHeight = 0, shaderHatThickness = 1,
    rtxIntensity = 1, rtxCinematic = false,
}

gameplayConfig.autoCombo = {
    Config = {
        M1Delay = 0.10,
        JumpM1Delay = 0.20,
        SecondJumpM1Delay = 0.10,
        Ability2Delay = 0.40,
        AfterAbility2Delay = 1.00,
        DashBackDistance = 3,
        DashWait = 0.22,
        Second4Distance = 6,
        Ability4Timeout = 3.0,
        KeyHold = 0.04,
        M1Hold = 0.02,
        Debug = false,
    },
    State = {
        running = false,
        thread = nil,
        rowSetState = nil,
        panelRefresh = nil,
    },
    start = nil,
    stop = nil,
}

local lastSyntheticClick = 0
local function clickM1()
    local now = os.clock()
    if now - lastSyntheticClick < 0.08 then return end
    lastSyntheticClick = now
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

local function getClosestPlayer()
    local closestCharacter, closestDist = nil, math.huge
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local d = (myRoot.Position - root.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closestCharacter = p.Character
                end
            end
        end
    end
    return closestCharacter
end

local function getSelectedTarget(playerName)
    if not playerName or playerName == "" then return nil end
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer or targetPlayer == player then return nil end
    local character = targetPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then return nil end
    return character
end

-- ═══════════════════════════════════════════════════════════════
-- THE STRONGEST BATTLEGROUNDS (TSB) - LUNA ENGINE INTEGRATION
-- ═══════════════════════════════════════════════════════════════
local function executeTsbDash()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local lookVec = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
    local moveDist = (gameplayConfig.tsbDashSpeed or 180) / 10
    char:TranslateBy(lookVec * moveDist)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function() root.AssemblyLinearVelocity = lookVec * 25 end)
    end
end

local function setTsbNoBlockSlow(enabled)
    gameplayConfig.tsbNoBlockSlow = enabled
    if _G.NoBlockSlowConn then
        pcall(function() _G.NoBlockSlowConn:Disconnect() end)
        _G.NoBlockSlowConn = nil
    end
    if gameplayConfig.noBlockSlowConn then
        pcall(function() gameplayConfig.noBlockSlowConn:Disconnect() end)
        gameplayConfig.noBlockSlowConn = nil
    end
    if enabled then
        local function attachToChar(char)
            if not char then return end
            local conn = char.ChildAdded:Connect(function(child)
                if child.Name == "Slow" or child.Name:find("Slow") then
                    task.wait()
                    if child and child.Parent then
                        child:Destroy()
                    end
                end
            end)
            gameplayConfig.noBlockSlowConn = conn
            _G.NoBlockSlowConn = conn
            trackRuntimeConnection(conn)
        end
        attachToChar(player.Character)
        trackRuntimeConnection(player.CharacterAdded:Connect(function(newChar)
            if gameplayConfig.tsbNoBlockSlow then
                attachToChar(newChar)
            end
        end))
    end
end

local function executeTsbDesync()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char.HumanoidRootPart
    local stored = (getgenv and getgenv().StoredCFrame) or hrp.CFrame
    local targetCFrame = stored * CFrame.new(0, 0.5, 0)
    char:SetPrimaryPartCFrame(targetCFrame)
    if hum then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            task.wait()
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

local function setTsbFastM1(enabled)
    gameplayConfig.tsbFastM1 = enabled
    if gameplayConfig.tsbFastM1Conn then
        pcall(function() gameplayConfig.tsbFastM1Conn:Disconnect() end)
        gameplayConfig.tsbFastM1Conn = nil
    end
    if enabled then
        local conn = RunService.Heartbeat:Connect(function()
            if not gameplayConfig.tsbFastM1 then return end
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    local animName = track.Name:lower()
                    if animName:find("punch") or animName:find("attack") or animName:find("m1") or animName:find("swing") then
                        local delayRatio = (gameplayConfig.tsbAttackDelay or 100) / 100
                        if track.Length > 0 and track.TimePosition >= (track.Length * delayRatio) then
                            track:Stop()
                        end
                    end
                end
            end
        end)
        gameplayConfig.tsbFastM1Conn = conn
        trackRuntimeConnection(conn)
    end
end

local function SkidFling(TargetPlayer)
    if not TargetPlayer or TargetPlayer == player or TargetPlayer.Parent ~= Players then return end
    local Character = player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter or not Character or not Humanoid or not RootPart then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    if not TRootPart then return end

    local oldPos = RootPart.CFrame
    local oldFallenPartsDestroyHeight
    pcall(function()
        oldFallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
    end)

    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    local seatedWasEnabled = Humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local ok, err = pcall(function()
        local timeToWait = 2
        local startedAt = tick()
        local angle = 0
        repeat
            if not RootPart.Parent or not TRootPart.Parent or THumanoid.Health <= 0 then break end
            angle = angle + 100
            RootPart.CFrame = CFrame.new(TRootPart.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(angle), 0, 0)
            RootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            task.wait()
        until tick() - startedAt > timeToWait
    end)

    if BV.Parent then BV:Destroy() end
    if Humanoid.Parent then Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, seatedWasEnabled) end
    if RootPart.Parent then RootPart.CFrame = oldPos end
    if oldFallenPartsDestroyHeight ~= nil then
        pcall(function() workspace.FallenPartsDestroyHeight = oldFallenPartsDestroyHeight end)
    end
    if not ok then warn("Solara fling stopped safely:", err) end
end
 
----------------------------------------------------------------
-- THEME APPLICATION ENGINE
----------------------------------------------------------------
 
local activeThemeManager
local _refreshThemeCards
local refreshHudColors -- forward-декларация: обновление цвета HUD (см. ниже секцию HUD)
local _setHudBgTransparency
-- ВАЖНО: это ЕДИНСТВЕННОЕ объявление этой переменной во всём скрипте.
-- Ранее ниже (в секции HUD) было повторное `local refreshHudColors`,
-- которое затеняло (shadow) эту переменную — из-за этого все замыкания,
-- объявленные ДО той точки (ApplyTheme, ApplySavedTheme, свотчи цвета
-- в Theme Dock, сеттер _setHudBgTransparency слайдера "HUD 透明度"),
-- навсегда видели nil и никогда не обновляли HUD. Убрали дубликат ниже.
 
-- applyBindings: проходит по всем привязкам и твинит цвета.
local function applyBindings(newColors)
    for inst, props in pairs(_themeBindings) do
        if inst.Parent then -- пропускаем уничтоженные
            for prop, keyFn in pairs(props) do
                local key = type(keyFn) == "function" and keyFn() or keyFn
                local target = newColors[key]
                if target and typeof(inst[prop]) == "Color3" then
                    tween(inst, { [prop] = target }, 0.35, Enum.EasingStyle.Quad)
                end
            end
        end
    end
end
 
local function ApplyTheme(themeName)
    local theme = THEMES[themeName]
    if not theme then return end
 
    -- Обновляем глобальную палитру.
    for key in pairs(COLORS) do
        COLORS[key] = theme[key] or COLORS[key]
    end
 
    currentTheme = themeName
 
    -- Применяем все зарегистрированные привязки (плавный переход 0.35с).
    applyBindings(COLORS)

    -- Автоматическая синхронизация палитры с визуальными системами и Cosmetics
    if theme.ambient then
        gameplayConfig.ambientThemeColor = theme.ambient
        if visualApply and visualApply.ambientColor then
            visualApply.ambientColor(theme.ambient)
        end
    end

    if theme.hit and theme.hitEnd then
        gameplayConfig.hitThemeColor = theme.hit
        gameplayConfig.hitThemeColorEnd = theme.hitEnd
    end

    if theme.glow then
        gameplayConfig.glowThemeColor = theme.glow
        if visualApply and visualApply.glow then
            visualApply.glow()
        end
    end

    if theme.cosmetics then
        gameplayConfig.cosmeticsThemeColor = theme.cosmetics
        if visualApply and visualApply.cosmetics then
            visualApply.cosmetics()
        end
    end

    -- Обновление Liquid Glass акрилового слоя под новую тему
    if updateLiquidGlassTint then
        updateLiquidGlassTint()
    end
 
    -- HUD красится в акцент темы только если включён режим "Цвет темы".
    if refreshHudColors then refreshHudColors() end
 
    -- Theme Manager сам управляет своими карточками (свой refresh).
    if _refreshThemeCards then _refreshThemeCards(themeName) end
    if HUD.refreshSelectorTheme then HUD.refreshSelectorTheme() end
end
 
local function AddShimmer(label)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(140, 140, 140)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(180, 180, 180)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)), 
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(180, 180, 180)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(140, 140, 140)),
    }
 
    gradient.Offset = Vector2.new(-1, 0)
    gradient.Parent = label
    gradient.Rotation = 15
    table.insert(shimmerGradients, gradient)
end
 
trackRuntimeConnection(RunService.RenderStepped:Connect(function(dt)
    shimmerPos = shimmerPos + dt * 0.8
    if shimmerPos > 1.5 then
        shimmerPos = -1.5
    end
    for i = #shimmerGradients, 1, -1 do
        local gradient = shimmerGradients[i]
        if gradient.Parent then
            gradient.Offset = Vector2.new(shimmerPos, 0)
        else
            table.remove(shimmerGradients, i)
        end
    end
end))
 
----------------------------------------------------------------
-- Эффект размытия заднего фона (Blur) — теперь с настраиваемой силой
----------------------------------------------------------------
 
local blurEffect = nil
local blurEffectCreated = false
local originalBlurSize = nil
pcall(function()
    blurEffect = Lighting:FindFirstChild("SolaraBlur")
    if not blurEffect then
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "SolaraBlur"
        blurEffect.Size = 0
        blurEffect.Parent = Lighting
        blurEffectCreated = true
    else
        originalBlurSize = blurEffect.Size
    end
end)
registerRuntimeCleanup(function()
    if not blurEffect then return end
    if blurEffectCreated then
        if blurEffect.Parent then blurEffect:Destroy() end
    elseif blurEffect.Parent and originalBlurSize ~= nil then
        blurEffect.Size = originalBlurSize
    end
end)
 
-- Настраиваемая пользователем сила блюра фона (применяется когда меню открыто)
local backgroundBlurAmount = 16
 
-- Настраиваемая прозрачность строк модулей (0 = непрозрачные, до 0.9 = почти прозрачные)
local moduleTransparency = 0
 
----------------------------------------------------------------
-- Корневой ScreenGui + Окно меню
----------------------------------------------------------------
 
local function getTargetGui()
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    if type(get_hidden_gui) == "function" then
        local ok, res = pcall(get_hidden_gui)
        if ok and res then return res end
    end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then return core end
    return playerGui
end

local targetGuiContainer = getTargetGui()

local function getViewportSize()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1920, 1080)
end

local previousGui = targetGuiContainer:FindFirstChild("SolaraMenu")
if previousGui then previousGui:Destroy() end

screenGui = create("ScreenGui", {
    Name = "SolaraMenu",
    Enabled = false, -- Включается только после загрузки и выбора игры.
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = targetGuiContainer,
})
screenGui.Destroying:Connect(cleanupRuntime)
 
local window = create("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(HUD.layout.width, HUD.layout.height),
    Position = UDim2.new(0.5, -490, 0.5, -310),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false, -- Скрыто, пока идет загрузка
    Parent = screenGui,
})
 
local mainGroup = create("CanvasGroup", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    GroupTransparency = 1,
    Parent = window,
})

-- Единый масштаб оболочки сохраняет доступность навигации и прокрутки.
HUD.windowScale = create("UIScale", { Scale = 1, Parent = window })
HUD.updateWindowScale = function(width, height)
    local viewport = getViewportSize()
    local baseWidth, baseHeight = width or HUD.layout.width, height or HUD.layout.height
    local scale = math.clamp(math.min((viewport.X - 24) / baseWidth, (viewport.Y - 24) / baseHeight), 0.3, 1)
    HUD.windowScale.Scale = scale
    return UDim2.new(0.5, -baseWidth * scale * 0.5, 0.5, -baseHeight * scale * 0.5)
end
window.Position = HUD.updateWindowScale()

-- Лёгкая система уведомлений: без RenderStepped, с ограниченной очередью и
-- автоматическим уничтожением карточек. Она даёт понятный feedback модулям,
-- но не создаёт постоянных соединений или объектов после закрытия toast'а.
HUD.moduleStates = {}
HUD.actionModules = { Teleport = true, ["Pull Player"] = true, Fling = true, ["Admin Panel"] = true }
HUD.notificationsEnabled = true
HUD.notificationsReady = false
HUD.toasts = {}
HUD.toastSerial = 0
HUD.toastLayer = create("Frame", {
    Name = "ToastLayer", Size = UDim2.new(0, 300, 0, 260),
    Position = UDim2.new(1, -316, 0, 16), BackgroundTransparency = 1,
    ZIndex = 300, Parent = screenGui,
})
create("UIListLayout", {
    Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = HUD.toastLayer,
})

HUD.notify = function(message, kind, duration)
    if not runtimeAlive or not HUD.notificationsReady or not HUD.notificationsEnabled then return end
    while #HUD.toasts >= 4 do
        local oldest = table.remove(HUD.toasts, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end

    HUD.toastSerial = HUD.toastSerial + 1
    local accent = COLORS.accent
    if kind == "success" then accent = Color3.fromRGB(76, 214, 140)
    elseif kind == "warning" then accent = Color3.fromRGB(255, 184, 77)
    elseif kind == "error" then accent = Color3.fromRGB(255, 92, 108) end

    local isGlass = guiStyle == "LiquidGlass"
    local card = create("CanvasGroup", {
        Name = "Toast", Size = UDim2.new(0, 280, 0, 0),
        BackgroundColor3 = COLORS.panel, BackgroundTransparency = isGlass and 0.28 or 0.04,
        GroupTransparency = 1, ClipsDescendants = true,
        LayoutOrder = HUD.toastSerial, ZIndex = 301, Parent = HUD.toastLayer,
    })
    corner(card, 10)
    stroke(card, COLORS.stroke, 1)
    create("Frame", {
        Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 7, 0, 6),
        BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 302,
        themeBind = kind == nil or kind == "info", Parent = card,
    })
    create("TextLabel", {
        Size = UDim2.new(1, -34, 1, -12), Position = UDim2.new(0, 20, 0, 6),
        BackgroundTransparency = 1, Text = tostring(message), TextWrapped = true,
        TextColor3 = COLORS.text, Font = Enum.Font.GothamSemibold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 302, Parent = card,
    })
    table.insert(HUD.toasts, card)
    tween(card, { Size = UDim2.new(0, 280, 0, 52), GroupTransparency = 0 }, 0.24, Enum.EasingStyle.Back)

    task.delay(duration or 2.4, function()
        if not card.Parent then return end
        tween(card, { Size = UDim2.new(0, 280, 0, 0), GroupTransparency = 1 }, 0.2)
        task.delay(0.21, function()
            if card.Parent then card:Destroy() end
            local index = table.find(HUD.toasts, card)
            if index then table.remove(HUD.toasts, index) end
        end)
    end)
end
 
-- Цельная тёмная оболочка вместо разрозненных колонок.
local windowGlassBg = create("Frame", {
    Name = "GlassBackground",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 0,
    Parent = mainGroup,
})
corner(windowGlassBg, 20)
local windowGlassStroke = stroke(windowGlassBg, COLORS.stroke, 1)
windowGlassStroke.Transparency = 0.15

-- Multi-layer Apple Liquid Glass: Акриловый слой с оттенком темы
local windowGlassTint = create("Frame", {
    Name = "GlassTint",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = COLORS.accent,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = windowGlassBg,
})
corner(windowGlassTint, 20)

-- Верхний световой блик (Specular highlight)
local windowGlassSpecular = create("Frame", {
    Name = "GlassSpecular",
    Size = UDim2.new(1, 0, 0, 48),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = windowGlassBg,
})
corner(windowGlassSpecular, 20)
do
    local specGrad = Instance.new("UIGradient")
specGrad.Rotation = 90
specGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0.0, 0.72),
    NumberSequenceKeypoint.new(0.35, 0.94),
    NumberSequenceKeypoint.new(1.0, 1.0),
}
specGrad.Parent = windowGlassSpecular
end

-- Анимированная полоса отражения (Reflection sweep)
local glassSweepFrame = create("Frame", {
    Name = "GlassSweep",
    Size = UDim2.new(0, 120, 2, 0),
    Position = UDim2.new(-0.4, 0, -0.5, 0),
    Rotation = 25,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = windowGlassBg,
})
do
    local sweepGrad = Instance.new("UIGradient")
sweepGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0.0, 1.0),
    NumberSequenceKeypoint.new(0.5, 0.88),
    NumberSequenceKeypoint.new(1.0, 1.0),
}
sweepGrad.Parent = glassSweepFrame
end

local function updateLiquidGlassTint()
    if windowGlassTint and windowGlassTint.Parent then
        windowGlassTint.BackgroundColor3 = COLORS.accent
    end
end
 
-- Мягкий "жидкий" блик поверх меню — виден только в режиме Liquid Glass
local guiGlassSheen = create("ImageLabel", {
    Name = "GlassSheen",
    Size = UDim2.new(1, 60, 1, 60),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://5028857084",
    ImageColor3 = Color3.fromRGB(255, 255, 255),
    ImageTransparency = 1,
    ZIndex = 200,
    themeBind = false,
    Parent = mainGroup,
})
 
-- Строка перетаскивания (TitleBar)
local titleBar = create("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundTransparency = 1,
    Parent = mainGroup,
})
 
-- Окошко для текста SOLARA в Клик-Гуи
local titleBadge = create("Frame", {
    Name = "TitleBadge",
    Size = UDim2.new(0, 180, 0, 38),
    Position = UDim2.fromOffset(24, 18),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 1,
    Parent = titleBar,
})
corner(titleBadge, 8)
 
create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = MENU_TITLE,
    TextColor3 = COLORS.header,
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = titleBadge,
})
create("Frame", { Name = "TopDivider", Position = UDim2.fromOffset(24, 71),
    Size = UDim2.new(1, -48, 0, 1), BackgroundColor3 = COLORS.stroke, Parent = mainGroup })
HUD.sidebar = create("Frame", { Name = "Sidebar", Position = UDim2.fromOffset(12, 84),
    Size = UDim2.new(0, 204, 1, -96), BackgroundColor3 = COLORS.off, Parent = mainGroup })
corner(HUD.sidebar, 14)
HUD.profileImage = create("ImageLabel", { Name = "ProfileImage", Position = UDim2.fromOffset(14, 18),
    Size = UDim2.fromOffset(38, 38), Image = "", BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Fit, Parent = HUD.sidebar })
corner(HUD.profileImage, 8)
HUD.profilePlaceholder = create("TextLabel", {
    Name = "ProfilePlaceholder", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = COLORS.panelAlt, Text = "UNI", TextSize = 13,
    Font = Enum.Font.GothamBold, TextColor3 = COLORS.accent,
    Visible = false, Parent = HUD.profileImage,
})
corner(HUD.profilePlaceholder, 8)
bindTheme(HUD.profilePlaceholder, "TextColor3", "accent")
bindTheme(HUD.profilePlaceholder, "BackgroundColor3", "panelAlt")
HUD.profileName = create("TextLabel", { Name = "ProfileName", Position = UDim2.fromOffset(62, 16),
    Size = UDim2.new(1, -74, 0, 44), BackgroundTransparency = 1, Text = "SOLARA",
    TextWrapped = true, TextSize = 12, Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLORS.text, Parent = HUD.sidebar })

local profileSwitchBtn = create("TextButton", {
    Name = "ProfileSwitchBtn", Position = UDim2.fromOffset(10, 14),
    Size = UDim2.new(1, -20, 0, 48), BackgroundColor3 = COLORS.hover,
    BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = HUD.sidebar,
})
corner(profileSwitchBtn, 10)
profileSwitchBtn.MouseEnter:Connect(function()
    tween(profileSwitchBtn, { BackgroundTransparency = 0.8 }, 0.15)
end)
profileSwitchBtn.MouseLeave:Connect(function()
    tween(profileSwitchBtn, { BackgroundTransparency = 1 }, 0.15)
end)
profileSwitchBtn.Activated:Connect(function()
    if HUD.openGameSelection then HUD.openGameSelection() end
end)

function HUD.openGameSelection()
    if not runtimeAlive or HUD.gameSelectorGui then return end
    closeSettingsPanel()
    if HUD.closeSettings then HUD.closeSettings() end
    if gameplayConfig.autoCombo and gameplayConfig.autoCombo.stop then
        gameplayConfig.autoCombo.stop()
    end
    if Ww2Engine and Ww2Engine.cancelTacticalThreads then
        Ww2Engine.cancelTacticalThreads()
    end
    HUD.selectedGame = nil
    screenGui.Enabled = false
    window.Visible = false
    menuOpen = false
    if themeFabButton then themeFabButton.Visible = false end
    HUD.notificationsReady = false
    HUD.showGameSelection()
end
HUD.navigationCaption = create("TextLabel", { Position = UDim2.fromOffset(16, 86),
    Size = UDim2.new(1, -32, 0, 16), BackgroundTransparency = 1, Text = "功能分类",
    Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = COLORS.textDim,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = HUD.sidebar })
HUD.navigation = create("Frame", { Name = "Navigation", Position = UDim2.fromOffset(8, 116),
    Size = UDim2.new(1, -16, 0, 258), BackgroundTransparency = 1, Parent = HUD.sidebar })
create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = HUD.navigation })
HUD.themeLibraryButton = create("TextButton", { Name = "ThemeLibrary", Position = UDim2.new(0, 12, 1, -100),
    Size = UDim2.new(1, -24, 0, 38), Text = "主题", TextSize = 12,
    Font = Enum.Font.GothamMedium, TextColor3 = COLORS.text, BackgroundColor3 = COLORS.panelAlt,
    AutoButtonColor = false, Parent = HUD.sidebar })
corner(HUD.themeLibraryButton, 9)
HUD.menuHint = create("TextLabel", { Position = UDim2.new(0, 244, 1, -34),
    Size = UDim2.new(1, -330, 0, 16), BackgroundTransparency = 1,
    Text = "点击 ⋯ 打开功能设置", TextSize = 11, Font = Enum.Font.Gotham,
    TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = mainGroup })
HUD.hideMenuButton = create("TextButton", { Name = "HideMenu", Position = UDim2.new(1, -60, 0, 24),
    Size = UDim2.fromOffset(36, 32), Text = "−", TextSize = 22, Font = Enum.Font.Gotham,
    TextColor3 = COLORS.textDim, BackgroundColor3 = COLORS.off, AutoButtonColor = false, Parent = mainGroup })
corner(HUD.hideMenuButton, 8)
 
----------------------------------------------------------------
-- Плавное перетаскивание (Lerp)
----------------------------------------------------------------
 
local dragging = false
local dragInput, dragStart, startPos
local targetPos = window.Position

do
    local camera = workspace.CurrentCamera
    if camera then
        trackRuntimeConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if menuOpen and not dragging then
                targetPos = HUD.updateWindowScale()
                window.Position = targetPos
            end
        end))
    end
end
 
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPos = window.Position
        
        local endConnection
        endConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                tween(window, { Rotation = 0 }, 0.18, Enum.EasingStyle.Back)
                if endConnection then endConnection:Disconnect(); endConnection = nil end
            end
        end)
    end
end)
 
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
 
trackRuntimeConnection(RunService.Heartbeat:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        targetPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    if dragging or window.Position ~= targetPos then
        window.Position = window.Position:Lerp(targetPos, 0.15)
    end
end))
 
----------------------------------------------------------------
-- Поиск по функциям в верхней панели.
----------------------------------------------------------------
 
local searchBox = create("TextBox", {
    Name = "SearchBox",
    Size = UDim2.new(1, -410, 0, 34),
    Position = UDim2.fromOffset(244, 23),
    BackgroundColor3 = COLORS.off,
    TextColor3 = COLORS.text,
    PlaceholderText = translate("SEARCH_PLACEHOLDER"),
    PlaceholderColor3 = COLORS.textDim,
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = mainGroup,
})
corner(searchBox, 8)
create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = searchBox })
local searchStroke = stroke(searchBox)
 
searchBox.Focused:Connect(function()
    tween(searchStroke, { Color = COLORS.accent }, 0.2)
end)
searchBox.FocusLost:Connect(function()
    tween(searchStroke, { Color = COLORS.stroke }, 0.2)
end)

-- ─── Языковая панель рядом с поиском (слева) ───
local langBtn = create("TextButton", {
    Name = "LangButton",
    Size = UDim2.new(0, 38, 0, 32),
    Position = UDim2.new(1, -154, 0, 24),
    BackgroundColor3 = COLORS.off,
    Text = CURRENT_LANG,
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    AutoButtonColor = false,
    Parent = mainGroup,
})
corner(langBtn, 8)
local langStroke = stroke(langBtn, COLORS.stroke, 0.5)
langBtn.MouseEnter:Connect(function()
    tween(langBtn, { BackgroundColor3 = COLORS.hover }, 0.12)
    tween(langBtn, { TextColor3 = COLORS.text }, 0.12)
    tween(langStroke, { Color = COLORS.accent }, 0.12)
end)
langBtn.MouseLeave:Connect(function()
    tween(langBtn, { BackgroundColor3 = COLORS.off }, 0.12)
    tween(langBtn, { TextColor3 = COLORS.text }, 0.12)
    tween(langStroke, { Color = COLORS.stroke }, 0.12)
end)

local langList = { "ZH" }
langBtn.MouseButton1Click:Connect(function()
    -- cycle to next language
    local idx = 1
    for i, v in ipairs(langList) do
        if v == CURRENT_LANG then
            idx = i
            break
        end
    end
    local next = langList[(idx % #langList) + 1]
    langBtn.Text = next
    -- call HUD.setLanguage (safe)
    HUD.setLanguage = HUD.setLanguage or function() end
    pcall(function() HUD.setLanguage(next) end)
end)
 
----------------------------------------------------------------
-- Страницы категорий. Видна одна страница, список функций прокручивается.
----------------------------------------------------------------
 
local columnsHolder = create("Frame", {
    Name = "CategoryPages",
    Size = UDim2.new(1, -268, 1, -148),
    Position = UDim2.fromOffset(244, 94),
    BackgroundTransparency = 1,
    Parent = mainGroup,
})
 
local allModuleRows = {}
local createdColumns = {}
 
----------------------------------------------------------------
-- Панель настроек модуля (ПКМ)
----------------------------------------------------------------
 
local activeSettingsPanel = nil
local activeSettingsOverlay = nil
local activeSettingsCloseCallback = nil
local closeColorPicker
 
local MODULE_SETTINGS_OPENERS = {}

local function closeSettingsPanel()
    if activeSettingsCloseCallback then
        local cb = activeSettingsCloseCallback
        activeSettingsCloseCallback = nil
        pcall(cb)
    end
    if activeSettingsPanel then
        local panel = activeSettingsPanel
        local ov = activeSettingsOverlay
        activeSettingsPanel = nil
        activeSettingsOverlay = nil
        if activePointerDrag and activePointerDrag.owner:IsDescendantOf(panel) then
            activePointerDrag = nil
        end
        tween(panel, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quad)
        task.delay(0.2, function()
            if panel.Parent then panel:Destroy() end
            if ov and ov.Parent then ov:Destroy() end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- Shared state для визуальных модулей (модифицируется панелями ПКМ)
-- ═══════════════════════════════════════════════════════════════
local _skyboxPreset = "Galaxy"
-- Glow Player V2 State
local _glowUseTheme = true
local _glowCustomColor = Color3.fromRGB(200, 210, 255)
local _glowMode = "Selected" -- "Selected", "Friends", "Everyone", "Self"
local _glowTargetPlayerName = ""
local _glowTargetUserId = nil
local _glowPulse = true
local _glowFillTransparency = 0.65
local _glowOutlineTransparency = 0.1
-- Better FPS V2 State (Non-destructive)
local _betterFpsLevel = 1 -- 1=Balanced (Recommended), 2=High FPS, 3=Extreme FPS
local _betterFpsDistanceCull = true
-- Hit Color V3 State
local _hitColorMode = "Gradient" -- "Gradient", "Smooth", "Pulse", "Glow", "Neon"
local _hitColorOpacity = 0.35
local _hitColorDuration = 0.30
local _hitColorUseTheme = true
local _fullbrightIntensity = 75 -- 0..100
-- Liquid Glass UI Effects State
if not gameplayConfig.uiEffects then
    gameplayConfig.uiEffects = {
        liquidGlass = false,
        reflections = true,
        glassBlur = 0.38,
        animSpeed = 1.0,
        glowIntensity = 1.0,
    }
end
local _rtxPreset = "Balanced" -- Performance, Balanced, Ultra
local _weatherCount = 80 -- 0..200
local _weatherType = "Rain" -- "Rain" / "Snow"
local _aspectRatioPreset = "16:9" -- "16:9", "4:3", "21:9", "1:1"
local _shaderHatStyle = "Halo Ring" -- "Halo Ring", "Crown Glow", "Orbit Ring"
local _crosshairStyle = "Dot" -- "Dot", "Circle", "Cross", "Target"
local _cosmeticsPreset = "Cyber Mask" -- "Cyber Mask", "Demon Wings", "Valkyrie", "Golden Crown", "Neon Aura"
local visualApply = {}

-- Тяжёлые процедурные аксессуары перестраиваются один раз после серии быстрых
-- изменений слайдера, а не десятки раз за один drag-жест.
visualApply.scheduleCosmetics = function()
    visualApply.cosmeticsRevision = (visualApply.cosmeticsRevision or 0) + 1
    local revision = visualApply.cosmeticsRevision
    task.delay(0.08, function()
        if revision == visualApply.cosmeticsRevision and visualApply.cosmetics then
            visualApply.cosmetics()
        end
    end)
end
visualApply.scheduleShaderHat = function()
    visualApply.shaderHatRevision = (visualApply.shaderHatRevision or 0) + 1
    local revision = visualApply.shaderHatRevision
    task.delay(0.06, function()
        if revision == visualApply.shaderHatRevision and visualApply.shaderHat then
            visualApply.shaderHat()
        end
    end)
end
visualApply.scheduleCrosshair = function()
    visualApply.crosshairRevision = (visualApply.crosshairRevision or 0) + 1
    local revision = visualApply.crosshairRevision
    task.delay(0.03, function()
        if revision == visualApply.crosshairRevision and visualApply.crosshair then
            visualApply.crosshair()
        end
    end)
end

local function reapplyLightingOverrides()
    if visualApply.betterFps then visualApply.betterFps() end
    if visualApply.rtx then visualApply.rtx() end
    if visualApply.fullbright then visualApply.fullbright() end
    if visualApply.ambient then visualApply.ambient() end
end

-- Единая панель ПКМ в стиле Click GUI. Все module-specific builders получают
-- прокручиваемую область, поэтому длинные списки больше не вылезают за экран.
local function createCustomPanel(moduleName, panelW, panelH, onClose)
    closeSettingsPanel()
    if HUD.closeSettings then HUD.closeSettings() end
    if closeColorPicker then closeColorPicker() end
    if themeDockOpen and toggleThemeDock then toggleThemeDock() end
    activeSettingsCloseCallback = onClose
    local viewport = getViewportSize()
    local actualW = math.min(math.clamp(panelW or 350, 260, 350), math.max(220, viewport.X - 24))
    local actualH = math.min(math.clamp(panelH or 420, 160, 420), math.max(160, viewport.Y - 24))
    local windowRight = window.AbsolutePosition.X + window.AbsoluteSize.X
    local posX
    if windowRight + actualW + 12 <= viewport.X then
        posX = windowRight + 10
    elseif window.AbsolutePosition.X - actualW - 12 >= 0 then
        posX = window.AbsolutePosition.X - actualW - 10
    else
        posX = math.clamp(window.AbsolutePosition.X + window.AbsoluteSize.X - actualW - 12, 12, math.max(12, viewport.X - actualW - 12))
    end
    local posY = math.clamp(window.AbsolutePosition.Y + 40, 12, math.max(12, viewport.Y - actualH - 12))

    local overlay = create("TextButton", {
        Name = "SettingsOverlay", Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 49, Parent = screenGui,
    })

    local panel = create("CanvasGroup", {
        Name = "SettingsPanel",
        Size = UDim2.fromOffset(actualW, actualH),
        Position = UDim2.new(0, posX, 0, posY),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0, ClipsDescendants = true,
        GroupTransparency = 1, ZIndex = 50, Parent = screenGui,
    })
    corner(panel, 16)
    stroke(panel, COLORS.stroke, 1)
    activeSettingsPanel = panel

    activeSettingsOverlay = overlay
    overlay.MouseButton1Click:Connect(function()
        if activeSettingsOverlay == overlay then closeSettingsPanel() end
    end)

    -- Общая шапка настроек в стиле новой оболочки.
    local headerH = 60
    local header = create("Frame", {
        Size = UDim2.new(1,0,0,headerH), BackgroundColor3 = COLORS.panelAlt,
        BorderSizePixel = 0, ZIndex = 2, Parent = panel,
    })
    create("Frame", { Size = UDim2.new(0,3,0,26), Position = UDim2.new(0,10,0.5,-13),
        BackgroundColor3 = COLORS.accent, BorderSizePixel = 0, ZIndex = 3, Parent = header })
    create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0),
        BackgroundColor3 = COLORS.stroke, ZIndex = 2, Parent = header })
    create("TextLabel", {
        Size = UDim2.new(1,-64,0,22), Position = UDim2.new(0,22,0,7),
        BackgroundTransparency = 1, Text = MODULE_ZH[moduleName] or moduleName, TextColor3 = COLORS.header,
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3, Parent = header,
    })
    create("TextLabel", {
        Size = UDim2.new(1,-64,0,14), Position = UDim2.new(0,22,0,29),
        BackgroundTransparency = 1, Text = CURRENT_LANG == "RU" and "功能设置" or "功能设置", TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3, Parent = header,
    })
    local closeBtn = create("TextButton", {
        Size = UDim2.new(0,28,0,28), Position = UDim2.new(1,-38,0.5,-14),
        BackgroundColor3 = COLORS.off, Text = "✕", TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold, TextSize = 13, AutoButtonColor = false,
        ZIndex = 3, Parent = header,
    })
    corner(closeBtn, 8)
    stroke(closeBtn, COLORS.stroke, 0.5)
    closeBtn.MouseButton1Click:Connect(function() closeSettingsPanel() end)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3=COLORS.hover}, 0.12) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3=COLORS.off}, 0.12) end)

    local content = create("ScrollingFrame", {
        Name = "SettingsContent",
        Size = UDim2.new(1, 0, 1, -headerH),
        Position = UDim2.new(0, 0, 0, headerH),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.accent,
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        ZIndex = 2,
        Parent = panel,
    })
    create("UIPadding", {
        Name = "SettingsPadding",
        PaddingBottom = UDim.new(0, 16),
        Parent = content,
    })

    -- Анимация
    panel.Size = UDim2.new(0, actualW - 16, 0, actualH - 16)
    panel.Position = UDim2.new(0, posX + 8, 0, posY + 8)
    tween(panel, { Size = UDim2.fromOffset(actualW, actualH), Position = UDim2.new(0, posX, 0, posY), GroupTransparency = 0 }, 0.25, Enum.EasingStyle.Back)

    return content, 12
end

-- Хелпер: кнопка-пресет внутри панели
local function createPresetButton(parent, text, posX, posY, w, isActive, onClick)
    local btn = create("TextButton", {
        Size = UDim2.new(0, w, 0, 28),
        Position = UDim2.new(0, posX, 0, posY),
        BackgroundColor3 = isActive and COLORS.accent or COLORS.off,
        Text = text, TextColor3 = isActive and COLORS.panel or COLORS.textDim,
        Font = Enum.Font.GothamSemibold, TextSize = 11, AutoButtonColor = false,
        Parent = parent,
    })
    corner(btn, 6)
    local btnStroke = stroke(btn, isActive and COLORS.accent or COLORS.stroke, 0.5)
    btn.MouseEnter:Connect(function()
        if btn.BackgroundColor3 ~= COLORS.accent then
            tween(btn, {BackgroundColor3 = COLORS.hover}, 0.12)
            tween(btnStroke, {Color = COLORS.accent}, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= COLORS.accent then
            tween(btn, {BackgroundColor3 = COLORS.off}, 0.12)
            tween(btnStroke, {Color = COLORS.stroke}, 0.12)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if onClick then onClick(btn, btnStroke) end
    end)
    return btn, btnStroke
end

-- Общие пресеты: выбор хранится в config, включая цвета после смены темы.
local function createPresetChoices(parent, posY, choices, getValue, setValue, apply)
    local buttons = {}
    local function refresh()
        for _, entry in ipairs(buttons) do
            local selected = getValue() == entry.value
            entry.button.BackgroundColor3 = selected and COLORS.accent or COLORS.off
            entry.button.TextColor3 = selected and COLORS.panel or COLORS.textDim
            entry.stroke.Color = selected and COLORS.accent or COLORS.stroke
        end
    end
    for index, value in ipairs(choices) do
        local column = (index - 1) % 2
        local y = posY + math.floor((index - 1) / 2) * 36
        local button, outline = createPresetButton(parent, value, 14, y, 104, getValue() == value, function()
            if getValue() == value then return end
            setValue(value)
            refresh()
            if apply then apply() end
        end)
        button.Position = UDim2.new(column * 0.5, 14, 0, y)
        button.Size = UDim2.new(index == #choices and column == 0 and 1 or 0.5, -28, 0, 28)
        bindTheme(button, "BackgroundColor3", function() return getValue() == value and "accent" or "off" end)
        bindTheme(button, "TextColor3", function() return getValue() == value and "panel" or "textDim" end)
        bindTheme(outline, "Color", function() return getValue() == value and "accent" or "stroke" end)
        table.insert(buttons, { button = button, stroke = outline, value = value })
    end
    return posY + math.ceil(#choices / 2) * 36 + 8
end

local function createPanelSlider(parent, posY, labelText, minValue, maxValue, currentValue, step, onChange)
    local row = create("Frame", {
        Size = UDim2.new(1, -28, 0, 48), Position = UDim2.new(0, 14, 0, posY),
        BackgroundColor3 = COLORS.off, BackgroundTransparency = 0.12,
        BorderSizePixel = 0, Parent = parent,
    })
    corner(row, 7)
    stroke(row, COLORS.stroke, 0.5)
    create("TextLabel", {
        Size = UDim2.new(0.66, -10, 0, 18), Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local valueLabel = create("TextLabel", {
        Size = UDim2.new(0.34, -10, 0, 18), Position = UDim2.new(0.66, 0, 0, 5),
        BackgroundTransparency = 1, TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })
    local bar = create("Frame", {
        Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 31),
        BackgroundColor3 = COLORS.panel, Active = true, Parent = row,
    })
    corner(bar, 4)
    stroke(bar, COLORS.stroke, 0.5)
    local fill = create("Frame", {
        BackgroundColor3 = COLORS.accent, Parent = bar,
    })
    corner(fill, 4)
    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = COLORS.header, ZIndex = 2, Parent = bar,
    })
    corner(knob, 7)
    stroke(knob, COLORS.stroke, 0.5)

    local function setVisual(value)
        local alpha = math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, math.floor((0.5 - alpha) * 14), 0.5, 0)
        local rounded = math.floor(value / step + 0.5) * step
        valueLabel.Text = step < 1 and string.format("%.2f", rounded) or tostring(math.floor(rounded + 0.5))
    end

    local function update(inputPosition)
        if bar.AbsoluteSize.X <= 0 then return end
        local alpha = math.clamp((inputPosition.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local rawValue = minValue + (maxValue - minValue) * alpha
        local value = math.clamp(math.floor(rawValue / step + 0.5) * step, minValue, maxValue)
        if value == currentValue then return end
        currentValue = value
        setVisual(value)
        onChange(value)
    end

    setVisual(currentValue)
    bindPointerDrag(bar, update)
    return posY + 56
end

-- ═══════════════════════════════════════════════════════════════
-- Skybox ПКМ: выбор пресета (Galaxy, Night, Cloudy, Fog, Custom)
-- ═══════════════════════════════════════════════════════════════
visualApply.skybox = nil -- заполняется при создании модуля

MODULE_SETTINGS_OPENERS["Skybox"] = function(anchorRow)
    local panel, cy = createCustomPanel("Skybox", 270, 240)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Выберите пресет неба:" or "选择天空盒预设：",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    createPresetChoices(panel, cy, {"Galaxy", "Night", "Sunset", "Cloudy", "Cyberpunk", "Blood Moon", "Custom"},
        function() return _skyboxPreset end,
        function(value)
            _skyboxPreset = value
            HUD.notify("Skybox: " .. value, "accent")
        end,
        function() if visualApply.skybox then visualApply.skybox() end end)
end

-- ═══════════════════════════════════════════════════════════════
-- Glow Player ПКМ: цвет следует теме или кастомный
-- ═══════════════════════════════════════════════════════════════
visualApply.glow = nil

MODULE_SETTINGS_OPENERS["Glow Player"] = function(anchorRow)
    local panel, cy = createCustomPanel("Glow Player V2", 280, 340)

    create("TextLabel", {
        Size = UDim2.new(1,-28,0,16), Position = UDim2.new(0,14,0,cy),
        BackgroundTransparency = 1, Text = CURRENT_LANG == "RU" and "Режим свечения" or "发光模式",
        TextColor3 = COLORS.textDim, Font = Enum.Font.GothamSemibold,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 20

    local glowModes = {
        { name = "Selected", label = CURRENT_LANG == "RU" and "Выбранный" or "已选择" },
        { name = "Friends",  label = CURRENT_LANG == "RU" and "Друзья" or "好友" },
        { name = "Everyone", label = CURRENT_LANG == "RU" and "Все" or "所有人" },
        { name = "Self",     label = CURRENT_LANG == "RU" and "Себя" or "自己" },
    }

    local modeBtns = {}
    local function refreshGlowModeButtons()
        for _, entry in ipairs(modeBtns) do
            local isAct = (_glowMode == entry.name)
            entry.btn.BackgroundColor3 = isAct and COLORS.accent or COLORS.off
            entry.btn.TextColor3 = isAct and COLORS.panel or COLORS.textDim
            entry.stroke.Color = isAct and COLORS.accent or COLORS.stroke
        end
    end

    local targetPlayerBtn, targetPlayerStroke

    for i, m in ipairs(glowModes) do
        local px = 14 + ((i-1) % 2) * 128
        local py = cy + math.floor((i-1) / 2) * 32
        local isAct = (_glowMode == m.name)
        local btn, bs = createPresetButton(panel, m.label, px, py, 122, isAct, function(b, bsInner)
            _glowMode = m.name
            refreshGlowModeButtons()
            if targetPlayerBtn then
                targetPlayerBtn.Visible = (_glowMode == "Selected")
            end
            if visualApply.glow then visualApply.glow() end
        end)
        table.insert(modeBtns, { btn = btn, stroke = bs, name = m.name })
    end
    cy = cy + 68

    -- Выбор игрока (Drop-down кнопка)
    local targetText = (_glowTargetPlayerName ~= "" and _glowTargetPlayerName) or (CURRENT_LANG == "RU" and "Выбрать игрока..." or "选择玩家……")
    targetPlayerBtn, targetPlayerStroke = createPresetButton(panel, "🎯 " .. targetText, 14, cy, 252, false, function(b, bs)
        local playersList = Players:GetPlayers()
        local pChoices = {}
        for _, p in ipairs(playersList) do
            if p ~= player then
                table.insert(pChoices, p.Name)
            end
        end
        if #pChoices == 0 then
            table.insert(pChoices, player.Name)
        end
        local dropPanel, dcy = createCustomPanel(CURRENT_LANG == "RU" and "Список игроков" or "玩家列表", 260, math.min(320, 48 + #pChoices * 34))
        for _, pName in ipairs(pChoices) do
            local pBtn, _ = createPresetButton(dropPanel, pName, 14, dcy, 232, (_glowTargetPlayerName == pName), function(pb)
                _glowTargetPlayerName = pName
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name == pName then _glowTargetUserId = p.UserId; break end
                end
                b.Text = "🎯 " .. pName
                if visualApply.glow then visualApply.glow() end
                closeSettingsPanel()
            end)
            dcy = dcy + 34
        end
    end)
    targetPlayerBtn.Visible = (_glowMode == "Selected")
    cy = cy + 36

    -- Theme Sync & Pulse кнопки
    local syncActive = _glowUseTheme == true
    local syncBtn, syncStroke = createPresetButton(panel, syncActive and (CURRENT_LANG == "RU" and "Синхронизация с темой: ВКЛ" or "主题同步：开") or (CURRENT_LANG == "RU" and "Синхронизация с темой: ВЫКЛ" or "主题同步：关"), 14, cy, 252, syncActive, function(b, bs)
        _glowUseTheme = not _glowUseTheme
        local act = _glowUseTheme
        b.Text = act and (CURRENT_LANG == "RU" and "Синхронизация с темой: ВКЛ" or "主题同步：开") or (CURRENT_LANG == "RU" and "Синхронизация с темой: ВЫКЛ" or "主题同步：关")
        b.BackgroundColor3 = act and COLORS.accent or COLORS.off
        b.TextColor3 = act and COLORS.panel or COLORS.textDim
        bs.Color = act and COLORS.accent or COLORS.stroke
        if visualApply.glow then visualApply.glow() end
    end)
    cy = cy + 36

    local pulseActive = _glowPulse == true
    local pulseBtn, pulseStroke = createPresetButton(panel, pulseActive and (CURRENT_LANG == "RU" and "Пульсация (Pulse): ВКЛ" or "脉冲动画：开") or (CURRENT_LANG == "RU" and "Пульсация (Pulse): ВЫКЛ" or "脉冲动画：关"), 14, cy, 252, pulseActive, function(b, bs)
        _glowPulse = not _glowPulse
        local act = _glowPulse
        b.Text = act and (CURRENT_LANG == "RU" and "Пульсация (Pulse): ВКЛ" or "脉冲动画：开") or (CURRENT_LANG == "RU" and "Пульсация (Pulse): ВЫКЛ" or "脉冲动画：关")
        b.BackgroundColor3 = act and COLORS.accent or COLORS.off
        b.TextColor3 = act and COLORS.panel or COLORS.textDim
        bs.Color = act and COLORS.accent or COLORS.stroke
        if visualApply.glow then visualApply.glow() end
    end)
    cy = cy + 38

    cy = createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Прозрачность заливки" or "填充透明度", 0, 100, math.floor(_glowFillTransparency * 100), 5, function(val)
        _glowFillTransparency = val / 100
        if visualApply.glow then visualApply.glow() end
    end)

    cy = createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Прозрачность контура" or "轮廓透明度", 0, 100, math.floor(_glowOutlineTransparency * 100), 5, function(val)
        _glowOutlineTransparency = val / 100
        if visualApply.glow then visualApply.glow() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Better FPS V2 ПКМ: Умная оптимизация эффектов (Non-Destructive)
-- ═══════════════════════════════════════════════════════════════
visualApply.betterFps = nil

MODULE_SETTINGS_OPENERS["Better FPS"] = function(anchorRow)
    local panel, cy = createCustomPanel("Better FPS V2", 280, 270)

    create("TextLabel", {
        Size = UDim2.new(1,-28,0,16), Position = UDim2.new(0,14,0,cy),
        BackgroundTransparency = 1, Text = CURRENT_LANG == "RU" and "Профиль умной оптимизации" or "优化方案",
        TextColor3 = COLORS.textDim, Font = Enum.Font.GothamSemibold,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })

    local levels = {
        {name = "Balanced (Рекомендуется)", desc = CURRENT_LANG == "RU" and "Без потери картинки, умный троттлинг дальних эффектов" or "保持画质，并按距离降低特效负载", val = 1},
        {name = "High FPS", desc = CURRENT_LANG == "RU" and "Снижение Rate тяжёлых частиц и Segments Beam" or "减少高负载粒子、光束分段和长拖尾", val = 2},
        {name = "Extreme FPS", desc = CURRENT_LANG == "RU" and "Максимальный FPS, динамическое затухание дальних эффектов" or "最高帧率，逐步裁剪远处粒子", val = 3},
    }

    local levelBtns = {}

    for i, level in ipairs(levels) do
        local py = cy + 20 + (i-1) * 44
        local isAct = (_betterFpsLevel == level.val)
        local btn, bs = createPresetButton(panel, level.name, 14, py, 252, isAct, function(b, bsInner)
            _betterFpsLevel = level.val
            for _, entry in ipairs(levelBtns) do
                entry.btn.BackgroundColor3 = COLORS.off
                entry.btn.TextColor3 = COLORS.textDim
                entry.stroke.Color = COLORS.stroke
            end
            b.BackgroundColor3 = COLORS.accent
            b.TextColor3 = COLORS.panel
            bsInner.Color = COLORS.accent
            if visualApply.betterFps then visualApply.betterFps() end
        end)
        create("TextLabel", {
            Size = UDim2.new(1,-28,0,12), Position = UDim2.new(0,14,0,py + 28),
            BackgroundTransparency = 1, Text = level.desc,
            TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham,
            TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
        })
        table.insert(levelBtns, {btn = btn, stroke = bs})
    end

    cy = cy + 154

    local distActive = _betterFpsDistanceCull == true
    local distBtn, distStroke = createPresetButton(panel, distActive and (CURRENT_LANG == "RU" and "Дистанционный троттлинг: ВКЛ" or "距离裁剪：开") or (CURRENT_LANG == "RU" and "Дистанционный троттлинг: ВЫКЛ" or "距离裁剪：关"), 14, cy, 252, distActive, function(b, bs)
        _betterFpsDistanceCull = not _betterFpsDistanceCull
        local act = _betterFpsDistanceCull
        b.Text = act and (CURRENT_LANG == "RU" and "Дистанционный троттлинг: ВКЛ" or "距离裁剪：开") or (CURRENT_LANG == "RU" and "Дистанционный троттлинг: ВЫКЛ" or "距离裁剪：关")
        b.BackgroundColor3 = act and COLORS.accent or COLORS.off
        b.TextColor3 = act and COLORS.panel or COLORS.textDim
        bs.Color = act and COLORS.accent or COLORS.stroke
        if visualApply.betterFps then visualApply.betterFps() end
    end)
    cy = cy + 34

    create("TextLabel", {
        Size = UDim2.new(1,-28,0,24), Position = UDim2.new(0,14,0,cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "✓ Текстуры, меши, тени и атмосфера остаются красивыми" or "✓ 保留纹理、网格、阴影与氛围效果",
        TextColor3 = Color3.fromRGB(120, 210, 150), Font = Enum.Font.GothamMedium,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- Hit Color V3 ПКМ: Двухцветный градиент темы и плавные анимации
-- ═══════════════════════════════════════════════════════════════
MODULE_SETTINGS_OPENERS["Hit Color"] = function(anchorRow)
    local panel, cy = createCustomPanel("Hit Color V3", 280, 270)

    create("TextLabel", {
        Size = UDim2.new(1,-28,0,16), Position = UDim2.new(0,14,0,cy),
        BackgroundTransparency = 1, Text = CURRENT_LANG == "RU" and "Стиль эффекта попадания" or "命中特效样式",
        TextColor3 = COLORS.textDim, Font = Enum.Font.GothamSemibold,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 20

    local modes = { "Gradient", "Smooth", "Pulse", "Glow", "Neon" }
    cy = createPresetChoices(panel, cy, modes,
        function() return _hitColorMode end,
        function(val) _hitColorMode = val end,
        function() end)

    cy = createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Прозрачность попадания" or "命中特效透明度", 10, 90, math.floor(_hitColorOpacity * 100), 5, function(val)
        _hitColorOpacity = val / 100
    end)

    cy = createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Длительность эффекта (сек)" or "持续时间（秒）", 15, 80, math.floor(_hitColorDuration * 100), 5, function(val)
        _hitColorDuration = val / 100
    end)

    create("TextLabel", {
        Size = UDim2.new(1,-28,0,24), Position = UDim2.new(0,14,0,cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "✓ Синхронизирован с двухцветной палитрой текущей темы" or "✓ 与当前主题双色配色同步",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

visualApply.fullbright = nil

MODULE_SETTINGS_OPENERS["Fullbright"] = function(anchorRow)
    local panel, cy = createCustomPanel("Fullbright", 260, 130)
    createPanelSlider(panel, cy, "Intensity", 0, 100, _fullbrightIntensity, 1, function(value)
        _fullbrightIntensity = value
        if visualApply.fullbright then visualApply.fullbright() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- RTX Graphics ПКМ: выбор профиля (Performance, Balanced, Ultra) + Cinematic Mode
-- ═══════════════════════════════════════════════════════════════
visualApply.rtx = nil

MODULE_SETTINGS_OPENERS["RTX Graphics"] = function(anchorRow)
    local panel, cy = createCustomPanel("RTX Graphics", 280, 270)

    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1, Text = "RTX 质量",
        TextColor3 = COLORS.textDim, Font = Enum.Font.GothamSemibold,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 20

    cy = createPresetChoices(panel, cy, {"Performance", "Balanced", "Ultra"},
        function() return _rtxPreset end,
        function(value) _rtxPreset = value end,
        function() if visualApply.rtx then visualApply.rtx() end end)

    local cinActive = gameplayConfig.rtxCinematic == true
    local cinBtn, cinStroke = createPresetButton(panel, cinActive and "Cinematic Mode: ON" or "Cinematic Mode: OFF", 14, cy, 252, cinActive, function(b, bs)
        gameplayConfig.rtxCinematic = not gameplayConfig.rtxCinematic
        local active = gameplayConfig.rtxCinematic
        b.Text = active and "Cinematic Mode: ON" or "Cinematic Mode: OFF"
        b.BackgroundColor3 = active and COLORS.accent or COLORS.off
        b.TextColor3 = active and COLORS.panel or COLORS.textDim
        bs.Color = active and COLORS.accent or COLORS.stroke
        if visualApply.rtx then visualApply.rtx() end
    end)
    bindTheme(cinBtn, "BackgroundColor3", function() return gameplayConfig.rtxCinematic and "accent" or "off" end)
    bindTheme(cinBtn, "TextColor3", function() return gameplayConfig.rtxCinematic and "panel" or "textDim" end)
    bindTheme(cinStroke, "Color", function() return gameplayConfig.rtxCinematic and "accent" or "stroke" end)
    cy = cy + 36

    createPanelSlider(panel, cy, "Effect Intensity", 0.5, 1.5, gameplayConfig.rtxIntensity, 0.05, function(value)
        gameplayConfig.rtxIntensity = value
        if visualApply.rtx then visualApply.rtx() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Weather FX ПКМ: выбор типа (Rain / Snow) и количества (0-200)
-- ═══════════════════════════════════════════════════════════════
visualApply.weather = nil

MODULE_SETTINGS_OPENERS["Weather FX"] = function(anchorRow)
    local panel, cy = createCustomPanel("Weather FX", 260, 200)
    cy = createPresetChoices(panel, cy, {"Rain", "Snow"},
        function() return _weatherType end,
        function(value) _weatherType = value end,
        function() if visualApply.weather then visualApply.weather() end end)
    createPanelSlider(panel, cy, "Particle Density", 0, 200, _weatherCount, 1, function(value)
        _weatherCount = value
        if visualApply.weather then visualApply.weather() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Aspect Ratio ПКМ: выбор соотношения сторон (16:9, 4:3, 21:9, 1:1)
-- ═══════════════════════════════════════════════════════════════
visualApply.aspect = nil

MODULE_SETTINGS_OPENERS["Aspect Ratio"] = function(anchorRow)
    local panel, cy = createCustomPanel("Aspect Ratio", 260, 180)
    createPresetChoices(panel, cy, {"16:9", "4:3", "21:9", "1:1"},
        function() return _aspectRatioPreset end,
        function(value) _aspectRatioPreset = value end,
        function() if visualApply.aspect then visualApply.aspect() end end)
end

-- ═══════════════════════════════════════════════════════════════
-- Shader Hat ПКМ: выбор стиля кольца (Halo Ring, Crown Glow, Orbit Ring)
-- ═══════════════════════════════════════════════════════════════
visualApply.shaderHat = nil

MODULE_SETTINGS_OPENERS["Shader Hat"] = function(anchorRow)
    local panel, cy = createCustomPanel("Shader Hat", 300, 340)
    cy = createPresetChoices(panel, cy, {"Halo Ring", "Crown Glow", "Orbit Ring"},
        function() return _shaderHatStyle end,
        function(value) _shaderHatStyle = value end,
        visualApply.scheduleShaderHat)
    cy = createPanelSlider(panel, cy, "Ring Scale", 0.5, 2, gameplayConfig.shaderHatScale, 0.05, function(value)
        gameplayConfig.shaderHatScale = value
        visualApply.scheduleShaderHat()
    end)
    cy = createPanelSlider(panel, cy, "Height Offset", -1, 3, gameplayConfig.shaderHatHeight, 0.1, function(value)
        gameplayConfig.shaderHatHeight = value
        visualApply.scheduleShaderHat()
    end)
    createPanelSlider(panel, cy, "Tube Thickness", 0.5, 2, gameplayConfig.shaderHatThickness, 0.05, function(value)
        gameplayConfig.shaderHatThickness = value
        visualApply.scheduleShaderHat()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Crosshair ПКМ: выбор вида прицела (Dot, Circle, Cross, Target)
-- ═══════════════════════════════════════════════════════════════
visualApply.crosshair = nil

MODULE_SETTINGS_OPENERS["Crosshair"] = function(anchorRow)
    local panel, cy = createCustomPanel("Crosshair", 300, 360)
    cy = createPresetChoices(panel, cy, {"Dot", "Circle", "Cross", "Target"},
        function() return _crosshairStyle end,
        function(value) _crosshairStyle = value end,
        visualApply.scheduleCrosshair)
    cy = createPanelSlider(panel, cy, "Size", 8, 40, gameplayConfig.crosshairSize, 1, function(value)
        gameplayConfig.crosshairSize = value
        visualApply.scheduleCrosshair()
    end)
    cy = createPanelSlider(panel, cy, "Thickness", 1, 6, gameplayConfig.crosshairThickness, 1, function(value)
        gameplayConfig.crosshairThickness = value
        visualApply.scheduleCrosshair()
    end)
    cy = createPanelSlider(panel, cy, "Center Gap", 0, 12, gameplayConfig.crosshairGap, 1, function(value)
        gameplayConfig.crosshairGap = value
        visualApply.scheduleCrosshair()
    end)
    createPanelSlider(panel, cy, "Transparency", 0, 0.9, gameplayConfig.crosshairOpacity, 0.05, function(value)
        gameplayConfig.crosshairOpacity = value
        visualApply.scheduleCrosshair()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Cosmetics ПКМ: выбор кастомного скина/аксессуара
-- ═══════════════════════════════════════════════════════════════
visualApply.cosmetics = nil

MODULE_SETTINGS_OPENERS["Cosmetics"] = function(anchorRow)
    local panel, cy = createCustomPanel("Cosmetics", 260, 330)
    cy = createPresetChoices(panel, cy, {"Cyber Mask", "Demon Wings", "Valkyrie", "Golden Crown", "Neon Aura"},
        function() return _cosmeticsPreset end,
        function(value) _cosmeticsPreset = value end,
        visualApply.scheduleCosmetics)
    cy = createPanelSlider(panel, cy, "Accessory Scale", 0.6, 1.6, gameplayConfig.cosmeticScale, 0.05, function(value)
        gameplayConfig.cosmeticScale = value
        visualApply.scheduleCosmetics()
    end)
    cy = createPanelSlider(panel, cy, "Animation Speed", 0.25, 2.5, gameplayConfig.cosmeticSpeed, 0.05, function(value)
        gameplayConfig.cosmeticSpeed = value
    end)
    createPanelSlider(panel, cy, "Height: 0 Ground / 20 Head", 0, 20, gameplayConfig.cosmeticHeight, 1, function(value)
        gameplayConfig.cosmeticHeight = value
        if visualApply.cosmeticHeight then visualApply.cosmeticHeight() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- SpotyHUB ПКМ Панели Настроек Модулей
-- ═══════════════════════════════════════════════════════════════

local function createPlayerPickerRow(panel, cy, titleText, currentSelection, onSelect)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1, Text = titleText,
        TextColor3 = COLORS.textDim, Font = Enum.Font.GothamSemibold,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })

    local playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(playerList, p) end
    end
    table.sort(playerList, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    local search = create("TextBox", {
        Name = "PlayerSearch",
        Size = UDim2.new(1, -28, 0, 30), Position = UDim2.new(0, 14, 0, cy + 20),
        BackgroundColor3 = COLORS.off, Text = "", PlaceholderText = "搜索玩家……",
        PlaceholderColor3 = COLORS.textDim, TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = panel,
    })
    corner(search, 7)
    stroke(search, COLORS.stroke, 1)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = search })

    local listStart = cy + 58
    local listFrame = create("Frame", {
        Name = "PlayerList",
        Size = UDim2.new(1, -28, 0, math.max(42, #playerList * 44)),
        Position = UDim2.new(0, 14, 0, listStart),
        BackgroundTransparency = 1,
        Parent = panel,
    })
    local records = {}
    local selectedName = currentSelection

    local function refreshSelection()
        for _, record in ipairs(records) do
            local selected = record.player.Name == selectedName
            record.button.BackgroundColor3 = selected and COLORS.accent or COLORS.off
            record.nameLabel.TextColor3 = selected and COLORS.panel or COLORS.text
            record.userLabel.TextColor3 = selected and COLORS.panelAlt or COLORS.textDim
            record.check.Text = selected and "✓" or ""
            record.stroke.Color = selected and COLORS.accent or COLORS.stroke
        end
    end

    if #playerList == 0 then
        local empty = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = COLORS.off,
            Text = "服务器中暂无其他玩家", TextColor3 = COLORS.textDim,
            Font = Enum.Font.GothamSemibold, TextSize = 11, Parent = listFrame,
        })
        corner(empty, 7)
        stroke(empty, COLORS.stroke, 0.5)
    else
        if selectedName ~= "" and not Players:FindFirstChild(selectedName) then
            selectedName = ""
            if onSelect then onSelect("") end
        end

        for index, targetPlayer in ipairs(playerList) do
            local playerButton = create("TextButton", {
                Name = targetPlayer.Name,
                Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, (index - 1) * 44),
                BackgroundColor3 = COLORS.off, Text = "", AutoButtonColor = false,
                Parent = listFrame,
            })
            corner(playerButton, 7)
            local playerStroke = stroke(playerButton, COLORS.stroke, 0.5)
            create("ImageLabel", {
                Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 5, 0.5, -15),
                BackgroundColor3 = COLORS.panelAlt,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(targetPlayer.UserId) .. "&w=48&h=48",
                Parent = playerButton,
            })
            local nameLabel = create("TextLabel", {
                Size = UDim2.new(1, -82, 0, 17), Position = UDim2.new(0, 43, 0, 4),
                BackgroundTransparency = 1, Text = targetPlayer.DisplayName,
                TextColor3 = COLORS.text, Font = Enum.Font.GothamSemibold, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = playerButton,
            })
            local userLabel = create("TextLabel", {
                Size = UDim2.new(1, -82, 0, 14), Position = UDim2.new(0, 43, 0, 21),
                BackgroundTransparency = 1, Text = "@" .. targetPlayer.Name,
                TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = playerButton,
            })
            local check = create("TextLabel", {
                Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -30, 0.5, -12),
                BackgroundTransparency = 1, Text = "", TextColor3 = COLORS.panel,
                Font = Enum.Font.GothamBold, TextSize = 14, Parent = playerButton,
            })
            local record = { player = targetPlayer, button = playerButton, stroke = playerStroke,
                nameLabel = nameLabel, userLabel = userLabel, check = check }
            table.insert(records, record)

            playerButton.MouseButton1Click:Connect(function()
                if selectedName == targetPlayer.Name then
                    selectedName = ""
                else
                    selectedName = targetPlayer.Name
                end
                if onSelect then onSelect(selectedName) end
                refreshSelection()
            end)
            playerButton.MouseEnter:Connect(function()
                if selectedName ~= targetPlayer.Name then tween(playerButton, { BackgroundColor3 = COLORS.hover }, 0.12) end
            end)
            playerButton.MouseLeave:Connect(function()
                if selectedName ~= targetPlayer.Name then tween(playerButton, { BackgroundColor3 = COLORS.off }, 0.12) end
            end)
        end
        refreshSelection()

        search:GetPropertyChangedSignal("Text"):Connect(function()
            local query = search.Text:lower()
            local visibleIndex = 0
            for _, record in ipairs(records) do
                local matches = query == "" or record.player.Name:lower():find(query, 1, true)
                    or record.player.DisplayName:lower():find(query, 1, true)
                record.button.Visible = matches and true or false
                if matches then
                    record.button.Position = UDim2.new(0, 0, 0, visibleIndex * 44)
                    visibleIndex = visibleIndex + 1
                end
            end
            listFrame.Size = UDim2.new(1, -28, 0, math.max(42, visibleIndex * 44))
        end)
    end

    return listStart + math.max(42, #playerList * 44) + 10
end

-- ═══════════════════════════════════════════════════════════════
-- Auto Combo ПКМ: выбор цели, кнопки START / STOP и настройки
-- ═══════════════════════════════════════════════════════════════
HUD.openAutoComboSettings = function(anchorRow)
    local AutoCombo = gameplayConfig.autoCombo
    local panel, cy = createCustomPanel("Auto Combo", 280, 420)

    local targetLabel = create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = "当前目标：" .. (gameplayConfig.autoComboTarget ~= "" and ("@" .. gameplayConfig.autoComboTarget) or "无"),
        TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22

    local statusLabel = create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = "状态：" .. (AutoCombo.State.running and "运行中" or "待机"),
        TextColor3 = AutoCombo.State.running and COLORS.accent or COLORS.textDim,
        Font = Enum.Font.GothamSemibold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22

    local function refreshHeader()
        targetLabel.Text = "当前目标：" .. (gameplayConfig.autoComboTarget ~= "" and ("@" .. gameplayConfig.autoComboTarget) or "无")
        statusLabel.Text = "状态：" .. (AutoCombo.State.running and "运行中" or "待机")
        statusLabel.TextColor3 = AutoCombo.State.running and COLORS.accent or COLORS.textDim
    end
    AutoCombo.State.panelRefresh = refreshHeader

    local startBtn, startStroke = createPresetButton(panel, "START COMBO", 14, cy, 120, false, function()
        if AutoCombo.start then AutoCombo.start() end
        refreshHeader()
    end)
    startBtn.BackgroundColor3 = COLORS.accent
    startBtn.TextColor3 = COLORS.panel
    startStroke.Color = COLORS.accent

    local stopBtn, stopStroke = createPresetButton(panel, "STOP COMBO", 146, cy, 120, false, function()
        if AutoCombo.stop then AutoCombo.stop() end
        refreshHeader()
    end)
    cy = cy + 36

    cy = createPlayerPickerRow(panel, cy, "Select Target Player", gameplayConfig.autoComboTarget, function(name)
        gameplayConfig.autoComboTarget = name
        refreshHeader()
    end)

    cy = createPanelSlider(panel, cy, "Dash Back Distance", 1, 8, AutoCombo.Config.DashBackDistance or 3, 1, function(value)
        AutoCombo.Config.DashBackDistance = value
    end)

    cy = createPanelSlider(panel, cy, "Second 4 Distance", 3, 15, AutoCombo.Config.Second4Distance or 6, 1, function(value)
        AutoCombo.Config.Second4Distance = value
    end)

    local dbgActive = AutoCombo.Config.Debug == true
    local dbgBtn, dbgStroke = createPresetButton(panel, dbgActive and "Debug Mode: ON" or "Debug Mode: OFF", 14, cy, 252, dbgActive, function(b, bs)
        AutoCombo.Config.Debug = not AutoCombo.Config.Debug
        local active = AutoCombo.Config.Debug
        b.Text = active and "Debug Mode: ON" or "Debug Mode: OFF"
        b.BackgroundColor3 = active and COLORS.accent or COLORS.off
        b.TextColor3 = active and COLORS.panel or COLORS.textDim
        bs.Color = active and COLORS.accent or COLORS.stroke
    end)
    bindTheme(dbgBtn, "BackgroundColor3", function() return AutoCombo.Config.Debug and "accent" or "off" end)
    bindTheme(dbgBtn, "TextColor3", function() return AutoCombo.Config.Debug and "panel" or "textDim" end)
    bindTheme(dbgStroke, "Color", function() return AutoCombo.Config.Debug and "accent" or "stroke" end)
end

MODULE_SETTINGS_OPENERS["HvH"] = function(anchorRow)
    local panel, cy = createCustomPanel("HvH Settings", 260, 140)
    createPlayerPickerRow(panel, cy, "HvH Target Player", gameplayConfig.hvhTarget, function(name) gameplayConfig.hvhTarget = name end)
end

MODULE_SETTINGS_OPENERS["Target Strafe"] = function(anchorRow)
    local panel, cy = createCustomPanel("Target Strafe", 260, 230)
    cy = createPlayerPickerRow(panel, cy, "Strafe Target Player", gameplayConfig.strafeTarget, function(name) gameplayConfig.strafeTarget = name end)
    cy = createPanelSlider(panel, cy, "Orbit Radius", 2, 20, gameplayConfig.strafeRadius, 1, function(value) gameplayConfig.strafeRadius = value end)
    createPanelSlider(panel, cy, "Orbit Speed", 30, 360, gameplayConfig.strafeSpeed, 10, function(value) gameplayConfig.strafeSpeed = value end)
end

MODULE_SETTINGS_OPENERS["Hitbox Expander"] = function(anchorRow)
    local panel, cy = createCustomPanel("Hitbox Expander", 260, 140)
    createPanelSlider(panel, cy, "Hitbox Size", 2, 20, gameplayConfig.hitboxSize, 1, function(value) gameplayConfig.hitboxSize = value end)
end

MODULE_SETTINGS_OPENERS["Kill Player"] = function(anchorRow)
    local panel, cy = createCustomPanel("Kill Player", 260, 160)
    createPlayerPickerRow(panel, cy, "Target Player to Kill", gameplayConfig.killTarget, function(name) gameplayConfig.killTarget = name end)
end

MODULE_SETTINGS_OPENERS["Instant Dash"] = function(anchorRow)
    local panel, cy = createCustomPanel("Instant Dash", 260, 200)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = "冲刺键：[Z]（游戏内按 Z）",
        TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 24
    cy = createPanelSlider(panel, cy, "Dash Speed / Distance", 50, 500, gameplayConfig.tsbDashSpeed or 180, 10, function(value)
        gameplayConfig.tsbDashSpeed = value
    end)
    createPresetButton(panel, "TRIGGER DASH NOW", 14, cy, 232, false, function()
        executeTsbDash()
    end)
end

MODULE_SETTINGS_OPENERS["No Block Slow"] = function(anchorRow)
    local panel, cy = createCustomPanel("No Block Slow", 260, 130)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 50), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = "自动移除 The Strongest Battlegrounds 格挡时附加的减速状态。",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Desync Glitch"] = function(anchorRow)
    local panel, cy = createCustomPanel("Desync Glitch", 260, 170)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 42), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = "利用物理状态改变服务器碰撞位置，以避开攻击。",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 46
    createPresetButton(panel, "TRIGGER DESYNC", 14, cy, 232, false, function()
        executeTsbDesync()
    end)
end

MODULE_SETTINGS_OPENERS["Fast M1"] = function(anchorRow)
    local panel, cy = createCustomPanel("Fast M1 Settings", 260, 180)
    cy = createPanelSlider(panel, cy, "Attack Delay %", 10, 100, gameplayConfig.tsbAttackDelay or 100, 5, function(value)
        gameplayConfig.tsbAttackDelay = value
    end)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 36), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = "提前结束攻击动画后摇，加快连续攻击。",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Bunny Hop"] = function(anchorRow)
    local panel, cy = createCustomPanel("Bunny Hop", 260, 170)
    cy = createPanelSlider(panel, cy, "Move Speed", 16, 120, gameplayConfig.bhopSpeed, 1, function(value) gameplayConfig.bhopSpeed = value end)
    createPanelSlider(panel, cy, "Jump Velocity", 20, 100, gameplayConfig.bhopJumpHeight, 1, function(value) gameplayConfig.bhopJumpHeight = value end)
end

MODULE_SETTINGS_OPENERS["Custom Speed"] = function(anchorRow)
    local panel, cy = createCustomPanel("Custom Speed", 260, 140)
    createPanelSlider(panel, cy, "WalkSpeed", 8, 150, gameplayConfig.customSpeed, 1, function(value) gameplayConfig.customSpeed = value end)
end

MODULE_SETTINGS_OPENERS["Fly"] = function(anchorRow)
    local isVehicle = (HUD.selectedGame and HUD.selectedGame.id == "midnight_chasers")
        or (anchorRow and anchorRow.Parent and anchorRow.Parent:GetAttribute("Category") == "COMBAT")
    if isVehicle then
        local panel, cy = createCustomPanel(CURRENT_LANG == "RU" and "Полёт на машине" or "车辆飞行", 260, 140)
        createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Скорость полёта" or "飞行速度", 10, 200, gameplayConfig.vehicleFlySpeed, 5, function(value)
            gameplayConfig.vehicleFlySpeed = value
        end)
    else
        local panel, cy = createCustomPanel("Fly Settings", 260, 140)
        createPanelSlider(panel, cy, "Fly Speed", 10, 200, gameplayConfig.flySpeed, 5, function(value) gameplayConfig.flySpeed = value end)
    end
end

function HUD.openVehicleSpeedSettings(anchorRow)
    local panel, cy = createCustomPanel(CURRENT_LANG == "RU" and "Скорость машины" or "车辆速度", 260, 140)
    createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Ускорение (Speed)" or "速度增幅", 0, 50, gameplayConfig.vehicleSpeed, 1, function(value)
        gameplayConfig.vehicleSpeed = value
    end)
end

function HUD.openVehicleBrakesSettings(anchorRow)
    local panel, cy = createCustomPanel(CURRENT_LANG == "RU" and "Тормоз машины" or "车辆制动", 260, 140)
    createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Сила тормоза (Brakes)" or "制动力", 0, 50, gameplayConfig.vehicleBrakes, 1, function(value)
        gameplayConfig.vehicleBrakes = value
    end)
end

function HUD.openVehicleHandlingSettings(anchorRow)
    local panel, cy = createCustomPanel(CURRENT_LANG == "RU" and "Управление машины" or "车辆操控", 260, 140)
    createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Отзывчивость руля" or "操控灵敏度", 0, 50, gameplayConfig.vehicleHandling, 1, function(value)
        gameplayConfig.vehicleHandling = value
    end)
end

function HUD.teleportVehicleToPlayer()
    local targetChar = getSelectedTarget(gameplayConfig.vehicleTpTarget)
    if not targetChar then
        HUD.notify(CURRENT_LANG == "RU" and "Teleport to: сначала выберите игрока через ПКМ" or "传送：请先在设置中选择玩家", "warning", 3)
        return false
    end
    local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then
        HUD.notify(CURRENT_LANG == "RU" and "Teleport to: персонаж цели не найден" or "传送：未找到目标角色", "error", 3)
        return false
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")

    local targetCF = tRoot.CFrame * CFrame.new(0, 3, 10)
    if seat then
        local vehModel = seat:FindFirstAncestorOfClass("Model")
        local vehRoot = seat.AssemblyRootPart or seat
        if vehModel and vehModel.PrimaryPart then
            pcall(function() vehModel:PivotTo(targetCF) end)
        end
        if vehRoot then
            vehRoot.CFrame = targetCF
            vehRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            vehRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        if myRoot then
            myRoot.CFrame = targetCF * CFrame.new(0, 2, 0)
        end
        HUD.notify(CURRENT_LANG == "RU" and "Teleport to: машина перемещена к игроку" or "传送：车辆已移动到目标玩家", "success")
        return true
    elseif myRoot then
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
        HUD.notify(CURRENT_LANG == "RU" and "Teleport to: вы не в машине, персонаж перемещён" or "传送：当前未乘车，已移动角色", "warning", 3)
        return true
    end
    return false
end

function HUD.openVehicleTeleportSettings(anchorRow)
    local panel, cy = createCustomPanel(CURRENT_LANG == "RU" and "Телепорт с машиной" or "传送到玩家", 270, 210)
    cy = createPlayerPickerRow(panel, cy, CURRENT_LANG == "RU" and "Игрок для телепорта" or "传送目标玩家", gameplayConfig.vehicleTpTarget, function(name)
        gameplayConfig.vehicleTpTarget = name
    end)
    local btn = create("TextButton", {
        Size = UDim2.new(1, -28, 0, 36), Position = UDim2.new(0, 14, 0, cy + 4),
        BackgroundColor3 = COLORS.off, Text = "", AutoButtonColor = false,
        Parent = panel,
    })
    corner(btn, 7)
    stroke(btn, COLORS.stroke, 0.5)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Телепортироваться сейчас" or "立即传送",
        TextColor3 = COLORS.accent, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center, Parent = btn,
    })
    btn.Activated:Connect(function()
        HUD.teleportVehicleToPlayer()
    end)
    btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = COLORS.hover }, 0.1) end)
    btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = COLORS.off }, 0.1) end)
end

MODULE_SETTINGS_OPENERS["Target ESP"] = function(anchorRow)
    local panel, cy = createCustomPanel("Target ESP", 260, 230)
    cy = createPlayerPickerRow(panel, cy, "Target Player for ESP", gameplayConfig.targetEspName, function(name) gameplayConfig.targetEspName = name end)
    cy = createPanelSlider(panel, cy, "Orbit Size", 1, 12, gameplayConfig.targetEspSize, 0.5, function(value) gameplayConfig.targetEspSize = value end)
    createPanelSlider(panel, cy, "Orbit Speed", 0.5, 8, gameplayConfig.targetEspSpin, 0.5, function(value) gameplayConfig.targetEspSpin = value end)
end

MODULE_SETTINGS_OPENERS["Teleport"] = function(anchorRow)
    local panel, cy = createCustomPanel("Teleport", 260, 160)
    createPlayerPickerRow(panel, cy, "Player to Teleport", gameplayConfig.teleportTarget, function(name) gameplayConfig.teleportTarget = name end)
end

MODULE_SETTINGS_OPENERS["Pull Player"] = function(anchorRow)
    local panel, cy = createCustomPanel("Pull Player", 260, 160)
    createPlayerPickerRow(panel, cy, "Player to Pull to Me", gameplayConfig.pullTarget, function(name) gameplayConfig.pullTarget = name end)
end

MODULE_SETTINGS_OPENERS["Fling"] = function(anchorRow)
    local panel, cy = createCustomPanel("Fling Target", 260, 140)
    createPlayerPickerRow(panel, cy, "Fling Target Player", gameplayConfig.flingTarget, function(name) gameplayConfig.flingTarget = name end)
end

MODULE_SETTINGS_OPENERS["Escape"] = function(anchorRow)
    local panel, cy = createCustomPanel("Escape Auto-Flee", 260, 170)
    cy = createPanelSlider(panel, cy, "Health Threshold", 1, 99, gameplayConfig.escapeHealth, 1, function(value) gameplayConfig.escapeHealth = value end)
    createPanelSlider(panel, cy, "Escape Distance", 20, 200, gameplayConfig.escapeDistance, 5, function(value) gameplayConfig.escapeDistance = value end)
end

MODULE_SETTINGS_OPENERS["Admin Panel"] = function(anchorRow, onClose)
    local panel, cy = createCustomPanel("Admin System", 280, 290, onClose)

    local function runAdminAction(actionName, callback)
        local ok, err = pcall(callback)
        if ok then
            HUD.notify(actionName .. ": запущено", "success")
        else
            warn("Solara " .. actionName .. " failed:", err)
            HUD.notify(actionName .. ": ошибка запуска", "error", 3.5)
        end
    end

    local function runRemoteScript(actionName, url)
        runAdminAction(actionName, function()
            if type(loadstring) ~= "function" then error("loadstring is unavailable in this environment") end
            local source = game:HttpGet(url)
            local chunk, compileError = loadstring(source)
            if not chunk then error(compileError or "remote script compilation failed") end
            chunk()
        end)
    end

    local function createAdminBtn(text, subtext, color, onClick)
        local btn = create("TextButton", {
            Size = UDim2.new(1, -28, 0, 38), Position = UDim2.new(0, 14, 0, cy),
            BackgroundColor3 = COLORS.off, Text = "", AutoButtonColor = false,
            Parent = panel,
        })
        corner(btn, 7)
        local bStroke = stroke(btn, COLORS.stroke, 0.5)
        create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 10, 0, 3),
            BackgroundTransparency = 1, Text = text,
            TextColor3 = color or COLORS.text, Font = Enum.Font.GothamBold, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
        })
        if subtext then
            create("TextLabel", {
                Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 10, 0, 20),
                BackgroundTransparency = 1, Text = subtext,
                TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
            })
        end
        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = COLORS.hover }, 0.12)
            bStroke.Color = COLORS.accent
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = COLORS.off }, 0.12)
            bStroke.Color = COLORS.stroke
        end)
        btn.MouseButton1Click:Connect(function()
            tween(btn, { Size = UDim2.new(1, -32, 0, 36) }, 0.05).Completed:Connect(function()
                tween(btn, { Size = UDim2.new(1, -28, 0, 38) }, 0.1)
            end)
            if onClick then onClick() end
        end)
        cy = cy + 44
        return btn
    end

    createAdminBtn("[+] Infinite Yield", "Universal Admin (500+ commands)", COLORS.accent, function()
        runRemoteScript("Infinite Yield", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    end)

    createAdminBtn("[+] Dark Dex Explorer", "Game Object Explorer & Inspector", COLORS.text, function()
        runRemoteScript("Dark Dex", "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")
    end)

    createAdminBtn("[+] SimpleSpy Remote Spy", "RemoteEvent Logger & Interceptor", COLORS.text, function()
        runRemoteScript("SimpleSpy", "https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua")
    end)

    createAdminBtn("[~] Rejoin Server", "Rejoin the current server", COLORS.textDim, function()
        runAdminAction("Rejoin", function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
    end)

    createAdminBtn("[~] Server Hop", "Find and join a different server", COLORS.textDim, function()
        runAdminAction("Server Hop", function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            local foundServer = false
            for _, s in ipairs(servers.data or {}) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    foundServer = true
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player)
                    break
                end
            end
            if not foundServer then error("no available server found") end
        end)
    end)
end


----------------------------------------------------------------
-- THEME MANAGER WINDOW
----------------------------------------------------------------
 
local themeCards = {}
 
local function closeThemeManager()
    if activeThemeManager then
        local mgr = activeThemeManager
        activeThemeManager = nil
        local mainBg = mgr:FindFirstChild("MainBg")
        local overlay = screenGui:FindFirstChild("ThemeManagerOverlay")
        if overlay then tween(overlay, { BackgroundTransparency = 1 }, 0.2).Completed:Connect(function() overlay:Destroy() end) end
        local t = tween(mgr, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quad)
        if mainBg then tween(mainBg, { Size = UDim2.new(0, 740, 0, 480) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In) end
        t.Completed:Connect(function()
            mgr:Destroy()
        end)
        themeCards = {}
        _refreshThemeCards = nil
    end
end
 
local function openThemeManager(anchorRow)
    closeThemeManager()
    closeSettingsPanel()
    if HUD.closeSettings then HUD.closeSettings() end
    if closeColorPicker then closeColorPicker() end
    if themeDockOpen and toggleThemeDock then toggleThemeDock() end
 
    local overlay = create("TextButton", {
        Name = "ThemeManagerOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 80,
        Parent = screenGui,
    })
 
    local mgr = create("CanvasGroup", {
        Name = "ThemeManager",
        Size = UDim2.new(0, 760, 0, 500),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 81,
        Parent = screenGui,
    })
    activeThemeManager = mgr
    local themeViewport = getViewportSize()
    create("UIScale", { Scale = math.min(1, (themeViewport.X - 24) / 760, (themeViewport.Y - 24) / 500), Parent = mgr })
 
 
    local mainBg = create("Frame", {
        Name = "MainBg",
        Size = UDim2.new(0, 760, 0, 500),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = COLORS.panel,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = mgr,
    })
    corner(mainBg, 18)
    local mainStroke = stroke(mainBg, COLORS.stroke, 1)
    mainStroke.Thickness = 1.5
 
 
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = COLORS.panelAlt,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Parent = mainBg,
    })
    corner(header, 12)
 
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = COLORS.stroke,
        BorderSizePixel = 0,
        Parent = header,
    })
 
    local _title = create("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 24),
        Position = UDim2.new(0, 24, 0, 12),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "界面主题" or "界面主题",
        TextColor3 = COLORS.header,
        Font = Enum.Font.GothamSemibold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
 
    local _subtitle = create("TextLabel", {
        Size = UDim2.new(0.8, 0, 0, 16),
        Position = UDim2.new(0, 24, 0, 38),
        BackgroundTransparency = 1,
        Text = "选择主题后界面会立即更新。",
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
 
    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -48, 0, 16),
        BackgroundColor3 = COLORS.off,
        Text = "×",
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 18,
        AutoButtonColor = false,
        Parent = header,
    })
    corner(closeBtn, 8)
    local _closeStroke = stroke(closeBtn, COLORS.stroke, 1)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = COLORS.hover, TextColor3 = COLORS.text }, 0.15)
        tween(closeBtn, { Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, -49, 0, 15) }, 0.12, Enum.EasingStyle.Back)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = COLORS.off, TextColor3 = COLORS.textDim }, 0.15)
        tween(closeBtn, { Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, -48, 0, 16) }, 0.12)
    end)
    closeBtn.MouseButton1Click:Connect(closeThemeManager)
 
    local content = create("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -32, 1, -64 - 56),
        Position = UDim2.new(0, 16, 0, 64),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = mainBg,
    })
    create("UIGridLayout", {
        CellSize = UDim2.new(0, 350, 0, 92),
        CellPadding = UDim2.new(0, 12, 0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = content,
    })
 
    local footer = create("Frame", {
        Size = UDim2.new(1, -32, 0, 40),
        Position = UDim2.new(0, 16, 1, -48),
        BackgroundColor3 = COLORS.panelAlt,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = mainBg,
    })
    corner(footer, 10)
    local footerLabel = create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "当前主题：默认黑色",
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })
 
    themeCards = {}
 
    local function buildThemeCard(themeName, order)
        local theme = THEMES[themeName]
        local card = create("TextButton", {
            Name = themeName,
            Size = UDim2.new(0, 350, 0, 92),
            BackgroundColor3 = COLORS.panelAlt,
            BackgroundTransparency = 0.1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = content,
        })
        corner(card, 10)
        local cardStroke = stroke(card, COLORS.stroke, 1)
 
        local cardGlow = create("ImageLabel", {
            Size = UDim2.new(1, 30, 1, 30),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://5028857084",
            ImageColor3 = theme.accent,
            ImageTransparency = 1,
            ZIndex = 0,
            themeBind = false,
            Parent = card,
        })
 
        local previewHolder = create("Frame", {
            Size = UDim2.new(0, 84, 0, 60),
            Position = UDim2.new(0, 12, 0.5, -30),
            BackgroundTransparency = 1,
            Parent = card,
        })
        corner(previewHolder, 8)
        local _previewStroke = stroke(previewHolder, COLORS.stroke, 1)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 3),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = previewHolder,
        })
        for _, col in ipairs(theme.preview) do
            local blk = create("Frame", {
                Size = UDim2.new(0, 12, 0, 44),
                BackgroundColor3 = col,
                BorderSizePixel = 0,
                Parent = previewHolder,
            })
            corner(blk, 3)
        end
 
        local _nameLabel = create("TextLabel", {
            Size = UDim2.new(1, -120, 0, 22),
            Position = UDim2.new(0, 108, 0, 14),
            BackgroundTransparency = 1,
            Text = theme.label,
            TextColor3 = COLORS.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
 
        local _descLabel = create("TextLabel", {
            Size = UDim2.new(1, -120, 0, 32),
            Position = UDim2.new(0, 108, 0, 38),
            BackgroundTransparency = 1,
            Text = theme.desc,
            TextColor3 = COLORS.textDim,
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card,
        })
 
        local checkHolder = create("Frame", {
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -34, 0, 12),
            BackgroundColor3 = COLORS.off,
            BorderSizePixel = 0,
            Parent = card,
        })
        corner(checkHolder, 6)
        local checkStroke = stroke(checkHolder, COLORS.stroke, 1)
 
        local checkIcon = create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "✓",
            TextColor3 = COLORS.accent,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextTransparency = 1,
            Parent = checkHolder,
        })
 
        local entry = {
            card = card, stroke = cardStroke, glow = cardGlow,
            checkHolder = checkHolder, checkStroke = checkStroke, checkIcon = checkIcon,
            accent = theme.accent, name = themeName,
        }
        themeCards[themeName] = entry
 
        card.MouseEnter:Connect(function()
            tween(card, { Size = UDim2.new(0, 354, 0, 96), BackgroundTransparency = 0.0 }, 0.18, Enum.EasingStyle.Back)
            tween(cardStroke, { Color = entry.accent, Thickness = 1.5 }, 0.18)
            tween(cardGlow, { ImageTransparency = 0.82 }, 0.2)
        end)
        card.MouseLeave:Connect(function()
            if currentTheme ~= themeName then
                tween(card, { Size = UDim2.new(0, 350, 0, 92), BackgroundTransparency = 0.1 }, 0.18, Enum.EasingStyle.Back)
                tween(cardStroke, { Color = COLORS.stroke, Thickness = 1 }, 0.18)
                tween(cardGlow, { ImageTransparency = 1 }, 0.2)
            end
        end)
 
        card.MouseButton1Click:Connect(function()
            if currentTheme == themeName then return end
            ApplyTheme(themeName)
        end)
 
        return entry
    end
 
    for i, themeName in ipairs(THEME_ORDER) do
        buildThemeCard(themeName, i)
    end
 
    _refreshThemeCards = function(selectedName)
        for name, e in pairs(themeCards) do
            local isActive = (name == selectedName)
            if isActive then
                tween(e.stroke, { Color = e.accent, Thickness = 1.5 }, 0.2)
                tween(e.glow, { ImageTransparency = 0.8 }, 0.25)
                tween(e.checkHolder, { BackgroundColor3 = e.accent }, 0.2)
                tween(e.checkStroke, { Color = e.accent }, 0.2)
                tween(e.checkIcon, { TextTransparency = 0, TextColor3 = THEMES[name].panel }, 0.2)
            else
                tween(e.stroke, { Color = COLORS.stroke, Thickness = 1 }, 0.2)
                tween(e.glow, { ImageTransparency = 1 }, 0.25)
                tween(e.checkHolder, { BackgroundColor3 = COLORS.off }, 0.2)
                tween(e.checkStroke, { Color = COLORS.stroke }, 0.2)
                tween(e.checkIcon, { TextTransparency = 1 }, 0.2)
            end
        end
        footerLabel.Text = "Текущая тема: " .. (THEMES[selectedName] and THEMES[selectedName].label or selectedName)
    end
 
    overlay.MouseButton1Click:Connect(closeThemeManager)
 
    tween(mgr, { GroupTransparency = 0 }, 0.28, Enum.EasingStyle.Quad)
    mainBg.Size = UDim2.new(0, 740, 0, 480)
    tween(mainBg, { Size = UDim2.new(0, 760, 0, 500) }, 0.4, Enum.EasingStyle.Back)
 
    _refreshThemeCards(currentTheme)
end
 
----------------------------------------------------------------
-- Настройки оформления внизу боковой панели.
----------------------------------------------------------------
 
themeDockOpen = false
 
themeFabButton = create("TextButton", {
    Name = "ThemeManagerFab",
    Size = UDim2.new(1, -24, 0, 38),
    Position = UDim2.new(0, 12, 1, -54),
    BackgroundColor3 = COLORS.panelAlt,
    Text = "    外观",
    TextColor3 = COLORS.text,
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false,
    Visible = false, -- показывается только когда меню открыто
    Parent = HUD.sidebar,
})
corner(themeFabButton, 9)
 
do
local fabSquareStroke = Instance.new("UIStroke")
fabSquareStroke.Color = COLORS.stroke
fabSquareStroke.Thickness = 1
fabSquareStroke.Parent = themeFabButton
bindTheme(fabSquareStroke, "Color", "stroke")
 
-- Кружок по центру чёрного квадрата (сплошной акцентный цвет, без радуги)
local fabCircle = create("Frame", {
    Name = "FabCircle",
    Size = UDim2.new(0, 10, 0, 10),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 20, 0.5, 0),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Parent = themeFabButton,
})
corner(fabCircle, 11) -- идеальный круг
 
local themeFabStroke = Instance.new("UIStroke")
themeFabStroke.Color = Color3.fromRGB(255, 255, 255)
themeFabStroke.Thickness = 1
themeFabStroke.Transparency = 0.4
themeFabStroke.Parent = fabCircle
 
themeFabButton.MouseEnter:Connect(function()
    tween(themeFabButton, { BackgroundColor3 = COLORS.hover }, 0.18)
    tween(fabSquareStroke, { Transparency = 0 }, 0.18)
end)
themeFabButton.MouseLeave:Connect(function()
    tween(themeFabButton, { BackgroundColor3 = COLORS.panelAlt }, 0.18)
    tween(fabSquareStroke, { Transparency = 0.3 }, 0.18)
end)
end
 
themeFabButton.MouseButton1Click:Connect(function()
    toggleThemeDock()
end)
HUD.themeLibraryButton.Activated:Connect(function() openThemeManager() end)
 
----------------------------------------------------------------
-- ЖИВОЙ ЦВЕТОВОЙ ПИКЕР (SV-квадрат + полоса Hue)
-- Обобщённый: принимает начальный цвет и callback onChange(Color3),
-- ничего не пишет напрямую в COLORS — вызывающий код сам решает,
-- куда применить новый цвет (в тему, в HUD, и т.д.)
----------------------------------------------------------------
 
local activeColorPicker
 
closeColorPicker = function()
    if activeColorPicker then
        local p = activeColorPicker
        activeColorPicker = nil
        if activePointerDrag and activePointerDrag.owner:IsDescendantOf(p) then
            activePointerDrag = nil
        end
        local t = tween(p, { GroupTransparency = 1 }, 0.15)
        t.Completed:Connect(function() p:Destroy() end)
    end
end
 
-- initialColor: Color3 с которого стартует пикер.
-- onChange: function(newColor: Color3) — вызывается при каждом изменении.
-- anchorButton: swatch, рядом с которым открыть пикер.
local function openColorPicker(anchorButton, initialColor, labelText, onChange)
    closeColorPicker()
 
    local h, s, v = initialColor:ToHSV()
 
    local popup = create("CanvasGroup", {
        Name = "ColorPicker",
        Size = UDim2.new(0, 200, 0, 232),
        BackgroundTransparency = 1,
        GroupTransparency = 0,
        ZIndex = 95,
        Parent = screenGui,
    })
    activeColorPicker = popup
 
    -- Позиционируем слева от кнопки-свотча, чтобы не улетать за край экрана.
    local abs = anchorButton.AbsolutePosition
    local viewport = getViewportSize()
    local popupX = math.clamp(abs.X - 210, 8, math.max(8, viewport.X - 208))
    local popupY = math.clamp(abs.Y - 90, 8, math.max(8, viewport.Y - 240))
    popup.Position = UDim2.new(0, popupX, 0, popupY)
 
    local bg = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = COLORS.panelAlt,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Parent = popup,
    })
    corner(bg, 12)
    stroke(bg, COLORS.stroke, 1)
 
    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = bg,
    })
 
    -- ═══ SV-квадрат ═══
    local sq = create("Frame", {
        Size = UDim2.new(0, 176, 0, 140),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        themeBind = false,
        Parent = bg,
    })
    corner(sq, 8)
 
    local whiteOverlay = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        themeBind = false,
        Parent = sq,
    })
    local whiteGrad = Instance.new("UIGradient")
    whiteGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    whiteGrad.Parent = whiteOverlay
 
    local blackOverlay = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        themeBind = false,
        Parent = sq,
    })
    local blackGrad = Instance.new("UIGradient")
    blackGrad.Rotation = 90
    blackGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    blackGrad.Parent = blackOverlay
 
    local svCursor = create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 5,
        themeBind = false,
        Parent = sq,
    })
    corner(svCursor, 6)
    local svCursorStroke = Instance.new("UIStroke")
    svCursorStroke.Color = Color3.fromRGB(0, 0, 0)
    svCursorStroke.Thickness = 1.5
    svCursorStroke.Parent = svCursor
 
    -- ═══ Полоса Hue ═══
    local hueBar = create("Frame", {
        Size = UDim2.new(0, 176, 0, 16),
        Position = UDim2.new(0, 12, 0, 182),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        themeBind = false,
        Parent = bg,
    })
    corner(hueBar, 8)
    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0/6, 1, 1)),
        ColorSequenceKeypoint.new(1/6,  Color3.fromHSV(1/6, 1, 1)),
        ColorSequenceKeypoint.new(2/6,  Color3.fromHSV(2/6, 1, 1)),
        ColorSequenceKeypoint.new(3/6,  Color3.fromHSV(3/6, 1, 1)),
        ColorSequenceKeypoint.new(4/6,  Color3.fromHSV(4/6, 1, 1)),
        ColorSequenceKeypoint.new(5/6,  Color3.fromHSV(5/6, 1, 1)),
        ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
    })
    hueGrad.Parent = hueBar
 
    local hueCursor = create("Frame", {
        Size = UDim2.new(0, 4, 1, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 5,
        themeBind = false,
        Parent = hueBar,
    })
    corner(hueCursor, 2)
    local hueCursorStroke = Instance.new("UIStroke")
    hueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
    hueCursorStroke.Thickness = 1.5
    hueCursorStroke.Parent = hueCursor
 
    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0, 6),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        Parent = bg,
    })
    closeBtn.MouseButton1Click:Connect(closeColorPicker)
 
    local function pushColor()
        local newColor = Color3.fromHSV(h, s, v)
        if onChange then onChange(newColor) end
    end
 
    local function updateSV(inputPos)
        local rel = Vector2.new(inputPos.X, inputPos.Y) - sq.AbsolutePosition
        s = math.clamp(rel.X / sq.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp(rel.Y / sq.AbsoluteSize.Y, 0, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        pushColor()
    end
 
    local function updateHue(inputPos)
        local rel = (inputPos.X - hueBar.AbsolutePosition.X)
        h = math.clamp(rel / hueBar.AbsoluteSize.X, 0, 1)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        sq.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        pushColor()
    end
 
    bindPointerDrag(sq, updateSV)
    bindPointerDrag(hueBar, updateHue)
end
 
----------------------------------------------------------------
-- ПАНЕЛЬ "ТЕМЫ" (докована в правом нижнем углу экрана)
----------------------------------------------------------------
 
local SAVED_THEMES = {
    { name = "Default", colors = { panel = COLORS.panel, panelAlt = COLORS.panelAlt, header = COLORS.header,
        text = COLORS.text, textDim = COLORS.textDim, stroke = COLORS.stroke, accent = COLORS.accent,
        off = COLORS.off, hover = COLORS.hover } },
}
 
local function ApplySavedTheme(snap)
    for key, val in pairs(snap) do
        if COLORS[key] ~= nil then COLORS[key] = val end
    end
    currentTheme = "Custom"
    applyBindings(COLORS)
    if refreshHudColors then refreshHudColors() end
    if _refreshThemeCards then _refreshThemeCards("Custom") end
end
 
local hudTranspFill, hudTranspValLabel
local HUD_TRANSP_MAX = 0.9
local refreshModuleTransparency
do
    themeDock = create("CanvasGroup", {
        Name = "ThemeDock",
        Size = UDim2.new(0, 220, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -22, 1, -88),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 55,
        Parent = screenGui,
    })
 
local themeDockBg = create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Parent = themeDock,
})
corner(themeDockBg, 12)
stroke(themeDockBg, COLORS.stroke, 1)
 
create("UIPadding", {
    PaddingTop = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    Parent = themeDockBg,
})
 
create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = themeDockBg,
})
 
-- ── Заголовок ──
local dockHeader = create("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
    Parent = themeDockBg,
})
create("TextLabel", {
    Size = UDim2.new(1, -24, 1, 0),
    BackgroundTransparency = 1,
    Text = "主题",
    TextColor3 = COLORS.header,
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = dockHeader,
})
local dockCloseBtn = create("TextButton", {
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(1, -20, 0, 0),
    BackgroundTransparency = 1,
    Text = "×",
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 16,
    Parent = dockHeader,
})
 
-- ── Ввод названия + кнопка добавления ──
local dockAddRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    Parent = themeDockBg,
})
local dockNameBox = create("TextBox", {
    Size = UDim2.new(1, -34, 1, 0),
    BackgroundColor3 = COLORS.off,
    Text = "",
    PlaceholderText = "输入名称",
    PlaceholderColor3 = COLORS.textDim,
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    ClearTextOnFocus = false,
    Parent = dockAddRow,
})
corner(dockNameBox, 6)
stroke(dockNameBox, COLORS.stroke, 1)
create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = dockNameBox })
 
local dockAddBtn = create("TextButton", {
    Size = UDim2.new(0, 26, 1, 0),
    Position = UDim2.new(1, -26, 0, 0),
    BackgroundColor3 = COLORS.accent,
    Text = "+",
    TextColor3 = COLORS.panel,
    Font = Enum.Font.GothamSemibold,
    TextSize = 16,
    AutoButtonColor = false,
    Parent = dockAddRow,
})
corner(dockAddBtn, 6)
 
-- ── Ряд сохранённых тем (кружки) ──
local dockDotsRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
    Parent = themeDockBg,
})
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Parent = dockDotsRow,
})
 
local dockDots = {}
local selectedDotIndex = 1
 
local function refreshDockDots()
    for i, entry in ipairs(dockDots) do
        local isSelected = (i == selectedDotIndex)
        tween(entry.ring, { Transparency = isSelected and 0 or 1 }, 0.15)
    end
end
 
local function addThemeDot(name, snap)
    local dot = create("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = snap.accent,
        BorderSizePixel = 0,
        LayoutOrder = #dockDots + 1,
        themeBind = false,
        Parent = dockDotsRow,
    })
    corner(dot, 9)
    local ring = Instance.new("UIStroke")
    ring.Color = Color3.fromRGB(255, 255, 255)
    ring.Thickness = 2
    ring.Transparency = 1
    ring.Parent = dot
 
    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = dot,
    })
    btn.MouseButton1Click:Connect(function()
        for i, entry in ipairs(dockDots) do
            if entry.dot == dot then selectedDotIndex = i end
        end
        refreshDockDots()
        ApplySavedTheme(snap)
    end)
 
    table.insert(dockDots, { dot = dot, ring = ring, name = name, snap = snap })
end
 
for _, t in ipairs(SAVED_THEMES) do
    addThemeDot(t.name, t.colors)
end
refreshDockDots()
 
dockAddBtn.MouseButton1Click:Connect(function()
    local nm = dockNameBox.Text ~= "" and dockNameBox.Text or ("Тема " .. tostring(#SAVED_THEMES + 1))
    local snap = { panel = COLORS.panel, panelAlt = COLORS.panelAlt, header = COLORS.header,
        text = COLORS.text, textDim = COLORS.textDim, stroke = COLORS.stroke, accent = COLORS.accent,
        off = COLORS.off, hover = COLORS.hover }
    table.insert(SAVED_THEMES, { name = nm, colors = snap })
    addThemeDot(nm, snap)
    selectedDotIndex = #dockDots
    refreshDockDots()
    dockNameBox.Text = ""
end)
 
-- ── Секция "颜色" ──
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "颜色",
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 4,
    Parent = themeDockBg,
})
 
do
local COLOR_ROWS = {
    { label = "强调色",         key = "accent" },
    { label = "背景",            key = "panel" },
    { label = "辅助色", key = "panelAlt" },
    { label = "文字",          key = "text" },
    { label = "描边",        key = "stroke" },
}
 
for i, entry in ipairs(COLOR_ROWS) do
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = 4 + i,
        Parent = themeDockBg,
    })
    create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = entry.label,
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local swatch = create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0.5, -10),
        BackgroundColor3 = COLORS[entry.key],
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    corner(swatch, 10)
    stroke(swatch, COLORS.stroke, 1)
    bindTheme(swatch, "BackgroundColor3", entry.key) -- явная привязка (защита от совпадения цветов при авто-детекте)
    swatch.MouseButton1Click:Connect(function()
        openColorPicker(swatch, COLORS[entry.key], entry.label, function(newColor)
            COLORS[entry.key] = newColor
            currentTheme = "Custom"
            applyBindings(COLORS)
            if refreshHudColors then refreshHudColors() end
            if _refreshThemeCards then _refreshThemeCards("Custom") end
        end)
    end)
end
end
 
-- ── Секция "其他" ──
create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "其他",
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 10,
    Parent = themeDockBg,
})
 
do
local animRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    LayoutOrder = 11,
    Parent = themeDockBg,
})
create("TextLabel", {
    Size = UDim2.new(1, -40, 1, 0),
    BackgroundTransparency = 1,
    Text = "动画",
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = animRow,
})
local animToggle = create("TextButton", {
    Size = UDim2.new(0, 34, 0, 18),
    Position = UDim2.new(1, -34, 0.5, -9),
    BackgroundColor3 = COLORS.accent,
    Text = "",
    AutoButtonColor = false,
    Parent = animRow,
})
corner(animToggle, 9)
local animKnob = create("Frame", {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(1, -16, 0.5, -7),
    BackgroundColor3 = COLORS.panel,
    themeBind = false,
    Parent = animToggle,
})
corner(animKnob, 7)
animToggle.MouseButton1Click:Connect(function()
    animationsEnabled = not animationsEnabled
    local goalPos = animationsEnabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local goalColor = animationsEnabled and COLORS.accent or COLORS.off
    TweenService:Create(animKnob, TweenInfo.new(0.15), { Position = goalPos }):Play()
    TweenService:Create(animToggle, TweenInfo.new(0.15), { BackgroundColor3 = goalColor }):Play()
end)
end
 
-- ── Слайдер: Сила блюра заднего фона (Lighting, не GUI) ──
do
local blurRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = COLORS.off,
    BackgroundTransparency = 0.1,
    LayoutOrder = 13,
    Parent = themeDockBg,
})
corner(blurRow, 8)
stroke(blurRow, COLORS.stroke, 0.5)
 
create("TextLabel", {
    Size = UDim2.new(0.6, 0, 0, 16),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundTransparency = 1,
    Text = "背景模糊",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = blurRow,
})
local blurValLabel = create("TextLabel", {
    Size = UDim2.new(0.35, -8, 0, 16),
    Position = UDim2.new(0.65, 0, 0, 4),
    BackgroundTransparency = 1,
    Text = tostring(backgroundBlurAmount),
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = blurRow,
})
local blurBar = create("Frame", {
    Size = UDim2.new(1, -16, 0, 6),
    Position = UDim2.new(0, 8, 0, 24),
    BackgroundColor3 = COLORS.panel,
    Parent = blurRow,
})
corner(blurBar, 3)
stroke(blurBar, COLORS.stroke, 0.5)
local BLUR_MIN, BLUR_MAX = 0, 32
local blurFill = create("Frame", {
    Size = UDim2.new((backgroundBlurAmount - BLUR_MIN) / (BLUR_MAX - BLUR_MIN), 0, 1, 0),
    BackgroundColor3 = COLORS.accent,
    Parent = blurBar,
})
corner(blurFill, 3)
 
local function updateBlurSlider(inputPos)
    local rel = math.clamp((inputPos.X - blurBar.AbsolutePosition.X) / blurBar.AbsoluteSize.X, 0, 1)
    tween(blurFill, { Size = UDim2.new(rel, 0, 1, 0) }, 0.05)
    backgroundBlurAmount = math.floor((BLUR_MIN + (BLUR_MAX - BLUR_MIN) * rel) + 0.5)
    blurValLabel.Text = tostring(backgroundBlurAmount)
    if menuOpen then
        blurEffect.Size = backgroundBlurAmount
    end
end
bindPointerDrag(blurBar, updateBlurSlider)
end
 
-- ── Слайдер: Прозрачность модулей (строк в колонках) ──
do
local moduleTranspRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = COLORS.off,
    BackgroundTransparency = 0.1,
    LayoutOrder = 14,
    Parent = themeDockBg,
})
corner(moduleTranspRow, 8)
stroke(moduleTranspRow, COLORS.stroke, 0.5)
 
create("TextLabel", {
    Size = UDim2.new(0.6, 0, 0, 16),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundTransparency = 1,
    Text = "功能卡片透明度",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = moduleTranspRow,
})
local moduleTranspValLabel = create("TextLabel", {
    Size = UDim2.new(0.35, -8, 0, 16),
    Position = UDim2.new(0.65, 0, 0, 4),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = moduleTranspRow,
})
local moduleTranspBar = create("Frame", {
    Size = UDim2.new(1, -16, 0, 6),
    Position = UDim2.new(0, 8, 0, 24),
    BackgroundColor3 = COLORS.panel,
    Parent = moduleTranspRow,
})
corner(moduleTranspBar, 3)
stroke(moduleTranspBar, COLORS.stroke, 0.5)
local MODULE_TRANSP_MAX = 0.9 -- ограничиваем максимум 90%, чтобы текст не пропадал совсем
local moduleTranspFill = create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = COLORS.accent,
    Parent = moduleTranspBar,
})
corner(moduleTranspFill, 3)
 
local function updateModuleTranspSlider(inputPos)
    local rel = math.clamp((inputPos.X - moduleTranspBar.AbsolutePosition.X) / moduleTranspBar.AbsoluteSize.X, 0, 1)
    tween(moduleTranspFill, { Size = UDim2.new(rel, 0, 1, 0) }, 0.05)
    moduleTransparency = rel * MODULE_TRANSP_MAX
    moduleTranspValLabel.Text = tostring(math.floor(moduleTransparency * 100)) .. "%"
    if refreshModuleTransparency then refreshModuleTransparency() end
end
bindPointerDrag(moduleTranspBar, updateModuleTranspSlider)
end
 
-- ── Слайдер: Прозрачность фона HUD ──
do
local hudTranspRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = COLORS.off,
    BackgroundTransparency = 0.1,
    LayoutOrder = 15,
    Parent = themeDockBg,
})
corner(hudTranspRow, 8)
stroke(hudTranspRow, COLORS.stroke, 0.5)
 
create("TextLabel", {
    Size = UDim2.new(0.6, 0, 0, 16),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundTransparency = 1,
    Text = "HUD 透明度",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = hudTranspRow,
})
hudTranspValLabel = create("TextLabel", {
    Size = UDim2.new(0.35, -8, 0, 16),
    Position = UDim2.new(0.65, 0, 0, 4),
    BackgroundTransparency = 1,
    Text = "8%",
    TextColor3 = COLORS.textDim,
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = hudTranspRow,
})
local hudTranspBar = create("Frame", {
    Size = UDim2.new(1, -16, 0, 6),
    Position = UDim2.new(0, 8, 0, 24),
    BackgroundColor3 = COLORS.panel,
    Parent = hudTranspRow,
})
corner(hudTranspBar, 3)
stroke(hudTranspBar, COLORS.stroke, 0.5)
hudTranspFill = create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = COLORS.accent,
    Parent = hudTranspBar,
})
corner(hudTranspFill, 3)
 
-- Заполняется реальным значением после того как hudColorState будет создан (см. ниже).
local function updateHudTranspSlider(inputPos)
    local rel = math.clamp((inputPos.X - hudTranspBar.AbsolutePosition.X) / hudTranspBar.AbsoluteSize.X, 0, 1)
    tween(hudTranspFill, { Size = UDim2.new(rel, 0, 1, 0) }, 0.05)
    local value = rel * HUD_TRANSP_MAX
    hudTranspValLabel.Text = tostring(math.floor(value * 100)) .. "%"
    if _setHudBgTransparency then _setHudBgTransparency(value) end
end
bindPointerDrag(hudTranspBar, updateHudTranspSlider)
end
 
-- ── Секция: Эффекты оформления UI (Liquid Glass) ──
do
    local effectsHeader = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "ЭФФЕКТЫ И СТЕКЛО" or "界面与玻璃效果",
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 15,
        Parent = themeDockBg,
    })

    local glassToggleBtn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = COLORS.off,
        Text = (guiStyle == "LiquidGlass") and (CURRENT_LANG == "RU" and "Liquid Glass: ВКЛ" or "液态玻璃：开") or (CURRENT_LANG == "RU" and "Liquid Glass: ВЫКЛ" or "液态玻璃：关"),
        TextColor3 = (guiStyle == "LiquidGlass") and COLORS.accent or COLORS.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        AutoButtonColor = false,
        LayoutOrder = 16,
        Parent = themeDockBg,
    })
    corner(glassToggleBtn, 6)
    stroke(glassToggleBtn, COLORS.stroke, 1)
    glassToggleBtn.MouseButton1Click:Connect(function()
        guiStyle = (guiStyle == "Normal") and "LiquidGlass" or "Normal"
        if gameplayConfig.uiEffects then gameplayConfig.uiEffects.liquidGlass = (guiStyle == "LiquidGlass") end
        glassToggleBtn.Text = (guiStyle == "LiquidGlass") and (CURRENT_LANG == "RU" and "Liquid Glass: ВКЛ" or "液态玻璃：开") or (CURRENT_LANG == "RU" and "Liquid Glass: ВЫКЛ" or "液态玻璃：关")
        glassToggleBtn.TextColor3 = (guiStyle == "LiquidGlass") and COLORS.accent or COLORS.text
        applyGuiStyle()
    end)

    local reflToggleBtn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = COLORS.off,
        Text = (gameplayConfig.uiEffects and gameplayConfig.uiEffects.reflections ~= false) and (CURRENT_LANG == "RU" and "Световые блики: ВКЛ" or "反射效果：开") or (CURRENT_LANG == "RU" and "Световые блики: ВЫКЛ" or "反射效果：关"),
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutoButtonColor = false,
        LayoutOrder = 17,
        Parent = themeDockBg,
    })
    corner(reflToggleBtn, 6)
    stroke(reflToggleBtn, COLORS.stroke, 1)
    reflToggleBtn.MouseButton1Click:Connect(function()
        if not gameplayConfig.uiEffects then gameplayConfig.uiEffects = {} end
        gameplayConfig.uiEffects.reflections = not (gameplayConfig.uiEffects.reflections ~= false)
        local act = gameplayConfig.uiEffects.reflections
        reflToggleBtn.Text = act and (CURRENT_LANG == "RU" and "Световые блики: ВКЛ" or "反射效果：开") or (CURRENT_LANG == "RU" and "Световые блики: ВЫКЛ" or "反射效果：关")
        reflToggleBtn.TextColor3 = act and COLORS.accent or COLORS.textDim
    end)
end

-- ── Кнопка перехода в галерею готовых тем ──
do
local browseBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = COLORS.off,
    Text = "全部主题",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    AutoButtonColor = false,
    LayoutOrder = 16,
    Parent = themeDockBg,
})
corner(browseBtn, 6)
stroke(browseBtn, COLORS.stroke, 1)
browseBtn.MouseEnter:Connect(function() tween(browseBtn, { BackgroundColor3 = COLORS.hover }, 0.15) end)
browseBtn.MouseLeave:Connect(function() tween(browseBtn, { BackgroundColor3 = COLORS.off }, 0.15) end)
browseBtn.MouseButton1Click:Connect(function()
    openThemeManager()
end)
end
 
toggleThemeDock = function()
    closeColorPicker()
    themeDockOpen = not themeDockOpen
    if themeDockOpen then
        closeSettingsPanel()
        if HUD.closeSettings then HUD.closeSettings() end
        closeThemeManager()
        local viewport = getViewportSize()
        local unscaledHeight = themeDock.AbsoluteSize.Y / (HUD.themeDockScale and HUD.themeDockScale.Scale or 1)
        local scale = math.min(1, (viewport.Y - 32) / math.max(1, unscaledHeight))
        if not HUD.themeDockScale then HUD.themeDockScale = create("UIScale", { Scale = 1, Parent = themeDock }) end
        HUD.themeDockScale.Scale = scale
        themeDock.AnchorPoint = Vector2.new(0, 1)
        themeDock.Position = UDim2.fromOffset(
            math.clamp(window.AbsolutePosition.X + 224 * HUD.windowScale.Scale, 12, math.max(12, viewport.X - 232)),
            math.clamp(window.AbsolutePosition.Y + window.AbsoluteSize.Y - 12, unscaledHeight * scale + 12, math.max(unscaledHeight * scale + 12, viewport.Y - 12)))
        themeDock.Visible = true
        tween(themeDock, { GroupTransparency = 0 }, 0.2)
    else
        local t = tween(themeDock, { GroupTransparency = 1 }, 0.18)
        t.Completed:Connect(function()
            if not themeDockOpen then themeDock.Visible = false end
        end)
    end
end
 
    dockCloseBtn.MouseButton1Click:Connect(function()
        if themeDockOpen then toggleThemeDock() end
    end)
end
 
----------------------------------------------------------------
-- СТИЛЬ ГУИ: плотная оболочка / полупрозрачное стекло.
----------------------------------------------------------------
 
local guiStyle = "Normal" -- "Normal" | "LiquidGlass"
local styleBoundFrames = {} -- { {frame=, normalTransparency=, glassTransparency=} }
local styleBoundStrokes = {} -- { {stroke=, normalTransparency=, glassTransparency=} }
 
local function registerStyleFrame(frame, normalTransparency, glassTransparency)
    table.insert(styleBoundFrames, { frame = frame, normal = normalTransparency, glass = glassTransparency })
    return frame
end
 
local function registerStyleStroke(strokeInst, normalTransparency, glassTransparency)
    table.insert(styleBoundStrokes, { stroke = strokeInst, normal = normalTransparency, glass = glassTransparency })
    return strokeInst
end
 
local styleFabButton = create("TextButton", {
    Name = "StyleToggle",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -106, 0, 25),
    BackgroundColor3 = COLORS.off,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 5,
    Parent = titleBar,
})
corner(styleFabButton, 9)
stroke(styleFabButton, COLORS.stroke, 1)
 
do
local styleFabIcon = create("Frame", {
    Size = UDim2.new(0, 12, 0, 12),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = COLORS.accent,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    themeBind = false,
    Parent = styleFabButton,
})
corner(styleFabIcon, 4)
local styleFabIconStroke = Instance.new("UIStroke")
styleFabIconStroke.Color = Color3.fromRGB(255, 255, 255)
styleFabIconStroke.Thickness = 1
styleFabIconStroke.Transparency = 0.3
styleFabIconStroke.Parent = styleFabIcon
end
 
styleFabButton.MouseEnter:Connect(function()
    tween(styleFabButton, { BackgroundColor3 = COLORS.hover }, 0.15)
end)
styleFabButton.MouseLeave:Connect(function()
    tween(styleFabButton, { BackgroundColor3 = COLORS.off }, 0.15)
end)
 
local _glassReflectionThread = nil

local function applyGuiStyle()
    local isGlass = guiStyle == "LiquidGlass"
    local blurAlpha = (gameplayConfig.uiEffects and gameplayConfig.uiEffects.glassBlur) or 0.38

    for _, entry in ipairs(styleBoundFrames) do
        if entry.frame.Parent then
            local targetTransp = isGlass and (entry.glass * (1 + (blurAlpha - 0.38) * 0.4)) or entry.normal
            tween(entry.frame, { BackgroundTransparency = math.clamp(targetTransp, 0, 0.95) }, 0.35)
        end
    end
    for _, entry in ipairs(styleBoundStrokes) do
        if entry.stroke.Parent then
            tween(entry.stroke, { Transparency = isGlass and entry.glass or entry.normal }, 0.35)
        end
    end

    tween(styleFabIcon, { BackgroundTransparency = isGlass and 0 or 0.4 }, 0.2)

    if isGlass then
        -- Настоящее Liquid Glass: акриловый оттенок темы + блик + отражение
        tween(windowGlassTint, { BackgroundTransparency = 0.93 }, 0.35)
        tween(windowGlassSpecular, { BackgroundTransparency = 0.82 }, 0.35)
        tween(windowGlassStroke, { Transparency = 0.25, Color = Color3.fromRGB(255, 255, 255) }, 0.35)
        tween(guiGlassSheen, { ImageTransparency = 0.85 }, 0.35)

        -- Редкая плавная анимация светового блика (раз в 9 секунд)
        if not _glassReflectionThread then
            _glassReflectionThread = task.spawn(function()
                while guiStyle == "LiquidGlass" and runtimeAlive do
                    task.wait(9)
                    if guiStyle == "LiquidGlass" and (gameplayConfig.uiEffects and gameplayConfig.uiEffects.reflections ~= false) then
                        glassSweepFrame.Position = UDim2.new(-0.4, 0, -0.5, 0)
                        glassSweepFrame.BackgroundTransparency = 0.88
                        local sweepTween = TweenService:Create(glassSweepFrame, TweenInfo.new(1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
                            Position = UDim2.new(1.4, 0, -0.5, 0),
                        })
                        sweepTween:Play()
                        sweepTween.Completed:Connect(function()
                            glassSweepFrame.BackgroundTransparency = 1
                        end)
                    end
                end
                _glassReflectionThread = nil
            end)
        end
    else
        -- Возврат оригинального стиля
        tween(windowGlassTint, { BackgroundTransparency = 1 }, 0.25)
        tween(windowGlassSpecular, { BackgroundTransparency = 1 }, 0.25)
        tween(windowGlassStroke, { Transparency = 0.15, Color = COLORS.stroke }, 0.25)
        tween(guiGlassSheen, { ImageTransparency = 1 }, 0.25)
        glassSweepFrame.BackgroundTransparency = 1
    end
end

styleFabButton.MouseButton1Click:Connect(function()
    guiStyle = (guiStyle == "Normal") and "LiquidGlass" or "Normal"
    if gameplayConfig.uiEffects then
        gameplayConfig.uiEffects.liquidGlass = (guiStyle == "LiquidGlass")
    end
    applyGuiStyle()
    HUD.notify(guiStyle == "LiquidGlass" and "Liquid Glass  •  ON" or "Liquid Glass  •  OFF", guiStyle == "LiquidGlass" and "success" or "info")
end)

-- Общая оболочка остаётся видимой; стекло теперь меняет её прозрачность.
registerStyleFrame(windowGlassBg, 0, 0.38)
registerStyleStroke(windowGlassStroke, 0.15, 0.3)
registerStyleFrame(HUD.sidebar, 0, 0.45)
registerStyleFrame(titleBadge, 1, 1)
registerStyleFrame(searchBox, 0, 0.55)

applyGuiStyle()
 
----------------------------------------------------------------
-- Создание строк модулей
----------------------------------------------------------------

-- Единственная таблица маршрутизации ПКМ. Модули без реальных настроек
-- намеренно не открывают устаревшую фиктивную панель.

-- ═══════════════════════════════════════════════════════════════
-- Ambient Color ПКМ: Палитра и интенсивность освещения
-- ═══════════════════════════════════════════════════════════════
MODULE_SETTINGS_OPENERS["Ambient Color"] = function(anchorRow)
    local panel, cy = createCustomPanel("Ambient Color", 280, 260)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1, Text = CURRENT_LANG == "RU" and "Пресеты освещения" or "光照预设",
        TextColor3 = COLORS.textDim, Font = Enum.Font.GothamSemibold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 20

    local presets = {
        { name = "Theme Sync", color = nil },
        { name = "Midnight",   color = Color3.fromRGB(80, 100, 180) },
        { name = "Crimson",    color = Color3.fromRGB(180, 40, 50) },
        { name = "Emerald",    color = Color3.fromRGB(50, 170, 90) },
        { name = "Purple",     color = Color3.fromRGB(130, 70, 200) },
        { name = "Gold",       color = Color3.fromRGB(190, 150, 60) },
    }

    for i, p in ipairs(presets) do
        local px = 14 + ((i - 1) % 3) * 85
        local py = cy + math.floor((i - 1) / 3) * 34
        local btn, _ = createPresetButton(panel, p.name, px, py, 78, false, function(b)
            if p.color then
                gameplayConfig.ambientThemeColor = p.color
            else
                local curTheme = THEMES[currentTheme]
                if curTheme and curTheme.ambient then
                    gameplayConfig.ambientThemeColor = curTheme.ambient
                end
            end
            if visualApply.ambient then visualApply.ambient(gameplayConfig.ambientThemeColor) end
        end)
    end
    cy = cy + 76

    cy = createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Яркость эмбиента" or "环境亮度", 10, 100, 75, 5, function(val)
        Lighting.Brightness = 1 + (val / 100) * 2
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Infinity Jump ПКМ: Сила прыжка и параметры
-- ═══════════════════════════════════════════════════════════════
MODULE_SETTINGS_OPENERS["Infinity Jump"] = function(anchorRow)
    local panel, cy = createCustomPanel("Infinity Jump", 260, 160)
    createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Сила прыжка" or "跳跃力度", 30, 120, gameplayConfig.infJumpPower or 52, 2, function(val)
        gameplayConfig.infJumpPower = val
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Glow ESP ПКМ: Настройки подсветки игроков
-- ═══════════════════════════════════════════════════════════════
MODULE_SETTINGS_OPENERS["Glow ESP"] = function(anchorRow)
    local panel, cy = createCustomPanel("Glow ESP", 280, 200)
    cy = createPanelSlider(panel, cy, CURRENT_LANG == "RU" and "Прозрачность ESP" or "ESP 透明度", 10, 90, math.floor((gameplayConfig.glowEspTransparency or 0.45) * 100), 5, function(val)
        gameplayConfig.glowEspTransparency = val / 100
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("SolaraGlowEsp")
                if hl then hl.FillTransparency = gameplayConfig.glowEspTransparency end
            end
        end
    end)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 32), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "✓ Высокопроизводительный Highlight ESP сквозь стены" or "✓ 高性能穿墙高亮 ESP",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- Anti-Fling ПКМ: Настройки защиты от флинга
-- ═══════════════════════════════════════════════════════════════
MODULE_SETTINGS_OPENERS["Anti-Fling"] = function(anchorRow)
    local panel, cy = createCustomPanel("Anti-Fling", 260, 150)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 60), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Отключает коллизию персонажа с чужими объектами и врагами, предотвращая отталкивание спиннерами и флингерами." or "关闭角色与其他物体和玩家的碰撞，减少旋转与甩飞影响。",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- Clear Screen ПКМ: Быстрая очистка экрана
-- ═══════════════════════════════════════════════════════════════
MODULE_SETTINGS_OPENERS["Clear Screen"] = function(anchorRow)
    local panel, cy = createCustomPanel("Clear Screen", 260, 160)
    createPresetButton(panel, CURRENT_LANG == "RU" and "Скрыть игровой чат Roblox" or "显示/隐藏 Roblox 聊天", 14, cy, 232, false, function()
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            local chatEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not chatEnabled)
        end)
    end)
    cy = cy + 36
    createPresetButton(panel, CURRENT_LANG == "RU" and "Очистить эффект размытия" or "清除模糊和景深", 14, cy, 232, false, function()
        for _, eff in ipairs(Lighting:GetChildren()) do
            if eff:IsA("BlurEffect") or eff:IsA("DepthOfFieldEffect") then
                if eff.Name:sub(1, 6) ~= "Solara" then eff.Enabled = false end
            end
        end
        HUD.notify("Clear Screen: эффекты размытия очищены", "success")
    end)
end


----------------------------------------------------------------
-- CONQUER THE WORLD WW2 — STRATEGY ENGINE (FROM SOI HUB v5.3)
----------------------------------------------------------------
local Ww2Engine = (function()
    local engine = {
        initialized = false,
        currentPreset = "Infantry Meta",
        State = {
            AutoFactory     = false, AutoProduction = false, AutoGovernment = false,
            AutoArmy        = false, AutoResearch   = false, SmartMovement  = false,
            AutoPlanes      = false, AutoSilo       = false, AutoNaval      = false,
            AutoDiplomacy   = false, AutoMissile    = false,
            GovernmentMode  = "War", ArmySpawnFocus = "Infantry", ResearchBases  = {},
        },
        dipState = { justifying = {} },
        navalState = { phase = "idle", usedArmies = {} },
        planeDeployed = {},
        cancelTacticalThreads = function() end,
        applyPreset = function(name)
            engine.currentPreset = name
            local b = engine.PRESETS and engine.PRESETS[name]
            if not b then return end
            engine.State.ResearchBases = {}
            for _, x in pairs(b) do table.insert(engine.State.ResearchBases, x) end
        end,
        toggleHud = function(override)
            if engine.hudGui then
                if override ~= nil then
                    engine.hudGui.Enabled = override
                else
                    engine.hudGui.Enabled = not engine.hudGui.Enabled
                end
                return engine.hudGui.Enabled
            end
            return false
        end,
        PRESETS = {
            ["Infantry Meta"] = { "Infantry Equipment", "Infantry Attack Equipment", "Infantry Armor", "Anti-Tank", "Support Equipment", "Fortifications", "Industry" },
            ["Tank Meta"]     = { "Tank Parts", "Tank Turret", "Mechanization", "Anti-Tank", "Support Equipment", "Industry" },
            ["Air Meta"]      = { "Fighter", "CAS", "Bomber", "Support Equipment", "Industry" },
            ["Naval Meta"]    = { "Destroyer", "Battleship", "Submarine", "Transport Ship", "Shipyard", "Industry" },
            ["Nuke Rush"]     = { "Uranium Mining", "Uranium Enrichment", "Nuke", "Nuclear Protection", "Industry" },
        },
    }

    function engine.init()
        if engine.initialized then return true end
        local LocalPlayer = player or Players.LocalPlayer
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")

        local map = workspace:FindFirstChild("Map")
        local cities = ReplicatedStorage:FindFirstChild("Cities")
        if not map and not cities then
            return false
        end

        engine.initialized = true

            local PurchaseFactory   = ReplicatedStorage.Cities.PurchaseFactory
    local SetProductionPct  = ReplicatedStorage.Production.SetProductionPercentage
    local TryPurchaseTech   = ReplicatedStorage.Research.TryPurchaseTech
    local StartResearch     = ReplicatedStorage.Research.StartResearch
    local TryStartFocus     = ReplicatedStorage.Government.TryStartFocus
    local TryIncreaseTarget = ReplicatedStorage.Army.TryIncreaseTarget
    local MoveTroop         = ReplicatedStorage.Player.MoveTroop
    local TryDeployPlanes   = ReplicatedStorage:WaitForChild("Planes"):WaitForChild("TryDeployPlanes")
    local ResearchCommon    = require(ReplicatedStorage.Common.ResearchCommon)
    local PreviewPath       = require(LocalPlayer.PlayerScripts.PlayerControls.PreviewPath)
    local Map               = workspace:WaitForChild("Map")
    local AirMap            = workspace:WaitForChild("AirMap")

    local function safeFire(r, ...) pcall(function(...) r:FireServer(...) end, ...) end
    local function safeInvoke(r, ...) local ok, a = pcall(function(...) return r:InvokeServer(...) end, ...); return ok and a or false end
    local function numAttr(i, n, f) local v = i and i:GetAttribute(n); return type(v) == "number" and v or (f or 0) end
    local function decodeJ(raw) if not raw then return nil end; local ok, d = pcall(HttpService.JSONDecode, HttpService, raw); return ok and d or nil end
    local function getCountry() local o = LocalPlayer:FindFirstChild("Country"); return o and o.Value or nil end

    local ok_ct, CommonTypes = pcall(function() return require(ReplicatedStorage.Common.CommonTypes) end)
    if not ok_ct then CommonTypes = nil end

    local PRESETS = {
        ["Infantry Meta"] = { "Infantry Equipment", "Infantry Attack Equipment", "Infantry Armor", "Anti-Tank", "Support Equipment", "Fortifications", "Industry" },
        ["Tank Meta"]     = { "Tank Parts", "Tank Turret", "Mechanization", "Anti-Tank", "Support Equipment", "Industry" },
        ["Air Meta"]      = { "Fighter", "CAS", "Bomber", "Support Equipment", "Industry" },
        ["Naval Meta"]    = { "Destroyer", "Battleship", "Submarine", "Transport Ship", "Shipyard", "Industry" },
        ["Nuke Rush"]     = { "Uranium Mining", "Uranium Enrichment", "Nuke", "Nuclear Protection", "Industry" },
    }

    local State = engine.State
    engine.applyPreset = applyPreset
    engine.PRESETS = PRESETS
    if engine.currentPreset then applyPreset(engine.currentPreset) end

    local function applyPreset(name) local b = PRESETS[name]; if not b then return end; State.ResearchBases = {}; for _, x in pairs(b) do table.insert(State.ResearchBases, x) end end

    -- ═══ AUTO NAVAL INVASION ══════════════════════════════════
    local LoadDivisionOnShip   = ReplicatedStorage:WaitForChild("Cities"):WaitForChild("Port"):WaitForChild("LoadDivisionOnShip")
    local TryExitPortWithFleet = ReplicatedStorage:WaitForChild("Cities"):WaitForChild("Port"):WaitForChild("TryExitPortWithFleet")
    local PreviewPath_naval    = require(LocalPlayer.PlayerScripts.PlayerControls.PreviewPath)

    local navalState = {
        phase       = "idle",   -- idle | loading | sailing | landed
        targetTile  = nil,
        usedArmies  = {},
        lastAt      = 0,
    }
    engine.navalState = navalState

    local function getEnemyCapitalTile(country)
        local dip = country:FindFirstChild("Diplomacy")
        if not dip then return nil end
        local enemies = dip:FindFirstChild("Enemies")
        if not enemies then return nil end
        for _, e in ipairs(enemies:GetChildren()) do
            if not e.Value then continue end
            local cities = e.Value:FindFirstChild("Cities")
            if not cities then continue end
            for _, city in ipairs(cities:GetChildren()) do
                if city:GetAttribute("isCapital") then
                    local tileName = tostring(city:GetAttribute("tileName") or "")
                    local tile = Map:FindFirstChild(tileName)
                    if tile then return tile, e.Value end
                end
            end
        end
        return nil
    end

    local function getBestInfantry(country, myHex, count)
        local units = {}
        for _, tile in ipairs(Map:GetChildren()) do
            if tile.Color:ToHex() ~= myHex then continue end
            local m = tile:FindFirstChildWhichIsA("Model")
            if not m then continue end
            if m:GetAttribute("state") ~= "Idle" then continue end
            local troopName = m:GetAttribute("troopName") or ""
            -- AntiTank ve Tank değil
            if troopName:find("AntiTank") or troopName:find("Tank") then continue end
            if navalState.usedArmies[m] then continue end
            local pow = (m:GetAttribute("attack") or 0) * (m:GetAttribute("health") or 0)
            table.insert(units, {tile = tile, model = m, pow = pow, troopName = troopName})
        end
        table.sort(units, function(a,b) return a.pow > b.pow end)
        local result = {}
        for i = 1, math.min(count, #units) do
            table.insert(result, units[i])
        end
        return result
    end

    local function getTransportShips(country)
        local ships = {}
        local cities = country:FindFirstChild("Cities")
        if not cities then return ships end
        for _, city in ipairs(cities:GetChildren()) do
            local port = city:FindFirstChild("Port")
            if not port then continue end
            local docked = port:FindFirstChild("DockedShips")
            if not docked then continue end
            for _, ship in ipairs(docked:GetChildren()) do
                local divCap = ship:GetAttribute("divisionCapacity") or 0
                if divCap <= 0 then continue end -- sadece transport
                local loaded = game:GetService("HttpService"):JSONDecode(ship:GetAttribute("loadedDivisions") or "[]")
                local freeSlots = divCap - #loaded
                if freeSlots > 0 then
                    table.insert(ships, {ship = ship, city = city, freeSlots = freeSlots, totalCap = divCap})
                end
            end
        end
        return ships
    end

    local function getPortTile(city)
        local tileName = tostring(city:GetAttribute("tileName") or "")
        return Map:FindFirstChild(tileName)
    end

    local function getSeaTileAdjacentTo(tile)
        -- Port tile'ına komşu deniz tile'ını bul
        local ns = PreviewPath_naval.neighbours[tile]
        if not ns then return nil end
        for _, n in ipairs(ns) do
            if n.Name:match("^Sea") then return n end
        end
        return nil
    end

    local function autoNavalTick(snap)
        if not State.AutoNaval then return end
        if os.clock() - navalState.lastAt < 5 then return end
        navalState.lastAt = os.clock()

        local country = snap.country
        local myHex   = snap.myColorHex
        local myColor = snap.myColor

        -- Düşman capital'ini bul
        local targetTile, enemyCountry = getEnemyCapitalTile(country)
        if not targetTile then
            print("[NAVAL] Düşman capital bulunamadı — savaşta değil")
            return
        end

        -- Transport ship var mı?
        local transports = getTransportShips(country)
        if #transports == 0 then
            print("[NAVAL] Transport ship yok — bekliyor")
            return
        end

        -- En iyi infantry ordularını al (ship kapasitesi kadar)
        local totalCap = 0
        for _, t in ipairs(transports) do totalCap = totalCap + t.freeSlots end
        local infantry = getBestInfantry(country, myHex, totalCap)

        if #infantry == 0 then
            print("[NAVAL] Yüklenebilir infantry yok")
            return
        end

        -- Phase 1: Infantry'yi porta hareket ettir ve gemiye yükle
        local allowed = {[myHex] = true}
        local dip = country:FindFirstChild("Diplomacy")
        if dip then
            local ef = dip:FindFirstChild("Enemies")
            if ef then for _, e in ipairs(ef:GetChildren()) do
                if e.Value then allowed[e.Value:GetAttribute("color"):ToHex()] = true end
            end end
        end

        local loadedCount = 0
        for _, transport in ipairs(transports) do
            if loadedCount >= #infantry then break end
            local portTile = getPortTile(transport.city)
            if not portTile then continue end

            for slot = 1, transport.freeSlots do
                local unitIdx = loadedCount + 1
                if unitIdx > #infantry then break end
                local unit = infantry[unitIdx]

                -- Önce porta hareket et
                if unit.tile ~= portTile then
                    local path = PreviewPath_naval.ComputePath(unit.tile, portTile, allowed)
                    if path then
                        local ok = pcall(function()
                            game.ReplicatedStorage.Player.MoveTroop:FireServer(path)
                        end)
                        if ok then
                            print(("[NAVAL] %s → %s (port)"):format(unit.troopName, transport.city.Name))
                            task.wait(0.5)
                        end
                    end
                end

                -- Gemiye yükle
                local loadOk = pcall(function()
                    LoadDivisionOnShip:FireServer(transport.ship)
                end)
                if loadOk then
                    navalState.usedArmies[unit.model] = true
                    loadedCount = loadedCount + (1)
                    print(("[NAVAL] Loaded %s onto %s"):format(unit.troopName, transport.ship.Name))
                    task.wait(0.3)
                end
            end

            -- Gemi dolu veya yükledik — limandan çık
            if loadedCount > 0 then
                task.wait(1)
                local exitOk, exitErr = pcall(function()
                    return TryExitPortWithFleet:InvokeServer(transport.city, {transport.ship})
                end)
                if exitOk then
                    print(("[NAVAL] Fleet exited %s → heading to %s"):format(
                        transport.city.Name, targetTile.Name))
                    navalState.phase = "sailing"
                else
                    warn("[NAVAL] Exit failed:", tostring(exitErr))
                end
            end
        end

        -- Phase 2: Denizde olan transport'lar hedef kıyısına varınca MoveTroop
        -- Gemi hedef tile'a komşu sea tile'ına gelince iniş yap
        task.spawn(function()
            local enemyHex = enemyCountry and enemyCountry:GetAttribute("color"):ToHex() or ""
            -- Hedef tile'a komşu sea tile'ı
            local landingSeaTile = getSeaTileAdjacentTo(targetTile)
            if not landingSeaTile then
                warn("[NAVAL] Hedef tile'a komşu sea tile yok")
                return
            end

            -- Çıkartma yeri — hedef capital veya en yakın düşman kıyı tile'ı
            -- MoveTroop ile denizden karaas geçiş: deniz → düşman tile
            local landingAllowed = {}
            for k, v in pairs(allowed) do landingAllowed[k] = v end

            -- Buradaki MoveTroop çağrısı gemi kıyıya yanaştığında tetiklenir
            -- Oyunda gemi otomatik hareket eder, biz sadece unload zamanını bekleriz
            print("[NAVAL] Fleet sailing — invasion will complete automatically when ships arrive")
        end)
    end

    -- ═══════════════════════════════════════════════════════
    -- AUTO DIPLOMACY
    -- Justify war against weak neighbors, then declare war
    -- Auto peace when outmatched
    -- ═══════════════════════════════════════════════════════
    local TryJustifyWar  = game:GetService("ReplicatedStorage").Diplomacy.TryJustifyWar
    local TryDeclareWar  = game:GetService("ReplicatedStorage").Diplomacy.TryDeclareWar
    local TrySendTreaty  = game:GetService("ReplicatedStorage").Diplomacy.TrySendTreaty
    local Countries      = game:GetService("ReplicatedStorage"):WaitForChild("Countries")

    local dipState = {
        lastJustifyAt   = 0,
        lastDeclareAt   = 0,
        lastPeaceAt     = 0,
        justifying      = {},  -- countryName → true if justification in progress
    }

    local function autoMissileTick(snap) end  -- forward declare, defined below

    local function autoRealDipTick(snap)
        if not State.AutoDiplomacy then return end
        local country = snap.country
        local myColor = country:GetAttribute("color")
        local myHex   = myColor and myColor:ToHex() or ""
        local money   = snap.economy.money
        local Map     = workspace.Map

        -- Power assessment: total attack power of all our armies
        local myPower = 0
        for _, tile in ipairs((tileCache.byHex[myHex] or {})) do
            local m = tile:FindFirstChildWhichIsA("Model")
            if m then
                local h = numAttr(m,"health"); local a = numAttr(m,"attack")
                myPower = myPower + h * a
            end
        end

        local dip = country:FindFirstChild("Diplomacy")
        if not dip then return end

        -- ── AUTO PEACE: if we are losing badly, send peace treaty ──
        if os.clock() - dipState.lastPeaceAt > 60 then
            local enemies = dip:FindFirstChild("Enemies")
            if enemies then
                for _, e in ipairs(enemies:GetChildren()) do
                    if not e.Value then continue end
                    local eHex = e.Value:GetAttribute("color"):ToHex()
                    local enemyPower = 0
                    for _, tile in ipairs((tileCache.byHex[eHex] or {})) do
                        local m = tile:FindFirstChildWhichIsA("Model")
                        if m then
                            local h = numAttr(m,"health"); local a = numAttr(m,"attack")
                            enemyPower = enemyPower + h * a
                        end
                    end
                    -- Enemy is 2.5x stronger → request peace
                    if enemyPower > myPower * 2.5 then
                        local eFolder = Countries:FindFirstChild(e.Value.Name)
                        if eFolder then
                            pcall(function()
                                TrySendTreaty:InvokeServer(eFolder, "Peace")
                            end)
                            print("[DIP] Peace requested with", e.Value.Name, "— outmatched")
                            dipState.lastPeaceAt = os.clock()
                        end
                    end
                end
            end
        end

        -- ── AUTO JUSTIFY: find weak neighbor not at war with us ──
        if os.clock() - dipState.lastJustifyAt < 45 then return end

        -- PP check
        local pp = country:GetAttribute("politicalPower") or 0
        if pp < 35 then return end  -- need at least 35 PP for justification

        -- Find weakest country bordering us that we're not at war with
        local bestTarget = nil
        local bestScore  = math.huge

        for _, eCountry in ipairs(Countries:GetChildren()) do
            local eColor = eCountry:GetAttribute("color")
            if not eColor then continue end
            local eHex = eColor:ToHex()
            if eHex == myHex then continue end

            -- Already at war?
            local alreadyEnemy = false
            local enemies = dip:FindFirstChild("Enemies")
            if enemies then
                for _, e in ipairs(enemies:GetChildren()) do
                    if e.Value and e.Value == eCountry then alreadyEnemy = true; break end
                end
            end
            if alreadyEnemy then continue end

            -- Already justifying?
            if dipState.justifying[eCountry.Name] then continue end

            -- Is this country neighboring us?
            local isNeighbor = false
            for _, tile in ipairs((tileCache.byHex[eHex] or {})) do
                local ns = PreviewPath.neighbours[tile]
                if ns then
                    for _, n in ipairs(ns) do
                        if not n.Name:match("^Sea") and n.Color:ToHex() == myHex then
                            isNeighbor = true; break
                        end
                    end
                end
                if isNeighbor then break end
            end
            if not isNeighbor then continue end

            -- Their power
            local ePower = 0
            local eTiles = #(tileCache.byHex[eHex] or {})
            for _, tile in ipairs((tileCache.byHex[eHex] or {})) do
                local m = tile:FindFirstChildWhichIsA("Model")
                if m then
                    local h = numAttr(m,"health"); local a = numAttr(m,"attack")
                    ePower = ePower + h * a
                end
            end

            -- Only target weaker countries (we have 1.5x their power)
            if myPower < ePower * 1.5 then continue end

            -- Score: fewer tiles + less power = easier target
            local score = ePower + eTiles * 10
            if score < bestScore then
                bestScore  = score
                bestTarget = eCountry
            end
        end

        if bestTarget then
            local ok, err = pcall(function()
                return TryJustifyWar:InvokeServer(bestTarget)
            end)
            if ok then
                dipState.justifying[bestTarget.Name] = true
                dipState.lastJustifyAt = os.clock()
                print("[DIP] Justifying war against:", bestTarget.Name)
            else
                print("[DIP] Justify failed:", tostring(err))
            end
        end

        -- ── AUTO DECLARE: if justification complete, declare war ──
        if os.clock() - dipState.lastDeclareAt < 30 then return end

        local justF = dip:FindFirstChild("Justification")
        if justF then
            for _, just in ipairs(justF:GetChildren()) do
                local progress = just:GetAttribute("progress") or 0
                if progress >= 1 then
                    local targetFolder = Countries:FindFirstChild(just.Name)
                    if targetFolder then
                        local ok2 = pcall(function()
                            TryDeclareWar:InvokeServer(targetFolder)
                        end)
                        if ok2 then
                            dipState.justifying[just.Name] = nil
                            dipState.lastDeclareAt = os.clock()
                            print("[DIP] War declared on:", just.Name)
                        end
                    end
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════
    -- AUTO MISSILE LAUNCH
    -- Fires missiles at enemy capitals/high-value tiles
    -- Prioritizes: capital > urban > high army density
    -- ═══════════════════════════════════════════════════════
    local LaunchMissileRF = game:GetService("ReplicatedStorage").TileProjects.LaunchMissile
    local lastMissileAt   = 0

    local function autoMissileTick(snap)
        if not State.AutoMissile then return end
        if os.clock() - lastMissileAt < 20 then return end -- cooldown

        local country = snap.country
        local myHex   = snap.myColorHex
        local Map     = workspace.Map

        -- Find our missile silos with ammo
        local siloTiles = {}
        local cities = country:FindFirstChild("Cities")
        if cities then
            for _, city in ipairs(cities:GetChildren()) do
                local tileName = tostring(city:GetAttribute("tileName") or "")
                local tile = Map:FindFirstChild(tileName)
                if not tile then continue end
                if not tile:GetAttribute("hasMissileSilo") then continue end

                -- Check ammo: get missile item name based on silo level
                local siloLevel = tile:GetAttribute("missileSiloLevel") or 1
                local prodF     = country:FindFirstChild("ProductionItems")
                local ammo      = 0
                if prodF then
                    -- Missile item names: "Ballistic Missiles I", "II", "III"
                    local tiers  = {"Ballistic Missiles I", "Ballistic Missiles II", "Ballistic Missiles III"}
                    local itemName = tiers[math.clamp(siloLevel, 1, 3)]
                    local item   = prodF:FindFirstChild(itemName)
                    if item then ammo = item:GetAttribute("stock") or 0 end
                end

                if ammo > 0 then
                    table.insert(siloTiles, {tile = tile, ammo = ammo, level = siloLevel})
                end
            end
        end

        if #siloTiles == 0 then return end

        -- Find best target tile (enemy capital first, then urban, then army dense)
        local bestTarget = nil
        local bestScore  = -math.huge

        for hex, eCountry in pairs(snap.enemyColors or {}) do
            -- Check silo range
            local maxRange = 0
            local techsF = country:FindFirstChild("Techs")
            if techsF then
                -- GetSiloRange equivalent: base range per level
                local SILO_RANGES = {60, 120, 200}
                for _, st in ipairs(siloTiles) do
                    maxRange = math.max(maxRange, SILO_RANGES[math.clamp(st.level, 1, 3)])
                end
            end

            for _, tile in ipairs((tileCache.byHex[hex] or {})) do
                -- Score target
                local score = 0
                if tile:GetAttribute("isCapital") then score = score + 500 end
                if tile:GetAttribute("hasCity")   then score = score + 100 end
                local m = tile:FindFirstChildWhichIsA("Model")
                if m then
                    -- High HP army = good target
                    score = score + (numAttr(m, "health") * numAttr(m, "attack")) * 2
                end

                -- Range check: distance from nearest silo
                local inRange = false
                for _, st in ipairs(siloTiles) do
                    local dist = (st.tile.Position - tile.Position).Magnitude
                    if dist <= maxRange * 10 then  -- stud conversion estimate
                        inRange = true; break
                    end
                end
                if not inRange then continue end

                if score > bestScore then
                    bestScore  = score
                    bestTarget = tile
                end
            end
        end

        if not bestTarget then return end

        -- Collect silo tiles array (as expected by server)
        local siloArr = {}
        for _, st in ipairs(siloTiles) do table.insert(siloArr, st.tile) end

        local ok, result = pcall(function()
            return LaunchMissileRF:InvokeServer(siloArr, bestTarget, false)  -- false = missile, not nuke
        end)

        if ok and result then
            lastMissileAt = os.clock()
            print("[MSL] Missile launched at:", bestTarget.Name)
        elseif not ok then
            warn("[MSL] Launch failed:", tostring(result))
        end
    end

    -- ═══════════════════════════════════════════════════════
    -- AUTO MISSILE SILO BUILDER
    -- ═══════════════════════════════════════════════════════
    local PurchaseMissileSiloRE = ReplicatedStorage:WaitForChild("TileProjects"):WaitForChild("PurchaseMissileSilo")
    local lastSiloAt = 0

    local function getSiloLevel(tile)
        if tile:GetAttribute("hasMissileSilo") ~= true then return 0 end
        local lv = tile:GetAttribute("missileSiloLevel")
        return type(lv) == "number" and math.clamp(math.floor(lv), 1, 3) or 1
    end

    local function getSiloQueue(tile)
        local q = tile:GetAttribute("missileSiloBuildQueue")
        if type(q) == "number" then return math.max(0, math.floor(q)) end
        if tile:GetAttribute("missileSiloBuildStart") then return 1 end
        return 0
    end

    local function getSiloCost(country, nextLevel)
        local techs = country:FindFirstChild("Techs")
        if not techs then return 15000 end
        local base = techs:GetAttribute("missileSiloPrice") or 15000
        local perLv = techs:GetAttribute("missileSiloPricePerLevel") or 10000
        return base + (math.clamp(nextLevel, 1, 3) - 1) * perLv
    end

    local function getSiloTechLevel(country)
        -- Ballistic Missiles I/II/III araştırma seviyesi
        local techs = country:FindFirstChild("Techs")
        if not techs then return 0 end
        local maxLv = 0
        for i = 1, 3 do
            local names = {"Ballistic Missiles I", "Ballistic Missiles II", "Ballistic Missiles III"}
            local nd = techs:FindFirstChild(names[i])
            if nd and nd:GetAttribute("progress") == 1 then maxLv = i end
        end
        return maxLv
    end

    -- Tile score: front'tan uzak, capital'a yakın, iç tile'lar tercihli
    local function scoreSiloTile(tile, myHex, frontTiles, protectedTiles)
        local score = 0
        -- Front tile'ı değilse +50 (silo front'ta olmamalı — vurulur)
        if not frontTiles[tile] then score = score + 50 end
        -- Protected (capital çevresi) ise +30
        if protectedTiles[tile] then score = score + 30 end
        -- Terrain: mountain/hills tercihli (savunma)
        local terrain = tile:GetAttribute("terrain") or ""
        if terrain == "mountain" then score = score + 20
        elseif terrain == "hills" then score = score + 10 end
        return score
    end

    local function autoSiloTick(snap)
        if not State.AutoSilo then return end
        if os.clock() - lastSiloAt < 8 then return end -- her 8s max 1 build

        local country = snap.country
        local money = snap.economy.money
        local myHex = snap.myColorHex
        local techLevel = getSiloTechLevel(country)
        if techLevel == 0 then return end -- hiç silo tech araştırılmamış

        -- Front ve protected tile'ları bul
        local frontTiles = snap.frontTiles
        local protectedTiles = {}
        local cf = country:FindFirstChild("Cities")
        if cf then
            for _, city in ipairs(cf:GetChildren()) do
                if city:GetAttribute("isCapital") then
                    local tileName = tostring(city:GetAttribute("tileName") or "")
                    local t = Map:FindFirstChild(tileName)
                    if t then protectedTiles[t] = true end
                end
            end
        end

        -- Kendi tile'larını tara, silo build edilebilecekleri bul
        local candidates = {}
        for _, tile in ipairs(Map:GetChildren()) do
            if tile.Name:match("^Sea") then continue end
            if tile.Color:ToHex() ~= myHex then continue end

            local curLevel = getSiloLevel(tile)
            local queueCount = getSiloQueue(tile)
            local nextLevel = curLevel + queueCount + 1

            -- Max level veya zaten build queue dolu
            if nextLevel > 3 then continue end
            -- Tech seviyesi yeterli mi?
            if techLevel < nextLevel then continue end
            -- Zaten build'de mi?
            if tile:GetAttribute("missileSiloBuildStart") and queueCount >= 1 then continue end

            local cost = getSiloCost(country, nextLevel)
            if money - cost < 20000 then continue end -- 20k reserve

            local score = scoreSiloTile(tile, myHex, frontTiles, protectedTiles)
            table.insert(candidates, {tile = tile, cost = cost, nextLevel = nextLevel, score = score})
        end

        if #candidates == 0 then return end

        -- En iyi tile'ı seç: score yüksek, mevcut level düşük önce
        table.sort(candidates, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            return a.nextLevel < b.nextLevel
        end)

        local best = candidates[1]
        local ok, err = pcall(function()
            PurchaseMissileSiloRE:FireServer(best.tile)
        end)

        if ok then
            lastSiloAt = os.clock()
            print(("[SILO] Build queued: %s → Level %d ($%d)"):format(
                best.tile.Name, best.nextLevel, best.cost))
        else
            warn("[SILO] FireServer error:", tostring(err))
        end
    end

    -- ═══ AUTO PLANE DEPLOYMENT ════════════════════════════════
    local planeDeployed = {}
    engine.planeDeployed = planeDeployed

    local function getEnemyHexes(country)
        local hexes = {}
        local dip = country:FindFirstChild("Diplomacy")
        if not dip then return hexes end
        local enemies = dip:FindFirstChild("Enemies")
        if not enemies then return hexes end
        for _, e in ipairs(enemies:GetChildren()) do
            if e.Value then
                local col = e.Value:GetAttribute("color")
                if col then hexes[col:ToHex()] = true end
            end
        end
        return hexes
    end

    local function getMyAirfields(country)
        local result = {}
        local cities = country:FindFirstChild("Cities")
        if not cities then return result end
        for _, city in ipairs(cities:GetChildren()) do
            local af = city:FindFirstChild("Airfield")
            if not af then continue end
            local tileName = tostring(city:GetAttribute("tileName") or "")
            local mapTile = Map:FindFirstChild(tileName)
            if not mapTile then continue end
            local pdRaw = af:GetAttribute("planeData")
            if not pdRaw then continue end
            local pdOk, pd = pcall(HttpService.JSONDecode, HttpService, pdRaw)
            if not pdOk then continue end
            local hasPlanes = false
            for _, v in pairs(pd) do if v > 0 then hasPlanes = true; break end end
            if not hasPlanes then continue end
            table.insert(result, { mapTile = mapTile, airfield = af, planeData = pd })
        end
        return result
    end

    local function getEnemyAirTiles(enemyHexes)
        local seen, result = {}, {}
        for _, tile in ipairs(Map:GetChildren()) do
            if tile.Name:match("^Sea") then continue end
            local tHex = tile.Color:ToHex()
            if not enemyHexes[tHex] then continue end
            local region = tile:GetAttribute("airRegion")
            if not region or seen[region] then continue end
            local airTile = AirMap:FindFirstChild(region)
            if airTile then seen[region] = true; table.insert(result, airTile) end
        end
        return result
    end

    local function buildPlaneObj(pd)
        if CommonTypes then
            local obj = CommonTypes.PlaneData.new()
            for k, v in pairs(pd) do if obj[k] ~= nil then obj[k] = v end end
            return obj
        end
        return pd
    end

    local function autoPlanesTick(snap)
        if not State.AutoPlanes then return end
        local country = snap.country
        local enemyHexes = getEnemyHexes(country)
        if not next(enemyHexes) then return end
        local airfields = getMyAirfields(country)
        if #airfields == 0 then return end
        local enemyAirTiles = getEnemyAirTiles(enemyHexes)
        if #enemyAirTiles == 0 then return end

        for _, af in ipairs(airfields) do
            for _, targetAirTile in ipairs(enemyAirTiles) do
                local key = af.mapTile.Name .. "_" .. targetAirTile.Name
                if planeDeployed[key] then continue end
                local planeObj = buildPlaneObj(af.planeData)
                local dOk, res = pcall(function()
                    return TryDeployPlanes:InvokeServer(af.mapTile, targetAirTile, planeObj)
                end)
                if dOk and res then
                    planeDeployed[key] = true
                    print(("[AIR] ✓ %s → %s"):format(af.mapTile.Name, targetAirTile.Name))
                    break -- airfield başına 1 hedef yeter
                end
                task.wait(0.3)
            end
        end
    end

    -- Savaş değişince cache temizle
    task.spawn(function()
        while true do
            local country = getCountry()
            if country then
                local dip = country:FindFirstChild("Diplomacy")
                if dip then
                    local enemies = dip:FindFirstChild("Enemies")
                    if enemies then
                        enemies.ChildAdded:Connect(function() planeDeployed = {} end)
                        enemies.ChildRemoved:Connect(function() planeDeployed = {} end)
                    end
                end
            end
            task.wait(10)
        end
    end)

    -- ═══ MEVCUT TERRAIN / TACTICAL ═══════════════════════════
    local TERRAIN_DEF    = { mountain = 4, hills = 2, forest = 1, urban = 1 }
    local ATTACK_RATIO   = 1.1  -- agresif: %10 üstünlük yeterli (eski: 1.4)
    local SURROUND_BONUS = 0.4  -- encirclement bonus artırıldı (eski: 0.25)
    local MAX_ACTIONS    = 30   -- 12→30 hamle per tick
    local CAPITAL_RING   = 1    -- daha dar capital guard → daha fazla ordu front'a
    local TILE_CACHE_TTL = 5
    local PATH_YIELD     = 4
    local MULTI_TARGET   = 4    -- aynı anda max kaç düşmana saldır

    local tileCache = { byHex = {}, lastBuild = 0 }
    local function rebuildCache()
        if os.clock() - tileCache.lastBuild < TILE_CACHE_TTL then return end
        tileCache.byHex = {}
        for _, tile in ipairs(Map:GetChildren()) do
            if tile.Name:match("^Sea") then continue end
            local hex = tile.Color:ToHex()
            if not tileCache.byHex[hex] then tileCache.byHex[hex] = {} end
            table.insert(tileCache.byHex[hex], tile)
        end
        tileCache.lastBuild = os.clock()
    end

    local function uPow(m, tile, role)
        if not m then return 0 end
        local h = numAttr(m,"health"); local a = numAttr(m,"attack"); local d = numAttr(m,"defense"); local e = numAttr(m,"experience")
        local em = 1 + e*0.15; local td = tile and (TERRAIN_DEF[tile:GetAttribute("terrain")] or 0) or 0
        if role == "attack" then return h*a*em elseif role == "defend" then return h*(d+td)*em else return h*(a+d+td)*em end
    end

    local function buildProtected(country)
        local p = {}; local cf = country:FindFirstChild("Cities"); if not cf then return p end
        for _, city in ipairs(cf:GetChildren()) do
            if not city:GetAttribute("isCapital") then continue end
            local root = Map:FindFirstChild(tostring(city:GetAttribute("tileName"))); if not root then continue end
            local frontier = {root}; local visited = {[root]=true}; p[root] = true
            for _ = 1, CAPITAL_RING do
                local nf = {}
                for _, tile in pairs(frontier) do
                    local ns = PreviewPath.neighbours[tile]; if not ns then continue end
                    for _, n in pairs(ns) do if not n.Name:match("^Sea") and not visited[n] then visited[n]=true; p[n]=true; table.insert(nf,n) end end
                end
                frontier = nf
            end
        end; return p
    end

    local function buildAllowed(country, enemyHexes, myHex)
        local a = {[myHex]=true}; local dip = country:FindFirstChild("Diplomacy")
        if dip then for _, fn in ipairs({"Allies","Puppets"}) do local f = dip:FindFirstChild(fn); if f then for _, m in ipairs(f:GetChildren()) do if m.Value then a[m.Value:GetAttribute("color"):ToHex()]=true end end end end end
        for hex in pairs(enemyHexes) do a[hex]=true end; return a
    end

    local function encBonus(t, myHex)
        local ns = PreviewPath.neighbours[t]; if not ns then return 1 end
        local c = 0; for _, n in pairs(ns) do if not n.Name:match("^Sea") and n.Color:ToHex()==myHex then c = c + 1 end end
        return c>=3 and 2 or c==2 and 1.3 or 1
    end

    local function findRes(from, myHex, myColor, used, prot)
        local frontier={from}; local visited={[from]=true}; local best={score=-1,tile=nil,model=nil}
        for _ = 1, 2 do
            local nf={}
            for _, tile in pairs(frontier) do
                local ns = PreviewPath.neighbours[tile]; if not ns then continue end
                for _, n in pairs(ns) do
                    if n.Name:match("^Sea") or visited[n] or n.Color:ToHex()~=myHex or prot[n] then continue end
                    visited[n]=true; table.insert(nf,n)
                    local m = n:FindFirstChildWhichIsA("Model")
                    if m and m:GetAttribute("color")==myColor and m:GetAttribute("state")=="Idle" and not used[m] then
                        local s=uPow(m,n,"attack"); if s>best.score then best={score=s,tile=n,model=m} end
                    end
                end
            end; frontier=nf
        end; return best.tile, best.model
    end

    -- ═══════════════════════════════════════════════════════════════
    -- SOI LIVE SCANNER API — Real-time army intelligence
    -- Works for ANY country. Exposed via getgenv()._SOI
    -- Updates every 2 seconds in background
    -- ═══════════════════════════════════════════════════════════════

    local RS_scan    = game:GetService("ReplicatedStorage")
    local ArmyCm_s   = require(RS_scan.Common.ArmyCommon)
    local TM_s       = ArmyCm_s.terrainModifiers
    local Map_s      = workspace:WaitForChild("Map")
    local PreviewPath_s = require(LocalPlayer.PlayerScripts.PlayerControls.PreviewPath)

    local function _troopCls(m)
        if not m then return "Infantry" end
        local tn = m:GetAttribute("troopName") or ""
        if tn:find("Tank") and not tn:find("Anti") then return "Tanks"
        elseif tn:find("Anti") then return "AntiTank" else return "Infantry" end
    end

    local function _terrCoef(terrain, cls, stat)
        local t = TM_s[terrain]
        if not t then return 1 end
        if stat == "atk" then
            return (cls=="Tanks" and t.TanksAttackCoef) or (cls=="AntiTank" and t.AntiTankAttackCoef) or t.InfantryAttackCoef or 1
        elseif stat == "def" then
            return (cls=="Tanks" and t.TanksDefenseCoef) or (cls=="AntiTank" and t.AntiTankDefenseCoef) or t.InfantryDefenseCoef or 1
        elseif stat == "spd" then
            return (cls=="Tanks" and t.TanksSpeedCoef) or (cls=="AntiTank" and t.AntiTankSpeedCoef) or t.InfantrySpeedCoef or 1
        end
        return 1
    end

    local function _atkPow(m, tile)
        if not m then return 0 end
        local h=m:GetAttribute("health") or 0
        local a=m:GetAttribute("attack") or 0
        local exp=m:GetAttribute("experience") or 0
        local cls=_troopCls(m)
        local terrain=tile and (tile:GetAttribute("terrain") or "none") or "none"
        return h*a*_terrCoef(terrain,cls,"atk")*(1+exp*0.15)
    end

    local function _defPow(m, tile)
        if not m then return 0 end
        local h=m:GetAttribute("health") or 0
        local d=m:GetAttribute("defense") or 0
        local exp=m:GetAttribute("experience") or 0
        local cls=_troopCls(m)
        local terrain=tile and (tile:GetAttribute("terrain") or "none") or "none"
        return h*d*_terrCoef(terrain,cls,"def")*(1+exp*0.15)
    end

    -- Main scan function — works for any country
    local function scanCountry(country)
        if not country then return nil end
        local myColor = country:GetAttribute("color")
        local myHex   = myColor and myColor:ToHex() or ""

        local dip = country:FindFirstChild("Diplomacy")
        local enemyHexes = {}
        local atWar = false
        if dip then
            local ef = dip:FindFirstChild("Enemies")
            if ef then for _, e in ipairs(ef:GetChildren()) do
                if e.Value then
                    enemyHexes[e.Value:GetAttribute("color"):ToHex()] = e.Value
                    atWar = true
                end
            end end
        end

        local result = {
            country     = country.Name,
            atWar       = atWar,
            timestamp   = os.clock(),
            -- Army counts
            total       = 0,
            idle        = 0,
            moving      = 0,
            waiting     = 0,
            onFront     = 0,
            -- Power
            atkPow      = 0,
            defPow      = 0,
            enemyAtkPow = 0,
            enemyDefPow = 0,
            enemyCount  = 0,
            -- Composition
            infantry    = 0,
            tanks       = 0,
            antitank    = 0,
            -- Front
            frontTiles  = 0,
            coveredFront= 0,
            exposedFront= 0,
            coverage    = 0,
            -- Tiles
            myTiles     = 0,
            enemyTiles  = 0,
            -- Derived
            powerRatio  = 0,
            strategy    = "BALANCED",
            -- Individual armies for tactical use
            armies      = {},
            enemyArmies = {},
            exposedTiles= {},
        }

        -- Scan map
        for _, tile in ipairs(Map_s:GetChildren()) do
            if tile.Name:match("^Sea") then continue end
            local tHex = tile.Color:ToHex()
            local m = tile:FindFirstChildWhichIsA("Model")

            if tHex == myHex then
                result.myTiles = result.myTiles + 1
                -- Front check
                local ns = PreviewPath_s.neighbours[tile]
                local isFront, threat = false, 0
                if ns then
                    for _, n in ipairs(ns) do
                        if not n.Name:match("^Sea") and enemyHexes[n.Color:ToHex()] then
                            isFront = true
                            local nm = n:FindFirstChildWhichIsA("Model")
                            threat = threat + (nm and _atkPow(nm,n) or 30)
                        end
                    end
                end
                if isFront then
                    result.frontTiles = result.frontTiles + 1
                    if m then result.coveredFront = result.coveredFront + 1
                    else
                        result.exposedFront = result.exposedFront + 1
                        table.insert(result.exposedTiles, {tile=tile, threat=threat})
                    end
                end
                -- Army stats
                if m then
                    result.total = result.total + 1
                    local st  = m:GetAttribute("state") or "Idle"
                    local cls = _troopCls(m)
                    local ap  = _atkPow(m, tile)
                    local dp  = _defPow(m, tile)
                    if st=="Idle"    then result.idle    = result.idle    + 1 end
                    if st=="Moving"  then result.moving  = result.moving  + 1 end
                    if st=="Waiting" then result.waiting = result.waiting + 1 end
                    if isFront       then result.onFront = result.onFront + 1 end
                    if cls=="Tanks"    then result.tanks    = result.tanks    + 1 end
                    if cls=="AntiTank" then result.antitank = result.antitank + 1 end
                    if cls=="Infantry" then result.infantry = result.infantry + 1 end
                    result.atkPow = result.atkPow + ap
                    result.defPow = result.defPow + dp
                    table.insert(result.armies, {
                        tile=tile, model=m, state=st, cls=cls,
                        atk=ap, def=dp, isFront=isFront, threat=threat,
                        locked=isFront and threat>0 and st=="Idle",
                    })
                end

            elseif enemyHexes[tHex] then
                result.enemyTiles = result.enemyTiles + 1
                if m then
                    result.enemyCount = result.enemyCount + 1
                    local ap = _atkPow(m, tile)
                    local dp = _defPow(m, tile)
                    result.enemyAtkPow = result.enemyAtkPow + ap
                    result.enemyDefPow = result.enemyDefPow + dp
                    local ns2 = PreviewPath_s.neighbours[tile]
                    local enc, adjMine = 1.0, 0
                    if ns2 then
                        for _, n in ipairs(ns2) do
                            if not n.Name:match("^Sea") and n.Color:ToHex()==myHex then adjMine=adjMine+1 end
                        end
                        enc = adjMine==0 and 1 or adjMine==1 and 1.4 or adjMine==2 and 2.0 or adjMine==3 and 3.0 or 4.0
                    end
                    local st = m:GetAttribute("state") or "Idle"
                    local effDef = dp / enc
                    if m:GetAttribute("dieOnNextRetreat") then effDef = effDef * 0.04 end
                    if st=="Retreating" then effDef = effDef * 0.12 end
                    table.insert(result.enemyArmies, {
                        tile=tile, model=m, atk=ap, def=dp, effDef=effDef,
                        enc=enc, state=st, empty=false,
                        dying=m:GetAttribute("dieOnNextRetreat") or false,
                        isCapital=tile:GetAttribute("isCapital") or false,
                    })
                else
                    -- Empty enemy tile
                    local ns2 = PreviewPath_s.neighbours[tile]
                    local adjMine = 0
                    if ns2 then
                        for _, n in ipairs(ns2) do
                            if not n.Name:match("^Sea") and n.Color:ToHex()==myHex then adjMine=adjMine+1 end
                        end
                    end
                    if adjMine > 0 then
                        table.insert(result.enemyArmies, {
                            tile=tile, model=nil, atk=0, def=0, effDef=0,
                            enc=1, state="Empty", empty=true,
                            isCapital=tile:GetAttribute("isCapital") or false,
                        })
                    end
                end
            end
        end

        -- Derived stats
        result.coverage   = result.frontTiles>0 and (result.coveredFront/result.frontTiles) or 1
        result.powerRatio = result.enemyDefPow>0 and (result.atkPow/result.enemyDefPow) or 9

        -- Sort armies: locked front attackers first, then by atk
        table.sort(result.armies, function(a,b)
            if a.locked ~= b.locked then return a.locked end
            return a.atk > b.atk
        end)
        -- Sort enemy: empty/dying first, then weakest effDef
        table.sort(result.enemyArmies, function(a,b)
            if a.empty ~= b.empty then return a.empty end
            if a.dying ~= b.dying then return a.dying end
            if a.isCapital ~= b.isCapital then return a.isCapital end
            return a.effDef < b.effDef
        end)
        -- Sort exposed front tiles by threat
        table.sort(result.exposedTiles, function(a,b) return a.threat>b.threat end)

        -- Strategy
        local cov = result.coverage
        local pr  = result.powerRatio
        if cov < 0.70 then result.strategy = "FORTIFY"
        elseif pr > 2.0 then result.strategy = "CRUSH"
        elseif pr > 1.3 then result.strategy = "AGGRESSIVE"
        elseif pr > 0.8 then result.strategy = "BALANCED"
        else result.strategy = "DEFENSIVE" end

        return result
    end

    -- ═══════════════════════════════════════════════════════════════
    -- LIVE SCANNER — background loop, updates _SOI.data every 2s
    -- ═══════════════════════════════════════════════════════════════
    local SOI_API = {
        data      = nil,       -- latest scan result
        scanning  = true,
        version   = "5.4",
        scan      = scanCountry,  -- call manually: SOI_API.scan(country)
    }
    getgenv()._SOI = SOI_API

    -- HUD GUI — Rayfield'ın üstünde, her zaman görünür
    local function buildHUD()
        local parentGui = playerGui
        pcall(function()
            local cg = game:GetService("CoreGui")
            if cg then parentGui = cg end
        end)
        local old = parentGui:FindFirstChild("SOI_HUD")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "SOI_HUD"; gui.ResetOnSpawn = false
        gui.DisplayOrder = 999; gui.IgnoreGuiInset = true
        gui.Enabled = false
        gui.Parent = parentGui
        engine.hudGui = gui

        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.new(0, 240, 0, 185)
        frame.Position = UDim2.new(0, 8, 0, 8)
        frame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
        frame.BackgroundTransparency = 0.08
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(60, 120, 255); stroke.Thickness = 1.5; stroke.Transparency = 0.4

        -- Title bar
        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1,-8,0,20); title.Position = UDim2.new(0,4,0,4)
        title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "◈ SOI LIVE SCANNER"; title.TextSize = 11
        title.Font = Enum.Font.GothamBold; title.TextColor3 = Color3.fromRGB(100,160,255)

        -- Strategy badge
        local badge = Instance.new("TextLabel", frame)
        badge.Size = UDim2.new(0,80,0,16); badge.Position = UDim2.new(1,-84,0,5)
        badge.BackgroundColor3 = Color3.fromRGB(30,60,140); badge.BackgroundTransparency = 0.2
        badge.BorderSizePixel = 0; badge.Text = "扫描中……"
        badge.TextSize = 9; badge.Font = Enum.Font.GothamBold
        badge.TextColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0,4)

        -- Divider
        local div = Instance.new("Frame", frame)
        div.Size = UDim2.new(1,-16,0,1); div.Position = UDim2.new(0,8,0,26)
        div.BackgroundColor3 = Color3.fromRGB(60,120,255); div.BackgroundTransparency = 0.6; div.BorderSizePixel=0

        -- Stats labels
        local function makeLabel(parent, y, color)
            local lbl = Instance.new("TextLabel", parent)
            lbl.Size = UDim2.new(1,-8,0,14); lbl.Position = UDim2.new(0,4,0,y)
            lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
            lbl.TextColor3 = color or Color3.fromRGB(200,200,220)
            return lbl
        end

        local lblCountry  = makeLabel(frame, 30,  Color3.fromRGB(255,220,100))
        local lblArmies   = makeLabel(frame, 46,  Color3.fromRGB(100,220,100))
        local lblFront    = makeLabel(frame, 62,  Color3.fromRGB(255,180,80))
        local lblPower    = makeLabel(frame, 78,  Color3.fromRGB(120,200,255))
        local lblEnemy    = makeLabel(frame, 94,  Color3.fromRGB(255,100,100))
        local lblSupply   = makeLabel(frame, 110, Color3.fromRGB(200,150,255))
        local lblComp     = makeLabel(frame, 126, Color3.fromRGB(180,180,200))
        local lblStatus   = makeLabel(frame, 148, Color3.fromRGB(150,150,170))
        local lblStrat    = makeLabel(frame, 164, Color3.fromRGB(255,255,255))

        -- Pulse dot
        local dot = Instance.new("Frame", frame)
        dot.Size = UDim2.new(0,6,0,6); dot.Position = UDim2.new(0,6,0,8)
        dot.BackgroundColor3 = Color3.fromRGB(100,255,100); dot.BorderSizePixel=0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

        local TS = game:GetService("TweenService")
        local function pulse()
            TS:Create(dot, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0.8}):Play()
            task.wait(0.6)
            TS:Create(dot, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0}):Play()
        end

        local STRAT_COLORS = {
            FORTIFY   = Color3.fromRGB(255,80,80),
            DEFENSIVE = Color3.fromRGB(255,150,50),
            BALANCED  = Color3.fromRGB(255,220,60),
            AGGRESSIVE= Color3.fromRGB(80,200,255),
            CRUSH     = Color3.fromRGB(80,255,120),
        }

        local function updateHUD(d)
            if not d then
                lblCountry.Text = "尚未选择国家"
                return
            end
            local cov = math.floor(d.coverage * 100)
            local pr  = math.floor(d.powerRatio * 100) / 100
            local stratColor = STRAT_COLORS[d.strategy] or Color3.fromRGB(255,255,255)

            badge.Text = d.strategy
            badge.TextColor3 = stratColor
            badge.BackgroundColor3 = Color3.fromRGB(20,20,40)

            lblCountry.Text  = string.format("Country: %s | War: %s", d.country, d.atWar and "YES" or "no")
            lblArmies.Text   = string.format("Armies: %d  |  Idle:%d  Move:%d  Front:%d", d.total, d.idle, d.moving, d.onFront)
            lblFront.Text    = string.format("Front: %d tiles  |  Covered:%d  EXPOSED:%d  (%d%%)", d.frontTiles, d.coveredFront, d.exposedFront, cov)
            lblPower.Text    = string.format("My ATK:%d  DEF:%d  |  Ratio:%.2fx", d.atkPow, d.defPow, pr)
            lblEnemy.Text    = string.format("Enemy: %d armies  |  ATK:%d  DEF:%d", d.enemyCount, d.enemyAtkPow, d.enemyDefPow)
            lblSupply.Text   = string.format("Tiles: %d", d.myTiles)
            lblComp.Text     = string.format("Inf:%d  Tank:%d  Anti:%d", d.infantry, d.tanks, d.antitank)
            lblStatus.Text   = string.format("Exposed front: %d  |  Enemy empty: %d",
                d.exposedFront,
                (function() local c=0; for _,e in ipairs(d.enemyArmies) do if e.empty then c=c+1 end end; return c end)()
            )
            lstrat_str = string.format("Strategy: %s  |  Power ratio: %.2f", d.strategy, pr)
            lblStrat.Text = lstrat_str
            lblStrat.TextColor3 = stratColor
        end

        return updateHUD, pulse
    end

    local updateHUD, pulseHUD = buildHUD()

    -- Background scanner loop
    task.spawn(function()
        while true do
            local co2 = LocalPlayer:FindFirstChild("Country")
            if co2 and co2.Value then
                local ok, data = pcall(scanCountry, co2.Value)
                if ok and data then
                    SOI_API.data = data
                    pcall(updateHUD, data)
                    pcall(pulseHUD)
                end
            else
                pcall(updateHUD, nil)
            end
            task.wait(2)
        end
    end)

    print("[SOI] Live Scanner active — getgenv()._SOI.data for full data")
    print("[SOI] HUD: top-left corner")

    local function tacticalTickAsync(country)
        -- ═══════════════════════════════════════════════════════
        -- SMART TACTICAL AI v4.0 — Group-based attack
        -- Think first, move second.
        -- 1) Analyze full board
        -- 2) Plan optimal assignments (each army → best target)
        -- 3) Execute all moves simultaneously
        -- Key insight: attackerCount matters — send multiple armies
        -- to same target AT ONCE for coordinated kills
        -- ═══════════════════════════════════════════════════════

        local myColor = country:GetAttribute("color")
        local myHex   = myColor and myColor:ToHex() or ""

        local dip = country:FindFirstChild("Diplomacy")
        local enemyHexes = {}
        local allyHexes  = {}
        local atWar = false

        if dip then
            local ef = dip:FindFirstChild("Enemies")
            if ef then
                for _, e in ipairs(ef:GetChildren()) do
                    if e.Value then
                        enemyHexes[e.Value:GetAttribute("color"):ToHex()] = e.Value
                        atWar = true
                    end
                end
            end
            for _, fn in ipairs({"Allies","Puppets"}) do
                local f = dip:FindFirstChild(fn)
                if f then
                    for _, a in ipairs(f:GetChildren()) do
                        if a.Value then
                            allyHexes[a.Value:GetAttribute("color"):ToHex()] = true
                        end
                    end
                end
            end
        end
        if not atWar then return end

        local allowed = {[myHex]=true}
        for hex in pairs(allyHexes)  do allowed[hex] = true end
        for hex in pairs(enemyHexes) do allowed[hex] = true end

        local prot   = buildProtected(country)
        local pathN  = 0

        rebuildCache()
        local myTiles = tileCache.byHex[myHex] or {}

        local function yPath(from, to)
            pathN = pathN + 1
            if pathN % PATH_YIELD == 0 then task.wait() end
            return PreviewPath.ComputePath(from, to, allowed)
        end

        -- ── TERRAIN & POWER ────────────────────────────────────
        local RS_tc  = game:GetService("ReplicatedStorage")
        local ArmyCm = require(RS_tc.Common.ArmyCommon)
        local TM     = ArmyCm.terrainModifiers

        local function troopCls(m)
            if not m then return "Infantry" end
            local tn = m:GetAttribute("troopName") or ""
            if tn:find("Tank") and not tn:find("Anti") then return "Tanks"
            elseif tn:find("Anti") then return "AntiTank"
            else return "Infantry" end
        end

        local function tm(terrain, cls, stat)
            local t = TM[terrain]
            if not t then return 1 end
            if stat=="atk" then
                return cls=="Tanks" and (t.TanksAttackCoef or 1) or
                       cls=="AntiTank" and (t.AntiTankAttackCoef or 1) or
                       (t.InfantryAttackCoef or 1)
            else
                return cls=="Tanks" and (t.TanksDefenseCoef or 1) or
                       cls=="AntiTank" and (t.AntiTankDefenseCoef or 1) or
                       (t.InfantryDefenseCoef or 1)
            end
        end

        local function atkP(m, tile)
            if not m then return 0 end
            local h=m:GetAttribute("health") or 0
            local a=m:GetAttribute("attack") or 0
            local exp=m:GetAttribute("experience") or 0
            local cls=troopCls(m)
            local ter=tile and (tile:GetAttribute("terrain") or "none") or "none"
            return h * a * tm(ter,cls,"atk") * (1+exp*0.15)
        end

        local function defP(m, tile)
            if not m then return 0 end
            local h=m:GetAttribute("health") or 0
            local d=m:GetAttribute("defense") or 0
            local exp=m:GetAttribute("experience") or 0
            local cls=troopCls(m)
            local ter=tile and (tile:GetAttribute("terrain") or "none") or "none"
            return h * d * tm(ter,cls,"def") * (1+exp*0.15)
        end

        -- ── BOARD SCAN ─────────────────────────────────────────
        local idleArmies  = {}   -- {tile, model, atk, def, onFront}
        local enemyTargets = {}  -- {tile, model, def, enc, empty, isCapital, sv}
        local frontSet    = {}   -- tile → threat
        local capitalTile = nil
        local totalMyAtk  = 0

        -- Capital
        local cf = country:FindFirstChild("Cities")
        if cf then
            for _, city in ipairs(cf:GetChildren()) do
                if city:GetAttribute("isCapital") then
                    capitalTile = Map:FindFirstChild(tostring(city:GetAttribute("tileName") or ""))
                    break
                end
            end
        end

        -- My tiles
        for _, tile in ipairs(myTiles) do
            local m = tile:FindFirstChildWhichIsA("Model")
            local ns = PreviewPath.neighbours[tile]
            local isFront, threat = false, 0
            if ns then
                for _, n in ipairs(ns) do
                    if not n.Name:match("^Sea") and enemyHexes[n.Color:ToHex()] then
                        isFront = true
                        local nm = n:FindFirstChildWhichIsA("Model")
                        threat = threat + (nm and atkP(nm,n) or 30)
                    end
                end
            end
            if isFront then frontSet[tile] = threat end
            if m and m:GetAttribute("state")=="Idle" then
                local ap = atkP(m, tile)
                totalMyAtk = totalMyAtk + ap
                table.insert(idleArmies, {
                    tile    = tile,
                    model   = m,
                    atk     = ap,
                    def     = defP(m, tile),
                    onFront = isFront,
                    adjEnemy = isFront, -- directly adjacent to enemy
                })
            end
        end

        -- Enemy tiles
        local totalEnemyDef = 0
        for hex in pairs(enemyHexes) do
            for _, tile in ipairs(tileCache.byHex[hex] or {}) do
                local m  = tile:FindFirstChildWhichIsA("Model")
                local dp = m and defP(m,tile) or 0
                local ap = m and atkP(m,tile) or 0

                -- Encirclement
                local ns = PreviewPath.neighbours[tile]
                local enc, adjMine = 1.0, 0
                local adjToMe = false
                if ns then
                    for _, n in ipairs(ns) do
                        if not n.Name:match("^Sea") and n.Color:ToHex()==myHex then
                            adjMine = adjMine + 1
                            adjToMe = true
                        end
                    end
                    enc = adjMine==0 and 1 or adjMine==1 and 1.4 or
                          adjMine==2 and 2.0 or adjMine==3 and 3.0 or 4.0
                end

                -- Effective defense (weakened by encirclement, retreat, dying)
                local effDef = dp / enc
                local st = m and (m:GetAttribute("state") or "Idle") or "Empty"
                if m and m:GetAttribute("dieOnNextRetreat") then effDef = effDef * 0.04 end
                if st == "Retreating" then effDef = effDef * 0.12 end

                -- Strategic value
                local sv = 10
                local ter = tile:GetAttribute("terrain") or "none"
                local TSCORE = {mountain=40,hills=25,urban=30,forest=18,desert=10,none=8}
                sv = TSCORE[ter] or 8
                if tile:GetAttribute("isCapital") then sv = sv + 300 end
                if tile:GetAttribute("hasCity")   then sv = sv + 30 end
                sv = sv * enc  -- encircled tiles much more valuable

                totalEnemyDef = totalEnemyDef + dp

                -- Only include tiles adjacent to us (can actually attack)
                if adjToMe or (m == nil) then
                    table.insert(enemyTargets, {
                        tile     = tile,
                        model    = m,
                        def      = dp,
                        effDef   = effDef,
                        atk      = ap,
                        enc      = enc,
                        empty    = (m == nil),
                        isCapital= tile:GetAttribute("isCapital") == true,
                        sv       = sv,
                        adjToMe  = adjToMe,
                        dying    = m and m:GetAttribute("dieOnNextRetreat") or false,
                        retreating = st == "Retreating",
                    })
                end
            end
        end

        -- Sort: empty first, dying second, then by value/difficulty ratio
        table.sort(enemyTargets, function(a, b)
            if a.empty ~= b.empty then return a.empty end
            if a.dying ~= b.dying then return a.dying end
            if a.retreating ~= b.retreating then return a.retreating end
            if a.isCapital ~= b.isCapital then return a.isCapital end
            -- Value per unit of difficulty
            local ra = a.sv / math.max(a.effDef, 1)
            local rb = b.sv / math.max(b.effDef, 1)
            return ra > rb
        end)

        table.sort(idleArmies, function(a, b) return a.atk > b.atk end)

        -- ── STRATEGIC MODE ─────────────────────────────────────
        local frontCount, coveredFront = 0, 0
        for tile, _ in pairs(frontSet) do
            frontCount = frontCount + 1
            if tile:FindFirstChildWhichIsA("Model") then coveredFront = coveredFront + 1 end
        end
        local coverage   = frontCount > 0 and (coveredFront/frontCount) or 1.0
        local powerRatio = totalEnemyDef > 0 and (totalMyAtk/totalEnemyDef) or 9.0

        local strategy
        if coverage < 0.50 then
            strategy = "FORTIFY"
        elseif powerRatio > 2.0 then
            strategy = "CRUSH"
        elseif powerRatio > 1.2 then
            strategy = "AGGRESSIVE"
        elseif powerRatio > 0.7 then
            strategy = "BALANCED"
        else
            strategy = "DEFENSIVE"
        end

        -- ── THINK: PLAN ASSIGNMENTS ────────────────────────────
        -- For each target, calculate minimum armies needed to kill
        -- Then assign armies greedily from strongest to weakest target

        local used    = {}
        local actions = 0
        local plan    = {}  -- list of {army, targetTile, path, priority}

        -- ┌─ STEP 1: Capital always defended ───────────────────
        if capitalTile and not capitalTile:FindFirstChildWhichIsA("Model") then
            local best = {score=-1, model=nil, path=nil}
            for _, a in ipairs(idleArmies) do
                if used[a.model] then continue end
                if a.tile == capitalTile then continue end
                -- prefer defensive armies for capital
                local path = yPath(a.tile, capitalTile)
                if path and a.def > best.score then
                    best = {score=a.def, model=a.model, path=path}
                end
            end
            if best.model then
                table.insert(plan, {model=best.model, path=best.path, priority=1000})
                used[best.model] = true
                actions = actions + 1
            end
        end

        -- ┌─ STEP 2: Fill exposed front tiles (ALWAYS) ─────────
        -- Sort by threat descending
        local exposedFront = {}
        for tile, threat in pairs(frontSet) do
            if not tile:FindFirstChildWhichIsA("Model") then
                table.insert(exposedFront, {tile=tile, threat=threat})
            end
        end
        table.sort(exposedFront, function(a,b) return a.threat > b.threat end)

        for _, ef in ipairs(exposedFront) do
            if actions >= MAX_ACTIONS then break end
            -- Find nearest non-front, non-locked army
            local best = {dist=math.huge, model=nil, path=nil}
            for _, a in ipairs(idleArmies) do
                if used[a.model] then continue end
                if capitalTile and a.tile==capitalTile then continue end
                -- Don't pull a front army away if it's the only defender
                if a.onFront and a.adjEnemy then
                    -- Only pull if another army is adjacent to cover
                    local hasBackup = false
                    local ns = PreviewPath.neighbours[a.tile]
                    if ns then
                        for _, n in ipairs(ns) do
                            if n.Color:ToHex()==myHex then
                                local nm = n:FindFirstChildWhichIsA("Model")
                                if nm and not used[nm] then hasBackup=true; break end
                            end
                        end
                    end
                    if not hasBackup then continue end
                end
                local path = yPath(a.tile, ef.tile)
                if path and #path < best.dist then
                    best = {dist=#path, model=a.model, path=path}
                end
            end
            if best.model then
                table.insert(plan, {model=best.model, path=best.path, priority=500+ef.threat})
                used[best.model] = true
                actions = actions + 1
            else
                -- No path to exposed tile — find nearest front tile instead
                local best2 = {dist=math.huge, model=nil, path=nil}
                for _, a in ipairs(idleArmies) do
                    if used[a.model] then continue end
                    if capitalTile and a.tile==capitalTile then continue end
                    if a.onFront then continue end  -- already on front
                    -- Find any front tile to move toward
                    for ftile, _ in pairs(frontSet) do
                        if ftile:FindFirstChildWhichIsA("Model") then continue end
                        local path = yPath(a.tile, ftile)
                        if path and #path < best2.dist then
                            best2 = {dist=#path, model=a.model, path=path}
                        end
                    end
                end
                if best2.model then
                    table.insert(plan, {model=best2.model, path=best2.path, priority=400})
                    used[best2.model] = true
                    actions = actions + 1
                end
            end
        end

        if strategy == "FORTIFY" then
            -- In FORTIFY: still attack dying/retreating enemies nearby
            for _, target in ipairs(enemyTargets) do
                if actions >= MAX_ACTIONS then break end
                if not (target.dying or target.retreating or target.empty) then continue end
                for _, a in ipairs(idleArmies) do
                    if used[a.model] then continue end
                    if not a.adjEnemy then continue end  -- only front armies
                    local path = yPath(a.tile, target.tile)
                    if path then
                        table.insert(plan, {model=a.model, path=path, priority=200})
                        used[a.model] = true
                        actions = actions + 1
                        break
                    end
                end
            end
            for _, p in ipairs(plan) do safeFire(MoveTroop, p.path) end
            return
        end

        -- ┌─ STEP 3: ATTACK PLANNING ────────────────────────────
        -- For each target: calculate how many armies we need
        -- Send exactly that many — no more, no less
        -- This creates coordinated simultaneous attacks

        local targetAssignments = {}  -- targetTile → {armies assigned}

        for _, target in ipairs(enemyTargets) do
            if actions >= MAX_ACTIONS then break end

            local needed = {}  -- armies assigned to this target
            local totalAssignedAtk = 0

            -- How much attack do we need?
            -- Empty tile: just 1 army
            -- Active defender: need enough to win in reasonable time
            -- Formula: win if totalAtk > effDef * 1.0 (equal = eventual win)
            local atkNeeded = target.empty and 0 or target.effDef * 0.9

            -- Find armies that can reach this target
            -- Prefer armies already adjacent (onFront + adjEnemy near target)
            local candidates = {}
            for _, a in ipairs(idleArmies) do
                if used[a.model] then continue end
                if capitalTile and a.tile==capitalTile then continue end
                -- DEFENSIVE: only attack from front
                if strategy=="DEFENSIVE" and not a.onFront then continue end

                local path = yPath(a.tile, target.tile)
                if not path then continue end

                local pathLen = #path
                -- Prefer adjacent armies (path length 1-2)
                local adjacency_bonus = pathLen <= 2 and 100 or 0
                local score = a.atk + adjacency_bonus - pathLen * 5

                table.insert(candidates, {army=a, path=path, pathLen=pathLen, score=score})
            end

            if #candidates == 0 then continue end

            -- Sort candidates: adjacent first, then strongest
            table.sort(candidates, function(a,b) return a.score > b.score end)

            -- Assign armies until we have enough attack power
            for _, cand in ipairs(candidates) do
                if totalAssignedAtk >= atkNeeded and #needed > 0 then break end
                if used[cand.army.model] then continue end
                -- Don't overload: max 3 armies per target
                if #needed >= 3 then break end

                table.insert(needed, cand)
                totalAssignedAtk = totalAssignedAtk + cand.army.atk
                used[cand.army.model] = true
                actions = actions + 1
            end

            if #needed > 0 then
                for _, cand in ipairs(needed) do
                    table.insert(plan, {
                        model = cand.army.model,
                        path  = cand.path,
                        priority = target.sv + totalAssignedAtk
                    })
                end
                targetAssignments[target.tile] = needed
            end
        end

        -- ┌─ STEP 4: Develop remaining armies ──────────────────
        -- Any idle army not assigned yet → push toward best front target
        local frontTargets = {}
        for hex in pairs(enemyHexes) do
            local bestSV, bestTile = -1, nil
            for _, tile in ipairs(tileCache.byHex[hex] or {}) do
                local ns2 = PreviewPath.neighbours[tile]
                if not ns2 then continue end
                local adj = false
                for _, n in ipairs(ns2) do
                    if not n.Name:match("^Sea") and n.Color:ToHex()==myHex then adj=true; break end
                end
                if not adj then continue end
                local sv = tile:GetAttribute("isCapital") and 300 or 50
                if sv > bestSV then bestSV=sv; bestTile=tile end
            end
            if bestTile then table.insert(frontTargets, {tile=bestTile, sv=bestSV, hex=hex}) end
        end
        table.sort(frontTargets, function(a,b) return a.sv>b.sv end)

        for _, a in ipairs(idleArmies) do
            if actions >= MAX_ACTIONS then break end
            if used[a.model] then continue end
            if capitalTile and a.tile==capitalTile then continue end
            if prot[a.tile] and not frontSet[a.tile] then continue end

            local best = {score=-math.huge, path=nil}
            for _, ft in ipairs(frontTargets) do
                local path = yPath(a.tile, ft.tile)
                if path then
                    local sc = ft.sv - #path * 3
                    if sc > best.score then best={score=sc, path=path} end
                end
            end
            if best.path then
                table.insert(plan, {model=a.model, path=best.path, priority=10})
                used[a.model] = true
                actions = actions + 1
            end
        end

        -- ┌─ EXECUTE: All moves at once ─────────────────────────
        -- Sort by priority (highest first)
        table.sort(plan, function(a,b) return a.priority > b.priority end)
        for _, p in ipairs(plan) do
            safeFire(MoveTroop, p.path)
        end
    end

            local function buildSnapshot()
        local country=getCountry(); if not country then return nil end
        local atWar=false; local dip=country:FindFirstChild("Diplomacy"); local enemyColors={}
        if dip then local ef=dip:FindFirstChild("Enemies"); if ef then for _,e in ipairs(ef:GetChildren()) do if e.Value then atWar=true; enemyColors[e.Value:GetAttribute("color"):ToHex()]=e.Value end end end end
        local myColor=country:GetAttribute("color"); local myHex=myColor and myColor:ToHex() or ""
        local myUnits,enemyUnits,frontTiles={},{},{}
        for _,tile in ipairs(Map:GetChildren()) do
            if tile.Name:match("^Sea") then continue end
            local tHex=tile.Color:ToHex(); local model=tile:FindFirstChildWhichIsA("Model")
            if model then
                local mHex=(model:GetAttribute("color") and model:GetAttribute("color"):ToHex()) or ""
                local tn=model:GetAttribute("troopName") or ""; local cls=tn:find("Tank") and "Tanks" or tn:find("Anti") and "AntiTank" or "Infantry"
                local u={tile=tile,model=model,health=numAttr(model,"health"),attack=numAttr(model,"attack"),defense=numAttr(model,"defense"),state=model:GetAttribute("state"),class=cls}
                if mHex==myHex then table.insert(myUnits,u) elseif enemyColors[tHex] then table.insert(enemyUnits,u) end
            end
            if tHex==myHex then local ns=PreviewPath.neighbours[tile]; if ns then for _, n in pairs(ns) do if not n.Name:match("^Sea") and enemyColors[n.Color:ToHex()] then frontTiles[tile]=true; break end end end end
        end
        return {atWar=atWar,country=country,myColorHex=myHex,myColor=myColor,enemyColors=enemyColors,economy={money=numAttr(country,"money"),manpower=numAttr(country,"manpower")},myUnits=myUnits,enemyUnits=enemyUnits,frontTiles=frontTiles}
    end

    local lastFacAt=0
    local function autoFactoryTick(snap)
        if os.clock()-lastFacAt<10 then return end
        local c=snap.country; local money=snap.economy.money; local manpower=snap.economy.manpower
        local citiesF=c:FindFirstChild("Cities"); if not citiesF then return end
        local techs=c:FindFirstChild("Techs"); local mpCost=numAttr(techs,"factoryManpowerPrice",100); local reserve=snap.atWar and 25000 or 6000
        local ecoF=c:FindFirstChild("Economy"); local cgIncome=numAttr(ecoF,"consumerGoodsTaxIncome")
        local prodF=c:FindFirstChild("ProductionItems"); local cgIt=prodF and prodF:FindFirstChild("Consumer Goods")
        local marginal=cgIncome*math.max(cgIt and numAttr(cgIt,"factoriesValue") or 0.3,0.05)
        local bestCity,bestCost=nil,math.huge
        for _,city in ipairs(citiesF:GetChildren()) do
            local maxFac=numAttr(city,"maxFactories"); if maxFac<=0 then continue end
            if numAttr(city,"factories")>=maxFac or city:GetAttribute("factoryBuildStart") then continue end
            local tile=Map:FindFirstChild(tostring(city:GetAttribute("tileName")))
            if tile and snap.frontTiles[tile] then continue end
            local cost=numAttr(techs,"factoryPrice",1000)*(1+numAttr(city,"factories")*numAttr(techs,"factoryPriceMultiplier",0.25)+numAttr(c,"factories")*numAttr(techs,"factoryTotalPriceMultiplier",0.1))
            if cost<bestCost then bestCost=cost; bestCity=city end
        end
        if not bestCity or money-bestCost<reserve or manpower-mpCost<10000 then return end
        if bestCost/math.max(marginal,0.01)>150 and money-bestCost<reserve*2 then return end
        safeFire(PurchaseFactory,bestCity); lastFacAt=os.clock()
    end

    local SUPPLY_P={"Infantry Equipment","Anti-Tank","Tank Parts","Fuel"}
    local SUP_CLS={Infantry="Infantry Equipment",AntiTank="Anti-Tank",Tanks="Tank Parts"}
    local sliderSt,refillM={},{}
    local function applySlider(item,target)
        local name=item.Name; local now=os.clock(); local ss=sliderSt[name]
        if not ss then ss={lastAt=0,votes=0,lastDir=0}; sliderSt[name]=ss end
        local delta=target-numAttr(item,"factoriesValue")
        if math.abs(delta)<0.02 then if ss.votes>0 then ss.votes = votes - 1 end; return end
        local dir=delta>0 and 1 or -1; if dir~=ss.lastDir then ss.votes=1; ss.lastDir=dir else ss.votes = votes + 1 end
        if ss.votes>=3 and now-ss.lastAt>=8 then safeFire(SetProductionPct,item,math.clamp(target,0,1)); ss.lastAt=now; ss.votes=0 end
    end
    local function autoProductionTick(snap)
        local c=snap.country; local prodF=c:FindFirstChild("ProductionItems"); if not prodF then return end
        local items={}; for _,it in ipairs(prodF:GetChildren()) do items[it.Name]=it end
        if not snap.atWar then
            local unman=0; for name, it in pairs(items) do if name~="Consumer Goods" and not table.find(SUPPLY_P,name) then unman = unman + numAttr(it,"factoriesValue") end end
            for _, name in pairs(SUPPLY_P) do if items[name] then applySlider(items[name],0) end end
            if items["Consumer Goods"] then applySlider(items["Consumer Goods"],math.clamp(1-unman,0,1)) end; return
        end
        local classes={}; for _, u in pairs(snap.myUnits) do if u.class then classes[u.class]=true end end
        local armyF=c:FindFirstChild("Army"); local clsF=armyF and armyF:FindFirstChild("Classes")
        if clsF then for _,cl in ipairs(clsF:GetChildren()) do if numAttr(cl,"target")>0 then classes[cl.Name]=true end end end
        local desired,supTotal={},0
        for _, name in pairs(SUPPLY_P) do
            local it=items[name]; if not it then continue end
            local wanted=name=="Fuel" and classes.Tanks==true or false
            if not wanted then for cls, sup in pairs(SUP_CLS) do if sup==name and classes[cls] then wanted=true end end end
            local stock=numAttr(it,"stock"); local maxSt=numAttr(it,"maxStock",20); local cons=numAttr(it,"consumption")
            local refilling=refillM[name]
            if refilling then if stock>=maxSt*0.95 then refillM[name]=false; refilling=false end elseif stock<maxSt*0.7 then refillM[name]=true; refilling=true end
            local target=0
            if wanted and refilling then local curSh=numAttr(it,"factoriesValue"); local prod=numAttr(it,"production"); local need=cons*1.25+(maxSt-stock)*0.05; target=(curSh>0.005 and prod>0) and math.clamp(curSh*need/prod,0,1) or 0.08 end
            desired[name]=target; supTotal = supTotal + target
        end
        if supTotal>0.7 then local excess=supTotal-0.7; for i=#SUPPLY_P,1,-1 do local name=SUPPLY_P[i]; local s=desired[name] or 0; if excess<=0 then break end; local cut=math.min(s,excess); desired[name]=s-cut; excess = excess - cut end; supTotal=0.7 end
        local unman=0; for name, it in pairs(items) do if name~="Consumer Goods" and not table.find(SUPPLY_P,name) then unman = unman + numAttr(it,"factoriesValue") end end
        for name, share in pairs(desired) do if items[name] then applySlider(items[name],share) end end
        if items["Consumer Goods"] then applySlider(items["Consumer Goods"],math.clamp(1-supTotal-unman,0,1)) end
    end

    local ROMAN={I=1,V=5,X=10}
    local function romanToNum(s) local t,p=0,0; for i=#s,1,-1 do local v=ROMAN[s:sub(i,i)] or 0; if v<p then t = t - v else t = t + v; p=v end end; return t end
    local function baseName(n) return (n:gsub("%s+[IVX]+$","")) end
    local function tierOf(n) local r=n:match("%s([IVX]+)$"); return r and romanToNum(r) or 0 end
    local function techDone(nd) return nd:GetAttribute("progress")==1 end
    local function techInProg(nd) local p=nd:GetAttribute("progress"); return type(p)=="number" and p>0 and p<1 end
    local function prereqMet(country,techName)
        local spec=ResearchCommon.techs and ResearchCommon.techs[techName]
        if not spec or not spec.required then return true end
        for _, rn in pairs(spec.required) do
            local nd=country.Techs:FindFirstChild(rn)
            if not nd or not techDone(nd) then return false end
        end
        return true
    end

    -- ═══════════════════════════════════════════════════════
    -- SMART RESEARCH ENGINE
    -- Para durumu, savaş fazı, düşman kompozisyonu,
    -- tech sinerji zinciri, ROI analizi ile karar verir
    -- ═══════════════════════════════════════════════════════

    -- Tech kategorileri ve öncelikleri
    local TECH_CATEGORY = {
        -- Savaş techleri
        ["Infantry Equipment"]       = "infantry",
        ["Infantry Attack Equipment"]= "infantry",
        ["Infantry Armor"]           = "infantry",
        ["Support Equipment"]        = "infantry",
        ["Anti-Tank"]                = "antitank",
        ["Tank Parts"]               = "armor",
        ["Tank Turret"]              = "armor",
        ["Mechanization"]            = "armor",
        ["Fighter"]                  = "air",
        ["CAS"]                      = "air",
        ["Bomber"]                   = "air",
        ["Anti Air"]                 = "air",
        ["Destroyer"]                = "naval",
        ["Battleship"]               = "naval",
        ["Submarine"]                = "naval",
        ["Transport Ship"]           = "naval",
        ["Shipyard"]                 = "naval",
        -- Ekonomi techleri
        ["Industry"]                 = "economy",
        ["Underground Industry"]     = "economy",
        ["Housing"]                  = "economy",
        ["Fortifications"]           = "defense",
        -- Özel
        ["Intelligence"]             = "intel",
        ["Ballistic Missiles"]       = "missile",
        ["Uranium Mining"]           = "nuke",
        ["Uranium Enrichment"]       = "nuke",
        ["Nuke"]                     = "nuke",
        ["Nuclear Protection"]       = "nuke",
    }

    local function getTechCategory(techName)
        local base = baseName(techName)
        return TECH_CATEGORY[base] or "other"
    end

    -- ROI: Bu tech'in getirisi ne kadar?
    -- Düşük tier + düşük fiyat + yüksek etki = yüksek ROI
    local function calcROI(nd, price, tier, category, snap, money)
        local roi = 0

        -- Temel: düşük fiyat = yüksek ROI (daha fazla tech alabiliriz)
        roi = roi + math.max(0, 500 - price) * 0.1

        -- Tier: düşük tier önce (sinerji zinciri için)
        roi = roi + (4 - math.min(tier, 4)) * 40

        -- Savaş fazı bonusları
        if snap.atWar then
            -- Aktif savaşta: askeri tech çok değerli
            if category == "infantry" then roi = roi + 120 end
            if category == "antitank" then
                -- Düşmanda tank varsa anti-tank kritik
                local tankRatio = snap.enemyUnits and
                    (function()
                        local t, tot = 0, 0
                        for _, u in pairs(snap.enemyUnits) do
                            tot = tot + 1
                            if u.class == "Tanks" then t = t + 1 end
                        end
                        return tot > 0 and t/tot or 0
                    end)() or 0
                roi = roi + tankRatio * 200
            end
            if category == "armor" then
                local infRatio = snap.enemyUnits and
                    (function()
                        local t, tot = 0, 0
                        for _, u in pairs(snap.enemyUnits) do
                            tot = tot + 1
                            if u.class == "Infantry" then t = t + 1 end
                        end
                        return tot > 0 and t/tot or 0
                    end)() or 0
                roi = roi + infRatio * 150
            end
            if category == "air"     then roi = roi + 80  end
            if category == "defense" then roi = roi + 60  end
            if category == "economy" then roi = roi + 20  end -- savaşta ekonomi az öncelik
        else
            -- Barışta: ekonomi ve altyapı önce
            if category == "economy" then roi = roi + 180 end
            if category == "defense" then roi = roi + 100 end
            if category == "infantry" then roi = roi + 60 end
            if category == "intel"   then roi = roi + 70  end
        end

        -- Preset bonusu
        for _, sel in pairs(State.ResearchBases) do
            local selBase = baseName(sel)
            local ndBase  = baseName(nd.Name)
            if selBase == ndBase then roi = roi + 800 end
        end

        -- Para durumuna göre: az para = ucuz tech önce
        local moneyRatio = money / math.max(price, 1)
        if moneyRatio < 3 then
            -- Az para: en ucuz tech'i al, hızlıca araştır
            roi = roi + math.max(0, 300 - price) * 0.3
        elseif moneyRatio > 10 then
            -- Çok para: yüksek tier ve değerli tech'leri al
            roi = roi + tier * 30
        end

        -- Sinerji: bu tech başka bir tech'in prereq'u mu?
        -- prereq'u olan tech: araştırılınca daha fazla kapı açılır
        if ResearchCommon.techs then
            local opensDoors = 0
            for tName, tSpec in pairs(ResearchCommon.techs) do
                if tSpec.required then
                    for _, req in ipairs(tSpec.required) do
                        if req == nd.Name then
                            opensDoors = opensDoors + 1
                            break
                        end
                    end
                end
            end
            roi = roi + opensDoors * 25 -- her kapı açılan tech +25
        end

        -- Speed: research hız tech'leri varsa daha hızlı biter
        local techsF = snap.country:FindFirstChild("Techs")
        local resSpeed = techsF and techsF:GetAttribute("researchSpeedMultiplier") or 1
        roi = roi * resSpeed -- araştırma hızı yüksekse tüm tech'ler daha değerli

        return roi
    end

    -- Para yönetimi: ne kadar harcayabiliriz?
    local function calcBudget(money, snap)
        local atWar = snap.atWar
        -- Savaşta: ordu bakımı için reserve
        -- Barışta: fabrika inşası için reserve
        local reserve = atWar and 30000 or 15000
        -- Çok fazla para varsa daha agresif harca
        if money > 200000 then reserve = reserve * 0.5 end
        local available = math.max(0, money - reserve)
        -- Max tek seferde paranın %60'ını harca
        return math.min(available, money * 0.6)
    end

    local lastResBuyAt = 0
    local function autoResearchTick(snap)
        local c = snap.country
        local techsF = c:FindFirstChild("Techs")
        if not techsF then return end

        local money = snap.economy.money

        -- Slot durumu
        local free, slotted = 0, {}
        local slotsF = c:FindFirstChild("ResearchSlots")
        if slotsF then
            for _, sl in ipairs(slotsF:GetChildren()) do
                if sl:IsA("ObjectValue") then
                    if sl.Value == nil then free = free + 1
                    else slotted[sl.Value] = true end
                end
            end
        end

        if free <= 0 then return end

        -- Önce: satın alınmış ama araştırılmamış tech'leri başlat (ücretsiz)
        for _, nd in ipairs(techsF:GetChildren()) do
            if free <= 0 then break end
            if nd:GetAttribute("purchased") == true and
               not techDone(nd) and not techInProg(nd) and not slotted[nd] then
                safeFire(StartResearch, nd)
                free = free - 1
                slotted[nd] = true
                print("[RES] Starting purchased:", nd.Name)
            end
        end

        if free <= 0 then return end

        -- Cooldown: çok hızlı satın alma engeli
        if os.clock() - lastResBuyAt < 8 then return end

        -- Budget hesapla
        local budget = calcBudget(money, snap)
        if budget <= 0 then return end

        -- Araştırılabilir tech'leri topla (prereq karşılanmış, yapılmamış)
        local candidates = {}
        local bestPerBase = {}

        for _, nd in ipairs(techsF:GetChildren()) do
            if techDone(nd) or techInProg(nd) or slotted[nd] then continue end
            if nd:GetAttribute("purchased") == true then continue end
            if not prereqMet(c, nd.Name) then continue end

            local price = nd:GetAttribute("price") or math.huge
            if price > budget then continue end -- parası yok

            local tier     = tierOf(nd.Name)
            local base     = baseName(nd.Name)
            local category = getTechCategory(nd.Name)
            local roi      = calcROI(nd, price, tier, category, snap, money)

            -- Her base'den en iyi tier'ı seç (önce düşük tier — sinerji)
            local cur = bestPerBase[base]
            if not cur or tier < cur.tier or (tier == cur.tier and roi > cur.roi) then
                bestPerBase[base] = {
                    node     = nd,
                    tier     = tier,
                    price    = price,
                    roi      = roi,
                    base     = base,
                    category = category,
                }
            end
        end

        -- Kandidatları ROI'ya göre sırala
        for _, e in pairs(bestPerBase) do
            table.insert(candidates, e)
        end
        table.sort(candidates, function(a, b)
            if math.abs(a.roi - b.roi) > 50 then return a.roi > b.roi end
            if a.tier ~= b.tier then return a.tier < b.tier end
            return a.price < b.price
        end)

        if #candidates == 0 then return end

        -- En iyi tech'leri al (budget dolana kadar)
        local spent = 0
        for _, cand in ipairs(candidates) do
            if free <= 0 then break end
            if spent + cand.price > budget then continue end

            local paid = safeInvoke(TryPurchaseTech, cand.node)
            if not paid then continue end

            safeFire(StartResearch, cand.node)
            spent   = spent + cand.price
            free    = free - 1
            slotted[cand.node] = true
            lastResBuyAt = os.clock()

            print(("[RES] Bought: %s (T%d) $%d ROI:%.0f"):format(
                cand.node.Name, cand.tier, cand.price, cand.roi))
        end
    end

    local WAR_KW={"attack","fighter","bomber","tank","fleet","naval","military","draft","uranium","atomic","defense","missile","artillery","infantry","armor","combat","war","blitz"}
    local ECO_KW={"factory","productivity","research speed","cost","industry","economy","trade","housing","mobilization","output","civil"}
    local function classifyFocus(f)
        local text=string.lower(f.Name); local lines=decodeJ(f:GetAttribute("effectLines")); if lines then for _, l in pairs(lines) do text..=" "..string.lower(l) end end
        local tt=f:GetAttribute("tooltipDescription"); if tt then text..=" "..string.lower(tt) end
        local ws,es=0,0; for _, kw in pairs(WAR_KW) do if text:find(kw,1,true) then ws = ws + 1 end end; for _, kw in pairs(ECO_KW) do if text:find(kw,1,true) then es = es + 1 end end
        if ws>es then return "War" elseif es>ws then return "Economy" end; return "Neutral"
    end
    local function autoGovernmentTick(snap)
        local c=snap.country; local gov=c:FindFirstChild("Government"); if not gov then return end
        local focuses=gov:FindFirstChild("Focuses"); if not focuses then return end
        local current=decodeJ(gov:GetAttribute("currentFocuses")) or {}; local eligible={}
        for _,f in ipairs(focuses:GetChildren()) do
            if f:GetAttribute("progress")~=1 and not table.find(current,f.Name) then
                local req=decodeJ(f:GetAttribute("required")) or {}; local ok=true
                for _, rn in pairs(req) do local rf=focuses:FindFirstChild(rn); if not rf or rf:GetAttribute("progress")~=1 then ok=false; break end end
                if ok then table.insert(eligible,f) end
            end
        end
        if #eligible==0 then return end
        local wantCat=State.GovernmentMode=="Economy" and "Economy" or "War"; local rank={Neutral=2}; rank[wantCat]=1
        table.sort(eligible,function(a,b) local ra=rank[classifyFocus(a)] or 3; local rb=rank[classifyFocus(b)] or 3; if ra~=rb then return ra<rb end; return numAttr(a,"ppCost")<numAttr(b,"ppCost") end)
        safeInvoke(TryStartFocus,eligible[1])
    end

    local function autoArmyTick(snap)
        local c=snap.country; local army=c:FindFirstChild("Army"); if not army then return end
        local clsF=army:FindFirstChild("Classes"); if not clsF then return end
        local target=State.ArmySpawnFocus=="Tank" and "Tanks" or "Infantry"
        for _,cl in ipairs(clsF:GetChildren()) do if cl.Name==target then safeInvoke(TryIncreaseTarget,cl) end end
    end

    -- Active tactical thread'leri track et -- toggle kapanınca hepsini kill et
    local activeTacticalThreads = {}
    local function cancelTacticalThreads()
        for _, thread in ipairs(activeTacticalThreads) do
            pcall(task.cancel, thread)
        end
        activeTacticalThreads = {}
    end
    engine.cancelTacticalThreads = cancelTacticalThreads

    task.spawn(function()
        local tacticalRunning = false
        while true do
            if State.SmartMovement then
                -- Mutex: bir önceki tick bitmeden yenisi başlasın
                if not tacticalRunning then
                    local co2 = LocalPlayer:FindFirstChild("Country")
                    if co2 and co2.Value then
                        tacticalRunning = true
                        local thread = task.spawn(function()
                            pcall(tacticalTickAsync, co2.Value)
                            tacticalRunning = false
                        end)
                        table.insert(activeTacticalThreads, thread)
                    end
                end
                -- Biten thread'leri temizle
                local alive = {}
                for _, t in ipairs(activeTacticalThreads) do
                    if coroutine.status(t) ~= "dead" then
                        table.insert(alive, t)
                    end
                end
                activeTacticalThreads = alive
            else
                tacticalRunning = false
                if #activeTacticalThreads > 0 then
                    cancelTacticalThreads()
                end
            end
            task.wait(4)  -- 2s → 4s: daha az çakışma
        end
    end)

    local lastNatAt = 0
    task.spawn(function()
        while true do
            if os.clock() - lastNatAt >= 3 then -- 5→3 saniye
                lastNatAt = os.clock()
                local ok, snap = pcall(buildSnapshot)
                if ok and snap then
                    if State.AutoFactory    then pcall(autoFactoryTick,    snap) end
                    if State.AutoProduction then pcall(autoProductionTick,  snap) end
                    if State.AutoGovernment then pcall(autoGovernmentTick,  snap) end
                    if State.AutoArmy       then pcall(autoArmyTick,        snap) end
                    if State.AutoResearch   then pcall(autoResearchTick,    snap) end
                    if State.AutoDiplomacy  then pcall(autoRealDipTick,     snap) end
                    if State.AutoMissile    then pcall(autoMissileTick,     snap) end
                    if State.AutoSilo       then pcall(autoSiloTick,        snap) end
                    if State.AutoNaval      then pcall(autoNavalTick,       snap) end
                    if State.AutoPlanes     then pcall(autoPlanesTick,      snap) end
                end
            end
            task.wait(1)
        end
    end)


        return true
    end

    return engine
end)()

----------------------------------------------------------------
-- WW2 SETTINGS PANELS
----------------------------------------------------------------
MODULE_SETTINGS_OPENERS["Smart Movement"] = function(anchorRow)
    local panel, cy = createCustomPanel("Smart Movement", 280, 260)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Тактический ИИ (Group Rush)" or "战术 AI（集群突击）",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 54), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "HP-симуляция боёв. Авто-захват пустых клеток, координированная атака дивизиями на 1 цель (требуемый шанс победы: 85%), защита столицы. Лимит 30 ходов/тик."
            or "HP-based combat sim. Captures empty tiles first, coordinates group attacks on high-value targets (85% win chance), capital defense. 30 moves/tick limit.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 60
    createPresetButton(panel, CURRENT_LANG == "RU" and "СБРОСИТЬ ПОТОКИ ТАКТИКИ" or "停止战术任务", 14, cy, 252, false, function()
        if Ww2Engine and Ww2Engine.cancelTacticalThreads then
            Ww2Engine.cancelTacticalThreads()
            HUD.notify(CURRENT_LANG == "RU" and "Потоки тактики сброшены" or "战术任务已停止", "success")
        end
    end)
    cy = cy + 34
    createPresetButton(panel, CURRENT_LANG == "RU" and "ТАКТИЧЕСКИЙ РАДАР (HUD)" or "战术扫描器（HUD）", 14, cy, 252, false, function()
        if Ww2Engine and Ww2Engine.toggleHud then
            local active = Ww2Engine.toggleHud()
            HUD.notify(active and (CURRENT_LANG == "RU" and "Радар включен" or "雷达已开启") or (CURRENT_LANG == "RU" and "Радар скрыт" or "雷达已隐藏"), "accent")
        end
    end)
end

MODULE_SETTINGS_OPENERS["Auto Army"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Army", 280, 220)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Фокус призыва дивизий:" or "部队招募重点：",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    cy = createPresetChoices(panel, cy, { "Infantry Focus", "Tank Focus" }, function()
        return (Ww2Engine.State.ArmySpawnFocus == "Tank") and "Tank Focus" or "Infantry Focus"
    end, function(choice)
        Ww2Engine.State.ArmySpawnFocus = (choice == "Tank Focus") and "Tank" or "Infantry"
        HUD.notify("Army Focus: " .. Ww2Engine.State.ArmySpawnFocus, "accent")
    end)
    cy = cy + 6
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 36), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Автоматически заказывает выбранный тип дивизий во всех подконтрольных центрах набора и городах."
            or "Automatically recruits selected division types across all controlled recruitment cities.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Auto Factory"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Factory", 280, 180)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Авто-строительство заводов" or "自动建设工业",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 24
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 60), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Возводит гражданские и военные заводы в доступных городах страны, поддерживая баланс между экономическим ростом и военным производством."
            or "Constructs civilian and military factories in available domestic cities, balancing industrial development with defense needs.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Auto Production"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Production", 280, 180)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Оптимизация производства" or "工厂生产平衡",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 24
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 60), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Регулирует ползунки выпуска техники, оружия и боеприпасов, гарантируя достаточное снабжение дивизий на фронте."
            or "Dynamically balances equipment, ammunition and supply sliders ensuring frontlines remain fully supplied.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Auto Government"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Government", 280, 220)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Национальный фокус:" or "国家方针：",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    cy = createPresetChoices(panel, cy, { "War Focused", "Economy Focused" }, function()
        return (Ww2Engine.State.GovernmentMode == "Economy") and "Economy Focused" or "War Focused"
    end, function(choice)
        Ww2Engine.State.GovernmentMode = (choice == "Economy Focused") and "Economy" or "War"
        HUD.notify("Gov Mode: " .. Ww2Engine.State.GovernmentMode, "accent")
    end)
    cy = cy + 6
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 36), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Автоматически активирует национальные реформы и фокусы по выбранной стратегии развития."
            or "Automatically advances government focus trees according to chosen doctrine.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Auto Diplomacy"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Diplomacy", 280, 230)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Дипломатический ИИ" or "外交 AI 与战争理由",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 54), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Оправдывает войну на слабых соседей, объявляет войну при готовности казус белли. Отправляет мирный договор, если силы врага превосходят в 2.5 раза."
            or "Justifies war on weaker neighbors, declares war when ready, requests peace treaty if outmatched 2.5x.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 58
    createPresetButton(panel, CURRENT_LANG == "RU" and "СБРОСИТЬ ОПРАВДАНИЯ" or "清除战争理由", 14, cy, 252, false, function()
        if Ww2Engine and Ww2Engine.dipState then
            Ww2Engine.dipState.justifying = {}
            HUD.notify(CURRENT_LANG == "RU" and "Список оправданий очищен" or "已清除战争理由", "success")
        end
    end)
end

MODULE_SETTINGS_OPENERS["Auto Missiles"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Missiles", 280, 190)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Ракетные удары" or "战略导弹打击",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 24
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 60), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Запускает баллистические и ядерные ракеты по вражеским столицам, шахтам и скоплениям сил. Кулдаун 20 сек. Требуются построенные шахты и боеголовки."
            or "Launches ballistic & nuclear strikes on enemy capitals and silos. 20s cooldown. Requires silo and ammo.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Auto Naval"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Naval", 280, 230)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Морской десант" or "海上登陆",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 54), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Погрузка отборной пехоты на транспортные корабли в портах, выход флота в открытое море и высадка десанта прямо на побережье вражеской столицы."
            or "Embarks infantry divisions onto transport ships, sails fleet through sea zones and launches coastal assault on enemy capital.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 58
    createPresetButton(panel, CURRENT_LANG == "RU" and "СБРОСИТЬ СОСТОЯНИЕ ФЛОТА" or "重置舰队状态", 14, cy, 252, false, function()
        if Ww2Engine and Ww2Engine.navalState then
            Ww2Engine.navalState.phase = "idle"
            Ww2Engine.navalState.usedArmies = {}
            HUD.notify(CURRENT_LANG == "RU" and "Состояние флота сброшено" or "已重置海军状态", "success")
        end
    end)
end

MODULE_SETTINGS_OPENERS["Auto Air Force"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Air Force", 280, 230)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Развертывание авиации" or "空军部署",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 54), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Автоматически отправляет звенья истребителей и штурмовиков во все спорные воздушные зоны со всех аэродромов страны."
            or "Automatically deploys fighter wings and CAS squadrons to contested airspace from all domestic airfields.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 58
    createPresetButton(panel, CURRENT_LANG == "RU" and "СБРОСИТЬ РАЗВЕРТКУ ВВС" or "重置空军部署", 14, cy, 252, false, function()
        if Ww2Engine and Ww2Engine.planeDeployed then
            table.clear(Ww2Engine.planeDeployed)
            HUD.notify(CURRENT_LANG == "RU" and "Развертка авиации сброшена" or "已重置空军部署", "success")
        end
    end)
end

MODULE_SETTINGS_OPENERS["Auto Silo"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Silo", 280, 190)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Ракетные шахты" or "自动建造导弹井",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 24
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 60), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Автоматически строит и улучшает шахты в безопасных тыловых регионах, сохраняя $20k резерв казны. Требует изучения баллистических ракет."
            or "Builds & upgrades silos on safe non-frontline tiles while preserving a $20,000 national treasury reserve. Requires Ballistic Missiles tech.",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["Auto Research"] = function(anchorRow)
    local panel, cy = createCustomPanel("Auto Research", 300, 310)
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU" and "Пресеты науки (+1000 очков):" or "科研预设（+1000 优先级）：",
        TextColor3 = COLORS.header, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
    cy = cy + 22
    local presets = { "Infantry Meta", "Tank Meta", "Air Meta", "Naval Meta", "Nuke Rush" }
    for _, name in ipairs(presets) do
        local isCur = Ww2Engine and Ww2Engine.currentPreset == name
        createPresetButton(panel, name, 14, cy, 272, isCur, function()
            if Ww2Engine and Ww2Engine.applyPreset then
                Ww2Engine.applyPreset(name)
                Ww2Engine.currentPreset = name
                HUD.notify("Research: " .. name .. " applied", "accent")
            end
        end)
        cy = cy + 32
    end
    cy = cy + 4
    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 36), Position = UDim2.new(0, 14, 0, cy),
        BackgroundTransparency = 1,
        Text = CURRENT_LANG == "RU"
            and "Автоматически начинает исследование технологий по кулдауну с приоритетом для выбранной ветки."
            or "Automatically queues technologies according to meta weights (+1000 base priority).",
        TextColor3 = COLORS.textDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel,
    })
end

MODULE_SETTINGS_OPENERS["HUD"] = function(row) if HUD.openSettings then HUD.openSettings(row) end end
MODULE_SETTINGS_OPENERS["Auto Combo"] = function(row) HUD.openAutoComboSettings(row) end
MODULE_SETTINGS_OPENERS["Speed"] = function(row) HUD.openVehicleSpeedSettings(row) end
MODULE_SETTINGS_OPENERS["Brakes"] = function(row) HUD.openVehicleBrakesSettings(row) end
MODULE_SETTINGS_OPENERS["Handling"] = function(row) HUD.openVehicleHandlingSettings(row) end
MODULE_SETTINGS_OPENERS["Teleport to"] = function(row) HUD.openVehicleTeleportSettings(row) end

local function createModuleRow(parent, moduleName, order, onToggle)
    local rowState = { enabled = false, hovered = false }
    HUD.moduleStates[moduleName] = false
 
    local row = create("TextButton", {
        Name = moduleName,
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = COLORS.off,
        BackgroundTransparency = moduleTransparency,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(row, 12)
    local rowStroke = stroke(row)
    rowStroke.Transparency = 0.5
    bindTheme(rowStroke, "Color", function() return rowState.enabled and "accent" or "stroke" end)
 
    bindTheme(row, "BackgroundColor3", function()
        if rowState.hovered then return "hover" end
        return "off"
    end)
 
    local label = create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -150, 0, 22),
        Position = UDim2.fromOffset(18, 11),
        BackgroundTransparency = 1,
        Text = MODULE_ZH[moduleName] or moduleName,
        TextColor3 = COLORS.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
        TextSize = 15,
        Parent = row,
    })
 
    bindTheme(label, "TextColor3", function()
        return "text"
    end)

    local statusLabel = create("TextLabel", {
        Name = "StateLabel", Position = UDim2.fromOffset(18, 37), Size = UDim2.new(1, -150, 0, 14),
        Text = CURRENT_LANG == "RU" and "已关闭" or "已关闭", TextSize = 9,
        Font = Enum.Font.GothamMedium, TextColor3 = COLORS.textDim,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = row,
    })
    local function refreshStateText()
        statusLabel.Text = CURRENT_LANG == "RU" and (rowState.enabled and "已开启" or "已关闭")
            or (rowState.enabled and "已开启" or "已关闭")
    end

    local settingsHint = create("TextButton", {
        Name = "SettingsHint", Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -100, 0.5, -15), BackgroundTransparency = 1,
        Text = "⋯", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = COLORS.textDim,
        AutoButtonColor = false, Visible = MODULE_SETTINGS_OPENERS[moduleName] ~= nil,
        Parent = row,
    })
    settingsHint.Activated:Connect(function()
        local opener = MODULE_SETTINGS_OPENERS[moduleName]
        if opener then opener(row) end
    end)
 
    local toggle = create("Frame", {
        Name = "Toggle",
        Size = UDim2.new(0, 38, 0, 22),
        Position = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = COLORS.stroke,
        Parent = row,
    })
    corner(toggle, 11)
    stroke(toggle)
 
    bindTheme(toggle, "BackgroundColor3", function()
        return rowState.enabled and "accent" or "stroke"
    end)
 
    -- Контрастная ручка: тёмная на белом акценте, светлая в выключенном состоянии.
    local knob = create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 4, 0.5, -7),
        BackgroundColor3 = COLORS.textDim,
        BorderSizePixel = 0,
        themeBind = false,
        Parent = toggle,
    })
    corner(knob, 7)
    bindTheme(knob, "BackgroundColor3", function() return rowState.enabled and "panel" or "textDim" end)
 
    local function setState(state)
        state = state == true
        if rowState.enabled == state then return end
        rowState.enabled = state
        local goalPos = rowState.enabled and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
        local goalToggleColor = rowState.enabled and COLORS.accent or COLORS.stroke
        local goalTextColor = COLORS.text
 
        -- Плавный iOS squash-and-stretch тумблер
        local animSpeed = (gameplayConfig.uiEffects and gameplayConfig.uiEffects.animSpeed) or 1.0
        local dur = 0.22 / animSpeed
        local squashWidth = 18
        tween(knob, { Size = UDim2.new(0, squashWidth, 0, 14) }, dur * 0.4, Enum.EasingStyle.Quart)
        task.delay(dur * 0.45, function()
            if knob.Parent then
                tween(knob, { Size = UDim2.new(0, 14, 0, 14) }, dur * 0.55, Enum.EasingStyle.Back)
            end
        end)
        tween(knob, { Position = goalPos, BackgroundColor3 = rowState.enabled and COLORS.panel or COLORS.textDim }, dur, Enum.EasingStyle.Quart)
        tween(toggle, { BackgroundColor3 = goalToggleColor }, dur)
        tween(label, { TextColor3 = goalTextColor }, dur)
 
        tween(rowStroke, { Color = rowState.enabled and COLORS.accent or COLORS.stroke }, dur)
 
        refreshStateText()
 
        if onToggle then
            onToggle(state)
        end
        HUD.moduleStates[moduleName] = state
        if HUD.refreshModuleSummary then HUD.refreshModuleSummary() end
        if not HUD.actionModules[moduleName] then
            HUD.notify(moduleName .. (state and "  •  ON" or "  •  OFF"), state and "success" or "info")
        end
    end

    registerRuntimeCleanup(function()
        if rowState.enabled then setState(false) end
    end)
 
    row.MouseEnter:Connect(function()
        rowState.hovered = true
        if settingsHint.Visible then tween(settingsHint, { TextTransparency = 0 }, 0.15) end
        if not rowState.enabled then
            tween(row, { BackgroundColor3 = COLORS.hover, BackgroundTransparency = moduleTransparency }, 0.15)
            tween(label, { TextColor3 = COLORS.text }, 0.15)
        end
    end)
    row.MouseLeave:Connect(function()
        rowState.hovered = false
        if settingsHint.Visible then tween(settingsHint, { TextTransparency = 0.25 }, 0.15) end
        if not rowState.enabled then
            tween(row, { BackgroundColor3 = COLORS.off, BackgroundTransparency = moduleTransparency }, 0.15)
            tween(label, { TextColor3 = COLORS.text }, 0.15)
        end
    end)
 
    row.Activated:Connect(function()
        setState(not rowState.enabled)
    end)
 
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            local opener = MODULE_SETTINGS_OPENERS[moduleName]
            if opener then
                opener(row)
            else
                local content, cy = createCustomPanel(moduleName, 350, 420)
                local info = create("Frame", {
                    Size = UDim2.new(1, -28, 0, 62), Position = UDim2.new(0, 14, 0, cy),
                    BackgroundColor3 = COLORS.off, BackgroundTransparency = 0.12,
                    Parent = content,
                })
                corner(info, 7)
                stroke(info, COLORS.stroke, 0.5)
                create("TextLabel", {
                    Size = UDim2.new(1, -20, 1, -12), Position = UDim2.new(0, 10, 0, 6),
                    BackgroundTransparency = 1,
                    Text = "此功能没有更多设置。",
                    TextWrapped = true, TextColor3 = COLORS.textDim,
                    Font = Enum.Font.GothamSemibold, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = info,
                })
            end
        end
    end)
 
    table.insert(allModuleRows, { row = row, name = moduleName:lower(), searchName = (MODULE_ZH[moduleName] or ""):lower(), category = parent:GetAttribute("Category"), refreshText = refreshStateText })
    return row, setState
end
 
-- Обновляет прозрачность фона у всех уже созданных строк модулей разом
-- (вызывается при движении слайдера "功能卡片透明度" в Theme Dock).
refreshModuleTransparency = function()
    for _, entry in ipairs(allModuleRows) do
        if entry.row.Parent then
            tween(entry.row, { BackgroundTransparency = moduleTransparency }, 0.2)
        end
    end
end
 
local function buildModule(list, moduleName, j)
    if moduleName == "HUD" then
        local _, setHudToggle = createModuleRow(list, moduleName, j, function(state)
            if HUD.setMasterEnabled then HUD.setMasterEnabled(state) end
        end)
        task.defer(setHudToggle, true)

        -- ═══════════════════════════════════════════════════════
        -- SKYBOX — Пресеты неба (Galaxy, Night, Cloudy, Fog, Custom)
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Skybox" then
            local _skyboxEnabled = false
            local SKYBOX_PRESETS = {
                Galaxy = {
                    Bk = "rbxassetid://159454299",
                    Dn = "rbxassetid://159454296",
                    Ft = "rbxassetid://159454293",
                    Lf = "rbxassetid://159454286",
                    Rt = "rbxassetid://159454300",
                    Up = "rbxassetid://159454288",
                    stars = 5000, celestial = true,
                    atmoColor = Color3.fromRGB(45, 25, 75), atmoDecay = Color3.fromRGB(20, 10, 40),
                    atmoDensity = 0.25, atmoHaze = 1.2, atmoGlare = 0.05,
                    clockTime = 0,
                },
                Night = {
                    Bk = "rbxassetid://12064107",
                    Dn = "rbxassetid://12064152",
                    Ft = "rbxassetid://12064121",
                    Lf = "rbxassetid://12064115",
                    Rt = "rbxassetid://12064131",
                    Up = "rbxassetid://12064147",
                    stars = 4000, celestial = true,
                    atmoColor = Color3.fromRGB(15, 18, 35), atmoDecay = Color3.fromRGB(8, 10, 25),
                    atmoDensity = 0.35, atmoHaze = 1.8, atmoGlare = 0.0,
                    clockTime = 0,
                },
                Sunset = {
                    Bk = "rbxassetid://600830446",
                    Dn = "rbxassetid://600831635",
                    Ft = "rbxassetid://600832720",
                    Lf = "rbxassetid://600886090",
                    Rt = "rbxassetid://600833862",
                    Up = "rbxassetid://600835177",
                    stars = 600, celestial = true,
                    atmoColor = Color3.fromRGB(255, 135, 80), atmoDecay = Color3.fromRGB(180, 50, 70),
                    atmoDensity = 0.3, atmoHaze = 2.4, atmoGlare = 0.35,
                    clockTime = 17.8,
                },
                Cloudy = {
                    Bk = "rbxassetid://252760980",
                    Dn = "rbxassetid://252763895",
                    Ft = "rbxassetid://252761439",
                    Lf = "rbxassetid://252760981",
                    Rt = "rbxassetid://252760986",
                    Up = "rbxassetid://252762652",
                    stars = 0, celestial = false,
                    atmoColor = Color3.fromRGB(190, 215, 245), atmoDecay = Color3.fromRGB(140, 170, 210),
                    atmoDensity = 0.38, atmoHaze = 1.0, atmoGlare = 0.2,
                    clockTime = 14,
                },
                Cyberpunk = {
                    Bk = "rbxassetid://271042310",
                    Dn = "rbxassetid://271077243",
                    Ft = "rbxassetid://271042516",
                    Lf = "rbxassetid://271042440",
                    Rt = "rbxassetid://271042479",
                    Up = "rbxassetid://271077958",
                    stars = 3500, celestial = true,
                    atmoColor = Color3.fromRGB(180, 40, 220), atmoDecay = Color3.fromRGB(40, 180, 230),
                    atmoDensity = 0.42, atmoHaze = 2.8, atmoGlare = 0.45,
                    clockTime = 21,
                },
                ["Blood Moon"] = {
                    Bk = "rbxassetid://888204683",
                    Dn = "rbxassetid://888204787",
                    Ft = "rbxassetid://888204895",
                    Lf = "rbxassetid://888205001",
                    Rt = "rbxassetid://888205105",
                    Up = "rbxassetid://888205209",
                    stars = 2500, celestial = true,
                    atmoColor = Color3.fromRGB(160, 20, 20), atmoDecay = Color3.fromRGB(80, 5, 10),
                    atmoDensity = 0.4, atmoHaze = 2.0, atmoGlare = 0.2,
                    clockTime = 0,
                },
                Custom = {
                    Bk = "rbxassetid://159454299",
                    Dn = "rbxassetid://159454296",
                    Ft = "rbxassetid://159454293",
                    Lf = "rbxassetid://159454286",
                    Rt = "rbxassetid://159454300",
                    Up = "rbxassetid://159454288",
                    stars = 3000, celestial = true,
                    atmoColor = nil, atmoDecay = nil,
                    atmoDensity = 0.3, atmoHaze = 1.5, atmoGlare = 0.1,
                    clockTime = 0,
                },
            }

            local function applySkyboxPreset()
                if not _skyboxEnabled then return end
                local preset = SKYBOX_PRESETS[_skyboxPreset] or SKYBOX_PRESETS.Galaxy
                -- Sky
                local sky = Lighting:FindFirstChild("SolaraSkybox")
                if sky then sky:Destroy() end
                sky = Instance.new("Sky")
                sky.Name = "SolaraSkybox"
                sky.CelestialBodiesShown = preset.celestial ~= false
                sky.StarCount = preset.stars or 3000
                sky.SkyboxBk = preset.Bk or preset.skyId
                sky.SkyboxDn = preset.Dn or preset.skyId
                sky.SkyboxFt = preset.Ft or preset.skyId
                sky.SkyboxLf = preset.Lf or preset.skyId
                sky.SkyboxRt = preset.Rt or preset.skyId
                sky.SkyboxUp = preset.Up or preset.skyId
                sky.Parent = Lighting
                -- Atmosphere
                local atmo = Lighting:FindFirstChild("SolaraAtmosphere")
                if atmo then atmo:Destroy() end
                atmo = Instance.new("Atmosphere")
                atmo.Name = "SolaraAtmosphere"
                atmo.Density = preset.atmoDensity or 0.3
                atmo.Offset = 0.2
                atmo.Color = preset.atmoColor or COLORS.accent
                atmo.Decay = preset.atmoDecay or COLORS.panel
                atmo.Glare = preset.atmoGlare or 0.1
                atmo.Haze = preset.atmoHaze or 1.5
                atmo.Parent = Lighting
                if preset.clockTime then
                    pcall(function() Lighting.ClockTime = preset.clockTime end)
                end
            end

            visualApply.skybox = applySkyboxPreset

            createModuleRow(list, moduleName, j, function(state)
                _skyboxEnabled = state
                if state then
                    applySkyboxPreset()
                else
                    local sky = Lighting:FindFirstChild("SolaraSkybox")
                    if sky then sky:Destroy() end
                    local atmo = Lighting:FindFirstChild("SolaraAtmosphere")
                    if atmo then atmo:Destroy() end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- BETTER FPS — Реальная оптимизация по уровням
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Better FPS" then
            local _fpsEnabled = false
            local _cachedEffects = setmetatable({}, { __mode = "k" })
            local _scanThread = nil
            local _cullThread = nil
            local _descAddedConn = nil

            local function cacheAndOptimizeEffect(obj)
                if not obj or not obj.Parent then return end
                if obj.Name:sub(1, 6) == "Solara" then return end

                if obj:IsA("ParticleEmitter") then
                    if _cachedEffects[obj] == nil then
                        _cachedEffects[obj] = {
                            kind = "Particle",
                            rate = obj.Rate,
                            lifetime = obj.Lifetime,
                            enabled = obj.Enabled,
                        }
                    end
                elseif obj:IsA("Beam") then
                    if _cachedEffects[obj] == nil then
                        _cachedEffects[obj] = {
                            kind = "Beam",
                            segments = obj.Segments,
                            enabled = obj.Enabled,
                        }
                    end
                elseif obj:IsA("Trail") then
                    if _cachedEffects[obj] == nil then
                        _cachedEffects[obj] = {
                            kind = "Trail",
                            lifetime = obj.Lifetime,
                            enabled = obj.Enabled,
                        }
                    end
                elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    if _cachedEffects[obj] == nil then
                        local sz = 0
                        pcall(function() sz = obj.Size end)
                        _cachedEffects[obj] = {
                            kind = "FireSmoke",
                            size = sz,
                            enabled = obj.Enabled,
                        }
                    end
                elseif obj:IsA("Explosion") then
                    if _cachedEffects[obj] == nil then
                        _cachedEffects[obj] = {
                            kind = "Explosion",
                            visible = obj.Visible,
                        }
                    end
                end
            end

            local function restoreAllEffects()
                for obj, orig in pairs(_cachedEffects) do
                    if obj.Parent then
                        pcall(function()
                            if orig.kind == "Particle" then
                                obj.Rate = orig.rate
                                obj.Lifetime = orig.lifetime
                                obj.Enabled = orig.enabled
                            elseif orig.kind == "Beam" then
                                obj.Segments = orig.segments
                                obj.Enabled = orig.enabled
                            elseif orig.kind == "Trail" then
                                obj.Lifetime = orig.lifetime
                                obj.Enabled = orig.enabled
                            elseif orig.kind == "FireSmoke" then
                                pcall(function() obj.Size = orig.size end)
                                obj.Enabled = orig.enabled
                            elseif orig.kind == "Explosion" then
                                obj.Visible = orig.visible
                            end
                        end)
                    end
                end
                table.clear(_cachedEffects)
            end

            local function evaluateDistanceCulling()
                if not _fpsEnabled then return end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local camPos = cam.CFrame.Position
                local level = _betterFpsLevel or 1
                local distThreshold = (level == 1) and 180 or ((level == 2) and 120 or 80)

                for obj, orig in pairs(_cachedEffects) do
                    if obj.Parent then
                        local pos = nil
                        local p = obj.Parent
                        if p:IsA("BasePart") or p:IsA("Attachment") then
                            pos = p.WorldPosition
                        elseif p.Parent and (p.Parent:IsA("BasePart") or p.Parent:IsA("Model")) then
                            local root = p.Parent:FindFirstChild("HumanoidRootPart") or p.Parent:FindFirstChildWhichIsA("BasePart")
                            if root then pos = root.Position end
                        end

                        if pos then
                            local dist = (camPos - pos).Magnitude
                            if dist > distThreshold and _betterFpsDistanceCull then
                                if orig.kind == "Particle" then
                                    local mult = (level == 1) and 0.65 or ((level == 2) and 0.40 or 0.20)
                                    obj.Rate = math.max(1, math.floor(orig.rate * mult))
                                elseif orig.kind == "Beam" then
                                    local seg = (level == 1) and 6 or ((level == 2) and 4 or 2)
                                    if orig.segments > seg then obj.Segments = seg end
                                elseif orig.kind == "Trail" then
                                    local mult = (level == 1) and 0.80 or ((level == 2) and 0.50 or 0.30)
                                    obj.Lifetime = orig.lifetime * mult
                                elseif orig.kind == "FireSmoke" then
                                    if level >= 2 then
                                        pcall(function() obj.Size = math.max(1, orig.size * 0.6) end)
                                    end
                                elseif orig.kind == "Explosion" then
                                    if level >= 2 and dist > 150 then
                                        obj.Visible = false
                                    end
                                end
                                if level == 3 and dist > 260 then
                                    obj.Enabled = false
                                end
                            else
                                if orig.kind == "Particle" then
                                    obj.Rate = orig.rate
                                    obj.Lifetime = orig.lifetime
                                    obj.Enabled = orig.enabled
                                elseif orig.kind == "Beam" then
                                    obj.Segments = orig.segments
                                    obj.Enabled = orig.enabled
                                elseif orig.kind == "Trail" then
                                    obj.Lifetime = orig.lifetime
                                    obj.Enabled = orig.enabled
                                elseif orig.kind == "FireSmoke" then
                                    pcall(function() obj.Size = orig.size end)
                                    obj.Enabled = orig.enabled
                                elseif orig.kind == "Explosion" then
                                    obj.Visible = orig.visible
                                end
                            end
                        end
                    end
                end
            end

            local function scanWorkspaceEffects()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    cacheAndOptimizeEffect(obj)
                end
            end

            local function applyBetterFps()
                if not _fpsEnabled then return end
                scanWorkspaceEffects()
                evaluateDistanceCulling()
            end

            visualApply.betterFps = function()
                if _fpsEnabled then
                    evaluateDistanceCulling()
                end
            end

            createModuleRow(list, moduleName, j, function(state)
                _fpsEnabled = state
                visualApply.betterFpsEnabled = state
                if state then
                    applyBetterFps()
                    _descAddedConn = workspace.DescendantAdded:Connect(function(desc)
                        if _fpsEnabled then
                            cacheAndOptimizeEffect(desc)
                        end
                    end)
                    _scanThread = task.spawn(function()
                        while _fpsEnabled and runtimeAlive do
                            task.wait(3)
                            if _fpsEnabled then scanWorkspaceEffects() end
                        end
                    end)
                    _cullThread = task.spawn(function()
                        while _fpsEnabled and runtimeAlive do
                            task.wait(1.5)
                            if _fpsEnabled then evaluateDistanceCulling() end
                        end
                    end)
                else
                    if _descAddedConn then _descAddedConn:Disconnect(); _descAddedConn = nil end
                    restoreAllEffects()
                end
            end)

        elseif moduleName == "RTX Graphics" then
            local _rtxEnabled = false
            local _hasOriginals = false
            local _origLighting = {}
            local _origAtmo = nil
            local _origEffects = {}
            local _origTerrain = {}
            local _origQuality = nil

            local RTX_PROFILES = {
                Performance = {
                    bloomInt = 0.15, bloomSize = 16, bloomThresh = 1.3,
                    raysEnabled = false, raysInt = 0, raysSpread = 0,
                    ccSat = 0.05, ccContrast = 0.05, ccTint = Color3.fromRGB(255, 255, 255), ccBright = 0,
                    atmoEnabled = false,
                    exposure = 0.02, diffuse = 0.8, specular = 0.8, shadowSoftness = 0.3,
                    ambient = nil, outdoorAmbient = nil, brightness = nil,
                    waterRefl = 0.2, waterTransp = 0.35, waterWave = 0.08, waterSpeed = 6,
                },
                Balanced = {
                    bloomInt = 0.25, bloomSize = 20, bloomThresh = 1.15,
                    raysEnabled = true, raysInt = 0.07, raysSpread = 0.62,
                    ccSat = 0.08, ccContrast = 0.08, ccTint = Color3.fromRGB(255, 252, 248), ccBright = 0.01,
                    atmoEnabled = true,
                    atmoDensity = 0.24, atmoColor = Color3.fromRGB(195, 205, 222), atmoDecay = Color3.fromRGB(105, 112, 126),
                    atmoHaze = 0.7, atmoGlare = 0.1, atmoOffset = 0.08,
                    exposure = 0.04, diffuse = 0.95, specular = 1.0, shadowSoftness = 0.2,
                    ambient = Color3.fromRGB(45, 45, 52), outdoorAmbient = Color3.fromRGB(110, 115, 125), brightness = 2,
                    waterRefl = 0.35, waterTransp = 0.4, waterWave = 0.10, waterSpeed = 8,
                },
                Ultra = {
                    bloomInt = 0.32, bloomSize = 24, bloomThresh = 1.10,
                    raysEnabled = true, raysInt = 0.10, raysSpread = 0.68,
                    ccSat = 0.11, ccContrast = 0.11, ccTint = Color3.fromRGB(255, 250, 244), ccBright = 0.015,
                    atmoEnabled = true,
                    atmoDensity = 0.26, atmoColor = Color3.fromRGB(190, 202, 220), atmoDecay = Color3.fromRGB(98, 105, 120),
                    atmoHaze = 0.9, atmoGlare = 0.15, atmoOffset = 0.10,
                    exposure = 0.06, diffuse = 1.0, specular = 1.0, shadowSoftness = 0.15,
                    ambient = Color3.fromRGB(50, 50, 58), outdoorAmbient = Color3.fromRGB(115, 120, 132), brightness = 2.2,
                    waterRefl = 0.48, waterTransp = 0.45, waterWave = 0.13, waterSpeed = 10,
                },
            }

            local function captureOriginals()
                if _hasOriginals then return end
                _hasOriginals = true

                pcall(function()
                    _origQuality = UserSettings():GetService("UserGameSettings").SavedQualityLevel
                end)

                local okDiff, valDiff = pcall(function() return Lighting.EnvironmentDiffuseScale end)
                local okSpec, valSpec = pcall(function() return Lighting.EnvironmentSpecularScale end)
                local okExp, valExp = pcall(function() return Lighting.ExposureCompensation end)
                local okSoft, valSoft = pcall(function() return Lighting.ShadowSoftness end)
                local okBright, valBright = pcall(function() return Lighting.Brightness end)
                local okAmb, valAmb = pcall(function() return Lighting.Ambient end)
                local okOut, valOut = pcall(function() return Lighting.OutdoorAmbient end)
                local okTech, valTech = pcall(function() return Lighting.Technology end)
                local okTime, valTime = pcall(function() return Lighting.ClockTime end)

                _origLighting = {
                    shadows = Lighting.GlobalShadows,
                    diffuse = okDiff and valDiff or 1,
                    specular = okSpec and valSpec or 1,
                    exposure = okExp and valExp or 0,
                    shadowSoftness = okSoft and valSoft or 0.5,
                    brightness = okBright and valBright or 2,
                    ambient = okAmb and valAmb or Color3.fromRGB(128, 128, 128),
                    outdoorAmbient = okOut and valOut or Color3.fromRGB(128, 128, 128),
                    technology = okTech and valTech or nil,
                    clockTime = okTime and valTime or 14,
                }

                -- Существующая атмосфера игры (не SolaraRTXAtmo)
                local existingAtmo = Lighting:FindFirstChildOfClass("Atmosphere")
                if existingAtmo and existingAtmo.Name ~= "SolaraRTXAtmo" then
                    _origAtmo = {
                        instance = existingAtmo,
                        density = existingAtmo.Density,
                        offset = existingAtmo.Offset,
                        color = existingAtmo.Color,
                        decay = existingAtmo.Decay,
                        glare = existingAtmo.Glare,
                        haze = existingAtmo.Haze,
                    }
                else
                    _origAtmo = nil
                end

                -- Существующие эффекты постабработки игры (отключаем на время Solara RTX)
                _origEffects = {}
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if (effect:IsA("PostEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect"))
                        and effect.Name:sub(1, 9) ~= "SolaraRTX" and effect.Name ~= "SolaraCC" and effect.Name ~= "SolaraBlur" then
                        _origEffects[effect] = effect.Enabled
                        effect.Enabled = false
                    end
                end

                -- Свойства воды Terrain
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    _origTerrain = {
                        refl = pcall(function() return terrain.WaterReflectance end) and terrain.WaterReflectance or 0,
                        transp = pcall(function() return terrain.WaterTransparency end) and terrain.WaterTransparency or 0,
                        waveSz = pcall(function() return terrain.WaterWaveSize end) and terrain.WaterWaveSize or 0,
                        waveSpd = pcall(function() return terrain.WaterWaveSpeed end) and terrain.WaterWaveSpeed or 0,
                        deco = pcall(function() return terrain.Decoration end) and terrain.Decoration or false,
                    }
                end
            end

            local function restoreOriginals()
                if not _hasOriginals then return end

                -- Удаляем только SolaraRTX объекты
                for _, name in ipairs({"SolaraRTXBloom", "SolaraRTXRays", "SolaraRTXDOF", "SolaraRTXCC", "SolaraRTXAtmo"}) do
                    local eff = Lighting:FindFirstChild(name)
                    if eff then eff:Destroy() end
                end

                -- Восстанавливаем существующую атмосферу игры
                if _origAtmo and _origAtmo.instance and _origAtmo.instance.Parent == Lighting then
                    pcall(function()
                        _origAtmo.instance.Density = _origAtmo.density
                        _origAtmo.instance.Offset = _origAtmo.offset
                        _origAtmo.instance.Color = _origAtmo.color
                        _origAtmo.instance.Decay = _origAtmo.decay
                        _origAtmo.instance.Glare = _origAtmo.glare
                        _origAtmo.instance.Haze = _origAtmo.haze
                    end)
                end
                _origAtmo = nil

                -- Восстанавливаем оригинальные эффекты постабработки
                for eff, state in pairs(_origEffects) do
                    if eff and eff.Parent then
                        pcall(function() eff.Enabled = state end)
                    end
                end
                _origEffects = {}

                -- Восстанавливаем свойства Lighting
                if _origLighting.shadows ~= nil then Lighting.GlobalShadows = _origLighting.shadows end
                pcall(function() Lighting.ShadowSoftness = _origLighting.shadowSoftness or 0.5 end)
                pcall(function() Lighting.Brightness = _origLighting.brightness or 2 end)
                pcall(function() Lighting.ExposureCompensation = _origLighting.exposure or 0 end)
                pcall(function() Lighting.Ambient = _origLighting.ambient or Color3.fromRGB(128, 128, 128) end)
                pcall(function() Lighting.OutdoorAmbient = _origLighting.outdoorAmbient or Color3.fromRGB(128, 128, 128) end)
                pcall(function() Lighting.EnvironmentDiffuseScale = _origLighting.diffuse or 1 end)
                pcall(function() Lighting.EnvironmentSpecularScale = _origLighting.specular or 1 end)
                if _origLighting.technology ~= nil then
                    pcall(function() Lighting.Technology = _origLighting.technology end)
                end

                -- Восстанавливаем качество рендера
                if _origQuality ~= nil then
                    pcall(function()
                        UserSettings():GetService("UserGameSettings").SavedQualityLevel = _origQuality
                    end)
                end

                -- Восстанавливаем Terrain
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain and _origTerrain.refl ~= nil then
                    pcall(function() terrain.WaterReflectance = _origTerrain.refl end)
                    pcall(function() terrain.WaterTransparency = _origTerrain.transp end)
                    pcall(function() terrain.WaterWaveSize = _origTerrain.waveSz end)
                    pcall(function() terrain.WaterWaveSpeed = _origTerrain.waveSpd end)
                    pcall(function() terrain.Decoration = _origTerrain.deco end)
                end

                _hasOriginals = false
                reapplyLightingOverrides()
            end

            local function applyRtxGraphics()
                if not _rtxEnabled then return end
                local profile = RTX_PROFILES[_rtxPreset] or RTX_PROFILES.Balanced
                local isCinematic = gameplayConfig.rtxCinematic == true
                local fpsLevel = visualApply.betterFpsEnabled and (visualApply.betterFpsLevel or 2) or 0
                local performanceScale = ({ [0] = 1, 0.85, 0.65, 0.4 })[fpsLevel] or 1
                local intensity = math.clamp((gameplayConfig.rtxIntensity or 1) * performanceScale, 0.2, 2.0)

                -- 1. Качество графики UserSettings (с уважением к Better FPS)
                pcall(function()
                    local userSettings = UserSettings():GetService("UserGameSettings")
                    if userSettings then
                        local qualities = {
                            [0] = Enum.SavedQualitySetting.QualityLevel10,
                            Enum.SavedQualitySetting.QualityLevel5,
                            Enum.SavedQualitySetting.QualityLevel3,
                            Enum.SavedQualitySetting.QualityLevel1,
                        }
                        userSettings.SavedQualityLevel = qualities[fpsLevel]
                    end
                end)

                -- 2. Technology (Future / ShadowMap при доступности)
                if fpsLevel < 2 and (_rtxPreset == "Ultra" or _rtxPreset == "Balanced") then
                    pcall(function()
                        Lighting.Technology = Enum.Technology.Future
                    end)
                end

                -- 3. Освещение и тени
                Lighting.GlobalShadows = fpsLevel < 2
                pcall(function() Lighting.ShadowSoftness = profile.shadowSoftness end)
                pcall(function() Lighting.ExposureCompensation = profile.exposure * intensity end)
                pcall(function() Lighting.EnvironmentDiffuseScale = profile.diffuse end)
                pcall(function() Lighting.EnvironmentSpecularScale = profile.specular end)
                if profile.brightness and fpsLevel < 2 then
                    pcall(function() Lighting.Brightness = profile.brightness end)
                end
                if profile.ambient and fpsLevel < 2 then
                    pcall(function() Lighting.Ambient = profile.ambient end)
                end
                if profile.outdoorAmbient and fpsLevel < 2 then
                    pcall(function() Lighting.OutdoorAmbient = profile.outdoorAmbient end)
                end

                -- 4. ColorCorrection (Цветокоррекция & Контраст — глубокий, естественный вид)
                local cc = Lighting:FindFirstChild("SolaraRTXCC") or Instance.new("ColorCorrectionEffect")
                cc.Name = "SolaraRTXCC"
                cc.Enabled = true
                cc.Saturation = math.clamp(profile.ccSat * intensity, 0, 0.25)
                cc.Contrast = math.clamp(profile.ccContrast * intensity, 0, 0.25)
                cc.TintColor = isCinematic and Color3.fromRGB(255, 248, 240) or profile.ccTint
                cc.Brightness = profile.ccBright
                cc.Parent = Lighting

                -- 5. Bloom (Свечение ТОЛЬКО ярких источников, Threshold > 1.0 предотвращает молочный экран)
                local bloom = Lighting:FindFirstChild("SolaraRTXBloom") or Instance.new("BloomEffect")
                bloom.Name = "SolaraRTXBloom"
                bloom.Enabled = true
                bloom.Intensity = math.clamp(profile.bloomInt * intensity * (isCinematic and 1.15 or 1.0), 0.05, 0.8)
                bloom.Size = profile.bloomSize
                bloom.Threshold = profile.bloomThresh
                bloom.Parent = Lighting

                -- 6. SunRays (Деликатные лучи солнца / God Rays)
                local rays = Lighting:FindFirstChild("SolaraRTXRays") or Instance.new("SunRaysEffect")
                rays.Name = "SolaraRTXRays"
                local enableRays = profile.raysEnabled and (fpsLevel < 2)
                rays.Enabled = enableRays
                if enableRays then
                    rays.Intensity = math.clamp((profile.raysInt + (isCinematic and 0.02 or 0)) * intensity, 0.02, 0.25)
                    rays.Spread = profile.raysSpread
                end
                rays.Parent = Lighting

                -- 7. Atmosphere (Глубина горизонта и воздушная перспектива без тумана)
                local atmoTarget = _origAtmo and _origAtmo.instance and _origAtmo.instance.Parent == Lighting and _origAtmo.instance
                if not atmoTarget then
                    atmoTarget = Lighting:FindFirstChild("SolaraRTXAtmo") or Instance.new("Atmosphere")
                    atmoTarget.Name = "SolaraRTXAtmo"
                    atmoTarget.Parent = Lighting
                end
                if profile.atmoEnabled and fpsLevel < 2 then
                    pcall(function()
                        atmoTarget.Density = profile.atmoDensity
                        atmoTarget.Color = profile.atmoColor
                        atmoTarget.Decay = profile.atmoDecay
                        atmoTarget.Haze = math.clamp((profile.atmoHaze + (isCinematic and 0.25 or 0)) * intensity, 0.2, 2.0)
                        atmoTarget.Glare = math.clamp((profile.atmoGlare + (isCinematic and 0.05 or 0)) * intensity, 0.02, 0.5)
                        atmoTarget.Offset = profile.atmoOffset
                    end)
                end

                -- 8. DepthOfField (НИКАКОГО МЫЛА: выключен по умолчанию; активен только в Cinematic Mode)
                local dof = Lighting:FindFirstChild("SolaraRTXDOF")
                if isCinematic and fpsLevel < 2 then
                    if not dof then
                        dof = Instance.new("DepthOfFieldEffect")
                        dof.Name = "SolaraRTXDOF"
                        dof.Parent = Lighting
                    end
                    dof.Enabled = true
                    dof.FarIntensity = math.clamp(0.035 * intensity, 0.01, 0.08)
                    dof.FocusDistance = 60
                    dof.InFocusRadius = 45
                    dof.NearIntensity = math.clamp(0.012 * intensity, 0.005, 0.03)
                else
                    if dof then
                        dof.Enabled = false
                    end
                end

                -- 9. Детали ландшафта и отражения воды (Terrain)
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    local simplifyWater = fpsLevel >= 2
                    pcall(function() terrain.WaterReflectance = simplifyWater and 0 or profile.waterRefl end)
                    pcall(function() terrain.WaterTransparency = profile.waterTransp end)
                    pcall(function() terrain.WaterWaveSize = simplifyWater and 0 or profile.waterWave end)
                    pcall(function() terrain.WaterWaveSpeed = simplifyWater and 0 or profile.waterSpeed end)
                    pcall(function() terrain.Decoration = not simplifyWater end)
                end
            end

            visualApply.rtx = function()
                if _rtxEnabled then applyRtxGraphics() end
            end

            createModuleRow(list, moduleName, j, function(state)
                _rtxEnabled = state
                if state then
                    captureOriginals()
                    applyRtxGraphics()
                else
                    restoreOriginals()
                end
            end)

            registerRuntimeCleanup(function()
                if _rtxEnabled then
                    _rtxEnabled = false
                    restoreOriginals()
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- WEATHER FX — RTX Дождь / Снег (0 - 200 частиц)
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Weather FX" then
            local _weatherEnabled = false
            local _weatherEmitter = nil
            local _weatherPart = nil
            local _weatherConn = nil

            local function applyWeather()
                if not _weatherEnabled then return end

                local cam = workspace.CurrentCamera
                if not cam then return end

                if not _weatherPart or _weatherPart.Parent ~= workspace then
                    if _weatherPart then _weatherPart:Destroy() end
                    _weatherPart = Instance.new("Part")
                    _weatherPart.Name = "SolaraWeatherPart"
                    _weatherPart.Size = Vector3.new(80, 2, 80)
                    _weatherPart.Transparency = 1
                    _weatherPart.CanCollide = false
                    _weatherPart.CanTouch = false
                    _weatherPart.CanQuery = false
                    _weatherPart.Anchored = true
                    _weatherPart.Parent = workspace
                end
                _weatherPart.CFrame = cam.CFrame * CFrame.new(0, 14, -12)

                if not _weatherEmitter or _weatherEmitter.Parent ~= _weatherPart then
                    if _weatherEmitter then _weatherEmitter:Destroy() end
                    _weatherEmitter = Instance.new("ParticleEmitter")
                    _weatherEmitter.Name = "SolaraWeatherEmitter"
                    _weatherEmitter.Parent = _weatherPart
                end

                _weatherEmitter.EmissionDirection = Enum.NormalId.Bottom
                _weatherEmitter.Rate = math.clamp(_weatherCount, 0, 200)
                _weatherEmitter.Enabled = true

                if _weatherType == "Rain" then
                    _weatherEmitter.Texture = "rbxassetid://243664672"
                    _weatherEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
                    _weatherEmitter.Size = NumberSequence.new(1.2)
                    _weatherEmitter.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.1),
                        NumberSequenceKeypoint.new(1, 0.4)
                    })
                    _weatherEmitter.Lifetime = NumberRange.new(1.0, 2.2)
                    _weatherEmitter.Speed = NumberRange.new(45, 80)
                    _weatherEmitter.SpreadAngle = Vector2.new(5, 5)
                    _weatherEmitter.Acceleration = Vector3.new(0, -60, 0)
                    _weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
                else -- Snow
                    _weatherEmitter.Texture = "rbxassetid://243664672"
                    _weatherEmitter.Orientation = Enum.ParticleOrientation.FacingCamera
                    _weatherEmitter.Size = NumberSequence.new(1.5)
                    _weatherEmitter.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.1),
                        NumberSequenceKeypoint.new(1, 0.3)
                    })
                    _weatherEmitter.Lifetime = NumberRange.new(2.5, 4.5)
                    _weatherEmitter.Speed = NumberRange.new(6, 14)
                    _weatherEmitter.SpreadAngle = Vector2.new(35, 35)
                    _weatherEmitter.Acceleration = Vector3.new(0, -6, 0)
                    _weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                end
            end

            visualApply.weather = function()
                if _weatherEnabled then applyWeather() end
            end

            createModuleRow(list, moduleName, j, function(state)
                _weatherEnabled = state
                if state then
                    applyWeather()
                    if _weatherConn then _weatherConn:Disconnect() end
                    _weatherConn = RunService.RenderStepped:Connect(function()
                        if not _weatherEnabled then return end
                        local cam = workspace.CurrentCamera
                        if cam and _weatherPart then
                            _weatherPart.CFrame = cam.CFrame * CFrame.new(0, 14, -12)
                        end
                    end)
                else
                    if _weatherConn then _weatherConn:Disconnect(); _weatherConn = nil end
                    if _weatherEmitter then _weatherEmitter:Destroy(); _weatherEmitter = nil end
                    if _weatherPart then _weatherPart:Destroy(); _weatherPart = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- SHADER HAT — 100% видимый горизонтальный нимб/круг над головой
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Shader Hat" then
            local hat = { enabled = false, model = nil, childConnection = nil }
            local styles = {
                ["Halo Ring"] = { radius = 1.1, height = 1.8, thickness = 0.16 },
                ["Crown Glow"] = { radius = 0.85, height = 2.15, thickness = 0.22 },
                ["Orbit Ring"] = { radius = 1.4, height = 1.65, thickness = 0.12 },
            }
            local legacyNames = {
                SolaraShaderHatGui = true,
                Solara3DHaloPart = true,
                SolaraShaderHatRing = true,
            }

            local function clearHat()
                if hat.model then hat.model:Destroy(); hat.model = nil end
            end

            local function removeLegacyHat(character)
                if not character then return end
                -- Однократная миграция только наших объектов при привязке персонажа.
                for _, object in ipairs(character:GetDescendants()) do
                    if legacyNames[object.Name] then object:Destroy() end
                end
            end

            local function applyShaderHat()
                clearHat()
                if not hat.enabled or not runtimeAlive then return end
                local character = player.Character
                local head = character and character:FindFirstChild("Head")
                if not head or not head:IsA("BasePart") then return end
                local style = styles[_shaderHatStyle] or styles["Halo Ring"]
                local radius = style.radius * gameplayConfig.shaderHatScale
                local height = style.height + gameplayConfig.shaderHatHeight
                local thickness = style.thickness * gameplayConfig.shaderHatThickness
                local model = Instance.new("Model")
                model.Name = "SolaraShaderHatRing"
                hat.model = model

                -- Трубчатый контур в плоскости XZ: центр полностью пустой.
                -- Короткие перекрывающиеся цилиндры образуют гладкое замкнутое кольцо.
                local segments = 40
                local chord = 2 * radius * math.sin(math.pi / segments) + 0.025
                for index = 0, segments - 1 do
                    local angle = index * 2 * math.pi / segments
                    local offset = CFrame.new(
                        math.cos(angle) * radius, height,
                        math.sin(angle) * radius
                    ) * CFrame.Angles(0, -angle - math.pi / 2, 0)
                    local segment = Instance.new("Part")
                    segment.Name = "RingSegment"
                    segment.Shape = Enum.PartType.Cylinder
                    segment.Size = Vector3.new(chord, thickness, thickness)
                    segment.Material = Enum.Material.Neon
                    segment.Color = COLORS.accent
                    segment.CanCollide, segment.CanTouch, segment.CanQuery = false, false, false
                    segment.Massless, segment.CastShadow = true, false
                    segment.CFrame = head.CFrame * offset
                    segment.Parent = model
                    local weld = Instance.new("Weld")
                    weld.Part0, weld.Part1, weld.C0 = head, segment, offset
                    weld.Parent = segment
                    bindTheme(segment, "Color", "accent")
                end
                model.Parent = character
            end

            local function bindHatCharacter(character)
                if hat.childConnection then
                    hat.childConnection:Disconnect()
                    hat.childConnection = nil
                end
                clearHat()
                removeLegacyHat(character)
                if not hat.enabled or not character then return end
                -- Head может реплицироваться позже CharacterAdded; без задержки 0.5s.
                hat.childConnection = character.ChildAdded:Connect(function(child)
                    if child.Name == "Head" and player.Character == character then
                        applyShaderHat()
                    end
                end)
                applyShaderHat()
            end

            visualApply.shaderHat = applyShaderHat
            removeLegacyHat(player.Character)
            createModuleRow(list, moduleName, j, function(state)
                hat.enabled = state
                if state then
                    hat.addedConnection = player.CharacterAdded:Connect(bindHatCharacter)
                    hat.removingConnection = player.CharacterRemoving:Connect(function()
                        bindHatCharacter(nil)
                    end)
                    bindHatCharacter(player.Character)
                else
                    for _, key in ipairs({ "addedConnection", "removingConnection", "childConnection" }) do
                        if hat[key] then hat[key]:Disconnect(); hat[key] = nil end
                    end
                    clearHat()
                    removeLegacyHat(player.Character)
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- CROSSHAIR — Точный кастомный прицел в центре экрана
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Crosshair" then
            local _crosshairEnabled = false
            local _crosshairGui = nil

            local function applyCrosshair()
                if _crosshairGui then _crosshairGui:Destroy() end
                if not _crosshairEnabled then return end

                _crosshairGui = create("ScreenGui", {
                    Name = "SolaraCrosshairGui",
                    ResetOnSpawn = false,
                    IgnoreGuiInset = true,
                    DisplayOrder = 999,
                    Parent = playerGui,
                })

                local size = gameplayConfig.crosshairSize
                local thickness = gameplayConfig.crosshairThickness
                local gap = gameplayConfig.crosshairGap
                local transparency = gameplayConfig.crosshairOpacity
                local centerFrame = create("Frame", {
                    Size = UDim2.fromOffset(size * 2 + gap * 2, size * 2 + gap * 2),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Parent = _crosshairGui,
                })

                if _crosshairStyle == "Dot" then
                    local diameter = math.max(3, thickness + 2)
                    local dot = create("Frame", {
                        Size = UDim2.fromOffset(diameter, diameter),
                        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = COLORS.accent,
                        BackgroundTransparency = transparency,
                        BorderSizePixel = 0,
                        Parent = centerFrame,
                    })
                    corner(dot, diameter * 0.5)
                    stroke(dot, Color3.fromRGB(0, 0, 0), 1)
                    bindTheme(dot, "BackgroundColor3", function() return "accent" end)
                elseif _crosshairStyle == "Circle" then
                    local circle = create("Frame", {
                        Size = UDim2.fromOffset(size, size),
                        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Parent = centerFrame,
                    })
                    corner(circle, size * 0.5)
                    local st = stroke(circle, COLORS.accent, thickness)
                    st.Transparency = transparency
                    bindTheme(st, "Color", function() return "accent" end)
                elseif _crosshairStyle == "Cross" then
                    local function makeArm(armSize, armPosition, anchorPoint)
                        local arm = create("Frame", {
                            Size = armSize, Position = armPosition, AnchorPoint = anchorPoint,
                            BackgroundColor3 = COLORS.accent, BackgroundTransparency = transparency,
                            BorderSizePixel = 0, Parent = centerFrame,
                        })
                        corner(arm, math.max(1, thickness * 0.5))
                        local outline = stroke(arm, Color3.fromRGB(0, 0, 0), 1)
                        outline.Transparency = math.min(0.85, transparency + 0.2)
                        bindTheme(arm, "BackgroundColor3", function() return "accent" end)
                    end
                    makeArm(UDim2.fromOffset(size, thickness), UDim2.new(0.5, -gap, 0.5, 0), Vector2.new(1, 0.5))
                    makeArm(UDim2.fromOffset(size, thickness), UDim2.new(0.5, gap, 0.5, 0), Vector2.new(0, 0.5))
                    makeArm(UDim2.fromOffset(thickness, size), UDim2.new(0.5, 0, 0.5, -gap), Vector2.new(0.5, 1))
                    makeArm(UDim2.fromOffset(thickness, size), UDim2.new(0.5, 0, 0.5, gap), Vector2.new(0.5, 0))
                else -- Target
                    local outer = create("Frame", {
                        Size = UDim2.fromOffset(size, size),
                        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Parent = centerFrame,
                    })
                    corner(outer, size * 0.5)
                    local outerStroke = stroke(outer, COLORS.accent, thickness)
                    outerStroke.Transparency = transparency
                    bindTheme(outerStroke, "Color", function() return "accent" end)
                    local diameter = math.max(3, thickness + 1)
                    local innerDot = create("Frame", {
                        Size = UDim2.fromOffset(diameter, diameter),
                        Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = COLORS.accent,
                        BackgroundTransparency = transparency,
                        BorderSizePixel = 0,
                        Parent = centerFrame,
                    })
                    corner(innerDot, diameter * 0.5)
                    bindTheme(innerDot, "BackgroundColor3", function() return "accent" end)
                end
            end

            visualApply.crosshair = function()
                if _crosshairEnabled then applyCrosshair() end
            end

            createModuleRow(list, moduleName, j, function(state)
                _crosshairEnabled = state
                if state then
                    applyCrosshair()
                else
                    if _crosshairGui then _crosshairGui:Destroy(); _crosshairGui = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- CLEAR SCREEN — Полностью убирает весь интерфейс Roblox и Solara
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Clear Screen" then
            local _clearScreenSaved = nil
            local _clearScreenRow
            _clearScreenRow, clearScreenSetState = createModuleRow(list, moduleName, j, function(state)
                clearScreenActive = state
                if state then
                    _clearScreenSaved = { coreGui = {}, hud = HUD.getMasterEnabled and HUD.getMasterEnabled() or true }
                    for _, coreType in ipairs({
                        Enum.CoreGuiType.Backpack,
                        Enum.CoreGuiType.Chat,
                        Enum.CoreGuiType.Health,
                        Enum.CoreGuiType.PlayerList,
                        Enum.CoreGuiType.EmotesMenu,
                    }) do
                        local ok, enabled = pcall(function() return StarterGui:GetCoreGuiEnabled(coreType) end)
                        if ok then _clearScreenSaved.coreGui[coreType] = enabled end
                    end
                    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
                    pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
                    pcall(function() StarterGui:SetCore("CoreGuiChatAlwaysVisible", false) end)
                    pcall(function() game:GetService("GuiService").TopbarEnabled = false end)
                    pcall(function() playerGui:SetTopbarTransparency(1) end)

                    -- Скрываем главное окно и фаб-кнопку Solara
                    if window then window.Visible = false end
                    if themeFabButton then themeFabButton.Visible = false end
                    if HUD.setMasterEnabled then HUD.setMasterEnabled(false) end
                else
                    if _clearScreenSaved then
                        for coreType, wasEnabled in pairs(_clearScreenSaved.coreGui) do
                            pcall(function() StarterGui:SetCoreGuiEnabled(coreType, wasEnabled) end)
                        end
                    end
                    pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
                    pcall(function() game:GetService("GuiService").TopbarEnabled = true end)

                    if window then window.Visible = menuOpen end
                    if themeFabButton then themeFabButton.Visible = menuOpen end
                    if HUD.setMasterEnabled then HUD.setMasterEnabled(_clearScreenSaved == nil or _clearScreenSaved.hud) end
                    _clearScreenSaved = nil
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- ASPECT RATIO — формирует настоящее окно выбранного соотношения сторон.
        -- Roblox не даёт LocalScript менять физическое разрешение/неравномерно
        -- растягивать 3D framebuffer, поэтому лишняя область корректно маскируется.
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Aspect Ratio" then
            local _aspectEnabled = false
            local _aspectConn = nil
            local _aspectCameraChangedConn = nil
            local _origFov = 70
            local _aspectGui = nil

            local RATIO_MAP = { ["16:9"] = 16/9, ["4:3"] = 4/3, ["21:9"] = 21/9, ["1:1"] = 1 }

            local function destroyAspectGui()
                if _aspectGui then _aspectGui:Destroy(); _aspectGui = nil end
            end

            local function ensureAspectGui()
                if _aspectGui and _aspectGui.Parent then return _aspectGui end
                _aspectGui = create("ScreenGui", {
                    Name = "SolaraAspectRatio",
                    IgnoreGuiInset = true,
                    ResetOnSpawn = false,
                    DisplayOrder = 999998,
                    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                    Parent = playerGui,
                })
                for _, name in ipairs({ "Left", "Right", "Top", "Bottom" }) do
                    create("Frame", {
                        Name = name,
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 100,
                        Parent = _aspectGui,
                        themeBind = false,
                    })
                end
                return _aspectGui
            end

            local function applyAspectRatio()
                local cam = workspace.CurrentCamera
                if not cam then return end

                if not _aspectEnabled then
                    cam.FieldOfView = _origFov
                    destroyAspectGui()
                    return
                end

                local gui = ensureAspectGui()
                local viewport = cam.ViewportSize
                local targetRatio = RATIO_MAP[_aspectRatioPreset] or (16/9)
                local currentRatio = viewport.X / math.max(viewport.Y, 1)
                local left, right, top, bottom = gui.Left, gui.Right, gui.Top, gui.Bottom
                left.Visible, right.Visible, top.Visible, bottom.Visible = false, false, false, false

                if currentRatio > targetRatio then
                    local contentWidth = viewport.Y * targetRatio
                    local barWidth = math.max(0, (viewport.X - contentWidth) * 0.5)
                    left.Size, left.Position = UDim2.fromOffset(barWidth, viewport.Y), UDim2.fromOffset(0, 0)
                    right.Size, right.Position = UDim2.fromOffset(barWidth, viewport.Y), UDim2.fromOffset(viewport.X - barWidth, 0)
                    left.Visible, right.Visible = barWidth >= 1, barWidth >= 1
                elseif currentRatio < targetRatio then
                    local contentHeight = viewport.X / targetRatio
                    local barHeight = math.max(0, (viewport.Y - contentHeight) * 0.5)
                    top.Size, top.Position = UDim2.fromOffset(viewport.X, barHeight), UDim2.fromOffset(0, 0)
                    bottom.Size, bottom.Position = UDim2.fromOffset(viewport.X, barHeight), UDim2.fromOffset(0, viewport.Y - barHeight)
                    top.Visible, bottom.Visible = barHeight >= 1, barHeight >= 1
                end

                -- Сохраняем исходную вертикальную перспективу: теперь эффект создаёт
                -- именно viewport выбранной формы, а не подменяет его случайным FOV.
                cam.FieldOfView = _origFov
            end

            visualApply.aspect = function()
                if _aspectEnabled then applyAspectRatio() end
            end

            local function bindAspectCamera()
                if _aspectConn then _aspectConn:Disconnect(); _aspectConn = nil end
                local cam = workspace.CurrentCamera
                if cam then
                    _origFov = cam.FieldOfView
                    _aspectConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyAspectRatio)
                end
                applyAspectRatio()
            end

            createModuleRow(list, moduleName, j, function(state)
                _aspectEnabled = state
                local cam = workspace.CurrentCamera
                if state then
                    if _aspectCameraChangedConn then _aspectCameraChangedConn:Disconnect() end
                    _aspectCameraChangedConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindAspectCamera)
                    bindAspectCamera()
                else
                    if _aspectConn then _aspectConn:Disconnect(); _aspectConn = nil end
                    if _aspectCameraChangedConn then _aspectCameraChangedConn:Disconnect(); _aspectCameraChangedConn = nil end
                    if cam then cam.FieldOfView = _origFov end
                    destroyAspectGui()
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- HIT COLOR — Вспышка красного цвета при нанесении урона врагу
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Hit Color" then
            local _hitColorEnabled = false
            local _hitDescendantConn = nil
            local _trackedHumanoids = setmetatable({}, { __mode = "k" })
            local _activeHitTweens = {}

            local function stopMonitoringHumanoids()
                if _hitDescendantConn then _hitDescendantConn:Disconnect(); _hitDescendantConn = nil end
                for humanoid, entry in pairs(_trackedHumanoids) do
                    if entry.healthConn then entry.healthConn:Disconnect() end
                    if entry.destroyConn then entry.destroyConn:Disconnect() end
                    _trackedHumanoids[humanoid] = nil
                end
                for _, t in ipairs(_activeHitTweens) do
                    pcall(function() t:Cancel() end)
                end
                table.clear(_activeHitTweens)
            end

            local function triggerHitEffect(model)
                if not model or not model.Parent then return end
                local startColor = gameplayConfig.hitThemeColor or COLORS.accent
                local endColor = gameplayConfig.hitThemeColorEnd or Color3.fromRGB(255, 120, 80)
                local opacity = _hitColorOpacity or 0.35
                local duration = _hitColorDuration or 0.30
                local mode = _hitColorMode or "Gradient"

                local oldHighlight = model:FindFirstChild("SolaraHitHighlight")
                if oldHighlight then oldHighlight:Destroy() end

                local highlight = Instance.new("Highlight")
                highlight.Name = "SolaraHitHighlight"
                highlight.FillColor = startColor
                highlight.FillTransparency = 1.0
                highlight.OutlineColor = (mode == "Gradient") and endColor or startColor
                highlight.OutlineTransparency = 1.0
                highlight.Adornee = model
                highlight.Parent = model

                if mode == "Gradient" then
                    local fadeIn = TweenService:Create(highlight, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        FillTransparency = opacity,
                        OutlineTransparency = 0.1,
                    })
                    table.insert(_activeHitTweens, fadeIn)
                    fadeIn:Play()
                    fadeIn.Completed:Connect(function()
                        if highlight.Parent then
                            local fadeOut = TweenService:Create(highlight, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                FillColor = endColor,
                                OutlineColor = endColor,
                                FillTransparency = 1.0,
                                OutlineTransparency = 1.0,
                            })
                            table.insert(_activeHitTweens, fadeOut)
                            fadeOut:Play()
                            fadeOut.Completed:Connect(function()
                                if highlight.Parent then highlight:Destroy() end
                            end)
                        end
                    end)
                elseif mode == "Pulse" then
                    local p1 = TweenService:Create(highlight, TweenInfo.new(0.04, Enum.EasingStyle.Sine), {
                        FillTransparency = opacity, OutlineTransparency = 0,
                    })
                    p1:Play()
                    p1.Completed:Connect(function()
                        if highlight.Parent then
                            local p2 = TweenService:Create(highlight, TweenInfo.new(0.06, Enum.EasingStyle.Sine), {
                                FillTransparency = math.min(1, opacity + 0.3), OutlineTransparency = 0.5,
                            })
                            p2:Play()
                            p2.Completed:Connect(function()
                                if highlight.Parent then
                                    local p3 = TweenService:Create(highlight, TweenInfo.new(duration * 0.7, Enum.EasingStyle.Quad), {
                                        FillTransparency = 1.0, OutlineTransparency = 1.0,
                                    })
                                    p3:Play()
                                    p3.Completed:Connect(function()
                                        if highlight.Parent then highlight:Destroy() end
                                    end)
                                end
                            end)
                        end
                    end)
                elseif mode == "Glow" then
                    highlight.FillColor = startColor
                    highlight.OutlineColor = endColor
                    local tIn = TweenService:Create(highlight, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {
                        FillTransparency = math.min(0.85, opacity + 0.25), OutlineTransparency = 0,
                    })
                    tIn:Play()
                    tIn.Completed:Connect(function()
                        if highlight.Parent then
                            local tOut = TweenService:Create(highlight, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
                                FillTransparency = 1.0, OutlineTransparency = 1.0,
                            })
                            tOut:Play()
                            tOut.Completed:Connect(function()
                                if highlight.Parent then highlight:Destroy() end
                            end)
                        end
                    end)
                elseif mode == "Neon" then
                    highlight.FillColor = startColor
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    local tIn = TweenService:Create(highlight, TweenInfo.new(0.04, Enum.EasingStyle.Exponential), {
                        FillTransparency = math.max(0.05, opacity * 0.5), OutlineTransparency = 0,
                    })
                    tIn:Play()
                    tIn.Completed:Connect(function()
                        if highlight.Parent then
                            local tOut = TweenService:Create(highlight, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
                                FillColor = endColor,
                                FillTransparency = 1.0, OutlineTransparency = 1.0,
                            })
                            tOut:Play()
                            tOut.Completed:Connect(function()
                                if highlight.Parent then highlight:Destroy() end
                            end)
                        end
                    end)
                else
                    local tIn = TweenService:Create(highlight, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        FillTransparency = opacity, OutlineTransparency = 0.15,
                    })
                    tIn:Play()
                    tIn.Completed:Connect(function()
                        if highlight.Parent then
                            local tOut = TweenService:Create(highlight, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                FillTransparency = 1.0, OutlineTransparency = 1.0,
                            })
                            tOut:Play()
                            tOut.Completed:Connect(function()
                                if highlight.Parent then highlight:Destroy() end
                            end)
                        end
                    end)
                end
            end

            local function monitorHumanoid(humanoid, model)
                if not _hitColorEnabled or not humanoid or not model then return end
                if player.Character and humanoid:IsDescendantOf(player.Character) then return end
                if _trackedHumanoids[humanoid] then return end

                local entry = { health = humanoid.Health }
                _trackedHumanoids[humanoid] = entry
                entry.healthConn = humanoid.HealthChanged:Connect(function(newHealth)
                    local previousHealth = entry.health
                    entry.health = newHealth
                    if not _hitColorEnabled or newHealth >= previousHealth or not model.Parent then return end
                    triggerHitEffect(model)
                end)
                entry.destroyConn = humanoid.Destroying:Connect(function()
                    if entry.healthConn then entry.healthConn:Disconnect() end
                    if entry.destroyConn then entry.destroyConn:Disconnect() end
                    _trackedHumanoids[humanoid] = nil
                end)
            end

            createModuleRow(list, moduleName, j, function(state)
                _hitColorEnabled = state
                if state then
                    stopMonitoringHumanoids()
                    _hitColorEnabled = true
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
                            monitorHumanoid(obj, obj.Parent)
                        end
                    end
                    _hitDescendantConn = workspace.DescendantAdded:Connect(function(desc)
                        if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then
                            monitorHumanoid(desc, desc.Parent)
                        end
                    end)
                else
                    stopMonitoringHumanoids()
                end
            end)

        elseif moduleName == "Cosmetics" then
            local _cosmeticsEnabled = false
            local _cosmeticsCharacterConn = nil
            local _cosmeticsAnimationConn = nil
            local _addedAccessories = {}
            local _animatedCosmetics = {}
            local _heightWelds = {}
            local _heightAttachments = {}
            local _cosmeticHeightOffset = 0

            local function calculateCosmeticHeightOffset()
                local char = player.Character
                local head = char and char:FindFirstChild("Head")
                if not char or not head then return 0 end
                -- Не используем Character:GetBoundingBox(): после создания больших
                -- крыльев они входят в bounding box и сами искажают расчёт земли.
                local groundY = head.Position.Y - 5
                local foundFoot = false
                for _, partName in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
                    local foot = char:FindFirstChild(partName)
                    if foot and foot:IsA("BasePart") then
                        local footBottom = foot.Position.Y - foot.Size.Y * 0.5
                        groundY = foundFoot and math.min(groundY, footBottom) or footBottom
                        foundFoot = true
                    end
                end
                local alpha = math.clamp(gameplayConfig.cosmeticHeight / 20, 0, 1)
                local targetY = groundY + (head.Position.Y - groundY) * alpha
                return targetY - head.Position.Y
            end

            local function heightAdjusted(base)
                return CFrame.new(0, _cosmeticHeightOffset, 0) * base
            end

            local function updateCosmeticHeight()
                _cosmeticHeightOffset = calculateCosmeticHeightOffset()
                for _, item in ipairs(_heightWelds) do
                    if item.weld.Parent then item.weld.C0 = heightAdjusted(item.base) end
                end
                for _, attachment in ipairs(_heightAttachments) do
                    if attachment.Parent then attachment.Position = Vector3.new(0, _cosmeticHeightOffset, 0) end
                end
            end

            visualApply.cosmeticHeight = updateCosmeticHeight

            local function removeCosmetics()
                if _cosmeticsAnimationConn then
                    _cosmeticsAnimationConn:Disconnect()
                    _cosmeticsAnimationConn = nil
                end
                for _, acc in ipairs(_addedAccessories) do
                    if acc and acc.Parent then acc:Destroy() end
                end
                _addedAccessories = {}
                _animatedCosmetics = {}
                _heightWelds = {}
                _heightAttachments = {}
            end

            local function applyCosmetics()
                local char = player.Character
                if not char then return end

                removeCosmetics()

                if not _cosmeticsEnabled then return end

                local head = char:FindFirstChild("Head")
                local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                local scale = gameplayConfig.cosmeticScale
                _cosmeticHeightOffset = calculateCosmeticHeightOffset()

                local function prepareCosmeticPart(part)
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                    part.Massless = true
                    part.CastShadow = false
                end

                local function makePart(className, parent, name, size, color, material, transparency)
                    local part = Instance.new(className)
                    part.Name = name
                    part.Size = size * scale
                    part.Color = color
                    part.Material = material or Enum.Material.SmoothPlastic
                    part.Transparency = transparency or 0
                    prepareCosmeticPart(part)
                    part.Parent = parent
                    return part
                end

                local function attach(part0, part1, c0, followsHeight)
                    local weld = Instance.new("Weld")
                    weld.Part0 = part0
                    weld.Part1 = part1
                    weld.C0 = followsHeight and heightAdjusted(c0) or c0
                    weld.Parent = part1
                    if followsHeight then
                        table.insert(_heightWelds, { weld = weld, base = c0 })
                    end
                    return weld
                end

                local function themePart(part, key)
                    bindTheme(part, "Color", key or "accent")
                    return part
                end

                local function makeCylinder(parent, name, length, radius, color, material, transparency)
                    local part = makePart("Part", parent, name, Vector3.new(length, radius * 2, radius * 2), color, material, transparency)
                    part.Shape = Enum.PartType.Cylinder
                    return part
                end

                local function makeBall(parent, name, diameter, color, material, transparency)
                    local part = makePart("Part", parent, name, Vector3.new(diameter, diameter, diameter), color, material, transparency)
                    part.Shape = Enum.PartType.Ball
                    return part
                end

                if _cosmeticsPreset == "Demon Wings" then
                    -- Крылья архидемона: точная анатомия рукокрылых.
                    -- Плечевая кость идёт ВВЕРХ от лопатки; все 5 пальцев расходятся
                    -- ВЕЕРОМ ИЗ ОДНОЙ ТОЧКИ ЗАПЯСТЬЯ — как настоящее перепончатое крыло.
                    -- Мембрана заполняет треугольники между соседними пальцами.
                    if torso then
                        local wingsModel = Instance.new("Model")
                        wingsModel.Name = "SolaraAnimatedWings"
                        wingsModel.Parent = char

                        local boneColor  = Color3.fromRGB(18, 14, 22)
                        local jointColor = Color3.fromRGB(30, 24, 36)
                        local darkMem    = Color3.fromRGB(10, 8, 14)

                        local function buildWingSide(isLeft)
                            local dir = isLeft and -1 or 1

                            -- ── КОРНЕВОЙ ПИВОТ (невидим): за лопаткой ──────────────────
                            local root = makePart("Part", wingsModel,
                                isLeft and "LeftWingRoot" or "RightWingRoot",
                                Vector3.new(0.08, 0.08, 0.08),
                                boneColor, Enum.Material.SmoothPlastic, 1)
                            -- Крепится к спине у верхнего торса, без дополнительных вращений.
                            -- root-local X совпадает с мировым X, Y — с мировым Y.
                            local base = CFrame.new(
                                dir * 0.52 * scale,   -- наружу к плечу
                                0.48 * scale,          -- вверх
                                0.42 * scale           -- назад (к спине)
                            )
                            local rootWeld = attach(torso, root, base, true)
                            table.insert(_animatedCosmetics, {
                                kind = "wing", weld = rootWeld, base = base, side = dir
                            })

                            -- ── ПЛЕЧЕВАЯ КОСТЬ (Humerus) ───────────────────────────────
                            -- Идёт ВВЕРХ от корня с небольшим наклоном наружу.
                            local hLen  = 1.5                         -- длина (пре-скейл)
                            local hTilt = math.rad(20)                -- наклон от вертикали
                            local hCx   = dir * math.sin(hTilt) * hLen * 0.5
                            local hCy   =       math.cos(hTilt) * hLen * 0.5

                            local humerus = makePart("Part", wingsModel, "WingHumerus",
                                Vector3.new(0.28, hLen, 0.24),
                                boneColor, Enum.Material.Slate, 0)
                            attach(root, humerus,
                                CFrame.new(hCx * scale, hCy * scale, 0)
                                * CFrame.Angles(0, 0, dir * hTilt))

                            local hVein = makePart("Part", wingsModel, "HumerusVein",
                                Vector3.new(0.08, hLen * 0.9, 0.08),
                                COLORS.accent, Enum.Material.Neon, 0.12)
                            attach(humerus, hVein, CFrame.new(0, 0, 0.12 * scale))
                            themePart(hVein)

                            -- ── ЗАПЯСТНЫЙ СУСТАВ (Wrist Apex) ──────────────────────────
                            -- Конец плечевой кости — единственная точка, из которой
                            -- исходят ВСЕ пальцы.  wx, wy — координаты запястья в root-local.
                            local wx = dir * math.sin(hTilt) * hLen
                            local wy =       math.cos(hTilt) * hLen

                            local wristBall = makeBall(wingsModel, "WristKnuckle", 0.36,
                                jointColor, Enum.Material.Metal, 0)
                            attach(root, wristBall,
                                CFrame.new(wx * scale, wy * scale, 0))

                            -- Большой коготь-шип вверх от запястья (ведущий край крыла)
                            local thumbSpike = makePart("WedgePart", wingsModel, "ThumbSpike",
                                Vector3.new(0.15, 0.72, 0.2),
                                jointColor, Enum.Material.SmoothPlastic, 0)
                            attach(root, thumbSpike,
                                CFrame.new(
                                    (wx - dir * 0.1) * scale,
                                    (wy + 0.46)      * scale,
                                    -0.05            * scale
                                )
                                * CFrame.Angles(math.rad(-14), dir * math.rad(-10), dir * math.rad(-18)))

                            -- ── ПАЛЬЦЫ (Phalanges) ─────────────────────────────────────
                            -- angle: угол от ВЕРТИКАЛИ (0°=вверх, 90°=горизонталь, >90°=вниз).
                            -- Для правого крыла (dir=1) угол растёт по часовой стрелке.
                            -- Rotation: CFrame.Angles(0, 0, dir * rad) наклоняет ось Y кости
                            -- в нужном направлении.  Центр кости = запястье + dir*len/2.
                            local fingerDefs = {
                                { deg = 8,   len = 2.95, r = 0.18 }, -- ведущий (почти вертикаль)
                                { deg = 34,  len = 2.65, r = 0.17 },
                                { deg = 62,  len = 2.25, r = 0.16 },
                                { deg = 90,  len = 1.80, r = 0.15 }, -- горизонталь
                                { deg = 116, len = 1.38, r = 0.14 }, -- задний (уходит вниз)
                            }

                            for fi, fd in ipairs(fingerDefs) do
                                local rad = math.rad(fd.deg)
                                -- единичный вектор направления пальца (в root-local XY)
                                local dirX = dir * math.sin(rad)
                                local dirY =       math.cos(rad)

                                -- центр кости = запястье + полдлины по направлению
                                local cx = wx + dirX * fd.len * 0.5
                                local cy = wy + dirY * fd.len * 0.5
                                -- кончик пальца
                                local tx = wx + dirX * fd.len
                                local ty = wy + dirY * fd.len

                                -- КОСТЬ
                                local bone = makePart("Part", wingsModel, "FingerBone_" .. fi,
                                    Vector3.new(fd.r, fd.len, fd.r),
                                    boneColor, Enum.Material.Slate, 0)
                                attach(root, bone,
                                    CFrame.new(cx * scale, cy * scale, 0)
                                    * CFrame.Angles(0, 0, dir * rad))

                                -- Неоновая жила вдоль пальца
                                local bVein = makePart("Part", wingsModel, "FingerVein_" .. fi,
                                    Vector3.new(0.07, fd.len * 0.88, 0.07),
                                    COLORS.accent, Enum.Material.Neon, 0.1)
                                attach(bone, bVein, CFrame.new(0, 0, 0.09 * scale))
                                themePart(bVein)

                                -- Суставной шар на середине пальца (каждые ~1 длины)
                                if fi <= 3 then
                                    local knuckle = makeBall(wingsModel, "MidKnuckle_" .. fi, 0.2,
                                        jointColor, Enum.Material.Metal, 0)
                                    attach(root, knuckle,
                                        CFrame.new(
                                            (wx + dirX * fd.len * 0.52) * scale,
                                            (wy + dirY * fd.len * 0.52) * scale,
                                            0
                                        ))
                                end

                                -- Коготь на кончике пальца
                                local claw = makePart("WedgePart", wingsModel, "FingerClaw_" .. fi,
                                    Vector3.new(0.13, 0.55, 0.2),
                                    jointColor, Enum.Material.SmoothPlastic, 0)
                                attach(root, claw,
                                    CFrame.new(tx * scale, ty * scale, -0.04 * scale)
                                    * CFrame.Angles(math.rad(-10), dir * math.rad(-6), dir * rad))
                            end

                            -- ── МЕМБРАНЫ (между соседними пальцами) ───────────────────
                            -- Каждая мембрана — плоский Part, перпендикулярный усреднённому
                            -- направлению двух соседних пальцев.  Размер X = хорда между
                            -- кончиками (ширина), Y = средняя длина (высота), Z = тонкий (~0).
                            for m = 1, #fingerDefs - 1 do
                                local f1  = fingerDefs[m]
                                local f2  = fingerDefs[m + 1]
                                local r1  = math.rad(f1.deg)
                                local r2  = math.rad(f2.deg)
                                local rM  = (r1 + r2) * 0.5
                                local lM  = (f1.len + f2.len) * 0.5

                                -- Центр мембраны: запястье + половина длины по среднему направлению
                                local mx = wx + dir * math.sin(rM) * lM * 0.5
                                local my = wy +       math.cos(rM) * lM * 0.5

                                -- Хорда на полной длине между двумя кончиками
                                local chord = lM * 2 * math.sin((r2 - r1) * 0.5)

                                -- Основная тёмная мембрана
                                local mem = makePart("Part", wingsModel, "WingMem_" .. m,
                                    Vector3.new(chord, lM * 0.96, 0.05),
                                    darkMem, Enum.Material.Glass, 0.18)
                                attach(root, mem,
                                    CFrame.new(mx * scale, my * scale, 0.04 * scale)
                                    * CFrame.Angles(0, 0, dir * rM))

                                -- Неоновый кант кромки мембраны
                                local glow = makePart("Part", wingsModel, "MemGlow_" .. m,
                                    Vector3.new(chord * 0.82, lM * 0.86, 0.04),
                                    COLORS.accent, Enum.Material.Neon, 0.44)
                                attach(mem, glow, CFrame.new(0, 0, -0.03 * scale))
                                themePart(glow)
                            end

                            -- ── ЧАСТИЦЫ ПЕПЛА из запястья ─────────────────────────────
                            local emAtt = Instance.new("Attachment")
                            emAtt.Name     = "DemonEmberAtt"
                            emAtt.Position = Vector3.new(wx * scale, (wy - 0.18) * scale, 0)
                            emAtt.Parent   = root
                            table.insert(_addedAccessories, emAtt)

                            local pe = Instance.new("ParticleEmitter")
                            pe.Name        = "DemonEmbers"
                            pe.Texture     = "rbxassetid://243664672"
                            pe.Rate        = 11
                            pe.Speed       = NumberRange.new(0.2, 0.75)
                            pe.Lifetime    = NumberRange.new(1.0, 2.4)
                            pe.Size        = NumberSequence.new(0.28 * scale, 0)
                            pe.Color       = ColorSequence.new(COLORS.accent)
                            pe.Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0,   0.08),
                                NumberSequenceKeypoint.new(0.6, 0.5),
                                NumberSequenceKeypoint.new(1,   1),
                            })
                            pe.LightEmission = 0.92
                            pe.RotSpeed      = NumberRange.new(-25, 25)
                            pe.Parent        = emAtt
                            table.insert(_addedAccessories, pe)
                        end

                        buildWingSide(true)
                        buildWingSide(false)
                        table.insert(_addedAccessories, wingsModel)
                    end

                elseif _cosmeticsPreset == "Cyber Mask" then
                    -- Тактический киберпанк-шлем с проекционным HUD-визором,
                    -- карбоновым респиратором, фильтрами очистки, комм-антенной и мягким свечением.
                    if head then
                        local maskModel = Instance.new("Model")
                        maskModel.Name = "SolaraCyberMask"
                        maskModel.Parent = char

                        -- 1. Центральный проекционный HUD-визор (Glass + оптический Neon слой)
                        local visorCenter = makePart("Part", maskModel, "VisorCenter",
                            Vector3.new(0.54, 0.28, 0.1), Color3.fromRGB(15, 18, 24), Enum.Material.Glass, 0.14)
                        attach(head, visorCenter, CFrame.new(0, 0.12 * scale, -0.58 * scale), true)

                        local hudOpticBeam = makePart("Part", maskModel, "HudOpticBeam",
                            Vector3.new(0.46, 0.06, 0.04), COLORS.accent, Enum.Material.Neon, 0.05)
                        attach(visorCenter, hudOpticBeam, CFrame.new(0, 0.02 * scale, -0.04 * scale))
                        themePart(hudOpticBeam)
                        table.insert(_animatedCosmetics, { kind = "pulse", part = hudOpticBeam, phase = 0, baseTransparency = 0.08 })

                        -- Верхняя бронированная бровь визора
                        local visorBrow = makePart("Part", maskModel, "VisorBrow",
                            Vector3.new(0.68, 0.08, 0.16), Color3.fromRGB(32, 35, 42), Enum.Material.Metal, 0)
                        attach(head, visorBrow, CFrame.new(0, 0.28 * scale, -0.52 * scale) * CFrame.Angles(math.rad(14), 0, 0), true)

                        -- 2. Скошенные боковые крылья визора (аэродинамический охват глаз)
                        for _, side in ipairs({ -1, 1 }) do
                            local visorWing = makePart("Part", maskModel, "VisorWing",
                                Vector3.new(0.36, 0.26, 0.08), Color3.fromRGB(15, 18, 24), Enum.Material.Glass, 0.16)
                            attach(head, visorWing, CFrame.new(side * 0.42 * scale, 0.12 * scale, -0.48 * scale)
                                * CFrame.Angles(0, side * math.rad(-34), side * math.rad(4)), true)

                            local wingTrim = makePart("Part", maskModel, "VisorWingTrim",
                                Vector3.new(0.38, 0.05, 0.06), COLORS.accent, Enum.Material.Neon, 0.25)
                            attach(visorWing, wingTrim, CFrame.new(0, 0.11 * scale, -0.02 * scale))
                            themePart(wingTrim)
                        end

                        -- 3. Тактический респиратор / нижняя карбоновая маска (челюсть и подбородок)
                        local chinGuard = makePart("Part", maskModel, "ChinGuard",
                            Vector3.new(0.44, 0.36, 0.24), Color3.fromRGB(28, 30, 36), Enum.Material.Metal, 0)
                        attach(head, chinGuard, CFrame.new(0, -0.26 * scale, -0.54 * scale)
                            * CFrame.Angles(math.rad(-14), 0, 0), true)

                        -- Вентиляционные прорези респиратора
                        for vent = 1, 3 do
                            local ventSlit = makePart("Part", maskModel, "ExhaustVent_" .. vent,
                                Vector3.new(0.24 - vent * 0.03, 0.03, 0.06), Color3.fromRGB(12, 14, 18), Enum.Material.Slate, 0)
                            attach(chinGuard, ventSlit, CFrame.new(0, (0.08 - (vent - 1) * 0.08) * scale, -0.11 * scale))
                        end

                        -- 4. Боковые фильтры-картриджи на щеках (левый и правый)
                        for _, side in ipairs({ -1, 1 }) do
                            local canister = makeCylinder(maskModel, "FilterCanister",
                                0.26, 0.16, Color3.fromRGB(36, 40, 48), Enum.Material.Metal, 0)
                            attach(head, canister, CFrame.new(side * 0.44 * scale, -0.22 * scale, -0.44 * scale)
                                * CFrame.Angles(math.rad(-8), side * math.rad(-42), math.rad(90)), true)

                            local filterCap = makeCylinder(maskModel, "FilterCap",
                                0.06, 0.15, Color3.fromRGB(22, 24, 28), Enum.Material.Slate, 0)
                            attach(canister, filterCap, CFrame.new(0.14 * scale, 0, 0))

                            local filterRing = makeCylinder(maskModel, "FilterGlowRing",
                                0.05, 0.17, COLORS.accent, Enum.Material.Neon, 0)
                            attach(canister, filterRing, CFrame.new(0, 0, 0))
                            themePart(filterRing)
                            table.insert(_animatedCosmetics, { kind = "pulse", part = filterRing, phase = side * 1.5, baseTransparency = 0.05 })

                            -- 5. Височные сенсорные блоки
                            local templeNode = makeCylinder(maskModel, "TempleNode",
                                0.14, 0.14, Color3.fromRGB(30, 32, 38), Enum.Material.Metal, 0)
                            attach(head, templeNode, CFrame.new(side * 0.62 * scale, 0.14 * scale, -0.16 * scale)
                                * CFrame.Angles(0, math.rad(90), 0), true)

                            local templeLed = makeBall(maskModel, "TempleLed", 0.1, COLORS.accent, Enum.Material.Neon, 0)
                            attach(templeNode, templeLed, CFrame.new(0.08 * scale, 0, 0))
                            themePart(templeLed)
                        end

                        -- 6. Левая микро-комм антенна
                        local commAntenna = makePart("Part", maskModel, "CommsAntenna",
                            Vector3.new(0.05, 0.58, 0.05), Color3.fromRGB(45, 48, 55), Enum.Material.Metal, 0)
                        attach(head, commAntenna, CFrame.new(-0.64 * scale, 0.06 * scale, -0.24 * scale)
                            * CFrame.Angles(math.rad(-35), math.rad(8), math.rad(-14)), true)

                        local antennaTip = makeBall(maskModel, "AntennaTip", 0.08, COLORS.accent, Enum.Material.Neon, 0)
                        attach(commAntenna, antennaTip, CFrame.new(0, 0.28 * scale, 0))
                        themePart(antennaTip)

                        -- 7. Мягкая подсветка лица (PointLight)
                        local visorLight = Instance.new("PointLight")
                        visorLight.Name = "SolaraCyberLight"
                        visorLight.Color = COLORS.accent
                        visorLight.Range = 5.5 * scale
                        visorLight.Brightness = 1.05
                        visorLight.Shadows = false
                        visorLight.Parent = visorCenter
                        bindTheme(visorLight, "Color", "accent")
                        table.insert(_addedAccessories, visorLight)

                        table.insert(_addedAccessories, maskModel)
                    end

                elseif _cosmeticsPreset == "Valkyrie" then
                    -- Скандинавский Шлем Валькирии: резная золотая диадема,
                    -- инкрустированный кристалл Эйнхериев, боковые чеканные медальоны,
                    -- многослойные перьевые крылья с мягкой анимацией порхания.
                    if head then
                        local valkModel = Instance.new("Model")
                        valkModel.Name = "SolaraValkyrieHelm"
                        valkModel.Parent = char

                        local goldColor = Color3.fromRGB(246, 212, 115)
                        local darkGold = Color3.fromRGB(195, 155, 65)

                        -- 1. Двухъярусная золотая диадема вокруг чела
                        for index = 1, 16 do
                            local angle = (index - 1) * math.pi / 15
                            local x = math.cos(angle) * 0.58 * scale
                            local y = (0.30 + math.sin(angle) * 0.08) * scale
                            local z = -math.sin(angle) * 0.54 * scale

                            local bead = makeBall(valkModel, "CircletBead_" .. index, 0.18, goldColor, Enum.Material.Metal, 0)
                            attach(head, bead, CFrame.new(x, y, z), true)

                            if index % 2 == 0 then
                                local subBead = makeBall(valkModel, "SubBead_" .. index, 0.12, darkGold, Enum.Material.Metal, 0)
                                attach(head, subBead, CFrame.new(x * 0.98, y - 0.09 * scale, z * 0.98), true)
                            end
                        end

                        -- 2. Центральный лобный герб с крылатой золотой оправой
                        local crestBase = makePart("Part", valkModel, "ValkCrestBase",
                            Vector3.new(0.38, 0.28, 0.14), darkGold, Enum.Material.Metal, 0)
                        attach(head, crestBase, CFrame.new(0, 0.44 * scale, -0.54 * scale) * CFrame.Angles(math.rad(-8), 0, 0), true)

                        local crestWingLeft = makePart("WedgePart", valkModel, "CrestWingL",
                            Vector3.new(0.08, 0.35, 0.22), goldColor, Enum.Material.Metal, 0)
                        attach(crestBase, crestWingLeft, CFrame.new(-0.2 * scale, 0.08 * scale, -0.02 * scale)
                            * CFrame.Angles(0, math.rad(-15), math.rad(-25)))

                        local crestWingRight = makePart("WedgePart", valkModel, "CrestWingR",
                            Vector3.new(0.08, 0.35, 0.22), goldColor, Enum.Material.Metal, 0)
                        attach(crestBase, crestWingRight, CFrame.new(0.2 * scale, 0.08 * scale, -0.02 * scale)
                            * CFrame.Angles(0, math.rad(15), math.rad(25)))

                        -- Сакральный кристалл Валькирии
                        local crestGem = makeBall(valkModel, "ValkyrieGem", 0.28, COLORS.accent, Enum.Material.Neon, 0)
                        attach(crestBase, crestGem, CFrame.new(0, 0.04 * scale, -0.06 * scale))
                        themePart(crestGem)
                        table.insert(_animatedCosmetics, { kind = "pulse", part = crestGem, phase = 0, baseTransparency = 0.05 })

                        local valkLight = Instance.new("PointLight")
                        valkLight.Name = "ValkLight"
                        valkLight.Color = COLORS.accent
                        valkLight.Range = 4.5 * scale
                        valkLight.Brightness = 0.9
                        valkLight.Shadows = false
                        valkLight.Parent = crestGem
                        bindTheme(valkLight, "Color", "accent")
                        table.insert(_addedAccessories, valkLight)

                        -- 3. Боковые чеканные медальоны у основания ушей
                        for _, isLeft in ipairs({ true, false }) do
                            local dir = isLeft and -1 or 1
                            local earDisc = makeCylinder(valkModel, isLeft and "LeftEarDisc" or "RightEarDisc",
                                0.12, 0.26, goldColor, Enum.Material.Metal, 0)
                            attach(head, earDisc, CFrame.new(dir * 0.62 * scale, 0.32 * scale, -0.02 * scale)
                                * CFrame.Angles(0, math.rad(90), 0), true)

                            local earBoss = makeBall(valkModel, "EarBoss", 0.24, darkGold, Enum.Material.Metal, 0)
                            attach(earDisc, earBoss, CFrame.new(dir * 0.06 * scale, 0, 0))

                            -- 4. Анимированный корень крыла шлема (flutter)
                            local root = makePart("Part", valkModel, isLeft and "LeftHelmWingRoot" or "RightHelmWingRoot",
                                Vector3.new(0.08, 0.08, 0.08), COLORS.accent, Enum.Material.SmoothPlastic, 1)
                            local base = CFrame.new(dir * 0.66 * scale, 0.38 * scale, -0.02 * scale)
                                * CFrame.Angles(0, dir * math.rad(12), dir * math.rad(-14))
                            local rootWeld = attach(head, root, base, true)
                            table.insert(_animatedCosmetics, { kind = "helmWing", weld = rootWeld, base = base, side = dir })

                            -- Золотая оправа пера
                            local featherBracket = makePart("Part", valkModel, "WingBracket",
                                Vector3.new(0.14, 0.42, 0.24), goldColor, Enum.Material.Metal, 0)
                            attach(root, featherBracket, CFrame.new(dir * 0.06 * scale, 0.14 * scale, 0))

                            -- Ярус 1: Главные белые/слоновой кости маховые перья (Primary Ivory Flight Feathers)
                            local ivoryColor = Color3.fromRGB(252, 250, 246)
                            for f = 1, 6 do
                                local feather = makePart("WedgePart", valkModel, "ValkFeather_" .. f,
                                    Vector3.new(0.12, 2.15 - f * 0.16, 0.52 - f * 0.03),
                                    ivoryColor, Enum.Material.SmoothPlastic, 0)
                                attach(root, feather, CFrame.new(dir * (0.06 + f * 0.03) * scale,
                                    (0.42 + f * 0.22) * scale,
                                    (0.12 + f * 0.18) * scale)
                                    * CFrame.Angles(math.rad(-18 - f * 5), dir * math.rad(5), dir * math.rad(10 + f * 4)))

                                -- Золотой наконечник на пере
                                local featherTip = makePart("WedgePart", valkModel, "FeatherTip_" .. f,
                                    Vector3.new(0.13, 0.45, 0.28), goldColor, Enum.Material.Metal, 0)
                                attach(feather, featherTip, CFrame.new(0, (1.85 - f * 0.16) * 0.42 * scale, 0.06 * scale))
                            end

                            -- Ярус 2: Внутренние световые перья божественной энергии
                            for g = 1, 4 do
                                local glowFeather = makePart("WedgePart", valkModel, "ValkGlowFeather_" .. g,
                                    Vector3.new(0.08, 1.45 - g * 0.15, 0.38), COLORS.accent, Enum.Material.Glass, 0.18)
                                attach(root, glowFeather, CFrame.new(dir * 0.02 * scale,
                                    (0.35 + g * 0.18) * scale,
                                    (0.1 + g * 0.14) * scale)
                                    * CFrame.Angles(math.rad(-14 - g * 4), dir * math.rad(3), dir * math.rad(6 + g * 3)))
                                themePart(glowFeather)
                            end

                            -- Божественные искры у кончиков крыльев
                            local sparkAtt = Instance.new("Attachment")
                            sparkAtt.Name = "ValkSparkAtt"
                            sparkAtt.Position = Vector3.new(dir * 0.25 * scale, 1.65 * scale, 1.1 * scale)
                            sparkAtt.Parent = root
                            table.insert(_addedAccessories, sparkAtt)

                            local pe = Instance.new("ParticleEmitter")
                            pe.Name = "ValkSparks"
                            pe.Texture = "rbxassetid://243664672"
                            pe.Rate = 10
                            pe.Speed = NumberRange.new(0.3, 0.9)
                            pe.Lifetime = NumberRange.new(0.6, 1.4)
                            pe.Size = NumberSequence.new(0.25 * scale, 0)
                            pe.Color = ColorSequence.new(COLORS.accent)
                            pe.LightEmission = 0.9
                            pe.Parent = sparkAtt
                            table.insert(_addedAccessories, pe)
                        end

                        table.insert(_addedAccessories, valkModel)
                    end

                elseif _cosmeticsPreset == "Golden Crown" then
                    -- Императорская Золотая Корона: двойной кованый обод с жемчужной каймой,
                    -- драгоценные камни (рубины, сапфиры, изумруды, пульсирующие алмазы),
                    -- 8 королевских геральдических лилий (Fleur-de-lis), сводчатые арки и Державный Крест.
                    if head then
                        local crownModel = Instance.new("Model")
                        crownModel.Name = "SolaraGoldenCrown"
                        crownModel.Parent = char

                        local goldColor = Color3.fromRGB(255, 205, 52)
                        local darkGold = Color3.fromRGB(198, 152, 42)
                        local pearlColor = Color3.fromRGB(252, 250, 244)

                        local crownRoot = makePart("Part", crownModel, "CrownRoot",
                            Vector3.new(0.08, 0.08, 0.08), goldColor, Enum.Material.SmoothPlastic, 1)
                        attach(head, crownRoot, CFrame.new(0, 0.74 * scale, 0), true)

                        local radius = 0.58 * scale

                        -- 1. Двойной золотой обод и жемчужный орнамент (верхний и нижний ряд)
                        for index = 1, 16 do
                            local angle = (index - 1) * math.pi * 2 / 16
                            local x = math.cos(angle) * radius
                            local z = math.sin(angle) * radius

                            -- Золотое звено обода
                            local bandLink = makePart("Part", crownModel, "BandLink_" .. index,
                                Vector3.new(0.24, 0.22, 0.16), goldColor, Enum.Material.Metal, 0)
                            attach(crownRoot, bandLink, CFrame.new(x, 0, z) * CFrame.Angles(0, -angle, 0))

                            -- Нижняя жемчужина
                            local lowerPearl = makeBall(crownModel, "PearlLower_" .. index, 0.11, pearlColor, Enum.Material.SmoothPlastic, 0)
                            attach(crownRoot, lowerPearl, CFrame.new(x * 1.02, -0.09 * scale, z * 1.02))

                            -- Верхняя жемчужина
                            local upperPearl = makeBall(crownModel, "PearlUpper_" .. index, 0.11, pearlColor, Enum.Material.SmoothPlastic, 0)
                            attach(crownRoot, upperPearl, CFrame.new(x * 1.02, 0.09 * scale, z * 1.02))
                        end

                        -- 2. Драгоценные камни в оправе по периметру обода (8 камней)
                        local gemColors = {
                            Color3.fromRGB(225, 25, 45),   -- Рубин
                            Color3.fromRGB(30, 95, 235),   -- Сапфир
                            Color3.fromRGB(35, 195, 75),   -- Изумруд
                            COLORS.accent,                 -- Императорский бриллиант
                        }

                        for g = 1, 8 do
                            local angle = (g - 1) * math.pi * 2 / 8
                            local x = math.cos(angle) * (radius * 1.08)
                            local z = math.sin(angle) * (radius * 1.08)

                            local gemColor = gemColors[(g - 1) % #gemColors + 1]
                            local isDiamond = ((g - 1) % #gemColors + 1) == 4

                            local bezel = makeBall(crownModel, "Bezel_" .. g, 0.19, darkGold, Enum.Material.Metal, 0)
                            attach(crownRoot, bezel, CFrame.new(x, 0, z))

                            local gem = makeBall(crownModel, "CrownJewel_" .. g, 0.15, gemColor,
                                isDiamond and Enum.Material.Neon or Enum.Material.Glass, isDiamond and 0 or 0.12)
                            attach(bezel, gem, CFrame.new(0, 0, 0))

                            if isDiamond then
                                themePart(gem)
                                table.insert(_animatedCosmetics, { kind = "pulse", part = gem, phase = angle, baseTransparency = 0 })
                            end
                        end

                        -- 3. 8 Королевских Пиков (4 больших Fleur-de-lis + 4 малых трилистника)
                        for index = 1, 8 do
                            local angle = (index - 1) * math.pi * 2 / 8
                            local isMajor = (index % 2 == 1)
                            local x = math.cos(angle) * (radius * 0.96)
                            local z = math.sin(angle) * (radius * 0.96)
                            local height = (isMajor and 0.82 or 0.56) * scale

                            -- Центральный наконечник пика
                            local spire = makePart("WedgePart", crownModel, "CrownSpire_" .. index,
                                Vector3.new(0.18, height, 0.22), goldColor, Enum.Material.Metal, 0)
                            attach(crownRoot, spire, CFrame.new(x, height * 0.5 + 0.1 * scale, z) * CFrame.Angles(0, -angle, 0))

                            -- Вершинная жемчужина
                            local tipPearl = makeBall(crownModel, "TipPearl_" .. index, isMajor and 0.16 or 0.12,
                                pearlColor, Enum.Material.SmoothPlastic, 0)
                            attach(crownRoot, tipPearl, CFrame.new(x * 1.02, height + 0.14 * scale, z * 1.02))

                            if isMajor then
                                -- Левый и правый лепесток лилии (Fleur-de-lis)
                                local petalL = makePart("WedgePart", crownModel, "FleurPetalL_" .. index,
                                    Vector3.new(0.12, height * 0.65, 0.18), darkGold, Enum.Material.Metal, 0)
                                attach(spire, petalL, CFrame.new(-0.14 * scale, -0.06 * scale, 0) * CFrame.Angles(0, 0, math.rad(-26)))

                                local petalR = makePart("WedgePart", crownModel, "FleurPetalR_" .. index,
                                    Vector3.new(0.12, height * 0.65, 0.18), darkGold, Enum.Material.Metal, 0)
                                attach(spire, petalR, CFrame.new(0.14 * scale, -0.06 * scale, 0) * CFrame.Angles(0, 0, math.rad(26)))

                                -- Сердечный кристалл лилии
                                local spireGem = makeBall(crownModel, "SpireGem_" .. index, 0.16, COLORS.accent, Enum.Material.Neon, 0)
                                attach(spire, spireGem, CFrame.new(0, -0.08 * scale, 0.1 * scale))
                                themePart(spireGem)
                                table.insert(_animatedCosmetics, { kind = "pulse", part = spireGem, phase = angle * 1.5, baseTransparency = 0 })
                            end
                        end

                        -- 4. Четыре сводчатые королевские арки (Imperial Arches), сходящиеся к центру
                        for a = 1, 4 do
                            local archAngle = (a - 1) * math.pi / 2
                            local segments = 6
                            for s = 1, segments do
                                local t = s / segments
                                local archRad = (1 - t) * radius
                                local archY = (0.2 + math.sin(t * math.pi * 0.5) * 0.72) * scale
                                local ax = math.cos(archAngle) * archRad
                                local az = math.sin(archAngle) * archRad

                                local rib = makePart("Part", crownModel, "ArchRib_" .. a .. "_" .. s,
                                    Vector3.new(0.14, 0.14, 0.16), goldColor, Enum.Material.Metal, 0)
                                attach(crownRoot, rib, CFrame.new(ax, archY, az) * CFrame.Angles(0, -archAngle, 0))

                                if s % 2 == 0 then
                                    local archPearl = makeBall(crownModel, "ArchPearl_" .. a .. "_" .. s,
                                        0.1, pearlColor, Enum.Material.SmoothPlastic, 0)
                                    attach(crownRoot, archPearl, CFrame.new(ax, archY + 0.08 * scale, az))
                                end
                            end
                        end

                        -- 5. Державный шар (Monde) и Королевский Крест в зените короны
                        local topY = 0.96 * scale
                        local sovereignOrb = makeBall(crownModel, "SovereignOrb", 0.32, goldColor, Enum.Material.Metal, 0)
                        attach(crownRoot, sovereignOrb, CFrame.new(0, topY, 0))

                        local crossShaft = makePart("Part", crownModel, "CrossShaft",
                            Vector3.new(0.08, 0.44, 0.08), goldColor, Enum.Material.Metal, 0)
                        attach(sovereignOrb, crossShaft, CFrame.new(0, 0.34 * scale, 0))

                        local crossBar = makePart("Part", crownModel, "CrossBar",
                            Vector3.new(0.28, 0.08, 0.08), goldColor, Enum.Material.Metal, 0)
                        attach(crossShaft, crossBar, CFrame.new(0, 0.06 * scale, 0))

                        local crossGem = makeBall(crownModel, "CrossGem", 0.15, COLORS.accent, Enum.Material.Neon, 0)
                        attach(crossShaft, crossGem, CFrame.new(0, 0.06 * scale, 0))
                        themePart(crossGem)
                        table.insert(_animatedCosmetics, { kind = "pulse", part = crossGem, phase = 0, baseTransparency = 0 })

                        -- Королевские золотые искры
                        local crownSparkAtt = Instance.new("Attachment")
                        crownSparkAtt.Name = "CrownSparkAtt"
                        crownSparkAtt.Position = Vector3.new(0, topY + 0.65 * scale, 0)
                        crownSparkAtt.Parent = crownRoot
                        table.insert(_addedAccessories, crownSparkAtt)

                        local pe = Instance.new("ParticleEmitter")
                        pe.Name = "CrownSparks"
                        pe.Texture = "rbxassetid://243664672"
                        pe.Rate = 8
                        pe.Speed = NumberRange.new(0.2, 0.8)
                        pe.Lifetime = NumberRange.new(0.6, 1.2)
                        pe.Size = NumberSequence.new(0.22 * scale, 0)
                        pe.Color = ColorSequence.new(goldColor)
                        pe.LightEmission = 0.95
                        pe.Parent = crownSparkAtt
                        table.insert(_addedAccessories, pe)

                        table.insert(_addedAccessories, crownModel)
                    end

                elseif _cosmeticsPreset == "Neon Aura" then
                    -- Космическая Неоновая Аура: кристаллические октаэдры энергии,
                    -- двухслойная гироскопическая орбита, сигил света и динамическое объемное освещение.
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local auraModel = Instance.new("Model")
                        auraModel.Name = "SolaraNeonAura"
                        auraModel.Parent = char

                        local auraAttachment = Instance.new("Attachment")
                        auraAttachment.Name = "SolaraAuraHeight"
                        auraAttachment.Position = Vector3.new(0, _cosmeticHeightOffset, 0)
                        auraAttachment.Parent = hrp
                        table.insert(_heightAttachments, auraAttachment)
                        table.insert(_addedAccessories, auraAttachment)

                        -- Динамический источник света ауры, освещающий игрока и мир
                        local auraLight = Instance.new("PointLight")
                        auraLight.Name = "SolaraAuraLight"
                        auraLight.Color = COLORS.accent
                        auraLight.Range = 15 * scale
                        auraLight.Brightness = 1.35
                        auraLight.Shadows = false
                        auraLight.Parent = auraAttachment
                        bindTheme(auraLight, "Color", "accent")
                        table.insert(_addedAccessories, auraLight)

                        -- Частицы космической звездной пыли
                        local pe = Instance.new("ParticleEmitter")
                        pe.Name = "SolaraCosmeticAura"
                        pe.Texture = "rbxassetid://243664672"
                        pe.Rate = 32
                        pe.Speed = NumberRange.new(0.6, 2.2)
                        pe.Lifetime = NumberRange.new(0.8, 1.8)
                        pe.Size = NumberSequence.new(0.65 * scale, 0)
                        pe.Color = ColorSequence.new(COLORS.accent)
                        pe.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.1),
                            NumberSequenceKeypoint.new(0.6, 0.35),
                            NumberSequenceKeypoint.new(1, 1),
                        })
                        pe.LightEmission = 0.9
                        pe.Parent = auraAttachment
                        table.insert(_addedAccessories, pe)

                        -- 1. Шесть орбитальных Кристаллических Октаэдров (Energy Polyhedron Prisms)
                        for index = 1, 6 do
                            local prismRoot = makePart("Part", auraModel, "PrismRoot_" .. index,
                                Vector3.new(0.08, 0.08, 0.08), COLORS.accent, Enum.Material.SmoothPlastic, 1)
                            local weld = attach(hrp, prismRoot, CFrame.new())
                            table.insert(_animatedCosmetics, {
                                kind = "orbit",
                                weld = weld,
                                index = index,
                                baseRadius = 2.25,
                                speed = 1.6,
                                angleStep = math.pi / 3,
                            })

                            -- Внутреннее светящееся неоновое ядро призмы
                            local prismCore = makeBall(auraModel, "PrismCore_" .. index, 0.26, COLORS.accent, Enum.Material.Neon, 0)
                            attach(prismRoot, prismCore, CFrame.new())
                            themePart(prismCore)
                            table.insert(_animatedCosmetics, { kind = "pulse", part = prismCore, phase = index * 0.9, baseTransparency = 0.05 })

                            -- Внешняя граненая оболочка кристалла из кварцевого стекла
                            local glassColor = Color3.fromRGB(240, 246, 255)
                            local topPyramid = makePart("WedgePart", auraModel, "PrismTop_" .. index,
                                Vector3.new(0.34, 0.38, 0.34), glassColor, Enum.Material.Glass, 0.28)
                            attach(prismRoot, topPyramid, CFrame.new(0, 0.16 * scale, 0))

                            local botPyramid = makePart("WedgePart", auraModel, "PrismBot_" .. index,
                                Vector3.new(0.34, 0.38, 0.34), glassColor, Enum.Material.Glass, 0.28)
                            attach(prismRoot, botPyramid, CFrame.new(0, -0.16 * scale, 0) * CFrame.Angles(math.pi, 0, 0))

                            -- Искрящийся шлейф кристалла
                            local crystalSpark = Instance.new("Attachment")
                            crystalSpark.Name = "PrismSparkAtt"
                            crystalSpark.Parent = prismRoot
                            table.insert(_addedAccessories, crystalSpark)

                            local trailPe = Instance.new("ParticleEmitter")
                            trailPe.Name = "PrismTrail"
                            trailPe.Texture = "rbxassetid://243664672"
                            trailPe.Rate = 8
                            trailPe.Speed = NumberRange.new(0.1, 0.4)
                            trailPe.Lifetime = NumberRange.new(0.4, 0.8)
                            trailPe.Size = NumberSequence.new(0.2 * scale, 0)
                            trailPe.Color = ColorSequence.new(COLORS.accent)
                            trailPe.LightEmission = 0.95
                            trailPe.Parent = crystalSpark
                            table.insert(_addedAccessories, trailPe)
                        end

                        -- 2. Вторичный пояс наклонных микро-орбит (Stardust Satellites)
                        for sat = 1, 4 do
                            local satOrb = makeBall(auraModel, "SatOrb_" .. sat, 0.16, COLORS.accent, Enum.Material.Neon, 0.1)
                            local satWeld = attach(hrp, satOrb, CFrame.new())
                            themePart(satOrb)
                            table.insert(_animatedCosmetics, {
                                kind = "orbit",
                                weld = satWeld,
                                index = sat,
                                baseRadius = 1.35,
                                speed = -2.4,
                                angleStep = math.pi / 2,
                                tilt = math.rad(32),
                            })
                        end

                        table.insert(_addedAccessories, auraModel)
                    end
                end

                if #_animatedCosmetics > 0 then
                    _cosmeticsAnimationConn = RunService.Heartbeat:Connect(function()
                        if not _cosmeticsEnabled then return end
                        local now = os.clock() * gameplayConfig.cosmeticSpeed
                        for _, item in ipairs(_animatedCosmetics) do
                            if item.kind == "wing" and item.weld.Parent then
                                local flap = math.rad(14) + math.sin(now * 3.1) * math.rad(18)
                                item.weld.C0 = heightAdjusted(item.base) * CFrame.Angles(math.sin(now * 1.55) * 0.05, 0, item.side * flap)
                            elseif item.kind == "helmWing" and item.weld.Parent then
                                local flap = math.sin(now * 3.8) * math.rad(8)
                                item.weld.C0 = heightAdjusted(item.base) * CFrame.Angles(0, 0, item.side * flap)
                            elseif item.kind == "orbit" and item.weld.Parent then
                                local speed = item.speed or 1.8
                                local angleStep = item.angleStep or (math.pi / 4)
                                local angle = now * speed + item.index * angleStep
                                local radius = (item.baseRadius or 2.0) * scale * (item.radiusMult or 1.0)
                                local height = (math.sin(angle * 2 + (item.phase or 0)) * 0.55) * scale
                                local cf = CFrame.new(math.cos(angle) * radius, height + _cosmeticHeightOffset, math.sin(angle) * radius)
                                if item.tilt then
                                    cf = cf * CFrame.Angles(item.tilt, angle, 0)
                                end
                                item.weld.C0 = cf
                            elseif item.kind == "pulse" and item.part.Parent then
                                item.part.Transparency = math.clamp(item.baseTransparency + (math.sin(now * 4 + item.phase) + 1) * 0.12, 0, 0.6)
                            end
                        end
                    end)
                end
            end

            visualApply.cosmetics = function()
                if _cosmeticsEnabled then applyCosmetics() end
            end

            createModuleRow(list, moduleName, j, function(state)
                _cosmeticsEnabled = state
                if state then
                    applyCosmetics()
                    if _cosmeticsCharacterConn then _cosmeticsCharacterConn:Disconnect() end
                    _cosmeticsCharacterConn = player.CharacterAdded:Connect(function()
                        task.wait(0.5)
                        applyCosmetics()
                    end)
                else
                    if _cosmeticsCharacterConn then _cosmeticsCharacterConn:Disconnect(); _cosmeticsCharacterConn = nil end
                    removeCosmetics()
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- GLOW PLAYER — Цвет по теме или кастомный
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Glow Player" then
            local _glowEnabled = false
            local _glowHighlights = {}
            local _glowTweens = {}
            local _playerConn = nil
            local _charConn = nil
            local _fadeThread = nil

            local function getGlowColor()
                if _glowUseTheme then
                    return gameplayConfig.glowThemeColor or COLORS.accent
                else
                    return _glowCustomColor or COLORS.accent
                end
            end

            local function clearAllGlow()
                for _, t in ipairs(_glowTweens) do
                    pcall(function() t:Cancel() end)
                end
                table.clear(_glowTweens)
                for char, hl in pairs(_glowHighlights) do
                    if hl and hl.Parent then hl:Destroy() end
                end
                table.clear(_glowHighlights)
            end

            local function applyGlowToChar(character, isTarget)
                if not character or not character.Parent then return end
                local old = character:FindFirstChild("SolaraGlowV2")
                if old then old:Destroy() end
                if not _glowEnabled then return end

                local color = getGlowColor()
                local hl = Instance.new("Highlight")
                hl.Name = "SolaraGlowV2"
                hl.FillColor = color
                hl.OutlineColor = color
                hl.FillTransparency = _glowFillTransparency or 0.65
                hl.OutlineTransparency = _glowOutlineTransparency or 0.1
                hl.Adornee = character
                hl.Parent = character
                _glowHighlights[character] = hl

                if _glowPulse then
                    local targetTransp = math.min(0.95, (hl.FillTransparency) + 0.25)
                    local pulseTween = TweenService:Create(hl, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                        FillTransparency = targetTransp,
                    })
                    table.insert(_glowTweens, pulseTween)
                    pulseTween:Play()
                end
            end

            local function refreshGlowTargets()
                if not _glowEnabled then
                    clearAllGlow()
                    return
                end
                clearAllGlow()
                local mode = _glowMode or "已选择"

                if mode == "Selected" then
                    local targetP = nil
                    if _glowTargetUserId then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.UserId == _glowTargetUserId then targetP = p; break end
                        end
                    end
                    if targetP and targetP.Character then
                        applyGlowToChar(targetP.Character, true)
                    end
                elseif mode == "Friends" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and player:IsFriendsWith(p.UserId) and p.Character then
                            applyGlowToChar(p.Character, false)
                        end
                    end
                elseif mode == "Everyone" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and p.Character then
                            applyGlowToChar(p.Character, false)
                        end
                    end
                elseif mode == "Self" then
                    if player.Character then
                        applyGlowToChar(player.Character, true)
                    end
                end
            end

            visualApply.glow = function()
                if _glowEnabled then
                    refreshGlowTargets()
                end
            end

            createModuleRow(list, moduleName, j, function(state)
                _glowEnabled = state
                if state then
                    refreshGlowTargets()
                    _playerConn = Players.PlayerRemoving:Connect(function(p)
                        if p.Character and _glowHighlights[p.Character] then
                            if _glowHighlights[p.Character].Parent then _glowHighlights[p.Character]:Destroy() end
                            _glowHighlights[p.Character] = nil
                        end
                    end)
                    _charConn = player.CharacterAdded:Connect(function(char)
                        task.wait(0.5)
                        if _glowEnabled then refreshGlowTargets() end
                    end)
                    _fadeThread = task.spawn(function()
                        while _glowEnabled and runtimeAlive do
                            task.wait(1.5)
                            local cam = workspace.CurrentCamera
                            if cam then
                                local cPos = cam.CFrame.Position
                                for char, hl in pairs(_glowHighlights) do
                                    if char and char.Parent and hl and hl.Parent then
                                        local root = char:FindFirstChild("HumanoidRootPart")
                                        if root then
                                            local dist = (cPos - root.Position).Magnitude
                                            if dist > 200 then
                                                hl.OutlineTransparency = math.min(0.8, (_glowOutlineTransparency or 0.1) + 0.4)
                                            else
                                                hl.OutlineTransparency = _glowOutlineTransparency or 0.1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                else
                    if _playerConn then _playerConn:Disconnect(); _playerConn = nil end
                    if _charConn then _charConn:Disconnect(); _charConn = nil end
                    clearAllGlow()
                end
            end)

        elseif moduleName == "Fullbright" then
            local _fbEnabled = false
            local _savedAmbient = nil
            local _savedOutdoor = nil
            local _savedBrightness = nil
            local _savedShadowsFb = nil

            local function applyFullbright()
                if not _fbEnabled then return end
                local t = _fullbrightIntensity / 100 -- 0..1
                -- Интерполяция: 0% = оригинальные значения, 100% = максимальная яркость
                local ambVal = math.floor(40 + t * 215) -- 40..255
                Lighting.Ambient = Color3.fromRGB(ambVal, ambVal, ambVal)
                Lighting.OutdoorAmbient = Color3.fromRGB(ambVal, ambVal, ambVal)
                Lighting.Brightness = 1 + t * 3 -- 1..4
                Lighting.GlobalShadows = (t < 0.5)
            end

            visualApply.fullbright = function()
                if _fbEnabled then applyFullbright() end
            end

            createModuleRow(list, moduleName, j, function(state)
                _fbEnabled = state
                if state then
                    _savedAmbient = Lighting.Ambient
                    _savedOutdoor = Lighting.OutdoorAmbient
                    _savedBrightness = Lighting.Brightness
                    _savedShadowsFb = Lighting.GlobalShadows
                    applyFullbright()
                else
                    if _savedAmbient then Lighting.Ambient = _savedAmbient end
                    if _savedOutdoor then Lighting.OutdoorAmbient = _savedOutdoor end
                    if _savedBrightness then Lighting.Brightness = _savedBrightness end
                    if _savedShadowsFb ~= nil then Lighting.GlobalShadows = _savedShadowsFb end
                    reapplyLightingOverrides()
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- AMBIENT COLOR — Меняет эмбиент на мягкий фиолетовый/эстетичный
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Ambient Color" then
            local _ambientEnabled = false
            local _savedAmbient2 = nil
            local _savedOutdoor2 = nil
            local _savedCC = nil

            local function applyAmbientColor(targetColor)
                if not _ambientEnabled then return end
                local color = targetColor or gameplayConfig.ambientThemeColor or Color3.fromRGB(90, 70, 130)
                Lighting.Ambient = color
                Lighting.OutdoorAmbient = color
                local cc = Lighting:FindFirstChild("SolaraCC")
                if not cc then
                    cc = Instance.new("ColorCorrectionEffect")
                    cc.Name = "SolaraCC"
                    cc.Parent = Lighting
                end
                cc.TintColor = Color3.fromRGB(240, 230, 255)
                cc.Saturation = 0.15
                cc.Contrast = 0.05
                cc.Brightness = 0.02
            end

            visualApply.ambient = applyAmbientColor
            visualApply.ambientColor = function(c)
                if _ambientEnabled then
                    applyAmbientColor(c)
                end
            end

            createModuleRow(list, moduleName, j, function(state)
                _ambientEnabled = state
                if state then
                    _savedAmbient2 = Lighting.Ambient
                    _savedOutdoor2 = Lighting.OutdoorAmbient
                    local cc = Lighting:FindFirstChild("SolaraCC")
                    _savedCC = cc and {
                        existed = true,
                        tint = cc.TintColor,
                        saturation = cc.Saturation,
                        contrast = cc.Contrast,
                        brightness = cc.Brightness,
                    } or { existed = false }
                    applyAmbientColor()
                else
                    if _savedAmbient2 then Lighting.Ambient = _savedAmbient2 end
                    if _savedOutdoor2 then Lighting.OutdoorAmbient = _savedOutdoor2 end
                    local cc = Lighting:FindFirstChild("SolaraCC")
                    if cc and _savedCC and _savedCC.existed then
                        cc.TintColor = _savedCC.tint
                        cc.Saturation = _savedCC.saturation
                        cc.Contrast = _savedCC.contrast
                        cc.Brightness = _savedCC.brightness
                    elseif cc then
                        cc:Destroy()
                    end
                    _savedCC = nil
                    reapplyLightingOverrides()
                end
            end)

        elseif moduleName == "Auto Combo" then
            local AutoCombo = gameplayConfig.autoCombo

            local function autoComboLog(msg)
                if AutoCombo.Config.Debug then
                    print("[AutoCombo] " .. tostring(msg))
                end
            end

            local function isTargetValid(targetChar)
                if not targetChar or not targetChar.Parent then return false end
                local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
                local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
                if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart.Parent then
                    return false
                end
                local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
                if not targetPlayer or targetPlayer.Parent ~= Players then
                    return false
                end
                local myChar = player.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHum or myHum.Health <= 0 or not myRoot then
                    return false
                end
                return true
            end

            local function aimAtPosition(pos)
                local myChar = player.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end
                local targetLook = Vector3.new(pos.X, myRoot.Position.Y, pos.Z)
                if (targetLook - myRoot.Position).Magnitude > 0.05 then
                    pcall(function()
                        myRoot.CFrame = CFrame.new(myRoot.Position, targetLook)
                    end)
                end
                local camera = workspace.CurrentCamera
                if camera then
                    pcall(function()
                        camera.CFrame = CFrame.new(camera.CFrame.Position, pos)
                    end)
                end
            end

            local function aimAtTarget(targetChar)
                if not targetChar then return end
                local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    aimAtPosition(tRoot.Position)
                end
            end

            local function pressCombatKey(keyCode, holdSeconds)
                holdSeconds = holdSeconds or AutoCombo.Config.KeyHold or 0.04
                if VirtualInputManager then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                    end)
                elseif keypress then
                    pcall(function() keypress(keyCode) end)
                end

                task.wait(holdSeconds)

                if VirtualInputManager then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                    end)
                elseif keyrelease then
                    pcall(function() keyrelease(keyCode) end)
                end
            end

            local function combatM1(holdSeconds)
                holdSeconds = holdSeconds or AutoCombo.Config.M1Hold or 0.02
                if VirtualInputManager then
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    end)
                elseif mouse1press then
                    pcall(function() mouse1press() end)
                end

                task.wait(holdSeconds)

                if VirtualInputManager then
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end)
                elseif mouse1release then
                    pcall(function() mouse1release() end)
                end
            end

            local function combatJump(holdSeconds)
                holdSeconds = holdSeconds or 0.04
                local myChar = player.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if myHum then
                    pcall(function()
                        myHum:ChangeState(Enum.HumanoidStateType.Jumping)
                        myHum.Jump = true
                    end)
                end
                pressCombatKey(Enum.KeyCode.Space, holdSeconds)
            end

            local function performQDashBehind(targetChar)
                local myChar = player.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local tRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                if not myRoot or not tRoot then return end

                local backDist = AutoCombo.Config.DashBackDistance or 3
                local behindPos = tRoot.Position - (tRoot.CFrame.LookVector * backDist)

                aimAtPosition(behindPos)
                task.wait(0.02)
                pressCombatKey(Enum.KeyCode.Q, AutoCombo.Config.KeyHold or 0.04)
                task.wait(AutoCombo.Config.DashWait or 0.22)
                aimAtTarget(targetChar)
            end

            local function runComboSequence()
                local targetChar = getSelectedTarget(gameplayConfig.autoComboTarget)
                if not isTargetValid(targetChar) then
                    autoComboLog("Target invalid at start")
                    AutoCombo.stop()
                    return
                end

                local function check()
                    if not AutoCombo.State.running then return false end
                    if not isTargetValid(targetChar) then
                        autoComboLog("Target lost during combo, stopping")
                        AutoCombo.stop()
                        return false
                    end
                    return true
                end

                autoComboLog("Started Auto Combo on " .. tostring(gameplayConfig.autoComboTarget))

                -- PHASE 1: Aim -> Q Dash Behind -> Aim -> 3x M1 -> Jump -> 200ms -> M1
                if not check() then return end
                aimAtTarget(targetChar)

                autoComboLog("Q behind target")
                performQDashBehind(targetChar)

                if not check() then return end
                aimAtTarget(targetChar)

                autoComboLog("M1 x3")
                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()

                autoComboLog("Jump + M1")
                if not check() then return end
                combatJump()

                task.wait(AutoCombo.Config.JumpM1Delay or 0.20)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()

                -- PHASE 2: Aim -> Ability 1 -> 3x M1 -> Jump -> ~100ms -> M1
                autoComboLog("Ability 1")
                if not check() then return end
                aimAtTarget(targetChar)
                pressCombatKey(Enum.KeyCode.One)

                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()

                if not check() then return end
                combatJump()

                task.wait(AutoCombo.Config.SecondJumpM1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()

                -- PHASE 3: 400ms -> Aim -> Ability 2 -> 1000ms
                task.wait(AutoCombo.Config.Ability2Delay or 0.40)
                if not check() then return end
                autoComboLog("Ability 2")
                aimAtTarget(targetChar)
                pressCombatKey(Enum.KeyCode.Two)

                task.wait(AutoCombo.Config.AfterAbility2Delay or 1.00)

                -- PHASE 4: Aim (fresh CFrame) -> Q Reconnect -> 4x M1
                if not check() then return end
                autoComboLog("Q reconnect")
                aimAtTarget(targetChar)
                performQDashBehind(targetChar)

                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()
                task.wait(AutoCombo.Config.M1Delay or 0.10)
                if not check() then return end
                aimAtTarget(targetChar)
                combatM1()

                -- PHASE 5: Aim -> Ability 3 -> check Target
                if not check() then return end
                aimAtTarget(targetChar)
                autoComboLog("Ability 3")
                pressCombatKey(Enum.KeyCode.Three)
                task.wait(0.1)
                if not check() then return end

                -- PHASE 6: Aim -> Ability 4 -> Track distance <= Second4Distance -> Ability 4 second activation
                aimAtTarget(targetChar)
                autoComboLog("Ability 4")
                pressCombatKey(Enum.KeyCode.Four)

                local startTime = os.clock()
                local second4Fired = false
                local timeout = AutoCombo.Config.Ability4Timeout or 3.0
                local triggerDist = AutoCombo.Config.Second4Distance or 6.0

                while AutoCombo.State.running and (os.clock() - startTime < timeout) do
                    if not check() then return end
                    local myChar = player.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if myRoot and tRoot then
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        if dist <= triggerDist then
                            autoComboLog("Ability 4 second activation")
                            aimAtTarget(targetChar)
                            pressCombatKey(Enum.KeyCode.Four)
                            second4Fired = true
                            break
                        end
                    end
                    task.wait(0.03)
                end

                if not second4Fired then
                    autoComboLog("Ability 4 second activation timed out")
                end

                autoComboLog("Finished")
                AutoCombo.stop()
            end

            AutoCombo.start = function()
                if AutoCombo.State.running then return false end
                if HUD.selectedGame and HUD.selectedGame.id == "universal" and not HUD.isTsbGame() then
                    if HUD.notify then
                        HUD.notify(CURRENT_LANG == "RU" and "Auto Combo доступен только в The Strongest Battlegrounds!" or "自动连招仅适用于 The Strongest Battlegrounds！", "warn")
                    end
                    if AutoCombo.State.rowSetState then AutoCombo.State.rowSetState(false) end
                    return false
                end
                local targetChar = getSelectedTarget(gameplayConfig.autoComboTarget)
                if not isTargetValid(targetChar) then
                    if HUD.notify then
                        HUD.notify(CURRENT_LANG == "RU" and "Выберите живую цель в настройках!" or "请在设置中选择存活目标！", "info")
                    end
                    if AutoCombo.State.rowSetState then AutoCombo.State.rowSetState(false) end
                    return false
                end

                AutoCombo.State.running = true
                if AutoCombo.State.panelRefresh then AutoCombo.State.panelRefresh() end
                AutoCombo.State.thread = task.spawn(runComboSequence)
                return true
            end

            AutoCombo.stop = function()
                if not AutoCombo.State.running then return end
                AutoCombo.State.running = false
                if AutoCombo.State.rowSetState then
                    AutoCombo.State.rowSetState(false)
                end
                if AutoCombo.State.panelRefresh then
                    AutoCombo.State.panelRefresh()
                end

                if VirtualInputManager then
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end
            end

            local row, setState = createModuleRow(list, moduleName, j, function(state)
                if state then
                    local ok = AutoCombo.start()
                    if not ok then
                        setState(false)
                    end
                else
                    AutoCombo.stop()
                end
            end)
            AutoCombo.State.rowSetState = setState

            registerRuntimeCleanup(function()
                AutoCombo.stop()
            end)

        -- ═══════════════════════════════════════════════════════
        -- HvH — Постоянный телепорт за спину цели + авто-удары
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "HvH" then
            local _hvhEnabled = false
            local _hvhConn = nil

            createModuleRow(list, moduleName, j, function(state)
                _hvhEnabled = state
                if state then
                    if _hvhConn then _hvhConn:Disconnect() end
                    _hvhConn = RunService.RenderStepped:Connect(function()
                        if not _hvhEnabled then return end
                        local targetChar = getSelectedTarget(gameplayConfig.hvhTarget) or getClosestPlayer()
                        local myChar = player.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if targetChar and myRoot then
                            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                            if tRoot then
                                myRoot.CFrame = CFrame.new(tRoot.Position - tRoot.CFrame.LookVector * 2.5, tRoot.Position)
                                clickM1()
                            end
                        end
                    end)
                else
                    if _hvhConn then _hvhConn:Disconnect(); _hvhConn = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- TARGET STRAFE — Орбитальное вращение вокруг цели + удары
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Target Strafe" then
            local _strafeEnabled = false
            local _strafeConn = nil
            local _angle = 0

            createModuleRow(list, moduleName, j, function(state)
                _strafeEnabled = state
                if state then
                    if _strafeConn then _strafeConn:Disconnect() end
                    _strafeConn = RunService.RenderStepped:Connect(function(dt)
                        if not _strafeEnabled then return end
                        local targetChar = getSelectedTarget(gameplayConfig.strafeTarget) or getClosestPlayer()
                        local myChar = player.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if targetChar and myRoot then
                            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                            if tRoot then
                                _angle = (_angle + dt * math.rad(gameplayConfig.strafeSpeed)) % (math.pi * 2)
                                local offset = Vector3.new(math.cos(_angle) * gameplayConfig.strafeRadius, 0, math.sin(_angle) * gameplayConfig.strafeRadius)
                                myRoot.CFrame = CFrame.new(tRoot.Position + offset, tRoot.Position)
                                clickM1()
                            end
                        end
                    end)
                else
                    if _strafeConn then _strafeConn:Disconnect(); _strafeConn = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- HITBOX EXPANDER — Серверное расширение хитбокса HumanoidRootPart
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Hitbox Expander" then
            local _hitboxEnabled = false
            local _hitboxConn = nil
            local _hitboxOriginal = setmetatable({}, { __mode = "k" })
            local _hitboxAccumulator = 0

            local function restoreHitboxes()
                for root, original in pairs(_hitboxOriginal) do
                    if root.Parent then
                        root.Size = original.Size
                        root.Transparency = original.Transparency
                        root.Material = original.Material
                        root.Color = original.Color
                        root.CanCollide = original.CanCollide
                    end
                    _hitboxOriginal[root] = nil
                end
            end

            createModuleRow(list, moduleName, j, function(state)
                _hitboxEnabled = state
                if state then
                    if _hitboxConn then _hitboxConn:Disconnect() end
                    _hitboxAccumulator = 0
                    _hitboxConn = RunService.Heartbeat:Connect(function(dt)
                        if not _hitboxEnabled then return end
                        _hitboxAccumulator = _hitboxAccumulator + dt
                        if _hitboxAccumulator < 0.1 then return end
                        _hitboxAccumulator = 0
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= player and p.Character then
                                local root = p.Character:FindFirstChild("HumanoidRootPart")
                                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                if root and hum and hum.Health > 0 then
                                    if not _hitboxOriginal[root] then
                                        _hitboxOriginal[root] = {
                                            Size = root.Size,
                                            Transparency = root.Transparency,
                                            Material = root.Material,
                                            Color = root.Color,
                                            CanCollide = root.CanCollide,
                                        }
                                    end
                                    root.Size = Vector3.new(gameplayConfig.hitboxSize, gameplayConfig.hitboxSize, gameplayConfig.hitboxSize)
                                    root.Transparency = 0.7
                                    root.Material = Enum.Material.ForceField
                                    root.Color = COLORS.accent
                                    root.CanCollide = false
                                end
                            end
                        end
                    end)
                else
                    if _hitboxConn then _hitboxConn:Disconnect(); _hitboxConn = nil end
                    restoreHitboxes()
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- KILL PLAYER — Преследование и уничтожение цели
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Kill Player" then
            local _killEnabled = false
            local _killConn = nil

            createModuleRow(list, moduleName, j, function(state)
                _killEnabled = state
                if state then
                    if _killConn then _killConn:Disconnect() end
                    _killConn = RunService.RenderStepped:Connect(function()
                        if not _killEnabled then return end
                        local targetChar = getSelectedTarget(gameplayConfig.killTarget)
                        local myChar = player.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if targetChar and myRoot then
                            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                            if tRoot then
                                myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.5)
                                clickM1()
                            end
                        end
                    end)
                else
                    if _killConn then _killConn:Disconnect(); _killConn = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- INSTANT DASH (TSB) — Мгновенный рывок по взгляду камеры (KeyCode Z)
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Instant Dash" then
            createModuleRow(list, moduleName, j, function(state)
                gameplayConfig.tsbDashEnabled = state
            end)

        -- ═══════════════════════════════════════════════════════
        -- NO BLOCK SLOW (TSB) — Снятие замедления при блоке
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "No Block Slow" then
            createModuleRow(list, moduleName, j, function(state)
                setTsbNoBlockSlow(state)
            end)

        -- ═══════════════════════════════════════════════════════
        -- DESYNC GLITCH (TSB) — Десинк хитбокса и физики
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Desync Glitch" then
            local _desyncConn = nil
            createModuleRow(list, moduleName, j, function(state)
                gameplayConfig.tsbDesync = state
                if state then
                    if _desyncConn then _desyncConn:Disconnect() end
                    _desyncConn = RunService.Heartbeat:Connect(function()
                        if not gameplayConfig.tsbDesync then return end
                        executeTsbDesync()
                    end)
                    trackRuntimeConnection(_desyncConn)
                else
                    if _desyncConn then _desyncConn:Disconnect(); _desyncConn = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- FAST M1 (TSB) — Сброс анимаций и ускорение ударов
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Fast M1" then
            createModuleRow(list, moduleName, j, function(state)
                setTsbFastM1(state)
            end)

        -- ═══════════════════════════════════════════════════════
        -- BUNNY HOP — Авто-прыжок при касании земли
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Bunny Hop" then
            local _bhopEnabled = false
            local _bhopConn = nil

            createModuleRow(list, moduleName, j, function(state)
                _bhopEnabled = state
                if state then
                    if _bhopConn then _bhopConn:Disconnect() end
                    _bhopConn = RunService.RenderStepped:Connect(function()
                        if not _bhopEnabled then return end
                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if hum and root and hum.MoveDirection.Magnitude > 0 then
                            if hum.FloorMaterial ~= Enum.Material.Air then
                                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                                local jH = gameplayConfig.bhopJumpHeight or 45
                                local spd = gameplayConfig.bhopSpeed or 28
                                local vY = jH
                                local vX = hum.MoveDirection.X * spd
                                local vZ = hum.MoveDirection.Z * spd
                                local targetVel = Vector3.new(vX, vY, vZ)
                                pcall(function() root.AssemblyLinearVelocity = targetVel end)
                                root.Velocity = targetVel
                            else
                                local spd = gameplayConfig.bhopSpeed or 28
                                local targetVel = Vector3.new(hum.MoveDirection.X * spd, root.Velocity.Y, hum.MoveDirection.Z * spd)
                                pcall(function() root.AssemblyLinearVelocity = targetVel end)
                                root.Velocity = targetVel
                            end
                        end
                    end)
                else
                    if _bhopConn then _bhopConn:Disconnect(); _bhopConn = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- INFINITY JUMP — Бесконечный прыжок в воздухе
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Infinity Jump" then
            local _infJumpEnabled = false
            local _infJumpConn = nil

            createModuleRow(list, moduleName, j, function(state)
                _infJumpEnabled = state
                if state then
                    if _infJumpConn then _infJumpConn:Disconnect() end
                    _infJumpConn = UserInputService.JumpRequest:Connect(function()
                        if not _infJumpEnabled then return end
                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if hum and root then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            local jumpPow = gameplayConfig.infJumpPower or 52
                            local newVel = Vector3.new(root.Velocity.X, jumpPow, root.Velocity.Z)
                            pcall(function() root.AssemblyLinearVelocity = newVel end)
                            root.Velocity = newVel
                        end
                    end)
                else
                    if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- CUSTOM SPEED — Кастомная скорость бега
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Custom Speed" then
            local _speedEnabled = false
            local _speedConn = nil
            local _speedOriginal = setmetatable({}, { __mode = "k" })

            createModuleRow(list, moduleName, j, function(state)
                _speedEnabled = state
                if state then
                    if _speedConn then _speedConn:Disconnect() end
                    _speedConn = RunService.RenderStepped:Connect(function()
                        if not _speedEnabled then return end
                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            if _speedOriginal[hum] == nil then _speedOriginal[hum] = hum.WalkSpeed end
                            hum.WalkSpeed = gameplayConfig.customSpeed
                        end
                    end)
                else
                    if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
                    for hum, originalSpeed in pairs(_speedOriginal) do
                        if hum.Parent then hum.WalkSpeed = originalSpeed end
                        _speedOriginal[hum] = nil
                    end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- FLY — Плавный полёт в направлении камеры
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Fly" then
            local categoryName = list:GetAttribute("Category")
            if categoryName == "COMBAT" then
                createModuleRow(list, moduleName, j, function(state)
                    gameplayConfig.vehicleFlyEnabled = state
                end)
            else
                local _flyEnabled = false
                local _flyConn = nil

                createModuleRow(list, moduleName, j, function(state)
                    _flyEnabled = state
                    if state then
                        if _flyConn then _flyConn:Disconnect() end
                        _flyConn = RunService.RenderStepped:Connect(function()
                            if not _flyEnabled then return end
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local cam = workspace.CurrentCamera
                            if root and cam then
                                local moveDir = Vector3.new(0, 0, 0)
                                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if hum and not hum.PlatformStand then hum.PlatformStand = true end
                                local spd = gameplayConfig.flySpeed or 50
                                if moveDir.Magnitude > 0 then
                                    local vel = moveDir.Unit * spd
                                    pcall(function() root.AssemblyLinearVelocity = vel end)
                                    root.Velocity = vel
                                else
                                    local stopVel = Vector3.new(0, 0, 0)
                                    pcall(function() root.AssemblyLinearVelocity = stopVel end)
                                    root.Velocity = stopVel
                                end
                            end
                        end)
                    else
                        if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then root.Velocity = Vector3.new(0, 0, 0) end
                    end
                end)
            end

        -- ═══════════════════════════════════════════════════════
        -- GLOW ESP — Подсветка всех игроков с инфой о здоровье
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Glow ESP" then
            local _glowEspEnabled = false
            local _glowEspConn = nil
            local _glowEspAccumulator = 0

            createModuleRow(list, moduleName, j, function(state)
                _glowEspEnabled = state
                if state then
                    if _glowEspConn then _glowEspConn:Disconnect() end
                    _glowEspAccumulator = 0
                    _glowEspConn = RunService.Heartbeat:Connect(function(dt)
                        if not _glowEspEnabled then return end
                        _glowEspAccumulator = _glowEspAccumulator + dt
                        if _glowEspAccumulator < 0.25 then return end
                        _glowEspAccumulator = 0
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= player and p.Character then
                                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                local head = p.Character:FindFirstChild("Head")
                                if hum and hum.Health > 0 and head then
                                    local hl = p.Character:FindFirstChild("SolaraGlowEsp")
                                    if not hl then
                                        hl = Instance.new("Highlight")
                                        hl.Name = "SolaraGlowEsp"
                                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                        hl.FillColor = COLORS.accent
                                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                        hl.FillTransparency = gameplayConfig.glowEspTransparency or 0.45
                                        hl.Parent = p.Character
                                        bindTheme(hl, "FillColor", function() return "accent" end)
                                    end
                                end
                            end
                        end
                    end)
                else
                    if _glowEspConn then _glowEspConn:Disconnect(); _glowEspConn = nil end
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character then
                            local hl = p.Character:FindFirstChild("SolaraGlowEsp")
                            if hl then hl:Destroy() end
                        end
                    end
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- TARGET ESP — Подсветка цели + 4 вращающиеся неоновые души
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Target ESP" then
            local _targetEspEnabled = false
            local _targetEspConn = nil
            local _souls = {}
            local _targetAngle = 0
            local _targetHighlighted = nil

            local function clearTargetVisuals()
                for _, soul in ipairs(_souls) do
                    if soul and soul.Parent then soul:Destroy() end
                end
                _souls = {}
                if _targetHighlighted and _targetHighlighted.Parent then
                    local oldHighlight = _targetHighlighted:FindFirstChild("SolaraTargetEspGlow")
                    if oldHighlight then oldHighlight:Destroy() end
                end
                _targetHighlighted = nil
            end

            createModuleRow(list, moduleName, j, function(state)
                _targetEspEnabled = state
                if state then
                    if _targetEspConn then _targetEspConn:Disconnect() end
                    _targetEspConn = RunService.RenderStepped:Connect(function(dt)
                        if not _targetEspEnabled then return end
                        local targetChar = getSelectedTarget(gameplayConfig.targetEspName) or getClosestPlayer()
                        if not targetChar then
                            clearTargetVisuals()
                            return
                        end
                        local root = targetChar:FindFirstChild("HumanoidRootPart")
                        if not root then return end

                        if _targetHighlighted ~= targetChar then
                            clearTargetVisuals()
                            _targetHighlighted = targetChar
                        end

                        local hl = targetChar:FindFirstChild("SolaraTargetEspGlow")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "SolaraTargetEspGlow"
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.FillColor = COLORS.accent
                            hl.FillTransparency = 0.4
                            hl.Parent = targetChar
                            bindTheme(hl, "FillColor", function() return "accent" end)
                        end

                        _targetAngle = (_targetAngle + dt * gameplayConfig.targetEspSpin) % (math.pi * 2)
                        local center = root.Position

                        if #_souls < 4 then
                            for k = #_souls + 1, 4 do
                                local p = Instance.new("Part")
                                p.Name = "SolaraSoul"
                                p.Shape = Enum.PartType.Ball
                                p.Size = Vector3.new(0.5, 0.5, 0.5)
                                p.Material = Enum.Material.Neon
                                p.Color = COLORS.accent
                                p.Anchored = true
                                p.CanCollide = false
                                p.Parent = workspace
                                bindTheme(p, "Color", function() return "accent" end)
                                table.insert(_souls, p)
                            end
                        end

                        for k, soulPart in ipairs(_souls) do
                            local phase = (k - 1) * (math.pi * 2 / 4)
                            local a = _targetAngle + phase
                            local x = math.cos(a) * gameplayConfig.targetEspSize
                            local z = math.sin(a) * gameplayConfig.targetEspSize
                            local y = math.sin(a * 2) * 2.5
                            soulPart.CFrame = CFrame.new(center + Vector3.new(x, y, z))
                        end
                    end)
                else
                    if _targetEspConn then _targetEspConn:Disconnect(); _targetEspConn = nil end
                    clearTargetVisuals()
                end
            end)

        -- ═══════════════════════════════════════════════════════
        -- TELEPORT — Мгновенный ТП к игроку
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Teleport" then
            local _teleportRow, setTeleportState
            _teleportRow, setTeleportState = createModuleRow(list, moduleName, j, function(state)
                if state then
                    local targetChar = getSelectedTarget(gameplayConfig.teleportTarget)
                    if not targetChar then
                        HUD.notify("Teleport: сначала выберите игрока через ПКМ", "warning", 3)
                        task.defer(setTeleportState, false)
                        return
                    end
                    local myChar = player.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if myRoot and tRoot then
                        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                        HUD.notify("Teleport: перемещение выполнено", "success")
                    else
                        HUD.notify("Teleport: персонаж ещё не загрузился", "error", 3)
                    end
                end
                -- Teleport — одноразовое действие, а не постоянно включённый loop.
                if state then task.defer(setTeleportState, false) end
            end)

        -- PULL PLAYER
        elseif moduleName == "Pull Player" then
            local _pullRow, setPullState
            _pullRow, setPullState = createModuleRow(list, moduleName, j, function(state)
                if state then
                    local targetChar = getSelectedTarget(gameplayConfig.pullTarget)
                    if not targetChar then
                        HUD.notify("Pull Player: сначала выберите игрока через ПКМ", "warning", 3)
                        task.defer(setPullState, false)
                        return
                    end
                    local myChar = player.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if myRoot and tRoot then
                        tRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                        tRoot.Velocity = Vector3.new(0, 0, 0)
                        HUD.notify("Pull Player: действие выполнено", "success")
                    else
                        HUD.notify("Pull Player: персонаж ещё не загрузился", "error", 3)
                    end
                end
                -- Pull Player также выполняется ровно один раз.
                if state then task.defer(setPullState, false) end
            end)

        -- FLING
        elseif moduleName == "Fling" then
            local _flingRow, setFlingState
            local flingRunning = false
            _flingRow, setFlingState = createModuleRow(list, moduleName, j, function(state)
                if state then
                    local targetPlayer = Players:FindFirstChild(gameplayConfig.flingTarget)
                    if not targetPlayer or targetPlayer == player then
                        HUD.notify("Fling: сначала выберите игрока через ПКМ", "warning", 3)
                        task.defer(setFlingState, false)
                        return
                    end
                    if not flingRunning then
                        flingRunning = true
                        HUD.notify("Fling: действие запущено", "success")
                        task.spawn(function()
                            SkidFling(targetPlayer)
                            flingRunning = false
                        end)
                    end
                end
                if state then task.defer(setFlingState, false) end
            end)

        -- ANTI-FLING
        elseif moduleName == "Anti-Fling" then
            local _antiFlingConn = nil
            local _antiFlingOriginal = setmetatable({}, { __mode = "k" })
            createModuleRow(list, moduleName, j, function(state)
                if state then
                    if _antiFlingConn then _antiFlingConn:Disconnect() end
                    _antiFlingConn = RunService.Stepped:Connect(function()
                        local char = player.Character
                        if char then
                            for _, p in ipairs(char:GetChildren()) do
                                if p:IsA("BasePart") then
                                    if _antiFlingOriginal[p] == nil then
                                        _antiFlingOriginal[p] = p.CanCollide
                                    end
                                    p.CanCollide = false
                                end
                            end
                        end
                    end)
                else
                    if _antiFlingConn then _antiFlingConn:Disconnect(); _antiFlingConn = nil end
                    for part, wasCollidable in pairs(_antiFlingOriginal) do
                        if part.Parent then part.CanCollide = wasCollidable end
                        _antiFlingOriginal[part] = nil
                    end
                end
            end)

        -- ESCAPE
        elseif moduleName == "Escape" then
            local _escapeConn = nil
            local _escapeTriggered = setmetatable({}, { __mode = "k" })
            createModuleRow(list, moduleName, j, function(state)
                if state then
                    if _escapeConn then _escapeConn:Disconnect() end
                    _escapeConn = RunService.RenderStepped:Connect(function()
                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health >= gameplayConfig.escapeHealth then
                            _escapeTriggered[hum] = nil
                        elseif hum and root and not _escapeTriggered[hum] then
                            _escapeTriggered[hum] = true
                            root.CFrame = root.CFrame * CFrame.new(0, 45, gameplayConfig.escapeDistance or 50)
                            pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
                            root.Velocity = Vector3.zero
                        end
                    end)
                else
                    if _escapeConn then _escapeConn:Disconnect(); _escapeConn = nil end
                    table.clear(_escapeTriggered)
                end
            end)

        -- ADMIN PANEL
        elseif moduleName == "Admin Panel" then
            local _adminRow, setAdminState
            _adminRow, setAdminState = createModuleRow(list, moduleName, j, function(state)
                -- Админ-команды требуют серверной части и не должны выглядеть
                -- как работающая функция в чистом LocalScript.
                if state then
                    HUD.notify("Admin Panel: команды находятся в настройках ПКМ", "warning", 3)
                    task.defer(setAdminState, false)
                end
            end)
        -- VEHICLE MODULES
        elseif moduleName == "Speed" then
            createModuleRow(list, moduleName, j, function(state)
                gameplayConfig.vehicleSpeedEnabled = state
            end)
        elseif moduleName == "Brakes" then
            createModuleRow(list, moduleName, j, function(state)
                gameplayConfig.vehicleBrakesEnabled = state
            end)
        elseif moduleName == "Handling" then
            createModuleRow(list, moduleName, j, function(state)
                gameplayConfig.vehicleHandlingEnabled = state
            end)

        -- ═══════════════════════════════════════════════════════
        -- CONQUER THE WORLD WW2 MODULES
        -- ═══════════════════════════════════════════════════════
        elseif moduleName == "Smart Movement" or moduleName == "Auto Army" or moduleName == "Auto Factory"
            or moduleName == "Auto Production" or moduleName == "Auto Government" or moduleName == "Auto Diplomacy"
            or moduleName == "Auto Missiles" or moduleName == "Auto Naval" or moduleName == "Auto Air Force"
            or moduleName == "Auto Silo" or moduleName == "Auto Research" then
            local ww2Row, setWw2State
            ww2Row, setWw2State = createModuleRow(list, moduleName, j, function(state)
                if state and HUD.selectedGame and HUD.selectedGame.id == "universal" and not HUD.isWw2Game() then
                    if HUD.notify then
                        HUD.notify(CURRENT_LANG == "RU" and "Функция доступна только в Conquer The World WW2!" or "仅适用于 Conquer The World WW2！", "warn")
                    end
                    if setWw2State then setWw2State(false) end
                    return
                end
                if state then Ww2Engine.init() end
                if moduleName == "Smart Movement" then
                    Ww2Engine.State.SmartMovement = state
                    if not state then
                        Ww2Engine.cancelTacticalThreads()
                    end
                elseif moduleName == "Auto Army" then
                    Ww2Engine.State.AutoArmy = state
                elseif moduleName == "Auto Factory" then
                    Ww2Engine.State.AutoFactory = state
                elseif moduleName == "Auto Production" then
                    Ww2Engine.State.AutoProduction = state
                elseif moduleName == "Auto Government" then
                    Ww2Engine.State.AutoGovernment = state
                elseif moduleName == "Auto Diplomacy" then
                    Ww2Engine.State.AutoDiplomacy = state
                    if state and Ww2Engine.dipState then
                        Ww2Engine.dipState.justifying = {}
                    end
                elseif moduleName == "Auto Missiles" then
                    Ww2Engine.State.AutoMissile = state
                elseif moduleName == "Auto Naval" then
                    Ww2Engine.State.AutoNaval = state
                    if state and Ww2Engine.navalState then
                        Ww2Engine.navalState.phase = "idle"
                        Ww2Engine.navalState.usedArmies = {}
                    end
                elseif moduleName == "Auto Air Force" then
                    Ww2Engine.State.AutoPlanes = state
                    if state and Ww2Engine.planeDeployed then
                        table.clear(Ww2Engine.planeDeployed)
                    end
                elseif moduleName == "Auto Silo" then
                    Ww2Engine.State.AutoSilo = state
                elseif moduleName == "Auto Research" then
                    Ww2Engine.State.AutoResearch = state
                end
            end)
        elseif moduleName == "Teleport to" then
            local _vehTpRow, setVehTpState
            _vehTpRow, setVehTpState = createModuleRow(list, moduleName, j, function(state)
                if state then
                    if HUD.teleportVehicleToPlayer then HUD.teleportVehicleToPlayer() end
                    task.defer(setVehTpState, false)
                end
            end)
        else
            createModuleRow(list, moduleName, j)
        end
end

-- =========================================================================
-- VEHICLE PHYSICS ENGINE (Heartbeat loop across all places)
-- =========================================================================
do
    local function updateVehicles(dt)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat or not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then return end
        local root = seat.AssemblyRootPart or seat
        if not root then return end

        local fwd = root.CFrame.LookVector
        local fwdFlat = Vector3.new(fwd.X, math.clamp(fwd.Y, -0.5, 0.5), fwd.Z).Unit

        -- 1. VEHICLE FLY
        if gameplayConfig.vehicleFlyEnabled then
            local cam = workspace.CurrentCamera
            if cam then
                local moveDir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                local flySpd = gameplayConfig.vehicleFlySpeed or 60
                if moveDir.Magnitude > 0 then
                    root.AssemblyLinearVelocity = moveDir.Unit * flySpd
                else
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                local look = cam.CFrame.LookVector
                local pitch = math.clamp(look.Y, -0.6, 0.6)
                local horizLook = Vector3.new(look.X, pitch, look.Z).Unit
                root.CFrame = CFrame.lookAt(root.Position, root.Position + horizLook)
            end
            return
        end

        -- 2. SPEED BOOST (0 - 50)
        if gameplayConfig.vehicleSpeedEnabled and (gameplayConfig.vehicleSpeed or 0) > 0 then
            local throttle = 0
            if seat:IsA("VehicleSeat") and seat.Throttle ~= 0 then
                throttle = seat.Throttle
            elseif UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
                throttle = 1
            elseif UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
                throttle = -1
            end
            if throttle > 0 then
                local speedVal = gameplayConfig.vehicleSpeed or 25
                local boostAcc = (speedVal / 25) * 55
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + fwdFlat * (boostAcc * dt)
                if seat:IsA("VehicleSeat") then
                    pcall(function()
                        if seat.MaxSpeed < 140 + speedVal * 8 then
                            seat.MaxSpeed = 140 + speedVal * 8
                        end
                        if seat.Torque < 500000 then
                            seat.Torque = 500000
                        end
                    end)
                end
            end
        end

        -- 3. BRAKES (0 - 50)
        if gameplayConfig.vehicleBrakesEnabled and (gameplayConfig.vehicleBrakes or 0) > 0 then
            local isBraking = false
            if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                isBraking = true
            elseif seat:IsA("VehicleSeat") and seat.Throttle < 0 then
                isBraking = true
            end
            if isBraking then
                local currentVel = root.AssemblyLinearVelocity
                local fwdVel = currentVel:Dot(fwdFlat)
                if fwdVel > 1 then
                    local brakeVal = gameplayConfig.vehicleBrakes or 25
                    local brakeStrength = (brakeVal / 50) * 8
                    local decel = math.min(fwdVel, brakeStrength * 35 * dt)
                    root.AssemblyLinearVelocity = currentVel - fwdFlat * decel
                end
            end
        end

        -- 4. HANDLING (0 - 50)
        if gameplayConfig.vehicleHandlingEnabled and (gameplayConfig.vehicleHandling or 0) > 0 then
            local steerInput = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) or (seat:IsA("VehicleSeat") and seat.Steer < 0) then
                steerInput = steerInput + 1
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) or (seat:IsA("VehicleSeat") and seat.Steer > 0) then
                steerInput = steerInput - 1
            end
            if steerInput ~= 0 then
                local handVal = gameplayConfig.vehicleHandling or 25
                local yawRate = (handVal / 25) * 2.0
                local curAng = root.AssemblyAngularVelocity
                local upVec = root.CFrame.UpVector
                root.AssemblyAngularVelocity = Vector3.new(curAng.X * 0.85, 0, curAng.Z * 0.85) + upVec * (steerInput * yawRate)

                local rightVec = root.CFrame.RightVector
                local latSpeed = root.AssemblyLinearVelocity:Dot(rightVec)
                local gripDamping = math.clamp((handVal / 50) * 0.45, 0.1, 0.55)
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity - rightVec * (latSpeed * gripDamping)
                if seat:IsA("VehicleSeat") then
                    pcall(function()
                        if seat.TurnSpeed < 2 + (handVal / 50) * 8 then
                            seat.TurnSpeed = 2 + (handVal / 50) * 8
                        end
                    end)
                end
            end
        end
    end

    trackRuntimeConnection(RunService.Heartbeat:Connect(updateVehicles))
end

-- NAVIGATION_START
HUD.categoryCopy = {
    COMBAT = { "Бой", "战斗", "Боевые функции и управление целью", "战斗与目标功能" },
    MOVEMENT = { "Движение", "移动", "Скорость, перемещение и управление персонажем", "速度、位移与角色移动" },
    VISUALS = { "Визуал", "视觉", "Освещение, эффекты и отображение мира", "光照、特效与世界显示" },
    PLAYER = { "Игроки", "玩家", "Инструменты взаимодействия с игроками", "玩家交互工具" },
    MISC = { "Прочее", "其他", "Дополнительные инструменты клиента", "其他客户端工具" },
}

function HUD.isCategoryAllowed(name)
    if HUD.selectedGame then
        if HUD.selectedGame.id == "universal" then
            return true
        end
        if HUD.selectedGame.id == "strongest_battlegrounds" and name == "PLAYER" then
            return false
        end
        if HUD.selectedGame.id == "midnight_chasers" and (name == "MOVEMENT" or name == "MISC") then
            return false
        end
    end
    return true
end

function HUD.refreshNavigation(selectFirstMatch)
    local query = searchBox.Text:lower()
    local counts = {}
    local isUniversal = HUD.selectedGame and HUD.selectedGame.id == "universal"
    local isMidnight = HUD.selectedGame and HUD.selectedGame.id == "midnight_chasers"
    local isTsb = HUD.selectedGame and HUD.selectedGame.id == "strongest_battlegrounds"
    local isWw2 = HUD.selectedGame and HUD.selectedGame.id == "conquer_world_ww2"
    for _, entry in ipairs(allModuleRows) do
        local allowed = HUD.isCategoryAllowed(entry.category)
        if allowed and entry.category == "COMBAT" then
            local isVehicleModule = (entry.name == "speed" or entry.name == "brakes" or entry.name == "handling" or entry.name == "teleport to" or (entry.name == "fly" and entry.category == "COMBAT"))
            local isTsbModule = (entry.name == "instant dash" or entry.name == "no block slow" or entry.name == "desync glitch" or entry.name == "fast m1")
            local isWw2Module = (
                entry.name == "smart movement" or entry.name == "auto army" or
                entry.name == "auto factory" or entry.name == "auto production" or
                entry.name == "auto government" or entry.name == "auto diplomacy" or
                entry.name == "auto missiles" or entry.name == "auto naval" or
                entry.name == "auto air force" or entry.name == "auto silo" or
                entry.name == "auto research"
            )
            if isUniversal then
                allowed = true
            elseif isWw2 then
                allowed = isWw2Module
            elseif isMidnight then
                allowed = isVehicleModule
            elseif isTsb then
                allowed = not isVehicleModule and not isWw2Module
            else
                allowed = not isVehicleModule and not isTsbModule and not isWw2Module
            end
        end
        entry.row.Visible = allowed and (query == "" or entry.name:find(query, 1, true) ~= nil or (entry.searchName and entry.searchName:find(query, 1, true) ~= nil))
        if entry.row.Visible then counts[entry.category] = (counts[entry.category] or 0) + 1 end
        if entry.refreshText then entry.refreshText() end
    end
    local firstAllowed, firstMatch
    for _, view in ipairs(HUD.categoryViews) do
        local name = view.category.name
        local allowed = HUD.isCategoryAllowed(name)
        view.button.Visible = allowed
        if allowed then
            firstAllowed = firstAllowed or name
            if (counts[name] or 0) > 0 then firstMatch = firstMatch or name end
        end
    end
    if not HUD.isCategoryAllowed(HUD.activeCategory) then HUD.activeCategory = firstAllowed end
    if selectFirstMatch and query ~= "" and (counts[HUD.activeCategory] or 0) == 0 and firstMatch then
        HUD.activeCategory = firstMatch
    end
    for _, view in ipairs(HUD.categoryViews) do
        local name = view.category.name
        local active = HUD.activeCategory == name
        local copy = HUD.categoryCopy[name]
        if isWw2 and name == "COMBAT" then
            copy = { "Военная стратегия", "二战战略", "Управление войсками, производство, дипломатия и исследования", "军事指挥、经济、外交与战争" }
        elseif isMidnight and name == "COMBAT" then
            copy = { "Транспорт", "车辆", "Управление, скорость и параметры автомобиля", "车辆操控、速度与驾驶参数" }
        elseif isUniversal and name == "COMBAT" then
            copy = { "Бой и стратегия", "战斗与战略", "Все боевые, военные и транспортные инструменты", "全部战斗、战略与车辆工具" }
        end
        local ru = CURRENT_LANG == "RU"
        view.page.Visible = active and HUD.isCategoryAllowed(name)
        view.label.Text = copy[ru and 1 or 2]
        view.title.Text = copy[ru and 1 or 2]
        view.subtitle.Text = copy[ru and 3 or 4]
        view.count.Text = tostring(counts[name] or 0)
        view.empty.Text = ru and "Ничего не найдено. Попробуй другой запрос." or "未找到匹配功能，请更换关键词。"
        view.empty.Visible = (counts[name] or 0) == 0
        view.indicator.Visible = active
        tween(view.button, { BackgroundColor3 = active and COLORS.panelAlt or COLORS.off }, 0.15)
        tween(view.label, { TextColor3 = active and COLORS.text or COLORS.textDim }, 0.15)
    end
    if HUD.navigationCaption then HUD.navigationCaption.Text = CURRENT_LANG == "RU" and "功能分类" or "功能分类" end
    if HUD.themeLibraryButton then HUD.themeLibraryButton.Text = CURRENT_LANG == "RU" and "主题" or "主题库" end
    if themeFabButton then themeFabButton.Text = CURRENT_LANG == "RU" and "    外观" or "    外观" end
    if HUD.menuHint then HUD.menuHint.Text = CURRENT_LANG == "RU" and "ПКМ или ⋯ — параметры функции  /  R — скрыть" or "点击 ⋯ 打开设置 / R 隐藏界面" end
end

function HUD.changeCategory(name)
    if not HUD.isCategoryAllowed(name) then return false end
    local exists = false
    for _, view in ipairs(HUD.categoryViews) do if view.category.name == name then exists = true end end
    if not exists then return false end
    closeSettingsPanel()
    if HUD.closeSettings then HUD.closeSettings() end
    HUD.activeCategory = name
    HUD.refreshNavigation(false)
    return true
end

function HUD.applyGameProfile()
    if not HUD.selectedGame then return end
    HUD.profileImage.Image = HUD.selectedGame.image
    HUD.profileName.Text = HUD.selectedGame.name
    if HUD.profilePlaceholder then
        local emptyImg = (HUD.selectedGame.image == nil or HUD.selectedGame.image == "")
        HUD.profilePlaceholder.Visible = emptyImg
        HUD.profilePlaceholder.Text = HUD.selectedGame.initials or "UNI"
    end
    HUD.refreshNavigation(true)
end
-- NAVIGATION_END

local function buildCategories()
    for i, category in ipairs(CATEGORIES) do
        local column = create("Frame", {
            Name = category.name, Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, Visible = false, Parent = columnsHolder,
        })
        local header = create("TextLabel", {
            Name = "Header", Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1,
            Text = category.name, TextColor3 = COLORS.header, Font = Enum.Font.GothamBold,
            TextSize = 30, TextXAlignment = Enum.TextXAlignment.Left, Parent = column,
        })
        local subtitle = create("TextLabel", {
            Position = UDim2.fromOffset(0, 47), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
            Text = "", TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = COLORS.textDim,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = column,
        })
        create("Frame", { Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = COLORS.stroke, Parent = column })
        local list = create("ScrollingFrame", {
            Name = "List", Size = UDim2.new(1, 0, 1, -100), Position = UDim2.fromOffset(0, 100),
            BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
            ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.accent, ScrollBarImageTransparency = 0.45,
            CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true, Parent = column,
        })
        list:SetAttribute("Category", category.name)
        bindTheme(list, "ScrollBarImageColor3", "accent")
        create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
        create("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingLeft = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), Parent = list })
        local empty = create("TextLabel", {
            Name = "EmptyState", Position = UDim2.fromOffset(0, 130), Size = UDim2.new(1, 0, 0, 80),
            Text = "", TextWrapped = true, TextSize = 14, Font = Enum.Font.Gotham,
            TextColor3 = COLORS.textDim, BackgroundTransparency = 1, Visible = false, Parent = column,
        })
        local button = create("TextButton", {
            Name = category.name, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = i, Text = "",
            BackgroundColor3 = COLORS.off, AutoButtonColor = false, Parent = HUD.navigation,
        })
        corner(button, 9)
        local indicator = create("Frame", { Position = UDim2.new(0, 0, 0.5, -9), Size = UDim2.fromOffset(2, 18),
            BackgroundColor3 = COLORS.accent, BorderSizePixel = 0, Parent = button })
        corner(indicator, 1)
        local label = create("TextLabel", {
            Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1,
            Text = category.name, TextSize = 13, Font = Enum.Font.GothamMedium,
            TextColor3 = COLORS.textDim, TextXAlignment = Enum.TextXAlignment.Left, Parent = button,
        })
        local count = create("TextLabel", {
            Position = UDim2.new(1, -38, 0, 0), Size = UDim2.fromOffset(26, 44), BackgroundTransparency = 1,
            Text = tostring(#category.modules), TextSize = 11, Font = Enum.Font.Gotham,
            TextColor3 = COLORS.textDim, Parent = button,
        })
        bindTheme(button, "BackgroundColor3", function() return HUD.activeCategory == category.name and "panelAlt" or "off" end)
        bindTheme(label, "TextColor3", function() return HUD.activeCategory == category.name and "text" or "textDim" end)
        button.Activated:Connect(function() HUD.changeCategory(category.name) end)
        button.MouseEnter:Connect(function() tween(button, { BackgroundColor3 = COLORS.hover }, 0.12) end)
        button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = HUD.activeCategory == category.name and COLORS.panelAlt or COLORS.off }, 0.12)
        end)
        for j, moduleName in ipairs(category.modules) do buildModule(list, moduleName, j) end
        table.insert(HUD.categoryViews, { category = category, button = button, page = column,
            label = label, title = header, subtitle = subtitle, count = count, empty = empty, indicator = indicator })
        table.insert(createdColumns, column)
    end
    HUD.refreshNavigation(false)
end
buildCategories()

searchBox:GetPropertyChangedSignal("Text"):Connect(function() HUD.refreshNavigation(true) end)
 
----------------------------------------------------------------
-- Логика Открытия / Закрытия меню (клавиша R)
----------------------------------------------------------------
 
local function toggleMenu(open)
    if not runtimeAlive or not HUD.selectedGame then return end
    menuOpen = open
    if open then
        window.Visible = true
        themeFabButton.Visible = true
        targetPos = HUD.updateWindowScale()
        tween(blurEffect, { Size = backgroundBlurAmount }, 0.3)
        tween(window, { Size = UDim2.fromOffset(HUD.layout.width, HUD.layout.height), Position = targetPos }, 0.25, Enum.EasingStyle.Quint)
        tween(mainGroup, { GroupTransparency = 0 }, 0.25)
    else
        closeSettingsPanel()
        closeThemeManager()
        if HUD.closeSettings then HUD.closeSettings() end
        if themeDockOpen then toggleThemeDock() end
        themeFabButton.Visible = false
        tween(blurEffect, { Size = 0 }, 0.2)
        tween(mainGroup, { GroupTransparency = 1 }, 0.2)
        local closedPos = HUD.updateWindowScale()
        targetPos = closedPos
        local t = tween(window, { Position = closedPos }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            if not menuOpen then
                window.Visible = false
            end
        end)
    end
end

HUD.hideMenuButton.Activated:Connect(function() toggleMenu(false) end)

local mobileMenuButton
if UserInputService.TouchEnabled then
    mobileMenuButton = create("TextButton", {
        Name = "MobileMenuButton", AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(64, 42),
        BackgroundColor3 = COLORS.panelAlt, TextColor3 = COLORS.text,
        Text = "菜单", TextSize = 14, Font = Enum.Font.GothamSemibold,
        AutoButtonColor = true, ZIndex = 1000, Parent = screenGui,
    })
    corner(mobileMenuButton, 10)
    stroke(mobileMenuButton, COLORS.stroke, 0.7)
    mobileMenuButton.Activated:Connect(function() toggleMenu(not menuOpen) end)
end

trackRuntimeConnection(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not HUD.selectedGame then return end
    if input.KeyCode == TOGGLE_KEY then
        if clearScreenActive and clearScreenSetState then
            clearScreenSetState(false)
            toggleMenu(true)
        else
            toggleMenu(not menuOpen)
        end
    elseif HUD.selectedGame and (HUD.selectedGame.id == "strongest_battlegrounds" or (HUD.selectedGame.id == "universal" and HUD.isTsbGame())) and input.KeyCode == (gameplayConfig.tsbDashKey or Enum.KeyCode.Z) then
        if gameplayConfig.tsbDashEnabled then
            executeTsbDash()
        end
    end
end))
 
----------------------------------------------------------------
-- HUD: плавающая карточка со статистикой (полностью кастомизируемая)
--
-- Что теперь можно менять живьём, без правки кода:
--   • Цвет текста/акцента HUD       (тема или свой цвет)
--   • Цвет фона HUD                  (тема или свой цвет)
--   • Прозрачность фона HUD          (слайдер 0-100%, теперь также доступен в Theme Dock)
--   • Размер текста HUD              (слайдер 10-20px)
--   • Название плейса                (текстовое поле, автоопределение по умолчанию)
--   • Ник персонажа                  (текстовое поле, автоопределение по умолчанию)
----------------------------------------------------------------
 

 
local hudColorState = {
    useTheme      = true,                              -- цвет текста/индикатора = акцент активной темы
    accentColor   = Color3.fromRGB(115, 83, 255),       -- свой цвет текста, если useTheme = false
    bgUseTheme    = true,                               -- фон HUD = COLORS.panel текущей темы
    bgColor       = Color3.fromRGB(8, 8, 10),           -- свой цвет фона, если bgUseTheme = false
    bgTransparency = 0.08,                              -- прозрачность фона HUD (0 = непрозрачный)
    textSize      = 12,                                 -- размер текста строк HUD
    placeName     = (function() local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end) return (ok and info and info.Name) or "Unknown Place" end)(),                      -- по умолчанию — автоопределение плейса
    nickname      = player.DisplayName or player.Name,                       -- по умолчанию — автоопределение ника
}
 
-- Синхронизируем слайдер "HUD 透明度" в Theme Dock со стартовым значением.
do
    local maxVal = HUD_TRANSP_MAX or 0.9
    local rel = math.clamp(hudColorState.bgTransparency / maxVal, 0, 1)
    if hudTranspFill then hudTranspFill.Size = UDim2.new(rel, 0, 1, 0) end
    if hudTranspValLabel then hudTranspValLabel.Text = tostring(math.floor(hudColorState.bgTransparency * 100)) .. "%" end
end
 
-- Публичный сеттер, которым пользуется слайдер в Theme Dock.
_setHudBgTransparency = function(value)
    hudColorState.bgTransparency = value
    if refreshHudColors then refreshHudColors() end
end
 
function HUD.getAccentColor()
    return hudColorState.useTheme and COLORS.accent or hudColorState.accentColor
end
 
function HUD.getBgColor()
    return hudColorState.bgUseTheme and COLORS.panel or hudColorState.bgColor
end
 
-- Элементы, зависящие от акцента HUD (индикатор + значения статистики)
local hudColorBoundElements = {}
local hudNameLabels = {} -- mapping key -> nameLabel for localization
function HUD.bindColor(inst, prop)
    table.insert(hudColorBoundElements, { inst = inst, prop = prop })
    return inst
end

-- Функция смены языка для HUD и других частей UI
HUD.setLanguage = function(code)
    if not LANGS[code] then return end
    CURRENT_LANG = code
    if HUD.refreshNavigation then HUD.refreshNavigation(false) end
    -- Обновляем все зарегистрированные HUD-подписи
    for key, lbl in pairs(hudNameLabels) do
        if lbl and lbl.Parent then
            lbl.Text = translate(key)
        end
    end
-- Обновляем placeholder поиска, если он есть
if searchBox and searchBox.Parent then
    pcall(function()
        searchBox.PlaceholderText = translate("SEARCH_PLACEHOLDER")
    end)
end
end

-- Строки HUD, у которых нужно менять размер шрифта лейбла и значения
local hudTextSizeBound = {}
function HUD.bindTextSize(label)
    table.insert(hudTextSizeBound, label)
    return label
end
 
local hudUI = {}
 
-- ФИКС: убрано повторное `local refreshHudColors`, которое раньше стояло
-- здесь и затеняло переменную, объявленную в самом начале скрипта.
-- Теперь присваивание ниже попадает в ту же (единственную) переменную,
-- которую уже используют ApplyTheme, ApplySavedTheme, свотчи цвета
-- в Theme Dock и _setHudBgTransparency.
 
function HUD.refreshCustomRows()
    if hudUI.placeRow then
        hudUI.placeRow.Visible = hudColorState.placeName ~= ""
        hudUI.placeValue.Text = hudColorState.placeName
    end
    if hudUI.nickRow then
        hudUI.nickRow.Visible = hudColorState.nickname ~= ""
        hudUI.nickValue.Text = hudColorState.nickname
    end
end
 
refreshHudColors = function()
    local col = HUD.getAccentColor()
    local bg = HUD.getBgColor()
 
    for _, entry in ipairs(hudColorBoundElements) do
        if entry.inst.Parent then
            tween(entry.inst, { [entry.prop] = col }, 0.25)
        end
    end
 
    if hudUI.frame and hudUI.frame.Parent then
        tween(hudUI.frame, { BackgroundColor3 = bg, BackgroundTransparency = hudColorState.bgTransparency }, 0.25)
    end
 
    for _, label in ipairs(hudTextSizeBound) do
        if label.Parent then
            label.TextSize = hudColorState.textSize
        end
    end
 
    -- Держим слайдер в Theme Dock синхронизированным, если прозрачность
    -- была изменена из панели настроек HUD (ПКМ по строке HUD).
    if hudTranspFill and hudTranspValLabel then
        local maxVal = HUD_TRANSP_MAX or 0.9
        local rel = math.clamp(hudColorState.bgTransparency / maxVal, 0, 1)
        hudTranspFill.Size = UDim2.new(rel, 0, 1, 0)
        hudTranspValLabel.Text = tostring(math.floor(hudColorState.bgTransparency * 100)) .. "%"
    end
end
 
local hudState = {
    masterEnabled = true,
}
 
function HUD.buildPanel()
    hudUI.frame = create("Frame", {
        Name = "HUDFrame",
        Size = UDim2.new(0, 236, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 16, 0, 16),
        BackgroundColor3 = HUD.getBgColor(),
        BackgroundTransparency = hudColorState.bgTransparency,
        Active = true,
        Draggable = true,
        themeBind = false, -- фон управляется вручную через refreshHudColors
        Parent = screenGui,
    })
    corner(hudUI.frame, 16)
    local _hudFrameStroke = stroke(hudUI.frame, COLORS.stroke, 1)
 
    local hudHeader = create("Frame", {
        Name = "HUDHeader",
        Size = UDim2.new(1, 0, 0, 38),
        -- Прозрачная шапка использует тот же фон HUD: на стыке больше нет
        -- светлой горизонтальной полосы при светлых/контрастных темах.
        BackgroundTransparency = 1,
        Parent = hudUI.frame,
    })
 
    -- Кружок-индикатор — цвет из HUD.getAccentColor()
    hudUI.dot = create("Frame", {
        Name = "StatusDot",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 10, 0.5, -4.5),
        BackgroundColor3 = HUD.getAccentColor(),
        BorderSizePixel = 0,
        themeBind = false,
        Parent = hudHeader,
    })
    corner(hudUI.dot, 5)
    HUD.bindColor(hudUI.dot, "BackgroundColor3")
 
    task.spawn(function()
        while runtimeAlive and hudUI.dot.Parent do
            tween(hudUI.dot, { BackgroundTransparency = 0.55 }, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
            if not runtimeAlive or not hudUI.dot.Parent then break end
            tween(hudUI.dot, { BackgroundTransparency = 0 }, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
        end
    end)
 
    create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1,
        Text = "SOLARA / HUD",
        TextColor3 = COLORS.header,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hudHeader,
    })
 
    local hudBody = create("Frame", {
        Name = "HUDBody",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = hudUI.frame,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = hudBody,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = hudBody,
    })
 
    local function addHudRow(nameKey, order)
        local row = create("Frame", {
                Name = nameKey .. "Row",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = COLORS.off,
            BackgroundTransparency = 0.35,
            LayoutOrder = order,
            Parent = hudBody,
        })
        corner(row, 6)

        local nameLabel = create("TextLabel", {
            Size = UDim2.new(0.55, -6, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
                Text = translate(nameKey),
            TextColor3 = COLORS.textDim,
            Font = Enum.Font.GothamSemibold,
            TextSize = hudColorState.textSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row,
        })
        HUD.bindTextSize(nameLabel)
            hudNameLabels[nameKey] = nameLabel

            local valueLabel = create("TextLabel", {
                Name = "Value",
                Size = UDim2.new(0.45, -8, 1, 0),
                Position = UDim2.new(0.55, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "--",
                TextColor3 = HUD.getAccentColor(),
                Font = Enum.Font.GothamSemibold,
                TextSize = hudColorState.textSize,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                themeBind = false,
                Parent = row,
            })
            HUD.bindColor(valueLabel, "TextColor3")
            HUD.bindTextSize(valueLabel)

            return valueLabel, row
        end
 
    hudUI.fpsValue = addHudRow("HUD_FPS", 1)
    hudUI.pingValue = addHudRow("HUD_PING", 2)
    HUD.activeModulesValue = addHudRow("HUD_MODULES", 3)
    hudUI.clockValue = addHudRow("HUD_TIME", 4)
    hudUI.placeValue, hudUI.placeRow = addHudRow("HUD_PLACE", 5)
    hudUI.nickValue, hudUI.nickRow = addHudRow("HUD_NICK", 6)

    HUD.refreshModuleSummary = function()
        local active = 0
        for moduleName, enabled in pairs(HUD.moduleStates) do
            if enabled and not HUD.actionModules[moduleName] then active = active + 1 end
        end
        if HUD.activeModulesValue and HUD.activeModulesValue.Parent then
            HUD.activeModulesValue.Text = tostring(active)
        end
    end
    HUD.refreshModuleSummary()
 
    HUD.refreshCustomRows()
    refreshHudColors()
end
 
HUD.buildPanel()
 
function HUD.refreshVisibility()
    hudUI.frame.Visible = hudState.masterEnabled
end
HUD.refreshVisibility()
 
HUD.setMasterEnabled = function(state)
    hudState.masterEnabled = state
    HUD.refreshVisibility()
end

HUD.getMasterEnabled = function()
    return hudState.masterEnabled
end
 
----------------------------------------------------------------
-- Обновление данных HUD (ФПС / Пинг / Часы) в реальном времени
----------------------------------------------------------------
 
do
    local fpsFrames, fpsTimer = 0, 0
    trackRuntimeConnection(RunService.RenderStepped:Connect(function(dt)
        fpsFrames = fpsFrames + 1
        fpsTimer = fpsTimer + dt
        if fpsTimer >= 0.5 then
            hudUI.fpsValue.Text = tostring(math.floor(fpsFrames / fpsTimer + 0.5))
            fpsFrames, fpsTimer = 0, 0
        end
    end))
end

task.spawn(function()
    while runtimeAlive and screenGui.Parent do
        local okPing, ms = pcall(function()
            return player:GetNetworkPing()
        end)
        hudUI.pingValue.Text = (okPing and ms) and (math.floor(ms * 1000 + 0.5) .. " ms") or "N/A"
        hudUI.clockValue.Text = os.date("%H:%M:%S")
        task.wait(1)
    end
end)
 
----------------------------------------------------------------
-- Панель настроек HUD (ПКМ по строке "HUD" в меню)
-- Теперь содержит:
--   • Цвет текста (тема / свой + пикер)
--   • Цвет фона   (тема / свой + пикер)
--   • Прозрачность фона (слайдер)
--   • Размер текста     (слайдер)
--   • Название плейса   (текстовое поле, по умолчанию — автоопределение)
--   • Ник персонажа     (текстовое поле, по умолчанию — автоопределение)
----------------------------------------------------------------
 
HUD.closeSettings = closeSettingsPanel
 
do
-- Небольшой хелпер: строка-переключатель "тема / свой цвет" + свотч
local function buildToggleColorRow(parent, order, labelText, getState, setState, getColor, onPickColor)
    local row = create("Frame", {
        Size = UDim2.new(1, -20, 0, 32),
        BackgroundColor3 = COLORS.panelAlt,
        BackgroundTransparency = 0.1,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(row, 8)
    stroke(row, COLORS.stroke, 0.5)
 
    create("TextLabel", {
        Size = UDim2.new(1, -96, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
 
    local switch = create("Frame", {
        Size = UDim2.new(0, 32, 0, 16),
        Position = UDim2.new(1, -80, 0.5, -8),
        BackgroundColor3 = getState() and COLORS.accent or COLORS.off,
        themeBind = false,
        Parent = row,
    })
    corner(switch, 8)
    stroke(switch)
 
    local knob = create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = getState() and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        themeBind = false,
        Parent = switch,
    })
    corner(knob, 6)
 
    local swatch = create("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -34, 0.5, -11),
        BackgroundColor3 = getColor(),
        Text = "",
        AutoButtonColor = false,
        themeBind = false,
        Parent = row,
    })
    corner(swatch, 6)
    stroke(swatch, COLORS.stroke, 1)
 
    local function refreshRow()
        local enabled = not getState()
        swatch.BackgroundTransparency = enabled and 0 or 0.5
    end
    refreshRow()
 
    local switchBtn = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = switch })
    switchBtn.MouseButton1Click:Connect(function()
        setState(not getState())
        tween(knob, {
            Position = getState() and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        }, 0.2, Enum.EasingStyle.Back)
        tween(switch, { BackgroundColor3 = getState() and COLORS.accent or COLORS.off }, 0.2)
        refreshRow()
        refreshHudColors()
    end)
 
    swatch.MouseButton1Click:Connect(function()
        if getState() then return end
        openColorPicker(swatch, getColor(), labelText, function(newColor)
            onPickColor(newColor)
            swatch.BackgroundColor3 = newColor
            refreshHudColors()
        end)
    end)
 
    return row
end
 
-- Хелпер: строка-слайдер (0..100, с произвольным диапазоном значений)
local function buildSliderRow(parent, order, labelText, minVal, maxVal, initVal, onChange)
    local row = create("Frame", {
        Size = UDim2.new(1, -20, 0, 40),
        BackgroundColor3 = COLORS.panelAlt,
        BackgroundTransparency = 0.1,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(row, 8)
    stroke(row, COLORS.stroke, 0.5)
 
    create("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
 
    local valLabel = create("TextLabel", {
        Size = UDim2.new(0.35, -10, 0, 16),
        Position = UDim2.new(0.65, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(initVal),
        TextColor3 = COLORS.textDim,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })
 
    local bar = create("Frame", {
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, 26),
        BackgroundColor3 = COLORS.off,
        Parent = row,
    })
    corner(bar, 3)
    stroke(bar, COLORS.stroke, 0.5)
 
    local startAlpha = (initVal - minVal) / (maxVal - minVal)
    local fill = create("Frame", {
        Size = UDim2.new(startAlpha, 0, 1, 0),
        BackgroundColor3 = COLORS.accent,
        Parent = bar,
    })
    corner(fill, 3)
 
    local function update(inputPos)
        local rel = math.clamp((inputPos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        local value = minVal + (maxVal - minVal) * rel
        valLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)
        onChange(value)
    end
 
    bindPointerDrag(bar, update)
 
    return row
end
 
-- Хелпер: строка с текстовым полем
local function buildTextRow(parent, order, labelText, placeholder, initValue, onChange)
    local row = create("Frame", {
        Size = UDim2.new(1, -20, 0, 32),
        BackgroundColor3 = COLORS.panelAlt,
        BackgroundTransparency = 0.1,
        LayoutOrder = order,
        Parent = parent,
    })
    corner(row, 8)
    stroke(row, COLORS.stroke, 0.5)
 
    create("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
 
    local box = create("TextBox", {
        Size = UDim2.new(0.6, -16, 0, 22),
        Position = UDim2.new(0.4, 0, 0.5, -11),
        BackgroundColor3 = COLORS.off,
        Text = initValue,
        PlaceholderText = placeholder,
        PlaceholderColor3 = COLORS.textDim,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        ClearTextOnFocus = false,
        Parent = row,
    })
    corner(box, 6)
    stroke(box, COLORS.stroke, 0.5)
    create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = box })
 
    box:GetPropertyChangedSignal("Text"):Connect(function()
        onChange(box.Text)
    end)
 
    return row
end
 
HUD.openSettings = function(anchorRow)
    local list = createCustomPanel(translate("HUD_SETTINGS"), 350, 420)
    create("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list,
    })
    local padding = list:FindFirstChild("SettingsPadding")
    padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 12), UDim.new(0, 14)
    padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
 
    buildToggleColorRow(list, 1, "Цвет текста",
        function() return hudColorState.useTheme end,
        function(v) hudColorState.useTheme = v end,
        function() return hudColorState.accentColor end,
        function(c) hudColorState.accentColor = c end)
 
    buildToggleColorRow(list, 2, "Цвет фона",
        function() return hudColorState.bgUseTheme end,
        function(v) hudColorState.bgUseTheme = v end,
        function() return hudColorState.bgColor end,
        function(c) hudColorState.bgColor = c end)
 
    buildSliderRow(list, 3, "Прозрачность фона", 0, 0.9, hudColorState.bgTransparency, function(v)
        hudColorState.bgTransparency = v
        refreshHudColors()
    end)
 
    buildSliderRow(list, 4, "Размер текста", 10, 20, hudColorState.textSize, function(v)
        hudColorState.textSize = math.floor(v + 0.5)
        refreshHudColors()
    end)
 
    buildTextRow(list, 5, translate("HUD_PLACE"), "Название плейса (авто)", hudColorState.placeName, function(text)
        hudColorState.placeName = text
        HUD.refreshCustomRows()
    end)
    buildTextRow(list, 6, translate("HUD_NICK"), "Ник персонажа (авто)", hudColorState.nickname, function(text)
        hudColorState.nickname = text
        HUD.refreshCustomRows()
    end)
end
end
 
----------------------------------------------------------------
-- GAME_SELECTION_START
-- Отдельный ScreenGui: основное меню и HUD полностью скрыты до выбора.
----------------------------------------------------------------

function HUD.showGameSelection()
    if not runtimeAlive or HUD.selectedGame or HUD.gameSelectorGui then return end
    screenGui.Enabled = false
    window.Visible = false
    menuOpen = false
    themeFabButton.Visible = false
    HUD.notificationsReady = false
    HUD.gameSelectionPending = false

    local function ui(class, props)
        props.themeBind = false
        return create(class, props)
    end
    local russian = CURRENT_LANG == "RU"
    local gui = ui("ScreenGui", {
        Name = "SolaraGameSelection", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = targetGuiContainer,
    })
    HUD.gameSelectorGui = gui
    local backdrop = ui("Frame", {
        Name = "Backdrop", Size = UDim2.fromScale(1, 1), Active = true,
        BackgroundColor3 = Color3.fromRGB(5, 6, 10), BorderSizePixel = 0, Parent = gui,
    })
    ui("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(23, 23, 27), Color3.fromRGB(8, 8, 10)),
        Rotation = 35, Parent = backdrop,
    })
    local isGlass = (guiStyle == "LiquidGlass")
    local shell = ui("CanvasGroup", {
        Name = "GameLibrary", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -32, 1, -40), BackgroundColor3 = isGlass and Color3.fromRGB(16, 17, 24) or Color3.fromRGB(12, 12, 15),
        BackgroundTransparency = isGlass and 0.35 or 0,
        BorderSizePixel = 0, GroupTransparency = 1, Parent = backdrop,
    })
    corner(shell, 24)
    ui("UISizeConstraint", { MaxSize = Vector2.new(1180, 620), Parent = shell })
    ui("UIStroke", { Color = isGlass and Color3.fromRGB(80, 85, 105) or Color3.fromRGB(49, 49, 56), Transparency = isGlass and 0.25 or 0.4, Thickness = 1, Parent = shell })
    ui("TextLabel", {
        Name = "Brand", Position = UDim2.fromOffset(28, 24), Size = UDim2.new(1, -56, 0, 20),
        BackgroundTransparency = 1, Text = "SOLARA / 游戏库", TextSize = 11,
        Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(220, 220, 228),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = shell,
    })
    local title = ui("TextLabel", {
        Name = "Title", Position = UDim2.fromOffset(28, 54), Size = UDim2.new(1, -56, 0, 40),
        BackgroundTransparency = 1, Text = russian and "Выбери свою игру" or "Choose your game",
        TextSize = 30, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(244, 243, 250),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = shell,
    })
    ui("TextLabel", {
        Name = "Subtitle", Position = UDim2.fromOffset(28, 100), Size = UDim2.new(1, -56, 0, 38),
        BackgroundTransparency = 1,
        Text = russian and "Выбери карточку, чтобы открыть Solara." or "Select a card to open Solara.",
        TextWrapped = true, TextSize = 13, Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(144, 148, 167), TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Parent = shell,
    })
    local cards = ui("ScrollingFrame", {
        Name = "GameCards", Position = UDim2.fromOffset(24, 152), Size = UDim2.new(1, -48, 1, -200),
        BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(220, 220, 228),
        Active = true, Parent = shell,
    })
    ui("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6), Parent = cards })
    local grid = ui("UIGridLayout", {
        CellPadding = UDim2.fromOffset(16, 16), CellSize = UDim2.new(1 / 4, -16, 0, 326),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = cards,
    })
    ui("TextLabel", {
        Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 28, 1, -17),
        Size = UDim2.new(1, -56, 0, 16), BackgroundTransparency = 1,
        Text = russian and "04 РЕЖИМА  •  ОДИН КЛИЕНТ" or "04 MODES  •  ONE CLIENT",
        TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(103, 109, 130),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = shell,
    })

    local function selectGame(choice, scale)
        if not runtimeAlive or HUD.gameSelectionPending or HUD.selectedGame then return end
        HUD.gameSelectionPending = true
        if scale then
            tween(scale, { Scale = 0.94 }, 0.15, Enum.EasingStyle.Quad)
        end
        tween(shell, { GroupTransparency = 1 }, 0.2)
        task.delay(0.2, function()
            if not runtimeAlive or not gui.Parent then return end
            HUD.selectedGame = choice
            HUD.applyGameProfile()
            screenGui:SetAttribute("SelectedGame", choice.id)
            screenGui:SetAttribute("SelectedGameName", choice.name)
            gui:Destroy()
            HUD.gameSelectorGui = nil
            HUD.gameSelectionPending = false
            screenGui.Enabled = true
            HUD.notificationsReady = true
            toggleMenu(true)
        end)
    end

    for order, choice in ipairs(HUD.gameChoices) do
        local isUniversalChoice = (choice.id == "universal")
        local accentColor = isUniversalChoice and (COLORS.accent or choice.accent) or choice.accent
        local card = ui("TextButton", {
            Name = choice.id, LayoutOrder = order, BackgroundColor3 = Color3.fromRGB(22, 25, 35),
            BackgroundTransparency = isGlass and 0.28 or 0,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false, Selectable = true, Parent = cards,
        })
        corner(card, 17)
        local scale = ui("UIScale", { Scale = 1.0, Parent = card })
        local outline = ui("UIStroke", { Color = accentColor, Transparency = 0.8,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Parent = card })
        local cover = ui("Frame", {
            Name = "Cover", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 160),
            BackgroundColor3 = Color3.fromRGB(39, 40, 56), BorderSizePixel = 0,
            ClipsDescendants = true, Parent = card,
        })
        corner(cover, 11)
        local coverGrad = ui("UIGradient", { Color = ColorSequence.new(accentColor, Color3.fromRGB(26, 28, 43)),
            Rotation = 125, Parent = cover })
        local placeholder = ui("TextLabel", {
            Name = "Placeholder", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Text = choice.initials, TextSize = 44, Font = Enum.Font.GothamBlack,
            TextColor3 = Color3.fromRGB(255, 255, 255), TextTransparency = 0.22, Parent = cover,
        })
        local image = ui("ImageLabel", {
            Name = "GameImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Image = choice.image, ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = cover,
        })
        corner(image, 11)
        local gameName = ui("TextLabel", {
            Name = "GameName", Position = UDim2.fromOffset(16, 184), Size = UDim2.new(1, -32, 0, 60),
            BackgroundTransparency = 1, Text = choice.name, TextWrapped = true,
            TextSize = 19, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(240, 241, 248),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = card,
        })
        local action = ui("Frame", {
            Name = "SelectAction", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12),
            Size = UDim2.new(1, -24, 0, 42), BackgroundColor3 = accentColor,
            BackgroundTransparency = 0.9, BorderSizePixel = 0, Parent = card,
        })
        corner(action, 9)
        local actionLabel = ui("TextLabel", {
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
            Text = isUniversalChoice and (russian and "Выбрать режим   →" or "Select mode   →")
                or (russian and "Выбрать игру   →" or "Select game   →"),
            TextColor3 = accentColor,
            TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = action,
        })
        local function highlight(active)
            if not runtimeAlive or not card.Parent or HUD.gameSelectionPending then return end
            tween(scale, { Scale = active and 1.025 or 1.0 }, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            tween(outline, { Transparency = active and 0.12 or 0.8 }, 0.18)
            local targetBg = active and Color3.fromRGB(30, 33, 46) or Color3.fromRGB(22, 25, 35)
            tween(card, { BackgroundColor3 = targetBg, BackgroundTransparency = isGlass and (active and 0.15 or 0.28) or 0 }, 0.18)
            tween(action, { BackgroundTransparency = active and 0.72 or 0.9 }, 0.18)
        end
        card.MouseEnter:Connect(function() highlight(true) end)
        card.MouseLeave:Connect(function() highlight(false) end)
        card.SelectionGained:Connect(function() highlight(true) end)
        card.SelectionLost:Connect(function() highlight(false) end)

        card.InputBegan:Connect(function(input)
            if not runtimeAlive or not card.Parent or HUD.gameSelectionPending then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tween(scale, { Scale = 0.97 }, 0.12, Enum.EasingStyle.Quad)
            end
        end)
        card.InputEnded:Connect(function(input)
            if not runtimeAlive or not card.Parent or HUD.gameSelectionPending then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tween(scale, { Scale = 1.025 }, 0.15, Enum.EasingStyle.Quad)
            end
        end)

        card.Activated:Connect(function() selectGame(choice, scale) end)
    end

    HUD.refreshSelectorTheme = function()
        if not runtimeAlive or not HUD.gameSelectorGui or not cards.Parent then return end
        for _, child in ipairs(cards:GetChildren()) do
            if child:IsA("TextButton") and child.Name == "universal" then
                local out = child:FindFirstChildOfClass("UIStroke")
                if out then tween(out, { Color = COLORS.accent }, 0.35) end
                local cov = child:FindFirstChild("Cover")
                if cov then
                    local gr = cov:FindFirstChildOfClass("UIGradient")
                    if gr then gr.Color = ColorSequence.new(COLORS.accent, Color3.fromRGB(26, 28, 43)) end
                end
                local act = child:FindFirstChild("SelectAction")
                if act then
                    tween(act, { BackgroundColor3 = COLORS.accent }, 0.35)
                    local txt = act:FindFirstChildOfClass("TextLabel")
                    if txt then tween(txt, { TextColor3 = COLORS.accent }, 0.35) end
                end
            end
        end
    end

    local function resize()
        if not runtimeAlive or not cards.Parent then return end
        local width = cards.AbsoluteSize.X
        local columns = width >= 940 and 4 or (width >= 520 and 2 or 1)
        grid.CellSize = UDim2.new(1 / columns, -(14 + 16 * (columns - 1)) / columns, 0, 326)
        grid.FillDirectionMaxCells = columns
        title.TextSize = shell.AbsoluteSize.X < 420 and 23 or 30
    end
    local resizeConnection = cards:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    gui.Destroying:Connect(function()
        HUD.refreshSelectorTheme = nil
        resizeConnection:Disconnect()
    end)
    resize()
    tween(shell, { GroupTransparency = 0 }, 0.35)
end

registerRuntimeCleanup(function()
    if HUD.gameSelectorGui then
        HUD.gameSelectorGui:Destroy()
        HUD.gameSelectorGui = nil
    end
end)
-- GAME_SELECTION_END

----------------------------------------------------------------
-- ИНТЕГРАЦИЯ ЭКРАНА ЗАГРУЗКИ (SOLARA Loading Screen — 2026 Minimal)
----------------------------------------------------------------

function HUD.StartUnifiedLoading()
    local old = targetGuiContainer:FindFirstChild("SolaraLoadingScreen")
    if old then old:Destroy() end

    local loadScreenGui = Instance.new("ScreenGui")
    loadScreenGui.Name = "SolaraLoadingScreen"
    loadScreenGui.ResetOnSpawn = false
    loadScreenGui.IgnoreGuiInset = true
    loadScreenGui.DisplayOrder = 999
    loadScreenGui.Parent = targetGuiContainer
    registerRuntimeCleanup(function()
        if loadScreenGui.Parent then loadScreenGui:Destroy() end
    end)

    -- =================== ФОН: глубокий чёрный с едва заметным виньетированием ===================
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.Position = UDim2.fromScale(0, 0)
    background.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
    background.BorderSizePixel = 0
    background.ZIndex = 1
    background.Parent = loadScreenGui

    -- Тонкий радиальный градиент (виньетка) — мягкое свечение в центре
    local vignetteGlow = Instance.new("ImageLabel")
    vignetteGlow.Name = "VignetteGlow"
    vignetteGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    vignetteGlow.Position = UDim2.fromScale(0.5, 0.48)
    vignetteGlow.Size = UDim2.fromScale(0.7, 0.7)
    vignetteGlow.BackgroundTransparency = 1
    vignetteGlow.Image = "rbxassetid://5028857084"
    vignetteGlow.ImageColor3 = Color3.fromRGB(18, 18, 28)
    vignetteGlow.ImageTransparency = 0.5
    vignetteGlow.ScaleType = Enum.ScaleType.Stretch
    vignetteGlow.ZIndex = 2
    vignetteGlow.Parent = background

    -- Контейнер для эффектов (частицы)
    local effectFolder = Instance.new("Frame")
    effectFolder.Name = "Effects"
    effectFolder.Size = UDim2.fromScale(1, 1)
    effectFolder.BackgroundTransparency = 1
    effectFolder.ClipsDescendants = true
    effectFolder.ZIndex = 3
    effectFolder.Parent = background

    -- =================== ГЕОМЕТРИЧЕСКИЕ ПЛАВАЮЩИЕ ЧАСТИЦЫ ===================
    -- Тонкие линии и точки — парят медленно, создают глубину
    local particleFolder = Instance.new("Frame")
    particleFolder.Name = "GeoParticles"
    particleFolder.Size = UDim2.fromScale(1, 1)
    particleFolder.BackgroundTransparency = 1
    particleFolder.ClipsDescendants = true
    particleFolder.ZIndex = 3
    particleFolder.Parent = effectFolder

    local function spawnGeoParticle()
        local isLine = math.random() > 0.5
        local particle = Instance.new("Frame")
        particle.BorderSizePixel = 0
        particle.BackgroundTransparency = math.random(85, 96) / 100

        -- Цвет — белый/серебристый с едва заметным оттенком
        local brightness = math.random(60, 140)
        particle.BackgroundColor3 = Color3.fromRGB(brightness, brightness, brightness + math.random(0, 20))

        if isLine then
            -- Тонкая линия
            local length = math.random(20, 80)
            particle.Size = UDim2.fromOffset(length, 1)
            particle.Rotation = math.random(-30, 30)
        else
            -- Маленькая точка
            local sz = math.random(2, 4)
            particle.Size = UDim2.fromOffset(sz, sz)
            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(0, 999)
            dotCorner.Parent = particle
        end

        local startX = math.random(50, 950) / 1000
        local startY = math.random(50, 950) / 1000
        particle.Position = UDim2.fromScale(startX, startY)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.ZIndex = 1
        particle.Parent = particleFolder

        -- Очень медленный дрейф
        local duration = math.random(6000, 14000) / 1000
        local driftX = (math.random(-40, 40)) / 1000
        local driftY = (math.random(-40, 40)) / 1000

        TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = UDim2.fromScale(startX + driftX, startY + driftY),
            BackgroundTransparency = math.random(90, 98) / 100,
        }):Play()
    end

    -- Спавним начальный набор частиц
    for _ = 1, 18 do
        spawnGeoParticle()
    end

    -- =================== БЕЛЫЕ КАПЕЛЬКИ (дождь) ===================
    local dropletFolder = Instance.new("Frame")
    dropletFolder.Name = "Droplets"
    dropletFolder.Size = UDim2.fromScale(1, 1)
    dropletFolder.BackgroundTransparency = 1
    dropletFolder.ClipsDescendants = true
    dropletFolder.ZIndex = 4
    dropletFolder.Parent = background

    local function spawnDroplet()
        local droplet = Instance.new("Frame")
        droplet.BorderSizePixel = 0

        -- Размер: маленькие капли (ширина 2-3, высота 6-18) — вытянутые вертикально
        local w = math.random(2, 3)
        local h = math.random(6, 18)
        droplet.Size = UDim2.fromOffset(w, h)

        -- Цвет: чисто белый с лёгкой вариацией яркости
        local b = math.random(200, 255)
        droplet.BackgroundColor3 = Color3.fromRGB(b, b, b)
        droplet.BackgroundTransparency = math.random(60, 90) / 100

        -- Скругление
        local dropCorner = Instance.new("UICorner")
        dropCorner.CornerRadius = UDim.new(0, 999)
        dropCorner.Parent = droplet

        -- Старт: случайная позиция X, чуть выше экрана
        local startX = math.random(0, 1000) / 1000
        droplet.Position = UDim2.fromScale(startX, -0.05)
        droplet.AnchorPoint = Vector2.new(0.5, 0)
        droplet.ZIndex = 2
        droplet.Parent = dropletFolder

        -- Падение: различная скорость, лёгкий горизонтальный дрейф
        local fallDuration = math.random(2000, 5000) / 1000
        local driftX = math.random(-30, 30) / 1000

        TweenService:Create(droplet, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {
            Position = UDim2.fromScale(startX + driftX, 1.1),
            BackgroundTransparency = 1,
        }):Play()

        task.delay(fallDuration, function()
            if droplet.Parent then droplet:Destroy() end
        end)
    end

    -- Спавн капель непрерывно во время загрузки
    task.spawn(function()
        while runtimeAlive and loadScreenGui.Parent do
            spawnDroplet()
            task.wait(math.random(80, 200) / 1000)
        end
    end)

    -- =================== ЦЕНТРАЛЬНЫЙ КОНТЕЙНЕР ===================
    local centerGroup = Instance.new("Frame")
    centerGroup.Name = "CenterGroup"
    centerGroup.AnchorPoint = Vector2.new(0.5, 0.5)
    centerGroup.Position = UDim2.fromScale(0.5, 0.47)
    centerGroup.Size = UDim2.fromOffset(400, 120)
    centerGroup.BackgroundTransparency = 1
    centerGroup.ZIndex = 10
    centerGroup.Parent = background

    -- =================== LETTER-BY-LETTER ТЕКСТ SOLARA ===================
    local letters = {}
    local titleText = MENU_TITLE
    local totalWidth = #titleText * 42 -- примерная ширина буквы
    local startOffsetX = -totalWidth / 2 + 21

    for i = 1, #titleText do
        local char = titleText:sub(i, i)
        local letterLabel = Instance.new("TextLabel")
        letterLabel.Name = "Letter_" .. i
        letterLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        letterLabel.Position = UDim2.new(0.5, startOffsetX + (i - 1) * 42, 0.5, 0)
        letterLabel.Size = UDim2.fromOffset(44, 70)
        letterLabel.BackgroundTransparency = 1
        letterLabel.Text = char
        letterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        letterLabel.TextTransparency = 1
        letterLabel.Font = Enum.Font.GothamSemibold
        letterLabel.TextSize = 52
        letterLabel.ZIndex = 12
        letterLabel.Parent = centerGroup
        letters[i] = letterLabel
    end

    -- Нежное свечение за текстом (дышащее)
    local breathGlow = Instance.new("Frame")
    breathGlow.Name = "BreathGlow"
    breathGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    breathGlow.Position = UDim2.fromScale(0.5, 0.5)
    breathGlow.Size = UDim2.fromOffset(320, 6)
    breathGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    breathGlow.BackgroundTransparency = 1
    breathGlow.BorderSizePixel = 0
    breathGlow.ZIndex = 8
    breathGlow.Parent = centerGroup
    local breathCorner = Instance.new("UICorner")
    breathCorner.CornerRadius = UDim.new(0, 999)
    breathCorner.Parent = breathGlow

    -- =================== LETTER REVEAL ANIMATION ===================
    -- Каждая буква появляется с задержкой: поднимается снизу + fade in
    for i, label in ipairs(letters) do
        local originalPos = label.Position
        label.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset + 20)

        task.delay(0.3 + (i - 1) * 0.12, function()
            if not runtimeAlive or not label.Parent then return end
            TweenService:Create(label, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                TextTransparency = 0,
                Position = originalPos,
            }):Play()
        end)
    end

    -- Свечение появляется после всех букв
    task.delay(0.3 + #letters * 0.12 + 0.2, function()
        if not runtimeAlive or not breathGlow.Parent then return end
        TweenService:Create(breathGlow, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.85,
        }):Play()

        -- Дышащая пульсация свечения
        task.delay(0.8, function()
            if not runtimeAlive or not breathGlow.Parent then return end
            TweenService:Create(breathGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundTransparency = 0.95,
                Size = UDim2.fromOffset(340, 8),
            }):Play()
        end)
    end)

    -- =================== УЛЬТРАТОНКИЙ ПРОГРЕСС (горизонтальная линия) ===================
    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.AnchorPoint = Vector2.new(0.5, 0)
    progressTrack.Position = UDim2.new(0.5, 0, 0.5, 52)
    progressTrack.Size = UDim2.fromOffset(240, 1)
    progressTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressTrack.BackgroundTransparency = 0.5
    progressTrack.BorderSizePixel = 0
    progressTrack.ZIndex = 10
    progressTrack.Parent = centerGroup
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 999)
    trackCorner.Parent = progressTrack

    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.fromScale(0, 1)
    progressFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressFill.BackgroundTransparency = 0.15
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 11
    progressFill.Parent = progressTrack
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 999)
    fillCorner.Parent = progressFill

    -- Анимация прогресса — плавные шаги
    task.spawn(function()
        local progress = 0
        task.wait(0.8) -- ждём появления букв
        while runtimeAlive and loadScreenGui.Parent and progress < 0.92 do
            local step = math.random(3, 10) / 100
            progress = math.min(progress + step, 0.92)
            TweenService:Create(progressFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(progress, 1),
            }):Play()
            task.wait(math.random(300, 700) / 1000)
        end
    end)

    -- =================== МИНИ-ТЕКСТ СТАТУСА ===================
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.AnchorPoint = Vector2.new(0.5, 0)
    statusLabel.Position = UDim2.new(0.5, 0, 0.5, 62)
    statusLabel.Size = UDim2.fromOffset(240, 18)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(90, 90, 105)
    statusLabel.TextTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.ZIndex = 10
    statusLabel.Parent = centerGroup

    -- Статус появляется с задержкой
    task.delay(1.4, function()
        if not runtimeAlive or not statusLabel.Parent then return end
        TweenService:Create(statusLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            TextTransparency = 0,
        }):Play()
    end)

    local statusMessages = { "initializing", "loading modules", "preparing interface", "almost ready" }
    local msgIdx = 0
    task.spawn(function()
        task.wait(1.4)
        while runtimeAlive and loadScreenGui.Parent do
            msgIdx = (msgIdx % #statusMessages) + 1
            -- Плавная смена текста: fade out → сменить → fade in
            TweenService:Create(statusLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                TextTransparency = 1,
            }):Play()
            task.wait(0.2)
            if not runtimeAlive or not statusLabel.Parent then break end
            statusLabel.Text = statusMessages[msgIdx]
            TweenService:Create(statusLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                TextTransparency = 0,
            }):Play()
            task.wait(1.2)
        end
    end)

    -- =================== КОПИРАЙТ ВНИЗУ ===================
    local copyrightLabel = Instance.new("TextLabel")
    copyrightLabel.Name = "Copyright"
    copyrightLabel.AnchorPoint = Vector2.new(0.5, 1)
    copyrightLabel.Position = UDim2.new(0.5, 0, 1, -24)
    copyrightLabel.Size = UDim2.fromOffset(300, 14)
    copyrightLabel.BackgroundTransparency = 1
    copyrightLabel.Text = "2026"
    copyrightLabel.TextColor3 = Color3.fromRGB(50, 50, 58)
    copyrightLabel.TextTransparency = 1
    copyrightLabel.Font = Enum.Font.Gotham
    copyrightLabel.TextSize = 10
    copyrightLabel.ZIndex = 10
    copyrightLabel.Parent = background

    task.delay(2, function()
        if not runtimeAlive or not copyrightLabel.Parent then return end
        TweenService:Create(copyrightLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
            TextTransparency = 0,
        }):Play()
    end)

    -- =================== ОЖИДАНИЕ И ВЫХОД ===================
    task.wait(5)
    if not runtimeAlive or not loadScreenGui.Parent then return end

    -- Финальный прогресс: заполняем до 100%
    TweenService:Create(progressFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(1, 1),
    }):Play()
    task.wait(0.5)

    -- Фаза 1: буквы разлетаются вверх, fade out
    for i, label in ipairs(letters) do
        task.delay((i - 1) * 0.04, function()
            TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                TextTransparency = 1,
                Position = UDim2.new(label.Position.X.Scale, label.Position.X.Offset, label.Position.Y.Scale, label.Position.Y.Offset - 30),
            }):Play()
        end)
    end

    -- Всё остальное fade out
    local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(breathGlow, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(progressTrack, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(progressFill, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(statusLabel, fadeInfo, {TextTransparency = 1}):Play()
    TweenService:Create(copyrightLabel, fadeInfo, {TextTransparency = 1}):Play()
    TweenService:Create(vignetteGlow, fadeInfo, {ImageTransparency = 1}):Play()

    -- Частицы fade out
    for _, particle in ipairs(particleFolder:GetChildren()) do
        TweenService:Create(particle, fadeInfo, {BackgroundTransparency = 1}):Play()
    end

    -- Капельки fade out
    for _, drop in ipairs(dropletFolder:GetChildren()) do
        TweenService:Create(drop, fadeInfo, {BackgroundTransparency = 1}):Play()
    end

    task.wait(0.4)

    -- Фаза 2: фон уходит
    TweenService:Create(background, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
    }):Play()

    task.wait(0.5)
    if not runtimeAlive or not loadScreenGui.Parent then return end
    loadScreenGui:Destroy()
    HUD.showGameSelection()
end

task.spawn(function()
    if not runtimeAlive then return end
    screenGui.Enabled = false
    window.Visible = false
    menuOpen = false
    if themeFabButton then themeFabButton.Visible = false end

    -- 1. СЕРВЕРНАЯ ПРОВЕРКА СЕССИИ И СТАТУСА БАНА INSTALLATION_ID ДО ЗАПУСКА КЛИЕНТА
    local sessionResult = nil
    local okSession, resSession = pcall(HUD.Telemetry.StartSession)
    if okSession and type(resSession) == "table" then
        sessionResult = resSession
    end

    if sessionResult and (sessionResult.banned == true or sessionResult.allowed == false) then
        -- Установка заблокирована: останавливаем дальнейшую инициализацию
        cleanupRuntime()
        HUD.Telemetry.ShowBannedScreen(sessionResult.message)
        return
    end

    -- 2. Если запуск разрешён (или оффлайн режим) — запускаем пульс heartbeat и интерфейс
    HUD.Telemetry.StartHeartbeatLoop()

    local ok, err = pcall(HUD.StartUnifiedLoading)
    if not ok and runtimeAlive then
        warn("Solara loading screen failed:", err)
        local oldLoading = targetGuiContainer:FindFirstChild("SolaraLoadingScreen")
        if oldLoading then oldLoading:Destroy() end
        HUD.showGameSelection()
    end
end)
    
