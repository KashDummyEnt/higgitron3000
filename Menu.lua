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

local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/ToggleSwitches.lua"

local SKY_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/ClientSky.lua"
local FULLBRIGHT_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Fullbright.lua"
local NOFOG_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/NoFog.lua"
local ADMINESP_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/AdminESP.lua"
local FLIGHT_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Flight.lua"
local SPEED_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/PlayerSpeed.lua"
local RAGE_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Rage.lua"
local WEATHER_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/Weather.lua"
local FASTMODE_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/FastMode.lua"

local function loadModule(url)
	local code = game:HttpGet(url)
	return loadstring(code)()
end

local Toggles = loadModule(TOGGLES_URL)
local G = (typeof(getgenv) == "function" and getgenv()) or _G
G.__HIGGI_TOGGLES_API = Toggles


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

local TAB_WIDTH = 110
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

for _,name in ipairs(tabs) do
	local pageData = makePage()
	pages[name] = pageData

	local btn = make("TextButton", {
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Size = UDim2.fromOffset(TAB_WIDTH, 34),
		BackgroundColor3 = CONFIG.Bg2,
		TextColor3 = CONFIG.Text,
		Parent = tabBar,
	})
	addCorner(btn, 8)
	addStroke(btn, 1, CONFIG.Stroke, 0.3)

	tabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		currentTab = name
		for tab,data in pairs(pages) do
			data.Page.Visible = (tab == name)
		end
	end)
end

pages["Main"].Page.Visible = true
------------------------------------------------------------
-- MAIN TAB
------------------------------------------------------------

-- LEFT COLUMN (core aimbot logic)
Toggles.AddToggleCard(
	pages["Main"].Left,
	"combat_rage",
	"Rage Aimbot",
	"Auto-aim at nearest enemy inside FOV.",
	1,
	false,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("combat_rage", RAGE_URL)
		end
	end
)

Toggles.AddSliderCard(
	pages["Main"].Left,
	"combat_rage_fov",
	"Aim FOV",
	nil,
	2,
	20,
	400,
	120,
	5,
	CONFIG,
	SERVICES
)

Toggles.AddSliderCard(
	pages["Main"].Left,
	"combat_rage_smooth",
	"Smooth",
	nil,
	3,
	0,
	1,
	0.18,
	0.01,
	CONFIG,
	SERVICES
)

-- RIGHT COLUMN (modifiers)
Toggles.AddToggleCard(
	pages["Main"].Right,
	"combat_rage_autowall",
	"Auto Wall",
	"Allow targeting through walls.",
	4,
	false,
	CONFIG,
	SERVICES
)

Toggles.AddToggleCard(
	pages["Main"].Right,
	"combat_rage_teamcheck",
	"Team Check",
	"Ignore players on your team.",
	5,
	true,
	CONFIG,
	SERVICES
)


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

-- RIGHT
Toggles.AddToggleCard(
	pages["Visuals"].Right,
	"visuals_player",
	"Chams",
	"Highlight player models.",
	4,
	false,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("adminesp", ADMINESP_URL)
		end
	end
)

Toggles.AddToggleCard(
	pages["Visuals"].Right,
	"visuals_snaplines",
	"Snaplines",
	"Draw rods from your feet to enemies.",
	5,
	false,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("adminesp", ADMINESP_URL)
		end
	end
)

Toggles.AddToggleCard(
	pages["Visuals"].Right,
	"visuals_team",
	"Show Teammates",
	"Render ESP on teammates.",
	6,
	false,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("adminesp", ADMINESP_URL)
		end
	end
)


------------------------------------------------------------
-- WORLD TAB
------------------------------------------------------------

-- LEFT

Toggles.AddToggleDropDownCard(
	pages["World"].Left,
	"world_skybox",	
	"world_skybox_dropdown",
	"Skybox",
	"Enable client skybox and select preset.",
	1, 
	-- Defaults
	false,
	"Eyes", 

	-- Options provider
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

	CONFIG,
	SERVICES,

	-- Toggle changed
	function(state)
		if state then
			ensureFeatureLoaded("world_skybox", SKY_URL)
		end
	end,

	-- Dropdown changed
	function(selected)
		-- ClientSky.lua handles this automatically
	end
)




Toggles.AddToggleCard(pages["World"].Left, "world_fullbright", "Fullbright", "Force max brightness.", 2, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_fullbright", FULLBRIGHT_URL) end
end)

