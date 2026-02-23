--!strict
-- CleanMenu.lua
-- HIGGI v2 Polished Layout (Stable Grouped Version)

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
	Accent = Color3.fromRGB(255, 0, 0),

	Bg = Color3.fromRGB(14, 14, 16),
	Bg2 = Color3.fromRGB(20, 20, 24),
	Bg3 = Color3.fromRGB(26, 26, 32),
	Text = Color3.fromRGB(240, 240, 244),
	SubText = Color3.fromRGB(170, 170, 180),
	Stroke = Color3.fromRGB(55, 55, 65),
}


------------------------------------------------------------
-- ACCENT SUBSCRIBE SYSTEM (MUST BE ABOVE SERVICES)
------------------------------------------------------------

local accentListeners = {}

local function subscribeAccent(fn)
	table.insert(accentListeners, fn)
end

local function fireAccentChanged()
	for _, fn in ipairs(accentListeners) do
		fn(CONFIG.Accent)
	end
end
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

local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/ToggleSwitches.lua"
local DRAG_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/DragController.lua"
local PREVIEW_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Menu/Preview.lua"
local EMULATOR_BYPASS_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/EmulatorBypass.lua"


local SKY_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/ClientSky.lua"
local FULLBRIGHT_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/Fullbright.lua"
local NOFOG_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/NoFog.lua"
local ADMINESP_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/AdminESP.lua"
local FLIGHT_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/Flight.lua"
local SPEED_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/PlayerSpeed.lua"
local LOCAL_GRAVITY_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/LocalGravity.lua"
local RAGE_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/Rage.lua"
local WEATHER_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/Weather.lua"
local FASTMODE_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/FastMode.lua"
local AFTERIMAGE_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Features/AfterImageTrail.lua"



local function loadModule(url)
	local code = game:HttpGet(url)
	return loadstring(code)()
end

local Toggles = loadModule(TOGGLES_URL)
local G = (typeof(getgenv) == "function" and getgenv()) or _G
G.__HIGGI_TOGGLES_API = Toggles

local DragController = loadModule(DRAG_URL)

------------------------------------------------------------
-- LAZY FEATURE LOADER
------------------------------------------------------------

local featureLoaded: {[string]: boolean} = {}

local function runRemote(url: string)
	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		warn("HttpGet failed:", code)
		return
	end

	local fn, compileErr = loadstring(code)
	if not fn then
		warn("Compile failed:", compileErr)
		return
	end

	local ok2, runErr = pcall(fn)
	if not ok2 then
		warn("Runtime error:", runErr)
	end
end

local function ensureFeatureLoaded(key: string, url: string)
	if featureLoaded[key] then
		return
	end
	featureLoaded[key] = true
	runRemote(url)
end

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

screen.DisplayOrder = 9999

local inputBlocker = make("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 1,
	Parent = screen,
})

------------------------------------------------------------
-- SERVICES TABLE (REQUIRED FOR TOGGLE MODULE)
------------------------------------------------------------

local SERVICES = {
	TweenService = TweenService,
	UserInputService = UserInputService,
	Overlay = screen,
	SubscribeAccent = subscribeAccent,
}

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
-- GROUP CONTAINER (CENTERED)
------------------------------------------------------------

local PREVIEW_WIDTH = 210
local PREVIEW_GAP = 16
local PREVIEW_HEIGHT = CONFIG.PopupSize.Y - 32 -- slightly shorter

local GROUP_WIDTH = CONFIG.PopupSize.X + PREVIEW_GAP + PREVIEW_WIDTH
local GROUP_HEIGHT = CONFIG.PopupSize.Y

local popupGroup = make("Frame", {
	Size = UDim2.fromOffset(GROUP_WIDTH, GROUP_HEIGHT),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screen,
})

popupGroup.ZIndex = 2

------------------------------------------------------------
-- MAIN MENU PANEL
------------------------------------------------------------

local popup = make("Frame", {
	Size = UDim2.fromOffset(CONFIG.PopupSize.X, CONFIG.PopupSize.Y),
	Position = UDim2.fromOffset(0, 0),
	BackgroundColor3 = CONFIG.Bg,
	Parent = popupGroup,
})
addCorner(popup, 16)
addStroke(popup, 1, CONFIG.Stroke, 0.2)

------------------------------------------------------------
-- PREVIEW PANEL
------------------------------------------------------------

