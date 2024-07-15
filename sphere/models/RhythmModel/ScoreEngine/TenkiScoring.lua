
local BaseJudge = require("sphere.models.RhythmModel.ScoreEngine.Judge")
local ScoreSystem = require("sphere.models.RhythmModel.ScoreEngine.ScoreSystem")

---@class sphere.TenkiScoring: sphere.ScoreSystem
---@operator call: sphere.TenkiScoring
local TenkiScoring = ScoreSystem + {}

TenkiScoring.name = "tenki"
TenkiScoring.metadata = {
	name = "Tenki",
}

local Judge = BaseJudge + {}

Judge.orderedCounters = { "critical", "perfect", "great", "good", "okay" }

---@param windows table
function Judge:new(windows)
	self.scoreSystemName = TenkiScoring.name

	self.windows = windows

	self.counters = {
		critical = 0,
		perfect = 0,
		great = 0,
		good = 0,
		okay = 0,
		miss = 0,
	}

	self.weights = {
		critical = 100,
		perfect = 100,
		great = 66.67,
		good = 33.33,
		okay = 16.67,
		miss = 0,
	}

	self.earlyHitWindow = -self.windows.okay
	self.lateHitWindow = self.windows.okay
	self.earlyMissWindow = -self.windows.miss
	self.lateMissWindow = self.windows.miss

	self.windowReleaseMultiplier = 1.5
end

function Judge:calculateAccuracy()
	local maxScore = self.notes * self.weights[self.orderedCounters[1]]
	local hitScore = 0
	local accScore = 0

	for key, count in pairs(self.counters) do
		hitScore = hitScore + (self.weights[key] * count)
	end

	local ssRank = hitScore / maxScore

	if ssRank >= 1 then
		local ratio = (self.counters[self.orderedCounters[1]] / self.notes) * 0.01
		accScore = (hitScore + ratio) / maxScore
	else
		local bonus = self.counters[self.orderedCounters[1]] * 1.67
		accScore = (hitScore + bonus) / (maxScore + bonus)
	end

	self.accuracy = math.max(0, maxScore > 0 and accScore or 1.01)
end

function Judge:getTimings()
	local early_hit = self.earlyHitWindow
	local late_hit = self.lateHitWindow
	local early_miss = self.earlyMissWindow
	local late_miss = self.lateMissWindow

	return {
		nearest = true,
		ShortNote = {
			hit = { early_hit, late_hit },
			miss = { early_miss, late_miss },
		},
		LongNoteStart = {
			hit = { early_hit, late_hit },
			miss = { early_miss, late_miss },
		},
		LongNoteEnd = {
			hit = { early_hit, late_hit },
			miss = { early_miss, late_miss },
		},
	}
end

local stdWindows = {
	critical = 0.025,
	perfect = 0.050,
	great = 0.075,
	good = 0.100,
	okay = 0.125,
	miss = 0.150,
}

function TenkiScoring:load()
	self.judges = {
		[self.metadata.name] = Judge(stdWindows),
	}
end

---@param event table
function TenkiScoring:hit(event)
	for _, judge in pairs(self.judges) do
		judge:processEvent(event)
		judge:calculateAccuracy()
	end
end

function TenkiScoring:releaseFail(event)
	for _, judge in pairs(self.judges) do
		judge:addCounter("good", event.currentTime)
		judge:calculateAccuracy()
	end
end

function TenkiScoring:miss(event)
	for _, judge in pairs(self.judges) do
		judge:addCounter("miss", event.currentTime)
		judge:calculateAccuracy()
	end
end

function TenkiScoring:getTimings()
	local judge = Judge(stdWindows)
	return judge:getTimings()
end

TenkiScoring.notes = {
	ShortNote = {
		clear = {
			passed = "hit",
			missed = "miss",
			clear = nil,
		},
	},
	LongNote = {
		clear = {
			startPassedPressed = "hit",
			startMissed = "miss",
			startMissedPressed = "miss",
			clear = nil,
		},
		startPassedPressed = {
			startMissed = "miss",
			endMissed = "releaseFail",
			endPassed = "hit",
		},
		startMissedPressed = {
			endMissedPassed = nil,
			startMissed = nil,
			endMissed = nil,
		},
		startMissed = {
			startMissedPressed = nil,
			endMissed = "miss",
		},
	},
}

return TenkiScoring