Toggles.AddToggleCard(pages["World"].Left, "world_nofog", "No Fog", "Reduce fog.", 3, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_nofog", NOFOG_URL) end
end)


-- RIGHT

Toggles.AddToggleDropDownCard(
	pages["World"].Right,
	"world_weather",
	"world_weather_type",
	"Weather FX",
	"Enable client weather and select type.",
	1,
	false,
	"Snow",
	function()
		return {
			"Snow",
		}
	end,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("world_weather", WEATHER_URL)
		end
	end,
	function(selected)
	end
)

Toggles.AddToggleCard(
	pages["World"].Right,
	"world_fastmode",
	"Fast Mode",
	"Disable textures & shadows for FPS boost.",
	2,
	false,
	CONFIG,
	SERVICES,
	function(state)
		if state then
			ensureFeatureLoaded("world_fastmode", FASTMODE_URL)
		end
	end
)

------------------------------------------------------------
-- MISC TAB
------------------------------------------------------------

Toggles.AddToggleCard(pages["Misc"].Left, "world_flight", "Flight", "Free noclip flight.", 1, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("world_flight", FLIGHT_URL) end
end)

Toggles.AddToggleCard(pages["Misc"].Right, "misc_speed", "Speed Boost", "Increase WalkSpeed.", 2, false, CONFIG, SERVICES, function(state)
	if state then ensureFeatureLoaded("misc_speed", SPEED_URL) end
end)

------------------------------------------------------------
-- SETTINGS TAB
------------------------------------------------------------

Toggles.AddToggleCard(
	pages["Settings"].Left,
	"settings_rgb_accent",
	"RGB Accent",
	"Cycle accent color dynamically.",
	1,
	false,
	CONFIG,
	SERVICES
)
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
------------------------------------------------------------
-- DRAG GROUP
------------------------------------------------------------

local dragging = false
local dragStart = Vector2.zero
local startPos = UDim2.new()

local function beginDrag(input)
	dragging = true
	dragStart = input.Position
	startPos = popupGroup.Position
end

local function updateDrag(input)
	if not dragging then return end
	local delta = input.Position - dragStart

	popupGroup.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input)
	end
end)

header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		updateDrag(input)
	end
end)

------------------------------------------------------------
-- BUILD AVATAR + PREVIEW ESP
------------------------------------------------------------

local PREVIEW_CHAMS_COLOR = Color3.fromRGB(255, 0, 0)

local preview: Model? = nil
local previewBox: Part? = nil

------------------------------------------------------------
-- NAME
------------------------------------------------------------

local previewNameLabel = Instance.new("TextLabel")
previewNameLabel.Name = "PreviewName"
previewNameLabel.Size = UDim2.new(1, -40, 0, 22)
previewNameLabel.Position = UDim2.new(0, 16, 0, 8)
previewNameLabel.Size = UDim2.new(1, -32, 0, 20)
previewNameLabel.BackgroundTransparency = 1
previewNameLabel.Font = Enum.Font.GothamSemibold
previewNameLabel.TextScaled = true
previewNameLabel.TextColor3 = Color3.fromRGB(255,70,70)
previewNameLabel.TextStrokeTransparency = 0.5
previewNameLabel.Visible = false
previewNameLabel.Parent = previewPanel

------------------------------------------------------------
-- HEALTH BAR (PREVIEW LOOPING VERSION)
------------------------------------------------------------

local previewHealthContainer = Instance.new("Frame")
previewHealthContainer.Size = UDim2.new(1, -40, 0, 8)
previewHealthContainer.Position = UDim2.new(0, 16, 1, -24)
previewHealthContainer.Size = UDim2.new(1, -32, 0, 8)
previewHealthContainer.BackgroundTransparency = 1
previewHealthContainer.Visible = false
previewHealthContainer.Parent = previewPanel

local back = Instance.new("Frame")
back.Size = UDim2.new(1, 0, 1, 0)
back.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
back.BorderSizePixel = 0
back.Parent = previewHealthContainer

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(1, 0)
backCorner.Parent = back

local fill = Instance.new("Frame")
fill.Size = UDim2.new(1, 0, 1, 0)
fill.BorderSizePixel = 0
fill.Parent = back

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill


------------------------------------------------------------
-- COLOR LOGIC (same as AdminESP)
------------------------------------------------------------

local function getHealthColor(pct: number)
	return Color3.fromRGB(
		math.floor(255 * (1 - pct)),
		math.floor(255 * pct),
		70
	)
