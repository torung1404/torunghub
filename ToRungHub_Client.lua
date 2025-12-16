local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local root = ReplicatedStorage:WaitForChild("ToRungHub")
local autoFarmRE = root:WaitForChild("AutoFarmRE")

local function send_set(key, value)
	autoFarmRE:FireServer({ cmd = "set", key = key, value = value })
end

-- ===== UI Theme (minimal, not too bright)
local Theme = {
	Bg = Color3.fromRGB(18, 18, 20),
	Panel = Color3.fromRGB(24, 24, 28),
	Stroke = Color3.fromRGB(120, 120, 135),
	Text = Color3.fromRGB(235, 235, 240),
	Muted = Color3.fromRGB(170, 170, 180),
	Accent = Color3.fromRGB(110, 160, 255),
	Good = Color3.fromRGB(95, 210, 140),
	Bad = Color3.fromRGB(235, 95, 95),
}

local gui = Instance.new("ScreenGui")
gui.Name = "ToRungHubGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(520, 330)
main.Position = UDim2.new(1, -540, 0.5, -165)
main.BackgroundColor3 = Theme.Bg
main.BackgroundTransparency = 0.18
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.55 -- soft border (your “mờ viền”, not blur whole UI)
stroke.Color = Theme.Stroke
stroke.Parent = main

-- Soft edge fade (fake blur) - only non-important area
local edge = Instance.new("Frame")
edge.Name = "EdgeFade"
edge.BackgroundTransparency = 1
edge.Size = UDim2.new(1, 0, 1, 0)
edge.Parent = main

local function mk_edge(size, pos, rot)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.Bg
	f.BackgroundTransparency = 1
	f.Size = size
	f.Position = pos
	f.Parent = edge

	local g = Instance.new("UIGradient")
	g.Rotation = rot
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
	return f
end

mk_edge(UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), 90)  -- top
mk_edge(UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), 270) -- bottom
mk_edge(UDim2.new(0, 16, 1, 0), UDim2.new(0, 0, 0, 0), 0)    -- left
mk_edge(UDim2.new(0, 16, 1, 0), UDim2.new(1, -16, 0, 0), 180) -- right

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundColor3 = Theme.Panel
header.BackgroundTransparency = 0.08
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Text = "ToRungHub"
title.Font = Enum.Font.GothamSemibold
title.TextSize = 15
title.TextColor3 = Theme.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(1, -120, 1, 0)
title.Parent = header

local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.fromOffset(30, 24)
btnMin.Position = UDim2.new(1, -68, 0, 5)
btnMin.Text = "—"
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 16
btnMin.TextColor3 = Theme.Muted
btnMin.BackgroundColor3 = Theme.Bg
btnMin.BackgroundTransparency = 0.25
btnMin.Parent = header
Instance.new("UICorner").Parent = btnMin

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.fromOffset(30, 24)
btnClose.Position = UDim2.new(1, -34, 0, 5)
btnClose.Text = "×"
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 18
btnClose.TextColor3 = Theme.Muted
btnClose.BackgroundColor3 = Theme.Bg
btnClose.BackgroundTransparency = 0.25
btnClose.Parent = header
Instance.new("UICorner").Parent = btnClose

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, -34)
sidebar.Position = UDim2.new(0, 0, 0, 34)
sidebar.BackgroundColor3 = Theme.Panel
sidebar.BackgroundTransparency = 0.10
sidebar.Parent = main

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -150, 1, -34)
content.Position = UDim2.new(0, 150, 0, 34)
content.BackgroundTransparency = 1
content.Parent = main

local function mk_label(parent, text, y)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamSemibold
	l.TextSize = 13
	l.TextColor3 = Theme.Muted
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Position = UDim2.fromOffset(14, y)
	l.Size = UDim2.new(1, -28, 0, 18)
	l.Parent = parent
	return l
end

local function mk_button(parent, text, y, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -18, 0, 30)
	b.Position = UDim2.fromOffset(9, y)
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextColor3 = Theme.Text
	b.BackgroundColor3 = Theme.Bg
	b.BackgroundTransparency = 0.35
	b.AutoButtonColor = true
	b.Parent = parent
	Instance.new("UICorner").Parent = b

	b.MouseButton1Click:Connect(function()
		if onClick then onClick() end
	end)
	return b
end

local pages = {}
local function mk_page(name)
	local p = Instance.new("Frame")
	p.Name = name
	p.Visible = false
	p.Size = UDim2.new(1, 0, 1, 0)
	p.BackgroundTransparency = 1
	p.Parent = content
	pages[name] = p
	return p
end

local function show_page(name)
	for n, p in pairs(pages) do
		p.Visible = (n == name)
	end
end

-- Pages
local pageFarm = mk_page("AutoFarm")
local pageSettings = mk_page("Settings")
local pageCredits = mk_page("Credits")

-- Sidebar nav
mk_label(sidebar, "Navigation", 12)

mk_button(sidebar, "Auto Farm", 40, function() show_page("AutoFarm") end)
mk_button(sidebar, "Settings", 76, function() show_page("Settings") end)
mk_button(sidebar, "Credits", 112, function() show_page("Credits") end)

-- AutoFarm controls (requested: auto start, 20s haki, 8s fruit, fix attack)
mk_label(pageFarm, "Auto Farm", 14)

