local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

pcall(function()
    if CoreGui:FindFirstChild("ERDEVA_HUB") then
        CoreGui:FindFirstChild("ERDEVA_HUB"):Destroy()
    end
end)

local LogoAssetId = nil -- 使用文字图标，避免外部图片请求

local C = {
    Bg = Color3.fromRGB(13, 14, 18),
    Top = Color3.fromRGB(18, 20, 26),
    TabBg = Color3.fromRGB(16, 18, 24),
    Card = Color3.fromRGB(20, 23, 31),
    CardHover = Color3.fromRGB(26, 30, 42),
    Red = Color3.fromRGB(235, 45, 65),
    RedGlow = Color3.fromRGB(255, 60, 80),
    Txt = Color3.fromRGB(245, 245, 250),
    Sub = Color3.fromRGB(135, 142, 160),
    Border = Color3.fromRGB(32, 36, 48),
    Off = Color3.fromRGB(36, 40, 54),
    Green = Color3.fromRGB(46, 204, 113)
}

local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function Notify(title, desc, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = desc,
            Duration = duration or 4
        })
    end)
end

RunService.Stepped:Connect(function()
    pcall(function()
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

pcall(function()
    local GC = getconnections or get_signal_cons
    if GC then
        for _, conn in ipairs(GC(player.Idled)) do
            if conn.Disable then
                conn:Disable()
            elseif conn.Disconnect then
                conn:Disconnect()
            end
        end
    end
end)

local function SafeCall(remoteName, ...)
    local r = rs:FindFirstChild(remoteName, true)
    if not r then
        return false
    end
    local args = {...}
    local ok = pcall(function()
        if r:IsA("RemoteFunction") then
            r:InvokeServer(table.unpack(args))
        elseif r:IsA("RemoteEvent") then
            r:FireServer(table.unpack(args))
        end
    end)
    return ok
end

local function ClickGuiButton(btn)
    if not btn or not btn.Parent then
        return false
    end
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
                if type(c) == "table" and type(c.Fire) == "function" then
                    c:Fire()
                end
            end
            for _, c in ipairs(getconnections(btn.Activated)) do
                if type(c) == "table" and type(c.Fire) == "function" then
                    c:Fire()
                end
            end
        end
        if firesignal then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
        end
    end)
    return true
end

local function ButtonText(btn)
    if not btn then
        return ""
    end
    local full = ((btn:IsA("TextButton") and btn.Text) or "") .. " " .. btn.Name
    for _, child in ipairs(btn:GetDescendants()) do
        if child:IsA("TextLabel") then
            full = full .. " " .. child.Text
        end
    end
    return full:lower()
end

local function IsVisibleGui(obj)
    if not obj:IsA("GuiObject") or not obj.Visible then
        return false
    end
    local cur = obj.Parent
    while cur and cur:IsA("GuiObject") do
        if not cur.Visible then
            return false
        end
        cur = cur.Parent
    end
    return true
end

local GuiCooldowns = {}
local function TryClickGuiAction(actionName, patterns, cooldown)
    local now = tick()
    if GuiCooldowns[actionName] and now - GuiCooldowns[actionName] < (cooldown or 1.0) then
        return false
    end
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then
        return false
    end
    for _, b in ipairs(pg:GetDescendants()) do
        if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
            local text = ButtonText(b)
            for _, pat in ipairs(patterns) do
                if text:find(pat) then
                    GuiCooldowns[actionName] = now
                    return ClickGuiButton(b)
                end
            end
        end
    end
    return false
end

local function DismissPopups()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then
        return false
    end
    local clicked = false
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("GuiObject") and IsVisibleGui(gui) then
            local text = (gui:IsA("TextLabel") and gui.Text:lower()) or ""
            local name = gui.Name:lower()
            if text:find("not enough") or name:find("notenoughcash") or text:find("insufficient") then
                local container = gui.Parent
                while container and container ~= pg do
                    for _, b in ipairs(container:GetDescendants()) do
                        if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
                            local bt = ButtonText(b)
                            if bt:find("x") or bt:find("close") or b.Name:lower() == "x" or b.Name:lower() == "close" then
                                clicked = ClickGuiButton(b) or clicked
                            end
                        end
                    end
                    container = container.Parent
                end
            end
        end
    end
    return clicked
end

local function DismissArenaResults()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then
        return false
    end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") and IsVisibleGui(obj) then
            local t = obj.Text:lower()
            if t:find("defeated") or t:find("victory") or t:find("trophies") then
                local cur = obj.Parent
                while cur and cur ~= pg do
                    for _, b in ipairs(cur:GetDescendants()) do
                        if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
                            ClickGuiButton(b)
                            return true
                        end
                    end
                    if cur:IsA("GuiButton") and IsVisibleGui(cur) then
                        ClickGuiButton(cur)
                        return true
                    end
                    cur = cur.Parent
                end
            end
        end
    end
    return false
end

local function TriggerFrontierFloorSequence()
    task.spawn(function()
        task.wait(0.15)
        local t0 = tick()
        local detectedFloor = nil
        local cam = workspace.CurrentCamera

        while tick() - t0 < 2.0 and not detectedFloor do
            local pg = player:FindFirstChild("PlayerGui")
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)

            if pg then
                for _, obj in ipairs(pg:GetDescendants()) do
                    if obj:IsA("TextLabel") and IsVisibleGui(obj) then
                        local pos = obj.AbsolutePosition
                        local size = obj.AbsoluteSize
                        local onScreen = pos.X >= -10 and pos.Y >= -10 and (pos.X + size.X) <= (vp.X + 100) and
                                             (pos.Y + size.Y) <= (vp.Y + 100) and size.X > 20 and size.Y > 10

                        if onScreen then
                            local t = obj.Text:lower()
                            if t:find("straight") and t:find("frontier") then
                                local num = tonumber(t:match("floor%s*(%d+)"))
                                if not num and obj.Parent then
                                    for _, sib in ipairs(obj.Parent:GetDescendants()) do
                                        if sib:IsA("TextLabel") and IsVisibleGui(sib) then
                                            local st = sib.Text:lower()
                                            if not st:find("k") and not st:find("m") and not st:find("b") then
                                                local n = tonumber(st:match("floor%s*(%d+)")) or
                                                              tonumber(st:match("(%d+)"))
                                                if n and n >= 5 then
                                                    num = n
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if num and num > 0 then
                                    detectedFloor = num
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if not detectedFloor then
                task.wait(0.05)
            end
        end

        if detectedFloor then
            local rem = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("TowerElevator")
            if not rem then
                rem = rs:FindFirstChild("TowerElevator", true)
            end

            if rem then
                Notify("ERDEVA HUB", "楼层 " .. tostring(detectedFloor) .. " 已选择", 2.5)
                for _ = 1, 5 do
                    task.spawn(function()
                        pcall(function()
                            if rem:IsA("RemoteFunction") then
                                rem:InvokeServer(detectedFloor)
                            elseif rem:IsA("RemoteEvent") then
                                rem:FireServer(detectedFloor)
                            end
                        end)
                    end)
                    task.wait(0.15)
                end
            end
        end
    end)
end

local StartMainScript