end

------------------------------------------------------------
-- PREVIEW LOOP ANIMATION (SAFE + STABLE)
------------------------------------------------------------

local previewHealthRunning = false
local previewHealthConn: RBXScriptConnection? = nil
local previewDirection = -1
local previewSpeed = 0.4

local function startPreviewHealthAnimation()

	if previewHealthRunning then
		return
	end

	previewHealthRunning = true
	previewDirection = -1

	-- hard reset to known state
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

	if previewHealthConn then
		previewHealthConn:Disconnect()
		previewHealthConn = nil
	end

	previewHealthConn = RunService.RenderStepped:Connect(function(dt)

		if not previewHealthRunning then
			return
		end

		local currentPct = fill.Size.X.Scale or 1
		local newPct = currentPct + (previewDirection * previewSpeed * dt)

		if newPct <= 0 then
			newPct = 0
			previewDirection = 1
		elseif newPct >= 1 then
			newPct = 1
			previewDirection = -1
		end

		fill.Size = UDim2.new(newPct, 0, 1, 0)

		fill.BackgroundColor3 = Color3.fromRGB(
			math.floor(255 * (1 - newPct)),
			math.floor(255 * newPct),
			0
		)
	end)
end

local function stopPreviewHealthAnimation()

	previewHealthRunning = false

	if previewHealthConn then
		previewHealthConn:Disconnect()
		previewHealthConn = nil
	end
end
------------------------------------------------------------
-- CHAMS (RED ONLY)
------------------------------------------------------------

local originalPartState: {[BasePart]: {
	Material: Enum.Material,
	Color: Color3,
	Transparency: number
}} = {}

local originalTextureState: {[Instance]: any} = {}
local originalParentState: {[Instance]: Instance} = {}

local function applyPreviewChams()
	if not preview then return end

	for _, inst in ipairs(preview:GetDescendants()) do

		if inst:IsA("Decal") or inst:IsA("Texture") then
			originalTextureState[inst] = inst.Transparency
			inst.Transparency = 1

		elseif inst:IsA("SpecialMesh") then
			originalTextureState[inst] = inst.TextureId
			inst.TextureId = ""

		elseif inst:IsA("MeshPart") then
			originalTextureState[inst] = inst.TextureID
			inst.TextureID = ""

		elseif inst:IsA("SurfaceAppearance")
			or inst:IsA("Shirt")
			or inst:IsA("Pants")
			or inst:IsA("ShirtGraphic") then

			originalParentState[inst] = inst.Parent
			inst.Parent = nil
		end
	end

	for _, inst in ipairs(preview:GetDescendants()) do
		if inst:IsA("BasePart") then

			if not originalPartState[inst] then
				originalPartState[inst] = {
					Material = inst.Material,
					Color = inst.Color,
					Transparency = inst.Transparency
				}
			end

			inst.Material = Enum.Material.Neon
			inst.Color = PREVIEW_CHAMS_COLOR
			inst.Transparency = 0
		end
	end
end

local function removePreviewChams()

	for part, data in pairs(originalPartState) do
		if part and part.Parent then
			part.Material = data.Material
			part.Color = data.Color
			part.Transparency = data.Transparency
		end
	end
	table.clear(originalPartState)

	for inst, saved in pairs(originalTextureState) do
		if inst and inst.Parent then
			if inst:IsA("Decal") or inst:IsA("Texture") then
				inst.Transparency = saved
			elseif inst:IsA("SpecialMesh") then
				inst.TextureId = saved
			elseif inst:IsA("MeshPart") then
				inst.TextureID = saved
			end
		end
	end
	table.clear(originalTextureState)

	for inst, parent in pairs(originalParentState) do
		if inst and parent then
			inst.Parent = parent
		end
	end
	table.clear(originalParentState)
end

------------------------------------------------------------
-- BOX (RED ONLY)
------------------------------------------------------------

local function clearPreviewESP()
	if previewBox then
		previewBox:Destroy()
		previewBox = nil
	end
end

local function addPreviewBox()
	if not preview then return end
	
	local box = Instance.new("Part")
	box.Anchored = true
	box.CanCollide = false
	box.Material = Enum.Material.Plastic
	box.Transparency = 0.65
	box.Color = PREVIEW_CHAMS_COLOR
	box.Parent = world
	
	previewBox = box
end