local function mk_toggle(parent, labelText, y, default, onChanged)
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Position = UDim2.fromOffset(14, y)
	wrap.Size = UDim2.new(1, -28, 0, 32)
	wrap.Parent = parent

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = labelText
	t.Font = Enum.Font.Gotham
	t.TextSize = 13
	t.TextColor3 = Theme.Text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Size = UDim2.new(1, -70, 1, 0)
	t.Parent = wrap

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(54, 24)
	btn.Position = UDim2.new(1, -54, 0, 4)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 12
	btn.Parent = wrap
	Instance.new("UICorner").Parent = btn

	local state = default == true
	local function render()
		btn.Text = state and "ON" or "OFF"
		btn.TextColor3 = Theme.Text
		btn.BackgroundColor3 = state and Theme.Good or Theme.Bad
		btn.BackgroundTransparency = 0.15
	end
	render()

	btn.MouseButton1Click:Connect(function()
		state = not state
		render()
		if onChanged then onChanged(state) end
	end)

	return {
		Get = function() return state end,
		Set = function(v) state = v == true; render() end,
	}
end

local function mk_slider(parent, labelText, y, minv, maxv, default, suffix, onChanged)
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Position = UDim2.fromOffset(14, y)
	wrap.Size = UDim2.new(1, -28, 0, 46)
	wrap.Parent = parent

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = labelText
	t.Font = Enum.Font.Gotham
	t.TextSize = 13
	t.TextColor3 = Theme.Text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Size = UDim2.new(1, 0, 0, 18)
	t.Parent = wrap

	local valueLbl = Instance.new("TextLabel")
	valueLbl.BackgroundTransparency = 1
	valueLbl.Font = Enum.Font.Gotham
	valueLbl.TextSize = 12
	valueLbl.TextColor3 = Theme.Muted
	valueLbl.TextXAlignment = Enum.TextXAlignment.Right
	valueLbl.Position = UDim2.new(0, 0, 0, 0)
	valueLbl.Size = UDim2.new(1, 0, 0, 18)
	valueLbl.Parent = wrap

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(0, 24)
	bar.Size = UDim2.new(1, 0, 0, 14)
	bar.BackgroundColor3 = Theme.Panel
	bar.BackgroundTransparency = 0.20
	bar.Parent = wrap
	Instance.new("UICorner").Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Theme.Accent
	fill.BackgroundTransparency = 0.10
	fill.Parent = bar
	Instance.new("UICorner").Parent = fill

	local v = math.clamp(tonumber(default) or minv, minv, maxv)
	local dragging = false

	local function render()
		local alpha = (v - minv) / (maxv - minv)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		valueLbl.Text = tostring(math.floor(v * 100 + 0.5) / 100) .. (suffix or "")
	end

	local function set_from_x(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		v = minv + a * (maxv - minv)
		render()
		if onChanged then onChanged(v) end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			set_from_x(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			set_from_x(input.Position.X)
		end
	end)

	render()
	return {
		Get = function() return v end,
		Set = function(nv) v = math.clamp(tonumber(nv) or v, minv, maxv); render() end,
	}
end

-- Defaults (client side view). Server is authoritative anyway.
local tEnabled = mk_toggle(pageFarm, "Enabled (Auto Start ON)", 44, true, function(v) send_set("Enabled", v) end)
local tBossOnly = mk_toggle(pageFarm, "Boss Only", 80, false, function(v) send_set("BossOnly", v) end)

mk_label(pageFarm, "Targeting", 126)
mk_slider(pageFarm, "Radius", 148, 30, 3000, 300, "m", function(v) send_set("Radius", v) end)
mk_slider(pageFarm, "Attack Range", 202, 6, 200, 24, "m", function(v) send_set("AttackRange", v) end)
mk_slider(pageFarm, "Attack Cooldown", 256, 0.05, 2, 0.18, "s", function(v) send_set("AttackCooldownSeconds", v) end)

-- Requested fixed timers (still adjustable here if you want)
mk_label(pageSettings, "Timers", 14)
mk_slider(pageSettings, "Haki Delay", 36, 0, 120, 20, "s", function(v) send_set("HakiDelaySeconds", v) end)
mk_slider(pageSettings, "Fruit Interval", 90, 1, 120, 8, "s", function(v) send_set("FruitIntervalSeconds", v) end)

mk_label(pageSettings, "Visual", 150)
mk_slider(pageSettings, "UI Transparency", 172, 0.05, 0.60, 0.18, "", function(v)
	main.BackgroundTransparency = math.clamp(v, 0.05, 0.60)
end)

local credits = Instance.new("TextLabel")
credits.BackgroundTransparency = 1
credits.TextXAlignment = Enum.TextXAlignment.Left
credits.TextYAlignment = Enum.TextYAlignment.Top
credits.Font = Enum.Font.Gotham
credits.TextSize = 13
credits.TextColor3 = Theme.Muted
credits.Position = UDim2.fromOffset(14, 14)
credits.Size = UDim2.new(1, -28, 1, -28)
credits.Text =
	"ToRungHub\n" ..
	"- AutoStart: ON\n" ..
	"- Haki after 20s, Fruit every 8s\n" ..
	"- Server-authoritative (anti-exploit)\n" ..
	""
credits.Parent = pageCredits

-- Minimize / Close
local minimized = false
local fullSize = main.Size

btnMin.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		main.Size = UDim2.fromOffset(520, 34)
		sidebar.Visible = false
		content.Visible = false
	else
		main.Size = fullSize
		sidebar.Visible = true
		content.Visible = true
	end
end)

btnClose.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- Drag window
do
	local dragging = false
	local dragStartPos
	local startMainPos

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStartPos = input.Position
			startMainPos = main.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStartPos
			main.Position = UDim2.new(startMainPos.X.Scale, startMainPos.X.Offset + delta.X, startMainPos.Y.Scale, startMainPos.Y.Offset + delta.Y)
		end
	end)
end

-- Hotkey show/hide
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		gui.Enabled = not gui.Enabled
	end
end)

-- Init
show_page("AutoFarm")
send_set("Enabled", true) -- ensures server state is ON even if you change Defaults later