local previewPanel = make("Frame", {
	Size = UDim2.fromOffset(PREVIEW_WIDTH, PREVIEW_HEIGHT),
	Position = UDim2.fromOffset(
		CONFIG.PopupSize.X + PREVIEW_GAP,
		(GROUP_HEIGHT - PREVIEW_HEIGHT) / 2
	),
	BackgroundColor3 = CONFIG.Bg,
	Parent = popupGroup,
})
addCorner(previewPanel, 16)
addStroke(previewPanel, 1, CONFIG.Stroke, 0.2)

------------------------------------------------------------
-- VIEWPORT SETUP
------------------------------------------------------------

local viewport = make("ViewportFrame", {
	Size = UDim2.new(1, -12, 1, -12),
	Position = UDim2.fromOffset(6, 6),
	BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(210,210,210),
	LightColor = Color3.fromRGB(255,255,255),
	LightDirection = Vector3.new(-1,-1,-0.5),
	Parent = previewPanel,
})

local world = Instance.new("WorldModel")
world.Parent = viewport

local cam = Instance.new("Camera")
cam.FieldOfView = 30
cam.Parent = viewport
viewport.CurrentCamera = cam

------------------------------------------------------------
-- LOAD PREVIEW MODULE
------------------------------------------------------------

local Preview = loadModule(PREVIEW_URL)

Preview.Init({
	Players = Players,
	RunService = RunService,
	UserInputService = UserInputService,
	Toggles = Toggles,
	Viewport = viewport,
	WorldModel = world,
	Camera = cam,
	PreviewPanel = previewPanel,
})

------------------------------------------------------------
-- HEADER
------------------------------------------------------------

local header = make("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	Parent = popup,
})

local title = make("TextLabel", {
	Text = "EBTware",
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
-- TAB BAR (CENTERED)
------------------------------------------------------------

local TAB_WIDTH = 90
local TAB_GAP = 8
local TAB_COUNT = 5

local TOTAL_TAB_WIDTH =
	(TAB_WIDTH * TAB_COUNT) +
	(TAB_GAP * (TAB_COUNT - 1))

local tabBar = make("Frame", {
	Size = UDim2.fromOffset(TOTAL_TAB_WIDTH, 40),
	Position = UDim2.new(0.5, 0, 0, 54),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Parent = popup,
})

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, TAB_GAP),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Parent = tabBar,
})

-- Divider above tabs
make("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.new(0, 12, 0, 44),
	BackgroundColor3 = CONFIG.Stroke,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	Parent = popup,
})

------------------------------------------------------------
-- CONTENT AREA
------------------------------------------------------------

local content = make("Frame", {
	Size = UDim2.new(1, -24, 1, -100),
	Position = UDim2.new(0, 12, 0, 88),
	BackgroundTransparency = 1,
	Parent = popup,
})

local function makePage()
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

	local CARD_WIDTH = 276
	local GAP = 16

	local columns = make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = page,
	})

	local leftColumn = make("Frame", {
		Name = "Left",
		Size = UDim2.fromOffset(CARD_WIDTH, 0),
		Position = UDim2.new(0.5, -CARD_WIDTH - (GAP/2), 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = columns,
	})

	local rightColumn = make("Frame", {
		Name = "Right",
		Size = UDim2.fromOffset(CARD_WIDTH, 0),
		Position = UDim2.new(0.5, GAP/2, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = columns,
	})

	make("UIListLayout", {
	Padding = UDim.new(0, GAP),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = leftColumn,
	})

	make("UIListLayout", {
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rightColumn,
	})

	local function updateCanvas()
		local height = math.max(leftColumn.AbsoluteSize.Y, rightColumn.AbsoluteSize.Y)
		page.CanvasSize = UDim2.new(0, 0, 0, height + 20)
	end

	leftColumn:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
	rightColumn:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)

	return {
		Page = page,
		Left = leftColumn,
		Right = rightColumn
	}
end



------------------------------------------------------------
-- CREATE TABS
------------------------------------------------------------

local tabs = { "Main", "Visuals", "World", "Misc", "Settings" }
local pages = {}
local tabButtons = {}
local currentTab = "Main"

-- repaint function (safe to call anytime)
local function repaintAccent()
	title.TextColor3 = CONFIG.Accent

	for name, btn in pairs(tabButtons) do
		if name == currentTab then
			btn.BackgroundColor3 = CONFIG.Accent
			btn.TextColor3 = Color3.fromRGB(0, 0, 0)
		else
			btn.BackgroundColor3 = CONFIG.Bg2
			btn.TextColor3 = CONFIG.Text
		end
	end
end

for _, name in ipairs(tabs) do
	local pageData = makePage()
	pages[name] = pageData

	local btn = make("TextButton", {
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Size = UDim2.fromOffset(TAB_WIDTH, 34),
		BackgroundColor3 = CONFIG.Bg2,
		TextColor3 = CONFIG.Text,
		AutoButtonColor = false,
		Parent = tabBar,
	})
	addCorner(btn, 8)
	addStroke(btn, 1, CONFIG.Stroke, 0.3)

	tabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		currentTab = name

		for tab, data in pairs(pages) do
			data.Page.Visible = (tab == name)
		end

		repaintAccent()
	end)
