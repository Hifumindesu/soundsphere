CloudburstEngine.LongLogicalNote = createClass(CloudburstEngine.LogicalNote)
local LongLogicalNote = CloudburstEngine.LongLogicalNote


LongLogicalNote.update = function(self)
	if self.ended or self.state == "endPassed" or self.state == "endMissed" or self.state == "endMissedPassed" then
		return
	end
	
	local deltaStartTime = self.startNoteData.timePoint:getAbsoluteTime() - self.engine.currentTime
	local deltaEndTime = self.endNoteData.timePoint:getAbsoluteTime() - self.engine.currentTime
	
	local startTimeState = self.engine:getTimeState(deltaStartTime)
	local endTimeState = self.engine:getTimeState(deltaEndTime)
	
	if self.engine.autoplay then
		if deltaStartTime < 0 and not self.keyState then
			self.noteHandler.keyState = true
			self.noteHandler:sendState()
			
			if self.pressSoundFilePath then
				self.engine.core.audioManager:playSound(self.pressSoundFilePath)
			end
			deltaStartTime = 0
			endTimeState = "early"
			self.keyState = true
			self.state = "startPassedPressed"
			self:sendState()
		elseif deltaEndTime < 0 and self.keyState then
			self.noteHandler.keyState = false
			self.noteHandler:sendState()
			
			if self.releaseSoundFilePath then
				self.engine.core.audioManager:playSound(self.releaseSoundFilePath)
			end
			deltaEndTime = 0
			endTimeState = "exactly"
			self.keyState = false
			self.state = "endPassed"
			self:sendState()
			return self:next()
		end
	end
	
	self.oldState = self.state
	if self.keyState and timeState == "none" then
		self.keyState = false
	elseif self.state == "clear" then
		if startTimeState == "late" then
			self.state = "startMissed"
			return self:sendState()
		elseif self.keyState then
			if startTimeState == "early" then
				self.state = "startMissedPressed"
				return self:sendState()
			elseif startTimeState == "exactly" then
				self.state = "startPassedPressed"
				return self:sendState()
			end
		end
	elseif self.state == "startPassedPressed" then
		self:updateFakeStartTime()
		if not self.keyState then
			if endTimeState == "none" then
				self.state = "startMissed"
				return self:sendState()
			elseif endTimeState == "exactly" then
				self.state = "endPassed"
				self:sendState()
				return self:next()
			end
		elseif endTimeState == "late" then
			self.state = "endMissed"
			self:sendState()
			return self:next()
		end
	elseif self.state == "startMissedPressed" then
		if not self.keyState then
			if endTimeState == "exactly" then
				self.state = "endMissedPassed"
				self:sendState()
				return self:next()
			else
				self.state = "startMissed"
			end
		elseif endTimeState == "late" then
			self.state = "endMissed"
			self:sendState()
			return self:next()
		end
	elseif self.state == "startMissed" then
		if self.keyState then
			self.state = "startMissedPressed"
			return self:sendState()
		elseif endTimeState == "late" then
			self.state = "endMissed"
			self:sendState()
			return self:next()
		end
	end
end

LongLogicalNote.updateFakeStartTime = function(self)
	local startTime = self.startNoteData.timePoint:getAbsoluteTime()
	local endTime = self.endNoteData.timePoint:getAbsoluteTime()
	self.fakeStartTime = self.engine.currentTime > startTime and self.engine.currentTime or startTime
	self.fakeStartTime = math.min(self.fakeStartTime, endTime)
end

LongLogicalNote.getFakeStartTime = function(self)
	local startTime = self.startNoteData.timePoint:getAbsoluteTime()
	if self.state == "startPassedPressed" and self.fakeStartTime then
		self:updateFakeStartTime()
		return self.fakeStartTime
	else
		return self.fakeStartTime or self.startNoteData.timePoint:getAbsoluteTime()
	end
end

LongLogicalNote.getFakeVelocityData = function(self)
	if self.state == "startPassedPressed" and self.fakeStartTime then
		return "current"
	else
		return self.fakeVelocityData or self.startNoteData.timePoint.velocityData
	end
end