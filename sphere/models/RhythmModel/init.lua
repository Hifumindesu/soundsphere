local Class				= require("Class")
local Observable		= require("Observable")
local ScoreEngine		= require("sphere.models.RhythmModel.ScoreEngine")
local LogicEngine		= require("sphere.models.RhythmModel.LogicEngine")
local GraphicEngine		= require("sphere.models.RhythmModel.GraphicEngine")
local AudioEngine		= require("sphere.models.RhythmModel.AudioEngine")
local TimeEngine		= require("sphere.models.RhythmModel.TimeEngine")
local InputManager		= require("sphere.models.RhythmModel.InputManager")
local PauseManager		= require("sphere.models.RhythmModel.PauseManager")
-- local Test		= require("sphere.models.RhythmModel.LogicEngine.Test")

local RhythmModel = Class:new()

RhythmModel.construct = function(self)
	self.inputManager = InputManager:new()
	self.pauseManager = PauseManager:new()
	self.timeEngine = TimeEngine:new()
	self.scoreEngine = ScoreEngine:new()
	self.audioEngine = AudioEngine:new()
	self.logicEngine = LogicEngine:new()
	self.graphicEngine = GraphicEngine:new()
	self.observable = Observable:new()
	self.inputManager.rhythmModel = self
	self.pauseManager.rhythmModel = self
	self.timeEngine.rhythmModel = self
	self.scoreEngine.rhythmModel = self
	self.audioEngine.rhythmModel = self
	self.logicEngine.rhythmModel = self
	self.graphicEngine.rhythmModel = self
	self.observable.rhythmModel = self

	self.inputManager.observable:add(self.logicEngine)
	self.inputManager.observable:add(self.observable)
end

RhythmModel.load = function(self)
	local scoreEngine = self.scoreEngine
	local logicEngine = self.logicEngine

	scoreEngine.judgements = self.judgements
	scoreEngine.hp = self.hp
	scoreEngine.settings = self.settings

	logicEngine.timings = self.timings
end

RhythmModel.loadAllEngines = function(self)
	self:loadLogicEngines()
	self.audioEngine:load()
	self.graphicEngine:load()
	self.pauseManager:load()
end

RhythmModel.loadLogicEngines = function(self)
	self.timeEngine:load()
	self.scoreEngine:load()
	self.logicEngine:load()
end

RhythmModel.unloadAllEngines = function(self)
	self.audioEngine:unload()
	self.logicEngine:unload()
	self.graphicEngine:unload()

	for _, inputType, inputIndex in self.noteChart:getInputIterator() do
		self.observable:send({
			name = "keyreleased",
			virtual = true,
			inputType .. inputIndex
		})
	end
end

RhythmModel.unloadLogicEngines = function(self)
	self.scoreEngine:unload()
	self.logicEngine:unload()
end

RhythmModel.receive = function(self, event)
	if event.name == "framestarted" then
		self.timeEngine:sync(event)
		return
	end

	self.inputManager:receive(event)
end

RhythmModel.update = function(self, dt)
	self.logicEngine:update()
	self.audioEngine:update()
	self.scoreEngine:update()
	self.graphicEngine:update(dt)
	self.pauseManager:update(dt)
end

RhythmModel.hasResult = function(self)
	local timeEngine = self.timeEngine
	local base = self.scoreEngine.scoreSystem.base
	local entry = self.scoreEngine.scoreSystem.entry

	return
		not self.logicEngine.autoplay and
		not self.logicEngine.promode and
		not self.timeEngine.windUp and
		timeEngine.currentTime >= timeEngine.minTime and
		base.hitCount > 0 and
		entry.accuracy > 0 and
		entry.accuracy < math.huge
end

RhythmModel.setWindUp = function(self, windUp)
	self.timeEngine.windUp = windUp
end

RhythmModel.setTimeRate = function(self, timeRate)
	self.timeEngine:setBaseTimeRate(timeRate)
end

RhythmModel.setAutoplay = function(self, autoplay)
	self.logicEngine.autoplay = autoplay
end

RhythmModel.setPromode = function(self, promode)
	self.logicEngine.promode = promode
end

RhythmModel.setAdjustRate = function(self, adjustRate)
	self.timeEngine.adjustRate = adjustRate
end

RhythmModel.setNoteChart = function(self, noteChart)
	assert(noteChart)
	self.noteChart = noteChart
	self.timeEngine.noteChart = noteChart
	self.scoreEngine.noteChart = noteChart
	self.logicEngine.noteChart = noteChart
	self.graphicEngine.noteChart = noteChart
end

RhythmModel.setDrawRange = function(self, range)
	self.graphicEngine.range = range
end

RhythmModel.setVolume = function(self, volume)
	self.audioEngine.volume = volume
	self.audioEngine:updateVolume()
end

RhythmModel.setAudioMode = function(self, mode)
	self.audioEngine.mode = mode
end

RhythmModel.setVisualTimeRate = function(self, visualTimeRate)
	self.graphicEngine.visualTimeRate = visualTimeRate
	self.graphicEngine.targetVisualTimeRate = visualTimeRate
end

RhythmModel.setLongNoteShortening = function(self, longNoteShortening)
	self.graphicEngine.longNoteShortening = longNoteShortening
end

RhythmModel.setTimeToPrepare = function(self, timeToPrepare)
	self.timeEngine.timeToPrepare = timeToPrepare
end

RhythmModel.setInputOffset = function(self, offset)
	self.timeEngine.inputOffset = math.floor(offset * 1024) / 1024
end

RhythmModel.setVisualOffset = function(self, offset)
	self.timeEngine.visualOffset = offset
end

RhythmModel.setPauseTimes = function(self, ...)
	self.pauseManager:setPauseTimes(...)
end

RhythmModel.setVisualTimeRateScale = function(self, scaleSpeed)
	self.graphicEngine.scaleSpeed = scaleSpeed
end

return RhythmModel
