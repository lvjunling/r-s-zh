--[[
 ██╗   ██╗
 ██║   ██║   VAN THANH EXECUTOR
 ╚██╗ ██╔╝   Steal An Egg V4
  ╚████╔╝    Anti-Cheat · Hook · Bypass · Farm
   ╚═══╝     
]]

----------------------------------------------------------------
-- EXECUTOR COMPAT LAYER
----------------------------------------------------------------

local ENV = getgenv and getgenv() or _G
local DELTA_SAFE_MODE = true
print("[VT-DELTA] 正在启动兼容模式……")

-- Delta 在游戏刚进入时可能比 LocalPlayer/CoreGui 更早执行自动运行脚本。
if not game:IsLoaded() then
    game.Loaded:Wait()
end

if ENV.__VanThanhV4 then
    local existingUI = false
    pcall(function()
        local parent
        if typeof(gethui) == "function" then parent = gethui() end
        parent = parent or game:GetService("CoreGui")
        existingUI = parent:FindFirstChild("StealEggHubV4") ~= nil
            and parent:FindFirstChild("VanThanhBadge") ~= nil
    end)
    if existingUI then
        warn("[VT-V4] 脚本已经加载，本次跳过。")
        return
    end
    -- 上一次若在 UI 创建前报错，会遗留标记；Delta 版自动清除后重新启动。
    ENV.__VanThanhV4 = nil
    ENV.__VanThanhAC = nil
    ENV.__StealEggV4 = nil
end
ENV.__VanThanhV4   = true
ENV.__VanThanhAC   = true
ENV.__StealEggV4   = true

local function safeRef(value)
    if typeof(cloneref) == "function" then
        local ok, result = pcall(cloneref, value)
        if ok and result then return result end
    end
    return value
end

local function safeClosure(fn)
    if typeof(newcclosure) == "function" then
        local ok, result = pcall(newcclosure, fn)
        if ok and result then return result end
    end
    return fn
end

local safeHook = (not DELTA_SAFE_MODE and typeof(hookfunction) == "function")
    and hookfunction or nil

local hookMeta = (not DELTA_SAFE_MODE and typeof(hookmetamethod) == "function")
    and hookmetamethod or nil

local isLClosure = (typeof(islclosure) == "function")
    and islclosure or function() return false end

local function getUIParent()
    -- Delta 优先使用 gethui；它比直接写入 CoreGui 更稳定。
    if typeof(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    if syn and syn.protect_gui then
        local ok, gui = pcall(function()
            local g = Instance.new("ScreenGui")
            syn.protect_gui(g)
            g.Parent = game:GetService("CoreGui")
            return g
        end)
        if ok then return gui end
    end
    local okCore, core = pcall(game.GetService, game, "CoreGui")
    if okCore and core then return safeRef(core) end

    local players = game:GetService("Players")
    local player = players.LocalPlayer or players.PlayerAdded:Wait()
    return player:WaitForChild("PlayerGui")
end

local function firePrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    elseif typeof(fireclickdetector) == "function" then
        local cd = prompt.Parent
            and prompt.Parent:FindFirstChildOfClass("ClickDetector")
        if cd then pcall(fireclickdetector, cd) end
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.05)
            prompt:InputHoldEnd()
        end)
    end
end

local function toClipboard(text)
    if setclipboard then pcall(setclipboard, text)
    elseif syn and syn.write_clipboard then pcall(syn.write_clipboard, text)
    elseif Clipboard then pcall(function() Clipboard.set(text) end)
    end
end

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local Players          = safeRef(game:GetService("Players"))
local Workspace        = safeRef(game:GetService("Workspace"))
local RunService       = safeRef(game:GetService("RunService"))
local UserInputService = safeRef(game:GetService("UserInputService"))
local VirtualInputManager
pcall(function()
    VirtualInputManager = safeRef(game:GetService("VirtualInputManager"))
end)
local TeleportService  = safeRef(game:GetService("TeleportService"))
local HttpService      = safeRef(game:GetService("HttpService"))
local ScriptContext    = safeRef(game:GetService("ScriptContext"))
local CoreGui          = safeRef(game:GetService("CoreGui"))
local LocalPlayer      = Players.LocalPlayer or Players.PlayerAdded:Wait()

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local CONFIG = {
    CHECK_INTERVAL   = 0.35,
    TREADMILL_CFRAME = CFrame.new(0, 10, 0),
    WATERFALL_CFRAME = CFrame.new(150, 5, -800),
    MOVE_MODE        = "ZigZag",
    ZIGZAG_OFFSET    = 6,
    STEP_SIZE        = 18,

    RARITY_PRIORITY = { "Secret","Eternal","Divine","Light","Dark","Unknown" },
    TARGET_RARITIES = {
        Secret  = true,
        Eternal = true,
        Divine  = true,
        Light   = true,
        Dark    = true,
        Unknown = true,
    },

    EXTRA_EGG_PATTERNS = {},

    ANTI = {
        AFK_INTERVAL     = 55,
        RECONNECT        = true,
        PROPERTY_GUARD   = true,
        HUMANOID_RESTORE = true,
        WALK_SPEED       = 16,
        JUMP_POWER       = 50,
        TELEPORT_DELAY   = 0.07,
    },

    BOSS = {
        SCAN_NAMES   = {"Boss","Events","EggBoss","GiantEgg"},
        ATTACK_DELAY = 0.3,
        MAX_RETRIES  = 5,
    },

    SESSION = { START_TICK = tick() },
}

local RARITY_ZH = {
    Secret = "秘密",
    Eternal = "永恒",
    Divine = "神圣",
    Light = "光明",
    Dark = "黑暗",
    Unknown = "未知",
}

----------------------------------------------------------------
-- FLAGS
----------------------------------------------------------------

local FLAGS = {
    AutoFarm        = false,
    AutoBoss        = false,
    ReturnTreadmill = true,
    Running         = true,
    EggsCollected   = 0,
    BossAttacks     = 0,
    EggsPerMinute   = 0,
    LastEggTick     = tick(),
    CurrentStatus   = "待机",
    NotifyOnRare    = true,
}

----------------------------------------------------------------
-- CONNECTION POOL
----------------------------------------------------------------

local Connections = {}

local function addConn(c)
    table.insert(Connections, c)
    return c
end

local function cleanupAll()
    FLAGS.Running    = false
    ENV.__VanThanhV4 = nil
    ENV.__VanThanhAC = nil
    ENV.__StealEggV4 = nil
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}
end

----------------------------------------------------------------
-- INTERNAL LOG
----------------------------------------------------------------

local VT_LOG = {}
local function vtLog(tag, msg)
    local entry = string.format("[VT][%s] %s | %.2fs", tag, msg, tick())
    table.insert(VT_LOG, entry)
    if ENV.__VT_DEV then print(entry) end
end

----------------------------------------------------------------
-- ╔══════════════════════════════════════════╗
-- ║      VAN THANH ANTI-CHEAT BYPASS         ║
-- ╚══════════════════════════════════════════╝
----------------------------------------------------------------

-- [1] REMOTE SPY SHIELD
-- Intercept FireServer/InvokeServer via __namecall hook
-- Drops any remote in BlockedRemotes silently

local VT_RemoteLog     = {}
local VT_BlockedRemotes = {
    -- add game-specific anti-cheat remote names here:
    -- ["CheatDetect"]   = true,
    -- ["IntegrityPing"] = true,
}

local _namecall_orig
if hookMeta then
    _namecall_orig = hookMeta(game, "__namecall", safeClosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if method == "FireServer"
            or method == "InvokeServer"
            or method == "FireAllClients" then

            local name = (typeof(self) ~= "nil" and self.Name) or "unknown"
            if VT_BlockedRemotes[name] then
                vtLog("REMOTE_BLOCK", "Dropped: " .. name)
                return
            end
            table.insert(VT_RemoteLog, {
                name=name, method=method, t=tick()
            })
        end
        return _namecall_orig(self, ...)
    end))
    vtLog("HOOK", "__namecall → remote shield active")
end

-- [2] DEBUG.INFO SPOOFER
-- Masks executor stack source from game anti-cheat scanners

