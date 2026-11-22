-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua","translations":{"        Combat":"        战斗","        Config":"        配置","        Debug":"        调试","        Farming":"        采集","        Home":"        主页","        Planters":"        种植盆","        Quests":"        任务","        RBC":"        机器人熊挑战","        Toys":"        互动装置","        Webhook":"        Webhook 通知","       Blue Flower Field":"       蓝花田","       Dandelion Field":"       蒲公英田","       Mushroom Field":"       蘑菇田","       Sunflower Field":"       向日葵田","   Amulet Settings":"   护符设置","   Best Blue Field: Blue Flower Field":"   最佳蓝色花田：蓝花田","   Best Blue Mask: Diamond Mask":"   最佳蓝色面具：钻石面具","   Best Blue Tool: Tide Popper":"   最佳蓝色工具：潮汐波普","   Best Red Field: Mushroom Field":"   最佳红色花田：蘑菇田","   Best Red Mask: Demon Mask":"   最佳红色面具：恶魔面具","   Best Red Tool: Dark Scythe":"   最佳红色工具：暗黑镰刀","   Best White Field: Sunflower Field":"   最佳白色花田：向日葵田","   Best White Mask: Gummy Mask":"   最佳白色面具：软糖面具","   Best White Tool: Gummyballer":"   最佳白色工具：软糖球发射器","   Blue":"   蓝色","   Bubble Mask":"   泡泡面具","   Dark Scythe":"   暗黑镰刀","   Demon Mask":"   恶魔面具","   Diamond Mask":"   钻石面具","   Drives To Buy":"   要购买的驱动器","   Drives To Use":"   要使用的驱动器","   Equipment Settings":"   装备设置","   Fire Mask":"   火焰面具","   Goo Method: Gumdrops":"   黏液获取方式：软糖","   Gumdrops":"   软糖","   Gummy Mask":"   软糖面具","   Gummyballer":"   软糖球发射器","   Honey Mask":"   蜂蜜面具","   Maximum Rerolls":"   最大重抽次数","   Maximum Round":"   最高轮次","   Maximum Round For Cog Quest":"   齿轮任务最高轮次","   Minimum Level":"   最低等级","   Minimum Round":"   最低轮次","   Minimum Round For Reroll":"   允许重抽的最低轮次","   Passive":"   被动效果","   Petal Wand":"   花瓣魔杖","   Preset: Blue":"   预设：蓝色","   Purchase Cooldown (mins)":"   购买冷却时间（分钟）","   Quest Settings":"   任务设置","   Red":"   红色","   Robo Bear Challenge":"   机器人熊挑战","   Tide Popper":"   潮汐波普","   Upgrade Settings":"   升级设置","   White":"   白色","   ✓ Blue":"   ✓ 蓝色","   ✓ Glitched":"   ✓ 故障","   ✓ Red":"   ✓ 红色","   ✓ White":"   ✓ 白色","Allow Convert For Cogs":"允许为获取齿轮转化蜂蜜","Atlas Console":"Atlas 控制台","Atlas v1.0":"Atlas v1.0","Auto Buy Robo Pass":"自动购买机器人通行证","Auto Buy Upgrades":"自动购买升级","Auto Cog Amulet":"自动获取齿轮护符","Auto Equip Mask":"自动装备面具","Auto Equip Tool":"自动装备工具","Auto Homepage":"自动主页","Auto Keep Old":"自动保留旧护符","Auto RBC":"自动机器人熊挑战","Auto Use Materials":"自动使用材料","Button":"按钮","Buy Cog Upgrades":"购买齿轮升级","Choose Highest Cog Quest":"选择齿轮奖励最高的任务","Configure Amulet":"配置护符","Configure Materials":"配置材料","Configure Upgrades":"配置升级","Disable RBC After Round":"指定轮次后关闭自动挑战","Kill Gold Cogmowers":"击杀金色齿轮割草机","Maintain 10x Precision":"保持 10 层精准效果","Quit After Round":"指定轮次后退出","Reroll After Buying":"购买后重新抽取","Reroll Bees For Digital":"为数字蜜蜂重新抽取蜜蜂","Reroll If Hive Color Not Met":"蜂巢颜色条件未满足时重新抽取","Search":"搜索","Track Mobs":"追踪怪物"}}]]
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
