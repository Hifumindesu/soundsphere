local Note = require("ncdk2.notes.Note")
local Notes = require("ncdk2.notes.Notes")
local InputMode = require("ncdk.InputMode")
local Modifier = require("sphere.models.ModifierModel.Modifier")

---@class sphere.MultiOverPlay: sphere.Modifier
---@operator call: sphere.MultiOverPlay
local MultiOverPlay = Modifier + {}

MultiOverPlay.name = "MultiOverPlay"

MultiOverPlay.defaultValue = 2
MultiOverPlay.values = {2, 3, 4}

MultiOverPlay.description = "1 2 1 2 -> 12 34 12 34, doubles the input mode"

---@param config table
---@return string
---@return string
function MultiOverPlay:getString(config)
	return tostring(config.value), "OP"
end

---@param config table
---@param state table
function MultiOverPlay:applyMeta(config, state)
	local inputMode = state.inputMode

	local value = config.value
	for inputType, inputCount in pairs(inputMode) do
		inputMode[inputType] = inputCount * value
	end
end

---@param config table
---@param chart ncdk2.Chart
function MultiOverPlay:apply(config, chart)
	local value = config.value

	local inputMode = chart.inputMode

	local new_notes = Notes()
	for _, note in chart.notes:iter() do
		local inputType, inputIndex = InputMode:splitInput(note.column)
		local inputCount = inputMode[inputType]
		if inputCount then
			for i = 1, value do
				local newInputIndex = (inputIndex - 1) * value + i
				if note.startNote then
				elseif note.endNote then
					local startNote = Note(note.visualPoint, inputType .. newInputIndex)
					local endNote = Note(note.endNote.visualPoint, inputType .. newInputIndex)

					startNote.endNote = endNote
					endNote.startNote = startNote

					startNote.noteType = note.noteType
					startNote.sounds = note.sounds
					endNote.noteType = note.endNote.noteType
					endNote.sounds = note.endNote.sounds

					new_notes:insert(startNote)
					new_notes:insert(endNote)
				else
					local newNote = Note(note.visualPoint, inputType .. newInputIndex)
					newNote.noteType = note.noteType
					newNote.sounds = note.sounds
					new_notes:insert(newNote)
				end
			end
		else
			new_notes:insert(note)
		end
	end
	chart.notes = new_notes

	for inputType, inputCount in pairs(inputMode) do
		inputMode[inputType] = inputCount * value
	end

	chart:compute()
end

return MultiOverPlay
