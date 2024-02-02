local chartdiffs = require("sphere.persistence.CacheModel.models.chartdiffs")

local scores = {}

scores.table_name = "scores"

scores.types = {
	is_top = "boolean",
	const = "boolean",
	single = "boolean",
	modifiers = chartdiffs.types.modifiers,
}

scores.relations = {}

return scores
