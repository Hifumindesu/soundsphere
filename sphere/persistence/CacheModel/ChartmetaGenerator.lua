local class = require("class")
local md5 = require("md5")

---@class sphere.ChartmetaGenerator
---@operator call: sphere.ChartmetaGenerator
local ChartmetaGenerator = class()

---@param chartRepo sphere.ChartRepo
---@param noteChartFactory notechart.NoteChartFactory
---@param fs love.filesystem
function ChartmetaGenerator:new(chartRepo, noteChartFactory, fs)
	self.chartRepo = chartRepo
	self.noteChartFactory = noteChartFactory
	self.fs = fs
	self.reused = 0
	self.cached = 0
end

---@param full boolean?
---@param after function?
function ChartmetaGenerator:generate(full, after)
	local chartfiles = self.chartRepo:selectUnhashedChartfiles()

	for i, chartfile in ipairs(chartfiles) do
		local status, err = self:processChartfile(chartfile, full)

		if not status then
			print(chartfile.id)
			print(chartfile.dir .. "/" .. chartfile.name)
			print(err)
		elseif status == "reused" then
			self.reused = self.reused + 1
		elseif status == "cached" then
			self.cached = self.cached + err
		end

		if after and after(i, #chartfiles, chartfile) then
			return
		end
	end
end

---@param chartfile table
---@param full boolean?
function ChartmetaGenerator:processChartfile(chartfile, full)
	local path = chartfile.dir .. "/" .. chartfile.name

	local content = assert(self.fs.read(path))
	local hash = md5.sumhexa(content)

	chartfile.hash = hash
	self.chartRepo:updateChartfile(chartfile)

	if not full and self.chartRepo:selectChartmeta(hash, 1) then
		return "reused"
	end

	local noteCharts, err = self.noteChartFactory:getNoteCharts(path, content)
	if not noteCharts then
		return nil, err
	end

	for index, noteChart in ipairs(noteCharts) do
		local chartmeta = noteChart.metaData
		chartmeta.index = index
		chartmeta.hash = hash
		self:setChartmeta(chartmeta)
	end

	return "cached", #noteCharts
end

---@param chartmeta table
function ChartmetaGenerator:setChartmeta(chartmeta)
	local old = self.chartRepo:selectChartmeta(chartmeta.hash, chartmeta.index)
	if not old then
		self.chartRepo:insertChartmeta(chartmeta)
		return
	end
	chartmeta.id = old.id
	self.chartRepo:updateChartmeta(chartmeta)
end

return ChartmetaGenerator
