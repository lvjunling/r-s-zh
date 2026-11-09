-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/SrilangishT/hub/refs/heads/main/Loader]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/SrilangishT/hub/refs/heads/main/Loader","translations":{"- Added Fish FE, Infinite Yield, Dex, and SimpleSpy.":"- 新增 Fish FE、Infinite Yield、Dex 和 SimpleSpy 工具。","- Added Target Bang with looping back & forth motion.":"- 新增目标顶胯动作，支持循环前后移动。","- Added Ultra Instinct Tool (rapid side-to-side TP).":"- 新增自在极意功工具（快速左右瞬移）。","- Configured chat commands (!bring, !kick) for Premium owners.":"- 为高级版用户配置聊天指令（!bring、!kick）。","- Implemented GUI persistence across character resets.":"- 角色重置后仍保留工具界面。","16":"16","Bang Target":"对目标做顶胯动作","BeaRadvxz":"BeaRadvxz","Buy Premium GamePass":"购买高级版通行证","C0LlHANDAL":"C0LlHANDAL","Changelogs & Updates":"更新日志","CleverBeans25":"CleverBeans25","Commands are managed by Premium Owners in chat.":"指令由高级版用户通过聊天管理。","Controls":"操作设置","Dex Explorer":"Dex 实例浏览器","Dropkick":"飞踢","Emote Player":"表情动作播放器","External Script Loaders":"外部脚本加载器","Fish FE":"Fish FE","Fling Target":"甩飞目标","Fling UI":"甩飞控制界面","Float":"悬浮","Fly GUI Mobile":"移动端飞行界面","Fly GUI V3":"飞行界面 V3","Fun":"趣味功能","Fun Features & Modifiers":"趣味功能与属性调整","Get Ultra Instinct Tool":"获取自在极意功工具","Goto Target":"传送到目标","Hansoy_26":"Hansoy_26","Infamous_Blader7":"Infamous_Blader7","Infinite Yield":"Infinite Yield 工具箱","Jasovcso":"Jasovcso","Juna19090":"Juna19090","Lukas Magnet":"Lukas 磁吸工具","Menus":"功能菜单","ONE666778":"ONE666778","Premium":"高级版","Premium Admin Commands":"高级版管理指令","Refresh Player List":"刷新玩家列表","Rhiix_8":"Rhiix_8","RightAlt":"右 Alt","Select Target Player":"选择目标玩家","SimpleSpy":"SimpleSpy 远程调用查看器","Spectate Target":"观看目标视角","Speed Slow Walk (1 Speed)":"慢速行走（速度 1）","Status: Free User":"状态：免费用户","SunCheese0":"SunCheese0","Super Spin Rings":"超级旋转环","Target":"目标玩家","Target Actions":"目标操作","Target Selection":"目标选择","Toggle UI":"显示 / 隐藏界面","UI Lib":"界面库","WalkSpeed Modifier":"移动速度调整","Welcome!":"欢迎使用！","arria81106":"arria81106","bananakidt8":"bananakidt8","h3llp_me991":"h3llp_me991","hatibatas":"hatibatas","keesha_12372":"keesha_12372","loveydragons":"loveydragons","mulyawira":"mulyawira","nov_vi":"nov_vi","tatatatror2":"tatatatror2","v1.5 Update Log:":"v1.5 更新日志：","xuxu17693":"xuxu17693"}}]]
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
