-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://barrage.cc/loader]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://barrage.cc/loader","translations":{"<font size=\"18\">BARRAGE</font>\n<font size=\"14\">TR Legacy</font>":"<font size=\"18\">BARRAGE</font>\n<font size=\"14\">TR Legacy</font>","<stroke color=\"#55FF77\" thickness=\"1\"><font color=\"#2ECC71\">MEMBER</font></stroke>":"<stroke color=\"#55FF77\" thickness=\"1\"><font color=\"#2ECC71\">会员</font></stroke>","AUTO DELIVERY":"自动配送","AUTO RACE":"自动比赛","Auto Cruise":"自动巡航","Auto Garage":"自动车库","Auto Jobs":"自动工作","Auto Rewards":"自动领取奖励","Auto Story":"自动剧情任务","Auto Wheelie":"自动翘头","Best Purse":"最高奖金","Bike Mods":"摩托车改装","Bike Style":"摩托车风格","Blatant":"明显模式","Button":"按钮","Config":"配置","Crash Guard":"防撞保护","Crestline":"Crestline","Crestline, Side Street, Drag, Highway, GP, Lake, World, Small Circuit, Mountain":"Crestline、侧街、直线加速、高速公路、大奖赛、湖区、世界、小型赛道、山路","Custom":"自定义","DESELECT ALL":"取消全选","Delivery Mods":"配送设置","Drag":"直线加速","Drives your bike lap after lap along a race road outside a race for the game's riding pay, on the road itself (the road map plans each lap), or Sky Road while that is on. Crash Guard is on while it rides. With Auto Wheelie on it rides along in the wheelie; it gives the bike up to a delivery, race or story step and comes back after.":"为赚取游戏的骑行报酬，在非比赛状态沿赛道路段循环骑行，可在实际道路上行驶（道路地图会规划每一圈），也可在开启“空中道路”时使用空中道路。骑行期间开启防撞保护。开启自动翘头时会保持翘头骑行；配送、比赛或剧情步骤需要摩托车时会让出控制，结束后继续巡航。","ESP":"透视","Enable Auto Delivery":"开启自动配送","Enable Auto Race":"开启自动比赛","FARMING":"自动刷取","Fast":"快速","Finish Wheelie Missions":"完成翘头任务","Flat Out":"全速","GARAGE":"车库","GP":"大奖赛（GP）","Guide":"指南","Highway":"高速公路","Lake":"湖区","Local Run":"短途","Long Haul":"长途","Longest Loop":"最长环线","MODS":"修改","MOVEMENT":"移动","Most RM Per Minute":"每分钟 RM 收益最高","Mountain":"山路","Movement":"移动","None":"无","Preset":"预设","REWARDS":"奖励","ROADS":"道路","Race":"比赛","Race Road":"比赛道路","Race Speed":"比赛速度","Races":"赛事","Reroute When Lost":"迷路时重新规划路线","Reroute When Lost, Crash Guard":"迷路时重新规划路线、防撞保护","Restore Defaults":"恢复默认","Return When Flipped":"翻车时返回路线","Return When Floating":"漂浮时返回路线","Return When Off Road":"偏离道路时返回路线","Ride Assist":"骑行辅助","Ride Speed":"骑行速度","Route":"路线","SEARCH":"搜索","SELECTED ALL":"已全选","SETTINGS":"设置","Safe":"保守模式","Settings":"设置","Side Street":"侧街","Sky Road":"空中道路","Small Circuit":"小型赛道","Standard":"标准","Standard, Long Haul, Local Run":"标准、长途、短途","Status":"状态","Steady":"平稳","Teleport When Stuck":"卡住时传送","Themes":"主题","Tiers":"等级","Track Pick":"赛道选择","VISUALS":"视觉","World":"世界","[IDLE]":"[空闲]"}}]]
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
