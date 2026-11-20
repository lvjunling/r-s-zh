-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://sirmemegithub.com/RealSlimShady2000/free-nokey-scripts/raw/branch/main/loader.luau]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://sirmemegithub.com/RealSlimShady2000/free-nokey-scripts/raw/branch/main/loader.luau","translations":{"--":"--","Accent":"强调色","Anti-AFK":"防挂机断线","Auto":"自动","Auto close tips":"自动关闭提示","Auto load (this game)":"自动加载（当前游戏）","Background":"背景","Border":"边框","BottomRight":"右下角","Config JSON":"配置 JSON","Config name":"配置名称","Configs":"配置","Configs & Auto Load":"配置与自动加载","Create":"创建","Created: Select a config":"创建时间：请选择配置","Custom cursor":"自定义光标","Decision interval":"决策间隔","Delete":"删除","Detected: Mobile | Active: Mobile":"检测到：手机｜当前模式：手机","Device mode":"设备模式","Element":"元素","Export":"导出","Fade time":"淡出时间","Find a feature, e.g. auto roll or fruit ESP":"查找功能，例如自动抽取或果实透视","For server changes: enable Queue on Teleport, save a profile and choose it under Auto Load.":"换服续载：开启“传送后执行”，保存配置并在“自动加载”中选中。","Glass blur":"玻璃模糊","Glass mode":"玻璃模式","Glow intensity":"发光强度","Gradient":"渐变","Hovered Element":"悬停元素","Import":"导入","Inline":"内嵌","Interface":"界面","Last saved: -":"上次保存：-","Last used: -":"上次使用：-","Load":"加载","Menu keybind":"菜单快捷键","Mobile Launch":"手机端启动","None":"无","Notif. duration":"通知持续时间","Notif. sounds":"通知音效","Notifications":"通知","Off":"关闭","Outline":"描边","Outlines":"描边","Page Background":"页面背景","Paste config JSON, then Import…":"粘贴配置 JSON，然后点击导入……","Paste theme JSON, then Import…":"粘贴主题 JSON，然后点击导入……","Placeholder Text":"占位文字","Quad":"二次缓动","Queue on Teleport":"传送后执行","Reopen rsHub after teleports and server changes. Save your config and select Auto load for farming to resume.":"传送或换服后重新打开 rsHub。保存配置并选择自动加载，以继续自动刷取。","RoWorld":"RoWorld","Save":"保存","Save under Configs & Auto Load, then select Auto load for this game.":"在“配置与自动加载”中保存，然后为当前游戏选择自动加载配置。","Search features":"搜索功能","Source updated: 2026-11-18 UTC":"源脚本更新时间：2026-11-18 UTC","Stop All":"停止全部功能","Stop hotkey:":"停止快捷键：","Teleport":"传送","Text":"文字","Text Stroke":"文字描边","Theme JSON":"主题 JSON","Theme colors":"主题颜色","Times shown in your local time.":"时间按你的本地时区显示。","Top-bar layout":"顶栏布局","Tween style":"过渡类型","Tween time":"过渡时间","Type a feature name to search every tab.":"输入功能名称，搜索全部标签页。","UI scale":"界面缩放","UI transparency":"界面透明度","Unload":"卸载","Version: v1.0.17":"版本：v1.0.17","[RControl]":"[右 Ctrl]","[RShift]":"[右 Shift]","name..":"名称……","robloxscripts.com Hub  •  v1.0.17":"robloxscripts.com Hub  •  v1.0.17","×":"×","⚔️ Combat":"⚔️ 战斗","⚙️ Settings":"⚙️ 设置"," Home":" 主页"," Economy":" 经济"," Intel":" 情报","🧠 Autopilot":"🧠 自动控制","🧪 Solo":"🧪 单人"}}]]
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
