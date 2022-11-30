local Class = require("Class")
local gfx_util = require("gfx_util")
local spherefonts = require("sphere.assets.fonts")
local just = require("just")
local DynamicLayerData = require("ncdk.DynamicLayerData")
local Fraction = require("ncdk.Fraction")
local imgui = require("sphere.imgui")

local Layout = require("sphere.views.EditorView.Layout")

local SnapGridView = Class:new()

SnapGridView.construct = function(self)
	local ld = DynamicLayerData:new()
	self.layerData = ld

	ld:setTimeMode("measure")
	ld:setSignatureMode("short")
	ld:setRange(Fraction(0), Fraction(10))

	ld:getSignatureData(2, Fraction(3))
	ld:getSignatureData(3, Fraction(34, 10))

	ld:getTempoData(Fraction(1), 60)
	ld:getTempoData(Fraction(3.5, 10, true), 120)

	ld:getStopData(Fraction(5), Fraction(4))

	ld:getVelocityData(Fraction(0.5, 10, true), -1, 1)
	ld:getVelocityData(Fraction(4.5, 10, true), -1, 2)
	ld:getVelocityData(Fraction(5, 4), -1, 0)
	ld:getVelocityData(Fraction(6, 4), -1, 1)

	ld:getExpandData(Fraction(2), -1, Fraction(1))

	self.beatTime = 0
	self.absoluteTime = 0
	self.visualTime = 0

	self.snap = 1

	self.pixelsPerBeat = 40
	self.pixelsPerSecond = 40
end

local function getTimePointText(timePoint)
	if timePoint._tempoData then
		return timePoint._tempoData.tempo .. " bpm"
	elseif timePoint._stopData then
		return "stop " .. timePoint._stopData.duration:tonumber() .. " beats"
	elseif timePoint._velocityData then
		return timePoint._velocityData.currentSpeed .. "x"
	elseif timePoint._expandData then
		return "expand into " .. timePoint._expandData.duration:tonumber() .. " beats"
	end
end

SnapGridView.drawTimingObjects = function(self, field, currentTime, pixels)
	local rangeTracker = self.layerData.timePointsRange
	local object = rangeTracker.startObject
	if not object then
		return
	end

	local endObject = rangeTracker.endObject
	while object and object <= endObject do
		local text = getTimePointText(object)
		if text then
			local y = (object[field] - currentTime) * pixels
			love.graphics.line(0, y, 10, y)
			gfx_util.printFrame(text, -500, y - 25, 490, 50, "right", "center")
		end

		object = object.next
	end
end

local colors = {
	white = {1, 1, 1},
	red = {1, 0, 0},
	blue = {0, 0, 1},
	green = {0, 1, 0},
	yellow = {1, 1, 0},
	violet = {1, 0, 1},
}

local snaps = {
	[1] = colors.white,
	[2] = colors.red,
	[3] = colors.violet,
	[4] = colors.blue,
	[5] = colors.yellow,
	[6] = colors.violet,
	[7] = colors.yellow,
	[8] = colors.green,
}

local function getSnapColor(j, snap)
	for i = 1, 16 do
		if snap % i == 0 then
			if (j - 1) % (snap / i) == 0 then
				return snaps[i] or colors.white
			end
		end
	end
	return colors.white
end

SnapGridView.drawComputedGrid = function(self, field, currentTime, pixels)
	local ld = self.layerData
	local snap = self.snap

	for time = ld.startTime:ceil(), ld.endTime:floor() do
		local signature = ld:getSignature(time)
		local _signature = signature:ceil()
		for i = 1, _signature do
			for j = 1, snap do
				local f = Fraction((i - 1) * snap + j - 1, signature * snap)
				if f:tonumber() < 1 then
					local timePoint = ld:getDynamicTimePoint(f + time, -1)
					if not timePoint then break end
					local y = (timePoint[field] - currentTime) * pixels

					local w = 30
					if i == 1 and j == 1 then
						w = 60
					end
					love.graphics.setColor(getSnapColor(j, snap))
					love.graphics.line(0, y, w, y)
				end
			end
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
end