end

-- default visible page
pages["Main"].Page.Visible = true

-- initial color paint
repaintAccent()
------------------------------------------------------------
-- MAIN TAB
------------------------------------------------------------

-- LEFT COLUMN
Toggles.AddToggleCard(pages["Main"].Left, "combat_rage", "Rage Aimbot", "Auto-aim at nearest enemy inside FOV.", 1, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("combat_rage", RAGE_URL) end
end)

Toggles.AddSliderCard(pages["Main"].Left, "combat_rage_fov", "Aim FOV", nil, 2, 20, 400, 120, 5, CONFIG, SERVICES)

Toggles.AddSliderCard(pages["Main"].Left, "combat_rage_smooth", "Smooth", nil, 3, 0, 1, 0.18, 0.01, CONFIG, SERVICES)

-- RIGHT COLUMN
Toggles.AddToggleCard(pages["Main"].Right, "combat_rage_autowall", "Auto Wall", "Allow targeting through walls.", 4, false, CONFIG, SERVICES)

Toggles.AddToggleCard(pages["Main"].Right, "combat_rage_teamcheck", "Team Check", "Ignore players on your team.", 5, true, CONFIG, SERVICES)


------------------------------------------------------------
-- VISUALS TAB
------------------------------------------------------------

-- LEFT
Toggles.AddToggleCard(pages["Visuals"].Left, "visuals_name", "Name ESP", "Show player names.", 1, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("adminesp", ADMINESP_URL) end
end)

Toggles.AddToggleCard(pages["Visuals"].Left, "visuals_health", "Health ESP", "Show player health.", 2, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("adminesp", ADMINESP_URL) end
end)

Toggles.AddToggleCard(pages["Visuals"].Left, "visuals_box3d", "Boxes", "3D wireframe boxes.", 3, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("adminesp", ADMINESP_URL) end
end)

Toggles.AddToggleCard(pages["Visuals"].Right, "visuals_player", "Chams", "Highlight player models.", 4, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("adminesp", ADMINESP_URL) end
end)

Toggles.AddToggleCard(pages["Visuals"].Right, "visuals_snaplines", "Snaplines", "Draw rods from your feet to enemies.", 5, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("adminesp", ADMINESP_URL) end
end)

Toggles.AddToggleCard(pages["Visuals"].Right, "visuals_team", "Show Teammates", "Render ESP on teammates.", 6, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("adminesp", ADMINESP_URL) end
end)


------------------------------------------------------------
-- WORLD TAB
------------------------------------------------------------

-- LEFT

Toggles.AddToggleDropDownCard(pages["World"].Left, "world_skybox", "world_skybox_dropdown", "Skybox", "Enable client skybox and select preset.", 1, false, "Eyes",
	function()
		return {
			"Space Rocks",
			"Red Planet",
			"Cyan Space",
			"Purple Space",
			"Cyan Planet",
			"Neon Borealis",
			"Sunset",
			"Aurora",
			"Error",
			"Dreamy",
			"Emerald Borealis",
			"War",
			"Nuke",
			"Storm",
			"Violet Moon",
			"Toon Moon",
			"Red Moon",
			"Crimson Despair",
			"Corrupted",
			"Dark Matter",
			"Molten",
			"Ghost",
			"Battlerock",
			"Stellar",
			"Grid",
			"Cyberpunk",
			"Emerald Oblivion",
			"Chromatic Horizon",
			"Eyes",
		}
	end,
	CONFIG, SERVICES,
	function(state) if state then ensureFeatureLoaded("world_skybox", SKY_URL) end end,
	function(selected) end
)

