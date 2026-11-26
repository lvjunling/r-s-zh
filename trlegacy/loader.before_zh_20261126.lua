-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://rbxscriptz.fun/RBXZ-HUB]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://rbxscriptz.fun/RBXZ-HUB","translations":{"AUTO FARM":"自动刷取","Acceleration":"加速度","Around The World":"环游世界","Auto Claim Rewards":"自动领取奖励","Auto Delivery":"自动配送","Auto Drive":"自动驾驶","Auto Reconnect":"自动重连","Auto unstuck - teleport":"自动脱困（传送）","BIKE":"摩托车","Beach":"海滩","Bike Modifications":"摩托车改装","Brake Power":"制动力","COPY":"复制","Codes":"兑换码","Crestline Circuit":"山脊赛道","Customization":"个性化设置","DISCORD":"DISCORD","Dealership":"车行","Dev Follow Bonus":"关注开发者奖励","Display Status":"显示状态","Drag Race":"直线加速赛","Every (Minutes)":"间隔（分钟）","FPS Boost":"帧率优化","Fly":"飞行","Fly Speed":"飞行速度","From 2€":"2 欧元起","GP Track":"大奖赛赛道","Grip":"抓地力","Helmet Shop":"头盔商店","Highway Race":"高速公路赛","LINK COPIED":"链接已复制","LOCATIONS":"地点","Label":"标签","Lake Race":"湖畔赛","Lean Speed":"侧倾速度","Light":"轻度","MISC":"杂项","Max Speed (km/h)":"最高速度（千米/小时）","Maximum":"最大","Medium":"中等","Min Speed (km/h)":"最低速度（千米/小时）","Missions":"任务","Mode":"模式","Mountain Race":"山地赛","New Server":"新服务器","No Clip":"穿墙","Notify Webhook":"Webhook 通知","OPEN":"打开","PREMIUM":"高级版","PREMIUM REQUIRED":"需要高级版","Paste webhook url here...":"在此粘贴 Webhook 地址…","Player ESP":"玩家透视","RBXScriptz":"RBXScriptz","RBXScriptz.fun":"RBXScriptz.fun","RBXZ":"RBXZ","REQUIRES PREMIUM ACCESS":"需要高级版权限","Range":"范围","Rejoin":"重新加入","Requires Auto Execute on Executor":"需要执行器支持自动执行","Ride":"骑行","Ride2":"骑行 2","Route":"路线","Same Server":"当前服务器","Search...":"搜索…","Send Report Now":"立即发送报告","Session Report":"本次运行报告","Set Speed":"设置速度","Settings":"设置","Side Street":"侧街","Skybox Changer":"天空盒更换","Small Circuit":"小型赛道","Speed (km/h)":"速度（千米/小时）","Speed Mode":"速度模式","Start from Dealership":"从车行出发","Steering":"转向","TELEPORT":"传送","TR LEGACY PRO":"TR LEGACY PRO","Take fragile deliveries":"接取易碎品配送","Top Speed":"极速","Travel":"旅行","UNLOCK EVERYTHING":"解锁全部内容","Ultra":"极致","Universal":"通用","WEBHOOK":"消息推送","WEBSITE":"网站","WalkSpeed":"行走速度","Webhook URL":"Webhook 地址","Wheelies On Straights":"直道翘头","discord.gg/RBXZ":"discord.gg/RBXZ","rbxscriptz.fun":"rbxscriptz.fun","rbxscriptz.store":"rbxscriptz.store","—":"—"}}]]
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