StartMainScript = function()
    local IsRunning = true
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
    local W = math.min(445, math.max(320, viewport.X - 20))
    local H = math.min(285, math.max(240, viewport.Y - 40))

    Notify("ERDEVA HUB", "脚本已加载", 4)

    local Flags = {
        AutoTakeEggs = false,
        AutoOpenEggs = false,
        AutoGrabScraps = false,
        AutoRecycleScrap = false,
        AutoUpgradeRecycler = false,
        ScrapCapacity = 20,
        AutoRebirth = false,
        AutoUpgradeCoop = false,
        AutoUpgradeFeeder = false,
        AutoBuyFeeders = false,
        AutoStartTower = false,
        AutoArena = false,
        AutoNoThanks = false,
        AutoBypassPopups = false,
        AutoStartChaos = false,
        AutoUFO = false,
        AutoAncientEgg = false,
        AutoJurassicPass = false,
        AutoSellChickens = false,
        VisualName = true,
        SellCommon = true,
        SellUncommon = true,
        SellRare = true,
        SellEpic = false,
        SellLegendary = false,
        SellMythic = false,
        SellCosmic = false,
        SellSecret = false
    }

    local LOCKED_RECYCLER_POS = nil
    local ToggleUpdaters = {}
    local CurrentBatchScraps = 0
    local ChickenInTower = false
    local ChickenInArena = false
    local TowerSentTime = 0
    local ArenaSentTime = 0
    local LastTowerFinishedAt = tick()
    local ChickenInPitUntil = 0

    local function GetChar()
        return player.Character
    end
    local function GetRoot()
        local c = GetChar()
        return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
    end
    local function GetHumanoid()
        local c = GetChar()
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    local ActionCooldowns = {}
    local function CanRunAction(action, cooldown)
        local now = tick()
        if ActionCooldowns[action] and now - ActionCooldowns[action] < cooldown then
            return false
        end
        ActionCooldowns[action] = now
        return true
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        CurrentBatchScraps = 0
        ChickenInTower = false
        ChickenInArena = false
        TowerSentTime = 0
        ArenaSentTime = 0
        ChickenInPitUntil = 0
    end)

    local function IsOurEvent(...)
        local args = {...}
        if #args == 0 then
            return true
        end
        local first = args[1]
        if typeof(first) == "Instance" then
            if first == player or first == player.Character then
                return true
            end
            if first:IsDescendantOf(player) or (player.Character and first:IsDescendantOf(player.Character)) then
                return true
            end
            return false
        elseif type(first) == "string" then
            if first == player.Name or first == tostring(player.UserId) then
                return true
            end
            return false
        elseif type(first) == "number" then
            if first == player.UserId then
                return true
            end
            return false
        elseif type(first) == "table" then
            if first.Player == player or first.UserId == player.UserId or first.Name == player.Name or first.Username ==
                player.Name then
                return true
            end
            for _, v in pairs(first) do
                if v == player or v == player.Name or v == player.UserId then
                    return true
                end
            end
            return false
        end
        return true
    end

    local function BindCombatListener(remoteName, callback)
        local r = rs:FindFirstChild(remoteName, true)
        if r and r:IsA("RemoteEvent") then
            pcall(function()
                r.OnClientEvent:Connect(function(...)
                    if IsOurEvent(...) then
                        callback(...)
                    end
                end)
            end)
        end
    end

    BindCombatListener("BattleStarted", function()
        ChickenInArena = true;
        ArenaSentTime = tick()
    end)
    BindCombatListener("BattleEnded", function()
        ChickenInArena = false;
        ArenaSentTime = 0
    end)
    BindCombatListener("TowerRunStarted", function()
        ChickenInTower = true;
        TowerSentTime = tick()
    end)
    BindCombatListener("TowerRunEnded", function()
        ChickenInTower = false;
        LastTowerFinishedAt = tick()
    end)
    BindCombatListener("TowerDefeat", function()
        ChickenInTower = false;
        LastTowerFinishedAt = tick()
    end)

    local function FlatDist(a, b)
        return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
    end

    local function FastTouch(part)
        local root = GetRoot()
        if not root or not part or not part:IsA("BasePart") then
            return
        end
        if firetouchinterest then
            firetouchinterest(root, part, 0)
            task.wait(0.02)
            firetouchinterest(root, part, 1)
        end
    end

    local function TriggerPrompt(prompt)
        if not prompt or not prompt.Parent then
            return false
        end
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait((prompt.HoldDuration or 0) + 0.02)
                prompt:InputHoldEnd()
            end
        end)
        return true
    end

    local function TriggerNearbyPrompt(keyword, radius)
        local root = GetRoot()
        if not root then
            return false
        end
        keyword = keyword and keyword:lower() or nil
        radius = radius or 16
        local best, bestDist = nil, radius
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local part = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or
                                 obj:FindFirstAncestorWhichIsA("BasePart")
                if part then
                    local text =
                        (obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. part.Name):lower()
                    local d = (root.Position - part.Position).Magnitude
                    if d <= bestDist and (not keyword or text:find(keyword)) then
                        best = obj
                        bestDist = d
                    end
                end
            end
        end
        if best then
            return TriggerPrompt(best)
        end
        return false
    end

    local function WalkTo(targetPos, timeout, stopDist)
        if not IsRunning then
            return false
        end
        local hum = GetHumanoid()
        local root = GetRoot()
        if not hum or not root then
            return false
        end
        stopDist = stopDist or 4.5
        timeout = timeout or 3.5
        local t0 = tick()
        local char = GetChar()
        local lastPos = root.Position
        local stuckCounter = 0

        while IsRunning and tick() - t0 < timeout do
            if GetChar() ~= char then
                return false
            end
            hum = GetHumanoid()
            root = GetRoot()
            if not hum or not root or hum.Health <= 0 then
                return false
            end
            if FlatDist(root.Position, targetPos) <= stopDist then
                return true
            end

            hum:MoveTo(targetPos)
            task.wait(0.05)

            if FlatDist(root.Position, lastPos) < 0.25 then
                stuckCounter = stuckCounter + 1
                if stuckCounter >= 4 then
                    hum.Jump = true
                    stuckCounter = 0
                end
            else
                stuckCounter = 0
                lastPos = root.Position
            end
        end
        root = GetRoot()
        return root and FlatDist(root.Position, targetPos) <= (stopDist + 2.5)
    end

    local function SendChickenToPit(tag, holdDuration)
        if not CanRunAction("SendChicken_" .. (tag or "general"), 4.0) then
            return
        end
        local patterns = {"to chaos", "chaos", "pit", "enter chaos"}
        TryClickGuiAction("PitChaosBtn", patterns, 2.5)
        TriggerNearbyPrompt("chaos", 20)
        TriggerNearbyPrompt("pit", 20)
        ChickenInArena = true
        if holdDuration and holdDuration > 0 then
            ChickenInPitUntil = tick() + holdDuration
        end
    end

    local function IsRealScrap(obj)
        if not obj:IsA("BasePart") or not obj.Parent then
            return false
        end
        local char = GetChar()
        if char and obj:IsDescendantOf(char) then
            return false
        end
        local anc = obj:FindFirstAncestorOfClass("Model")
        if anc and anc:FindFirstChildOfClass("Humanoid") then
            return false
        end
        local n = obj.Name:lower()
        local pn = obj.Parent.Name:lower()
        local ppn = (obj.Parent.Parent and obj.Parent.Parent.Name:lower()) or ""
        if n:find("fence") or n:find("wall") or n:find("floor") or n:find("base") or n:find("spawn") or n:find("grass") or
            n:find("terrain") then
            return false
        end
        if n:find("recycler") or n:find("feeder") or n:find("coop") or n:find("incubator") or n:find("shop") or
            n:find("pad") or n:find("button") then
            return false
        end
        if pn:find("recycler") or pn:find("feeder") or pn:find("coop") or pn:find("incubator") or pn:find("shop") or
            pn:find("plot") then
            return false
        end
        if ppn:find("plot") or ppn:find("base") or ppn:find("feeder") or ppn:find("recycler") then
            return false
        end

        if n:find("scrap") or n:find("plate") or n:find("drop") or n:find("trash") or n:find("sheet") or
            n:find("debris") or n:find("alien") or n:find("coin") or n:find("gold") or n:find("meteor") or
            pn:find("scrap") or pn:find("plate") or pn:find("drop") or pn:find("drops") or pn:find("alien") or
            pn:find("coin") or pn:find("debris") then
            return true
        end
        return false
    end

    local BlacklistedScraps = {}
    local function CleanupScrapBlacklist()
        local now = tick()
        for scrap, t in pairs(BlacklistedScraps) do
            if typeof(scrap) ~= "Instance" or not scrap.Parent or now - t > 3.0 then
                BlacklistedScraps[scrap] = nil
            end
        end
    end

    local function FindNearestArenaScrap()
        CleanupScrapBlacklist()
        local root = GetRoot()
        if not root then
            return nil
        end
        local best, bestDist = nil, 9999
        local pitScrap = workspace:FindFirstChild("PitScrap") or workspace:FindFirstChild("Pit")
        if pitScrap then
            for _, obj in ipairs(pitScrap:GetDescendants()) do
                if obj:IsA("BasePart") and not BlacklistedScraps[obj] and obj.Parent then
                    local d = FlatDist(root.Position, obj.Position)
                    if d < 800 and d < bestDist then
                        best = obj
                        bestDist = d
                    end
                end
            end
        end
        if not best then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if IsRealScrap(obj) and not BlacklistedScraps[obj] then
                    local d = FlatDist(root.Position, obj.Position)
                    if d < 800 and d < bestDist then
                        best = obj
                        bestDist = d
                    end
                end
            end
        end
        return best
    end

    local function CollectScrapPlate(scrap)
        if not scrap or not scrap.Parent then
            return false
        end
        local root = GetRoot()
        if not root or not GetChar() then
            return false
        end

        FastTouch(scrap)
        WalkTo(scrap.Position, 2.0, 2.0)
        FastTouch(scrap)
        TriggerNearbyPrompt("scrap", 16)

        CurrentBatchScraps = CurrentBatchScraps + 1
        BlacklistedScraps[scrap] = tick()
        return true
    end

    local function FindBasePad(keywords)
        local root = GetRoot()
        if not root then
            return nil
        end
        local bestPart, bestPrompt, bestDist = nil, nil, 9999
        for _, obj in ipairs(workspace:GetDescendants()) do
            local targetPart, prompt, matched = nil, nil, false
            if obj:IsA("ProximityPrompt") then
                local part = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or
                                 obj:FindFirstAncestorWhichIsA("BasePart")
                if part then
                    local text =
                        (obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. part.Name):lower()
                    for _, kw in ipairs(keywords) do
                        if text:find(kw:lower()) then
                            matched = true
                            targetPart = part
                            prompt = obj
                            break
                        end
                    end
                end
            elseif obj:IsA("BasePart") then
                local name = obj.Name:lower()
                local pName = obj.Parent and obj.Parent.Name:lower() or ""
                for _, kw in ipairs(keywords) do
                    local kl = kw:lower()
                    if name:find(kl) or pName:find(kl) then
                        matched = true
                        targetPart = obj
                        prompt = obj:FindFirstChildOfClass("ProximityPrompt") or
                                     obj:FindFirstChildOfClass("ClickDetector")
                        break
                    end
                end
            end
            if matched and targetPart and targetPart:IsA("BasePart") then
                local d = (root.Position - targetPart.Position).Magnitude
                if d < 400 and d < bestDist then
                    bestDist = d
                    bestPart = targetPart
                    bestPrompt = prompt
                end
            end
        end
        if bestPart then
            return {
                part = bestPart,
                prompt = bestPrompt
            }
        end
        return nil
    end

    local function DoRecycleAtBase()
        if not CanRunAction("RecycleScrapAction", 1.8) then
            return false
        end
        local targetPos = LOCKED_RECYCLER_POS
        local pad = nil
        if not targetPos then
            pad = FindBasePad({"recycler", "recycle", "sell scrap", "convert", "deposit"})
            if pad and pad.part then
                targetPos = pad.part.Position
            end
        end
        if not targetPos then
            local recs = workspace:FindFirstChild("Recyclers")
            if recs then
                local root = GetRoot()
                local bestR, bestRD = nil, 9999
                for _, r in ipairs(recs:GetChildren()) do
                    local p = r:IsA("BasePart") and r or r:FindFirstChildWhichIsA("BasePart", true)
                    if p and root then
                        local d = (root.Position - p.Position).Magnitude
                        if d < bestRD then
                            bestR = p
                            bestRD = d
                        end
                    end
                end
                if bestR then
                    targetPos = bestR.Position
                end
            end
        end
        if not targetPos then
            return false
        end

        local arrived = WalkTo(targetPos, 4.0, 3.5)
        if pad and pad.part then
            FastTouch(pad.part)
        end
        TriggerNearbyPrompt("recycle", 16)
        TriggerNearbyPrompt("deposit", 16)
        TryClickGuiAction("RecycleDeposit", {"recycle", "sell scrap", "convert", "deposit", "empty"}, 0.8)
        SafeCall("UpgradeRecycler")
        task.wait(0.3)

        CurrentBatchScraps = 0
        table.clear(BlacklistedScraps)
        return true
    end

    local function ExecuteBasePad(actionName, keywords, guiPatterns, cooldown)
        if not CanRunAction(actionName, cooldown or 2.0) then
            return false
        end
        local pad = FindBasePad(keywords)
        if pad and pad.part then
            FastTouch(pad.part)
            if pad.prompt and pad.prompt:IsA("ProximityPrompt") then
                TriggerPrompt(pad.prompt)
            elseif pad.prompt and pad.prompt:IsA("ClickDetector") and fireclickdetector then
                pcall(function()
                    fireclickdetector(pad.prompt)
                end)
            else
                for _, kw in ipairs(keywords) do
                    TriggerNearbyPrompt(kw, 12)
                end
            end
        end
        if guiPatterns then
            TryClickGuiAction(actionName, guiPatterns, cooldown or 2.0)
        end
        return true
    end

    local function DoUpgrades()
        if Flags.AutoBuyFeeders then
            for slot = 1, 2 do
                SafeCall("BuyGenerator", slot)
                task.wait(0.1)
            end
            ExecuteBasePad("BuyFeeder", {"buy feeder", "new feeder", "feeder"}, {"buy feeder", "new feeder"}, 2.0)
        end
        if Flags.AutoUpgradeFeeder then
            for slot = 1, 2 do
                SafeCall("UpgradeGenerator", slot)
            end
            ExecuteBasePad("UpgradeFeeder", {"upgrade feeder", "feed speed", "speed upgrade"},
                {"upgrade feeder", "upgrade speed"}, 0.1)
        end
        if Flags.AutoUpgradeRecycler then
            SafeCall("UpgradeRecycler")
            ExecuteBasePad("UpgradeRecycler", {"upgrade recycler", "recycler speed", "recycler level"},
                {"upgrade recycler", "recycle speed"}, 2.5)
        end
        if Flags.AutoUpgradeCoop then
            SafeCall("ExpandCoop")
            ExecuteBasePad("UpgradeCoop", {"upgrade coop", "coop"}, {"upgrade coop"}, 2.5)
        end
        if Flags.AutoOpenEggs and CanRunAction("HatchMaxAction", 2.0) then
            SafeCall("HatchMaxEggs", "barn")
            TryClickGuiAction("OpenMaxAction", {"openmax", "open max"}, 1.5)
        end
    end

    local EggCollectCooldowns = setmetatable({}, {__mode = "k"})
    local CachedEggContainers = {}
    local LastEggContainerScan = 0

    local function GetEggContainers()
        local now = tick()
        local cacheValid = now - LastEggContainerScan < 5
        if cacheValid then
            for _, container in ipairs(CachedEggContainers) do
                if not container.Parent then
                    cacheValid = false
                    break
                end
            end
        end
        if cacheValid then
            return CachedEggContainers
        end

        local found = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower():gsub("[%s_-]", "")
            if (n == "nesteggs" or n == "incubators" or n == "incubator" or n == "nests") and
                (obj:IsA("Folder") or obj:IsA("Model")) then
                table.insert(found, obj)
            end
        end
        CachedEggContainers = found
        LastEggContainerScan = now
        return found
    end

    local function IsOwnNestEgg(nestEgg)
        local owner = nestEgg:GetAttribute("owner") or nestEgg:GetAttribute("Owner") or
                          nestEgg:GetAttribute("userId") or nestEgg:GetAttribute("UserId") or
                          nestEgg:GetAttribute("username") or nestEgg:GetAttribute("Username")

        if owner == nil then
            for _, valueName in ipairs({"owner", "Owner", "userId", "UserId", "username", "Username"}) do
                local valueObj = nestEgg:FindFirstChild(valueName, true)
                if valueObj and valueObj:IsA("ObjectValue") then
                    owner = valueObj.Value
                    break
                elseif valueObj and (valueObj:IsA("StringValue") or valueObj:IsA("IntValue") or
                    valueObj:IsA("NumberValue")) then
                    owner = valueObj.Value
                    break
                end
            end
        end

        if owner == nil then
            return true
        end
        if owner == player then
            return true
        end
        local ownerText = tostring(owner)
        return ownerText == player.Name or ownerText == player.DisplayName or ownerText == tostring(player.UserId)
    end

    local function CollectNestEgg(nestEgg, root)
        if not nestEgg or not nestEgg.Parent or not IsOwnNestEgg(nestEgg) then
            return false
        end

        local now = tick()
        if EggCollectCooldowns[nestEgg] and now - EggCollectCooldowns[nestEgg] < 1.0 then
            return false
        end
        EggCollectCooldowns[nestEgg] = now

        local eggId = nestEgg:GetAttribute("eggId") or nestEgg:GetAttribute("EggId") or
                          nestEgg:GetAttribute("id") or nestEgg:GetAttribute("Id")
        if eggId ~= nil then
            SafeCall("CollectNestEgg", eggId)
            SafeCall("ClaimNestEgg", eggId)
            SafeCall("CollectEgg", eggId)
            SafeCall("TakeEgg", eggId)
        end
        SafeCall("CollectNestEgg", nestEgg)
        SafeCall("ClaimNestEgg", nestEgg)

        local targetPart = nestEgg:IsA("BasePart") and nestEgg or nestEgg:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            FastTouch(targetPart)
        end

        for _, obj in ipairs(nestEgg:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                TriggerPrompt(obj)
            elseif obj:IsA("ClickDetector") and fireclickdetector then
                pcall(function()
                    fireclickdetector(obj)
                end)
            end
        end
        return true
    end

    local function RunAutoTakeEggs()
        if not CanRunAction("AutoTakeEggsAction", 1.0) then
            return
        end

        local root = GetRoot()
        if not root then
            return
        end

        -- 孵化器领取和巢穴鸡蛋是两套独立机制，两者都执行。
        SafeCall("IncubatorClaim")
        SafeCall("ClaimIncubator")

        local containers = GetEggContainers()
        for _, container in ipairs(containers) do
            for _, nestEgg in ipairs(container:GetChildren()) do
                CollectNestEgg(nestEgg, root)
            end

            -- 某些版本把交互提示直接放在容器的更深层级。
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local part = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or
                                     obj:FindFirstAncestorWhichIsA("BasePart")
                    local text = (obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name):lower()
                    if part and (root.Position - part.Position).Magnitude <= 120 and
                        (text:find("egg") or text:find("claim") or text:find("collect") or
                            text:find("take") or text:find("incubator")) then
                        TriggerPrompt(obj)
                    end
                end
            end
        end

        -- 保留界面按钮方式，适配仅通过 GUI 领取的游戏版本。
        TryClickGuiAction("TakeEggGui", {"claim egg", "collect egg", "take egg", "nest egg"}, 1.0)
    end

    local function RunEventCheck()
        if Flags.AutoUFO then
            local ufoActive = false
            if workspace:FindFirstChild("UfoShow") or workspace:FindFirstChild("Ufo") then
                ufoActive = true
            end
            local pg = player:FindFirstChild("PlayerGui")
            if not ufoActive and pg then
                local meter = pg:FindFirstChild("BlessingVsCurseMeter")
                if meter and meter.Enabled then
                    ufoActive = true
                end
            end
            if ufoActive then
                if tick() >= ChickenInPitUntil then
                    TryClickGuiAction("UfoChip", {"live-ufo"}, 2.0)
                    SendChickenToPit("UFO", 35)
                end
            end
        end
    end

    local function HasRebirthExclamationMark()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then
            return false
        end
        local rail = pg:FindFirstChild("ArenaSideRail")
        local railRebirth = rail and rail:FindFirstChild("Rebirth", true)
        if not railRebirth or not IsVisibleGui(railRebirth) then
            return false
        end

        for _, child in ipairs(railRebirth:GetDescendants()) do
            if child:IsA("TextLabel") and IsVisibleGui(child) and child.Text:find("!") then
                return true
            end
        end
        return false
    end

    local function CheckAndDoRebirth()
        if not HasRebirthExclamationMark() then
            return false
        end
        if not CanRunAction("ExecuteRebirthAction", 6.0) then
            return false
        end

        if ChickenInTower then
            SafeCall("TowerSurrender")
            ChickenInTower = false
            TowerSentTime = 0
            LastTowerFinishedAt = tick()
            task.wait(1.0)
        end

        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            local rail = pg:FindFirstChild("ArenaSideRail")
            local railRebirth = rail and rail:FindFirstChild("Rebirth", true)
            if railRebirth and IsVisibleGui(railRebirth) then
                ClickGuiButton(railRebirth)
                task.wait(0.3)
            end

            local rebirthGui = pg:FindFirstChild("Rebirth")
            local confirmBtn = rebirthGui and
                                   (rebirthGui:FindFirstChild("Rebirth", true) or
                                       rebirthGui:FindFirstChild("confirm", true))
            if confirmBtn then
                ClickGuiButton(confirmBtn)
            end
        end

        SafeCall("Rebirth")
        task.wait(0.3)
        TryClickGuiAction("RebirthConfirm", {"confirm", "yes", "do rebirth"}, 1.5)

        local pgAfter = player:FindFirstChild("PlayerGui")
        local rebirthGuiAfter = pgAfter and pgAfter:FindFirstChild("Rebirth")
        if rebirthGuiAfter then
            for _, b in ipairs(rebirthGuiAfter:GetDescendants()) do
                if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
                    local bt = ButtonText(b)
                    if bt:find("close") or bt:find("x") or b.Name:lower() == "x" or b.Name:lower() == "close" then
                        ClickGuiButton(b)
                        break
                    end
                end
            end
        end

        CurrentBatchScraps = 0
        table.clear(BlacklistedScraps)
        LastTowerFinishedAt = tick()
        return true
    end

    local ChickenDatabase = {}
    pcall(function()
        local cTypesMod = rs:FindFirstChild("Content") and rs.Content:FindFirstChild("Catalog") and
                              rs.Content.Catalog:FindFirstChild("ChickenTypes")

        if not cTypesMod then
            cTypesMod = rs:FindFirstChild("ChickenTypes", true)
        end

        if cTypesMod then
            local raw = require(cTypesMod)
            if type(raw) == "table" then
                for id, info in pairs(raw) do
                    if type(info) == "table" then
                        local rarity = tostring(info.Rarity or info.rarity or "common"):lower()
                        local displayName = tostring(info.Name or info.DisplayName or info.name or id):lower()
                        ChickenDatabase[displayName] = rarity
                        ChickenDatabase[tostring(id):lower()] = rarity
                    end
                end
            end
        end
    end)

    local function ShouldSellRarity(rStr)
        if not rStr then
            return false
        end
        rStr = rStr:lower()
        if rStr:find("common") and not rStr:find("uncommon") then
            return Flags.SellCommon
        end
        if rStr:find("uncommon") then
            return Flags.SellUncommon
        end
        if rStr:find("rare") then
            return Flags.SellRare
        end
        if rStr:find("epic") then
            return Flags.SellEpic
        end
        if rStr:find("legendary") then
            return Flags.SellLegendary
        end
        if rStr:find("mythic") or rStr:find("celestial") or rStr:find("divine") then
            return Flags.SellMythic
        end
        if rStr:find("cosmic") then
            return Flags.SellCosmic
        end
        if rStr:find("secret") then
            return Flags.SellSecret
        end
        return false
    end

    local function GetChickenRarity(chickenBtn)
        if not chickenBtn then
            return "common"
        end

        local nameLbl = chickenBtn:FindFirstChild("ChickenName", true)
        local rawName = nameLbl and nameLbl.Text:lower() or ""

        if ChickenDatabase[rawName] then
            return ChickenDatabase[rawName]
        end

        local buttonName = chickenBtn.Name:lower()
        if ChickenDatabase[buttonName] then
            return ChickenDatabase[buttonName]
        end

        for _, obj in ipairs(chickenBtn:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local txt = obj.Text:lower()
                if txt:find("cosmic") then
                    return "cosmic"
                end
                if txt:find("secret") then
                    return "secret"
                end
                if txt:find("mythic") or txt:find("divine") or txt:find("celestial") then
                    return "mythic"
                end
                if txt:find("legendary") then
                    return "legendary"
                end
                if txt:find("epic") then
                    return "epic"
                end
                if txt:find("rare") and not txt:find("uncommon") then
                    return "rare"
                end
                if txt:find("uncommon") then
                    return "uncommon"
                end
                if txt:find("common") then
                    return "common"
                end
            end
        end
        return "common"
    end

    local function CheckBackpackFull()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then
            return false
        end
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and IsVisibleGui(lbl) then
                local cur, max = lbl.Text:match("(%d+)%s*/%s*(%d+)")
                if cur and max then
                    local current = tonumber(cur)
                    local maximum = tonumber(max)
                    if maximum and maximum >= 50 and current >= (maximum - 10) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local isSellingNow = false
    local function ExecuteAutoSell()
        if isSellingNow or not CanRunAction("AutoSellChickensAction", 4.0) then
            return
        end
        isSellingNow = true

        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            local flock = pg and pg:FindFirstChild("Collection") and pg.Collection:FindFirstChild("Flock", true)
            if not flock then
                isSellingNow = false
                return
            end

            local scroll = flock:FindFirstChild("ScrollingFrame", true)
            local topButtons = flock:FindFirstChild("TopButtons")
            local sellModeBtn = topButtons and topButtons:FindFirstChild("Sell")
            local sellInfo = flock:FindFirstChild("SellInfoHolder", true)
            local confirmSellBtn = sellInfo and sellInfo:FindFirstChild("Sell")

            if not scroll or not sellModeBtn or not confirmSellBtn then
                isSellingNow = false
                return
            end

            if not sellInfo.Visible then
                ClickGuiButton(sellModeBtn)
                task.wait(0.3)
            end

            local selectedCount = 0
            for _, btn in ipairs(scroll:GetChildren()) do
                if btn:IsA("GuiButton") and btn.Name:sub(1, 1) == "c" and tonumber(btn.Name:sub(2)) then
                    local fav = btn:FindFirstChild("FavoriteIcon", true)
                    local isFav = fav and fav.Visible
                    if not isFav then
                        local rarity = GetChickenRarity(btn)
                        if ShouldSellRarity(rarity) then
                            ClickGuiButton(btn)
                            selectedCount = selectedCount + 1
                            if selectedCount % 15 == 0 then
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end

            task.wait(0.2)

            local toSellLbl = sellInfo:FindFirstChild("ToSellCount", true) or sellInfo:FindFirstChild("Value", true)
            local toSellText = toSellLbl and toSellLbl.Text or ""
            local count = tonumber(toSellText:match("(%d+)")) or selectedCount

            if count > 0 then
                ClickGuiButton(confirmSellBtn)
                Notify("ERDEVA HUB", "已自动出售 " .. tostring(count) .. " 只小鸡！", 3)
                TotalChickensSold = TotalChickensSold + count
                task.wait(0.3)
            end

            local cancelBtn = sellInfo:FindFirstChild("Cancel")
            if cancelBtn and sellInfo.Visible then
                ClickGuiButton(cancelBtn)
            elseif sellModeBtn and sellInfo.Visible then
                ClickGuiButton(sellModeBtn)
            end
        end)

        isSellingNow = false
    end

    task.spawn(function()
        while IsRunning do
            pcall(function()
                if Flags.AutoBypassPopups then
                    DismissPopups()
                end
                if Flags.AutoTakeEggs then
                    RunAutoTakeEggs()
                end
                if Flags.AutoUpgradeRecycler or Flags.AutoUpgradeFeeder or Flags.AutoBuyFeeders or Flags.AutoUpgradeCoop or
                    Flags.AutoOpenEggs then
                    DoUpgrades()
                end
            end)
            task.wait(1.5)
        end
    end)

    task.spawn(function()
        while IsRunning do
            pcall(function()
                if Flags.AutoSellChickens and CheckBackpackFull() then
                    ExecuteAutoSell()
                end
            end)
            task.wait(2.0)
        end
    end)

    task.spawn(function()
        while IsRunning do
            pcall(function()
                local pg = player:FindFirstChild("PlayerGui")
                if not pg then
                    return
                end

                if ChickenInTower and (tick() - TowerSentTime >= 90) then
                    ChickenInTower = false
                    TowerSentTime = 0
                    LastTowerFinishedAt = tick()
                end

                if ChickenInArena and (tick() - ArenaSentTime >= 70) then
                    ChickenInArena = false
                    ArenaSentTime = 0
                end

                if Flags.AutoArena then
                    DismissArenaResults()
                    TryClickGuiAction("ArenaGoBattleBtn", {"go to battle"}, 15.0)
                end

                if Flags.AutoNoThanks then
                    for _, obj in ipairs(pg:GetDescendants()) do
                        local isMatch = false
                        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and IsVisibleGui(obj) then
                            local t = obj.Text:lower()
                            if t:find("no thanks") or t:find("nothanks") or t:find("no, thanks") or
                                t:find("keep climbing") then
                                isMatch = true
                            end
                        end
                        if isMatch then
                            local target = obj
                            if not obj:IsA("TextButton") and not obj:IsA("ImageButton") then
                                target = obj:FindFirstAncestorWhichIsA("TextButton") or
                                             obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                            end
                            if target then
                                ClickGuiButton(target)
                                if ChickenInTower then
                                    ChickenInTower = false
                                    LastTowerFinishedAt = tick()
                                end
                                break
                            end
                        end
                    end
                end

                if Flags.AutoRebirth then
                    CheckAndDoRebirth()
                end

                local pitActiveHold = (tick() < ChickenInPitUntil)
                if Flags.AutoStartTower and not ChickenInTower and not ChickenInArena and not pitActiveHold and
                    (tick() - LastTowerFinishedAt >= 20.0) and not HasRebirthExclamationMark() then
                    if CanRunAction("SendChickenTower", 5.0) then
                        SafeCall("TowerStart")
                        TryClickGuiAction("TowerBtnDirect", {"tower"}, 2.0)
                        ChickenInTower = true
                        TowerSentTime = tick()
                        TriggerFrontierFloorSequence()
                    end
                end

                if Flags.AutoArena and not ChickenInTower and not ChickenInArena and not pitActiveHold then
                    if CanRunAction("ExecuteArenaFight", 3.0) then
                        SafeCall("ArenaFight")
                        TryClickGuiAction("OpenArenaRail", {"arena"}, 2.0)
                        ChickenInArena = true
                        ArenaSentTime = tick()
                    end
                end

                if Flags.AutoStartChaos then
                    SendChickenToPit("Chaos", 0)
                end
            end)
            task.wait(0.5)
        end
    end)

    local function GetArenaCenter()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("arena") or n:find("pen") or n:find("chickenarena")) and obj:IsA("BasePart") then
                return obj.Position
            end
        end
        return nil
    end

    task.spawn(function()
        while IsRunning do
            pcall(function()
                RunEventCheck()

                local shouldFarm = Flags.AutoGrabScraps or Flags.AutoRecycleScrap or Flags.AutoRebirth
                if not shouldFarm then
                    task.wait(0.3)
                    return
                end

                local root = GetRoot()
                local hum = GetHumanoid()
                if not root or not hum or hum.Health <= 0 then
                    task.wait(0.3)
                    return
                end

                if Flags.AutoRebirth then
                    CheckAndDoRebirth()
                end

                local targetCap = tonumber(Flags.ScrapCapacity) or 20
                if Flags.AutoGrabScraps and (CurrentBatchScraps < targetCap or not Flags.AutoRecycleScrap) then
                    local scrap = FindNearestArenaScrap()
                    if scrap then
                        CollectScrapPlate(scrap)
                    else
                        local arenaPos = GetArenaCenter()
                        if arenaPos and FlatDist(root.Position, arenaPos) > 20 then
                            WalkTo(arenaPos, 3.0, 6.0)
                        else
                            task.wait(0.15)
                        end
                    end
                elseif Flags.AutoRecycleScrap and (CurrentBatchScraps >= targetCap or not Flags.AutoGrabScraps) then
                    DoRecycleAtBase()
                end
            end)
            task.wait(0.02)
        end
    end)

    local function CheckAndClaimJurassicPass()
        pcall(function()
            local claimRemotes = {
                rs:FindFirstChild("ClaimPassReward", true),
                rs:FindFirstChild("ClaimJurassicPass", true),
                rs:FindFirstChild("ClaimEventReward", true),
                rs:FindFirstChild("JurassicPassClaim", true)
            }
            for _, rem in ipairs(claimRemotes) do
                if rem and rem:IsA("RemoteFunction") then
                    pcall(function() rem:InvokeServer() end)
                elseif rem and rem:IsA("RemoteEvent") then
                    pcall(function() rem:FireServer() end)
                end
            end
        end)
    end

    local function GetCarryingEgg()
        local char = player.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
                    return item
                end
            end
        end
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
                    return item
                end
            end
        end
        return nil
    end

    local function EquipEgg()
        local bp = player:FindFirstChild("Backpack")
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if bp and hum then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
                    hum:EquipTool(item)
                    task.wait(0.2)
                    break
                end
            end
        end
    end

    local function GetEventCenterPosition()
        local anchor = workspace:FindFirstChild("EventCardAnchor", true)
        if anchor and anchor:IsA("BasePart") then
            return anchor.Position
        end
        return Vector3.new(0, 0, 0)
    end

    local function FindEventEggPrompt()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, nil end

        local bestPrompt = nil
        local bestDist = math.huge

        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local act = string.lower(desc.ActionText or "")
                local obj = string.lower(desc.ObjectText or "")
                local pName = string.lower(desc.Parent and desc.Parent.Name or "")
                local isEgg = string.find(act, "pick") or string.find(act, "egg") or string.find(act, "take") or string.find(act, "collect") or string.find(obj, "egg") or string.find(pName, "egg")
                if isEgg then
                    local promptPos = nil
                    if desc.Parent:IsA("BasePart") then
                        promptPos = desc.Parent.Position
                    elseif desc.Parent:IsA("Attachment") then
                        promptPos = desc.Parent.WorldPosition
                    end
                    if promptPos then
                        local d = (hrp.Position - promptPos).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestPrompt = desc
                        end
                    end
                end
            end
        end
        return bestPrompt, bestDist
    end

    task.spawn(function()
        while task.wait(0.5) do
            if Flags.AutoAncientEgg then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    CheckAndClaimJurassicPass()

                    local carrying = GetCarryingEgg()

                    if carrying then
                        EquipEgg()
                        local centerPos = GetEventCenterPosition()
                        local distToCenter = (hrp.Position - centerPos).Magnitude

                        if distToCenter > 6 then
                            WalkTo(centerPos, 5.0, math.clamp(distToCenter / 12, 3.5, 16.0))
                        else
                            for _, desc in ipairs(workspace:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") and desc.Enabled then
                                    local act = string.lower(desc.ActionText or "")
                                    if string.find(act, "deposit") or string.find(act, "feed") or string.find(act, "place") or string.find(act, "give") or string.find(act, "interact") then
                                        local pPos = desc.Parent:IsA("BasePart") and desc.Parent.Position or (desc.Parent:IsA("Attachment") and desc.Parent.WorldPosition or nil)
                                        if pPos and (hrp.Position - pPos).Magnitude <= (desc.MaxActivationDistance + 4) then
                                            pcall(function()
                                                fireproximityprompt(desc, 0)
                                            end)
                                        end
                                    end
                                end
                            end
                            task.wait(0.5)
                        end
                    else
                        local prompt, dist = FindEventEggPrompt()

                        if prompt then
                            local targetPos = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or prompt.Parent.WorldPosition
                            local travelTime = math.clamp(dist / 12, 3.5, 18.0)

                            WalkTo(targetPos, math.min(prompt.MaxActivationDistance - 1, 4.0), travelTime)

                            local curDist = (hrp.Position - targetPos).Magnitude
                            if curDist <= (prompt.MaxActivationDistance + 3) then
                                pcall(function()
                                    fireproximityprompt(prompt, 0)
                                end)
                                task.wait(0.3)
                            end
                        else
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end)

    local SessionStartTime = tick()
    local InitialRebirth = nil
    local TotalChickensSold = 0

    local function GetCurrentRebirth()
        local lStats = player:FindFirstChild("leaderstats")
        if lStats then
            for _, v in ipairs(lStats:GetChildren()) do
                local n = string.lower(v.Name)
                if string.find(n, "rebirth") or string.find(n, "prestige") then
                    local num = tonumber(tostring(v.Value):gsub("[^%d]", ""))
                    if num then return num end
                end
            end
        end
        for _, fName in ipairs({"Data", "PlayerData", "Stats"}) do
            local f = player:FindFirstChild(fName)
            if f then
                for _, v in ipairs(f:GetDescendants()) do
                    local n = string.lower(v.Name)
                    if (string.find(n, "rebirth") or string.find(n, "prestige")) and (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue")) then
                        local num = tonumber(tostring(v.Value):gsub("[^%d]", ""))
                        if num then return num end
                    end
                end
            end
        end
        for _, a in ipairs({"Rebirth", "Rebirths", "Prestige"}) do
            local attr = player:GetAttribute(a)
            if attr and tonumber(attr) then return tonumber(attr) end
        end
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            for _, t in ipairs(pg:GetDescendants()) do
                if t:IsA("TextLabel") and t.Visible then
                    local txt = string.lower(t.Text)
                    if string.find(txt, "rebirth") then
                        local match = string.match(txt, "%d[%d,.]*")
                        if match then
                            local num = tonumber(match:gsub("[,.]", ""))
                            if num then return num end
                        end
                    end
                end
            end
        end
        return 0
    end

    local function FormatNumber(n)
        local str = tostring(math.floor(n))
        local k
        while true do
            str, k = string.gsub(str, "^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
        end
        return str
    end

    local function FormatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02d时 %02d分 %02d秒", h, m, s)
    end

    local function GetSessionStats()
        local elapsed = math.max(tick() - SessionStartTime, 1)
        local currentRebirth = GetCurrentRebirth()

        if InitialRebirth == nil and currentRebirth > 0 then
            InitialRebirth = currentRebirth
        end

        local startRebirth = InitialRebirth or currentRebirth
        local rebirthsGained = math.max(0, currentRebirth - startRebirth)
        local hours = elapsed / 3600
        local rebirthPerHour = hours > 0.003 and math.floor((rebirthsGained / hours) * 10) / 10 or 0
        local chickensPerHour = hours > 0.003 and math.floor((TotalChickensSold / hours) * 10) / 10 or 0

        return {
            TimeText = FormatTime(elapsed),
            CurrentRebirth = FormatNumber(currentRebirth),
            RebirthsGained = FormatNumber(rebirthsGained),
            RebirthPerHour = FormatNumber(rebirthPerHour),
            ChickensSold = FormatNumber(TotalChickensSold),
            ChickensPerHour = FormatNumber(chickensPerHour),
        }
    end

    pcall(function()
        if hookmetamethod and getnamecallmethod then
            local oldNc
            oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
                    local n = string.lower(tostring(self.Name))
                    if string.find(n, "sellchicken") then
                        if n == "sellchickens" and typeof(args[1]) == "table" then
                            TotalChickensSold = TotalChickensSold + #args[1]
                        else
                            TotalChickensSold = TotalChickensSold + 1
                        end
                    end
                end
                return oldNc(self, ...)
            end))
        end
    end)

    local Gui = Instance.new("ScreenGui", CoreGui)
    Gui.Name = "ERDEVA_HUB"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    Gui.DisplayOrder = 9999

    local function Shutdown()
        IsRunning = false
        for k in pairs(Flags) do
            Flags[k] = false
        end
        pcall(function()
            Gui:Destroy()
        end)
    end

    local Main = Instance.new("Frame", Gui)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.fromOffset(W, H)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.BackgroundColor3 = C.Bg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = C.Red
    MainStroke.Thickness = 1.2

    local Top = Instance.new("Frame", Main)
    Top.Size = UDim2.new(1, 0, 0, 36)
    Top.BackgroundColor3 = C.Top
    Top.BorderSizePixel = 0

    local TopLine = Instance.new("Frame", Top)
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 1, -1)
    TopLine.BackgroundColor3 = C.Border
    TopLine.BorderSizePixel = 0

    local HeaderLogo = nil
    if LogoAssetId then
        HeaderLogo = Instance.new("ImageLabel", Top)
        HeaderLogo.Size = UDim2.fromOffset(22, 22)
        HeaderLogo.Position = UDim2.fromOffset(10, 7)
        HeaderLogo.BackgroundTransparency = 1
        HeaderLogo.Image = LogoAssetId
        Instance.new("UICorner", HeaderLogo).CornerRadius = UDim.new(0, 4)
    end

    local Title = Instance.new("TextLabel", Top)
    Title.Size = UDim2.new(1, HeaderLogo and -95 or -75, 1, 0)
    Title.Position = UDim2.fromOffset(HeaderLogo and 38 or 12, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "ERDEVA HUB v2.7 中文直启版"
    Title.TextColor3 = C.Txt
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Top)
    CloseBtn.Size = UDim2.fromOffset(24, 24)
    CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = C.Sub
    CloseBtn.TextSize = 11
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    local CloseStroke = Instance.new("UIStroke", CloseBtn)
    CloseStroke.Color = C.Border
    CloseStroke.Thickness = 1

    CloseBtn.MouseEnter:Connect(function()
        tw(CloseBtn, {
            BackgroundColor3 = C.Red,
            TextColor3 = C.Txt
        }, 0.15)
        tw(CloseStroke, {
            Color = C.RedGlow
        }, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        tw(CloseBtn, {
            BackgroundColor3 = Color3.fromRGB(24, 27, 36),
            TextColor3 = C.Sub
        }, 0.15)
        tw(CloseStroke, {
            Color = C.Border
        }, 0.15)
    end)
    CloseBtn.MouseButton1Click:Connect(Shutdown)

    local MinBtn = Instance.new("TextButton", Top)
    MinBtn.Size = UDim2.fromOffset(24, 24)
    MinBtn.Position = UDim2.new(1, -58, 0.5, -12)
    MinBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    MinBtn.Text = "-"
    MinBtn.TextSize = 13
    MinBtn.TextColor3 = C.Sub
    MinBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)
    local MinStroke = Instance.new("UIStroke", MinBtn)
    MinStroke.Color = C.Border
    MinStroke.Thickness = 1

    MinBtn.MouseEnter:Connect(function()
        tw(MinBtn, {
            BackgroundColor3 = C.CardHover,
            TextColor3 = C.Txt
        }, 0.15)
        tw(MinStroke, {
            Color = C.Red
        }, 0.15)
    end)
    MinBtn.MouseLeave:Connect(function()
        tw(MinBtn, {
            BackgroundColor3 = Color3.fromRGB(24, 27, 36),
            TextColor3 = C.Sub
        }, 0.15)
        tw(MinStroke, {
            Color = C.Border
        }, 0.15)
    end)

    local MiniIcon = Instance.new("Frame", Gui)
    MiniIcon.Size = UDim2.fromOffset(50, 50)
    MiniIcon.Position = UDim2.new(0, 20, 0.5, -25)
    MiniIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
    MiniIcon.BorderSizePixel = 0
    MiniIcon.Visible = false
    MiniIcon.Active = true
    Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 10)
    local MiniStroke = Instance.new("UIStroke", MiniIcon)
    MiniStroke.Color = C.Red
    MiniStroke.Thickness = 1.4

    if LogoAssetId then
        local IconImg = Instance.new("ImageLabel", MiniIcon)
        IconImg.Size = UDim2.new(1, -12, 1, -12)
        IconImg.Position = UDim2.fromOffset(6, 6)
        IconImg.BackgroundTransparency = 1
        IconImg.Image = LogoAssetId
        Instance.new("UICorner", IconImg).CornerRadius = UDim.new(0, 7)
    else
        local MiniLabel = Instance.new("TextLabel", MiniIcon)
        MiniLabel.Size = UDim2.new(1, 0, 1, 0)
        MiniLabel.BackgroundTransparency = 1
        MiniLabel.Text = "ERDEVA"
        MiniLabel.TextColor3 = C.Red
        MiniLabel.TextSize = 9
        MiniLabel.Font = Enum.Font.GothamBold
        MiniLabel.TextXAlignment = Enum.TextXAlignment.Center
    end

    local minState = false
    local function SetMinimized(state)
        minState = state
        if state then
            tw(Main, {
                Size = UDim2.fromOffset(W, 0),
                BackgroundTransparency = 1
            }, 0.2)
            task.delay(0.2, function()
                Main.Visible = false
                MiniIcon.Visible = true
                tw(MiniIcon, {
                    BackgroundTransparency = 0
                }, 0.15)
            end)
        else
            MiniIcon.Visible = false
            Main.Visible = true
            Main.BackgroundTransparency = 0
            tw(Main, {
                Size = UDim2.fromOffset(W, H)
            }, 0.2)
        end
    end

    MinBtn.MouseButton1Click:Connect(function()
        SetMinimized(true)
    end)

    local miniDragging = false
    local miniDragStart = nil
    local miniStartPos = nil
    local miniMoveDist = 0

    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging = true
            miniDragStart = input.Position
            miniStartPos = MiniIcon.Position
            miniMoveDist = 0

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    miniDragging = false
                    connection:Disconnect()
                    if miniMoveDist < 8 then
                        SetMinimized(false)
                    end
                end
            end)
        end
    end)

    local mainDrag = false
    local mainDragStart = nil
    local mainStartPos = nil

    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mainDrag = true
            mainDragStart = input.Position
            mainStartPos = Main.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mainDrag = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            if mainDrag and not minState then
                local delta = input.Position - mainDragStart
                Main.Position = UDim2.new(0.5, math.clamp(mainStartPos.X.Offset + delta.X, -vs.X / 2 + W / 2 + 10,
                    vs.X / 2 - W / 2 - 10), 0.5, math.clamp(mainStartPos.Y.Offset + delta.Y, -vs.Y / 2 + H / 2 + 25,
                    vs.Y / 2 - H / 2 - 10))
            end
            if miniDragging and MiniIcon.Visible then
                local delta = input.Position - miniDragStart
                miniMoveDist = (Vector2.new(delta.X, delta.Y)).Magnitude
                local curX = miniStartPos.X.Offset + delta.X
                local curY = miniStartPos.Y.Offset + delta.Y
                local curScaleX = miniStartPos.X.Scale
                local curScaleY = miniStartPos.Y.Scale
                local absX = curScaleX * vs.X + curX
                local absY = curScaleY * vs.Y + curY
                absX = math.clamp(absX, 4, vs.X - 56)
                absY = math.clamp(absY, 4, vs.Y - 56)
                MiniIcon.Position = UDim2.new(0, absX, 0, absY)
            end
        end
    end)

    local TabFrame = Instance.new("Frame", Main)
    TabFrame.Size = UDim2.new(1, -16, 0, 30)
    TabFrame.Position = UDim2.fromOffset(8, 42)
    TabFrame.BackgroundColor3 = C.TabBg
    TabFrame.BorderSizePixel = 0
    Instance.new("UICorner", TabFrame).CornerRadius = UDim.new(0, 6)
    local TabFrameStroke = Instance.new("UIStroke", TabFrame)
    TabFrameStroke.Color = C.Border
    TabFrameStroke.Thickness = 1

    local TabList = Instance.new("UIListLayout", TabFrame)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center
    TabList.Padding = UDim.new(0, 3)

    local TabPadding = Instance.new("UIPadding", TabFrame)
    TabPadding.PaddingLeft = UDim.new(0, 2)
    TabPadding.PaddingRight = UDim.new(0, 2)
    TabPadding.PaddingTop = UDim.new(0, 3)
    TabPadding.PaddingBottom = UDim.new(0, 3)

    local Content = Instance.new("ScrollingFrame", Main)
    Content.Size = UDim2.new(1, -16, 1, -82)
    Content.Position = UDim2.fromOffset(8, 76)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 2
    Content.ScrollBarImageColor3 = C.Red
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local CL = Instance.new("UIListLayout", Content)
    CL.Padding = UDim.new(0, 4)

    local Pages, TabBtns = {}, {}
    local function SetTab(name)
        for n, p in pairs(Pages) do
            p.Visible = (n == name)
        end
        for n, btnData in pairs(TabBtns) do
            local isSel = (n == name)
            tw(btnData.btn, {
                BackgroundColor3 = isSel and Color3.fromRGB(38, 18, 24) or Color3.fromRGB(18, 20, 26)
            }, 0.15)
            tw(btnData.label, {
                TextColor3 = isSel and C.Txt or C.Sub
            }, 0.15)
            tw(btnData.icon, {
                ImageColor3 = isSel and C.Red or C.Sub
            }, 0.15)
            tw(btnData.stroke, {
                Color = isSel and C.Red or Color3.fromRGB(26, 29, 38)
            }, 0.15)
        end
    end

    local TabIcons = {
        Farm = "rbxassetid://10734965572",
        Flock = "rbxassetid://10723354671",
        Plot = "rbxassetid://6031265976",
        Battle = "rbxassetid://10734975692",
        Events = "rbxassetid://6031075931",
        Info = "rbxassetid://6031154871",
        Stats = "rbxassetid://10709789810"
    }

    local MakeTab = function(name, order, displayName)
        local btn = Instance.new("TextButton", TabFrame)
        btn.Size = UDim2.new(1 / 7, -3, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = Color3.fromRGB(26, 29, 38)
        bStroke.Thickness = 1

        local icon = Instance.new("ImageLabel", btn)
        icon.Size = UDim2.fromOffset(13, 13)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 5, 0.5, 0)
        icon.BackgroundTransparency = 1
        icon.Image = TabIcons[name] or "rbxassetid://6031154871"
        icon.ImageColor3 = C.Sub

        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.fromOffset(20, 0)
        label.BackgroundTransparency = 1
        label.Text = displayName or name
        label.TextColor3 = C.Sub
        label.TextSize = 9.0
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left

        TabBtns[name] = {
            btn = btn,
            icon = icon,
            label = label,
            stroke = bStroke
        }

        local page = Instance.new("Frame", Content)
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.Visible = false
        local pl = Instance.new("UIListLayout", page)
        pl.Padding = UDim.new(0, 4)
        Pages[name] = page

        btn.MouseButton1Click:Connect(function()
            SetTab(name)
        end)
        return page
    end

    local function SetFlag(key, val)
        Flags[key] = val
        if ToggleUpdaters[key] then
            ToggleUpdaters[key](val)
        end
    end

    local function AddToggle(parent, label, key, iconAsset)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -54, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        if iconAsset then
            local crown = Instance.new("ImageLabel", f)
            crown.Size = UDim2.fromOffset(14, 14)
            crown.Position = UDim2.fromOffset(88, 8)
            crown.BackgroundTransparency = 1
            crown.Image = "rbxassetid://7733765398"
            crown.ImageColor3 = Color3.fromRGB(241, 196, 15)
        end

        local b = Instance.new("TextButton", f)
        b.Size = UDim2.fromOffset(36, 18)
        b.Position = UDim2.new(1, -44, 0.5, -9)
        b.BackgroundColor3 = C.Off
        b.Text = ""
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border
        bStroke.Thickness = 1

        local k = Instance.new("Frame", b)
        k.Size = UDim2.fromOffset(12, 12)
        k.Position = UDim2.fromOffset(3, 3)
        k.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)

        local function upd(on)
            tw(b, {
                BackgroundColor3 = (on and C.Red or C.Off)
            })
            tw(bStroke, {
                Color = (on and C.RedGlow or C.Border)
            })
            tw(k, {
                Position = (on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3))
            })
            tw(fStroke, {
                Color = (on and Color3.fromRGB(55, 26, 34) or C.Border)
            })
        end

        ToggleUpdaters[key] = upd
        upd(Flags[key])

        b.MouseButton1Click:Connect(function()
            local ns = not Flags[key]
            SetFlag(key, ns)
            if key == "AutoRebirth" then
                if ns then
                    SetFlag("AutoUpgradeRecycler", true)
                    SetFlag("AutoBuyFeeders", true)
                    SetFlag("AutoUpgradeFeeder", true)
                    SetFlag("AutoUpgradeCoop", true)
                    SetFlag("AutoStartTower", true)
                    SetFlag("AutoNoThanks", true)
                    SetFlag("AutoBypassPopups", true)
                else
                    SetFlag("AutoUpgradeRecycler", false)
                    SetFlag("AutoBuyFeeders", false)
                    SetFlag("AutoUpgradeFeeder", false)
                    SetFlag("AutoUpgradeCoop", false)
                    SetFlag("AutoStartTower", false)
                    SetFlag("AutoNoThanks", false)
                    SetFlag("AutoBypassPopups", false)
                end
            end
        end)
    end

    local function AddButton(parent, label, callback)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = C.Card
        b.Text = label
        b.TextColor3 = C.Txt
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border
        bStroke.Thickness = 1

        b.MouseEnter:Connect(function()
            tw(b, {
                BackgroundColor3 = C.CardHover
            })
            tw(bStroke, {
                Color = C.Red
            })
        end)
        b.MouseLeave:Connect(function()
            tw(b, {
                BackgroundColor3 = C.Card
            })
            tw(bStroke, {
                Color = C.Border
            })
        end)

        b.MouseButton1Click:Connect(function()
            tw(b, {
                BackgroundColor3 = C.Red
            }, 0.1)
            task.delay(0.2, function()
                tw(b, {
                    BackgroundColor3 = C.Card
                }, 0.15)
            end)
            if callback then
                callback(b)
            end
        end)
        return b
    end

    local function AddBadge(parent, label, badgeText)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -95, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Sub
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local b = Instance.new("TextLabel", f)
        b.Size = UDim2.fromOffset(80, 20)
        b.Position = UDim2.new(1, -88, 0.5, -10)
        b.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
        b.Text = badgeText
        b.TextColor3 = Color3.fromRGB(160, 170, 190)
        b.TextSize = 9
        b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = Color3.fromRGB(40, 45, 60)
        bStroke.Thickness = 1
    end

    local function AddSlider(parent, label, maxV, defV, key)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -65, 0, 16)
        l.Position = UDim2.fromOffset(10, 3)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local vl = Instance.new("TextLabel", f)
        vl.Size = UDim2.fromOffset(50, 16)
        vl.Position = UDim2.new(1, -58, 0, 3)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(defV) .. "/" .. tostring(maxV)
        vl.TextColor3 = C.Red
        vl.TextSize = 11
        vl.Font = Enum.Font.GothamBold
        vl.TextXAlignment = Enum.TextXAlignment.Right

        local bar = Instance.new("Frame", f)
        bar.Size = UDim2.new(1, -20, 0, 4)
        bar.Position = UDim2.fromOffset(10, 23)
        bar.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
        bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new(defV / maxV, 0, 1, 0)
        fill.BackgroundColor3 = C.Red
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local sld = false
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                sld = true
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                sld = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sld and
                (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local r = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(r, 0, 1, 0)
                local v = math.max(1, math.floor(r * maxV + 0.5))
                vl.Text = tostring(v) .. "/" .. tostring(maxV)
                Flags[key] = v
            end
        end)
    end

    local function AddRarityRow(parent)
        local row = Instance.new("Frame", parent)
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        return row
    end

    local function AddRarityChip(row, label, key, rarityColor, isRight)
        local b = Instance.new("TextButton", row)
        b.Size = UDim2.new(0.5, -3, 1, 0)
        b.Position = isRight and UDim2.new(0.5, 3, 0, 0) or UDim2.new(0, 0, 0, 0)
        b.BackgroundColor3 = C.Card
        b.Text = ""
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border
        bStroke.Thickness = 1

        local dot = Instance.new("Frame", b)
        dot.Size = UDim2.fromOffset(7, 7)
        dot.Position = UDim2.new(0, 8, 0.5, -3.5)
        dot.BackgroundColor3 = rarityColor or C.Txt
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local l = Instance.new("TextLabel", b)
        l.Size = UDim2.new(1, -48, 1, 0)
        l.Position = UDim2.fromOffset(19, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 10
        l.Font = Enum.Font.GothamBold
        l.TextXAlignment = Enum.TextXAlignment.Left

        local pill = Instance.new("Frame", b)
        pill.Size = UDim2.fromOffset(26, 14)
        pill.Position = UDim2.new(1, -30, 0.5, -7)
        pill.BackgroundColor3 = C.Off
        pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
        local pillStroke = Instance.new("UIStroke", pill)
        pillStroke.Color = C.Border
        pillStroke.Thickness = 1

        local knob = Instance.new("Frame", pill)
        knob.Size = UDim2.fromOffset(10, 10)
        knob.Position = UDim2.fromOffset(2, 2)
        knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local function upd(on)
            tw(pill, {
                BackgroundColor3 = (on and C.Red or C.Off)
            })
            tw(pillStroke, {
                Color = (on and C.RedGlow or C.Border)
            })
            tw(knob, {
                Position = (on and UDim2.fromOffset(14, 2) or UDim2.fromOffset(2, 2))
            })
            tw(bStroke, {
                Color = (on and (rarityColor or C.Red) or C.Border)
            })
            tw(l, {
                TextColor3 = (on and C.Txt or C.Sub)
            })
            tw(dot, {
                BackgroundTransparency = (on and 0 or 0.6)
            })
        end

        ToggleUpdaters[key] = upd
        upd(Flags[key])

        b.MouseButton1Click:Connect(function()
            local ns = not Flags[key]
            SetFlag(key, ns)
        end)
    end

    local FarmPage = MakeTab("Farm", 1, "挂机")
    local PlotPage = MakeTab("Plot", 2, "基地")
    local FlockPage = MakeTab("Flock", 3, "鸡群")
    local BattlePage = MakeTab("Battle", 4, "战斗")
    local EventsPage = MakeTab("Events", 5, "活动")
    local InfoPage = MakeTab("Info", 6, "信息")
    local StatsPage = MakeTab("Stats", 7, "统计")

    AddToggle(FarmPage, "自动拾取鸡蛋", "AutoTakeEggs")
    AddToggle(FarmPage, "自动开启鸡蛋", "AutoOpenEggs")
    AddToggle(FarmPage, "自动收集废料", "AutoGrabScraps")
    AddToggle(FarmPage, "自动回收废料", "AutoRecycleScrap")
    AddSlider(FarmPage, "废料容量", 50, 20, "ScrapCapacity")

    AddToggle(FlockPage, "自动出售小鸡", "AutoSellChickens")
    AddButton(FlockPage, "立即出售小鸡", function()
        ExecuteAutoSell()
    end)

    local r1 = AddRarityRow(FlockPage)
    AddRarityChip(r1, "普通", "SellCommon", Color3.fromRGB(200, 205, 215), false)
    AddRarityChip(r1, "优秀", "SellUncommon", Color3.fromRGB(46, 204, 113), true)

    local r2 = AddRarityRow(FlockPage)
    AddRarityChip(r2, "稀有", "SellRare", Color3.fromRGB(52, 152, 219), false)
    AddRarityChip(r2, "史诗", "SellEpic", Color3.fromRGB(155, 89, 182), true)

    local r3 = AddRarityRow(FlockPage)
    AddRarityChip(r3, "传奇", "SellLegendary", Color3.fromRGB(241, 196, 15), false)
    AddRarityChip(r3, "神话+", "SellMythic", Color3.fromRGB(231, 76, 60), true)

    local r4 = AddRarityRow(FlockPage)
    AddRarityChip(r4, "宇宙", "SellCosmic", Color3.fromRGB(26, 188, 156), false)
    AddRarityChip(r4, "秘密", "SellSecret", Color3.fromRGB(255, 105, 180), true)

    AddToggle(PlotPage, "自动重生", "AutoRebirth", true)
    AddButton(PlotPage, "[锁定] 设置基地", function(btn)
        local root = GetRoot()
        if root then
            LOCKED_RECYCLER_POS = root.Position
            btn.Text = "基地已锁定"
            Notify("ERDEVA HUB", "基地位置已锁定", 3.0)
            task.delay(2.5, function()
                btn.Text = "[锁定] 设置基地"
            end)
        end
    end)
    AddToggle(PlotPage, "自动购买喂食器", "AutoBuyFeeders")
    AddToggle(PlotPage, "自动升级喂食器", "AutoUpgradeFeeder")
    AddToggle(PlotPage, "自动升级回收机", "AutoUpgradeRecycler")
    AddToggle(PlotPage, "自动升级鸡舍", "AutoUpgradeCoop")

    AddToggle(BattlePage, "自动开始高塔", "AutoStartTower")
    AddToggle(BattlePage, "自动竞技场", "AutoArena")
    AddToggle(BattlePage, "自动关闭“不用了”", "AutoNoThanks")
    AddToggle(BattlePage, "自动关闭弹窗", "AutoBypassPopups")
    AddButton(BattlePage, "将小鸡送入竞技坑", function()
        SendChickenToPit("Manual", 0)
        Notify("ERDEVA HUB", "已将小鸡送入竞技坑", 2)
    end)

    AddToggle(EventsPage, "自动 UFO 活动", "AutoUFO")
    AddToggle(EventsPage, "自动远古鸡蛋", "AutoAncientEgg")
    AddToggle(EventsPage, "自动领取侏罗纪通行证", "AutoJurassicPass")

    local LiveCarriedLabel = nil

    local function AddInfo(k, v, isLive)
        local f = Instance.new("Frame", InfoPage)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(0.5, 0, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = k
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local r = Instance.new("TextLabel", f)
        r.Size = UDim2.new(0.5, -10, 1, 0)
        r.Position = UDim2.new(0.5, 0, 0, 0)
        r.BackgroundTransparency = 1
        r.Text = v
        r.TextColor3 = C.Red
        r.TextSize = 11
        r.Font = Enum.Font.GothamBold
        r.TextXAlignment = Enum.TextXAlignment.Right

        if isLive then
            LiveCarriedLabel = r
        end
    end

    AddInfo("用户", player.Name, false)
    AddInfo("Hub 版本", "v2.7", false)
    AddInfo("版本状态", "中文直启版", false)

    AddToggle(InfoPage, "伪装名称", "VisualName")

    local InfoSpacer = Instance.new("Frame", InfoPage)
    InfoSpacer.Size = UDim2.new(1, 0, 0, 4)
    InfoSpacer.BackgroundTransparency = 1


    local function CreateStatCard(parent, title, defaultVal, color)
        local card = Instance.new("Frame", parent)
        card.Size = UDim2.new(1, 0, 0, 52)
        card.BackgroundColor3 = C.Card
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", card)
        stroke.Color = C.Border
        stroke.Thickness = 1

        local tLabel = Instance.new("TextLabel", card)
        tLabel.Size = UDim2.new(1, -20, 0, 18)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = C.Sub
        tLabel.TextSize = 11
        tLabel.Font = Enum.Font.GothamMedium
        tLabel.TextXAlignment = Enum.TextXAlignment.Left

        local vLabel = Instance.new("TextLabel", card)
        vLabel.Size = UDim2.new(1, -20, 0, 20)
        vLabel.Position = UDim2.new(0, 12, 0, 26)
        vLabel.BackgroundTransparency = 1
        vLabel.Text = defaultVal
        vLabel.TextColor3 = color or C.Txt
        vLabel.TextSize = 14
        vLabel.Font = Enum.Font.GothamBold
        vLabel.TextXAlignment = Enum.TextXAlignment.Left

        return vLabel
    end

    local LabelTime = CreateStatCard(StatsPage, "在线时长", "00时 00分 00秒", C.Txt)
    local LabelCurRebirth = CreateStatCard(StatsPage, "当前重生次数", "0", Color3.fromRGB(56, 189, 248))
    local LabelGainRebirth = CreateStatCard(StatsPage, "本次增加重生", "+0", Color3.fromRGB(34, 197, 94))
    local LabelRateRebirth = CreateStatCard(StatsPage, "每小时重生", "0 / 小时", Color3.fromRGB(234, 179, 8))
    local LabelSoldChicken = CreateStatCard(StatsPage, "已出售小鸡", "0", Color3.fromRGB(239, 68, 68))
    local LabelRateChicken = CreateStatCard(StatsPage, "每小时出售小鸡", "0 / 小时", Color3.fromRGB(168, 85, 247))

    local ResetStatsBtn = Instance.new("TextButton", StatsPage)
    ResetStatsBtn.Size = UDim2.new(1, 0, 0, 36)
    ResetStatsBtn.BackgroundColor3 = C.Off
    ResetStatsBtn.Text = "重置统计"
    ResetStatsBtn.TextColor3 = C.Txt
    ResetStatsBtn.TextSize = 11
    ResetStatsBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", ResetStatsBtn).CornerRadius = UDim.new(0, 8)

    ResetStatsBtn.MouseButton1Click:Connect(function()
        SessionStartTime = tick()
        InitialRebirth = GetCurrentRebirth()
        TotalChickensSold = 0
    end)

    task.spawn(function()
        while IsRunning do
            local stats = GetSessionStats()
            if LabelTime and LabelTime.Parent then
                LabelTime.Text = stats.TimeText
                LabelCurRebirth.Text = stats.CurrentRebirth
                LabelGainRebirth.Text = "+" .. stats.RebirthsGained
                LabelRateRebirth.Text = stats.RebirthPerHour .. " / 小时"
                LabelSoldChicken.Text = stats.ChickensSold .. " 只"
                LabelRateChicken.Text = stats.ChickensPerHour .. " / 小时"
            end
            task.wait(1)
        end
    end)

    task.spawn(function()
        while IsRunning do
            if LiveCarriedLabel and LiveCarriedLabel.Parent then
                LiveCarriedLabel.Text = tostring(CurrentBatchScraps) .. " / " .. tostring(Flags.ScrapCapacity or 20)
            end
            task.wait(0.1)
        end
    end)

    local originalOverheadData = {}

    local function UpdateVisualName()
        local char = player.Character
        if not char then return end

        if char:FindFirstChild("Head") and char.Head:FindFirstChild("ErdevaVisualTag") then
            char.Head.ErdevaVisualTag:Destroy()
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and Flags.VisualName then
            if hum.DisplayName ~= "ERDEVA" then
                hum.DisplayName = "ERDEVA"
            end
        end

        for _, bg in ipairs(char:GetDescendants()) do
            if bg:IsA("BillboardGui") and bg.Name ~= "ErdevaVisualTag" then
                for _, lbl in ipairs(bg:GetDescendants()) do
                    if lbl:IsA("TextLabel") then
                        local t = lbl.Text:lower()
                        local pn = player.Name:lower()
                        local pd = player.DisplayName:lower()
                        local ln = lbl.Name:lower()

                        local isNameLabel = (t == pn or t == pd or t == "erdeva" or t:find(pn) or t:find(pd) or ln == "name" or ln == "playername" or ln == "username" or ln:find("namelabel"))
                        local isTitle = (t:find("rebirth") or t:find("diamond") or t:find("tier") or t:find("level") or t:find("coop") or t:find("king") or t:find("stone"))

                        if isNameLabel and not isTitle then
                            if Flags.VisualName then
                                if not originalOverheadData[lbl] then
                                    originalOverheadData[lbl] = {
                                        Text = lbl.Text,
                                        TextColor3 = lbl.TextColor3
                                    }
                                end
                                if lbl.Text ~= "ERDEVA" then
                                    lbl.Text = "ERDEVA"
                                end
                                lbl.TextColor3 = Color3.fromRGB(235, 45, 65)
                                local stroke = lbl:FindFirstChildOfClass("UIStroke")
                                if stroke then
                                    stroke.Color = Color3.fromRGB(20, 20, 25)
                                end
                            else
                                if originalOverheadData[lbl] then
                                    lbl.Text = originalOverheadData[lbl].Text
                                    lbl.TextColor3 = originalOverheadData[lbl].TextColor3
                                end
                            end
                        end
                    end
                end
            end
        end

        if not Flags.VisualName then
            table.clear(originalOverheadData)
        end
    end

    task.spawn(function()
        while IsRunning do
            pcall(UpdateVisualName)
            task.wait(0.25)
        end
    end)

    SetTab("Farm")
end


-- 已移除外部密钥验证与试用服务器检查，直接启动主界面
StartMainScript()
