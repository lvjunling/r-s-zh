-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/sampku45-glitch/loader.lua/main/loader%20bug%20evolution.lua]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/sampku45-glitch/loader.lua/main/loader%20bug%20evolution.lua","translations":{"All  ▼":"全部  ▼","All Bugs  ▼":"全部昆虫  ▼","All Sizes  ▼":"全部体型  ▼","Attack Distance : 2":"攻击距离：2","BREAKABLE FARMING":"自动刷可破坏物","BUG ESP":"昆虫透视","BUG EVOLUTION":"昆虫进化（Bug Evolution）","BUG FARMING":"自动刷昆虫","Breakable":"可破坏物","Bug Farm":"昆虫刷取","Bug Value / Size":"昆虫价值 / 体型","Destroy GUI":"关闭并销毁界面","ESP":"透视","Enable Breakable Farming":"启用自动刷可破坏物","Enable Bug Farming":"启用自动刷昆虫","Enable ESP":"启用透视","Enable Orb Farming":"启用自动收集能量球","Farm Options":"刷取选项","Largest First  ▼":"体型最大优先  ▼","MOVEMENT":"移动","Maximum Distance : 1000":"最大距离：1000","Movement Method":"移动方式","Movement settings apply to Bug and Breakable farming.":"移动设置适用于昆虫和可破坏物刷取。","OFF":"关闭","ORB FARMING":"自动收集能量球","Orb":"能量球","Orb  ▼":"能量球  ▼","Orb Type":"能量球类型","Refresh All Lists":"刷新全部列表","Refresh Breakable Types":"刷新可破坏物类型","Refresh Bug / Species Lists":"刷新昆虫 / 物种列表","Refresh Bug Species":"刷新昆虫物种","Select Breakable":"选择可破坏物","Select Bug Species":"选择昆虫物种","Select ESP Species":"选择透视物种","Status: Idle":"状态：空闲","Status: Stopped":"状态：已停止","Stop All Farms":"停止全部刷取","Target Priority":"目标优先级","Target: None":"目标：无","Teleport Delay : 0.20":"传送间隔：0.20","The character moves above the selected breakable. The game's own attack system handles breaking.":"角色会移动到所选可破坏物上方，由游戏自身的攻击系统进行破坏。","Tween  ▼":"平滑移动  ▼","Tween Speed : 150":"平滑移动速度：150","VoidOrbs Available: 8":"可用虚空能量球：8","—":"—"}}]]
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
