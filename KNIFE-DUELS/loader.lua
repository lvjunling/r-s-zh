-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/imshrak/knifeduels/refs/heads/main/menu]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/imshrak/knifeduels/refs/heads/main/menu","translations":{"#050505 • 5, 5, 5":"#050505 • 5, 5, 5","#111827 • 17, 23, 39":"#111827 • 17, 23, 39","#1f2937 • 31, 41, 55":"#1f2937 • 31, 41, 55","#3b82f6 • 59, 130, 246":"#3b82f6 • 59, 130, 246","#ffffff • 255, 255, 255":"#ffffff • 255, 255, 255","---":"---","70/100":"70/100","96/180":"96/180","Accent color":"强调色","Aimbot":"自动瞄准","Aimbot Strength":"自动瞄准强度","Always":"始终","BBot":"BBot","Background Image":"背景图片","Background color":"背景色","Basketball Head":"篮球头","Body":"身体","Box ESP":"方框透视","BuilderSans":"BuilderSans","Chinese Dance":"中国舞","Code":"代码","Combat":"战斗","Config JSON":"配置 JSON","Config list":"配置列表","Config name":"配置名称","Configuration":"配置管理","Contrast check: good (17.7:1)":"对比度检查：良好（17.7:1）","Copy Hex":"复制十六进制色值","Copy RGB":"复制 RGB 色值","Copy color":"复制颜色","Create config":"创建配置","Create theme":"创建主题","Current autoload config: none":"当前自动加载配置：无","Current default theme: none":"当前默认主题：无","Custom theme name":"自定义主题名称","Custom themes":"自定义主题","Cute Sit":"可爱坐姿","Default":"默认","Delete config":"删除配置","Delete theme":"删除主题","Distance ESP":"距离透视","Dracula":"德古拉","Emotes":"表情动作","Export current config":"导出当前配置","Export current theme":"导出当前主题","Extra":"额外功能","FOV Circle":"瞄准范围圈","FOV Size":"瞄准范围大小","Fake Dead":"装死","Fantasy":"幻想","Fatality":"致命","Font Face":"字体","Font color":"字体颜色","Gangnam Style":"江南 Style","Gotham":"Gotham","Head":"头部","Health ESP":"血量透视","Hold":"按住","Import config":"导入配置","Import theme":"导入主题","Jester":"小丑","Join Discord":"加入 Discord 社区","Jumpstyle":"跳步舞","Jura":"Jura","K":"K","KDV2":"KDV2","Keybinds":"快捷键","Label":"标签","Load config":"加载配置","Load theme":"加载主题","Lock":"锁定","Main":"主要功能","Main color":"主色","Menu":"菜单","Menu bind":"菜单快捷键","Mint":"薄荷","Moonwalk":"太空步","Nervy Dance":"紧张舞","Nord":"北欧","Outline color":"描边颜色","Overwrite config":"覆盖配置","Overwrite theme":"覆盖主题","Paste color":"粘贴颜色","Play/Stop":"播放 / 停止","Quartz":"石英","Random":"随机","Rat Dance":"老鼠舞","Refresh list":"刷新列表","Remove":"移除","Reset autoload":"重置自动加载","Reset default":"重置默认项","RightShift":"右 Shift","Roboto":"Roboto","RobotoMono":"RobotoMono","Search":"搜索","Set as autoload":"设为自动加载","Set as default":"设为默认","Settings":"设置","Skeleton ESP":"骨骼透视","SourceSans":"SourceSans","Take the L":"失败者之舞","Target Part":"目标部位","Team Check":"队伍检测","Theme JSON":"主题 JSON","Theme list":"主题列表","Themes":"主题","Toggle":"切换","Tokyo Night":"东京之夜","Ubuntu":"Ubuntu","Unload":"卸载脚本","Visible Keybinds":"可见快捷键","Visual":"视觉","check":"check","chevron-up":"chevron-up","discord.gg/N7Fa87GtKe":"discord.gg/N7Fa87GtKe","folder-cog":"folder-cog","move":"move","move-diagonal-2":"move-diagonal-2","paintbrush":"paintbrush","search":"search","settings":"settings","x":"x"}}]]
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