if debug and typeof(debug.info) == "function" and safeHook then
    local real_di = debug.info
    if isLClosure(debug.info) then
        safeHook(debug.info, safeClosure(function(level, opts)
            local ok, src = pcall(real_di, level, "s")
            if ok and src and type(opts) == "string"
                and string.find(opts, "s")
                and string.find(src, "LocalScript") == nil
                and string.find(src, "Script") == nil then
                return (real_di(level, opts)):gsub(src, "LocalScript")
            end
            return real_di(level, opts)
        end))
        vtLog("HOOK", "debug.info spoofed")
    end
end

-- [3] SCRIPT IDENTITY MASKER
-- Spoof executor identity level to CoreScript (7)

if typeof(getscriptidentity) == "function" and safeHook then
    local real_gsi = getscriptidentity
    safeHook(real_gsi, safeClosure(function(...)
        return 7
    end))
    vtLog("HOOK", "getscriptidentity masked → 7")
end

if typeof(identifyexecutor) == "function" and safeHook then
    local real_ie = identifyexecutor
    safeHook(real_ie, safeClosure(function()
        return "Roblox", "0.0.0"
    end))
    vtLog("HOOK", "identifyexecutor spoofed → vanilla")
end

-- [4] HTTPSERVICE FINGERPRINT BLOCK
-- Intercept outgoing HTTP calls containing anti-cheat keywords

local HTTP_BLOCKLIST = {
    "cheatdetect","anticheat","exploit","ban",
    "report","telemetry","integrity","flagged",
}

if safeHook then
    pcall(function()
        if isLClosure(HttpService.GetAsync) then
            local real_get = HttpService.GetAsync
            safeHook(real_get, safeClosure(function(self, url, ...)
                for _, kw in ipairs(HTTP_BLOCKLIST) do
                    if string.find(string.lower(url or ""), kw) then
                        vtLog("HTTP_BLOCK", "GET blocked: " .. url)
                        return "{}"
                    end
                end
                return real_get(self, url, ...)
            end))
            vtLog("HOOK", "HttpService.GetAsync filtered")
        end
    end)

    pcall(function()
        if isLClosure(HttpService.PostAsync) then
            local real_post = HttpService.PostAsync
            safeHook(real_post, safeClosure(function(self, url, body, ...)
                for _, kw in ipairs(HTTP_BLOCKLIST) do
                    if string.find(string.lower(url or ""), kw) then
                        vtLog("HTTP_BLOCK", "POST blocked: " .. url)
                        return "{}"
                    end
                end
                return real_post(self, url, body, ...)
            end))
            vtLog("HOOK", "HttpService.PostAsync filtered")
        end
    end)
end

-- [5] KICK BYPASS + AUTO RECONNECT
-- Null out LocalPlayer:Kick(), intercept game:Shutdown()
-- Fallback: reconnect via TeleportService on real kick

local function doReconnect()
    vtLog("RECONNECT", "Reconnecting to " .. tostring(game.PlaceId))
    task.wait(2.5)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

if safeHook then
    pcall(function()
        if isLClosure(LocalPlayer.Kick) then
            safeHook(LocalPlayer.Kick, safeClosure(function(self, msg)
                vtLog("KICK_BLOCK", "Intercepted: " .. (msg or "no reason"))
                -- swallow the kick
            end))
            vtLog("HOOK", "LocalPlayer:Kick() nulled")
        end
    end)

    pcall(function()
        if isLClosure(game.Shutdown) then
            safeHook(game.Shutdown, safeClosure(function(self)
                vtLog("SHUTDOWN_BLOCK", "game:Shutdown() intercepted")
                doReconnect()
            end))
            vtLog("HOOK", "game:Shutdown() intercepted")
        end
    end)
end

-- Player.Kicked 并不是所有 Roblox/Delta 版本都公开的事件。
-- 原版本在这里直接索引会中止整个脚本，表现为“加载后没有反应”。
pcall(function()
    local kickedSignal = LocalPlayer.Kicked
    if kickedSignal and typeof(kickedSignal.Connect) == "function" then
        addConn(kickedSignal:Connect(safeClosure(function(reason)
            vtLog("KICKED_EVENT", "Reason: " .. (reason or "nil"))
            doReconnect()
        end)))
    end
end)

-- [6] HUMANOID PROPERTY SPOOF VIA __INDEX
-- If game scans hum.WalkSpeed via __index meta, return vanilla value

if hookMeta then
    pcall(function()
        local char = LocalPlayer.Character
            or LocalPlayer.CharacterAdded:Wait()
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local _hum_index = hookMeta(hum, "__index", safeClosure(function(self, key)
            if key == "WalkSpeed" then return CONFIG.ANTI.WALK_SPEED end
            if key == "JumpPower" then return CONFIG.ANTI.JUMP_POWER end
            return _hum_index(self, key)
        end))
        vtLog("HOOK", "Humanoid __index spoofed")
    end)
end

-- [7] WORKSPACE GRAVITY GUARD
-- Block games that set Gravity=0 to detect fly/noclip

if hookMeta then
    pcall(function()
        local ws = game:GetService("Workspace")
        local real_grav = ws.Gravity
        local _ws_ni = hookMeta(ws, "__newindex", safeClosure(function(self, key, value)
            if key == "Gravity" then
                vtLog("GRAVITY_GUARD", "Gravity write blocked: " .. tostring(value))
                return _ws_ni(self, key, real_grav)
            end
            return _ws_ni(self, key, value)
        end))
        vtLog("HOOK", "Workspace.Gravity guarded")
    end)
end

-- [8] SCRIPT CONTEXT ERROR SINK
-- Suppress executor-level error stack leaks

pcall(function()
    addConn(ScriptContext.Error:Connect(safeClosure(function(msg, trace, script)
        if script == nil then
            vtLog("ERROR_SINK", "Suppressed: " .. tostring(msg))
        end
    end)))
    vtLog("HOOK", "ScriptContext.Error sink active")
end)

-- [9] ENVIRONMENT FINGERPRINT WIPE
-- Remove executor-identifying keys from getgenv after boot

task.delay(1.5, safeClosure(function()
    local DIRTY_KEYS = {
        "SYNAPSE_LOADED","KRNL_LOADED","FLUXUS_LOADED",
        "SCRIPTWARE_LOADED","OXYGEN_LOADED","WAVE_LOADED",
        "EVON_LOADED","ARCEUS_LOADED","CODEX_LOADED",
    }
    local g = getgenv and getgenv() or _G
    for _, key in ipairs(DIRTY_KEYS) do
        pcall(function() g[key] = nil end)
    end
    vtLog("ENV_CLEAN", "Executor fingerprint keys wiped")
end))

-- [10] RUNTIME INTEGRITY LOOP
-- Re-verify and re-apply critical hooks every 30s
-- Guards against game scripts restoring hooked functions

task.spawn(safeClosure(function()
    while ENV.__VanThanhAC do
        task.wait(30)
        pcall(function()
            if safeHook and isLClosure(LocalPlayer.Kick) then
                safeHook(LocalPlayer.Kick, safeClosure(function(self, msg)
                    vtLog("KICK_REBLOCK", "Re-intercepted: " .. (msg or ""))
                end))
            end
        end)
        vtLog("INTEGRITY", "Hook integrity sweep done")
    end
end))

vtLog("INIT", "Van Thanh bypass layer fully loaded — " .. #VT_LOG .. " hooks")
print("[VAN THANH] Anti-cheat bypass active")

----------------------------------------------------------------
-- ╔══════════════════════════════════════════╗
-- ║         ANTI-AFK                         ║
-- ╚══════════════════════════════════════════╝
----------------------------------------------------------------

task.spawn(safeClosure(function()
    while FLAGS.Running do
        task.wait(CONFIG.ANTI.AFK_INTERVAL)
        if not FLAGS.Running then break end
        if VirtualInputManager then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            end)
        end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump = true end
        end)
    end
end))

----------------------------------------------------------------
-- PROPERTY GUARD (WalkSpeed / JumpPower)
----------------------------------------------------------------

