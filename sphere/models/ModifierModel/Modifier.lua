local class = require("class")
local round = require("math_util").round
local table_util = require("table_util")

---@class sphere.Modifier
---@operator call: sphere.Modifier
local Modifier = class()

---@return table
function Modifier:getDefaultConfig()
	return {
		name = self.name,
		version = self.version,
		value = self.defaultValue
	}
end

Modifier.version = 0
Modifier.name = ""
Modifier.format = "%d"
Modifier.defaultValue = 0

---@param config table
---@return string
function Modifier:encode(config)
	local version = config.version or 0
	return ("%d,%s"):format(version, config.value)
end

---@param configData string
---@return table
function Modifier:decode(configData)
	local config = self:getDefaultConfig()
	local version, value = configData:match("^(%d+),(.+)$")
	config.version = tonumber(version)
	config.value = self:decodeValue(value)
	return config
end

---@param s string
---@return string|boolean|number
function Modifier:decodeValue(s)
	if type(self.defaultValue) == "boolean" then
		return s == "true"
	elseif type(self.defaultValue) == "number" then
		return tonumber(s) or 0
	end
	return s
end

---@param config table
---@return any
function Modifier:getValue(config)
	return config.value
end

---@param value any
---@return number
function Modifier:toNormValue(value)
	local index = table_util.indexof(self.values, value)
	return (index - 1) / (#self.values - 1)
end

---@param normValue number
---@return any
function Modifier:fromNormValue(normValue)
	normValue = math.min(math.max(normValue, 0), 1)
	local index = 1 + round(normValue * (#self.values - 1), 1)
	return self.values[index]
end

---@param value any
---@return number
function Modifier:toIndexValue(value)
	return table_util.indexof(self.values, value) or 1
end

---@param indexValue number
---@return any
function Modifier:fromIndexValue(indexValue)
	indexValue = math.min(math.max(indexValue, 1), #self.values)
	return self.values[indexValue]
end

---@return number
function Modifier:getCount()
	return #self.values
end

---@param config table
---@param value any
function Modifier:setValue(config, value)
	config.value = value
end

---@param modifierConfig table
---@param state table
function Modifier:applyMeta(modifierConfig, state) end

---@param modifierConfig table
function Modifier:apply(modifierConfig) end

---@param config table
---@return string
---@return string?
function Modifier:getString(config)
	return self.shortName or self.name
end

return Modifier
