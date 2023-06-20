local Class = require("Class")
local NoteChartExporter = require("sph.NoteChartExporter")
local OsuNoteChartExporter = require("osu.NoteChartExporter")
local NoteChartResourceLoader = require("sphere.database.NoteChartResourceLoader")
local FileFinder = require("sphere.filesystem.FileFinder")

local EditorController = Class:new()

EditorController.load = function(self)
	local noteChartModel = self.game.noteChartModel
	local editorModel = self.game.editorModel

	noteChartModel:load()
	noteChartModel:loadNoteChart()

	local noteSkin = self.game.noteSkinModel:getNoteSkin(noteChartModel.noteChart.inputMode)
	noteSkin:loadData()
	noteSkin.editor = true

	editorModel:load()
	self.game.previewModel:stop()

	FileFinder:reset()
	FileFinder:addPath(noteChartModel.noteChartEntry.path:match("^(.+)/.-$"))
	FileFinder:addPath(noteSkin.directoryPath)
	FileFinder:addPath("userdata/hitsounds")
	FileFinder:addPath("userdata/hitsounds/midi")

	NoteChartResourceLoader.game = self.game
	NoteChartResourceLoader:load(noteChartModel.noteChartEntry.path, noteChartModel.noteChart, function()
		editorModel:loadResources()
	end)

	local graphics = self.game.configModel.configs.settings.graphics
	local flags = graphics.mode.flags
	if graphics.vsyncOnSelect then
		self.game.baseVsync = flags.vsync ~= 0 and flags.vsync or 1
		flags.vsync = 0
	end
end

EditorController.unload = function(self)
	self.game.editorModel:unload()

	local graphics = self.game.configModel.configs.settings.graphics
	local flags = graphics.mode.flags
	if graphics.vsyncOnSelect and flags.vsync == 0 then
		flags.vsync = self.game.baseVsync
	end
end

EditorController.save = function(self)
	local noteChartModel = self.game.noteChartModel

	self.game.editorModel:save()

	local exp = NoteChartExporter:new()
	exp.noteChart = noteChartModel.noteChart

	local path = noteChartModel.noteChartEntry.path:gsub(".sph$", "") .. ".sph"

	love.filesystem.write(path, exp:export())
end

EditorController.saveToOsu = function(self)
	local noteChartModel = self.game.noteChartModel

	self.game.editorModel:save()

	local exp = OsuNoteChartExporter:new()
	exp.noteChart = noteChartModel.noteChart
	exp.noteChartEntry = self.game.noteChartModel.noteChartEntry
	exp.noteChartDataEntry = self.game.noteChartModel.noteChartDataEntry

	local path = noteChartModel.noteChartEntry.path
	path = path:gsub(".osu$", ""):gsub(".sph$", "") .. ".sph.osu"

	love.filesystem.write(path, exp:export())
end

EditorController.receive = function(self, event)
	self.game.editorModel:receive(event)
	if event.name == "filedropped" then
		return self:filedropped(event[1])
	end
end

local exts = {
	mp3 = true,
	ogg = true,
}
EditorController.filedropped = function(self, file)
	local path = file:getFilename():gsub("\\", "/")

	local _name, ext = path:match("^(.+)%.(.-)$")
	if not exts[ext] then
		return
	end

	local audioName = _name:match("^.+/(.-)$")
	local chartSetPath = "userdata/charts/editor/" .. os.time() .. " " .. audioName

	love.filesystem.write(chartSetPath .. "/" .. audioName .. "." .. ext, file:read())
end

return EditorController
