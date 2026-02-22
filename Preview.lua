--!strict
-- Preview.lua
-- Handles viewport avatar + preview ESP + motion

local Preview = {}

------------------------------------------------------------
-- INIT
------------------------------------------------------------

function Preview.Init(deps)

	local Players = deps.Players
	local RunService = deps.RunService
	local UserInputService = deps.UserInputService
	local Toggles = deps.Toggles
	local viewport = deps.Viewport
	local world = deps.WorldModel
	local cam = deps.Camera
	local previewPanel = deps.PreviewPanel
	local player = Players.LocalPlayer

	------------------------------------------------------------
	-- STATE
	------------------------------------------------------------

	local PREVIEW_CHAMS_COLOR = Color3.fromRGB(255,0,0)

	local preview: Model? = nil
	local previewBox: Part? = nil

	------------------------------------------------------------
	-- NAME
	------------------------------------------------------------

	local previewNameLabel = Instance.new("TextLabel")
	previewNameLabel.Size = UDim2.new(1,-32,0,20)
	previewNameLabel.Position = UDim2.new(0,16,0,8)
	previewNameLabel.BackgroundTransparency = 1
	previewNameLabel.Font = Enum.Font.GothamSemibold
	previewNameLabel.TextScaled = true
	previewNameLabel.TextColor3 = Color3.fromRGB(255,70,70)
	previewNameLabel.TextStrokeTransparency = 0.5
	previewNameLabel.Visible = false
	previewNameLabel.Parent = previewPanel

	------------------------------------------------------------
	-- HEALTH BAR
	------------------------------------------------------------

	local previewHealthContainer = Instance.new("Frame")
	previewHealthContainer.Size = UDim2.new(1,-32,0,8)
	previewHealthContainer.Position = UDim2.new(0,16,1,-24)
	previewHealthContainer.BackgroundTransparency = 1
	previewHealthContainer.Visible = false
	previewHealthContainer.Parent = previewPanel

	local back = Instance.new("Frame")
	back.Size = UDim2.new(1,0,1,0)
	back.BackgroundColor3 = Color3.fromRGB(18,18,18)
	back.BorderSizePixel = 0
	back.Parent = previewHealthContainer

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1,0,1,0)
	fill.BorderSizePixel = 0
	fill.Parent = back

	------------------------------------------------------------
	-- HEALTH ANIMATION
	------------------------------------------------------------

	local healthConn: RBXScriptConnection? = nil
	local direction = -1

	local function startHealth()

		if healthConn then return end

		fill.Size = UDim2.new(1,0,1,0)

		healthConn = RunService.RenderStepped:Connect(function(dt)

			local pct = fill.Size.X.Scale
			local newPct = pct + (direction * 0.4 * dt)

			if newPct <= 0 then
				newPct = 0
				direction = 1
			elseif newPct >= 1 then
				newPct = 1
				direction = -1
			end

			fill.Size = UDim2.new(newPct,0,1,0)
			fill.BackgroundColor3 = Color3.fromRGB(
				math.floor(255*(1-newPct)),
				math.floor(255*newPct),
				0
			)
		end)
	end

	local function stopHealth()
		if healthConn then
			healthConn:Disconnect()
			healthConn = nil
		end
	end

	------------------------------------------------------------
	-- BOX
	------------------------------------------------------------

	local function clearBox()
		if previewBox then
			previewBox:Destroy()
			previewBox = nil
		end
	end

	local function addBox(size, cf)
		local box = Instance.new("Part")
		box.Anchored = true
		box.CanCollide = false
		box.Material = Enum.Material.Plastic
		box.Transparency = 0.65
		box.Color = PREVIEW_CHAMS_COLOR
		box.Size = size
		box.CFrame = cf
		box.Parent = world
		previewBox = box
	end

	------------------------------------------------------------
	-- CHAMS
	------------------------------------------------------------

	local function applyChams()
		if not preview then return end
		for _,inst in ipairs(preview:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst.Material = Enum.Material.Neon
				inst.Color = PREVIEW_CHAMS_COLOR
				inst.Transparency = 0
			end
		end
	end

	------------------------------------------------------------
	-- REFRESH
	------------------------------------------------------------

	local function refresh()

		clearBox()

		if not preview then return end

		local cf, size = preview:GetBoundingBox()

		if Toggles.GetState("visuals_box3d") then
			local padded = Vector3.new(size.X+0.05,size.Y,size.Z)
			addBox(padded, cf)
		end

		if Toggles.GetState("visuals_player") then
			applyChams()
		end

		local healthEnabled = Toggles.GetState("visuals_health")
		previewHealthContainer.Visible = healthEnabled

		if healthEnabled then
			startHealth()
		else
			stopHealth()
		end

		local nameEnabled = Toggles.GetState("visuals_name")
		previewNameLabel.Visible = nameEnabled
	end

	------------------------------------------------------------
	-- BUILD AVATAR
	------------------------------------------------------------

	local function build()

		world:ClearAllChildren()
		preview = nil
		clearBox()

		local desc = Players:GetHumanoidDescriptionFromUserId(player.UserId)
		local rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		rig.Parent = world
		RunService.Heartbeat:Wait()

		rig.PrimaryPart = rig:FindFirstChild("HumanoidRootPart")
		preview = rig

		previewNameLabel.Text = player.DisplayName

		refresh()
	end

	------------------------------------------------------------
	-- MOTION
	------------------------------------------------------------

	local rotationY = 0

	RunService.RenderStepped:Connect(function()
		if not preview or not preview.PrimaryPart then return end

		preview:SetPrimaryPartCFrame(
			CFrame.new(0,0,0) *
			CFrame.Angles(0,math.rad(180+rotationY),0)
		)

		local cf,size = preview:GetBoundingBox()
		local center = cf.Position
		local maxDim = math.max(size.X,size.Y,size.Z)
		local fov = math.rad(cam.FieldOfView)
		local dist = (maxDim/(2*math.tan(fov/2)))*1.25
		cam.CFrame = CFrame.new(center + Vector3.new(0,0,dist), center)

		if previewBox then
			previewBox.Size = Vector3.new(size.X+0.05,size.Y,size.Z)
			previewBox.CFrame = cf
		end
	end)

	------------------------------------------------------------
	-- TOGGLE SUBS
	------------------------------------------------------------

	Toggles.Subscribe("visuals_box3d", refresh)
	Toggles.Subscribe("visuals_health", refresh)
	Toggles.Subscribe("visuals_name", refresh)
	Toggles.Subscribe("visuals_player", refresh)

	build()
end

return Preview
