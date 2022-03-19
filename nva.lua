local nvi = require("nvi")

local nva = {}

local function generateArgStr(short, long)
	assert(short or long, "need short or long or both")
	local argstr = ""

	if short then
		argstr = "-"..short.." "
	end

	if long then
		argstr = argstr.."--"..long
	end

	return argstr
end

---@param major integer
---@param minor integer
---@param patch integer
function nva.version(major, minor, patch)
	nvi.assertVersion(major, minor or 0, patch or 0)
	nvi.setVisualizerVersion(major, minor or 0, patch or 0)
end

function nva.author(author)
	nvi.setAuthor(author)
end

function nva.registerCommandLineOption(short, long, description, default)
	local argparse = nvi.getArgparse()
	return argparse:option(generateArgStr(short, long), description, tostring(default))
end

function nva.registerCommandLineFlag(short, long, description, default)
	local argparse = nvi.getArgparse()
	return argparse:flag(generateArgStr(short, long), description, tostring(default))
end

---@param path string
---@param asimagedata boolean
function nva.loadLocalImage(path, asimagedata)
	local realPath = nvi.resolveVisualizerPath(path)

	if asimagedata then
		return love.image.newImageData(realPath)
	else
		return love.graphics.newImage(realPath, {mipmaps = true})
	end
end

---@param abspath string
---@param asimagedata boolean
function nva.loadImage(abspath, asimagedata)
	local file = assert(io.open(abspath, "rb"))
	local fileData = love.filesystem.newFileData(file:read("*a"), abspath)

	if asimagedata then
		return love.image.newImageData(fileData)
	else
		return love.graphics.newImage(fileData, {mipmaps = true})
	end
end

---@param path string
---@param size integer
---@param hinting love.HintingMode
function nva.loadLocalFont(path, size, hinting)
	local realPath = nvi.resolveVisualizerPath(path)
	return love.graphics.newFont(realPath, size, hinting or "normal", nvi.getDPIScale())
end

---@param abspath string
---@param size integer
---@param hinting love.HintingMode
function nva.loadFont(abspath, size, hinting)
	local file = assert(io.open(abspath, "rb"))
	local fileData = love.filesystem.newFileData(file:read("*a"), abspath)
	return love.graphics.newFont(fileData, size, hinting or "normal", nvi.getDPIScale())
end

---@param width integer
---@param height integer
---@param pixfmt love.PixelFormat
---@param type love.TextureType
function nva.newCanvas(width, height, pixfmt, type)
	return love.graphics.newCanvas(width, height, {dpiscale = nvi.getDPIScale(), format = pixfmt or "normal", type = type or "2d"})
end

return nva
