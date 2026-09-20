-- Steal an Egg 中文外置加载器
-- 用法：loadstring(game:HttpGet("你的 clover.lua 原始链接"))()

local ORIGINAL_URL = "https://raw.githubusercontent.com/ojiasa/Steal-an-egg/main/main.lua"

local function httpGet(url)
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(source) == "string" and #source > 100 then
        return source
    end
    return nil
end

local source = httpGet(ORIGINAL_URL) or httpGet(FALLBACK_URL)
if not source then
    warn("[汉化] 无法下载原脚本，请检查网络或源地址")
    return
end

local originalLoader = loadstring(source, "=StealAnEgg-original")
if not originalLoader then
    warn("[汉化] 原脚本加载失败：loadstring 编译错误")
    return
end

local ok, err = pcall(originalLoader)
if not ok then
    warn("[汉化] 原脚本执行失败：" .. tostring(err))
    return
end

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local translations = {
    ["STEAL AN EGG HUB"] = "偷蛋助手",
    ["STEAL AN EGG HUB "] = "偷蛋助手 ",
    ["Main"] = "主页",
    ["Pet"] = "宠物",
    ["ESP"] = "透视",
    ["Egg"] = "蛋",
    ["Select Map"] = "选择地图",
    ["Steal Best Egg (value m)"] = "优先偷高价蛋（单位：百万）",
    ["Auto Steal Big Egg"] = "自动偷大蛋",
    ["Auto Steal Egg"] = "自动偷蛋",
    ["Anti Treadmill"] = "防跑步机",
    ["🐾 PET MANAGER"] = "🐾 宠物管理",
    ["Auto Sell Pet All"] = "自动出售全部宠物",
    ["⚠ BẬT SẼ SELL TOÀN BỘ PET TRONG TÚI!"] = "⚠ 开启后会出售背包里的全部宠物！",
    ["Auto Equip Best Pet"] = "自动装备最佳宠物",
    ["ESP Egg"] = "蛋透视",
    ["🥚 EGG MANAGER"] = "🥚 蛋管理",
    ["Auto Hatch Egg"] = "自动孵化蛋",
    ["Auto Place Egg"] = "自动放置蛋",
    ["⚠ Không tích hợp với Steal"] = "⚠ 不要与偷蛋功能同时开启",
    ["All Maps --"] = "全部地图 --",
}

local mapTranslations = {
    ["Forest"] = "森林",
    ["Lake"] = "湖泊",
    ["Desert"] = "沙漠",
    ["Jungle"] = "丛林",
    ["Snow"] = "雪地",
    ["Volcano"] = "火山",
    ["Abyss Ocean"] = "深渊海洋",
    ["Prehistoric"] = "史前",
    ["Cosmic"] = "宇宙",
    ["Cherry Blossom"] = "樱花",
    ["Titan Temple"] = "泰坦神庙",
    ["Light Dark"] = "光暗",
}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function translate(value)
    if type(value) ~= "string" or #value == 0 then
        return value
    end

    if translations[value] then
        return translations[value]
    end

    local count = value:match("^(%d+) Maps selected --$")
    if count then
        return "已选择 " .. count .. " 张地图 --"
    end

    local clean = trim(value)
    if mapTranslations[clean] then
        return value:gsub("^%s*", ""):gsub("^" .. clean, mapTranslations[clean], 1)
    end

    local mapName = clean:match("^(.-)%s+✓$")
    if mapName and mapTranslations[mapName] then
        return "  " .. mapTranslations[mapName] .. "  ✓"
    end

    return value
end

local function findUI()
    local gui = CoreGui:FindFirstChild("StealEggUI")
    if gui then
        return gui
    end

    local playerGui = player and player:FindFirstChild("PlayerGui")
    return playerGui and playerGui:FindFirstChild("StealEggUI") or nil
end

local ui = findUI()
local deadline = os.clock() + 10
while not ui and os.clock() < deadline do
    task.wait(0.1)
    ui = findUI()
end

if not ui then
    warn("[汉化] 未找到 StealEggUI，界面可能未创建或被拦截")
    return
end

local connected = {}

local function bindText(instance)
    if not instance:IsA("TextLabel") and not instance:IsA("TextButton") and not instance:IsA("TextBox") then
        return
    end
    if connected[instance] then
        return
    end
    connected[instance] = true

    instance.Text = translate(instance.Text)
    instance:GetPropertyChangedSignal("Text"):Connect(function()
        instance.Text = translate(instance.Text)
    end)
end

local function bindTree(root)
    for _, instance in ipairs(root:GetDescendants()) do
        bindText(instance)
    end
end

bindTree(ui)
ui.DescendantAdded:Connect(function(instance)
    task.defer(bindText, instance)
end)

print("[汉化] Steal an Egg 中文加载完成")
