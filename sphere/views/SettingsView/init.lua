local viewspackage = (...):match("^(.-%.views%.)")

local ScreenView = require(viewspackage .. "ScreenView")

local SettingsViewConfig = require(viewspackage .. "SettingsView.SettingsViewConfig")
local SettingsNavigator = require(viewspackage .. "SettingsView.SettingsNavigator")
local SettingsListView = require(viewspackage .. "SettingsView.SettingsListView")
local SectionsListView = require(viewspackage .. "SettingsView.SectionsListView")

local SettingsView = ScreenView:new({construct = false})

SettingsView.construct = function(self)
	ScreenView.construct(self)
	self.viewConfig = SettingsViewConfig
	self.navigator = SettingsNavigator:new()
	self.settingsListView = SettingsListView:new()
	self.sectionsListView = SectionsListView:new()
end

SettingsView.load = function(self)
	local navigator = self.navigator
	local sectionsListView = self.sectionsListView
	local settingsListView = self.settingsListView
	local configSettings = self.configModel:getConfig("settings")

	navigator.config = configSettings
	navigator.settingsModel = self.settingsModel
	navigator.view = self

	sectionsListView.navigator = navigator
	sectionsListView.configSettings = configSettings
	sectionsListView.settingsModel = self.settingsModel

	settingsListView.navigator = navigator
	settingsListView.configSettings = configSettings
	settingsListView.settingsModel = self.settingsModel

	self.backgroundView.settings = configSettings
	self.gaussianBlurView.settings = configSettings

	local sequenceView = self.sequenceView
	sequenceView:setView("SectionsListView", sectionsListView)
	sequenceView:setView("SettingsListView", settingsListView)

	ScreenView.load(self)
end

return SettingsView
