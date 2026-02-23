--!strict
-- Freecam.lua
-- Stable Heartbeat Freecam (No Snap + Fast Rotation)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local cam = workspace.CurrentCamera

------------------------------------------------------------------
-- TOGGLE API
------------------------------------------------------------------

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
	warn("[Freecam] Toggle API missing")
	return
end

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------

local KEY = "misc_freecam"

local BASE_SPEED = 100
local BOOST_MULT = 2
local ACCEL = 14
local DECEL = 16

local TURN_SENS_MOUSE = 0.004
local TURN_SENS_TOUCH = 0.005

------------------------------------------------------------------
-- SAFETY
------------------------------------------------------------------

if G.__HIGGI_FREECAM and G.__HIGGI_FREECAM.Cleanup then
	G.__HIGGI_FREECAM.Cleanup()
end

G.__HIGGI_FREECAM = {}
local State = G.__HIGGI_FREECAM

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------

local running = false
local boosting = false
local moveUp = false
local moveDown = false

local camPos = Vector3.zero
local yaw = 0
local pitch = 0

local currentVel = Vector3.zero

local hbConn: RBXScriptConnection? = nil
local inputConn: RBXScriptConnection? = nil

local Controls = nil
local originalWalkSpeed = 16
local originalJumpPower = 50

------------------------------------------------------------------
-- MOBILE CONTROLS
------------------------------------------------------------------

local function hookControls()
	local ok, playerModule = pcall(function()
		return require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	end)

	if ok and playerModule then
		Controls = playerModule:GetControls()
	end
end

------------------------------------------------------------------
-- INPUT BINDS
------------------------------------------------------------------

local function bindVertical()

	ContextActionService:BindAction("FreecamUp", function(_, state)
		moveUp = (state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change)
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space)

	ContextActionService:BindAction("FreecamDown", function(_, state)
		moveDown = (state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change)
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.LeftControl, Enum.KeyCode.C)

	ContextActionService:BindAction("FreecamBoost", function(_, state)
		boosting = (state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change)
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift)

end

local function unbindVertical()
	ContextActionService:UnbindAction("FreecamUp")
	ContextActionService:UnbindAction("FreecamDown")
	ContextActionService:UnbindAction("FreecamBoost")
	moveUp = false
	moveDown = false
	boosting = false
end

------------------------------------------------------------------
-- STOP
------------------------------------------------------------------

local function stopFreecam()

	if not running then return end
	running = false

	if hbConn then hbConn:Disconnect() hbConn = nil end
	if inputConn then inputConn:Disconnect() inputConn = nil end

	unbindVertical()

	cam.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = originalWalkSpeed
			hum.JumpPower = originalJumpPower
			hum.AutoRotate = true
		end
	end

	if Controls and Controls.Enable then
		Controls:Enable()
	end

	currentVel = Vector3.zero
end

------------------------------------------------------------------
-- START
------------------------------------------------------------------

local function startFreecam()

	if running then return end
	running = true

	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			originalWalkSpeed = hum.WalkSpeed
			originalJumpPower = hum.JumpPower
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hum.AutoRotate = false
		end
	end

	if Controls and Controls.Disable then
		Controls:Disable()
	end

	cam.CameraType = Enum.CameraType.Scriptable

	camPos = cam.CFrame.Position

	local look = cam.CFrame.LookVector
	yaw = math.atan2(-look.X, -look.Z)
	pitch = math.asin(look.Y)

	bindVertical()

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	inputConn = UserInputService.InputChanged:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseMovement then
			yaw -= input.Delta.X * TURN_SENS_MOUSE
			pitch -= input.Delta.Y * TURN_SENS_MOUSE
		end

		if input.UserInputType == Enum.UserInputType.Touch then
			yaw -= input.Delta.X * TURN_SENS_TOUCH
			pitch -= input.Delta.Y * TURN_SENS_TOUCH
		end

		pitch = math.clamp(pitch, -1.5, 1.5)

	end)

	hbConn = RunService.Heartbeat:Connect(function(dt)

		local mv = Vector3.zero
		if Controls and Controls.GetMoveVector then
			local raw = Controls:GetMoveVector()
			mv = Vector3.new(raw.X, 0, -raw.Z)
		end

		local yMove = 0
		if moveUp then yMove += 1 end
		if moveDown then yMove -= 1 end

		local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)

		local forward = rotation.LookVector
		local right = rotation.RightVector

		local desired = (right * mv.X + forward * mv.Z)
		if desired.Magnitude > 1 then
			desired = desired.Unit
		end

		local speed = BASE_SPEED * (boosting and BOOST_MULT or 1)
		local targetVel = (desired * speed) + Vector3.new(0, yMove * speed, 0)

		local rate = (targetVel.Magnitude > currentVel.Magnitude) and ACCEL or DECEL
		local alpha = math.clamp(rate * dt, 0, 1)
		currentVel = currentVel:Lerp(targetVel, alpha)

		camPos += currentVel * dt
		cam.CFrame = CFrame.new(camPos) * rotation

	end)

end

------------------------------------------------------------------
-- TOGGLE
------------------------------------------------------------------

Toggles.Subscribe(KEY, function(state: boolean)
	if state then
		startFreecam()
	else
		stopFreecam()
	end
end)

if Toggles.GetState(KEY, false) then
	startFreecam()
end

State.Cleanup = function()
	stopFreecam()
end

hookControls()
