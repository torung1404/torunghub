--// =========================================================
--// File: StarterPlayerScripts/ToRungHub_UI.client.lua
--// =========================================================
--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage:WaitForChild("ToRungHub"):WaitForChild("Theme"))
local Widgets = require(ReplicatedStorage:WaitForChild("ToRungHub"):WaitForChild("Widgets"))
local HPProbe = require(ReplicatedStorage:WaitForChild("ToRungHub"):WaitForChild("HPProbe"))

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

local state = {
	-- UI only (NO persistence)
	tab = "Gameplay",
	dragLocked = false,
	minimized = false,
	visible = true,

	-- Feature toggles (UI only; you can hook to your own server-authorized logic)
	autoStart = false,
	autoHaki = false,
	autoFruit = false,

	radius = 3000,
	followDist = 6,
}

local function mk<T>(className: string, props: any, parent: Instance?): T
	local inst = Instance.new(className) :: any
	for k, v in pairs(props or {}) do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst :: T
end

-- root gui
local existing = playerGui:FindFirstChild(Theme.Name)
if existing then existing:Destroy() end

local gui = mk("ScreenGui", {
	Name = Theme.Name,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
}, playerGui)

-- window
local main = mk("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(Theme.WindowSize.X, Theme.WindowSize.Y),
	Position = UDim2.new(0, 28, 0.35, 0),
	BackgroundColor3 = Theme.Colors.Bg,
	BackgroundTransparency = Theme.Transparency.Window,
	BorderSizePixel = 0,
	Active = true,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, Theme.Radius) }, main)
mk("UIStroke", { Color = Theme.Colors.Stroke, Transparency = Theme.Transparency.Stroke, Thickness = 1 }, main)

Widgets.SoftShadow(main, Theme, 18) -- "mờ viền" kiểu shadow/gradient (không blur toàn màn)

local top = mk("Frame", {
	Name = "Topbar",
	Size = UDim2.new(1, 0, 0, Theme.TopbarHeight),
	BackgroundColor3 = Theme.Colors.Panel,
	BackgroundTransparency = Theme.Transparency.Topbar,
	BorderSizePixel = 0,
}, main)
mk("UICorner", { CornerRadius = UDim.new(0, Theme.Radius) }, top)

local title = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(1, -160, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Theme.FontTitle,
	TextSize = Theme.TextSizeTitle,
	TextColor3 = Theme.Colors.Text,
	Text = Theme.Name,
}, top)

local status = mk("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -260, 0, 0),
	Size = UDim2.fromOffset(140, Theme.TopbarHeight),
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Theme.Font,
	TextSize = Theme.TextSizeSmall,
	TextColor3 = Theme.Colors.Muted,
	Text = "",
}, top)

local function mkTopBtn(text: string, right: number): TextButton
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(34, 26),
		Position = UDim2.new(1, -right, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		AutoButtonColor = false,
		Text = text,
		Font = Theme.FontTitle,
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
		BackgroundColor3 = Theme.Colors.Panel2,
		BackgroundTransparency = Theme.Transparency.Panel,
		BorderSizePixel = 0,
	}, top)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	mk("UIStroke", { Color = Theme.Colors.Stroke, Transparency = 0.9, Thickness = 1 }, b)
	return b
end

local btnLock = mkTopBtn("🔓", 114)
local btnMin = mkTopBtn("–", 76)
local btnClose = mkTopBtn("×", 38)

local body = mk("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(0, Theme.TopbarHeight),
	Size = UDim2.new(1, 0, 1, -Theme.TopbarHeight),
	BackgroundTransparency = 1,
}, main)

local sidebar = mk("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, Theme.SidebarWidth, 1, 0),
	BackgroundColor3 = Theme.Colors.Panel,
	BackgroundTransparency = Theme.Transparency.Panel,
	BorderSizePixel = 0,
}, body)
mk("UIStroke", { Color = Theme.Colors.Stroke, Transparency = 0.92, Thickness = 1 }, sidebar)

local nav = mk("Frame", {
	Name = "Nav",
	Size = UDim2.new(1, -16, 1, -16),
	Position = UDim2.fromOffset(8, 8),
	BackgroundTransparency = 1,
}, sidebar)

