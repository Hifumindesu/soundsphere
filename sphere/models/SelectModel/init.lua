local class = require("class")
local delay = require("delay")
local thread = require("thread")
local path_util = require("path_util")
local table_util = require("table_util")
local NoteChartFactory = require("notechart.NoteChartFactory")
local NoteChartLibrary = require("sphere.models.SelectModel.NoteChartLibrary")
local NoteChartSetLibrary = require("sphere.models.SelectModel.NoteChartSetLibrary")
local CollectionLibrary = require("sphere.models.SelectModel.CollectionLibrary")
local ScoreLibrary = require("sphere.models.SelectModel.ScoreLibrary")
local SearchModel = require("sphere.models.SelectModel.SearchModel")
local SortModel = require("sphere.models.SelectModel.SortModel")

---@class sphere.SelectModel
---@operator call: sphere.SelectModel
local SelectModel = class()

SelectModel.chartview_set_index = 1
SelectModel.chartview_index = 1
SelectModel.scoreItemIndex = 1
SelectModel.pullingNoteChartSet = false
SelectModel.debounceTime = 0.5

---@param configModel sphere.ConfigModel
---@param cacheModel sphere.CacheModel
---@param onlineModel sphere.OnlineModel
function SelectModel:new(configModel, cacheModel, onlineModel)
	self.configModel = configModel
	self.cacheModel = cacheModel

	self.noteChartLibrary = NoteChartLibrary(cacheModel)
	self.noteChartSetLibrary = NoteChartSetLibrary(cacheModel)
	self.collectionLibrary = CollectionLibrary(cacheModel, configModel)
	self.searchModel = SearchModel(configModel)
	self.sortModel = SortModel()

	self.scoreLibrary = ScoreLibrary(
		configModel,
		onlineModel,
		cacheModel
	)
end

function SelectModel:load()
	local config = self.configModel.configs.select
	self.config = config

	self.searchMode = config.searchMode

	self.noteChartSetStateCounter = 1
	self.noteChartStateCounter = 1
	self.scoreStateCounter = 1

	self.collectionLibrary:load()

	self.collectionItemIndex = self.collectionLibrary:indexof(config.collection)
	self.collectionItem = self.collectionLibrary.items[self.collectionItemIndex]

	self:noDebouncePullNoteChartSet()
end

function SelectModel:updateSetItems()
	local config = self.configModel.configs.settings.select

	local params = {}

	local order, group_allowed = self.sortModel:getOrder(self.config.sortFunction)

	params.order = table_util.copy(order)
	table.insert(params.order, "chartmeta_id")

	if config.collapse and group_allowed then
		params.group = {"chartfile_set_id"}
	end

	local where, lamp = self.searchModel:getConditions()

	local path = self.collectionItem.path
	if path then
		where.path__startswith = path
	end

	params.where = where
	params.lamp = lamp
	params.difficulty = config.diff_column

	self.cacheModel.cacheDatabase:queryAsync(params)
	self.noteChartSetLibrary:updateItems()
end

---@param hash string
---@param index number
function SelectModel:findNotechart(hash, index)
	local config = self.configModel.configs.settings.select
	local params = {
		where = {hash = hash, index = index},
		difficulty = config.diff_column,
	}
	self.cacheModel.cacheDatabase:queryAsync(params)
	self.noteChartSetLibrary:updateItems()
end

---@return string?
function SelectModel:getBackgroundPath()
	local chartview = self.chartview
	if not chartview then
		return
	end

	local background_path = chartview.background_path
	if not background_path or background_path == "" then
		return
	end

	local name = chartview.name
	if name:find("%.ojn$") or name:find("%.mid$") then
		return chartview.path
	end

	return path_util.join(chartview.location_dir, background_path)
end

---@return string?
---@return number?
---@return string?
function SelectModel:getAudioPathPreview()
	local chartview = self.chartview
	if not chartview then
		return
	end

	local mode = "absolute"

	local audio_path = chartview.audio_path
	if not audio_path or audio_path == "" then
		return path_util.join(chartview.location_dir, "preview.ogg"), 0, mode
	end

	local full_path = path_util.join(chartview.location_dir, audio_path)
	local preview_time = chartview.preview_time

	if preview_time < 0 and chartview.format == "osu" then
		mode = "relative"
		preview_time = 0.4
	end

	return full_path, preview_time, mode
