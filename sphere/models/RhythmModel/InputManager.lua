local Class			= require("aqua.util.Class")
local Observable	= require("aqua.util.Observable")
local json			= require("json")

local InputManager = Class:new()

InputManager.path = "userdata/input.json"

InputManager.mode = "external"
InputManager.needRound = true

InputManager.types = {
	"keyboard",
	"gamepad",
	"joystick",
	"midi"
}

InputManager.construct = function(self)
	self.observable = Observable:new()
end

InputManager.setMode = function(self, mode)
	self.mode = mode
end

InputManager.setBindings = function(self, inputBindings)
	self.inputBindings = inputBindings
end

InputManager.send = function(self, event)
	return self.observable:send(event)
end

InputManager.setInputMode = function(self, inputMode)
	self.inputMode = inputMode
	self.inputConfig = self.inputBindings[inputMode]
end

InputManager.receive = function(self, event)
	local mode = self.mode

	if event.virtual and mode == "internal" then
		return self:send(event)
	end

	if mode ~= "external" then
		return
	end

	if not self.inputConfig then
		return
	end

	local keyConfig
	if event.name == "keypressed" and self.inputConfig.press.keyboard then
		keyConfig = self.inputConfig.press.keyboard[event[2]]
	elseif event.name == "keyreleased" and self.inputConfig.release.keyboard then
		keyConfig = self.inputConfig.release.keyboard[event[2]]
	elseif event.name == "gamepadpressed" then
		keyConfig = self.inputConfig.press.gamepad[tostring(event[2])]
	elseif event.name == "gamepadreleased" then
		keyConfig = self.inputConfig.release.gamepad[tostring(event[2])]
	elseif event.name == "joystickpressed" and self.inputConfig.press.joystick then
		keyConfig = self.inputConfig.press.joystick[tostring(event[2])]
	elseif event.name == "joystickreleased" and self.inputConfig.release.joystick then
		keyConfig = self.inputConfig.release.joystick[tostring(event[2])]
	elseif event.name == "midipressed" then
		keyConfig = self.inputConfig.press.midi[tostring(event[1])]
	elseif event.name == "midireleased" then
		keyConfig = self.inputConfig.release.midi[tostring(event[1])]
	end
	if not keyConfig then
		return
	end

	local timeEngine = self.rhythmModel.timeEngine
	local eventTime = timeEngine.timer:transformTime(event.time)
	eventTime = math.floor(eventTime * 1024) / 1024

	local virtualEvent = {
		virtual = true,
		time = eventTime,
	}

	virtualEvent.name = "keypressed"
	for _, key in ipairs(keyConfig.press) do
		virtualEvent[1] = key
		self:send(virtualEvent)
	end
	virtualEvent.name = "keyreleased"
	for _, key in ipairs(keyConfig.release) do
		virtualEvent[1] = key
		self:send(virtualEvent)
	end
end

return InputManager
