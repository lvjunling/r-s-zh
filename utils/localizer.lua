-- 采集地址可通过 getgenv().GUI_LOCALIZER_URL 传入，或编辑 script_url。
-- BEGIN GENERATED CONFIG
local SETTINGS = { script_url = "", mode = "collect" }
local EMBEDDED_JSON = nil
-- END GENERATED CONFIG

if SETTINGS.mode == "collect" then
    local environment = (getgenv and getgenv()) or _G
    SETTINGS.script_url = environment.GUI_LOCALIZER_URL or SETTINGS.script_url
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local connections, originals = {}, {}
local active = true
local translations = {}
local panel, status, output
local exportPath = "gui_strings.json"

if SETTINGS.mode == "translate" then
    local decoded = HttpService:JSONDecode(EMBEDDED_JSON)
    translations = decoded.translations
end

local function track(connection)
    connections[#connections + 1] = connection
    return connection
end

local function report(message)
    if status and status.Parent then status.Text = message end
    warn("[界面汉化工具] " .. message)
end

local function snapshot()
    local keys = {}
    for text in pairs(originals) do keys[#keys + 1] = text end
    table.sort(keys)
    local lines = {
        '{', '  "version": 1,',
        '  "script_url": ' .. HttpService:JSONEncode(SETTINGS.script_url) .. ',',
        '  "translations": {'
    }
    for index, text in ipairs(keys) do
        lines[#lines + 1] = "    " .. HttpService:JSONEncode(text) .. ': ""' .. (index < #keys and ',' or '')
    end
    lines[#lines + 1] = '  }'
    lines[#lines + 1] = '}'
    return table.concat(lines, '\n'), #keys
end

if SETTINGS.mode == "collect" then
    panel = Instance.new("ScreenGui")
    panel.Name = "GuiLocalizerCollector"
    panel.ResetOnSpawn = false
    panel.DisplayOrder = 10000
    panel.Parent = playerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0.55, 0)
    frame.Position = UDim2.fromScale(0.05, 0.05)
    frame.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
    frame.Parent = panel
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(620, 380)
    limit.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 30)
    title.Position = UDim2.fromOffset(8, 0)
    title.BackgroundTransparency = 1
    title.Text = "界面文字采集：展开原脚本各个菜单后导出"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 14
    title.TextWrapped = true
    title.Parent = frame
    status = title
    output = Instance.new("TextBox")
    output.Size = UDim2.new(1, -16, 1, -82)
    output.Position = UDim2.fromOffset(8, 34)
    output.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    output.TextColor3 = Color3.new(1, 1, 1)
    output.TextSize = 13
    output.TextXAlignment = Enum.TextXAlignment.Left
    output.TextYAlignment = Enum.TextYAlignment.Top
    output.MultiLine = true
    output.ClearTextOnFocus = false
    output.TextEditable = false
    output.Text = "导出后的 JSON 会显示在这里；也会尝试保存文件和复制到剪贴板。"
    output.Parent = frame
    local function button(text, x, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.32, -4, 0, 36)
        btn.Position = UDim2.new(x, 8, 1, -42)
        btn.Text = text
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(55, 85, 140)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Parent = frame
        track(btn.Activated:Connect(callback))
    end
    button("导出 JSON", 0, function()
        local json, count = snapshot()
        output.Text = json
        local saved = type(writefile) == "function" and pcall(writefile, exportPath, json)
        local copied = type(setclipboard) == "function" and pcall(setclipboard, json)
        report(string.format("已采集 %d 条；文件：%s；剪贴板：%s", count, saved and exportPath or "未保存", copied and "已复制" or "未复制"))
    end)
    button("收起/展开", 0.33, function()
        output.Visible = not output.Visible
        frame.Size = output.Visible and UDim2.new(0.9, 0, 0.55, 0) or UDim2.new(0.9, 0, 0, 82)
    end)
    button("结束采集", 0.66, function()
        active = false
        for _, connection in ipairs(connections) do connection:Disconnect() end
        panel:Destroy()
    end)
end

local hooked = setmetatable({}, { __mode = "k" })
local function hook(obj)
    if not active or hooked[obj] or (panel and obj:IsDescendantOf(panel)) then return end
    local property
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        property = "Text"
    elseif obj:IsA("TextBox") then
        -- 用户输入内容可能是密钥、用户名或搜索条件，仅处理占位提示。
        property = "PlaceholderText"
    else
        return
    end
    hooked[obj] = true
    local applying = false
    local function apply()
        if not active or applying then return end
        local text = obj[property]
        if text == "" or not text:find("%S") then return end
        if SETTINGS.mode == "collect" then
            originals[text] = true
        else
            local translated = translations[text]
            if type(translated) == "string" and translated ~= "" and translated ~= text then
                applying = true
                obj[property] = translated
                applying = false
            end
        end
    end
    apply()
    track(obj:GetPropertyChangedSignal(property):Connect(apply))
end

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
        -- 仅监听启动后新建的文字控件，不扫描现有游戏界面。
        pcall(function()
            track(root.DescendantAdded:Connect(function(obj) task.defer(hook, obj) end))
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

task.spawn(function()
    local success, err = pcall(function()
        local source = fetch(SETTINGS.script_url)
        assert(type(loadstring) == "function", "执行器缺少 loadstring")
        local fn, compileError = loadstring(source)
        assert(fn, compileError)
        fn()
    end)
    if not success then
        report("脚本运行出错：" .. tostring(err))
    elseif SETTINGS.mode == "collect" then
        report("脚本已执行；请展开菜单、切换选项，再点击导出 JSON")
    end
end)
