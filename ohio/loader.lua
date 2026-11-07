-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://pastebin.com/raw/QT3TWdJ2]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://pastebin.com/raw/QT3TWdJ2","translations":{"<b><font color=\"#ffffff\">DZINDRAS</font> <font color=\"#a040ff\">MENU</font></b>":"<b><font color=\"#ffffff\">DZINDRAS</font> <font color=\"#a040ff\">菜单</font></b>","📍  TELEPORT":"📍  传送","⚙️  MISC":"⚙️  杂项","🛒  SHOP":"🛒  商店","👤  PLAYER":"👤  玩家","👁️  ESP":"👁️  视透","⚠️  CHEATERS":"⚠️  疑似作弊","💎  VALUABLES":"💎  高价值物品","🌾  AUTOFARM":"🌾  自动刷","🧲  BRING":"🧲  拉人","🎯  AIM LOCK":"🎯  自瞄锁定","💬  DISCORD":"💬  社群","🏦  Bank":"🏦  银行","💰  BankCash":"💰  银行现金","💎  Jewelry Store":"💎  珠宝店","🪖  Military Gate":"🪖  军事基地大门","🔫  Armory 1":"🔫  军械库 1","🔫  Armory 2":"🔫  军械库 2","🖤  Black Market":"🖤  黑市","🏥  Hospital":"🏥  医院","🚔  Police Station":"🚔  警察局","Custom:":"自定义：","Object name...":"对象名称...","📍  Teleport to Custom Name":"📍  传送到自定义名称","↩  Rejoin":"↩  重新加入","🔵  Join Small Server":"🔵  加入小服务器","🔴  Join Big Server":"🔴  加入大服务器","⚡  INSTANT INTERACT":"⚡  即时交互","⚡  Instant Interact":"⚡  即时交互","💤  ANTI AFK":"💤  防挂机","💤  Anti AFK":"💤  防挂机","🔍  Search item...":"🔍  搜索物品...","↩  Return to previous position":"↩  返回原位置","💰  MONEY LIST":"💰  金钱排行","🎯  FOLLOW / 👁️  SPECTATE":"🎯  跟随 / 👁️  观战","🔄  Refresh List":"🔄  刷新列表","🔄  Refresh Players":"🔄  刷新玩家","▶  Start Follow":"▶  开始跟随","⏹  Stop Follow":"⏹  停止跟随","▶  Start Spectate":"▶  开始观战","⏹  Stop Spectate":"⏹  停止观战","👁️  Player ESP":"👁️  玩家视透","💰  Money ESP":"💰  金钱视透","🗑️  Clear List":"🗑️  清空列表","🎯 TP":"🎯 传送","🏦  AUTO ROB BANK":"🏦  自动抢银行","▶  Start Auto Rob":"▶  开始自动抢劫","⏹  Stop Auto Rob":"⏹  停止自动抢劫","BringPlayer":"拉取玩家","Player RootPart bring. and You can shoot.":"把玩家的 RootPart 拉到身边，你可以开枪射击。","BringAhead":"拉到面前","Brings player directly in front of you.":"把玩家直接拉到你面前。","Player name...":"玩家名称...","🎯  Enable Aim Lock":"🎯  启用自瞄锁定","💬  Join our Discord!":"💬  加入我们的 Discord！","📋  Copy Link":"📋  复制链接","✅  Copied!":"✅  已复制！","Copy the link and paste it\nin your browser or Discord app!":"复制链接后\n粘贴到浏览器或 Discord 客户端！","Status: Ready":"状态：就绪","Status: Ready  (Hold Q)":"状态：就绪（按住 Q）","Status: Teleporting...":"状态：传送中...","Status: Searching...":"状态：搜索中...","Status: Teleported!":"状态：已传送！","Status: Not found!":"状态：未找到！","Status: Can't get position.":"状态：无法获取位置。","Status: Can't get pos!":"状态：无法获取位置！","Status: Enter name!":"状态：请输入名称！","Status: Rejoining...":"状态：重新加入中...","Status: Finding...":"状态：查找中...","Status: Instant Interact ON":"状态：即时交互已开启","Status: Anti AFK ON":"状态：防挂机已开启","Status: OFF":"状态：已关闭","Status: Returned!":"状态：已返回！","Status: No saved pos!":"状态：没有已保存的位置！","Status: ItemsOnSale not found!":"状态：未找到 ItemsOnSale！","Status: Refreshed!":"状态：已刷新！","Status: Select player!":"状态：请选择玩家！","Status: Stopped":"状态：已停止","Status: ESP ON":"状态：视透已开启","Status: ESP OFF":"状态：视透已关闭","Status: Money ESP ON":"状态：金钱视透已开启","Status: Money ESP OFF":"状态：金钱视透已关闭","Status: Monitoring...":"状态：监控中...","Status: Cleared":"状态：已清空","Status: Scanning...":"状态：扫描中...","Status: BankCash not found!":"状态：未找到银行现金！","Status: At BankCash!":"状态：已到达银行现金！","Status: Robbing...":"状态：抢劫中...","Status: Enabled — Hold Q":"状态：已启用 — 按住 Q","Status: Locked!":"状态：已锁定！","Status: Disabled":"状态：已禁用"}}]]
-- END GENERATED CONFIG

