--!strict
-- Rage.lua
-- Distance-Priority Rage Aimbot (HIGGI SYSTEM)
-- Stable lock handling + no snap on visibility loss

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- DEFAULTS
----------------------------------------------------

local fov = 120
local smoothness = 0.18

----------------------------------------------------
-- GLOBAL TOGGLE ACCESS
----------------------------------------------------

local function getGlobal(): any
	local gg = (typeof(getgenv) == "function") and getgenv() or nil
	if gg then return gg end
	return _G
end

local G = getGlobal()

local function waitForTogglesApi(timeout: number): any?
	local start = os.clock()
	while os.clock() - start < timeout do
		local api = G.__HIGGI_TOGGLES_API
		if type(api) == "table" and type(api.Subscribe) == "function" then
			return api
		end
		task.wait(0.05)
	end
	return nil
end

local Toggles = waitForTogglesApi(6)
if not Toggles then
	warn("[Rage] Toggle API missing")
	return
end

----------------------------------------------------
-- STATE
----------------------------------------------------

local aimBound = false
local AIM_BIND_NAME = "HiggiRageAim"
local fovGui: ScreenGui? = nil
local autoWallEnabled = false

local currentTarget: BasePart? = nil

----------------------------------------------------
-- CAMERA
----------------------------------------------------

local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = workspace.CurrentCamera or Camera
end)

----------------------------------------------------
-- FOV CIRCLE
----------------------------------------------------

local function getFovCircleFrame(): Frame?
	if not fovGui then return nil end
	local circle = fovGui:FindFirstChild("Circle")
	if circle and circle:IsA("Frame") then
		return circle
	end
	return nil
end

local function applyFovToCircle()
	local circle = getFovCircleFrame()
	if not circle then return end
	circle.Size = UDim2.fromOffset(fov * 2, fov * 2)
end

local function createFov()
	if fovGui then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RageFovGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.Size = UDim2.fromOffset(fov * 2, fov * 2)
	circle.BackgroundTransparency = 1
	circle.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = circle

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	fovGui = gui
end

local function destroyFov()
	if fovGui then
		fovGui:Destroy()
		fovGui = nil
	end
end

----------------------------------------------------
-- NPC HELPERS
----------------------------------------------------

local function getZombiesFolder(): Instance?
	return workspace:FindFirstChild("Zombies")
end

local function isZombieModel(model: Instance): boolean
	return model:IsA("Model") and model.Name == "Zombie"
end

local function isAliveZombie(model: Model): boolean
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function getAimPartFromZombie(model: Model): BasePart?
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

----------------------------------------------------
-- VISIBILITY
----------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function isVisible(part: BasePart): boolean
	if not Camera then return false end
	if not LocalPlayer.Character then return false end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	rayParams.FilterDescendantsInstances = {
		LocalPlayer.Character
	}

	local result = workspace:Raycast(origin, direction, rayParams)

	if not result then
		return true
	end

	if result.Instance:IsDescendantOf(part.Parent) then
		return true
	end

	return false
end

----------------------------------------------------
-- TARGETING
----------------------------------------------------

local function getClosestTarget(): BasePart?
	if not Camera then return nil end
	if not LocalPlayer.Character then return nil end

	local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local zombiesFolder = getZombiesFolder()
	if not zombiesFolder then return nil end

	local viewport = Camera.ViewportSize
	local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)

	local bestPart: BasePart? = nil
	local bestWorldDist = math.huge

	for _, npc in ipairs(zombiesFolder:GetChildren()) do
		if not isZombieModel(npc) then continue end

		local zombie = npc :: Model

		if not isAliveZombie(zombie) then continue end

		local part = getAimPartFromZombie(zombie)
		if not part then continue end

		if not autoWallEnabled then
			if not isVisible(part) then
				continue
			end
		end

		local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen or screenPos.Z <= 0 then continue end

		local dx = screenPos.X - center.X
		local dy = screenPos.Y - center.Y
		local dist2 = dx * dx + dy * dy
		if dist2 > fov * fov then continue end

		local worldDist = (part.Position - root.Position).Magnitude

		if worldDist < bestWorldDist then
			bestWorldDist = worldDist
			bestPart = part
		end
	end

	return bestPart
end

----------------------------------------------------
-- SMOOTH AIM
----------------------------------------------------

local function smoothLookAt(targetPos: Vector3)
	if not Camera then return end

	local camCF = Camera.CFrame
	local desired = CFrame.new(camCF.Position, targetPos)

	-- Prevent extreme 180 flips
	if desired.LookVector:Dot(camCF.LookVector) < -0.999 then
		return
	end

	Camera.CFrame = camCF:Lerp(desired, 1 - smoothness)
end

local function rotateCharacterTowards(targetPos: Vector3)
	if not LocalPlayer.Character then return end

	local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local rootPos = root.Position
	local flatTarget = Vector3.new(targetPos.X, rootPos.Y, targetPos.Z)

	local desired = CFrame.new(rootPos, flatTarget)
	root.CFrame = root.CFrame:Lerp(desired, 1 - smoothness)
end

----------------------------------------------------
-- CONTROL
----------------------------------------------------

local function start()
	if aimBound then return end

	createFov()
	applyFovToCircle()

	aimBound = true

	RunService:BindToRenderStep(AIM_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		local newTarget = getClosestTarget()

		if currentTarget then
			if not newTarget or newTarget ~= currentTarget then
				currentTarget = nil
			end
		end

		if not currentTarget and newTarget then
			currentTarget = newTarget
		end

		local character = LocalPlayer.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")

		if currentTarget then
			if hum then
				hum.AutoRotate = false
			end

			local pos = currentTarget.Position
			smoothLookAt(pos)
			rotateCharacterTowards(pos)
		else
			if hum then
				hum.AutoRotate = true
			end
		end
	end)
end

local function stop()
	if aimBound then
		RunService:UnbindFromRenderStep(AIM_BIND_NAME)
		aimBound = false
	end

	local character = LocalPlayer.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.AutoRotate = true
	end

	currentTarget = nil
	destroyFov()
end

----------------------------------------------------
-- VALUE LINKS
----------------------------------------------------

local function applyFromStore()
	fov = Toggles.GetValue("combat_rage_fov", 120)
	smoothness = Toggles.GetValue("combat_rage_smooth", 0.18)
	applyFovToCircle()
end

Toggles.SubscribeValue("combat_rage_fov", function(v)
	fov = v
	applyFovToCircle()
end)

Toggles.SubscribeValue("combat_rage_smooth", function(v)
	smoothness = v
end)

applyFromStore()

----------------------------------------------------
-- TOGGLES
----------------------------------------------------

Toggles.Subscribe("combat_rage", function(state)
	if state then
		start()
	else
		stop()
	end
end)

Toggles.Subscribe("combat_rage_autowall", function(state)
	autoWallEnabled = state
end)

if Toggles.GetState("combat_rage", false) then
	start()
end

autoWallEnabled = Toggles.GetState("combat_rage_autowall", false)