if CONFIG.ANTI.PROPERTY_GUARD then
    local function guardHumanoid(hum)
        if not hum then return end

        addConn(hum:GetPropertyChangedSignal("WalkSpeed"):Connect(
            safeClosure(function()
                task.defer(function()
                    pcall(function()
                        if hum.WalkSpeed ~= CONFIG.ANTI.WALK_SPEED then
                            hum.WalkSpeed = CONFIG.ANTI.WALK_SPEED
                        end
                    end)
                end)
            end)
        ))

        addConn(hum:GetPropertyChangedSignal("JumpPower"):Connect(
            safeClosure(function()
                task.defer(function()
                    pcall(function()
                        if hum.JumpPower ~= CONFIG.ANTI.JUMP_POWER then
                            hum.JumpPower = CONFIG.ANTI.JUMP_POWER
                        end
                    end)
                end)
            end)
        ))
    end

    pcall(function()
        local char = LocalPlayer.Character
        if char then
            guardHumanoid(char:FindFirstChildOfClass("Humanoid"))
        end
    end)

    addConn(LocalPlayer.CharacterAdded:Connect(
        safeClosure(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            guardHumanoid(hum)
            if CONFIG.ANTI.HUMANOID_RESTORE then
                task.wait(0.2)
                pcall(function()
                    hum.WalkSpeed = CONFIG.ANTI.WALK_SPEED
                    hum.JumpPower = CONFIG.ANTI.JUMP_POWER
                end)
            end
        end)
    ))
end

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

----------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------

local function moveTarget(targetCFrame)
    local root = getRoot()
    if not root then return end

    if CONFIG.MOVE_MODE == "Direct" then
        root.CFrame = targetCFrame
        task.wait(CONFIG.ANTI.TELEPORT_DELAY)
        return
    end

    local startPos = root.Position
    local endPos   = targetCFrame.Position
    local diff     = endPos - startPos
    local dist     = diff.Magnitude

    if dist < 1 then
        root.CFrame = targetCFrame
        return
    end

    local steps = math.clamp(math.floor(dist / 15), 2, 12)
    local dir   = diff.Unit
    local right = dir:Cross(Vector3.new(0,1,0))

    if right.Magnitude < 0.01 then
        right = Vector3.new(1,0,0)
    else
        right = right.Unit
    end

    for i = 1, steps do
        if not FLAGS.Running then break end
        local alpha  = i / steps
        local pos    = startPos:Lerp(endPos, alpha)
        local offset = (CONFIG.MOVE_MODE == "ZigZag")
            and ((i % 2 == 0) and CONFIG.ZIGZAG_OFFSET or -CONFIG.ZIGZAG_OFFSET)
            or 0
        root.CFrame = CFrame.new(pos + right * offset)
        task.wait(CONFIG.ANTI.TELEPORT_DELAY)
    end

    root.CFrame = targetCFrame
end

----------------------------------------------------------------
-- STATUS
----------------------------------------------------------------

local StatusBox

local function updateStatus(text)
    FLAGS.CurrentStatus = text
    if StatusBox then
        StatusBox.Text = "  状态：" .. text
    end
end

----------------------------------------------------------------
-- EGG SCANNER
----------------------------------------------------------------

local function getRarity(obj)
    local attr = obj:GetAttribute("Rarity")
        or obj:GetAttribute("RarityName")
        or obj:GetAttribute("EggRarity")
    if attr then return attr end

    local name = string.lower(obj.Name)
    for _, rarity in ipairs(CONFIG.RARITY_PRIORITY) do
        if string.find(name, string.lower(rarity)) then
            return rarity
        end
    end
    return nil
end

local function isEggCandidate(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return false end

    local lowerName = string.lower(obj.Name)
    if string.find(lowerName, "hatch") then return false end
    if obj:GetAttribute("EggUid") or obj:GetAttribute("toolUidAttribute") then
        return true
    end
    if string.find(lowerName, "egg") then return true end

    for _, pat in ipairs(CONFIG.EXTRA_EGG_PATTERNS) do
        if string.find(lowerName, string.lower(pat)) then return true end
    end

    return obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
        and (obj:GetAttribute("Rarity") ~= nil
            or obj:GetAttribute("RarityName") ~= nil
            or obj:GetAttribute("EggRarity") ~= nil)
end

local function getObjectPosition(obj)
    if obj:IsA("Model") then
        local ok, pivot = pcall(obj.GetPivot, obj)
        return ok and pivot.Position or nil
    end
    return obj.Position
end

local function findPriorityEgg()
    local root = getRoot()
    if not root then return nil end

    local bestEgg      = nil
    local bestPriority = math.huge
    local bestDistance = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isEggCandidate(obj) then
            -- 部分版本的鸡蛋没有稀有度属性；仍将其作为最低优先级目标。
            local rarity = getRarity(obj) or "Unknown"
            if CONFIG.TARGET_RARITIES[rarity] == nil then rarity = "Unknown" end
            if not CONFIG.TARGET_RARITIES[rarity] then continue end

            local priority = math.huge
            for i, r in ipairs(CONFIG.RARITY_PRIORITY) do
                if r == rarity then priority = i break end
            end

            local pos = getObjectPosition(obj)
            if not pos then continue end

            local dist = (root.Position - pos).Magnitude

            if priority < bestPriority
                or (priority == bestPriority and dist < bestDistance) then
                bestPriority = priority
                bestDistance = dist
                bestEgg      = obj
            end
        end
    end

    return bestEgg
end

----------------------------------------------------------------
-- TREADMILL
----------------------------------------------------------------

local function goToTreadmill()
    updateStatus("正在前往跑步机……")
    moveTarget(CONFIG.TREADMILL_CFRAME)
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent then
            local n = string.lower(prompt.Parent.Name)
            if string.find(n, "treadmill") then
                firePrompt(prompt)
                break
            end
        end
    end
end

----------------------------------------------------------------
-- COLLECT EGG
----------------------------------------------------------------

local function collectEgg(eggObj)
    if not eggObj or not eggObj.Parent then return false end

    local rarity = getRarity(eggObj) or "?"
    updateStatus("正在拾取 " .. (RARITY_ZH[rarity] or rarity) .. "：" .. eggObj.Name)

    local okTarget, targetCF = pcall(function()
        return eggObj:IsA("Model") and eggObj:GetPivot() or eggObj.CFrame
    end)
    if not okTarget or not targetCF then
        updateStatus("鸡蛋位置已失效，重新扫描中……")
        return false
    end

    moveTarget(targetCF + Vector3.new(0, 3, 0))
    task.wait(0.15)

    local prompt = eggObj:FindFirstChildOfClass("ProximityPrompt")
    if not prompt and eggObj.Parent then
        prompt = eggObj.Parent:FindFirstChildOfClass("ProximityPrompt")
    end
    if not prompt then
        for _, child in ipairs(eggObj:GetDescendants()) do
            if child:IsA("ProximityPrompt") then
                prompt = child
                break
            end
        end
    end

    if prompt then
        -- 临时放宽交互条件，并进行短间隔重试，提高移动端和高延迟环境的成功率。
        pcall(function()
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 30)
            prompt.HoldDuration = 0
        end)

        for attempt = 1, 3 do
            if not prompt.Parent or not eggObj.Parent then break end
            firePrompt(prompt)
            task.wait(0.12 + attempt * 0.04)
        end

        FLAGS.EggsCollected += 1

        -- EPM tracking
        local now  = tick()
        local elapsed = now - CONFIG.SESSION.START_TICK
        FLAGS.EggsPerMinute = math.floor(
            FLAGS.EggsCollected / math.max(elapsed / 60, 0.01)
        )

        -- notify on rare
        if FLAGS.NotifyOnRare and
            (rarity == "Secret" or rarity == "Eternal") then
            vtLog("RARE", "Collected " .. rarity .. " egg!")
        end
        return true
    end

    updateStatus("未找到鸡蛋交互按钮，重新扫描中……")
    return false
end

----------------------------------------------------------------
-- BOSS HANDLER (multi-scan + retry)
----------------------------------------------------------------

