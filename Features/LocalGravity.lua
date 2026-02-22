--!strict
-- LocalGravity.lua
-- Toggle key: "misc_local_gravity"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

------------------------------------------------------------
-- GLOBAL ACCESS
------------------------------------------------------------

local function getGlobal(): any
	local gg = (typeof(getgenv) == "function") and getgenv() or nil
	if gg then
		return gg
	end
	return _G
end

local G = getGlobal()

local TOGGLE_KEY = "misc_local_gravity"

------------------------------------------------------------
-- WAIT FOR TOGGLE API
------------------------------------------------------------

local function waitForTogglesApi(timeoutSeconds: number): any?
	local start = os.clock()

	while os.clock() - start < timeoutSeconds do
		local api = G.__HIGGI_TOGGLES_API
		if type(api) == "table"
		and type(api.GetState) == "function"
		and type(api.Subscribe) == "function" then
			return api
		end
		task.wait(0.05)
	end

	return nil
end

local Toggles = waitForTogglesApi(6)
if not Toggles then
	warn("[LocalGravity] Toggle API missing")
	return
end

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local CUSTOM_GRAVITY = 80
local DEFAULT_GRAVITY = workspace.Gravity

local gravityForce: VectorForce? = nil
local attachment: Attachment? = nil
local enabled = false

------------------------------------------------------------
-- SETUP
------------------------------------------------------------

local function setupCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	if gravityForce then
		gravityForce:Destroy()
		gravityForce = nil
	end

	if attachment then
		attachment:Destroy()
		attachment = nil
	end

	attachment = Instance.new("Attachment")
	attachment.Parent = root

	gravityForce = Instance.new("VectorForce")
	gravityForce.Attachment0 = attachment
	gravityForce.RelativeTo = Enum.ActuatorRelativeTo.World
	gravityForce.ApplyAtCenterOfMass = true
	gravityForce.Parent = root
end

------------------------------------------------------------
-- UPDATE LOOP
------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not enabled then
		if gravityForce then
			gravityForce.Force = Vector3.zero
		end
		return
	end

	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	if not gravityForce then return end

	local mass = root.AssemblyMass
	local gravityDifference = CUSTOM_GRAVITY - DEFAULT_GRAVITY

	local force = Vector3.new(0, -gravityDifference * mass, 0)
	gravityForce.Force = force
end)

------------------------------------------------------------
-- ENABLE / DISABLE
------------------------------------------------------------

local function setEnabled(state: boolean)
	enabled = state

	if enabled then
		if player.Character then
			setupCharacter(player.Character)
		end
	else
		if gravityForce then
			gravityForce.Force = Vector3.zero
		end
	end
end

------------------------------------------------------------
-- TOGGLE LISTENER
------------------------------------------------------------

Toggles.Subscribe(TOGGLE_KEY, function(state: boolean)
	setEnabled(state)
end)

player.CharacterAdded:Connect(function(char)
	if enabled then
		setupCharacter(char)
	end
end)

------------------------------------------------------------
-- APPLY CURRENT STATE ON LOAD
------------------------------------------------------------

setEnabled(Toggles.GetState(TOGGLE_KEY, false))
