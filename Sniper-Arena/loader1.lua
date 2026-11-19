-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/polo242c/sniper-arena/main/snpar]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/polo242c/sniper-arena/main/snpar","translations":{"Aimbot":"自动瞄准","Aimbot (Right Click)":"自动瞄准（鼠标右键）","Aimbot Smoothness":"瞄准平滑度","Auto Strafe":"自动横移","Automation":"自动化","B":"B","CFrame Speed (Fix)":"CFrame 移动加速（修复版）","Change the link in the loadstring from github to https://sirius.menu/rayfield":"将 loadstring 中的 GitHub 链接替换为 https://sirius.menu/rayfield","Color Picker":"颜色选择器","Distance ESP":"距离标记","Dropdown":"下拉选择","Dynamic Input":"动态输入","ESP Range":"透视范围","Enable Tracers":"启用追踪线","Enemy ESP (Box)":"敌人方框标记","Fast Reload":"快速换弹","G":"G","General":"通用","Hitbox Expand (Big Head)":"扩大命中范围（大头）","Hitbox Size":"命中范围大小","If you are not the script author":"如果你不是脚本作者","If you are the script author":"如果你是脚本作者","If you need support making this change":"如果你需要协助完成此修改","If you're seeing this, this script may not be on the latest Rayfield version. The developer needs to use the sirius.menu/rayfield loadstring to use the latest features and fixes. \n\nVisit sirius.menu/discord for help.":"看到此提示，说明脚本可能尚未使用最新版 Rayfield。开发者需要使用 sirius.menu/rayfield 的加载代码，以获取最新功能和修复。\n\n访问 sirius.menu/discord 获取帮助。","Jump Boost":"跳跃增强","Jump Power":"跳跃力度","Keybind":"快捷键","Label":"标签","Let us know in our Discord, at sirius.menu/discord, and we'll do our best to help.":"请通过 sirius.menu/discord 加入我们的 Discord 并说明问题，我们会尽力协助。","Loading Saved Configuration":"正在加载已保存的配置","No Recoil":"无后坐力","No Spread":"无散布","Notification Error":"通知错误","Notify the script author where possible to ensure their version of Rayfield is updated.":"如有条件，请通知脚本作者更新其使用的 Rayfield 版本。","Ok":"确定","Only Best Cheats":"精选辅助功能","Option":"选项","Option #1":"选项 1","Paragraph Title":"段落标题","Polo Sniper Arena":"Polo 狙击竞技场","R":"R","Rayfield Keybind":"Rayfield 快捷键","Rayfield Settings":"Rayfield 设置","Rayfield UI":"Rayfield 界面","Reset Aimbot System":"重置瞄准系统","Search this page":"搜索当前页面","Sends anonymous counts of which parts of this window are used. Never your name, what you type or your messages. sirius.menu/privacy":"发送本窗口各部分使用次数的匿名统计，不发送姓名、输入内容或消息。sirius.menu/privacy","Show Rayfield":"显示 Rayfield","Skeleton ESP":"骨骼标记","Speed Value":"速度数值","System":"系统","Target Keybind":"目标快捷键","Target Player":"目标玩家","This version of Rayfield Library is outdated.":"当前 Rayfield 界面库版本已过时。","Tracer ESP (Lines)":"追踪线标记","Trigger Assist (Auto Fire)":"扳机辅助（自动开火）","Usage analytics":"使用情况统计","Visible Check":"可见性检测","button":"按钮","by polo":"作者 polo","hex":"十六进制","hi":"你好","⚠️ Speed Limit: Max 0.1 (CFrame)":"⚠️ 速度上限：最高 0.1（CFrame）"," COMBAT":" 战斗"," MOVEMENT":" 移动","️ VISUALS":"️ 视觉"," WEAPON":" 武器"}}]]
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
