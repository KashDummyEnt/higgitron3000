--!strict
-- Freecam.lua
-- Mobile + KBM Supported Local Freecam

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

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

local BASE_SPEED = 80
local BOOST_MULT = 2
local ACCEL = 10
local DECEL = 14
local TURN_SENS = 0.25

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------

if G.__HIGGI_FREECAM and G.__HIGGI_FREECAM.Cleanup then
	G.__HIGGI_FREECAM.Cleanup()
end

G.__HIGGI_FREECAM = {}
local State = G.__HIGGI_FREECAM

local cam = workspace.CurrentCamera
local running = false
local boosting = false

local moveUp = false
local moveDown = false

local moveVector = Vector3.zero
local currentVel = Vector3.zero

local rotX = 0
local rotY = 0

local hbConn: RBXScriptConnection? = nil
local inputConn: RBXScriptConnection? = nil

local Controls = nil

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

	currentVel = Vector3.zero
	moveVector = Vector3.zero
end

------------------------------------------------------------------
-- START
------------------------------------------------------------------

local function startFreecam()
	if running then return end
	running = true

	cam.CameraType = Enum.CameraType.Scriptable

	local cf = cam.CFrame
	rotX, rotY = cf:ToOrientation()

	bindVertical()

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	inputConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			rotY -= input.Delta.X * TURN_SENS * 0.01
			rotX -= input.Delta.Y * TURN_SENS * 0.01
			rotX = math.clamp(rotX, -1.5, 1.5)
		end

		if input.UserInputType == Enum.UserInputType.Touch then
			rotY -= input.Delta.X * 0.002
			rotX -= input.Delta.Y * 0.002
			rotX = math.clamp(rotX, -1.5, 1.5)
		end
	end)

	hbConn = RunService.Heartbeat:Connect(function(dt)

		local mv = Vector3.zero

		if Controls and Controls.GetMoveVector then
			local raw = Controls:GetMoveVector()
			mv = Vector3.new(raw.X, 0, -raw.Z)
		else
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				mv = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z)
			end
		end

		local y = 0
		if moveUp then y += 1 end
		if moveDown then y -= 1 end

		local camCF =
			CFrame.new(cam.CFrame.Position)
			* CFrame.Angles(0, rotY, 0)
			* CFrame.Angles(rotX, 0, 0)

		local forward = camCF.LookVector
		local right = camCF.RightVector

		local desired = (right * mv.X + forward * mv.Z)
		if desired.Magnitude > 1 then
			desired = desired.Unit
		end

		local speed = BASE_SPEED * (boosting and BOOST_MULT or 1)
		local targetVel = (desired * speed) + Vector3.new(0, y * speed, 0)

		local rate = (targetVel.Magnitude > currentVel.Magnitude) and ACCEL or DECEL
		local alpha = math.clamp(rate * dt, 0, 1)
		currentVel = currentVel:Lerp(targetVel, alpha)

		local newPos = cam.CFrame.Position + currentVel * dt
		cam.CFrame = CFrame.new(newPos) * CFrame.Angles(0, rotY, 0) * CFrame.Angles(rotX, 0, 0)
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

------------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------------

State.Cleanup = function()
	stopFreecam()
end

hookControls()
