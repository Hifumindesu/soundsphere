local LayerData = require("ncdk.LayerData")
local Fraction = require("ncdk.Fraction")

local timingMatchWindow = 0.005  -- 0.005s for 60 bpm, 0.0025 for 120 bpm, etc

--[[
osu rounds time down
in this case approximate fraction should be >= absolute time
because rounded time may be closer to incorrect fraction
use fraction_mode = "closest_gte"
]]

return function(layerData, fraction_mode)
	if not fraction_mode then
		fraction_mode = false
	end

	local newLayerData = LayerData()
	newLayerData:setTimeMode("interval")

	for i = 1, #layerData.tempoDatas do
		local td = layerData.tempoDatas[i]
		td.prev = layerData.tempoDatas[i - 1]
		td.next = layerData.tempoDatas[i + 1]
	end

	local intervalsMap = {}
	for _, tp in ipairs(layerData.timePointList) do
		local td = tp.tempoData
		intervalsMap[td] = intervalsMap[td] or {tempoData = td}
		table.insert(intervalsMap[td], tp)
	end
	local intervals = {}
	for _, interval in pairs(intervalsMap) do
		table.insert(intervals, interval)
	end
	table.sort(intervals, function(a, b)
		return a.tempoData < b.tempoData
	end)

	local timePointMap = {}
	local intervalData
	for i, interval in ipairs(intervals) do
		local td = interval.tempoData
		table.sort(interval)

		local is_same = interval[#interval].absoluteTime == td.timePoint.absoluteTime
		interval.beats = 1
		if not is_same and i < #intervals then
			local _interval = {}
			local next_interval = intervals[i + 1]
			local next_td = next_interval.tempoData
			local idt = next_td.timePoint.absoluteTime - td.timePoint.absoluteTime
			local beats = idt / td:getBeatDuration()
			local next_td_time = Fraction(beats, 16, fraction_mode)
			local idt_new = next_td_time:floor() * td:getBeatDuration()
			local _time = next_td_time - Fraction(1, 16)
			_interval.beats = next_td_time:floor()
			if _time:tonumber() <= 0 then
				_interval.beats = 1
			elseif math.abs(idt_new - idt) > timingMatchWindow * td:getBeatDuration() then
				_interval.beats = _time:floor()
			end
			for j, tp in ipairs(interval) do
				local dt = tp.absoluteTime - td.timePoint.absoluteTime
				local time = Fraction(dt / td:getBeatDuration(), 16, fraction_mode)
				if time == next_td_time and time[1] ~= 0 then
					table.insert(next_interval, tp)
				else
					table.insert(_interval, tp)
				end
			end
			interval = _interval
		end
		table.sort(interval)

		is_same = interval[#interval].absoluteTime == td.timePoint.absoluteTime
		if is_same then
			interval.beats = 1
		end

		intervalData = newLayerData:insertIntervalData(td.timePoint.absoluteTime, interval.beats)

		for j, tp in ipairs(interval) do
			local dt = tp.absoluteTime - td.timePoint.absoluteTime
			local beatDuraion = td:getBeatDuration()
			local time = Fraction(dt / beatDuraion, 16, fraction_mode)

			if #interval > 1 and dt > 0 and i < #intervals and j == #interval then
				local next_interval = intervals[i + 1]
				local next_td = next_interval.tempoData
				local idt = next_td.timePoint.absoluteTime - td.timePoint.absoluteTime
				local beats = idt / beatDuraion
				local next_td_time = Fraction(beats, 16, fraction_mode)
				local idt_new = next_td_time:floor() * beatDuraion
				local _time = next_td_time - Fraction(1, 16)
				local t = td.timePoint.absoluteTime + _time:tonumber() * beatDuraion
				if _time:tonumber() > 0 and math.abs(idt_new - idt) > timingMatchWindow * beatDuraion then
					local id = newLayerData:insertIntervalData(t, 1, _time % 1)
					if time == _time then
						intervalData = id
						time = Fraction(0)
					end
				end
			end
			if i == #intervals and j == #interval then
				local beats = math.ceil(dt / beatDuraion)
				if beats > 0 then
					intervalData.beats = beats
					local t = td.timePoint.absoluteTime + beatDuraion * beats
					local id = newLayerData:insertIntervalData(t, 1)
					if time == Fraction(beats) then
						intervalData = id
						time = Fraction(0)
					end
				end
			end

			timePointMap[tp] = newLayerData:getTimePoint(intervalData, time, tp.visualSide)
		end
	end

	if #newLayerData.intervalDatas == 1 then
		local td = layerData.tempoDatas[1]
		local beatDuration = td:getBeatDuration()
		intervalData = newLayerData:insertIntervalData(td.timePoint.absoluteTime + beatDuration, 1)
	end

	for inputMode, r in pairs(layerData.noteDatas) do
		for inputIndex, _noteDatas in pairs(r) do
			for _, noteData in ipairs(_noteDatas) do
				noteData.timePoint = timePointMap[noteData.timePoint]
			end
		end
	end
	newLayerData.noteDatas = layerData.noteDatas

	for _, velocityData in ipairs(layerData.velocityDatas) do
		velocityData.timePoint = timePointMap[velocityData.timePoint]
		velocityData.timePoint._velocityData = velocityData
	end
	newLayerData.velocityDatas = layerData.velocityDatas

	for _, expandData in ipairs(layerData.expandDatas) do
		expandData.timePoint = timePointMap[expandData.timePoint]
		expandData.timePoint._expandData = expandData
	end
	newLayerData.expandDatas = layerData.expandDatas

	newLayerData:compute()

	return newLayerData, timePointMap
end
