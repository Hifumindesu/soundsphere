local inspect = require("inspect")
local utf8validate = require("utf8validate")
local just = require("just")
local imgui = require("sphere.imgui")
local ContainerImView = require("sphere.imviews.ContainerImView")
local errhand = love.errhand

local message = ""
local trace = ""

local scrollY = 0
local function draw()
	local w, h = love.graphics.getDimensions()

	love.graphics.origin()
	love.graphics.clear(0.1, 0.1, 0.1, 1)
	love.graphics.setColor(1, 1, 1, 1)

	local _h = 40
	imgui.setSize(w, h, w / 2, _h)
	local h0 = just.height

	just.row(true)
	if imgui.button("close", "close") then
		love.event.quit()
	end
	if imgui.button("copy", "copy") then
		love.system.setClipboardText(message .. "\n" .. trace)
	end
	if imgui.button("restart", "restart") then
		love.event.quit("restart")
	end
	if imgui.button("restart+check", "restart and check integrity") then
		love.filesystem.remove("userdata/files.lua")
		love.event.quit("restart")
	end
	just.offset(w - 70)
	if imgui.button("error", "error") then
		error(message .. "\n" .. trace)
	end
	just.row()

	ContainerImView("error container", w, h - (just.height - h0), _h, scrollY)
	just.indent(10)
	just.text(message .. "\n" .. trace, w - _h)
	scrollY = ContainerImView()
end

local handlers = {}

function handlers.keypressed(key, scancode)
	if key == "escape" then
		love.event.quit()
	elseif key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
		love.system.setClipboardText(message .. "\n" .. trace)
	end
end

local function run()
	love.event.pump()

	for name, a,b,c,d,e,f in love.event.poll() do
		if name == "quit" then
			return a or 1
		end
		local icb = just.callbacks[name]
		local skip = icb and icb(a,b,c,d,e,f)
		if not skip and handlers[name] then
			handlers[name](a,b,c,d,e,f)
		end
	end

	if love.graphics.isActive() then
		draw()
		just._end()
		love.graphics.present()
	end

	if love.timer then
		love.timer.sleep(0.001)
	end
end

return function(msg)
	if type(msg) ~= "string" then
		msg = inspect(msg)
	end
	message = utf8validate(msg)
	trace = debug.traceback()

	print(message .. "\n" .. trace)
	love.filesystem.write("userdata/lasterror.txt", message .. "\n" .. trace)

	love.graphics.reset()
	love.window.setVSync(1)
	just.reset()

	return function()
		local status, err = pcall(run)
		if not status then
			run = errhand(err)
		else
			return err
		end
	end
end
