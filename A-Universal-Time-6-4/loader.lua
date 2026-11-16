-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/AkatsukiHub1/A-Universal-Time/refs/heads/main/README.md]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/AkatsukiHub1/A-Universal-Time/refs/heads/main/README.md","translations":{"31":"31","60":"60","Akatsuki Hub : A Universal Time":"Akatsuki Hub：A Universal Time（通用时间）","Anti-Afk":"防挂机踢出","Auto Collect Play Time Rewards":"自动领取在线时长奖励","B":"B","B+":"B+","Boundless Tower":"无尽之塔","By AkatXD":"作者：AkatXD","C":"C","C+":"C+","Common":"普通","Crocodile":"克洛克达尔","Curses":"咒灵","Diavolo, The Boss":"迪亚波罗，老板","Disable 3D Render":"关闭 3D 渲染","Discord":"Discord","E":"E","Eight-Handled Sword Divergent Sila Divine General Mahoraga":"八握剑异戒神将魔虚罗","Epic":"史诗","Fleeing Prisoner":"逃犯","Funny Valentine / The 23rd President":"法尼·瓦伦泰 / 第 23 任总统","G":"G","G+":"G+","Guardian":"守卫","H":"H","H+":"H+","Hold up, aint you Dio?":"等等，你不是迪奥吗？","Hooligan":"流氓","Ichigo Kurosaki":"黑崎一护","Intruding Hueco":"入侵虚圈","Items":"物品","J":"J","J+":"J+","Kars":"卡兹","King Crimson Stand User":"绯红之王替身使者","Legendary":"传说","Locacoca Tree":"洛卡卡卡树","Luffy":"路飞","Magician's Red Stand User":"魔术师之红替身使者","Main":"主要功能","Max FPS":"帧率上限","Misc":"杂项","Noclip":"穿墙","Normal":"正常","Pirate":"海盗","Quests":"任务","R":"R","R+":"R+","Rare":"稀有","Rejoin":"重新加入","Search...":"搜索...","Shanks":"香克斯","Shop":"商店","Small":"小","Soul Reaper":"死神","Star Platinum Stand User":"白金之星替身使者","Stats":"属性","Sword Disciple":"剑术学徒","T":"T","T+":"T+","Teleport":"传送","The Bearer":"承载者","The Clown":"小丑","The Denizen Of Hell":"地狱住民","The Knight":"骑士","The Sorcerer Killer":"术师杀手","The Sovereign":"君主","The Spy":"间谍","The Strongest In History":"史上最强","The Strongest Of Today":"当代最强","The Vessel":"容器","Thug":"暴徒","Traits":"特质","U":"U","U+":"U+","UI Size":"界面大小","V":"V","V+":"V+","Walk Speed":"行走速度","WaterTower":"水塔","Whitebeard":"白胡子","X":"X","X+":"X+","Y":"Y","Y+":"Y+","Z":"Z","Z+":"Z+","Zombie":"僵尸"}}]]
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
