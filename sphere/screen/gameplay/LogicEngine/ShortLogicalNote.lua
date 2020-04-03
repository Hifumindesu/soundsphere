local LogicalNote = require("sphere.screen.gameplay.LogicEngine.LogicalNote")

local ShortLogicalNote = LogicalNote:new()

ShortLogicalNote.noteClass = "ShortLogicalNote"

ShortLogicalNote.construct = function(self)
	self.startNoteData = self.noteData
	self.noteData = nil

	self.keyBind = self.startNoteData.inputType .. self.startNoteData.inputIndex
end

ShortLogicalNote.process = function(self)
	if self.ended then
		return
	end

	local deltaTime = self.logicEngine.currentTime - self.startNoteData.timePoint.absoluteTime
	local timeState = self.score:getTimeState(deltaTime)
	
	if not self.autoplay then
		self:processTimeState(timeState)
	else
		self:processAuto()
	end
	-- self:processShortNoteState(note.state)
	
	-- if note.ended then
	-- 	self:hit(deltaTime, note.startNoteData.timePoint.absoluteTime)
	-- end
end

ShortLogicalNote.processTimeState = function(self, timeState)
	if self.keyState and timeState == "none" then
		self.keyState = false
	elseif self.keyState and timeState == "early" then
		self.state = "missed"
		return self:next()
	elseif timeState == "late" then
		self.state = "missed"
		return self:next()
	elseif self.keyState and timeState == "exactly" then
		self.state = "passed"
		return self:next()
	end
end

ShortLogicalNote.processAuto = function(self)
	local deltaTime = self.logicEngine.currentTime - self.startNoteData.timePoint.absoluteTime
	if deltaTime >= 0 then
		self.keyState = true
		self:sendState("keyState")
		
		self:processTimeState("exactly")
		-- note.score:processShortNoteState(note.state)
		
		-- if note.ended then
		-- 	note.score:hit(0, note.startNoteData.timePoint.absoluteTime)
		-- end
	end
end

ShortLogicalNote.receive = function(self, event)
	local key = event.args and event.args[1]
	if key == self.keyBind then
		if event.name == "keypressed" then
			self.keyState = true
			return self:sendState("keyState")
		elseif event.name == "keyreleased" then
			self.keyState = false
			return self:sendState("keyState")
		end
	end
end

return ShortLogicalNote