local HttpService = game:GetService("HttpService")
local translations = HttpService:JSONDecode(EMBEDDED_JSON).translations
local hooked = setmetatable({}, { __mode = "k" })

local function hook(obj)
    if hooked[obj] then return end
    local property
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        property = "Text"
    elseif obj:IsA("TextBox") then
        -- 保留用户输入，只翻译输入框占位提示。
        property = "PlaceholderText"
    else
        return
    end
    hooked[obj] = true
    local applying = false
    local function apply()
        if applying then return end
        local text = obj[property]
        local translated = translations[text]
        if type(translated) == "string" and translated ~= "" and translated ~= text then
            applying = true
            obj[property] = translated
            applying = false
        end
    end
    apply()
    obj:GetPropertyChangedSignal(property):Connect(apply)
end

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local roots = { playerGui }
local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
if ok then roots[#roots + 1] = coreGui end
if type(gethui) == "function" then
    local success, hidden = pcall(gethui)
    if success and hidden then roots[#roots + 1] = hidden end
end
local seen = {}
for _, root in ipairs(roots) do
    if not seen[root] then
        seen[root] = true
        pcall(function()
            root.DescendantAdded:Connect(function(obj) task.defer(hook, obj) end)
        end)
    end
end

local drawingTexts = setmetatable({}, { __mode = "k" })
if type(Drawing) == "table" and type(Drawing.new) == "function" then
    local library = Drawing
    local original = library.new
    local function wrapped(kind, ...)
        local obj = original(kind, ...)
        if kind == "Text" then drawingTexts[obj] = true end
        return obj
    end
    local installed = pcall(function() library.new = wrapped end) and library.new == wrapped
    if not installed then
        local proxy = setmetatable({ new = wrapped }, { __index = library })
        pcall(function() Drawing = proxy end)
    end
end

task.spawn(function()
    while true do
        for obj in pairs(drawingTexts) do
            local success, text = pcall(function() return obj.Text end)
            if not success and type(getrenderproperty) == "function" then
                success, text = pcall(getrenderproperty, obj, "Text")
            end
            local translated = success and translations[text]
            if type(translated) == "string" and translated ~= "" and translated ~= text then
                local applied = pcall(function() obj.Text = translated end)
                if not applied and type(setrenderproperty) == "function" then
                    pcall(setrenderproperty, obj, "Text", translated)
                end
            end
        end
        task.wait(0.1)
    end
end)

local function fetch(url)
    assert(type(url) == "string" and url:match("^https://"), "请配置 HTTPS 脚本地址")
    local success, source = pcall(function() return game:HttpGet(url) end)
    if success and type(source) == "string" and #source > 0 then return source end
    local requestFn = request or http_request or (syn and syn.request)
    if type(requestFn) == "function" then
        local fetched, response = pcall(requestFn, { Url = url, Method = "GET" })
        if fetched and type(response) == "table" then
            local code = tonumber(response.StatusCode or response.Status)
            if code and code >= 200 and code < 300 and type(response.Body) == "string" and #response.Body > 0 then
                return response.Body
            end
        end
    end
    error("下载失败，请检查 URL、网络与执行器的 HTTP 支持")
end

local success, err = pcall(function()
    local source = fetch(SCRIPT_URL)
    assert(type(loadstring) == "function", "执行器缺少 loadstring")
    local fn, compileError = loadstring(source)
    assert(fn, compileError)
    fn()
end)
if not success then warn("[界面汉化] " .. tostring(err)) end