SnapGridView.drawUI = function(self, w, h)
	just.push()

	imgui.setSize(w, h, 200, 55)
	self.snap = imgui.slider1("snap select", self.snap, "%d", 1, 16, 1, "snap")
	self.pixelsPerBeat = imgui.slider1("beat pixels", self.pixelsPerBeat, "%d", 10, 1000, 10, "pixels per beat")
	self.pixelsPerSecond = imgui.slider1("second pixels", self.pixelsPerSecond, "%d", 10, 1000, 10, "pixels per second")

	just.pop()
end

local function drag(id, w, h)
	local over = just.is_over(w, h)
	local _, active, hovered = just.button(id, over)

	if hovered then
		local alpha = active and 0.2 or 0.1
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.rectangle("fill", 0, 0, w, h)
	end
	love.graphics.setColor(1, 1, 1, 1)

	just.next(w, h)

	return just.active_id == id
end

local prevMouseY = 0
SnapGridView.draw = function(self)
	local w, h = Layout:move("base")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(spherefonts.get("Noto Sans", 24))

	self:drawUI(w, h)

	love.graphics.translate(w / 5, 0)

	local ld = self.layerData
	local dtp = ld:getDynamicTimePointAbsolute(self.absoluteTime, 192, -1)
	self.visualTime = dtp.visualTime
	self.beatTime = dtp.beatTime
	local measureOffset = dtp.measureTime:floor()

	love.graphics.push()
	love.graphics.translate(0, h / 2)
	love.graphics.line(0, 0, 240, 0)

	love.graphics.translate(-40, 0)
	self:drawTimingObjects("beatTime", self.beatTime, self.pixelsPerBeat)
	love.graphics.translate(40, 0)
	self:drawComputedGrid("beatTime", self.beatTime, self.pixelsPerBeat)

	love.graphics.translate(80, 0)
	self:drawComputedGrid("absoluteTime", self.absoluteTime, self.pixelsPerSecond)

	love.graphics.translate(80, 0)
	self:drawComputedGrid("visualTime", self.visualTime, self.pixelsPerSecond)

	love.graphics.pop()

	local delta = 2
	if ld.startTime:tonumber() ~= measureOffset - delta then
		ld:setRange(Fraction(measureOffset - delta), Fraction(measureOffset + delta))
	end

	local _, my = love.graphics.inverseTransformPoint(love.mouse.getPosition())
	my = h - my

	just.push()
	just.row(true)
	local pixels = drag("drag1", 80, h) and self.pixelsPerBeat or drag("drag2", 160, h) and self.pixelsPerSecond
	if pixels then
		self.absoluteTime = self.absoluteTime + (my - prevMouseY) / pixels
	end
	just.row(false)
	just.pop()

	prevMouseY = my

	local scroll = just.wheel_over("scale scroll", just.is_over(240, h))
	scroll = scroll and -scroll
	if just.keypressed("right") then
		scroll = 1
	elseif just.keypressed("left") then
		scroll = -1
	end

	if scroll then
		dtp = ld:getDynamicTimePointAbsolute(self.absoluteTime, 192, -1)
		local signature = ld:getSignature(measureOffset)
		local sigSnap = signature * self.snap

		local targetMeasureOffset
		if scroll == -1 then
			targetMeasureOffset = dtp.measureTime:ceil() - 1
		else
			targetMeasureOffset = (dtp.measureTime + Fraction(1) / sigSnap):floor()
		end
		signature = ld:getSignature(targetMeasureOffset)
		sigSnap = signature * self.snap

		local measureTime
		if measureOffset ~= targetMeasureOffset then
			if scroll == -1 then
				measureTime = Fraction(sigSnap:ceil() - 1) / sigSnap + targetMeasureOffset
			else
				measureTime = Fraction(targetMeasureOffset)
			end
		else
			local snapTime = (dtp.measureTime - measureOffset) * sigSnap

			local targetSnapTime
			if scroll == -1 then
				targetSnapTime = snapTime:ceil() - 1
			else
				targetSnapTime = snapTime:floor() + 1
			end

			measureTime = Fraction(targetSnapTime) / sigSnap + measureOffset
		end

		dtp = ld:getDynamicTimePoint(measureTime)
		self.absoluteTime = dtp.absoluteTime
		self.visualTime = dtp.visualTime
		self.beatTime = dtp.beatTime
	end
end

return SnapGridView
