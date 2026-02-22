--!strict
-- Avatar Preview GUI (Proper Framing + Weld-Safe + Smooth Rotate)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "AvatarPreviewGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(200, 320)
frame.Position = UDim2.fromScale(0.05, 0.5)
frame.AnchorPoint = Vector2.new(0, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(15,15,18)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = frame

local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1, -16, 1, -16)
viewport.Position = UDim2.fromOffset(8, 8)
viewport.BackgroundTransparency = 1
viewport.Ambient = Color3.fromRGB(210,210,210)
viewport.LightColor = Color3.fromRGB(255,255,255)
viewport.LightDirection = Vector3.new(-1,-1,-0.5)
viewport.Parent = frame

local world = Instance.new("WorldModel")
world.Parent = viewport

local cam = Instance.new("Camera")
cam.FieldOfView = 30
cam.Parent = viewport
viewport.CurrentCamera = cam

--------------------------------------------------
-- BUILD AVATAR SAFELY
--------------------------------------------------

local preview: Model? = nil
local rotationY = 0

local function buildAvatar()
	world:ClearAllChildren()

	local desc = Players:GetHumanoidDescriptionFromUserId(player.UserId)

	local rig = Players:CreateHumanoidModelFromDescription(
		desc,
		Enum.HumanoidRigType.R15
	)

	rig.Name = "Preview"
	rig.Parent = world

	-- Allow welds + accessories to fully attach
	RunService.Heartbeat:Wait()

	for _, v in ipairs(rig:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
		elseif v:IsA("Script") or v:IsA("LocalScript") then
			v:Destroy()
		end
	end

	local root = rig:FindFirstChild("HumanoidRootPart")
	if root then
		rig.PrimaryPart = root
	end

	preview = rig
end

buildAvatar()

--------------------------------------------------
-- CAMERA FIT (CORRECT CENTERING)
--------------------------------------------------

local function update()
	if not preview or not preview.PrimaryPart then
		return
	end

	preview:SetPrimaryPartCFrame(
		CFrame.new(0, 0, 0) *
		CFrame.Angles(0, math.rad(rotationY), 0)
	)

	local cf, size = preview:GetBoundingBox()
	local center = cf.Position

	local maxDim = math.max(size.X, size.Y, size.Z)
	local fov = math.rad(cam.FieldOfView)

	local distance = (maxDim / (2 * math.tan(fov / 2))) * 1.25

	local cameraPosition = center + Vector3.new(0, 0, distance)

	cam.CFrame = CFrame.new(cameraPosition, center)
end

RunService.RenderStepped:Connect(update)

--------------------------------------------------
-- DRAG ROTATION
--------------------------------------------------

local dragging = false
local lastX = 0
local rotationSpeed = 0.45

viewport.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		lastX = input.Position.X
	end
end)

viewport.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position.X - lastX
		lastX = input.Position.X
		rotationY += delta * rotationSpeed
	end
end)

--------------------------------------------------
-- RESPAWN REFRESH
--------------------------------------------------

player.CharacterAdded:Connect(function()
	task.wait(0.4)
	buildAvatar()
end)
