local ListView = require("sphere.views.ListView")
local just = require("just")
local TextCellImView = require("sphere.imviews.TextCellImView")
local LabelImView = require("sphere.imviews.LabelImView")
local Format = require("sphere.views.Format")
local TextButtonImView = require("sphere.imviews.TextButtonImView")

local RoomUsersListView = ListView:new({construct = false})

RoomUsersListView.reloadItems = function(self)
	self.items = self.game.multiplayerModel.roomUsers
end

RoomUsersListView.drawItem = function(self, i, w, h)
	local items = self.items
	local user = items[i]

	local multiplayerModel = self.game.multiplayerModel
	local room = self.game.multiplayerModel.room
	if not room then
		return
	end

	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	if user.isReady then
		love.graphics.setColor(0.3, 1, 0.3, 1)
	end
	if not user.isNotechartFound then
		love.graphics.setColor(1, 0.3, 0.1, 1)
	end
	love.graphics.rectangle("fill", 0, 0, 12, h)
	love.graphics.setColor(1, 1, 1, 1)

	local name = user.name
	if room.hostPeerId == user.peerId then
		name = name .. " host"
	end
	if user.isPlaying then
		name = name .. " playing"
	end

	just.row(true)
	just.indent(18)
	LabelImView(user, name, h)
	just.row(false)

	if not multiplayerModel:isHost() or room.hostPeerId == user.peerId then
		return
	end

	local s = tostring(self)
	if just.button(s .. i .. "button", just.is_over(w, -h)) then
		local width = 200
		self.game.gameView:setContextMenu(function()
			local close = false
			just.indent(10)
			just.text(user.name)
			love.graphics.line(0, 0, 200, 0)
			if TextButtonImView("Kick", "Kick", width, 55) then
				multiplayerModel:kickUser(user.peerId)
				close = true
			end
			if TextButtonImView("Give host", "Give host", width, 55) then
				multiplayerModel:setHost(user.peerId)
				close = true
			end
			if TextButtonImView("Close", "Close", width, 55) then
				close = true
			end
			return close
		end, width)
	end
end

return RoomUsersListView
