local Screen = require("sphere.screen.Screen")
local FileManager = require("sphere.filesystem.FileManager")

local MapList = require("sphere.game.MapList")
local NoteChartFactory = require("sphere.game.NoteChartFactory")
local NoteSkinManager = require("sphere.game.NoteSkinManager")
local InputManager = require("sphere.game.InputManager")
local CloudburstEngine = require("sphere.game.CloudburstEngine")
local NoteSkin = require("sphere.game.CloudburstEngine.NoteSkin")
local PlayField = require("sphere.game.PlayField")
local Score = require("sphere.game.Score")

local ScreenManager = require("sphere.screen.ScreenManager")

local GameplayScreen = Screen:new()

Screen.construct(GameplayScreen)

GameplayScreen.load = function(self)
	InputManager:load()
	
	local currentCacheData = MapList.currentCacheData
	
	local noteChart = NoteChartFactory:getNoteChart(currentCacheData.path)
	local noteSkinData = NoteSkinManager:getNoteSkin(noteChart.inputMode)
	
	noteChart.directoryPath = currentCacheData.path:match("^(.+)/")
	FileManager:addPath(noteChart.directoryPath)
	
	local noteSkin = NoteSkin:new({
		directoryPath = noteSkinData.directoryPath,
		noteSkinData = noteSkinData.noteSkin
	})
	
	self.engine = CloudburstEngine:new()
	self.engine.noteChart = noteChart
	self.engine.noteSkin = noteSkin
	self.engine.container = self.container
	self.engine:load()
	
	self.score = Score:new()
	self.score:load()
	
	self.playField = PlayField:new()
	self.playField.directoryPath = noteSkinData.directoryPath
	self.playField.noteSkinData = noteSkinData.noteSkin
	self.playField.playFieldData = noteSkinData.playField
	self.playField.noteSkin = noteSkin
	self.playField.container = self.container
	self.playField:load()
	
	self.engine.observable:add(self.playField)
	self.engine.observable:add(self.score)
end

GameplayScreen.unload = function(self)
	FileManager:removePath(self.engine.noteChart.directoryPath)
	self.engine:unload()
	self.score:unload()
	
	self.playField:unload()
end

GameplayScreen.update = function(self)
	Screen.update(self)
	
	self.engine:update()
	self.playField:update()
end

GameplayScreen.draw = function(self)
	Screen.draw(self)
end

GameplayScreen.receive = function(self, event)
	InputManager:receive(event, self.engine)
	self.engine:receive(event)
	self.playField:receive(event)
	
	if event.name == "keypressed" and event.args[1] == "escape" then
		ScreenManager:set(require("sphere.screen.ResultScreen"))
		ScreenManager:receive({
			name = "score",
			score = self.score
		})
	end
end

return GameplayScreen
