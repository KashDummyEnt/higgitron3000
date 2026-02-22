--!strict
-- CleanMenu.lua
-- HIGGI v2 Polished Layout (Correct Grid Width)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local CONFIG = {
	GuiName = "HiggiCleanGui",
	ToggleButtonName = "MenuToggleButton",

	PopupSize = Vector2.new(600, 400),

	BaseAccent = Color3.fromRGB(255, 0, 0),
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
-- LOAD TOGGLE MODULE
------------------------------------------------------------

local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/ToggleSwitches.lua"

local function loadModule(url)
	local code = game:HttpGet(url)
	return loadstring(code)()
end

local Toggles = loadModule(TOGGLES_URL)
local G = (typeof(getgenv) == "function" and getgenv()) or _G
G.__HIGGI_TOGGLES_API = Toggles

------------------------------------------------------------
-- BUILD GUI
------------------------------------------------------------

local old = playerGui:FindFirstChild(CONFIG.GuiName)
if old then old:Destroy() end

local screen = make("ScreenGui", {
	Name = CONFIG.GuiName,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

------------------------------------------------------------
-- FLOATING BUTTON
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
-- POPUP
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
	Position = UDim2.new(0, 12, 0, 52),
	BackgroundTransparency = 1,
	Parent = popup,
})

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	Parent = tabBar,
})

-- Divider ABOVE tabs (correct position)
make("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.new(0, 12, 0, 44),
	BackgroundColor3 = CONFIG.Stroke,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	Parent = popup,
})

local tabs = { "Main", "Visuals", "World", "Misc", "Settings" }
local pages = {}
local tabButtons = {}
local currentTab = "Main"

------------------------------------------------------------
-- CONTENT AREA
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

	make("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		Parent = page,
	})

	-- PERFECT WIDTH FOR 16PX SYMMETRY
	local CARD_WIDTH = 276
	local CARD_HEIGHT = 76
	local GAP = 16

	local grid = make("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT),
		CellPadding = UDim2.fromOffset(GAP, GAP),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = page,
	})

	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0,0,0,grid.AbsoluteContentSize.Y + 10)
	end)

	return page
end

------------------------------------------------------------
-- CREATE TABS
------------------------------------------------------------

for _,name in ipairs(tabs) do
	pages[name] = makePage(name)

	local btn = make("TextButton", {
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Size = UDim2.fromOffset(110, 34),
		BackgroundColor3 = CONFIG.Bg2,
		TextColor3 = CONFIG.Text,
		Parent = tabBar,
	})
	addCorner(btn, 8)
	addStroke(btn, 1, CONFIG.Stroke, 0.3)

	tabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		currentTab = name
		for tab,page in pairs(pages) do
			page.Visible = (tab == name)
		end
	end)
end

pages["Main"].Visible = true

------------------------------------------------------------
-- DEMO TOGGLES
------------------------------------------------------------

local SERVICES = {
	TweenService = TweenService,
	UserInputService = UserInputService,
	Overlay = screen,
}

Toggles.AddToggleCard(pages["Main"], "aimbot", "Aimbot", "Placeholder toggle card.", 1, false, CONFIG, SERVICES, nil)
Toggles.AddToggleCard(pages["Main"], "esp", "ESP", "Second placeholder.", 2, false, CONFIG, SERVICES, nil)
Toggles.AddToggleCard(pages["Settings"], "settings_rgb_accent", "RGB Accent", "Animate accent color.", 1, false, CONFIG, SERVICES, nil)

------------------------------------------------------------
-- OPEN/CLOSE
------------------------------------------------------------

toggleBtn.MouseButton1Click:Connect(function()
	popup.Visible = not popup.Visible
end)

close.MouseButton1Click:Connect(function()
	popup.Visible = false
end)

------------------------------------------------------------
-- RGB + ACTIVE TAB
------------------------------------------------------------

RunService.RenderStepped:Connect(function()

	if Toggles.GetState("settings_rgb_accent", false) then
		local t = tick() * 0.5
		CONFIG.Accent = Color3.fromHSV((t % 5)/5, 1, 1)
	else
		CONFIG.Accent = CONFIG.BaseAccent
	end

	title.TextColor3 = CONFIG.Accent

	for name,btn in pairs(tabButtons) do
		if name == currentTab then
			btn.BackgroundColor3 = CONFIG.Accent
			btn.TextColor3 = Color3.fromRGB(0,0,0)
		else
			btn.BackgroundColor3 = CONFIG.Bg2
			btn.TextColor3 = CONFIG.Text
		end
	end
end)