local function handleBoss()
    updateStatus("正在攻击首领……")

    local bossFolder = nil
    for _, name in ipairs(CONFIG.BOSS.SCAN_NAMES) do
        bossFolder = Workspace:FindFirstChild(name)
        if bossFolder then break end
    end

    if not bossFolder then
        updateStatus("未找到首领")
        return
    end

    local boss = bossFolder:FindFirstChildOfClass("Model")
    if not boss then
        updateStatus("未找到首领模型")
        return
    end

    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return end

    moveTarget(bossRoot.CFrame + Vector3.new(0, 5, -8))
    task.wait(CONFIG.BOSS.ATTACK_DELAY)

    local char = LocalPlayer.Character
    if not char then return end

    -- try all tools in backpack
    local tried = false
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            pcall(function() item:Activate() end)
            tried = true
        end
    end

    -- fallback: check backpack
    if not tried then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") then
                    item.Parent = char
                    task.wait(0.05)
                    pcall(function() item:Activate() end)
                end
            end
        end
    end

    -- scan for ClickDetectors on boss
    for _, desc in ipairs(boss:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            pcall(function()
                if typeof(fireclickdetector) == "function" then
                    fireclickdetector(desc)
                end
            end)
        end
        if desc:IsA("ProximityPrompt") then
            firePrompt(desc)
        end
    end

    FLAGS.BossAttacks += 1
    updateStatus("已攻击首领，次数：" .. FLAGS.BossAttacks)
end

----------------------------------------------------------------
-- CLEAN OLD UI
----------------------------------------------------------------

local UIParent = getUIParent()

pcall(function()
    local old = UIParent:FindFirstChild("StealEggHubV3")
    if old then old:Destroy() end
    local old4 = UIParent:FindFirstChild("StealEggHubV4")
    if old4 then old4:Destroy() end
    local oldBadge = UIParent:FindFirstChild("VanThanhBadge")
    if oldBadge then oldBadge:Destroy() end
end)

----------------------------------------------------------------
-- UI BUILD
----------------------------------------------------------------

local function create(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    obj.Parent = parent
    return obj
end

local ScreenGui = create("ScreenGui", {
    Name           = "StealEggHubV4",
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
    DisplayOrder   = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, UIParent)

if syn and syn.protect_gui then
    pcall(syn.protect_gui, ScreenGui)
end

local MainFrame = create("Frame", {
    Name              = "MainFrame",
    Size              = UDim2.new(0, 640, 0, 450),
    AnchorPoint       = Vector2.new(0.5, 0.5),
    Position          = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3  = Color3.fromRGB(13, 13, 18),
    BorderSizePixel   = 0,
    Active            = true,
    Draggable         = true,
}, ScreenGui)

-- 根据屏幕尺寸自动缩放，避免手机和平板界面超出安全区域。
local MainScale = create("UIScale", { Scale = 1 }, MainFrame)
local function updateUIScale()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    MainScale.Scale = math.clamp(
        math.min((viewport.X - 20) / 640, (viewport.Y - 70) / 450),
        0.52,
        1
    )
end
updateUIScale()
if Workspace.CurrentCamera then
    addConn(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale))
end

create("UICorner", { CornerRadius = UDim.new(0, 12) }, MainFrame)
create("UIStroke", {
    Color     = Color3.fromRGB(50, 50, 70),
    Thickness = 1,
}, MainFrame)

-- TopBar
local TopBar = create("Frame", {
    Size             = UDim2.new(1, 0, 0, 62),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel  = 0,
}, MainFrame)
create("UICorner", { CornerRadius = UDim.new(0, 12) }, TopBar)

-- Logo V (small, inline in topbar)
local LogoBox = create("Frame", {
    Size             = UDim2.new(0, 36, 0, 36),
    Position         = UDim2.new(0, 14, 0, 13),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel  = 0,
}, TopBar)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, LogoBox)
create("UIStroke", {
    Color = Color3.fromRGB(70,70,70), Thickness = 1
}, LogoBox)
create("TextLabel", {
    Size               = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Text               = "V",
    TextColor3         = Color3.fromRGB(255,255,255),
    TextSize           = 20,
    Font               = Enum.Font.GothamBold,
    TextXAlignment     = Enum.TextXAlignment.Center,
    TextYAlignment     = Enum.TextYAlignment.Center,
}, LogoBox)

create("TextLabel", {
    Size               = UDim2.new(1,-160, 0, 22),
    Position           = UDim2.new(0, 58, 0, 8),
    BackgroundTransparency = 1,
    Text               = "VAN THANH  ·  偷蛋助手",
    TextColor3         = Color3.fromRGB(255,255,255),
    TextSize           = 14,
    Font               = Enum.Font.GothamBold,
    TextXAlignment     = Enum.TextXAlignment.Left,
}, TopBar)

create("TextLabel", {
    Size               = UDim2.new(1,-160, 0, 16),
    Position           = UDim2.new(0, 58, 0, 32),
    BackgroundTransparency = 1,
    Text               = "V4  ·  Delta 兼容模式  ·  移动端优化",
    TextColor3         = Color3.fromRGB(100,200,120),
    TextSize           = 9,
    Font               = Enum.Font.Gotham,
    TextXAlignment     = Enum.TextXAlignment.Left,
}, TopBar)

local CloseButton = create("TextButton", {
    Size             = UDim2.new(0, 34, 0, 34),
    Position         = UDim2.new(1,-45,0,14),
    BackgroundColor3 = Color3.fromRGB(160,40,50),
    Text             = "×",
    TextColor3       = Color3.fromRGB(255,255,255),
    TextSize         = 20,
    Font             = Enum.Font.GothamBold,
    BorderSizePixel  = 0,
}, TopBar)
create("UICorner", { CornerRadius = UDim.new(0,8) }, CloseButton)

local Sidebar = create("ScrollingFrame", {
    Size             = UDim2.new(0, 148, 1, -72),
    Position         = UDim2.new(0, 10, 0, 72),
    BackgroundColor3 = Color3.fromRGB(18,18,26),
    BorderSizePixel  = 0,
    CanvasSize       = UDim2.new(0, 0, 0, 438),
    ScrollBarThickness = 3,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, MainFrame)
create("UICorner", { CornerRadius = UDim.new(0,9) }, Sidebar)

local Content = create("Frame", {
    Size                = UDim2.new(1,-173,1,-72),
    Position            = UDim2.new(0,163,0,72),
    BackgroundTransparency = 1,
}, MainFrame)

----------------------------------------------------------------
-- TAB SYSTEM
----------------------------------------------------------------

local Tabs  = {}
local Pages = {}

local function createPage(name)
    local page = create("ScrollingFrame", {
        Name               = name.."Page",
        Size               = UDim2.new(1,-10,1,-10),
        Position           = UDim2.new(0,5,0,5),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ScrollBarThickness = 3,
        CanvasSize         = UDim2.new(0,0,0,0),
        Visible            = false,
    }, Content)

    local layout = create("UIListLayout", {
        Padding   = UDim.new(0,8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 15)
    end)

    Pages[name] = page
    return page
end

local function showPage(name)
    for k, p in pairs(Pages) do p.Visible = k == name end
    for k, b in pairs(Tabs) do
        if k == name then
            b.BackgroundColor3 = Color3.fromRGB(60,45,130)
            b.TextColor3       = Color3.fromRGB(255,255,255)
        else
            b.BackgroundColor3 = Color3.fromRGB(24,24,33)
            b.TextColor3       = Color3.fromRGB(155,155,170)
        end
    end
end

local function createTab(name, text, order)
    local btn = create("TextButton", {
        Name             = name.."Tab",
        Size             = UDim2.new(1,-16,0,36),
        Position         = UDim2.new(0,8,0,order*42+8),
        BackgroundColor3 = Color3.fromRGB(24,24,33),
        BorderSizePixel  = 0,
        Text             = text,
        TextColor3       = Color3.fromRGB(155,155,170),
        TextSize         = 10,
        Font             = Enum.Font.GothamMedium,
    }, Sidebar)
    create("UICorner", { CornerRadius = UDim.new(0,7) }, btn)
    Tabs[name] = btn
    btn.MouseButton1Click:Connect(function() showPage(name) end)
    return btn
end

local HomePage     = createPage("Home")
local FarmPage     = createPage("Farm")
local MovementPage = createPage("Movement")
local BossPage     = createPage("Boss")
local TeleportPage = createPage("Teleport")
local AntiPage     = createPage("Anti")
local BypassPage   = createPage("Bypass")
local SettingsPage = createPage("Settings")

createTab("Home",     "⌂  首页",       0)
createTab("Farm",     "🥚 自动拾取",        1)
createTab("Movement", "➤  移动",   2)
createTab("Boss",     "⚔  首领",       3)
createTab("Teleport", "◆  传送",   4)
createTab("Anti",     "🛡 防护",        5)
createTab("Bypass",   "⚡ 状态",      6)
createTab("Settings", "⚙  设置",   7)

----------------------------------------------------------------
-- UI COMPONENTS
----------------------------------------------------------------

local function createSection(parent, text)
    return create("TextLabel", {
        Size               = UDim2.new(1,-10,0,26),
        BackgroundTransparency = 1,
        Text               = text,
        TextColor3         = Color3.fromRGB(200,200,220),
        TextSize           = 11,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, parent)
end

local function createButton(parent, text)
    local btn = create("TextButton", {
        Size             = UDim2.new(1,-10,0,36),
        BackgroundColor3 = Color3.fromRGB(28,28,38),
        BorderSizePixel  = 0,
        Text             = text,
        TextColor3       = Color3.fromRGB(225,225,230),
        TextSize         = 10,
        Font             = Enum.Font.GothamMedium,
    }, parent)
    create("UICorner", {CornerRadius=UDim.new(0,7)}, btn)
    return btn
end

local function createToggle(parent, text, initial, cb)
    local enabled = initial
    local btn = createButton(parent, text..": "..(enabled and "开启" or "关闭"))

    local function refresh()
        btn.Text = text..": "..(enabled and "开启" or "关闭")
        btn.BackgroundColor3 = enabled
            and Color3.fromRGB(38,130,65)
            or  Color3.fromRGB(28,28,38)
    end

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        refresh()
        if cb then cb(enabled) end
    end)

    refresh()
    return btn
end

local function createLabel(parent, text)
    local lbl = create("TextLabel", {
        Size               = UDim2.new(1,-10,0,30),
        BackgroundColor3   = Color3.fromRGB(22,22,31),
        BorderSizePixel    = 0,
        Text               = text,
        TextColor3         = Color3.fromRGB(175,175,190),
        TextSize           = 10,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }, parent)
    create("UICorner",{CornerRadius=UDim.new(0,6)},lbl)
    return lbl
end

----------------------------------------------------------------
-- HOME PAGE
----------------------------------------------------------------

createSection(HomePage, "运行概览")

StatusBox = createLabel(HomePage, "  状态：待机")

local FarmBox     = createLabel(HomePage, "  自动拾取：关闭")
local BossBox     = createLabel(HomePage, "  自动首领：关闭")
local EggCounter  = createLabel(HomePage, "  已拾取鸡蛋：0")
local BossCounter = createLabel(HomePage, "  首领攻击次数：0")
local EPMLabel    = createLabel(HomePage, "  每分钟鸡蛋：0")
local SessionLabel= createLabel(HomePage, "  运行时间：0分 0秒")

local function updateDashboard()
    FarmBox.Text     = "  自动拾取："..(FLAGS.AutoFarm and "开启" or "关闭")
    BossBox.Text     = "  自动首领："..(FLAGS.AutoBoss and "开启" or "关闭")
    EggCounter.Text  = "  已拾取鸡蛋："..FLAGS.EggsCollected
    BossCounter.Text = "  首领攻击次数："..FLAGS.BossAttacks
    EPMLabel.Text    = "  每分钟鸡蛋："..FLAGS.EggsPerMinute

    local elapsed = math.floor(tick() - CONFIG.SESSION.START_TICK)
    SessionLabel.Text = string.format("  运行时间：%d分 %d秒",
        math.floor(elapsed/60), elapsed%60)
end

createSection(HomePage, "快捷控制")

local function setAutoFarm(v)
    FLAGS.AutoFarm = v
    updateStatus(v and "自动拾取已开启" or "自动拾取已关闭")
    updateDashboard()
end

local function setAutoBoss(v)
    FLAGS.AutoBoss = v
    updateStatus(v and "自动首领已开启" or "自动首领已关闭")
    updateDashboard()
end

createButton(HomePage, "启动 / 停止自动拾取").MouseButton1Click:Connect(function()
    setAutoFarm(not FLAGS.AutoFarm)
end)

createButton(HomePage, "启动 / 停止自动首领").MouseButton1Click:Connect(function()
    setAutoBoss(not FLAGS.AutoBoss)
end)

----------------------------------------------------------------
-- FARM PAGE
----------------------------------------------------------------

createSection(FarmPage, "自动拾取")
createToggle(FarmPage, "自动拾取鸡蛋", false, setAutoFarm)
createToggle(FarmPage, "无目标时返回跑步机", true, function(v)
    FLAGS.ReturnTreadmill = v
end)
createToggle(FarmPage, "稀有鸡蛋提示", true, function(v)
    FLAGS.NotifyOnRare = v
end)

createSection(FarmPage, "稀有度筛选")
for _, rarity in ipairs(CONFIG.RARITY_PRIORITY) do
    createToggle(FarmPage, RARITY_ZH[rarity] or rarity, CONFIG.TARGET_RARITIES[rarity], function(v)
        CONFIG.TARGET_RARITIES[rarity] = v
    end)
end

createSection(FarmPage, "优先级")
createLabel(FarmPage, "  秘密 > 永恒 > 神圣 > 光明 > 黑暗 > 未知")

----------------------------------------------------------------
-- MOVEMENT PAGE
----------------------------------------------------------------

createSection(MovementPage, "移动模式")

local ModeBtn = createButton(MovementPage, "模式：折线")
ModeBtn.MouseButton1Click:Connect(function()
    CONFIG.MOVE_MODE = CONFIG.MOVE_MODE == "ZigZag" and "Direct" or "ZigZag"
    ModeBtn.Text = "模式："..(CONFIG.MOVE_MODE == "ZigZag" and "折线" or "直线")
end)

createSection(MovementPage, "保存位置")

local SaveBtn = createButton(MovementPage, "保存当前位置")
local GoBtn   = createButton(MovementPage, "传送到保存位置")

SaveBtn.MouseButton1Click:Connect(function()
    local root = getRoot()
    if root then
        CONFIG.TREADMILL_CFRAME = root.CFrame
        SaveBtn.Text = "位置已保存 ✓"
        task.delay(1.5, function() SaveBtn.Text = "保存当前位置" end)
    end
end)

GoBtn.MouseButton1Click:Connect(function()
    moveTarget(CONFIG.TREADMILL_CFRAME)
    updateStatus("已传送到保存位置")
end)

createSection(MovementPage, "速度调节")
local SpeedLabel = createLabel(MovementPage, "  传送延迟："..CONFIG.ANTI.TELEPORT_DELAY)

local SpeedFast = createButton(MovementPage, "更快（–0.01）")
local SpeedSlow = createButton(MovementPage, "更慢（+0.01）")

SpeedFast.MouseButton1Click:Connect(function()
    CONFIG.ANTI.TELEPORT_DELAY = math.max(0.01,
        CONFIG.ANTI.TELEPORT_DELAY - 0.01)
    SpeedLabel.Text = string.format("  Teleport delay: %.2f", CONFIG.ANTI.TELEPORT_DELAY)
end)

SpeedSlow.MouseButton1Click:Connect(function()
    CONFIG.ANTI.TELEPORT_DELAY = math.min(0.3,
        CONFIG.ANTI.TELEPORT_DELAY + 0.01)
    SpeedLabel.Text = string.format("  Teleport delay: %.2f", CONFIG.ANTI.TELEPORT_DELAY)
end)

----------------------------------------------------------------
-- BOSS PAGE
----------------------------------------------------------------

createSection(BossPage, "首领自动化")
createToggle(BossPage, "自动首领", false, setAutoBoss)

createButton(BossPage, "攻击首领一次").MouseButton1Click:Connect(function()
    pcall(handleBoss)
end)

createSection(BossPage, "扫描目标")
createLabel(BossPage, "  Boss / Events / EggBoss / GiantEgg")

----------------------------------------------------------------
-- TELEPORT PAGE
----------------------------------------------------------------

createSection(TeleportPage, "传送地点")

createButton(TeleportPage, "秘密瀑布").MouseButton1Click:Connect(function()
    updateStatus("正在传送到秘密瀑布……")
    moveTarget(CONFIG.WATERFALL_CFRAME)
    updateStatus("已到达秘密瀑布")
end)

createButton(TeleportPage, "跑步机").MouseButton1Click:Connect(function()
    moveTarget(CONFIG.TREADMILL_CFRAME)
    updateStatus("已到达跑步机")
end)

----------------------------------------------------------------
-- ANTI PAGE
----------------------------------------------------------------

createSection(AntiPage, "防护状态")
createLabel(AntiPage, "  防挂机：开启（每 "..CONFIG.ANTI.AFK_INTERVAL.."秒）")
createLabel(AntiPage, "  自动重连："..(CONFIG.ANTI.RECONNECT and "开启" or "关闭"))
createLabel(AntiPage, "  属性保护："..(CONFIG.ANTI.PROPERTY_GUARD and "开启" or "关闭"))

createSection(AntiPage, "行走速度")

local WalkSpeedLabel = createLabel(AntiPage, "  行走速度："..CONFIG.ANTI.WALK_SPEED)

createButton(AntiPage, "速度 +2").MouseButton1Click:Connect(function()
    CONFIG.ANTI.WALK_SPEED += 2
    WalkSpeedLabel.Text = "  行走速度："..CONFIG.ANTI.WALK_SPEED
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = CONFIG.ANTI.WALK_SPEED end
    end)
end)

createButton(AntiPage, "速度 -2").MouseButton1Click:Connect(function()
    CONFIG.ANTI.WALK_SPEED = math.max(4, CONFIG.ANTI.WALK_SPEED - 2)
    WalkSpeedLabel.Text = "  行走速度："..CONFIG.ANTI.WALK_SPEED
    pcall(function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = CONFIG.ANTI.WALK_SPEED end
    end)
end)

----------------------------------------------------------------
-- BYPASS PAGE (live status)
----------------------------------------------------------------

createSection(BypassPage, "VAN THANH 模块状态")

local function bypassStatusLabel(text, active)
    local lbl = createLabel(BypassPage, "  "..text)
    lbl.TextColor3 = active
        and Color3.fromRGB(80,210,110)
        or  Color3.fromRGB(200,80,80)
    return lbl
end

bypassStatusLabel("__namecall Hook（远程调用保护）",  hookMeta ~= nil)
bypassStatusLabel("debug.info 信息隐藏",              safeHook ~= nil)
bypassStatusLabel("脚本身份信息隐藏",                  typeof(getscriptidentity)=="function")
bypassStatusLabel("执行器信息隐藏",                    typeof(identifyexecutor)=="function")
bypassStatusLabel("HTTP 特征过滤",                     safeHook ~= nil)
bypassStatusLabel("断开拦截",                          safeHook ~= nil)
bypassStatusLabel("关闭事件拦截",                      safeHook ~= nil)
bypassStatusLabel("重力属性保护",                      hookMeta ~= nil)
bypassStatusLabel("脚本错误信息处理",                  true)
bypassStatusLabel("环境特征清理",                      true)
bypassStatusLabel("完整性检查（30秒）",                true)

createSection(BypassPage, "远程调用日志")
local RemoteLogLabel = createLabel(BypassPage, "  已记录远程调用：0")

createSection(BypassPage, "拦截列表")
createLabel(BypassPage, "  在 VT_BlockedRemotes 表中添加名称")

createButton(BypassPage, "复制运行日志").MouseButton1Click:Connect(function()
    toClipboard(table.concat(VT_LOG, "\n"))
    updateStatus("运行日志已复制")
end)

----------------------------------------------------------------
-- SETTINGS PAGE
----------------------------------------------------------------

createSection(SettingsPage, "界面设置")

createButton(SettingsPage, "隐藏界面").MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

createButton(SettingsPage, "重置计数").MouseButton1Click:Connect(function()
    FLAGS.EggsCollected      = 0
    FLAGS.BossAttacks        = 0
    FLAGS.EggsPerMinute      = 0
    CONFIG.SESSION.START_TICK = tick()
    updateDashboard()
    updateStatus("计数已重置")
end)

createButton(SettingsPage, "卸载脚本").MouseButton1Click:Connect(function()
    cleanupAll()
    pcall(function() ScreenGui:Destroy() end)
    print("[VAN THANH V4] 已卸载。")
end)

createLabel(SettingsPage, "  RightShift = 显示 / 隐藏界面")
createLabel(SettingsPage, "  Van Thanh Executor V4")

----------------------------------------------------------------
-- CLOSE / KEYBIND
----------------------------------------------------------------

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

addConn(UserInputService.InputBegan:Connect(
    safeClosure(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
))

----------------------------------------------------------------
-- VAN THANH FLOATING LOGO (draggable)
----------------------------------------------------------------

local FloatingGui
task.spawn(safeClosure(function()
    local sg2 = create("ScreenGui", {
        Name           = "VanThanhBadge",
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
        DisplayOrder   = 1000000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, UIParent)
    FloatingGui = sg2

    if syn and syn.protect_gui then
        pcall(syn.protect_gui, sg2)
    end

    local badge = create("Frame", {
        Size             = UDim2.new(0,50,0,50),
        Position         = UDim2.new(1,-70,0,14),
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BorderSizePixel  = 0,
        Active           = true,
    }, sg2)
    create("UICorner", { CornerRadius = UDim.new(0,8) }, badge)
    create("UIStroke", {
        Color=Color3.fromRGB(55,55,55), Thickness=1
    }, badge)

    create("TextLabel", {
        Size               = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text               = "V",
        TextColor3         = Color3.fromRGB(255,255,255),
        TextSize           = 26,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Center,
        TextYAlignment     = Enum.TextYAlignment.Center,
    }, badge)

    -- click to toggle main UI
    local clickBtn = create("TextButton", {
        Size               = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text               = "",
    }, badge)

    addConn(clickBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end))

    -- drag
    local dragging, dragStart, frameStart = false, nil, nil
    addConn(badge.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            dragStart  = input.Position
            frameStart = badge.Position
        end
    end))
    addConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            badge.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + delta.X,
                frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
            )
        end
    end))
    addConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end))

