--// =========================================================
--// File: ReplicatedStorage/ToRungHub/Theme.lua
--// =========================================================
--!strict

local Theme = {}

Theme.Name = "ToRungHub"

Theme.FontTitle = Enum.Font.GothamBold
Theme.Font = Enum.Font.Gotham
Theme.FontMono = Enum.Font.Code

Theme.TextSizeTitle = 14
Theme.TextSize = 12
Theme.TextSizeSmall = 11

Theme.Radius = 12

Theme.WindowSize = Vector2.new(520, 360)
Theme.SidebarWidth = 160
Theme.TopbarHeight = 36

Theme.Colors = {
	Bg = Color3.fromRGB(14, 14, 16),
	Panel = Color3.fromRGB(18, 18, 20),
	Panel2 = Color3.fromRGB(22, 22, 25),
	Stroke = Color3.fromRGB(255, 255, 255),

	Text = Color3.fromRGB(240, 240, 240),
	Muted = Color3.fromRGB(175, 175, 175),

	Accent = Color3.fromRGB(210, 210, 210),
	Good = Color3.fromRGB(140, 255, 140),
	Bad = Color3.fromRGB(255, 170, 170),
}

Theme.Transparency = {
	Window = 0.12,
	Panel = 0.18,
	Topbar = 0.14,
	Stroke = 0.86,
	Shadow = 0.45,
}

return Theme
