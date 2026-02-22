--!strict
-- FeatureLoader.lua
-- Handles lazy-loading remote feature scripts

local FeatureLoader = {}

local featureLoaded: {[string]: boolean} = {}

local function runRemote(url: string)
	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)

	if not ok then
		warn("HttpGet failed:", code)
		return
	end

	local fn, compileErr = loadstring(code)
	if not fn then
		warn("Compile failed:", compileErr)
		return
	end

	local ok2, runErr = pcall(fn)
	if not ok2 then
		warn("Runtime error:", runErr)
	end
end

function FeatureLoader.Ensure(key: string, url: string)
	if featureLoaded[key] then
		return
	end

	featureLoaded[key] = true
	runRemote(url)
end

return FeatureLoader
