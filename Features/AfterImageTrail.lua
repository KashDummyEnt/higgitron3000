--!strict
-- AfterImageTrail_Sandevistan_Tight.lua
-- Toggle key: "misc_afterimage"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

------------------------------------------------------------
-- GLOBAL ACCESS (for toggle API)
------------------------------------------------------------

local function getGlobal(): any
	local gg = (typeof(getgenv) == "function") and getgenv() or nil
	if gg then
		return gg
	end
	return _G
end

local G = getGlobal()

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

local TRAIL_INTERVAL = 0.028
local FADE_TIME = 0.38
local START_TRANSPARENCY = 0.18

local HUE_STEP = 0.015
local SATURATION = 0.7
local VALUE = 0.6

local BACK_OFFSET_DISTANCE = 0.35

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local enabled = false
local connection: RBXScriptConnection? = nil
local accumulator = 0
local currentHue = 0

------------------------------------------------------------
-- COLOR
------------------------------------------------------------

local function getNextGradientColor(): Color3
	currentHue += HUE_STEP
	if currentHue > 1 then
		currentHue -= 1
	end
	return Color3.fromHSV(currentHue, SATURATION, VALUE)
end

------------------------------------------------------------
-- CREATE AFTERIMAGE (UNCHANGED LOGIC)
------------------------------------------------------------

local function createAfterImage(char: Model, moveDirection: Vector3)
	if not char then return end

	local offset = Vector3.zero
	if moveDirection.Magnitude > 0 then
		offset = -moveDirection.Unit * BACK_OFFSET_DISTANCE
	end

	local ghostModel = Instance.new("Model")
	ghostModel.Name = "AfterImage"
	ghostModel.Parent = workspace

	local ghostColor = getNextGradientColor()

	-- BODY
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			
			if obj.Name == "HumanoidRootPart" then
				continue
			end
			
			if obj.Parent and obj.Parent:IsA("Accessory") then
				continue
			end

			local newPart = Instance.new(obj.ClassName)
			newPart.Size = obj.Size
			newPart.CFrame = obj.CFrame + offset
			newPart.Anchored = true
			newPart.CanCollide = false
			newPart.CastShadow = false
			newPart.Transparency = START_TRANSPARENCY
			newPart.Material = Enum.Material.SmoothPlastic
			newPart.Color = ghostColor

			if obj:IsA("MeshPart") then
				newPart.MeshId = obj.MeshId
				newPart.TextureID = ""
				newPart.RenderFidelity = obj.RenderFidelity
			end

			local mesh = obj:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				local newMesh = mesh:Clone()
				newMesh.TextureId = ""
				newMesh.Parent = newPart
			end

			newPart.Parent = ghostModel

			TweenService:Create(
				newPart,
				TweenInfo.new(FADE_TIME),
				{ Transparency = 1 }
			):Play()
		end
	end

	-- ACCESSORIES
	for _, accessory in ipairs(char:GetChildren()) do
		if accessory:IsA("Accessory") then
			
			local clonedAccessory = accessory:Clone()
			clonedAccessory.Parent = ghostModel

			for _, obj in ipairs(clonedAccessory:GetDescendants()) do
				
				if obj:IsA("Weld")
				or obj:IsA("Motor6D")
				or obj:IsA("WeldConstraint")
				or obj:IsA("Attachment") then
					obj:Destroy()
				end

				if obj:IsA("BasePart") then
					obj.Anch
