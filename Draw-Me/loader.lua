-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/xqmt/wow-mr-beashed/refs/heads/main/Draw%20me]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/xqmt/wow-mr-beashed/refs/heads/main/Draw%20me","translations":{".jpg .jpeg .png":".jpg .jpeg .png","Ashu Hub":"Ashu Hub","Autistic":"自闭","Brutal":"残酷","Don't upload any 18+ or NSFW images to the canvas. That includes all adult content. Doing so can get you banned.":"请勿向画布上传任何 18+ 或不宜公开展示的图片，包括所有成人内容，否则可能被封禁。","Draw":"绘制","Draw Me":"画我（Draw Me）","Funny 1":"搞笑 1","Funny 2":"搞笑 2","Funny 3":"搞笑 3","Headshot 1":"头像 1","Headshot 2":"头像 2","How to get URL ?":"如何获取图片链接？","Image URL":"图片链接","Info":"说明","Locked":"已锁定","Mogged 1":"颜值碾压 1","Mogged 2":"颜值碾压 2","Netanyahu":"内塔尼亚胡","Open Main UI":"打开主界面","Presets":"预设","Quick Presets":"快捷预设","Ronaldo Gang":"C 罗帮","Shut up sub 5":"闭嘴吧，颜值不到 5 分的家伙","Support image types":"支持的图片格式","This tab is Empty":"此页面暂无内容","Upload":"上传","Use This Website  -  https://postimg.cc":"使用此网站  -  https://postimg.cc","Warning":"警告","drill gangster":"Drill 帮派成员","https://example.com/image.png":"https://example.com/image.png","icaNext02":"icaNext02","kirk":"kirk","linkmon99":"linkmon99","promo":"宣传","then i walk in":"然后我走了进来"}}]]
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
