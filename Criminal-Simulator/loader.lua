-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://xain01.surge.sh/script.lua]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://xain01.surge.sh/script.lua","translations":{"$1,080":"$1,080","$1,200":"$1,200","$1,250":"$1,250","$1,400":"$1,400","$1,500":"$1,500","$1,600":"$1,600","$1,800":"$1,800","$100":"$100","$110":"$110","$120":"$120","$135":"$135","$140":"$140","$150":"$150","$160":"$160","$180":"$180","$2,000":"$2,000","$2,500":"$2,500","$200":"$200","$220":"$220","$230":"$230","$25":"$25","$250":"$250","$290":"$290","$30":"$30","$300":"$300","$310":"$310","$350":"$350","$370":"$370","$45":"$45","$450":"$450","$5":"$5","$5,000":"$5,000","$50":"$50","$500":"$500","$6,000":"$6,000","$60":"$60","$600":"$600","$65":"$65","$7,500":"$7,500","$70":"$70","$75":"$75","$750":"$750","$770":"$770","$800":"$800","$85":"$85","$850":"$850","$900":"$900","$95":"$95","$950":"$950","(M)OUSE":"鼠标模式 (M)","+":"+","AIM (J)":"瞄准 (J)","ALL":"全部","ESP  ·  zip":"透视  ·  ZIP","ESP  ·  zip  ·  aim":"透视  ·  ZIP  ·  瞄准","EXIT CAM":"退出视角","FLYJump (K)":"飞行跳跃 (K)","GodCAM (L)":"上帝视角 (L)","LINE":"连线","MENU":"菜单","NONE":"无","NPC":"NPC","RANGE  300 studs":"范围  300 格","X":"X","a(U)to ZIP":"自动 ZIP (U)","xain01. Hotkey: (H)ide, Es(P)":"xain01. 快捷键：隐藏 (H)，透视 (P)","−":"−","▢ AntiqueRifle":"▢ 古董步枪","▢ Bicycle":"▢ 自行车","▢ BigTV":"▢ 大电视","▢ CashBag":"▢ 现金袋","▢ Computer":"▢ 电脑","▢ FlatTV":"▢ 平板电视","▢ GamingPC":"▢ 游戏电脑","▢ Masterpiece":"▢ 艺术杰作","▢ Moped":"▢ 轻便摩托车","▢ Painting":"▢ 绘画作品","▢ RiotShield":"▢ 防暴盾牌","▢ SeizedCash":"▢ 查扣现金","▢ Stone":"▢ 石头","▢ Tire":"▢ 轮胎","▢ Vase":"▢ 花瓶","▢ WaterLilies":"▢ 睡莲","▣ $200 Gift Card":"▣ $200 礼品卡","▣ $50 Gift Card":"▣ $50 礼品卡","▣ $500 Gift Card":"▣ $500 礼品卡","▣ Binoculars":"▣ 双筒望远镜","▣ Black Card":"▣ 黑卡","▣ BoloTie":"▣ 波洛领带","▣ Camera":"▣ 相机","▣ Cash":"▣ 现金","▣ CashBox":"▣ 现金箱","▣ Debit Card":"▣ 借记卡","▣ DiamondNecklace":"▣ 钻石项链","▣ Drone":"▣ 无人机","▣ EspressoMachine":"▣ 意式咖啡机","▣ EvidenceJewels":"▣ 珠宝证物","▣ FabergeEgg":"▣ 法贝热彩蛋","▣ GameConsole":"▣ 游戏主机","▣ Gold Card":"▣ 金卡","▣ GoldBar":"▣ 金条","▣ GoldDustPouch":"▣ 金粉袋","▣ GoldNugget":"▣ 金块","▣ Guitar":"▣ 吉他","▣ HairDryer":"▣ 吹风机","▣ Handbag":"▣ 手提包","▣ Headphones":"▣ 耳机","▣ JewelryBox":"▣ 珠宝盒","▣ Journal":"▣ 日记本","▣ LandDeed":"▣ 土地契约","▣ Laptop":"▣ 笔记本电脑","▣ LuxuryWatch":"▣ 奢华腕表","▣ Microwave":"▣ 微波炉","▣ Package":"▣ 包裹","▣ Perfume":"▣ 香水","▣ Phone":"▣ 手机","▣ Platinum Card":"▣ 白金卡","▣ PoliceBadge":"▣ 警徽","▣ PoliceRadio":"▣ 警用对讲机","▣ PowerDrill":"▣ 电钻","▣ RingBox":"▣ 戒指盒","▣ Silver Card":"▣ 银卡","▣ Silverware":"▣ 银器","▣ Skateboard":"▣ 滑板","▣ SmartWatch":"▣ 智能手表","▣ Sneakers":"▣ 运动鞋","▣ Speaker":"▣ 音箱","▣ StandMixer":"▣ 厨师机","▣ Sunglasses":"▣ 太阳镜","▣ Tablet":"▣ 平板电脑","▣ Tool":"▣ 工具","▣ Toolbox":"▣ 工具箱","▣ TurquoiseRing":"▣ 绿松石戒指","▣ Typewriter":"▣ 打字机","▣ VinylRecords":"▣ 黑胶唱片","▣ Wallet":"▣ 钱包","▣ Watch":"▣ 手表","▣ WineBottle":"▣ 葡萄酒瓶","▲":"▲","▶":"▶","▼":"▼","◀":"◀"}}]]
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