mk("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, nav)

local pagesHost = mk("Frame", {
	Name = "Pages",
	Position = UDim2.fromOffset(Theme.SidebarWidth, 0),
	Size = UDim2.new(1, -Theme.SidebarWidth, 1, 0),
	BackgroundTransparency = 1,
}, body)

local function mkPage(name: string): ScrollingFrame
	local p = mk("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, -14, 1, -14),
		Position = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.Transparency.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Visible = false,
	}, pagesHost)

	mk("UICorner", { CornerRadius = UDim.new(0, Theme.Radius) }, p)
	mk("UIStroke", { Color = Theme.Colors.Stroke, Transparency = 0.86, Thickness = 1 }, p)

	local pad = mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	}, p)

	mk("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, p)

	return p
end

local pages = {
	Gameplay = mkPage("Gameplay"),
	Status = mkPage("Status"),
	About = mkPage("About"),
}

local navButtons: { [string]: TextButton } = {}

local function mkNavButton(name: string, icon: string)
	local b = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Colors.Panel2,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Text = "",
	}, nav)
	mk("UICorner", { CornerRadius = UDim.new(0, 10) }, b)

	local ic = mk("TextLabel", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.fromOffset(8, 4),
		BackgroundColor3 = Theme.Colors.Bg,
		BackgroundTransparency = 0.25,
		Text = icon,
		Font = Theme.FontTitle,
		TextSize = 14,
		TextColor3 = Theme.Colors.Text,
	}, b)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, ic)

	local lbl = mk("TextLabel", {
		Size = UDim2.new(1, -48, 1, 0),
		Position = UDim2.fromOffset(42, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.FontTitle,
		TextSize = 12,
		TextColor3 = Theme.Colors.Muted,
		Text = name,
	}, b)

	navButtons[name] = b
	return b, lbl
end

local function setTab(name: string)
	state.tab = name
	for pageName, page in pairs(pages) do
		page.Visible = (pageName == name)
	end
	for btnName, btn in pairs(navButtons) do
		local lbl = btn:FindFirstChildWhichIsA("TextLabel", true)
		if lbl and lbl:IsA("TextLabel") then
			lbl.TextColor3 = (btnName == name) and Theme.Colors.Text or Theme.Colors.Muted
		end
	end
end

do
	local b1 = mkNavButton("Gameplay", "⚙")
	b1.Activated:Connect(function() setTab("Gameplay") end)

	local b2 = mkNavButton("Status", "📈")
	b2.Activated:Connect(function() setTab("Status") end)

	local b3 = mkNavButton("About", "★")
	b3.Activated:Connect(function() setTab("About") end)
end

-- Gameplay page (UI-only toggles)
do
	Widgets.Header(pages.Gameplay, Theme, "Gameplay")
	Widgets.Note(pages.Gameplay, Theme, "Mình chỉ làm UI/HP chuẩn + viền mờ. Logic auto-attack/haki/fruit phải làm server-authorized trong game bạn.")

	Widgets.Toggle(pages.Gameplay, Theme, "Auto Start (UI only)", function()
		return state.autoStart
	end, function(v)
		state.autoStart = v
		status.Text = v and "Start toggled" or ""
	end)

	Widgets.Toggle(pages.Gameplay, Theme, "Auto Haki (UI only)", function()
		return state.autoHaki
	end, function(v)
		state.autoHaki = v
		status.Text = v and "Haki toggled" or ""
	end)

	Widgets.Toggle(pages.Gameplay, Theme, "Auto Fruit (UI only)", function()
		return state.autoFruit
	end, function(v)
		state.autoFruit = v
		status.Text = v and "Fruit toggled" or ""
	end)

	Widgets.Slider(pages.Gameplay, Theme, "Radius", 0, 20000, function()
		return state.radius
	end, function(v)
		state.radius = math.clamp(v, 0, 20000)
	end)

	Widgets.Slider(pages.Gameplay, Theme, "Follow Distance", 1, 60, function()
		return state.followDist
	end, function(v)
		state.followDist = math.clamp(v, 1, 60)
	end)

	Widgets.Button(pages.Gameplay, Theme, "Test Ping", "PING", function()
		status.Text = "Ping"
		task.delay(0.8, function() status.Text = "" end)
	end)
end

-- Status page (HP accurate)
local hpLabel: TextLabel? = nil
do
	Widgets.Header(pages.Status, Theme, "Status")
	Widgets.Note(pages.Status, Theme, "HP lấy trực tiếp từ Humanoid.Health/MaxHealth (chuẩn, không phụ thuộc UI game).")

	local row = Widgets.Row(pages.Status, Theme, 46)
	hpLabel = mk("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Colors.Text,
		Text = "HP: ...",
	})
end

-- About page
do
	Widgets.Header(pages.About, Theme, "About")
	Widgets.Note(pages.About, Theme, "ToRungHub UI kit. Border 'mờ' = soft shadow + gradient edges (không BlurEffect).\nHotkey: RightShift (toggle UI).")
end

-- Window controls
local minimizedSize = UDim2.fromOffset(Theme.WindowSize.X, Theme.TopbarHeight)
local normalSize = main.Size

local function applyMinimize(on: boolean)
	state.minimized = on
	if on then
		main.Size = minimizedSize
		body.Visible = false
		btnMin.Text = "+"
	else
		main.Size = normalSize
		body.Visible = true
		btnMin.Text = "–"
	end
end

local function applyLock(on: boolean)
	state.dragLocked = on
	btnLock.Text = on and "🔒" or "🔓"
end

local function applyVisible(on: boolean)
	state.visible = on
	main.Visible = on
end

btnClose.Activated:Connect(function()
	applyVisible(false)
end)

btnMin.Activated:Connect(function()
	applyMinimize(not state.minimized)
end)

btnLock.Activated:Connect(function()
	applyLock(not state.dragLocked)
end)

-- Dragging
local dragging = false
local dragStart: Vector2? = nil
local startPos: UDim2? = nil

top.InputBegan:Connect(function(input)
	if state.dragLocked then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging or not dragStart or not startPos then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		dragStart = nil
		startPos = nil
	end
end)

-- Hotkey toggle
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		applyVisible(not main.Visible)
	end
end)

-- Live HP update
RunService.RenderStepped:Connect(function()
	if not hpLabel then return end
	local info = HPProbe.Get(plr)
	if not info then
		hpLabel.Text = "HP: (no humanoid)"
		return
	end
	local pct = math.floor(info.percent * 100 + 0.5)
	hpLabel.Text = ("HP: %d / %d (%d%%)"):format(math.floor(info.health + 0.5), math.floor(info.maxHealth + 0.5), pct)
end)

-- init
applyMinimize(false)
applyLock(false)
applyVisible(true)
setTab("Gameplay")
