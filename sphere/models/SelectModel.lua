local Class = require("aqua.util.Class")

local SelectModel = Class:new()

SelectModel.load = function(self)
	local config = self.configModel.configs.select
	self.config = config

	self.searchModel:setSearchString(config.searchString)
	self:setSearchMode(config.searchMode)
	self.sortModel.name = config.sortFunction
	self.noteChartSetLibraryModel.sortFunction = self.sortModel:getSortFunction()
	self.noteChartSetLibraryModel.collapse = config.collapse

	self.collectionItemIndex = 1
	self.noteChartSetItemIndex = 1
	self.noteChartItemIndex = 1
	self.scoreItemIndex = 1

	self.noteChartSetStateCounter = 1
	self.noteChartStateCounter = 1

	self:pullNoteChartSet()
end

SelectModel.setSearchMode = function(self, searchMode)
	if searchMode ~= "show" and searchMode ~= "hide" then
		return
	end
	self.noteChartSetLibraryModel.searchMode = searchMode
	self.noteChartLibraryModel.searchMode = searchMode
	self.searchModel.searchMode = searchMode
end

SelectModel.setSortFunction = function(self, sortFunctionName)
	local config = self.config
	config.sortFunction = sortFunctionName
	self.sortModel.name = sortFunctionName
	self.noteChartSetLibraryModel.sortFunction = self.sortModel:getSortFunction()
	self:pullNoteChartSet()
end

SelectModel.scrollSortFunction = function(self, delta)
	self.sortModel:increase(delta)
	self:setSortFunction(self.sortModel.name)
end

SelectModel.changeSearchMode = function(self)
	local config = self.config
	if config.searchMode == "hide" then
		config.searchMode = "show"
	else
		config.searchMode = "hide"
	end
	self:setSearchMode(config.searchMode)
	self:pullNoteChartSet()
end

SelectModel.changeCollapse = function(self)
	local config = self.config
	config.collapse = not config.collapse
	self.noteChartSetLibraryModel.collapse = config.collapse
	self:pullNoteChartSet()
end

SelectModel.update = function(self)
	self:updateSearch()
end

SelectModel.updateSearch = function(self)
	local newSearchString = self.searchModel.searchString
	if self.config.searchString ~= newSearchString then
		self.config.searchString = newSearchString
		self:pullNoteChartSet()
	end
end