end

---@param settings table?
---@return ncdk.NoteChart?
function SelectModel:loadNoteChart(settings)
	local chartview = self.chartview

	local content = love.filesystem.read(chartview.location_path)
	if not content then
		return
	end

	return assert(NoteChartFactory:getNoteChart(
		chartview.chartfile_name,
		content,
		chartview.index,
		settings
	))
end

---@return boolean
function SelectModel:isChanged()
	local changed = self.changed
	self.changed = false
	return changed == true
end

function SelectModel:setChanged()
	self.changed = true
end

---@return boolean
function SelectModel:notechartExists()
	local chartview = self.chartview
	if chartview then
		return love.filesystem.getInfo(chartview.location_path) ~= nil
	end
	return false
end

---@return boolean
function SelectModel:isPlayed()
	return not not (self:notechartExists() and self.scoreItem)
end

---@param ... any?
function SelectModel:debouncePullNoteChartSet(...)
	delay.debounce(self, "pullNoteChartSetDebounce", self.debounceTime, self.pullNoteChartSet, self, ...)
end

SelectModel.noDebouncePullNoteChartSet = thread.coro(function(self, ...)
	self:pullNoteChartSet(...)
end)

---@param sortFunctionName string
function SelectModel:setSortFunction(sortFunctionName)
	if self.pullingNoteChartSet then
		return
	end
	self.config.sortFunction = sortFunctionName
	self:noDebouncePullNoteChartSet()
end

---@param locked boolean
function SelectModel:setLock(locked)
	self.locked = locked
end

