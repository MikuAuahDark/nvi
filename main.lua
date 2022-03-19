local love = require("love")
local nvi = require("nvi")
local argparse = require("libs.argparse")

---@type love.Canvas
local mainCanvas
---@type NVi.BaseVisualizer
local visualizerObject
local inRenderMode = false
local songDuration = 0
local songTime = 0
---@type love.Source
local songSource

local function filterArgs(arg)
	local r, rcomp = {}, {}
	local insert = false
	local inputCount = 0

	for _, v in ipairs(arg) do
		local found = insert

		if insert then
			r[#r + 1] = v
			insert = false
		elseif v:find("--", 1, true) == 1 then
			local a = v:sub(3)

			if a == "render" or a == "dimensions" then
				r[#r + 1] = v
				insert = true
				found = true
			elseif a == "about" or a == "help" or a == "list" then
				r[#r + 1] = v
				found = true
			end
		elseif v:find("-", 1, true) == 1 then
			local a = v:sub(2)

			if a == "r" or a == "d" then
				r[#r + 1] = v
				insert = true
				found = true
			elseif a == "a" or a == "h" or a == "l" then
				r[#r + 1] = v
				found = true
			end
		elseif inputCount < 2 then
			r[#r + 1] = v
			inputCount = inputCount + 1
			found = true
		end

		if not found then
			rcomp[#rcomp + 1] = v
		end
	end

	return r, rcomp
end

local function listVisualizers()
	local result = {}

	for _, dir in ipairs(love.filesystem.getDirectoryItems("nvi")) do
		if love.filesystem.getInfo("nvi/"..dir.."/init.lua", "file") then
			result[#result + 1] = dir
		end
	end

	return result
end

function love.load(arg)
	-- Arg parse
	local parser = argparse("nvi", "NPad Visualizer Framework")
	local exitNow = false
	local realArg, filteredArg = filterArgs(arg)
	parser:argument("songfile", "Music file.")
	parser:argument("visualizer", "Visualizer name.")
	parser:option("-r --render", "Render visualizer to.")
	parser:option("-d --dimensions", "Render visualizer dimensions.", "4k")
		:choices({"720p", "hd", "1080", "fhd", "1440p", "qhd", "2160p", "4k"})
		:convert({
			["720p"] = 1, hd = 1,
			["1080p"] = 1.5, fhd = 1.5,
			["1440p"] = 2, qhd = 2,
			["2160p"] = 3, ["4k"] = 3
		})
	parser:flag("--about", "Show information about this program."):action(function()
		print("NPad Visualizer Framework")
		print()
		print("Licensed under MIT License")
		print()
		exitNow = true
	end)
	parser:flag("-l --list", "List all available visualizers."):action(function()
		print("Available visualizers:")

		for _, v in ipairs(listVisualizers()) do
			print("* "..v)
		end

		print()
		exitNow = true
	end)

	-- Parse main program args
	local status, parsedArgs = parser:pparse(realArg)
	if exitNow then
		love.event.quit(0)
		return
	elseif not status then
		io.stderr:write("Error: ", parsedArgs, "\n")
		love.event.quit(1)
		return
	end
	local canvasSize = {1280 * parsedArgs.dimensions, 720 * parsedArgs.dimensions}
	local renderTarget = parsedArgs.render
	nvi.setScaling(parsedArgs.dimensions)

	-- Load music
	nvi.loadSongFile(parsedArgs.songfile)
	local songData = nvi.getSongData()
	songDuration = songData.soundData:getSampleCount() / songData.soundData:getSampleRate()

	-- Load visualizer
	local func = assert(love.filesystem.load("nvi/"..parsedArgs.visualizer.."/init.lua"))

	-- Setup file-level context
	nvi.loadVisualizerArgparse(parsedArgs.visualizer)

	-- Load
	visualizerObject = func()
	local visArgparse = nvi.getArgparse()
	nvi.loadVisualizerArgparse(nil)

	-- Parse additional args
	status, parsedArgs = visArgparse:pparse(filteredArg)
	if not status then
		error(parsedArgs)
	end

	-- Initialize window
	nvi.createWindow()

	-- Load metadata
	---@type NVi.Metadata
	local metadata = {}

	for k, v in pairs(songData.metadata) do
		metadata[k] = v
	end

	if songData.cover then
		metadata.coverArt = love.graphics.newImage(songData.cover)
	end

	-- Call visualizer loader
	local visualizerRequirement = visualizerObject.load(parsedArgs, metadata)

	-- Initialize canvas
	mainCanvas = love.graphics.newCanvas(canvasSize[1], canvasSize[2], {
		format = "normal",
		dpiscale = 1,
		mipmaps = renderTarget and "none" or "auto"
	})

	-- Load render mode
	if renderTarget then
		-- TODO: cycle canvas in render mode
		nvi.startRender(renderTarget, 60, canvasSize[1], canvasSize[2])
		inRenderMode = true
	else
		songSource = love.audio.newSource(songData.soundData)
	end

	-- Load visualizer requirement
	-- TODO
end

function love.update(dt)
	local actualSongTime = 0

	-- Play audio
	if songSource then
		if not songSource:isPlaying() then
			if songTime == 1 then
				love.event.quit()
				return
			else
				songSource:play()
			end
		else
			actualSongTime = songSource:tell("seconds")
		end
	else
		actualSongTime = songTime
	end

	-- Update Canvas
	love.graphics.push("all")
	love.graphics.setCanvas(mainCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.scale(nvi.getScaling())
	visualizerObject.draw()
	love.graphics.pop()

	if inRenderMode then
		if not nvi.supplyRender(mainCanvas) then
			nvi.endRender()
			error("supplyRender failed, console may give more info")
		end
	end

	if not songSource then
		if songTime >= songDuration then
			love.event.quit()
			return
		end

		songTime = songTime + dt
	end
end

function love.draw()
	-- TODO: resize according to window
	love.graphics.draw(mainCanvas, 0, 0, 0, 1 / nvi.getScaling())
end

function love.quit()
	nvi.saveWindowData()
end
