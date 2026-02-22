--!strict
-- CleanMenu.lua
-- New minimalist toggle GUI shell (no features included)

-- Load with:
-- loadstring(game:HttpGet("YOUR_GITHUB_RAW_LINK"))()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
	GuiName = "CleanMenuGui",

	Width = 560,
	Height = 380,

	Accent = Color3.fromRGB(170, 0, 255),
	BgMain = Color3.fromRGB(18,18,22),
	BgSidebar = Color3.fromRGB(22,22,28),
	BgCard = Color3.fromRGB(28,28,35),

	Text = Color3.fromRGB(240,240,245),
	SubText = Color3.fromRGB(170,170,180),
	Stroke = Color3.fromRGB(60,60,70),
}

----------------------------------------------------------------
-- LOAD TOGGLE MODULE (UNCHANGED)
----------------------------------------------------------------
local TOGGLES_URL = "https://raw.githubusercontent.com/KashDummyEnt/higgitron3000/refs/heads/main/ToggleSwitches.lua"

local function loadModule(url: string)
	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then error(code) end

	local fn = loadstring(code)
	if not fn then error("compile fail") end

	local result = fn()
	if type(result) ~= "table" then
		error("Toggle module invalid")
	end

	return result
end

local Toggles = loadModule(TOGGLES_URL)

-- expose globally
local G = (typeof(getgenv) == "function") and getgenv() or _G
G.__HIGGI_TOGGLES_API = Toggles

----------------------------------------------------------------
-- UI HELPERS
----------------------------------------------------------------
local function make(class, props)
	local inst = Instance.new(class)
	if props then
		for k,v in pairs(props) do
			inst[k] = v
		end
	end
	return inst
end

local function addCorner(parent, r)
	make("UICorner", {
		CornerRadius = UDim.new(0,r),
		Parent = parent,
	})
end

local function addStroke(parent)
	make("UIStroke", {
		Color = CONFIG.Stroke,
		Thickness = 1,
		Transparency = 0.3,
		Parent = parent,
	})
end

----------------------------------------------------------------
-- DESTROY OLD
----------------------------------------------------------------
local existing = playerGui:FindFirstChild(CONFIG.GuiName)
if existing then
	existing:Destroy()
end

----------------------------------------------------------------
-- SCREEN GUI
----------------------------------------------------------------
local screenGui = make("ScreenGui", {
	Name = CONFIG.GuiName,
	ResetOnSpawn = false,
	Parent = playerGui,
})

----------------------------------------------------------------
-- MAIN WINDOW
----------------------------------------------------------------
local window = make("Frame", {
	BackgroundColor3 = CONFIG.BgMain,
	Size = UDim2.fromOffset(CONFIG.Width, CONFIG.Height),
	Position = UDim2.fromScale(0.5,0.5),
	AnchorPoint = Vector2.new(0.5,0.5),
	Parent = screenGui,
})
addCorner(window,16)
addStroke(window)

----------------------------------------------------------------
-- HEADER
----------------------------------------------------------------
local header = make("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1,0,0,50),
	Parent = window,
})

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	Text = "CLEAN MENU",
	TextColor3 = CONFIG.Accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Position = UDim2.new(0,20,0,0),
	Size = UDim2.new(1,-20,1,0),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
})

----------------------------------------------------------------
-- BODY
----------------------------------------------------------------
local body = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0,0,0,50),
	Size = UDim2.new(1,0,1,-50),
	Parent = window,
})

----------------------------------------------------------------
-- SIDEBAR
----------------------------------------------------------------
local sidebar = make("Frame", {
	BackgroundColor3 = CONFIG.BgSidebar,
	Size = UDim2.new(0,150,1,0),
	Parent = body,
})
addCorner(sidebar,14)
addStroke(sidebar)

make("UIListLayout", {
	Padding = UDim.new(0,8),
	Parent = sidebar,
})

make("UIPadding", {
	PaddingTop = UDim.new(0,12),
	PaddingLeft = UDim.new(0,12),
	PaddingRight = UDim.new(0,12),
	Parent = sidebar,
})

----------------------------------------------------------------
-- PAGE CONTAINER
----------------------------------------------------------------
local pages = make("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0,160,0,10),
	Size = UDim2.new(1,-170,1,-20),
	Parent = body,
})

----------------------------------------------------------------
-- TAB SYSTEM
----------------------------------------------------------------
local currentTab = nil
local tabButtons = {}

local function createPage(name: string)
	local page = make("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Visible = false,
		Parent = pages,
	})
	return page
end

local function switchTab(name: string)
	for tabName, page in pairs(pages:GetChildren()) do
		if page:IsA("Frame") then
			page.Visible = (page.Name == name)
		end
	end

	for nameBtn, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (nameBtn == name)
			and CONFIG.BgCard
			or CONFIG.BgSidebar
	end

	currentTab = name
end

local function createTab(name: string)
	local btn = make("TextButton", {
		Text = name,
		AutoButtonColor = false,
		TextColor3 = CONFIG.Text,
		BackgroundColor3 = CONFIG.BgSidebar,
		Size = UDim2.new(1,0,0,40),
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Parent = sidebar,
	})
	addCorner(btn,10)

	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)

	tabButtons[name] = btn

	return createPage(name)
end

----------------------------------------------------------------
-- CREATE EMPTY TABS
----------------------------------------------------------------
local pageMain = createTab("Main")
local pageVisuals = createTab("Visuals")
local pageWorld = createTab("World")
local pageMisc = createTab("Misc")
local pageSettings = createTab("Settings")

switchTab("Main")

----------------------------------------------------------------
-- DRAG SYSTEM
----------------------------------------------------------------
do
	local dragging = false
	local dragStart
	local startPos

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
		end
	end)

	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end
