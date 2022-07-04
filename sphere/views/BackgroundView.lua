
local Class = require("aqua.util.Class")
local frame_draw = require("aqua.graphics.frame_draw")
local map = require("aqua.math").map
local transform = require("aqua.graphics.transform")
local inside = require("aqua.util.inside")

local BackgroundView = Class:new()

BackgroundView.draw = function(self)
	local dim = self.dim.value or inside(self, self.dim.key)
	if dim == 1 then
		return
	end

	self:drawBackground()
end

BackgroundView.drawBackground = function(self)
	local backgroundModel = self.game.backgroundModel
	local tf = transform(self.transform):translate(self.x, self.y)
	love.graphics.replaceTransform(tf)
	-- love.graphics.origin()

	local images = backgroundModel.images
	local alpha = backgroundModel.alpha

	local dim = 1 - (self.dim.value or inside(self, self.dim.key))
	local r, g, b = dim, dim, dim

	local mx, my = love.mouse.getPosition()
	-- local w, h = love.graphics.getDimensions()
	local w, h = self.w, self.h
	for i = 1, 3 do
		if not images[i] then
			return
		end

		if i == 1 then
			love.graphics.setColor(r, g, b, 1)
		elseif i == 2 then
			love.graphics.setColor(r, g, b, alpha)
		elseif i == 3 then
			love.graphics.setColor(r, g, b, 0)
		end

		frame_draw(
			images[i],
			-map(mx, 0, w, self.parallax, 0) * w,
			-map(my, 0, h, self.parallax, 0) * h,
			(1 + 2 * self.parallax) * w,
			(1 + 2 * self.parallax) * h,
			"out"
		)
	end
end

return BackgroundView
