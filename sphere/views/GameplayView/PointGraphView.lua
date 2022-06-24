
local transform = require("aqua.graphics.transform")
local map				= require("aqua.math").map
local Class				= require("aqua.util.Class")
local inside = require("aqua.util.inside")

local PointGraphView = Class:new()

PointGraphView.load = function(self)
	self.drawnPoints = 0
	self.drawnBackgroundPoints = 0

	self.startTime = self.game.noteChartModel.noteChart.metaData:get("minTime")
	self.endTime = self.game.noteChartModel.noteChart.metaData:get("maxTime")

	self.canvas = love.graphics.newCanvas()
	self.backgroundCanvas = love.graphics.newCanvas()
end

PointGraphView.draw = function(self)
	if self.show and not self.show(self) then
		return
	end

	if self.background then
		self:drawPoints("drawnBackgroundPoints", self.backgroundCanvas, self.backgroundColor, self.backgroundRadius)
	end
	self:drawPoints("drawnPoints", self.canvas, self.color, self.radius)

	love.graphics.origin()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.backgroundCanvas, 0, 0)
	love.graphics.draw(self.canvas, 0, 0)
end

PointGraphView.update = function(self, dt) end
PointGraphView.unload = function(self) end

PointGraphView.receive = function(self, event)
	if event.name == "resize" then
		self:reload()
	end
end

PointGraphView.reload = function(self)
	self:unload()
	self:load()
end

PointGraphView.drawPoints = function(self, counter, canvas, color, radius)
	local shader = love.graphics.getShader()
	love.graphics.setShader()
	love.graphics.setCanvas(canvas)

	local tf = transform(self.transform):translate(self.x, self.y)
	love.graphics.replaceTransform(tf)

	local points = inside(self, self.key)
	for i = self[counter] + 1, #points do
		self:drawPoint(points[i], color, radius)
	end
	self[counter] = #points

	love.graphics.setCanvas()
	love.graphics.setShader(shader)
end

PointGraphView.drawPoint = function(self, point, color, radius)
	local time = inside(point, self.time)
	local value = inside(point, self.value)
	local unit = inside(point, self.unit)
	if type(time) == "nil" then
		time = tonumber(self.time) or 0
	end
	if type(value) == "nil" then
		value = tonumber(self.value) or 0
	end
	if type(unit) == "nil" then
		unit = tonumber(self.unit) or 1
	end

	if type(color) == "function" then
		color = color(time, self.startTime, self.endTime, value, unit)
	end
	love.graphics.setColor(color)

	if self.point then
		local x, y = self.point(time, self.startTime, self.endTime, value, unit)
		if not x then
			return
		end
		x = math.min(math.max(x, 0), 1)
		y = math.min(math.max(y, 0), 1)
		local _x, _y = map(x, 0, 1, 0, self.w), map(y, 0, 1, 0, self.h)
		love.graphics.rectangle("fill", _x - radius, _y - radius, radius * 2, radius * 2)
	elseif self.line then
		local x = self.line(time, self.startTime, self.endTime, value, unit)
		if not x then
			return
		end
		x = math.min(math.max(x, 0), 1)
		local _x = map(x, 0, 1, 0, self.w)
		love.graphics.rectangle("fill", _x - radius, 0, radius * 2, self.h)
	end
end

return PointGraphView