SelectModel.scrollCollection = function(self, direction, destination)
	local collectionItems = self.collectionModel.items

	destination = math.min(math.max(destination or self.collectionItemIndex + direction, 1), #collectionItems)
	if not collectionItems[destination] or self.collectionItemIndex == destination then
		return
	end
	self.collectionItemIndex = destination

	local oldCollectionItem = self.collectionItem

	local collectionItem = collectionItems[self.collectionItemIndex]
	self.collectionItem = collectionItem
	self.config.collection = collectionItem.path

	self:pullNoteChartSet(oldCollectionItem.path == collectionItem.path)
end

SelectModel.scrollRandom = function(self)
	local noteChartSetItems = self.noteChartSetLibraryModel.items

	local destination = math.random(1, #noteChartSetItems)

	self:scrollNoteChartSet(nil, destination)
end

SelectModel.scrollNoteChartSet = function(self, direction, destination)
	local noteChartSetItems = self.noteChartSetLibraryModel.items

	destination = math.min(math.max(destination or self.noteChartSetItemIndex + direction, 1), #noteChartSetItems)
	if not noteChartSetItems[destination] or self.noteChartSetItemIndex == destination then
		return
	end
	self.noteChartSetItemIndex = destination

	local oldNoteChartSetItem = self.noteChartSetItem

	local noteChartSetItem = noteChartSetItems[self.noteChartSetItemIndex]
	self.noteChartSetItem = noteChartSetItem
	self.config.noteChartSetEntryId = noteChartSetItem.setId
	self.config.noteChartEntryId = noteChartSetItem.noteChartId
	self.config.noteChartDataEntryId = noteChartSetItem.noteChartDataId

	self:pullNoteChart(oldNoteChartSetItem and oldNoteChartSetItem.setId == noteChartSetItem.setId)
end

SelectModel.scrollNoteChart = function(self, direction, destination)
	local noteChartItems = self.noteChartLibraryModel.items

	direction = direction or destination - self.noteChartItemIndex

	destination = math.min(math.max(destination or self.noteChartItemIndex + direction, 1), #noteChartItems)
	if not noteChartItems[destination] or self.noteChartItemIndex == destination then
		return
	end
	self.noteChartItemIndex = destination

	local noteChartItem = noteChartItems[self.noteChartItemIndex]
	self.noteChartItem = noteChartItem

	self.config.noteChartSetEntryId = noteChartItem.setId
	self.config.noteChartEntryId = noteChartItem.noteChartId
	self.config.noteChartDataEntryId = noteChartItem.noteChartDataId

	self:pullNoteChartSet(true)
	self:pullScore()
end

SelectModel.scrollScore = function(self, direction, destination)
	local scoreItems = self.scoreLibraryModel.items

	destination = math.min(math.max(destination or self.scoreItemIndex + direction, 1), #scoreItems)
	if not scoreItems[destination] or self.scoreItemIndex == destination then
		return
	end
	self.scoreItemIndex = destination

	local scoreItem = scoreItems[self.scoreItemIndex]
	self.scoreItem = scoreItem

	self.config.scoreEntryId = scoreItem.scoreEntry.id
end

SelectModel.pullNoteChartSet = function(self, noUpdate)
	if not noUpdate then
		self.searchModel:setCollection(self.collectionItem)
		self.noteChartLibraryModel:updateItems()
		self.noteChartSetLibraryModel:updateItems()
	end

	local noteChartSetItems = self.noteChartSetLibraryModel.items
	self.noteChartSetItemIndex = self.noteChartSetLibraryModel:getItemIndex(
		self.config.noteChartDataEntryId,
		self.config.noteChartEntryId,
		self.config.noteChartSetEntryId
	)

	if not noUpdate then
		self.noteChartSetStateCounter = self.noteChartSetStateCounter + 1
	end

	local noteChartSetItem = noteChartSetItems[self.noteChartSetItemIndex]
	self.noteChartSetItem = noteChartSetItem
	if noteChartSetItem then
		self.config.noteChartSetEntryId = noteChartSetItem.setId
		self:pullNoteChart(noUpdate)
	end
end

SelectModel.pullNoteChart = function(self, noUpdate)
	if not noUpdate then
		self.noteChartLibraryModel:setNoteChartSetId(self.config.noteChartSetEntryId)
		self.noteChartLibraryModel:updateItems()
	end

	local noteChartItems = self.noteChartLibraryModel.items
	self.noteChartItemIndex = self.noteChartLibraryModel:getItemIndex(
		self.config.noteChartDataEntryId,
		self.config.noteChartEntryId,
		self.config.noteChartSetEntryId
	)

	if not noUpdate then
		self.noteChartStateCounter = self.noteChartStateCounter + 1
	end

	local noteChartItem = noteChartItems[self.noteChartItemIndex]
	self.noteChartItem = noteChartItem
	if not noteChartItem then
		return
	end

	self.config.noteChartEntryId = noteChartItem.noteChartId
	self.config.noteChartDataEntryId = noteChartItem.noteChartDataId
	self:pullScore(noUpdate)
end

SelectModel.pullScore = function(self, noUpdate)
	local noteChartItems = self.noteChartLibraryModel.items
	local noteChartItem = noteChartItems[self.noteChartItemIndex]

	if not noUpdate then
		self.scoreLibraryModel:setHash(noteChartItem.hash)
		self.scoreLibraryModel:setIndex(noteChartItem.index)
		self.scoreLibraryModel:updateItems()
	end

	local scoreItems = self.scoreLibraryModel.items

	self.config.noteChartEntryId = noteChartItem.noteChartId
	self.config.noteChartDataEntryId = noteChartItem.noteChartDataId

	self.scoreItemIndex = self.scoreLibraryModel:getItemIndex(self.config.scoreEntryId) or self.scoreItemIndex

	local scoreItem = scoreItems[self.scoreItemIndex]
	self.scoreItem = scoreItem
	if scoreItem then
		self.config.scoreEntryId = scoreItem.scoreEntry.id
	end
end

return SelectModel
