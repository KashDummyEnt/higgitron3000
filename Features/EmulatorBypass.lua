--!strict
-- EmulatorBypass.lua
-- Blocks KBM when touch is detected (mobile + emulator)

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local G = (typeof(getgenv) == "function" and getgenv()) or _G
local function waitForTogglesApi(timeout: number): any?
	local start = os.clock()
	while os.clock() - start < timeout do
		local api = G.__HIGGI_TOGGLES_API
		if type(api) == "table"
		and type(api.Subscribe) == "function"
		and type(api.GetState) == "function" then
			return api
		end
		task.wait(0.05)
	end
	return nil
end

local Toggles = waitForTogglesApi(6)
if not Toggles then
	warn("[EmulatorBypass] Toggle API missing.")
	return
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local blocked = false
local bindings = {}

------------------------------------------------------------
-- DETECTION
------------------------------------------------------------

local function isTouchEnvironment(): boolean
	return UserInputService.TouchEnabled
end

------------------------------------------------------------
-- BLOCK CALLBACK
------------------------------------------------------------

local function blockInput(
	actionName: string,
	inputState: Enum.UserInputState,
	inputObject: InputObject
)
	return Enum.ContextActionResult.Sink
end

------------------------------------------------------------
-- APPLY BLOCKS
------------------------------------------------------------

local function applyBlock()

	if blocked then return end
	if not isTouchEnvironment() then return end

	blocked = true

	-- Keyboard
	for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
		local name = "EMU_BLOCK_KEY_" .. key.Name
		ContextActionService:BindActionAtPriority(
			name,
			blockInput,
			false,
			Enum.ContextActionPriority.High.Value,
			key
		)
		table.insert(bindings, name)
	end

	-- Mouse buttons + movement
	local mouseTypes = {
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.MouseButton2,
		Enum.UserInputType.MouseButton3,
		Enum.UserInputType.MouseMovement,
		Enum.UserInputType.MouseWheel
	}

	for _, inputType in ipairs(mouseTypes) do
		local name = "EMU_BLOCK_MOUSE_" .. tostring(inputType)
		ContextActionService:BindActionAtPriority(
			name,
			blockInput,
			false,
			Enum.ContextActionPriority.High.Value,
			inputType
		)
		table.insert(bindings, name)
	end

	print("[EmulatorBypass] KBM blocked.")
end

------------------------------------------------------------
-- REMOVE BLOCKS
------------------------------------------------------------

local function removeBlock()

	if not blocked then return end

	for _, name in ipairs(bindings) do
		ContextActionService:UnbindAction(name)
	end

	table.clear(bindings)
	blocked = false

	print("[EmulatorBypass] KBM restored.")
end

------------------------------------------------------------
-- TOGGLE LISTENER
------------------------------------------------------------

Toggles.Subscribe("settings_emulator_bypass", function(state)
	if state then
		applyBlock()
	else
		removeBlock()
	end
end)

-- Apply immediately if already enabled
if Toggles.GetState("settings_emulator_bypass") then
	applyBlock()
end
