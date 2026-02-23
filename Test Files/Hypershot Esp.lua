--!strict
-- HighlightSyncedESP.lua
-- 2D Box ESP + Vertical Health (Left) + Name + Snapline
-- Lower minimum size version

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

print("=== 2D BOX ESP STARTED ===")

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------

local BLUE = Color3.fromRGB(0,120,255)

local SNAP_THICKNESS = 0.05
local SNAP_TRANSPARENCY = 0.15

local BOX_THICKNESS = 2
local HEALTH_WIDTH = 2

-- Ultra minimal clamp (failsafe only)
local MIN_BOX_HEIGHT = 6
local MIN_BOX_WIDTH = 3

------------------------------------------------------------------
-- UTIL
------------------------------------------------------------------

local function isCharacterModel(model: Instance): boolean
	if not model:IsA("Model") then return false end
	return model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isGreen(c: Color3): boolean
	return c.G > 0.6 and c.R < 0.4 and c.B < 0.4
end

local function getHighlightColor(model: Model): Color3
	local highlight = model:FindFirstChildOfClass("Highlight")
	if not highlight then return BLUE end

	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	if isGreen(highlight.FillColor) or isGreen(highlight.OutlineColor) then
		highlight.FillColor = BLUE
		highlight.OutlineColor = BLUE
	end

	return highlight.FillColor
end

------------------------------------------------------------------
-- STORAGE
------------------------------------------------------------------

type ESPData = {
	box: Frame,
	stroke: UIStroke,
	healthBg: Frame,
	healthFill: Frame,
	name: TextLabel,
}

local espByModel: {[Model]: ESPData} = {}

------------------------------------------------------------------
-- GUI ROOT
------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Higgi2DESP"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- CREATE ESP
------------------------------------------------------------------

local function createESP(model: Model): ESPData
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = BOX_THICKNESS
	stroke.Parent = box

	local healthBg = Instance.new("Frame")
	healthBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = box

	local healthFill = Instance.new("Frame")
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.Font = Enum.Font.GothamSemibold
	name.TextStrokeTransparency = 0.5
	name.Parent = box

	local data: ESPData = {
		box = box,
		stroke = stroke,
		healthBg = healthBg,
		healthFill = healthFill,
		name = name,
	}

	espByModel[model] = data
	return data
end

local function getESP(model: Model): ESPData
	return espByModel[model] or createESP(model)
end

------------------------------------------------------------------
-- SNAP STORAGE
------------------------------------------------------------------

type SnapData = {
	part: BasePart,
	ad: BoxHandleAdornment,
}

local snapByModel: {[Model]: SnapData} = {}

local function createSnap(model: Model): SnapData
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2,0.2,0.2)
	p.Parent = workspace

	local ad = Instance.new("BoxHandleAdornment")
	ad.Adornee = p
	ad.AlwaysOnTop = true
	ad.ZIndex = 10
	ad.Transparency = SNAP_TRANSPARENCY
	ad.Parent = workspace

	local data: SnapData = {
		part = p,
		ad = ad,
	}

	snapByModel[model] = data
	return data
end

local function getSnap(model: Model): SnapData
	return snapByModel[model] or createSnap(model)
end

------------------------------------------------------------------
-- RENDER LOOP
------------------------------------------------------------------

RunService.RenderStepped:Connect(function()

	local localChar = LocalPlayer.Character
	if not localChar then return end

	local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local localHum = localChar:FindFirstChildOfClass("Humanoid")
	if not localRoot or not localHum then return end

	local origin = localRoot.Position - Vector3.new(0, localHum.HipHeight + (localRoot.Size.Y / 2), 0)

	for _, model in ipairs(workspace:GetDescendants()) do
		if not model:IsA("Model") then continue end
		if not isCharacterModel(model) then continue end
		if model == localChar then continue end

		local hum = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local head = model:FindFirstChild("Head") :: BasePart?

		if not hum or not root or not head or hum.Health <= 0 then
			if espByModel[model] then
				espByModel[model].box.Visible = false
			end
			continue
		end

		local color = getHighlightColor(model)

		local top3D = head.Position + Vector3.new(0,0.5,0)
		local bottom3D = root.Position - Vector3.new(0,hum.HipHeight + (root.Size.Y/2),0)

		local top2D, topOnScreen = Camera:WorldToViewportPoint(top3D)
		local bottom2D, bottomOnScreen = Camera:WorldToViewportPoint(bottom3D)

		if not topOnScreen or not bottomOnScreen then
			if espByModel[model] then
				espByModel[model].box.Visible = false
			end
			continue
		end

		local rawHeight = math.abs(bottom2D.Y - top2D.Y)
		local height = math.max(rawHeight, MIN_BOX_HEIGHT)

		local rawWidth = rawHeight * 0.5
		local width = math.max(rawWidth, MIN_BOX_WIDTH)

		local esp = getESP(model)
		local box = esp.box

		box.Visible = true
		box.Size = UDim2.fromOffset(width, height)
		box.Position = UDim2.fromOffset(top2D.X - width/2, top2D.Y)

		esp.stroke.Color = color

		local plr = Players:GetPlayerFromCharacter(model)
		local displayName = plr and plr.DisplayName or model.Name

		esp.name.Text = displayName
		esp.name.TextColor3 = color
		esp.name.Size = UDim2.new(1,0,0,14)
		esp.name.Position = UDim2.new(0,0,0,-16)

		local hpPercent = math.clamp(hum.Health / hum.MaxHealth,0,1)

		esp.healthBg.Size = UDim2.new(0, HEALTH_WIDTH, 1, 0)
		esp.healthBg.Position = UDim2.new(0, -HEALTH_WIDTH-2, 0, 0)

		esp.healthFill.Size = UDim2.new(1,0, hpPercent,0)
		esp.healthFill.Position = UDim2.new(0,0, 1-hpPercent,0)
		esp.healthFill.BackgroundColor3 = color

		local targetFeet = bottom3D
		local dir = targetFeet - origin
		local len = dir.Magnitude

		if len > 0.1 then
			local mid = origin + dir*0.5
			local snap = getSnap(model)

			snap.part.CFrame = CFrame.lookAt(mid, targetFeet)
			snap.ad.Size = Vector3.new(SNAP_THICKNESS,SNAP_THICKNESS,len)
			snap.ad.Color3 = color
		end
	end
end)

print("=== 2D BOX ESP ACTIVE ===")
