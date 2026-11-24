-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/ummarxfarooq/mystrix-hub/main/loader]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/ummarxfarooq/mystrix-hub/main/loader","translations":{"-> For Bug Reports & Suggestions, Join The Discord Server!":"→ 反馈问题或提出建议，请加入 Discord 服务器！","Anti AFK":"防挂机断线","Anti Lag":"减少卡顿","Appearance":"外观","Authentication":"验证","Auto Farm":"自动刷取","Auto Play":"自动游玩","Auto Race":"自动比赛","Circuit Race":"环道赛","Config":"配置","Config Name":"配置名称","Copy Invite":"复制邀请链接","Criminal":"罪犯","Crimson":"绯红","Czm":"Czm","Delete Selected Config":"删除所选配置","Delivery":"配送","Discord":"Discord","Enable Auto Load":"启用自动加载","Export Config":"导出配置","FPS Cap":"帧率上限","Farm":"刷取","Hide Players":"隐藏玩家","Home":"主页","Import Config":"导入配置","Infinite Jump":"无限跳跃","J":"J","Jobs":"工作","Key Info":"密钥信息","Key Label: N/A\nKey ID: N/A\nTime Left: Unlimited\nExecutions: INF":"密钥标签：不适用\n密钥 ID：不适用\n剩余时间：无限\n执行次数：无限","Keybinds":"快捷键","Load Last Config":"加载上次配置","Load Selected Config":"加载所选配置","Locked":"已锁定","Members: 26307\nOnline: 693":"成员：26307\n在线：693","Misc":"其他","Multiplier":"倍率","Mystrix Hub":"Mystrix Hub","Mystrix Hub - 驾驶帝国 [✨全新限量版✨]":"Mystrix Hub - 驾驶帝国 [✨全新限量版✨]","MystrixHub":"MystrixHub","No configs found":"未找到配置","Paste exported config string here...":"在此粘贴导出的配置字符串……","Performance":"性能","Quick Interact":"快速交互","Race":"比赛","Races":"赛事","Reduce CPU Usage":"降低 CPU 占用","Refresh Config List":"刷新配置列表","Save Config":"保存配置","Search":"搜索","Security":"安保","Select Config":"选择配置","Settings":"设置","Show FPS":"显示帧率","Show Ping":"显示延迟","Show User":"显示用户","Solo":"单人","Theme":"主题","This tab is Empty":"此标签页暂无内容","Toggle UI":"展开／收起界面","Transparency":"透明度","UPDATED — v1.0":"已更新 — v1.0","Update":"更新","v1.0":"v1.0"}}]]
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
