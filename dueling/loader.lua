-- 简体中文界面翻译加载器
-- BEGIN GENERATED CONFIG
local SCRIPT_URL = [[https://raw.githubusercontent.com/abobby1234589-gif/aaaaaaaaaaaaaa/refs/heads/main/Dueling]]
local EMBEDDED_JSON = [[{"version":1,"script_url":"https://raw.githubusercontent.com/abobby1234589-gif/aaaaaaaaaaaaaa/refs/heads/main/Dueling","translations":{"Apply Now":"立即应用","Apply Skin":"应用皮肤","Auto Parry":"自动招架","Auto Parry Key":"自动招架快捷键","Auto Parry, God Mode and a client-side skin changer.":"自动招架、无敌模式和客户端换肤。","BoStaff":"长棍","BoStaff Skin":"长棍皮肤","Client-side only: swaps the equipped weapon model to the chosen skin and re-applies it whenever the weapon remounts. The server never sees it, so locked skins work too.":"仅在客户端生效：将已装备武器的模型替换为所选皮肤，并在武器重新装载时自动应用。服务器不会同步此变化，因此也可在本地显示未解锁皮肤。","Combat":"战斗","Cosmetics":"外观","Current Skin":"当前皮肤","CurvedBlades Skin":"双曲刃皮肤","Daggers Skin":"匕首皮肤","DefaultBoStaff":"默认长棍","DefaultCurvedBlades":"默认双曲刃","DefaultDaggers":"默认匕首","DefaultGauntlets":"默认拳套","DefaultKatana":"默认武士刀","DefaultKusarigama":"默认锁镰","DefaultNaginata":"默认薙刀","DefaultWarhammer":"默认战锤","Dueling Grounds":"决斗场","Equip Weapon":"装备武器","Equipped: None | Skin: None":"已装备：无 | 皮肤：无","Every incoming impact resolves as a dodge on your client, and the server accepts the result, so you take no damage.":"在客户端将每次受到的攻击判定为闪避，并由服务器接受该结果，从而免受伤害。","G":"G","Gauntlets Skin":"拳套皮肤","God Mode":"无敌模式","God Mode Key":"无敌模式快捷键","H":"H","Katana Skin":"武士刀皮肤","Keybind used to open and close this menu.":"用于打开或关闭此菜单的快捷键。","Kusarigama Skin":"锁镰皮肤","Locked":"未解锁","Misc":"杂项","Naginata Skin":"薙刀皮肤","Parried: 0 | Dodged: 0 | Missed: 0":"招架：0 | 闪避：0 | 漏防：0","Parry Chance":"招架概率","Parry Notifications":"招架通知","Percentage of incoming impacts the auto parry actually parries. Below 100 it rolls each hit, so it keeps looking human.":"自动招架实际生效的攻击比例。低于 100% 时，每次攻击独立随机判定，使表现更接近人工操作。","Press to toggle auto parry on and off.":"按此快捷键开启或关闭自动招架。","Press to toggle god mode on and off.":"按此快捷键开启或关闭无敌模式。","Preview any BoStaff skin client-side. Applies when a BoStaff is equipped.":"在客户端预览任意长棍皮肤，装备长棍后生效。","Preview any CurvedBlades skin client-side. Applies when a CurvedBlades is equipped.":"在客户端预览任意双曲刃皮肤，装备双曲刃后生效。","Preview any Daggers skin client-side. Applies when a Daggers is equipped.":"在客户端预览任意匕首皮肤，装备匕首后生效。","Preview any Gauntlets skin client-side. Applies when a Gauntlets is equipped.":"在客户端预览任意拳套皮肤，装备拳套后生效。","Preview any Katana skin client-side. Applies when a Katana is equipped.":"在客户端预览任意武士刀皮肤，装备武士刀后生效。","Preview any Kusarigama skin client-side. Applies when a Kusarigama is equipped.":"在客户端预览任意锁镰皮肤，装备锁镰后生效。","Preview any Naginata skin client-side. Applies when a Naginata is equipped.":"在客户端预览任意薙刀皮肤，装备薙刀后生效。","Preview any Warhammer skin client-side. Applies when a Warhammer is equipped.":"在客户端预览任意战锤皮肤，装备战锤后生效。","Reset Counter":"重置计数","Resolves every incoming impact as a parry. The game decides hit outcomes on your client, so this uses its own resolver instead of faking packets.":"将每次受到的攻击判定为招架。游戏在客户端计算命中结果，因此使用游戏自身的判定逻辑，而非伪造数据包。","RightShift":"右 Shift 键","Sends the game's own Request_SetCurrentWeapon. Server validated, only weapons you own will actually equip.":"发送游戏自身的 Request_SetCurrentWeapon 请求。服务器会进行验证，实际仅可装备你已拥有的武器。","Session":"本次运行","Shows a notification for every parried impact.":"每次成功招架时显示通知。","This tab is Empty":"此标签页暂无内容","Toggle Menu":"显示／隐藏菜单","Unload Script":"卸载脚本","Warhammer Skin":"战锤皮肤","icaNext02":"icaNext02"}}]]
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
