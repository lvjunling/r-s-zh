-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/Mast1k00/Ninjalegends/refs/heads/main/mast1k-legends.lua]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/Mast1k00/Ninjalegends/refs/heads/main/mast1k-legends.lua","translations":{"1️⃣ Press 'INF GEMS' button":"1️⃣ 点击“无限宝石”按钮","2️⃣ Open 'Toggle Master Elements'":"2️⃣ 打开“大师元素开关”","3️⃣ Click ANY element (e.g. Shadow Charge)":"3️⃣ 点击任意元素（例如“暗影蓄能”）","4️⃣ Enjoy inf gems and almost inf coins!":"4️⃣ 获得无限宝石和近乎无限金币！","Aimbot":"辅助瞄准","Auto Farm":"自动刷取","Automation":"自动化","B":"B","Change the link in the loadstring from github to https://sirius.menu/rayfield":"将 loadstring 中的 GitHub 链接替换为 https://sirius.menu/rayfield","Color Picker":"颜色选择器","Dropdown":"下拉选择","Dynamic Input":"动态输入框","ESP Range":"透视范围","Elements":"元素","Enable Tracers":"启用追踪线","Enter jump (default: 50)":"输入跳跃力度（默认：50）","Enter number of gems":"输入宝石数量","Enter speed (default: 16)":"输入速度（默认：16）","G":"G","Gems":"宝石","General":"常规","If you are not the script author":"如果你不是脚本作者","If you are the script author":"如果你是脚本作者","If you need support making this change":"如果修改时需要帮助","If you're seeing this, this script may not be on the latest Rayfield version. The developer needs to use the sirius.menu/rayfield loadstring to use the latest features and fixes. \n\nVisit sirius.menu/discord for help.":"出现此提示说明脚本可能未使用最新版 Rayfield。开发者需通过 sirius.menu/rayfield 加载界面库，以使用最新功能和修复。\n\n如需帮助，请访问 sirius.menu/discord。","Infinite Gems":"无限宝石","Islands":"岛屿","Jump ON/OFF":"跳跃增强开关","Jump Value":"跳跃数值","Keybind":"快捷键","Label":"标签","Let us know in our Discord, at sirius.menu/discord, and we'll do our best to help.":"请前往 sirius.menu/discord 在 Discord 社区联系我们，我们会尽力提供帮助。","Loading Saved Configuration":"正在加载已保存配置","Main":"主页","Movement":"移动","Notification Error":"通知错误","Notify the script author where possible to ensure their version of Rayfield is updated.":"请尽可能通知脚本作者，确保其使用的 Rayfield 已更新。","Ok":"确定","Old Pets":"旧版宠物","Option":"选项","Option #1":"选项 1","Paragraph Title":"段落标题","R":"R","Rayfield Keybind":"Rayfield 快捷键","Rayfield Settings":"Rayfield 设置","Rayfield UI":"Rayfield 界面","Reset Aimbot System":"重置辅助瞄准系统","Search this page":"搜索当前页面","Sends anonymous counts of which parts of this window are used. Never your name, what you type or your messages. sirius.menu/privacy":"发送此窗口各部分使用次数的匿名统计，不包含你的姓名、输入内容或消息。隐私说明：sirius.menu/privacy","Show Rayfield":"显示 Rayfield","Speed ON/OFF":"速度增强开关","Speed Value":"速度数值","System":"系统","Target Keybind":"目标快捷键","Target Player":"目标玩家","This version of Rayfield Library is outdated.":"当前 Rayfield 界面库版本已过时。","Usage analytics":"使用情况统计","button":"按钮","by vanya1236s":"作者：vanya1236s","hex":"十六进制颜色值","hi":"你好","mast1k-legends":"mast1k-legends","⏹ Stop Auto Buy":"⏹ 停止自动购买","▶ Blazing Entity":"▶ 炽焰实体","▶ Electral Chaos":"▶ 雷电混沌","▶ Eternity Storm":"▶ 永恒风暴","▶ Frost":"▶ 冰霜","▶ Inferno":"▶ 炼狱","▶ Lightning":"▶ 闪电","▶ Load Auto Buy Old Pets":"▶ 加载旧版宠物自动购买","▶ Masterful Wrath":"▶ 大师之怒","▶ Shadow Charge":"▶ 暗影蓄能","▶ Shadowfire":"▶ 暗影之火","⚔️ Auto Swing":"⚔️ 自动挥刀","⚠️ WARNING ⚠️":"⚠️ 警告 ⚠️","⚡ Activate All":"⚡ 激活全部","⚡ INF GEMS":"⚡ 无限宝石","⚡mast1k-legends":"⚡mast1k-legends"," Movement Settings":" 移动设置"," by vanya1236s":" 作者：vanya1236s"," Amount of Gems":" 宝石数量"," Convert Gems to Coins":" 将宝石转换为金币"," INSTRUCTIONS":" 使用说明"," Reset to Default":" 恢复默认设置"," INF GEMS (Gems ∞, Coins -inf)":" 无限宝石（宝石 ∞，金币为负无穷）"," DO NOT USE MAIN ACCOUNT IN ENDGAME":" 游戏后期请勿使用主账号"," THIS SCRIPT IS NOT MINE":" 此脚本并非本人原创"," USE ALT ACCOUNT RECOMMENDED":" 建议使用备用账号","️ Unlock All Islands":"️ 解锁全部岛屿"}}]]
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
