local Modifier = require("sphere.models.ModifierModel.Modifier")
local InputMode = require("ncdk.InputMode")
local Notes = require("ncdk2.notes.Notes")

---@class sphere.Taiko: sphere.Modifier
---@operator call: sphere.Taiko
local Taiko = Modifier + {}

Taiko.name = "Taiko"
Taiko.shortName = "TK"

Taiko.description = "Converts mania 4K to taiko 2K (experimental)"

function Taiko:applyMeta(config, state)
	if state.inputMode.key ~= 4 then
		return
	end
	state.inputMode.key = 2
end

local function getKey(i)
	if i == 1 or i == 4 then
		return 2
	end
	return 1
end

---@param config table
---@param chart ncdk2.Chart
function Taiko:apply(config, chart)
	local inputMode = chart.inputMode

	if tostring(inputMode) ~= "4key" then
		return
	end

	local new_notes = Notes()
	for _, note in chart.notes:iter() do
		local inputType, inputIndex = InputMode:splitInput(note.column)
		if inputType == "key" then
			if note.noteType == "ShortNote" or note.noteType == "LongNoteStart" then
				note.noteType = "ShortNote"
				note.endNote = nil
				note.column = "key" .. getKey(inputIndex)
				local found_note = new_notes:get(note.visualPoint, note.column)
				if not found_note then
					new_notes:insert(note)
				else
					found_note.isDouble = true
				end
			end
		else
			new_notes:insert(note)
		end
	end
	chart.notes = new_notes

	inputMode.key = 2

	chart:compute()
end

return Taiko
