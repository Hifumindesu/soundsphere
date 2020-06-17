local ScoreDatabase	= require("sphere.database.ScoreDatabase")
local Log			= require("aqua.util.Log")

local ScoreManager = {}

ScoreDatabase.init = function(self)
	self.log = Log:new()
	self.log.console = true
	self.log.path = "userdata/scores.log"
end

local sortByScore = function(a, b)
	return a.score > b.score
end

ScoreManager.select = function(self)
	local loaded = ScoreDatabase.loaded
	if not loaded then
		ScoreDatabase:load()
	end

	local scores = {}
	self.scores = scores
	
	local scoreColumns = ScoreDatabase.scoreColumns
	local scoreNumberColumns = ScoreDatabase.scoreNumberColumns

	local selectScoresStatement = ScoreDatabase.selectScoresStatement
	
	local stmt = selectScoresStatement:reset()
	local row = stmt:step()
	while row do
		local entry = ScoreDatabase:transformScoreEntry(row)
		scores[#scores + 1] = entry

		row = stmt:step()
	end
	
	local scoresId = {}
	self.scoresId = scoresId
	
	for i = 1, #scores do
		local entry = scores[i]
		scoresId[entry.id] = entry
	end
	
	local scoresHashIndex = {}
	self.scoresHashIndex = scoresHashIndex
	
	for i = 1, #scores do
		local entry = scores[i]
		local hash = entry.noteChartHash
		local index = entry.noteChartIndex
		scoresHashIndex[hash] = scoresHashIndex[hash] or {}
		scoresHashIndex[hash][index] = scoresHashIndex[hash][index] or {}
		local list = scoresHashIndex[hash][index]
		list[#list + 1] = entry
	end
	for _, list in pairs(scoresHashIndex) do
		for _, sublist in pairs(list) do
			table.sort(sublist, sortByScore)
		end
	end

	if not loaded then
		ScoreDatabase:unload()
	end
end

ScoreManager.insertScore = function(self, scoreTable, noteChartDataEntry)
	ScoreDatabase:insertScore({
		noteChartHash = noteChartDataEntry.hash,
		noteChartIndex = noteChartDataEntry.index,
		playerName = "Player",
		time = os.time(),
		score = scoreTable.score,
		accuracy = scoreTable.accuracy,
		maxCombo = scoreTable.maxcombo,
		scoreRating = 0,
		mods = "None"
	})
	self:select()
end

ScoreManager.getScores = function(self)
	return self.scores
end

ScoreManager.getScores = function(self)
	return self.scores
end

ScoreManager.getScoreEntryById = function(self, id)
	return self.scoresId[id]
end

ScoreManager.getScoreEntries = function(self, hash, index)
	local t = self.scoresHashIndex
	return t[hash] and t[hash][index]
end

return ScoreManager
