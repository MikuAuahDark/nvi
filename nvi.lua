local love = require("love")
local argparse = require("libs.argparse")
local ls2x = require("libs.ls2x")
local hasffi
---@type ffilib
local ffi
hasffi, ffi = pcall(require, "ffi")

local nvi = {}

local cmdParser
local visPath
local visAuthor = "nil"
local resolutionScaling = 1

---@class NVi.SongFile
---@field public metadata table<string,string>
---@field public cover love.ImageData
---@field public soundData love.SoundData
local songFile

local function formatVersion(major, minor, patch)
	return string.format("%d.%d.%d", major, minor, patch)
end

local VER_MAJOR = 1
local VER_MINOR = 0
local VER_PATCH = 0
local VER_STRING = formatVersion(VER_MAJOR, VER_MINOR, VER_PATCH)

local nviVersion = {VER_MAJOR, VER_MINOR, VER_PATCH}

local function errorVersion(major, minor, patch)
	error("visualizer requires NVi "..formatVersion(major, minor, patch).." but current NVi version is "..VER_STRING, 2)
end

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
		errorVersion(major, minor, patch)
	elseif VER_MAJOR > major then
		return
	end

	if VER_MINOR < minor then
		errorVersion(major, minor, patch)
	elseif VER_MINOR > minor then
		return
	end

	if VER_PATCH < patch then
		errorVersion(major, minor, patch)
	elseif VER_PATCH > patch then
		return
	end
end

function nvi.setVisualizerVersion(major, minor, patch)
	nviVersion[1], nviVersion[2], nviVersion[3] = major, minor, patch
end

function nvi.getVisualizerVersion()
	return nviVersion[1], nviVersion[2], nviVersion[3]
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

---@param author string
function nvi.setAuthor(author)
	visAuthor = author
end

function nvi.getAuthor()
	return visAuthor
end

function nvi.loadSongFile(path)
	if ls2x.libav then
		local data = ls2x.libav.loadAudioFile(path)

		songFile = {}
		songFile.metadata = data.metadata

		-- Load cover art
		if data.coverArt then
			---@type integer
			local w, h = data.coverArt.width, data.coverArt.height
			local image = love.image.newImageData(w, h, "rgba8")
			ffi.copy(image:getFFIPointer(), data.coverArt.data, w * h * 4)
			ls2x.libav.free(data.coverArt.data)

			songFile.coverArt = cover
		end

		-- Create SoundData
		songFile.soundData = love.sound.newSoundData(data.sampleCount, data.sampleRate, 16, 2)
		ffi.copy(songFile.soundData:getFFIPointer(), data.samples, 2 * 16 * 2)
		ls2x.libav.free(data.samples)
	else
		-- Uh oh
		local f = assert(io.open(path, "rb"))
		local fd = love.filesystem.newFileData(f:read("*a"), path)
		songFile = {
			metadata = {},
			soundData = love.sound.newSoundData(fd)
		}

		f:close()
	end
end

function nvi.getSongData()
	return songFile
end

return nvi
