local imgui = require("cimgui")

local modes = love.window.getFullscreenModes()
table.sort(modes, function(a, b)
	if a.width ~= b.width then
		return a.width > b.width
	end
	return a.height > b.height
end)

local settings = {
	{
		name = "play speed",
		section = "gameplay",
		key = "gameplay.speed",
		type = "InputFloat",
		step = 0.05,
		format = "%0.2f",
	},
	{
		name = "pause on fail",
		section = "gameplay",
		key = "gameplay.pauseOnFail",
		type = "Checkbox",
	},
	{
		name = "scale scroll speed with rate",
		section = "gameplay",
		key = "gameplay.scaleSpeed",
		type = "Checkbox",
	},
	{
		name = "visual LN shortening",
		section = "gameplay",
		key = "gameplay.longNoteShortening",
		type = "SliderInt",
		range = {-0.3, 0},
		multiplier = 1000,
	},
	{
		name = "input offset",
		section = "gameplay",
		key = "gameplay.offset.input",
		type = "InputInt",
		step = 0.001,
		step_fast = 0.01,
		multiplier = 1000,
	},
	{
		name = "visual offset",
		section = "gameplay",
		key = "gameplay.offset.visual",
		type = "InputInt",
		step = 0.001,
		step_fast = 0.01,
		multiplier = 1000,
	},
	{
		name = "last mean values",
		section = "gameplay",
		key = "gameplay.lastMeanValues",
		type = "SliderInt",
		range = {10, 100},
	},
	{
		name = "rating hit timing window",
		section = "gameplay",
		key = "gameplay.ratingHitTimingWindow",
		type = "InputInt",
		step = 0.001,
		step_fast = 0.01,
		multiplier = 1000,
	},
	{
		name = "video BGA",
		section = "gameplay",
		key = "gameplay.bga.video",
		type = "Checkbox",
	},
	{
		name = "image BGA",
		section = "gameplay",
		key = "gameplay.bga.image",
		type = "Checkbox",
	},
	{
		name = "time to prepare",
		section = "gameplay",
		key = "gameplay.time.prepare",
		type = "SliderFloat",
		range = {0.5, 3},
		format = "%0.1f",
	},
	{
		name = "time to play-pause",
		section = "gameplay",
		key = "gameplay.time.playPause",
		type = "SliderFloat",
		range = {0, 2},
		format = "%0.1f",
	},
	{
		name = "time to pause-play",
		section = "gameplay",
		key = "gameplay.time.pausePlay",
		type = "SliderFloat",
		range = {0, 2},
		format = "%0.1f",
	},
	{
		name = "time to play-retry",
		section = "gameplay",
		key = "gameplay.time.playRetry",
		type = "SliderFloat",
		range = {0, 2},
		format = "%0.1f",
	},
	{
		name = "time to pause-retry",
		section = "gameplay",
		key = "gameplay.time.pauseRetry",
		type = "SliderFloat",
		range = {0, 2},
		format = "%0.1f",
	},
	{
		name = "pause",
		type = "Hotkey",
		section = "gameplay",
		key = "input.pause",
	},
	{
		name = "skip intro",
		type = "Hotkey",
		section = "gameplay",
		key = "input.skipIntro",
	},
	{
		name = "quick restart",
		type = "Hotkey",
		section = "gameplay",
		key = "input.quickRestart",
	},
	{
		name = "decrease offset",
		type = "Hotkey",
		section = "gameplay",
		key = "input.offset.decrease",
	},
	{
		name = "increase offset",
		type = "Hotkey",
		section = "gameplay",
		key = "input.offset.increase",
	},
	{
		name = "decrease play speed",
		type = "Hotkey",
		section = "gameplay",
		key = "input.playSpeed.decrease",
	},
	{
		name = "increase play speed",
		type = "Hotkey",
		section = "gameplay",
		key = "input.playSpeed.increase",
	},
	{
		name = "invert play speed",
		type = "Hotkey",
		section = "gameplay",
		key = "input.playSpeed.invert",
	},
	{
		name = "decrease time rate",
		type = "Hotkey",
		section = "gameplay",
		key = "input.timeRate.decrease",
	},
	{
		name = "increase time rate",
		type = "Hotkey",
		section = "gameplay",
		key = "input.timeRate.increase",
	},
	{
		name = "invert time rate",
		type = "Hotkey",
		section = "gameplay",
		key = "input.timeRate.invert",
	},
	{
		name = "FPS limit",
		section = "graphics",
		key = "graphics.fps",
		type = "SliderFloat",
		range = {10, 1000},
		format = "%0.0f",
	},
	{
		name = "fullscreen",
		section = "graphics",
		key = "graphics.mode.flags.fullscreen",
		type = "Checkbox",
	},
	{
		name = "fullscreen type",
		section = "graphics",
		key = "graphics.mode.flags.fullscreentype",
		type = "Combo",
		values = {"desktop", "exclusive"},
	},
	{
		name = "vsync",
		section = "graphics",
		key = "graphics.mode.flags.vsync",
		type = "Combo",
		values = {1, 0, -1},
		displayValues = {"enabled", "disabled", "adaptive"},
	},
	{
		name = "vsync on select",
		section = "graphics",
		key = "graphics.vsyncOnSelect",
		type = "Checkbox",
	},
	{
		name = "DWM flush",
		section = "graphics",
		key = "graphics.dwmflush",
		type = "Checkbox",
	},
	{
		name = "threaded input",
		section = "graphics",
		key = "graphics.asynckey",
		type = "Checkbox",
	},
	{
		name = "start window resolution",
		section = "graphics",
		key = "graphics.mode.window",
		type = "Combo",
		values = modes,
		displayValues = (function()
			local displayValues = {}
			for i, mode in ipairs(modes) do
				displayValues[i] = ("%dx%d"):format(mode.width, mode.height)
			end
			return displayValues
		end)(),
	},
	{
		name = "cursor",
		section = "graphics",
		key = "graphics.cursor",
		type = "Combo",
		values = {"circle", "arrow", "system"},
	},
	{
		name = "dim select",
		section = "graphics",
		key = "graphics.dim.select",
		type = "SliderInt",
		range = {0, 1},
		multiplier = 100,
	},
	{
		name = "dim gameplay",
		section = "graphics",
		key = "graphics.dim.gameplay",
		type = "SliderInt",
		range = {0, 1},
		multiplier = 100,
	},
	{
		name = "dim result",
		section = "graphics",
		key = "graphics.dim.result",
		type = "SliderInt",
		range = {0, 1},
		multiplier = 100,
	},
	{
		name = "blur select",
		section = "graphics",
		key = "graphics.blur.select",
		type = "SliderInt",
		range = {0, 50},
	},
	{
		name = "blur gameplay",
		section = "graphics",
		key = "graphics.blur.gameplay",
		type = "SliderInt",
		range = {0, 50},
	},
	{
		name = "blur result",
		section = "graphics",
		key = "graphics.blur.result",
		type = "SliderInt",
		range = {0, 50},
	},
	{
		name = "enable camera",
		section = "graphics",
		key = "graphics.perspective.camera",
		type = "Checkbox",
	},
	{
		name = "allow rotate x",
		section = "graphics",
		key = "graphics.perspective.rx",
		type = "Checkbox",
	},
	{
		name = "allow rotate y",
		section = "graphics",
		key = "graphics.perspective.ry",
		type = "Checkbox",
	},
	{
		name = "master volume",
		section = "audio",
		key = "audio.volume.master",
		type = "SliderInt",
		range = {0, 1},
		multiplier = 100,
	},
	{
		name = "music volume",
		section = "audio",
		key = "audio.volume.music",
		type = "SliderInt",
		range = {0, 1},
		multiplier = 100,
	},
	{
		name = "effects volume",
		section = "audio",
		key = "audio.volume.effects",
		type = "SliderInt",
		range = {0, 1},
		multiplier = 100,
	},
	{
		name = "primary audio mode",
		section = "audio",
		key = "audio.mode.primary",
		type = "Combo",
		values = {
			"sample",
			"streamMemoryTempo",
			-- "streamOpenAL", "sampleOpenAL"
		},
		displayValues = {
			"sample",
			"memory",
			-- "streamOAL", "sampleOAL"
		},
	},
	{
		name = "secondary audio mode",
		section = "audio",
		key = "audio.mode.secondary",
		type = "Combo",
		values = {
			"sample",
			"streamMemoryTempo",
			-- "streamOpenAL", "sampleOpenAL"
		},
		displayValues = {
			"sample",
			"memory",
			-- "streamOAL", "sampleOAL"
		},
	},
	{
		name = "midi constant volume",
		section = "audio",
		key = "audio.midi.constantVolume",
		type = "Checkbox",
	},
	{
		name = "select random chart",
		type = "Hotkey",
		section = "input",
		key = "input.selectRandom",
	},
	{
		name = "capture screenshot",
		type = "Hotkey",
		section = "input",
		key = "input.screenshot.capture",
	},
	{
		name = "open screenshot",
		type = "Hotkey",
		section = "input",
		key = "input.screenshot.open",
	},
	{
		name = "auto update on game start",
		section = "miscellaneous",
		key = "miscellaneous.autoUpdate",
		type = "Checkbox",
	},
	{
		name = "imgui.ShowDemoWindow",
		section = "miscellaneous",
		key = "miscellaneous.imguiShowDemoWindow",
		type = "Checkbox",
	},
}

return settings
