-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://pasteblox.com/raw/h96htjnkkk]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://pasteblox.com/raw/h96htjnkkk","translations":{"100 Friends":"100 位好友","12 playing":"12 人正在游玩","18 minutes":"18 分钟","2 friends":"2 位好友","28 friends":"28 位好友","30 players can join this server":"此服务器最多可容纳 30 名玩家","Active Option":"选中选项","Aimbot":"辅助瞄准","All":"全部","Autoload Config":"自动加载配置","Autoloads The Selected Config Every Time The Script Is Run After This":"此后每次运行脚本时，自动加载选中的配置","B":"B","Bind":"绑定按键","But With A Description":"附带说明的示例","Button":"按钮","Check Key":"验证密钥","Color 1":"颜色 1","Color 2":"颜色 2","Color 3":"颜色 3","Color Picker":"颜色选择器","Combat":"战斗","Config Name":"配置名称","Configuration":"配置管理","Configuration Selector":"配置选择器","Cool Configuration":"示例配置","Copy Key":"复制密钥","Couldn't catch region in time":"未能及时获取服务器地区","Current Autoload: None":"当前自动加载配置：无","Custom Gradient Editor":"自定义渐变编辑器","Delete Configuration":"删除配置","Delete The Selected Configuration":"删除选中的配置","Deleting A Config Is Permanant, And You Have To Redo The Config":"删除配置后不可恢复，需要重新设置","Discord":"Discord","Dropdown":"下拉选择","Dynamic Input":"动态输入框","ESP":"透视","FOV Radius":"瞄准范围半径","Find out what your friends are currently doing":"查看好友当前动态","Friends":"好友","G":"G","Health":"生命值","Hello, Pookie (Display Name)":"你好，Pookie（显示名称）","Hex Input":"十六进制颜色输入","Hitbox":"碰撞范围","Home Dashboard":"主页概览","Hunter Infinity":"Hunter Infinity","ImNotDoxxingMyGirlFriendLol (Username Here)":"ImNotDoxxingMyGirlFriendLol（此处为用户名）","In Server":"当前服务器","In server for":"已在服务器停留","Inactive Option":"未选中选项","Inactive Tab":"未选中标签页","Information":"信息","Information on the session you're currently in":"当前会话的相关信息","Input Placeholder":"输入框占位提示","Join Script":"加入服务器脚本","Key":"密钥","Key System":"密钥系统","Keybind":"快捷键","Label":"标签","Latency":"延迟","Load Config":"加载配置","Load Configuration":"加载配置","Load The Selected Configuration":"加载选中的配置","Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec tincidunt, nulla et facilisis blandit, arcu ligula hendrerit nisi, at fringilla metus metus a mi. Proin vel porttitor ante. Cras felis enim, placerat quis dictum vitae, ":"示例占位文案：此段文字用于预览界面排版、段落换行及长文本显示效果，不包含实际功能说明。","Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus venenatis lacus sed tempus eleifend. Mauris interdum bibendum felis, in tempor augue egestas vel. Praesent tristique consectetur ex, eu pretium sem placerat non. Vestibulum a nisi sit amet augue facilisis consectetur sit amet et nunc. Integer fermentum ornare cursus. Pellentesque sed ultricies metus, ut egestas metus. Vivamus auctor erat ac sapien vulputate, nec ultricies sem tempor. Quisque leo lorem, faucibus nec pulvinar nec, congue eu velit. Duis sodales massa efficitur imperdiet ultrices. Donec eros ipsum, ornare pharetra purus aliquam, tincidunt elementum nisi. Ut mi tortor, feugiat eget nunc vitae, facilisis interdum dui. Vivamus ullamcorper nunc dui, a dapibus nisi pretium ac. Integer eleifend placerat nibh, maximus malesuada tellus. Cras in justo in ligula scelerisque suscipit vel vitae quam. Aenean tempor elit sed sagittis fermentum. Sed fringilla vel ex nec finibus. ":"示例占位文案：此段文字用于预览界面排版、段落换行及长文本显示效果，不包含实际功能说明。","Luna Interface Suite":"Luna 界面套件","Lunar build":"Lunar 构建版本","Maximum Players":"最大玩家人数","Miscellaneous And UI Settings":"杂项与界面设置","Modifiers":"功能调节","Name":"名称","Notification System":"通知系统","Offline":"离线","Online":"在线","Paragraph":"段落","Players":"玩家","Prerelease Beta 6.1":"预发布测试版 6.1","Preset Gradients":"预设渐变","R":"R","Save Config":"保存配置","Save Configuration - Name":"保存配置 — 名称","Save Configuration - Save":"保存配置 — 保存","Save The Configuration":"保存当前配置","Section":"分区","Select The Config To Work with":"选择要操作的配置","Server":"服务器","Server Region":"服务器地区","Show FOV":"显示瞄准范围","Skeleton":"骨骼透视","Slider":"滑块","Smoothing":"瞄准平滑度","Spin Bind":"旋转快捷键","Spin Speed":"旋转速度","Spinbot":"自动旋转","Tab Template":"标签页模板","Tap to copy join script":"点击复制加入服务器脚本","Tap to join the Discord Server":"点击加入 Discord 服务器","Template":"模板","The Bind To Reopen The Window After It is minimized":"窗口最小化后，使用此快捷键重新打开","The Name To Save The Current Config Under":"保存当前配置时使用的名称","Theming Settings":"主题设置","This Is A Preview Of Luna's Dynamic Notification System Entailing Estimated/Calculated Wait Times, A Sleek Design, Icons, And A Glassmorphic Look":"这是 Luna 动态通知系统的预览，包含预计／计算的等待时间、简洁设计、图标及毛玻璃外观。","Toggle":"开关","Toggle Interface":"显示／隐藏界面","Tracers":"追踪线","UI Settings":"界面设置","UI Toggle Bind":"界面开关快捷键","Urban Reload":"Urban Reload","Visibility Check":"可见性检测","Warning":"警告","Y-Axis Only":"仅 Y 轴","Your executor seems to support this script.":"你的执行器似乎支持此脚本。","by Nebula Softworks":"由 Nebula Softworks 制作","icaNext02":"icaNext02","no friends":"暂无好友"}}]]
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
