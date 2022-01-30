local love = require("love")
local argparse = require("libs.argparse")

local nvi = {}

local cmdParser
local visPath
local resolutionScaling = 1

local function formatVersion(major, minor, patch)
	return string.format("%d.%d.%d", major, minor, patch)
end

local VER_MAJOR = 1
local VER_MINOR = 0
local VER_PATCH = 0
local VER_STRING = formatVersion(VER_MAJOR, VER_MINOR, VER_PATCH)

function nvi.saveWindowData()
	if love.window.isOpen() then
		local w, h, d = love.window.getMode()
		assert(love.filesystem.write("nvi_window.txt", string.format("%d,%d,%d", w, h, d.display)))
	end
end

local function getWindowData()
	local data = love.filesystem.read("nvi_window.txt")

	if data then
		local w, h, d = data:match("(%d+),(%d+),(%d+)")

		if w and h and d then
			return tonumber(w), tonumber(h), tonumber(d)
		end
	end

	return 1280, 720, 1
end

function nvi.createWindow()
	local w, h, d = getWindowData()

	love.window.setTitle("NVi Framework")
	love.window.setMode(w, h, {
		display = d,
		highdpi = true,
		minwidth = 320,
		minheight = 240,
		vsync = -1
	})
end

function nvi.assertVersion(major, minor, patch)
	if VER_MAJOR < major then
		error("visualizer requires NVi "..formatVersion(major, minor, patch).." but current NVi version is "..VER_STRING)
	elseif VER_MAJOR > major then
		return
	end

	if VER_MINOR < minor then
		error("visualizer requires NVi "..formatVersion(major, minor, patch).." but current NVi version is "..VER_STRING)
	elseif VER_MINOR > minor then
		return
	end

	if VER_PATCH < patch then
		error("visualizer requires NVi "..formatVersion(major, minor, patch).." but current NVi version is "..VER_STRING)
	elseif VER_PATCH > patch then
		return
	end
end

---@param name string
function nvi.loadVisualizerArgparse(name)
	if name == nil then
		cmdParser = nil
	else
		cmdParser = argparse(name, "Visualizer-specific options")
	end
end

function nvi.getArgparse()
	return assert(cmdParser, "command-line system is unavailable in this context")
end

---@return string
function nvi.getVisualizerPath()
	return visPath
end

---@param path string
function nvi.setVisualizerPath(path)
	if path:sub(-1) ~= "/" then
		visPath = path.."/"
	else
		visPath = path
	end
end

function nvi.resolveVisualizerPath(path)
	return visPath..path
end

function nvi.getScaling()
	return resolutionScaling
end

---@param scale integer
function nvi.setScaling(scale)
	resolutionScaling = scale
end

function nvi.getDPIScale()
	return math.ceil(resolutionScaling)
end

function nvi.getDownscalingFactor()
	return resolutionScaling / nvi.getDPIScale()
end

return nvi
