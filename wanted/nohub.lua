-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://cdn.luaprotect.dev/u/41e5f2/5sLSKXAh64bcZwAR]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://cdn.luaprotect.dev/u/41e5f2/5sLSKXAh64bcZwAR","translations":{"ATMs":"自动取款机","Aim":"瞄准","Aim FOV (radius)":"瞄准范围半径","Anti AFK":"防挂机断线","Anti Fling":"防击飞","Audio":"音频","Auto Collect Cash":"自动拾取现金","Auto Reload":"自动换弹","Auto Sell - Ofy":"自动出售给 Ofy","Auto Sell - Sir B":"自动出售给 Sir B","Auto Turn In Tasks":"自动交任务","Bags":"背包","Bank Floor":"银行大厅","Bank Vault":"银行金库","Bhop Multiplier":"连跳倍率","Both":"两者","Bunny Hop":"连跳","Camera & Display":"镜头与显示","Cash":"现金","Cash & Loot":"现金与战利品","Chests":"宝箱","Climb Multiplier":"攀爬倍率","Collect Nearby Cash":"拾取附近现金","Combat":"战斗","Crosshair":"准星","Custom Gravity":"自定义重力","Dark WindUI layout. Search a feature at the top or open its category. Settings are auto-loaded from the local preset on startup.":"深色 WindUI 界面。可在顶部搜索功能，或打开对应分类。启动时会自动加载本地预设。","Disable All Features":"关闭所有功能","Display & Performance":"显示与性能","Draw Aim FOV":"显示瞄准范围","Draw Distance":"绘制距离","ESP":"透视标记","Exit Vehicle":"离开载具","FOV Color":"范围圈颜色","Fill Color":"填充颜色","Fill Transparency":"填充透明度","Flight":"飞行","Fly":"飞行开关","Fly Smoothness":"飞行平滑度","Fly Speed":"飞行速度","Gravity":"重力","Green":"绿色","Head":"头部","Hit Chance":"命中概率","Hit Nearby ATMs":"攻击附近的取款机","Hit Nearby Registers":"攻击附近的收银机","Hit Nearest ATM":"攻击最近的取款机","Ignore Friends":"忽略好友","Ignore Ghosts":"忽略幽灵","Ignore Knocked Players":"忽略倒地玩家","Ignore Party":"忽略同小队成员","Ignore Same Team":"忽略同阵营成员","Infinite Jump":"无限跳跃","Join Police":"加入警方","Join Syndicate":"加入帮派","Jump Power":"跳跃力度","JumpPower":"跳跃力度","Kick Multiplier":"枪械后坐倍率","Leave Police":"退出警方","Leave Syndicate":"退出帮派","Lighting":"光照","Local Preset":"本地预设","Locked":"已锁定","Loot":"战利品","Max Distance":"最大距离","Mobile arrows, controller A/B, PC Space/Ctrl":"手机用方向按钮，手柄用 A／B，电脑用空格／Ctrl","Movement":"移动","Mute Footsteps":"关闭脚步声","Mute Gunshots":"关闭枪声","Mute UI Sounds":"关闭界面音效","Mute Vehicle Sounds":"关闭载具音效","NHOOK":"NHOOK","NHOOK  v2.5.0":"NHOOK v2.5.0","NHOOK  |  WANTED  v2.5.0":"NHOOK｜WANTED v2.5.0","NPCs":"NPC","Nearest Safe":"最近的保险箱","No Bloom":"关闭泛光","No Blur":"关闭模糊","No Camera Shake":"关闭镜头抖动","No Color Correction":"关闭色彩校正","No Depth of Field":"关闭景深","No Fog":"关闭雾效","No Shadows":"关闭阴影","No Sky":"隐藏天空","No Sun Rays":"关闭阳光光束","Noclip":"穿墙","Ofy":"Ofy","Open Nearby Chests":"打开附近的宝箱","Other":"其他","Outline Color":"描边颜色","Outline Transparency":"描边透明度","Performance Mode":"性能模式","Pick Up Nearby Cases":"拾取附近的手提箱","Pickup Radius":"拾取半径","Player ESP":"玩家透视标记","Players":"玩家","Prediction":"移动预判","Prediction Seconds":"预判时长（秒）","Priority":"优先级","Recoil Reduction":"降低后坐力","Redirects the client aim point":"重定向客户端的瞄准点","Refill Ammo":"补充弹药","Refresh ESP":"刷新透视标记","Refresh Interval":"刷新间隔","Registers":"收银机","Render Mode":"渲染模式","Requests a reload when your gun is empty":"弹匣打空时发起换弹请求","Reset Camera":"重置镜头","Reset Saved Settings":"重置已保存的设置","Restore Visuals":"恢复画面效果","Robberies":"抢劫","Safes":"保险箱","Save My Position":"保存当前位置","Save Settings":"保存设置","Search":"搜索","Sell & Tasks":"出售与任务","Session":"当前会话","Settings":"设置","Show ATM Timer":"显示取款机倒计时","Show Broken ATMs":"显示已损坏的取款机","Show Distance":"显示距离","Show Health":"显示生命值","Show Name":"显示名称","Show Ready ATMs":"显示可用的取款机","Show Stars":"显示通缉星级","Show Team":"显示阵营","Silent Aim":"静默瞄准","Sir B":"Sir B","Spread Multiplier":"弹道散布倍率","Sway Multiplier":"武器晃动倍率","Takes effect when equipping a gun":"装备枪械时生效","Target":"目标","Target Filters":"目标筛选","Teams":"阵营","Teleport":"传送","Teleport to Saved Position":"传送到已保存的位置","Text Color":"文字颜色","Text Size":"文字大小","This tab is Empty":"此标签页暂无内容","Travel":"传送与出行","Turn In Ready Tasks":"提交已完成的任务","Unload NHOOK":"卸载 NHOOK","Vehicle":"载具","Vehicles":"载具","Visibility Check":"可见性检测","Visuals":"画面","Walk Speed":"行走速度","WalkSpeed":"行走速度","Weapons":"武器","White":"白色","World":"世界"}}]]
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
