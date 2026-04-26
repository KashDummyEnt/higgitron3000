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

local connection: RBXScriptConnection? = nil
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
	if connection then return end

	connection = RunService.RenderStepped:Connect(function()
		local newTarget = getClosestTarget()

		-- Release lock if target lost
		if currentTarget then
			if not newTarget or newTarget ~= currentTarget then
				currentTarget = nil
			end
		end

		-- Acquire new target
		if not currentTarget and newTarget then
			currentTarget = newTarget
		end

		local character = LocalPlayer.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")

		if currentTarget then
			-- Disable auto rotate ONLY while locked
			if hum then
				hum.AutoRotate = false
			end

			local pos = currentTarget.Position
			smoothLookAt(pos)
			rotateCharacterTowards(pos)
		else
			-- Restore normal player rotation when not locked
			if hum then
				hum.AutoRotate = true
			end
		end
	end)
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	-- Restore AutoRotate when rage disabled
	local character = LocalPlayer.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.AutoRotate = true
	end

	currentTarget = nil
end

----------------------------------------------------
-- VALUE LINKS
----------------------------------------------------

local function applyFromStore()
	smoothness = Toggles.GetValue("combat_rage_smooth", 0.18)
end

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
