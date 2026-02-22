--!strict
-- CleanMenu.lua
-- HIGGI v2 Menu Shell (No features yet)
-- Reuses existing ToggleSwitches.lua system

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIG (same color system)
------------------------------------------------------------

local CONFIG = {
	GuiName = "HiggiCleanGui",
	ToggleButtonName = "MenuToggleButton",

	PopupSize = Vector2.new(560, 380),

	Accent = Color3.fromRGB(255, 0, 255),
	Bg = Color3.fromRGB(14, 14, 16),
	Bg2 = Color3.fromRGB(20, 20, 24),
	Bg3 = Color3.fromRGB(26, 26, 32),
	Text = Color3.fromRGB(240, 240, 244),
	SubText = Color3.fromRGB(170, 170, 180),
	Stroke = Color3.fromRGB(55, 55, 65),
}

------------------------------------------------------------
-- UTIL
------------------------------------------------------------

local function make(t, p)
	local i = Instance.new(t)
	if p then
		for k,v in pairs(p) do
			i[k] = v
		end
	end
	return i
end

local function addCorner(parent, r)
	make("UICorner", {
		CornerRadius = UDim.new(0, r),
		Parent = parent,
	})
end

local function addStroke(parent, t, c, tr)
	make("UIStroke", {
		Thickness = t,
		Color = c,
		Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

------------------------------------------------------------
-- TOGGLE MODULE LOAD (reuse existing)
------------------------------------------------------------

local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/ToggleSwitches.lua"

local function loadModule(url)
	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		error(code)
	end

	local chunk = loadstring(code)
	return chunk()
end

local Toggles = loadModule(TOGGLES_URL)

local G = (typeof(getgenv) == "function" and getgenv()) or _G
G.__HIGGI_TOGGLES_API = Toggles

------------------------------------------------------------
-- GUI BUILD
------------------------------------------------------------

local old = playerGui:FindFirstChild(CONFIG.GuiName)
if old then
	old:Destroy()
end

local screen = make("ScreenGui", {
	Name = CONFIG.GuiName,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

------------------------------------------------------------
-- Floating Toggle Button
------------------------------------------------------------

local toggleBtn = make("ImageButton", {
	Name = CONFIG.ToggleButtonName,
	Size = UDim2.fromOffset(44, 44),
	Position = UDim2.fromOffset(16, 80),
	BackgroundColor3 = CONFIG.Bg2,
	Parent = screen,
})
addCorner(toggleBtn, 22)
addStroke(toggleBtn, 1, CONFIG.Stroke, 0.25)

------------------------------------------------------------
-- Popup
------------------------------------------------------------

local popup = make("Frame", {
	Size = UDim2.fromOffset(CONFIG.PopupSize.X, CONFIG.PopupSize.Y),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = CONFIG.Bg,
	Visible = false,
	Parent = screen,
})
addCorner(popup, 16)
addStroke(popup, 1, CONFIG.Stroke, 0.2)

------------------------------------------------------------
-- HEADER
------------------------------------------------------------

local header = make("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	Parent = popup,
})

local title = make("TextLabel", {
	Text = "HIGGI v2",
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = CONFIG.Accent,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, -60, 1, 0),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Parent = header,
})

local close = make("TextButton", {
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Size = UDim2.fromOffset(32, 28),
	Position = UDim2.new(1, -42, 0, 8),
	BackgroundColor3 = CONFIG.Bg2,
	TextColor3 = CONFIG.Text,
	Parent = header,
})
addCorner(close, 8)
addStroke(close, 1, CONFIG.Stroke, 0.25)

------------------------------------------------------------
-- TAB BAR
------------------------------------------------------------

local tabBar = make("Frame", {
	Size = UDim2.new(1, -24, 0, 40),
	Position = UDim2.new(0, 12, 0, 44),
	BackgroundTransparency = 1,
	Parent = popup,
})

local tabLayout = make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	Parent = tabBar,
})

local tabs = { "Main", "Visuals", "World", "Misc", "Settings" }

local pages = {}

------------------------------------------------------------
-- CONTENT AREA (2 COLUMN GRID)
------------------------------------------------------------

local content = make("Frame", {
	Size = UDim2.new(1, -24, 1, -100),
	Position = UDim2.new(0, 12, 0, 88),
	BackgroundTransparency = 1,
	Parent = popup,
})

local function makePage(name)
	local page = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0,0,0,0),
		ScrollBarThickness = 4,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = content,
	})

	local grid = make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 70),
		CellPadding = UDim2.new(0, 12, 0, 12),
		Parent = page,
	})

	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0,0,0,grid.AbsoluteContentSize.Y + 10)
	end)

	return page
end

for _,name in ipairs(tabs) do
	pages[name] = makePage(name)

	local btn = make("TextButton", {
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Size = UDim2.fromOffset(100, 34),
		BackgroundColor3 = CONFIG.Bg2,
		TextColor3 = CONFIG.Text,
		Parent = tabBar,
	})
	addCorner(btn, 8)
	addStroke(btn, 1, CONFIG.Stroke, 0.3)

	btn.MouseButton1Click:Connect(function()
		for _,p in pairs(pages) do
			p.Visible = false
		end
		pages[name].Visible = true
	end)
end

pages["Main"].Visible = true

------------------------------------------------------------
-- SAMPLE PLACEHOLDER TOGGLES (2 COLUMN DEMO)
------------------------------------------------------------

local SERVICES = {
	TweenService = TweenService,
	UserInputService = UserInputService,
	Overlay = screen,
}

Toggles.AddToggleCard(
	pages["Main"],
	"example_toggle_1",
	"Example Toggle",
	"Placeholder toggle card.",
	1,
	false,
	CONFIG,
	SERVICES,
	nil
)

Toggles.AddToggleCard(
	pages["Main"],
	"example_toggle_2",
	"Second Toggle",
	"Second placeholder.",
	2,
	false,
	CONFIG,
	SERVICES,
	nil
)

------------------------------------------------------------
-- OPEN / CLOSE LOGIC
------------------------------------------------------------

toggleBtn.MouseButton1Click:Connect(function()
	popup.Visible = not popup.Visible
end)

close.MouseButton1Click:Connect(function()
	popup.Visible = false
end)

------------------------------------------------------------
-- RGB ACCENT SYSTEM
------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	if Toggles.GetState("settings_rgb_accent", false) then
		local t = tick() * 0.8
		CONFIG.Accent = Color3.fromHSV((t % 5)/5, 1, 1)
	end
	title.TextColor3 = CONFIG.Accent
end)