Toggles.AddToggleCard(pages["World"].Left, "world_fullbright", "Fullbright", "Force max brightness.", 2, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_fullbright", FULLBRIGHT_URL) end
end)

Toggles.AddToggleCard(pages["World"].Left, "world_nofog", "No Fog", "Reduce fog.", 3, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_nofog", NOFOG_URL) end
end)


-- RIGHT

Toggles.AddToggleDropDownCard(pages["World"].Right, "world_weather", "world_weather_type", "Weather FX", "Enable client weather and select type.", 1, false, "Snow",
	function() return { "Snow" } end,
	CONFIG, SERVICES,
	function(state) if state then ensureFeatureLoaded("world_weather", WEATHER_URL) end end,
	function(selected) end
)

Toggles.AddToggleCard(pages["World"].Right, "world_fastmode", "Fast Mode", "Disable textures & shadows for FPS boost.", 2, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_fastmode", FASTMODE_URL) end
end)

------------------------------------------------------------
-- MISC TAB
------------------------------------------------------------

Toggles.AddToggleCard(pages["Misc"].Left, "world_flight", "Flight", "Free noclip flight.", 1, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_flight", FLIGHT_URL) end
end)

Toggles.AddToggleCard(pages["Misc"].Right, "misc_speed", "Speed Boost", "Increase WalkSpeed.", 2, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("misc_speed", SPEED_URL) end
end)

Toggles.AddToggleCard(pages["Misc"].Left, "misc_local_gravity", "Low Gravity", "Reduce client gravity.", 3, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("misc_local_gravity", LOCAL_GRAVITY_URL) end
end)

Toggles.AddToggleCard(
	pages["Misc"].Right,
	"misc_afterimage",
	"After Image Trail",
	"Sandevistan-style time echo trail.",
	4,
	false,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("misc_afterimage", AFTERIMAGE_URL)
		end
	end
)

------------------------------------------------------------
-- SETTINGS TAB
------------------------------------------------------------

Toggles.AddToggleCard(pages["Settings"].Left, "settings_rgb_accent", "RGB Accent", "Cycle accent color dynamically.", 1, true, CONFIG, SERVICES)

Toggles.AddToggleCard(pages["Settings"].Right, "settings_emulator_bypass", "Emulator Bypass", "Bypasses Emulator Detections.", 2, true, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("settings_emulator_bypass", EMULATOR_BYPASS_URL) end
end)
------------------------------------------------------------
-- RGB ACCENT SYSTEM (PROPER SUBSCRIBE VERSION)
------------------------------------------------------------

local DEFAULT_ACCENT = CONFIG.BaseAccent
local rgbConnection: RBXScriptConnection? = nil
local hue = 0

local function repaintAccent()
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
end

local function startRGB()
	if rgbConnection then return end

	rgbConnection = RunService.RenderStepped:Connect(function(dt)
		hue += dt * 0.2
		if hue > 1 then hue -= 1 end
		CONFIG.Accent = Color3.fromHSV(hue,1,1)
		repaintAccent()
		fireAccentChanged()
	end)
end

local function stopRGB()
	if rgbConnection then
		rgbConnection:Disconnect()
		rgbConnection = nil
	end
	CONFIG.Accent = DEFAULT_ACCENT
	repaintAccent()
	fireAccentChanged()
end

Toggles.Subscribe("settings_rgb_accent", function(state)
	if state then
		startRGB()
	else
		stopRGB()
	end
end)

-- Sync initial RGB state
task.defer(function()
	local state = Toggles.GetState("settings_rgb_accent", true)
	if state then
		startRGB()
	end
end)

------------------------------------------------------------
-- ATTACH DRAG CONTROLLER
------------------------------------------------------------

DragController.Attach(header, popupGroup, UserInputService)

------------------------------------------------------------
-- OPEN / CLOSE
------------------------------------------------------------

local function setMenuState(state: boolean)
	popupGroup.Visible = state
	inputBlocker.Visible = state
	
	if state then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	setMenuState(not popupGroup.Visible)
end)

close.MouseButton1Click:Connect(function()
	setMenuState(false)
end)