----------------------------------------------------------------
-- AUTOMATION LOOP
----------------------------------------------------------------

task.spawn(safeClosure(function()
    while FLAGS.Running do
        if FLAGS.AutoBoss then
            pcall(handleBoss)
        elseif FLAGS.AutoFarm then
            pcall(function()
                local egg = findPriorityEgg()
                if egg then
                    collectEgg(egg)
                elseif FLAGS.ReturnTreadmill then
                    goToTreadmill()
                else
                    updateStatus("正在等待鸡蛋……")
                end
            end)
        else
            if FLAGS.CurrentStatus ~= "待机" then
                updateStatus("待机")
            end
        end
        task.wait(CONFIG.CHECK_INTERVAL)
    end
end))

----------------------------------------------------------------
-- DASHBOARD + BYPASS LOG REFRESH
----------------------------------------------------------------

task.spawn(safeClosure(function()
    while FLAGS.Running do
        updateDashboard()
        RemoteLogLabel.Text = "  已记录远程调用："..#VT_RemoteLog
        task.wait(0.5)
    end
end))

----------------------------------------------------------------
-- ╔══════════════════════════════════════════╗
-- ║         CHEAT SUITE — VAN THANH          ║
-- ║  ESP · Fly · Noclip · Speed · Pull · God ║
-- ╚══════════════════════════════════════════╝
----------------------------------------------------------------

