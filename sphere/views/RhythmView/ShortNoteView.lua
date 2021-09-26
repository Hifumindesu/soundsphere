local NoteView = require("sphere.views.RhythmView.NoteView")

local ShortNoteView = NoteView:new({construct = false})

ShortNoteView.construct = function(self)
	NoteView.construct(self)
	self.headView = self:newNotePartView("Head")
end

ShortNoteView.update = function(self)
	self.timeState = self.graphicalNote.timeState
	self.logicalState = self.graphicalNote.logicalNote:getLastState()
	self.headView.timeState = self.graphicalNote.startTimeState or self.graphicalNote.timeState
end

ShortNoteView.draw = function(self)
	local spriteBatch = self.headView:getSpriteBatch()
	if not spriteBatch then
		return
	end
	spriteBatch:setColor(self.headView:get("color"))
	spriteBatch:add(self:getDraw(self.headView:getQuad(), self:getTransformParams()))
end

ShortNoteView.getTransformParams = function(self)
	local hw = self.headView
	local w, h = hw:getDimensions()
	return
		hw:get("x"),
		hw:get("y"),
		hw:get("r"),
		hw:get("w") / w,
		hw:get("h") / h,
		hw:get("ox") * w,
		hw:get("oy") * h
end

return ShortNoteView
