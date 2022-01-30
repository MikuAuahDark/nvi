local love = require("love")
local nvi = require("nvi")

function love.conf(t)
    t.version = "11.4"

    t.identity = "lovelyzer"
    t.appendidentity = true
	love.filesystem.setIdentity(t.identity)

    t.externalstorage = true
    t.gammacorrect = false
    t.window = nil

    t.modules.audio = false
    t.modules.joystick = false
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.thread = false
    t.modules.touch = false
end
