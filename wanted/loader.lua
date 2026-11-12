-- PHANTOM 中文版：原文件仅含始终失败的密钥界面，没有游戏功能入口。
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local guiParent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- 界面配色
local C = {
	bg = Color3.fromRGB(18, 18, 20),
	panel = Color3.fromRGB(28, 28, 32),
	panelLight = Color3.fromRGB(34, 34, 38),
	border = Color3.fromRGB(180, 35, 45),
	red = Color3.fromRGB(200, 45, 55),
	redDark = Color3.fromRGB(120, 28, 35),
	white = Color3.fromRGB(235, 235, 240),
	dim = Color3.fromRGB(120, 120, 130),
	yellow = Color3.fromRGB(220, 180, 60),
	green = Color3.fromRGB(70, 200, 100),
	blue = Color3.fromRGB(80, 140, 220),
	inputRed = Color3.fromRGB(220, 60, 70),
	orange = Color3.fromRGB(220, 140, 70),
}

local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or C.border
	s.Thickness = thickness or 1
	s.Parent = inst
	return s
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Code
	l.TextColor3 = C.white
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

local function button(parent, props)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.Font = Enum.Font.Code
	b.TextColor3 = C.white
	b.Text = ""
	for k, v in pairs(props) do
		b[k] = v
	end
	b.Parent = parent
	return b
end


local old = guiParent:FindFirstChild("PhantomAuth")
if old then old:Destroy() end
local screen = Instance.new("ScreenGui")
screen.Name = "PhantomAuth"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = guiParent

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(420, 300)
root.BackgroundColor3 = C.bg
root.BorderSizePixel = 0
root.Parent = screen
corner(root, 8)
stroke(root, C.border, 1.5)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = root
label(header, {
    Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(14, 0),
    Text = "◆ PHANTOM // 中文版", TextSize = 16,
})
local closeBtn = button(header, {
    Size = UDim2.fromOffset(40, 36), Position = UDim2.new(1, -46, 0, 4),
    BackgroundColor3 = C.redDark, Text = "关闭", TextSize = 12,
})
corner(closeBtn, 4)
closeBtn.Activated:Connect(function() screen:Destroy() end)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -24, 1, -64)
body.Position = UDim2.fromOffset(12, 52)
body.BackgroundColor3 = C.panel
body.Parent = root
corner(body, 6)
label(body, {
    Size = UDim2.new(1, -24, 0, 32), Position = UDim2.fromOffset(12, 10),
    Text = "密钥界面已移除", TextSize = 18, TextColor3 = C.green,
    Font = Enum.Font.GothamBold,
})
label(body, {
    Size = UDim2.new(1, -24, 0, 150), Position = UDim2.fromOffset(12, 50),
    Text = "原文件仅包含密钥输入及外部下载引导。\n\n验证被写死为始终失败，且未包含验证成功后的游戏功能。\n\n此版本已移除密钥输入、验证按钮及下载软件的引导；没有额外功能被解锁。",
    TextSize = 14, TextWrapped = true, TextColor3 = C.white,
    TextYAlignment = Enum.TextYAlignment.Top,
})

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = input, input.Position, root.Position
    end
end)
local changed = UIS.InputChanged:Connect(function(input)
    if dragging and (input == dragging or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
local ended = UIS.InputEnded:Connect(function(input)
    if input == dragging then dragging = nil end
end)
screen.Destroying:Connect(function() changed:Disconnect(); ended:Disconnect() end)
print("[PHANTOM] 中文界面已加载；原文件未包含游戏功能。")