---@param direction number?
---@param destination number?
function SelectModel:scrollCollection(direction, destination)
	if self.pullingNoteChartSet then
		return
	end

	local collectionItems = self.collectionLibrary.items

	destination = math.min(math.max(destination or self.collectionItemIndex + direction, 1), #collectionItems)
	if not collectionItems[destination] or self.collectionItemIndex == destination then
		return
	end
	self.collectionItemIndex = destination

	local oldCollectionItem = self.collectionItem

	local collectionItem = collectionItems[self.collectionItemIndex]
	self.collectionItem = collectionItem
	self.config.collection = collectionItem.path

	self:debouncePullNoteChartSet(oldCollectionItem and oldCollectionItem.path == collectionItem.path)
end

function SelectModel:scrollRandom()
	local items = self.noteChartSetLibrary.items
	local destination = math.random(1, #items)
	self:scrollNoteChartSet(nil, destination)
end

---@param item table
function SelectModel:setConfig(item)
	self.config.chartfile_set_id = item.chartfile_set_id
	self.config.chartfile_id = item.chartfile_id
	self.config.chartmeta_id = item.chartmeta_id
end

---@param direction number?
---@param destination number?
function SelectModel:scrollNoteChartSet(direction, destination)
	local items = self.noteChartSetLibrary.items

	destination = math.min(math.max(destination or self.chartview_set_index + direction, 1), #items)
	if not items[destination] or self.chartview_set_index == destination then
		return
	end

	local old_chartview_set = items[self.chartview_set_index]
	self.chartview_set_index = destination

	local chartview_set = items[destination]
	self:setConfig(chartview_set)

	self:pullNoteChart(old_chartview_set and old_chartview_set.chartfile_set_id == chartview_set.chartfile_set_id)
end

---@param direction number?
---@param destination number?
function SelectModel:scrollNoteChart(direction, destination)
	local items = self.noteChartLibrary.items

	direction = direction or destination - self.chartview_index

	destination = math.min(math.max(destination or self.chartview_index + direction, 1), #items)
	if not items[destination] or self.chartview_index == destination then
		return
	end
	self.chartview_index = destination

	local chartview = items[self.chartview_index]
	self.chartview = chartview
	self.changed = true

	self:setConfig(chartview)

	self:pullNoteChartSet(true, true)
	self:pullScore()
end

---@param direction number?
---@param destination number?
function SelectModel:scrollScore(direction, destination)
	local items = self.scoreLibrary.items

	destination = math.min(math.max(destination or self.scoreItemIndex + direction, 1), #items)
	if not items[destination] or self.scoreItemIndex == destination then
		return
	end
	self.scoreItemIndex = destination

	local scoreItem = items[self.scoreItemIndex]
	self.scoreItem = scoreItem

	self.config.score_id = scoreItem.id
end

---@param noUpdate boolean?
---@param noPullNext boolean?
function SelectModel:pullNoteChartSet(noUpdate, noPullNext)
	if self.locked then
		return
	end

	self.pullingNoteChartSet = true

	if not noUpdate then
		self:updateSetItems()
	end

	local items = self.noteChartSetLibrary.items
	self.chartview_set_index = self.noteChartSetLibrary:indexof(self.config)

	if not noUpdate then
		self.noteChartSetStateCounter = self.noteChartSetStateCounter + 1
	end

	local chartview_set = items[self.chartview_set_index]
	if chartview_set then
		self.config.chartfile_set_id = chartview_set.chartfile_set_id
		self.pullingNoteChartSet = false
		if not noPullNext then
			self:pullNoteChart(noUpdate)
		end
		return
	end

	self.config.chartfile_set_id = 0
	self.config.chartfile_id = 0
	self.config.chartmeta_id = 0

	self.chartview = nil
	self.scoreItem = nil
	self.changed = true

	self.noteChartLibrary:clear()
	self.scoreLibrary:clear()

	self.pullingNoteChartSet = false
end

---@param noUpdate boolean?
---@param noPullNext boolean?
function SelectModel:pullNoteChart(noUpdate, noPullNext)
	local oldId = self.chartview and self.chartview.id

	self.noteChartLibrary:setNoteChartSetId(self.config.chartfile_set_id)

	local items = self.noteChartLibrary.items
	self.chartview_index = self.noteChartLibrary:getItemIndex(
		self.config.chartfile_id,
		self.config.chartmeta_id
	)

	if not noUpdate then
		self.noteChartStateCounter = self.noteChartStateCounter + 1
	end
	local chartview = items[self.chartview_index]
	self.chartview = chartview
	self.changed = true

	if chartview then
		self.config.chartfile_id = chartview.chartfile_id
		self.config.chartmeta_id = chartview.chartmeta_id
		if not noPullNext then
			self:pullScore(oldId and oldId == chartview.id)
		end
		return
	end

	self.config.chartfile_id = 0
	self.config.chartmeta_id = 0

	self.scoreItem = nil

	self.scoreLibrary:clear()
end

function SelectModel:updateScoreOnlineAsync()
	self.scoreLibrary:updateItemsAsync(self.chartview)
	self:findScore()
end

SelectModel.updateScoreOnline = thread.coro(SelectModel.updateScoreOnlineAsync)

function SelectModel:findScore()
	local scoreItems = self.scoreLibrary.items
	self.scoreItemIndex = self.scoreLibrary:getItemIndex(self.config.score_id) or 1

	local scoreItem = scoreItems[self.scoreItemIndex]
	self.scoreItem = scoreItem
	if scoreItem then
		self.config.score_id = scoreItem.id
	end
end

---@param noUpdate boolean?
function SelectModel:pullScore(noUpdate)
	local items = self.noteChartLibrary.items
	local chartview = items[self.chartview_index]

	if not chartview then
		return
	end

	if not noUpdate then
		self.scoreStateCounter = self.scoreStateCounter + 1
		self.scoreLibrary:setHash(chartview.hash)
		self.scoreLibrary:setIndex(chartview.index)

		local select = self.configModel.configs.select
		if select.scoreSourceName == "online" then
			self.scoreLibrary:clear()
			delay.debounce(self, "scoreDebounce", self.debounceTime,
				self.updateScoreOnlineAsync, self
			)
			return
		end
		self.scoreLibrary:updateItems(self.chartview)
	end

	self:findScore()
end

return SelectModel
