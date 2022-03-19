local love = require("love")
local nvi = require("nvi")
local argparse = require("libs.argparse")

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

	local status, parsedArgs = parser:pparse(realArg)
	if exitNow then
		love.event.quit(0)
		return
	elseif not status then
		io.stderr:write("Error: ", parsedArgs, "\n")
		love.event.quit(1)
		return
	end

	-- Load music
	nvi.loadSongFile(parsedArgs.songfile)

	-- Load visualizer
	local func = assert(love.filesystem.load("nvi/"..parsedArgs.visualizer.."/init.lua"))

	-- Setup file-level context
	nvi.loadVisualizerArgparse(parsedArgs.visualizer)

	-- Load
	---@type NVi.BaseVisualizer
	local visualizerObject = func()
	local visArgparse = nvi.getArgparse()
	nvi.loadVisualizerArgparse(nil)

	-- Parse additional args
	status, parsedArgs = visArgparse:pparse(filteredArg)
	if not status then
		error(parsedArgs)
	end
end

function love.quit()
	nvi.saveWindowData()
end
