-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/gurungunknown96-gif/muscle-legend/refs/heads/main/main]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/gurungunknown96-gif/muscle-legend/refs/heads/main/main","translations":{"-":"-","Anti-AFK":"防挂机断线","Auto Rebirth":"自动重生","Auto Tool":"自动使用工具","Auto Train":"自动训练","Automatic rebirth":"自动进行重生","CR":"CR","Config":"配置","Credits":"致谢","Delete file":"删除文件","Enable while holding tool (10x rep)":"持有工具时启用（10 倍重复次数）","Farm":"刷取","Fly":"飞行","Go to spawn area":"前往出生区域","Inspiration":"灵感来源","Jump":"跳跃","Jump 120 (50 when off)":"跳跃力度 120（关闭时为 50）","Load Config":"加载配置","Main":"主要功能","Movement":"移动","Noclip":"穿墙","ON: equip slot 2, OFF: hand only":"开启：装备第 2 槽位；关闭：仅空手","Owner: Monkey.d.luffy.ezz\nOwner: Rectslayer":"所有者：Monkey.d.luffy.ezz\n所有者：Rectslayer","Player":"玩家","Prevents AFK kick":"防止因挂机被踢出","RIVO HUB":"RIVO HUB","Rejoin":"重新加入","Rejoin same server":"重新加入当前服务器","Reload file":"重新加载文件","Reset Config":"重置配置","Save Config":"保存配置","Save now":"立即保存","Settings":"设置","Speed":"速度","Speed 60 (16 when off)":"速度 60（关闭时为 16）","Speed Hub [Menu]":"Speed Hub［菜单］","Teleport - Gym":"传送至健身房","Utility":"实用工具","WASD + E/Q to rise, speed 50":"WASD 移动，E／Q 升降，速度 50","Walk through walls":"穿过墙壁","X":"X"}}]]
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