-- Add cheat tabs to sidebar
local CheatPage  = createPage("Cheat")
local ESPPage    = createPage("ESP")

createTab("Cheat", "💀 功能",   8)
createTab("ESP",   "👁  透视",      9)

----------------------------------------------------------------
-- CHEAT FLAGS
----------------------------------------------------------------

local CHEAT = {
    Fly          = false,
    FlySpeed     = 60,
    Noclip       = false,
    SpeedHack    = false,
    SpeedValue   = 60,
    InfJump      = false,
    GodMode      = false,
    PullEggs     = false,
    PullRadius   = 80,
    AutoCollect  = false,
    FlyConn      = nil,
    NoclipConn   = nil,
}

----------------------------------------------------------------
-- FLY SYSTEM
-- Smooth WASD + mouse-dir flight via BodyVelocity + BodyGyro
----------------------------------------------------------------

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.Velocity       = Vector3.zero
    bv.MaxForce       = Vector3.new(1e5, 1e5, 1e5)
    bv.P              = 1e4
    bv.Parent         = root

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque      = Vector3.new(1e5, 1e5, 1e5)
    bg.P              = 1e4
    bg.D              = 500
    bg.CFrame         = root.CFrame
    bg.Parent         = root

    local cam = workspace.CurrentCamera

    CHEAT.FlyConn = RunService.Heartbeat:Connect(safeClosure(function()
        if not CHEAT.Fly then
            bv:Destroy()
            bg:Destroy()
            hum.PlatformStand = false
            CHEAT.FlyConn:Disconnect()
            CHEAT.FlyConn = nil
            return
        end

        local moveDir = Vector3.zero
        local cf      = cam.CFrame
        local spd     = CHEAT.FlySpeed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDir = moveDir - Vector3.new(0,1,0)
        end

        -- 手机摇杆通过 Humanoid.MoveDirection 提供方向。
        if moveDir.Magnitude == 0 and hum.MoveDirection.Magnitude > 0 then
            moveDir = hum.MoveDirection
        end

        -- 手机跳跃键控制上升；松开后保持当前高度。
        if UserInputService.TouchEnabled and hum.Jump then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            bv.Velocity = moveDir.Unit * spd
        else
            bv.Velocity = Vector3.zero
        end

        bg.CFrame = cf
    end))
