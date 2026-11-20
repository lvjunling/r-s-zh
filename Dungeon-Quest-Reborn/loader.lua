-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/dma-scripts/script/refs/heads/main/dungeonquestog]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/dma-scripts/script/refs/heads/main/dungeonquestog","translations":{"--":"--","2D OVERLAY VISUALS":"二维叠加显示","Attack Swing Delay (Sec)":"挥击间隔（秒）","Drawing ESP":"绘制式透视","Enable 2D Overlay ESP":"启用二维透视标记","Hover Height Above Head (Studs)":"目标头顶悬停高度（格）","Infinite Stamina & Roll Cooldown Bypass":"无限体力与跳过翻滚冷却","Lighting Ambient Brightness":"环境光亮度","Locked":"已锁定","MOVEMENT OVERRIDES":"移动参数覆盖","Master Game Volume":"游戏总音量","OVERHEAD AFK FARM CONTROLS":"头顶悬停挂机控制","OVERHEAD AUTO FARM (Hover & Kill)":"头顶自动刷怪（悬停并攻击）","Overhead Farm":"头顶悬停刷怪","Q & E Auto Spell Caster":"自动施放 Q／E 技能","Select WindUI Theme":"选择 WindUI 主题","Settings":"设置","Show Bounding Boxes":"显示包围方框","Show Health Bars":"显示血条","Show Name & Distance Tags":"显示名称与距离标签","Stamina & Speed":"体力与速度","THEMES & AUDIO":"主题与音频","Targeting Priority Mode":"目标优先级模式","This tab is Empty":"此标签页暂无内容","Touch Interest Damage Injector":"触碰事件伤害注入","Unload Script (Clean Unhook)":"卸载脚本（清理钩子）","WalkSpeed Booster Multiplier":"行走加速倍率","WalkSpeed Value":"行走速度","dma.wtf":"dma.wtf"}}]]
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
