CloudburstEngine.NoteHandler = createClass(soul.SoulObject)
local NoteHandler = CloudburstEngine.NoteHandler

NoteHandler.autoplayDelay = 1/15

NoteHandler.loadNoteData = function(self)
	self.noteData = {}
	
	for layerDataIndex in self.engine.noteChart:getLayerDataIndexIterator() do
		local layerData = self.engine.noteChart:requireLayerData(layerDataIndex)
		for noteDataIndex = 1, layerData:getNoteDataCount() do
			local noteData = layerData:getNoteData(noteDataIndex)
			
			if noteData.inputType == self.inputType and noteData.inputIndex == self.inputIndex then
				local logicalNote
				
				local soundFilePath
				if noteData.soundFileName then
					if not self.engine.soundFiles[noteData.soundFileName] then
						self.engine.soundFiles[noteData.soundFileName] = self.engine.fileManager:findFile(noteData.soundFileName, "audio")
					end
					soundFilePath = self.engine.soundFiles[noteData.soundFileName]
				end
				
				if noteData.noteType == "ShortNote" then
					logicalNote = self.engine.ShortLogicalNote:new({
						startNoteData = noteData,
						pressSoundFilePath = soundFilePath
					})
				elseif noteData.noteType == "LongNoteStart" then
					logicalNote = self.engine.LongLogicalNote:new({
						startNoteData = noteData,
						endNoteData = noteData.endNoteData,
						pressSoundFilePath = soundFilePath
					})
				elseif noteData.noteType == "LineNoteStart" then
					logicalNote = self.engine.SoundNote:new({
						startNoteData = noteData,
						endNoteData = noteData.endNoteData,
						pressSoundFilePath = soundFilePath
					})
				elseif noteData.noteType == "SoundNote" then
					logicalNote = self.engine.SoundNote:new({
						startNoteData = noteData,
						pressSoundFilePath = soundFilePath
					})
				end
				
				if logicalNote then
					logicalNote.noteHandler = self
					logicalNote.engine = self.engine
					table.insert(self.noteData, logicalNote)
					
					self.engine.sharedLogicalNoteData[noteData] = logicalNote
				end
			end
		end
	end
	
	table.sort(self.noteData, function(a, b)
		return a.startNoteData.timePoint < b.startNoteData.timePoint
	end)

	for index, logicalNote in ipairs(self.noteData) do
		logicalNote.index = index
	end
	
	self.startNoteIndex = 1
	self.currentNote = self.noteData[1]
end

NoteHandler.setKeyState = function(self)
	self.keyBind = self.engine.inputMode:getString() .. ":" .. self.inputType .. self.inputIndex
	self.keyState = love.keyboard.isDown(self.keyBind)
end

NoteHandler.update = function(self)
	self.currentNote:update()
	if self.click then
		self.keyTimer = self.keyTimer + love.timer.getDelta()
		if self.keyTimer > self.autoplayDelay then
			self.click = false
			self:switchKey(false)
		end
	end
end

NoteHandler.receiveEvent = function(self, event)
	local key = event.data and event.data[1]
	if self.keyBind and key == self.keyBind then
		if event.name == "love.keypressed" then
			if self.currentNote.pressSoundFilePath then
				self.engine.core.audioManager:playSound(self.currentNote.pressSoundFilePath)
			end
			
			self.currentNote.keyState = true
			return self:switchKey(true)
		elseif event.name == "love.keyreleased" then
			if self.currentNote.releaseSoundFilePath then
				self.engine.core.audioManager:playSound(self.currentNote.releaseSoundFilePath)
			end
			
			self.currentNote.keyState = false
			return self:switchKey(false)
		end
	end
end

NoteHandler.switchKey = function(self, state)
	self.keyState = state
	return self:sendState()
end

NoteHandler.clickKey = function(self)
	self.keyTimer = 0
	self.click = true
	self.keyState = true
	return self:sendState()
end

NoteHandler.sendState = function(self)
	return self.engine.observable:sendEvent({
		name = "noteHandlerUpdated",
		noteHandler = self
	})
end

NoteHandler.load = function(self)
	self:loadNoteData()
	self:setKeyState()
end