end

local function stopFly()
    CHEAT.Fly = false
    -- conn cleans itself on next heartbeat
end

----------------------------------------------------------------
-- NOCLIP
-- Zero CanCollide on char parts every physics step
----------------------------------------------------------------

local function startNoclip()
    CHEAT.NoclipConn = RunService.Stepped:Connect(safeClosure(function()
        if not CHEAT.Noclip then
            CHEAT.NoclipConn:Disconnect()
            CHEAT.NoclipConn = nil
            -- restore collisions
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = true
                    end
                end
            end
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = false
            end
        end
    end))
end

----------------------------------------------------------------
-- INFINITE JUMP
----------------------------------------------------------------

local infJumpConn
local function enableInfJump()
    infJumpConn = UserInputService.JumpRequest:Connect(safeClosure(function()
        if not CHEAT.InfJump then
            infJumpConn:Disconnect()
            infJumpConn = nil
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

----------------------------------------------------------------
-- GOD MODE
-- Loop-restore Health to MaxHealth
----------------------------------------------------------------

local godConn
local function enableGod()
    godConn = RunService.Heartbeat:Connect(safeClosure(function()
        if not CHEAT.GodMode then
            godConn:Disconnect()
            godConn = nil
            return
        end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end))
end

----------------------------------------------------------------
-- EGG PULL / VACUUM
-- Teleport all nearby eggs to player every tick
----------------------------------------------------------------

local pullConn
local function startPull()
    pullConn = RunService.Heartbeat:Connect(safeClosure(function()
        if not CHEAT.PullEggs then
            pullConn:Disconnect()
            pullConn = nil
            return
        end
        local root = getRoot()
        if not root then return end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local isEgg = (obj:IsA("BasePart") or obj:IsA("Model"))
                and string.find(string.lower(obj.Name), "egg")
                and not string.find(string.lower(obj.Name), "hatch")

            if isEgg then
                local pos = obj:IsA("Model")
                    and obj:GetPivot().Position
                    or obj.Position

                if (root.Position - pos).Magnitude <= CHEAT.PullRadius then
                    pcall(function()
                        if obj:IsA("Model") then
                            obj:PivotTo(CFrame.new(root.Position + Vector3.new(0,2,0)))
                        else
                            obj.CFrame = CFrame.new(root.Position + Vector3.new(0,2,0))
                        end
                    end)

                    -- auto-collect if toggled
                    if CHEAT.AutoCollect then
                        pcall(function() collectEgg(obj) end)
                    end
                end
            end
        end
    end))
end

----------------------------------------------------------------
-- CHEAT PAGE UI
----------------------------------------------------------------

createSection(CheatPage, "移动功能")

createToggle(CheatPage, "飞行", false, function(v)
    CHEAT.Fly = v
    if v then
        startFly()
        updateStatus("飞行已开启")
    else
        stopFly()
        updateStatus("飞行已关闭")
    end
end)

-- fly speed slider (buttons)
local FlySpeedLabel = createLabel(CheatPage,
    "  飞行速度：" .. CHEAT.FlySpeed)

createButton(CheatPage, "飞行速度 +10").MouseButton1Click:Connect(function()
    CHEAT.FlySpeed = math.min(500, CHEAT.FlySpeed + 10)
    FlySpeedLabel.Text = "  飞行速度：" .. CHEAT.FlySpeed
end)
createButton(CheatPage, "飞行速度 -10").MouseButton1Click:Connect(function()
    CHEAT.FlySpeed = math.max(10, CHEAT.FlySpeed - 10)
    FlySpeedLabel.Text = "  飞行速度：" .. CHEAT.FlySpeed
end)

createToggle(CheatPage, "穿墙", false, function(v)
    CHEAT.Noclip = v
    if v then
        startNoclip()
        updateStatus("穿墙已开启")
    else
        updateStatus("穿墙已关闭")
    end
end)

createToggle(CheatPage, "无限跳跃", false, function(v)
    CHEAT.InfJump = v
    if v then
        enableInfJump()
        updateStatus("无限跳跃已开启")
    else
        updateStatus("无限跳跃已关闭")
    end
end)

createSection(CheatPage, "速度功能")

local SpeedHackLabel = createLabel(CheatPage,
    "  加速速度：" .. CHEAT.SpeedValue)

createToggle(CheatPage, "移动加速", false, function(v)
    CHEAT.SpeedHack = v
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = v and CHEAT.SpeedValue or CONFIG.ANTI.WALK_SPEED
    end
    updateStatus(v and ("移动加速已开启（"..CHEAT.SpeedValue..")") or "移动加速已关闭")
end)

createButton(CheatPage, "移动速度 +10").MouseButton1Click:Connect(function()
    CHEAT.SpeedValue = math.min(500, CHEAT.SpeedValue + 10)
    SpeedHackLabel.Text = "  加速速度：" .. CHEAT.SpeedValue
    if CHEAT.SpeedHack then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = CHEAT.SpeedValue end
    end
end)
createButton(CheatPage, "移动速度 -10").MouseButton1Click:Connect(function()
    CHEAT.SpeedValue = math.max(16, CHEAT.SpeedValue - 10)
    SpeedHackLabel.Text = "  加速速度：" .. CHEAT.SpeedValue
    if CHEAT.SpeedHack then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = CHEAT.SpeedValue end
    end
end)

createSection(CheatPage, "生存功能")

createToggle(CheatPage, "生命保持", false, function(v)
    CHEAT.GodMode = v
    if v then
        enableGod()
        updateStatus("生命保持已开启")
    else
        updateStatus("生命保持已关闭")
    end
end)

createSection(CheatPage, "鸡蛋吸附")

local PullRadiusLabel = createLabel(CheatPage,
    "  吸附范围：" .. CHEAT.PullRadius)

createToggle(CheatPage, "吸附附近鸡蛋", false, function(v)
    CHEAT.PullEggs = v
    if v then
        startPull()
        updateStatus("鸡蛋吸附已开启")
    else
        updateStatus("鸡蛋吸附已关闭")
    end
end)

createToggle(CheatPage, "吸附后自动拾取", false, function(v)
    CHEAT.AutoCollect = v
end)

createButton(CheatPage, "范围 +20").MouseButton1Click:Connect(function()
    CHEAT.PullRadius = math.min(500, CHEAT.PullRadius + 20)
    PullRadiusLabel.Text = "  吸附范围：" .. CHEAT.PullRadius
end)
createButton(CheatPage, "范围 -20").MouseButton1Click:Connect(function()
    CHEAT.PullRadius = math.max(20, CHEAT.PullRadius - 20)
    PullRadiusLabel.Text = "  吸附范围：" .. CHEAT.PullRadius
end)

----------------------------------------------------------------
-- ESP SYSTEM
-- Billboard tags above players + eggs
-- Highlights via SelectionBox on parts
----------------------------------------------------------------

local ESP = {
    Players  = false,
    Eggs     = false,
    Tags     = {},      -- [instance] = billboard
    Boxes    = {},      -- [instance] = SelectionBox
    MaxDist  = 500,
}

local ESP_COLORS = {
    Secret  = Color3.fromRGB(255, 215, 0),
    Eternal = Color3.fromRGB(180, 0, 255),
    Divine  = Color3.fromRGB(255, 120, 0),
    Light   = Color3.fromRGB(200, 230, 255),
    Dark    = Color3.fromRGB(80,  0,  160),
    Player  = Color3.fromRGB(255, 80,  80),
    Default = Color3.fromRGB(255, 255, 255),
}

local ESPFolder = Instance.new("Folder")
ESPFolder.Name   = "VT_ESP"
ESPFolder.Parent = UIParent

local function makeTag(adornee, text, color, key)
    if ESP.Tags[key] then return end

    local bb = Instance.new("BillboardGui")
    bb.Name          = "VT_ESP_Tag"
    bb.Size          = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset   = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop   = true
    bb.Adornee       = adornee
    bb.Parent        = ESPFolder

    local frame = Instance.new("Frame")
    frame.Size            = UDim2.new(1,0,1,0)
    frame.BackgroundColor3= Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent          = bb
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,4)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = text
    lbl.TextColor3         = color
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextXAlignment     = Enum.TextXAlignment.Center
    lbl.TextYAlignment     = Enum.TextYAlignment.Center
    lbl.Parent             = frame

    ESP.Tags[key] = bb
end

local function makeBox(adornee, color, key)
    if ESP.Boxes[key] then return end
    local sb = Instance.new("SelectionBox")
    sb.Color3        = color
    sb.LineThickness = 0.05
    sb.SurfaceTransparency = 0.8
    sb.SurfaceColor3 = color
    sb.Adornee       = adornee
    sb.Parent        = ESPFolder
    ESP.Boxes[key]   = sb
end

local function removeESP(key)
    if ESP.Tags[key] then
        ESP.Tags[key]:Destroy()
        ESP.Tags[key] = nil
    end
    if ESP.Boxes[key] then
        ESP.Boxes[key]:Destroy()
        ESP.Boxes[key] = nil
    end
end

local function clearAllESP()
    for key in pairs(ESP.Tags) do removeESP(key) end
    ESPFolder:ClearAllChildren()
end

-- ESP loop
local espConn
local function startESP()
    espConn = RunService.Heartbeat:Connect(safeClosure(function()
        if not ESP.Players and not ESP.Eggs then
            espConn:Disconnect()
            espConn = nil
            clearAllESP()
            return
        end

        local root = getRoot()
        local myPos = root and root.Position or Vector3.zero

        -- PLAYER ESP
        if ESP.Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                local char = plr.Character
                if not char then continue end
                local proot = char:FindFirstChild("HumanoidRootPart")
                if not proot then continue end

                local dist = (myPos - proot.Position).Magnitude
                local playerKey = "player:" .. tostring(plr.UserId)
                local playerBoxKey = "playerbox:" .. tostring(plr.UserId)
                if dist > ESP.MaxDist then
                    removeESP(playerKey)
                    removeESP(playerBoxKey)
                    continue
                end

                local distStr = string.format("[%.0f]", dist)
                makeTag(proot,
                    plr.Name .. "\n" .. distStr,
                    ESP_COLORS.Player,
                    playerKey)
                makeBox(char, ESP_COLORS.Player, playerBoxKey)
            end
        else
            -- clean player tags if toggled off
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    removeESP("player:" .. tostring(plr.UserId))
                    removeESP("playerbox:" .. tostring(plr.UserId))
                end
            end
        end

        -- EGG ESP
        if ESP.Eggs then
            local seen = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local isEgg = (obj:IsA("BasePart") or obj:IsA("Model"))
                    and string.find(string.lower(obj.Name), "egg")
                    and not string.find(string.lower(obj.Name), "hatch")
                if not isEgg then continue end

                local pos = obj:IsA("Model")
                    and obj:GetPivot().Position
                    or obj.Position

                local dist = (myPos - pos).Magnitude
                if dist > ESP.MaxDist then continue end

                local rarity   = getRarity(obj) or "?"
                local color    = ESP_COLORS[rarity] or ESP_COLORS.Default
                local key      = "egg:" .. tostring(obj)
                local boxKey   = "eggbox:" .. tostring(obj)
                local distStr  = string.format("[%.0f]", dist)
                local adornee  = obj:IsA("Model")
                    and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart"))
                    or obj

                if adornee then
                    makeTag(adornee,
                        (RARITY_ZH[rarity] or rarity) .. "\n" .. distStr,
                        color, key)
                    makeBox(adornee, color, boxKey)
                end
                seen[key] = true
                seen[boxKey] = true
            end

            -- prune stale egg tags
            for key in pairs(ESP.Tags) do
                if type(key) == "string"
                    and string.sub(key, 1, 4) == "egg:"
                    and not seen[key] then
                    removeESP(key)
                    removeESP("eggbox:" .. string.sub(key, 5))
                end
            end
        else
            -- 仅清除鸡蛋标记，保留仍处于开启状态的玩家透视。
            local removeKeys = {}
            for key in pairs(ESP.Tags) do
                if type(key) == "string" and string.sub(key, 1, 4) == "egg:" then
                    table.insert(removeKeys, key)
                    table.insert(removeKeys, "eggbox:" .. string.sub(key, 5))
                end
            end
            for _, key in ipairs(removeKeys) do removeESP(key) end
        end
    end))
end

----------------------------------------------------------------
-- ESP PAGE UI
----------------------------------------------------------------

createSection(ESPPage, "玩家透视")

createToggle(ESPPage, "玩家透视", false, function(v)
    ESP.Players = v
    if (v or ESP.Eggs) and not espConn then startESP() end
    updateStatus(v and "玩家透视已开启" or "玩家透视已关闭")
end)

createSection(ESPPage, "鸡蛋透视")

createToggle(ESPPage, "鸡蛋透视", false, function(v)
    ESP.Eggs = v
    if (v or ESP.Players) and not espConn then startESP() end
    updateStatus(v and "鸡蛋透视已开启" or "鸡蛋透视已关闭")
end)

createSection(ESPPage, "透视设置")

local ESPDistLabel = createLabel(ESPPage,
    "  最大距离：" .. ESP.MaxDist)

createButton(ESPPage, "距离 +50").MouseButton1Click:Connect(function()
    ESP.MaxDist = math.min(2000, ESP.MaxDist + 50)
    ESPDistLabel.Text = "  最大距离：" .. ESP.MaxDist
end)
createButton(ESPPage, "距离 -50").MouseButton1Click:Connect(function()
    ESP.MaxDist = math.max(50, ESP.MaxDist - 50)
    ESPDistLabel.Text = "  最大距离：" .. ESP.MaxDist
end)

createButton(ESPPage, "清除全部透视").MouseButton1Click:Connect(function()
    clearAllESP()
    updateStatus("透视标记已清除")
end)

createSection(ESPPage, "颜色说明")
createLabel(ESPPage, "  🟡 秘密   🟣 永恒   🟠 神圣")
createLabel(ESPPage, "  🔵 光明   🟤 黑暗   🔴 玩家")

----------------------------------------------------------------
-- CLEANUP PATCH — include cheat connections
----------------------------------------------------------------

local _origCleanup = cleanupAll
cleanupAll = function()
    CHEAT.Fly      = false
    CHEAT.Noclip   = false
    CHEAT.GodMode  = false
    CHEAT.PullEggs = false
    CHEAT.InfJump  = false
    CHEAT.SpeedHack= false
    ESP.Players    = false
    ESP.Eggs       = false
    clearAllESP()
    pcall(function() ESPFolder:Destroy() end)
    pcall(function()
        if FloatingGui then FloatingGui:Destroy() end
    end)
    _origCleanup()
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

showPage("Home")
updateDashboard()
updateStatus("就绪")

print("[VAN THANH V4] 加载完成：功能与透视模块已启用。")
