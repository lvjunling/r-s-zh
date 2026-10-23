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
local UserInputService = game:GetService("UserInputService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local connections, originals = {}, {}
local active = true
local translations = {}
local panel, status, output
local exportPath = "gui_strings.json"
local selectedGui
local refreshCollection
local picking = false
local roots = {}
local function belongsToTarget(obj)
    return selectedGui ~= nil and selectedGui.Parent ~= nil and (obj == selectedGui or obj:IsDescendantOf(selectedGui))
end

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
    frame.Size = UDim2.new(0.9, 0, 0.65, 0)
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
    title.Text = "先点“点选界面”，再点击目标窗口的标题栏"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 14
    title.TextWrapped = true
    title.Parent = frame
    status = title
    output = Instance.new("TextBox")
    output.Size = UDim2.new(1, -16, 1, -126)
    output.Position = UDim2.fromOffset(8, 34)
    output.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    output.TextColor3 = Color3.new(1, 1, 1)
    output.TextSize = 13
    output.TextXAlignment = Enum.TextXAlignment.Left
    output.TextYAlignment = Enum.TextYAlignment.Top
    output.MultiLine = true
    output.ClearTextOnFocus = false
    output.TextEditable = false
    output.Text = "先选择脚本界面；刷新会清空历史记录并重新扫描当前界面。"
    output.Parent = frame
    local function button(text, x, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.32, -4, 0, 36)
        btn.Position = UDim2.new(x, 8, 1, y)
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        btn.Text = text
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(55, 85, 140)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Parent = frame
        track(btn.Activated:Connect(callback))
        return btn
    end
    button("点选界面", 0, -82, function()
        picking = true
        report("请点击目标窗口标题栏或空白区域；按 Esc 取消")
        panel.Enabled = false
    end)
    button("刷新采集", 0.33, -82, function() refreshCollection() end)
    button("复制 JSON", 0.66, -82, function()
        if not selectedGui or not selectedGui.Parent then report("请先选择脚本界面") return end
        local json, count = snapshot()
        output.Text = json
        if type(setclipboard) == "function" then
            local copied, err = pcall(setclipboard, json)
            report(copied and ("已复制 " .. count .. " 条文字的 JSON") or ("复制失败：" .. tostring(err)))
        else
            output.TextEditable = true
            output:CaptureFocus()
            output.CursorPosition = #json + 1
            output.SelectionStart = 1
            report("执行器缺少剪贴板接口，已选中 JSON，请手动复制")
        end
    end)
    button("导出 JSON", 0, -42, function()
        if not selectedGui or not selectedGui.Parent then report("请先选择脚本界面") return end
        local json, count = snapshot()
        output.Text = json
        local saved = type(writefile) == "function" and pcall(writefile, exportPath, json)
        report(string.format("已采集 %d 条；文件：%s", count, saved and exportPath or "未保存，请使用复制按钮"))
    end)
    button("收起/展开", 0.33, -42, function()
        output.Visible = not output.Visible
        frame.Size = output.Visible and UDim2.new(0.9, 0, 0.65, 0) or UDim2.new(0.9, 0, 0, 126)
    end)
    button("结束采集", 0.66, -42, function()
        active = false
        for _, connection in ipairs(connections) do connection:Disconnect() end
        panel:Destroy()
    end)
end

local hooked = setmetatable({}, { __mode = "k" })
local function hook(obj)
    if not active or hooked[obj] or (panel and obj:IsDescendantOf(panel)) then return end
    if SETTINGS.mode == "collect" and not belongsToTarget(obj) then return end
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
        if SETTINGS.mode == "collect" and not belongsToTarget(obj) then return end
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

roots = { playerGui }
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
            track(root.DescendantAdded:Connect(function(obj) task.defer(hook, obj) end))
        end)
    end
end

refreshCollection = function()
    if not selectedGui or not selectedGui.Parent then report("请先选择脚本界面") return end
    originals = {}
    local objects = selectedGui:GetDescendants()
    table.insert(objects, selectedGui)
    for _, obj in ipairs(objects) do
        -- 重扫时直接读取当前值，已有控件继续使用原连接。
        local property = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and "Text"
            or (obj:IsA("TextBox") and "PlaceholderText")
        if property then
            local text = obj[property]
            if text ~= "" and text:find("%S") then originals[text] = true end
            hook(obj)
        end
    end
    local json, count = snapshot()
    output.Text = json
    report(string.format("目标：%s；已刷新 %d 条", selectedGui.Name, count))
end

-- 选择点击对象所属的最外层窗口分支，支持已有 ScreenGui 和隐藏容器。
local function windowFor(obj)
    if panel and (obj == panel or obj:IsDescendantOf(panel)) then return nil end
    local window = obj
    while window.Parent and window.Parent:IsA("GuiObject") do
        window = window.Parent
    end
    return window:IsA("GuiObject") and window or nil
end

local function visibleAt(obj, point)
    if not obj:IsA("GuiObject") then return false end
    local position, size = obj.AbsolutePosition, obj.AbsoluteSize
    if point.X < position.X or point.Y < position.Y
        or point.X >= position.X + size.X or point.Y >= position.Y + size.Y then return false end
    local ancestor = obj
    while ancestor do
        if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
        if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
        ancestor = ancestor.Parent
    end
    return true
end

local function pickWindow(point)
    for index = #roots, 1, -1 do
        local root = roots[index]
        local ok, hits = pcall(function()
            return root:GetGuiObjectsAtPosition(point.X, point.Y)
        end)
        if not ok then
            -- gethui 可能返回 Folder，使用其可见控件矩形作为回退。
            hits = {}
            pcall(function()
                for _, obj in ipairs(root:GetDescendants()) do
                    if visibleAt(obj, point) then hits[#hits + 1] = obj end
                end
            end)
            table.sort(hits, function(a, b) return a.ZIndex > b.ZIndex end)
        end
        for _, obj in ipairs(hits) do
            local window = windowFor(obj)
            if window then return window end
        end
    end
end

if SETTINGS.mode == "collect" then
    track(UserInputService.InputBegan:Connect(function(input)
        if not picking then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            picking = false
            panel.Enabled = true
            report("已取消点选")
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local point = input.UserInputType == Enum.UserInputType.Touch
            and Vector2.new(input.Position.X, input.Position.Y) or UserInputService:GetMouseLocation()
        local target = pickWindow(point)
        picking = false
        -- 等本次点击结束再显示采集面板，避免挡住目标点击。
        task.defer(function()
            if not active then return end
            panel.Enabled = true
            if target then
                selectedGui = target
                refreshCollection()
                report("已选中：" .. target:GetFullName())
            else
                report("此位置没有可选界面，请重新点选窗口标题栏")
            end
        end)
    end))
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
        report("脚本已执行；请点击“点选界面”，然后点击目标窗口标题栏")
    end
end)