------------------------------------------------------------
-- REFRESH PREVIEW ESP
------------------------------------------------------------

local function refreshPreviewESP()

	clearPreviewESP()
	removePreviewChams()

	------------------------------------------------------------
	-- 3D BOX
	------------------------------------------------------------

	if Toggles.GetState("visuals_box3d") then
		addPreviewBox()
	end

	------------------------------------------------------------
	-- CHAMS
	------------------------------------------------------------

	if Toggles.GetState("visuals_player") then
		applyPreviewChams()
	end

	------------------------------------------------------------
	-- HEALTH
	------------------------------------------------------------

local healthEnabled = Toggles.GetState("visuals_health") == true
previewHealthContainer.Visible = healthEnabled

if healthEnabled then
	startPreviewHealthAnimation()
else
	stopPreviewHealthAnimation()
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
end

	------------------------------------------------------------
	-- NAME
	------------------------------------------------------------

	local nameEnabled = Toggles.GetState("visuals_name") == true
	previewNameLabel.Visible = nameEnabled
end

------------------------------------------------------------
-- BUILD AVATAR
------------------------------------------------------------

local function buildAvatar()
	world:ClearAllChildren()
	preview = nil
	clearPreviewESP()
	removePreviewChams()

	local desc = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	local rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)

	rig.Parent = world
	RunService.Heartbeat:Wait()

	for _, v in ipairs(rig:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
		elseif v:IsA("Script") or v:IsA("LocalScript") then
			v:Destroy()
		end
	end

	rig.PrimaryPart = rig:FindFirstChild("HumanoidRootPart")
	preview = rig

	previewNameLabel.Text = player.DisplayName

	refreshPreviewESP()
end

------------------------------------------------------------
-- TOGGLES
------------------------------------------------------------

Toggles.Subscribe("visuals_box3d", refreshPreviewESP)
Toggles.Subscribe("visuals_health", refreshPreviewESP)
Toggles.Subscribe("visuals_name", refreshPreviewESP)
Toggles.Subscribe("visuals_player", refreshPreviewESP)

buildAvatar()

------------------------------------------------------------
-- PREVIEW MOTION SYSTEM (UNCHANGED EXCEPT REMOVED 3D HEALTH)
------------------------------------------------------------

local draggingPreview = false
local lastX = 0
local rotationY = 0
local velocity = 0

local dragSensitivity = 0.4
local inertiaDamping = 0.92

local idleTimer = 0
local idleDelay = 1.2

local springTargetAngle = 35
local springFrequency = 0.6
local springStiffness = 8
local springDamping = 6
local springVelocity = 0

viewport.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		draggingPreview = true
		lastX = input.Position.X
		idleTimer = 0
	end
end)

viewport.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		draggingPreview = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingPreview then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		
		local delta = input.Position.X - lastX
		lastX = input.Position.X
		
		local applied = delta * dragSensitivity
		
		rotationY += applied
		velocity = applied
		idleTimer = 0
	end
end)

RunService.RenderStepped:Connect(function(dt)

	if not preview or not preview.PrimaryPart then return end

	if not draggingPreview then
		idleTimer += dt
	end

	if not draggingPreview and idleTimer <= idleDelay then
		rotationY += velocity
		velocity *= inertiaDamping
		
		if math.abs(velocity) < 0.01 then
			velocity = 0
		end
	end

	if not draggingPreview and idleTimer > idleDelay then
		local target = math.sin(tick() * springFrequency) * springTargetAngle
		local displacement = target - rotationY
		local force = displacement * springStiffness
		
		springVelocity += force * dt
		springVelocity -= springVelocity * springDamping * dt
		
		rotationY += springVelocity * dt
	end

	preview:SetPrimaryPartCFrame(
		CFrame.new(0,0,0) *
		CFrame.Angles(0, math.rad(180 + rotationY), 0)
	)

	local cf, size = preview:GetBoundingBox()
	local center = cf.Position

	local maxDim = math.max(size.X, size.Y, size.Z)
	local fov = math.rad(cam.FieldOfView)
	local distance = (maxDim / (2 * math.tan(fov / 2))) * 1.25

	cam.CFrame = CFrame.new(center + Vector3.new(0,0,distance), center)

	if previewBox then
	local paddedSize = Vector3.new(
			size.X + 0.05, -- tiny width increase
			size.Y,
			size.Z
		)

		previewBox.Size = paddedSize
		previewBox.CFrame = cf
	end
end)

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
