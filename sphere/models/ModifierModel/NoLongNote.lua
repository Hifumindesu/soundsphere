local Modifier = require("sphere.models.ModifierModel.Modifier")

local NoLongNote = Modifier:new()

NoLongNote.type = "NoteChartModifier"
NoLongNote.interfaceType = "toggle"

NoLongNote.defaultValue = true
NoLongNote.name = "NoLongNote"
NoLongNote.shortName = "NLN"

NoLongNote.description = "Remove long notes"

NoLongNote.getString = function(self, config)
	if not config.value then
		return
	end
	return Modifier.getString(self)
end

NoLongNote.apply = function(self, config)
	if not config.value then
		return
	end

	local noteChart = self.noteChart

	for noteDatas in noteChart:getInputIterator() do
		for _, noteData in ipairs(noteDatas) do
			if noteData.noteType == "LongNoteStart" or noteData.noteType == "LaserNoteStart" then
				noteData.noteType = "ShortNote"
			elseif noteData.noteType == "LongNoteEnd" or noteData.noteType == "LaserNoteEnd" then
				noteData.noteType = "Ignore"
			end
		end
	end
end

return NoLongNote
