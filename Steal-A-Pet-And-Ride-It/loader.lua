-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/ummarxfarooq/mystrix-hub/main/loader]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/ummarxfarooq/mystrix-hub/main/loader","translations":{"-> For bug reports or suggestions, join the discord server!":"→ 反馈问题或提出建议，请加入 Discord 服务器！","Anti AFK":"防挂机断线","Anti Lag":"减少卡顿","Appearance":"外观","Authentication":"验证","Auto":"自动","Auto Buy":"自动购买","Auto Claim":"自动领取","Auto Collect":"自动收集","Auto Equip Best":"自动装备最佳宠物","Auto Farm":"自动刷取","Auto Open Cages":"自动开启笼子","Auto Place Best":"自动放置最佳宠物","Auto Play Minigames":"自动游玩小游戏","Auto Press 2x & 3x":"自动点击 2 倍和 3 倍","Auto Rebirth":"自动重生","Auto Ride Best":"自动骑乘最佳宠物","Auto Sell":"自动出售","Auto Train":"自动训练","Auto Upgrade":"自动升级","Automation":"自动化","Buy":"购买","By Income":"按收益","Cages":"笼子","Cash":"现金","Claim":"领取","Config":"配置","Config Name":"配置名称","Copy Invite":"复制邀请链接","Crimson":"绯红","Czm":"Czm","Daily":"每日奖励","Delete Selected Config":"删除所选配置","Discord":"Discord","Enable Auto Load":"启用自动加载","Export Config":"导出配置","FPS Cap":"帧率上限","Farm":"刷取","Games":"游戏","Hide Players":"隐藏玩家","Home":"主页","Import Config":"导入配置","Index":"图鉴","Infinite Jump":"无限跳跃","J":"J","Key Info":"密钥信息","Key Label: N/A\nKey ID: N/A\nTime Left: Unlimited\nExecutions: INF":"密钥标签：不适用\n密钥 ID：不适用\n剩余时间：无限\n执行次数：无限","Keybinds":"快捷键","Load Last Config":"加载上次配置","Load Selected Config":"加载所选配置","Locked":"已锁定","Members: 25651\nOnline: 696":"成员：25651\n在线：696","Minigames":"小游戏","Misc":"其他","Mystrix Hub":"Mystrix Hub","Mystrix Hub - [] 偷一只宠物并骑上它！":"Mystrix Hub - [] 偷一只宠物并骑上它！","MystrixHub":"MystrixHub","No configs found":"未找到配置","None":"无","Paste exported config string here...":"在此粘贴导出的配置字符串……","Performance":"性能","Pets":"宠物","Playtime":"在线时长","Plot":"地块","Quick Interact":"快速交互","Race, Boss, Keep":"竞速、首领、保留","Rarities":"稀有度","Rebirth":"重生","Reduce CPU Usage":"降低 CPU 占用","Refresh Config List":"刷新配置列表","Rewards":"奖励","Save Config":"保存配置","Search":"搜索","Select":"选择","Select Config":"选择配置","Sell":"出售","Sell Below":"出售低于阈值的宠物","Sell Pets Below Income":"出售收益低于阈值的宠物","Settings":"设置","Shop":"商店","Show FPS":"显示帧率","Show Ping":"显示延迟","Show User":"显示用户","Start":"开始","Talisman":"护符","Theme":"主题","This tab is Empty":"此标签页暂无内容","Toggle UI":"展开／收起界面","Trails":"拖尾","Transparency":"透明度","Treadmill":"跑步机","UPDATED — v1.3":"已更新 — v1.3","Update":"更新","Zones":"区域","e.g. 1.5M/s, 500K, 2B":"例如：1.5M/s、500K、2B","v1.3":"v1.3"}}]]
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
