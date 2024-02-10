local just = require("just")
local imgui = require("imgui")
local ModalImView = require("sphere.imviews.ModalImView")
local _transform = require("gfx_util").transform
local spherefonts = require("sphere.assets.fonts")
local theme = require("imgui.theme")

local transform = {{1 / 2, -16 / 9 / 2}, 0, 0, {0, 1 / 1080}, {0, 1 / 1080}, 0, 0, 0, 0}

local scrollY = 0
local scrollYlist = 0

local w, h = 1024, 1080 / 2
local _w, _h = w / 2, 55
local r = 8
local window_id = "MountsView"
local selected_cfl
local location_info

local sections = {
	"locations",
	"metadata",
}
local section = sections[1]

local section_draw = {}

local function get_cache_text(self)
	local cacheModel = self.game.cacheModel
	local shared = cacheModel.shared
	local state = shared.state

	local text = ""
	if state == 1 then
		text = ("searching for charts: %d"):format(shared.noteChartCount)
	elseif state == 2 then
		text = ("creating cache: %0.2f%%"):format(shared.cachePercent)
	elseif state == 3 then
		text = "complete"
	elseif state == 0 then
		text = "update"
	end

	return text
end

local function get_location_info(self, location_id)
	local chartRepo = self.game.cacheModel.chartRepo

	return {
		chartfile_sets = chartRepo:countChartfileSets({location_id = location_id}),
		chartfiles = chartRepo:countChartfiles({location_id = location_id}),
		hashed_chartfiles = chartRepo:countChartfiles({
			location_id = location_id,
			hash__isnotnull = true,
		}),
	}
end

local modal = ModalImView(function(self)
	if not self then
		return true
	end

	imgui.setSize(w, h, w, _h)

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))

	love.graphics.replaceTransform(_transform(transform))
	love.graphics.translate((1920 - w) / 2, (1080 - h) / 2)

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, w, h, r)
	love.graphics.setColor(1, 1, 1, 1)

	just.push()
	imgui.Container(window_id, w, h, _h / 3, _h * 2, scrollY)

	just.push()
	local tabsw
	section, tabsw = imgui.vtabs("settings tabs", section, sections)
	just.pop()

	local inner_w = w - tabsw
	imgui.setSize(inner_w, h, inner_w / 2, _h)
	love.graphics.translate(tabsw, 0)

	love.graphics.setColor(1, 1, 1, 1)
	section_draw[section](self, inner_w)
	just.emptyline(8)

	scrollY = imgui.Container()
	just.pop()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", 0, 0, w, h, r)
end)

function section_draw.locations(self, inner_w)
	local mountModel = self.game.mountModel
	local cf_locations = mountModel.cf_locations

	local list_w = inner_w / 3

	just.push()
	imgui.List("mount points", list_w, h, _h / 2, _h, scrollYlist)
	for i, item in ipairs(cf_locations) do
		local cf_location = item.name
		if selected_cfl == item then
			cf_location = "> " .. cf_location
		end
		if imgui.TextOnlyButton("mount item" .. i, cf_location, w, _h * theme.size, "left") or not selected_cfl then
			selected_cfl = item
			location_info = get_location_info(self, item.id)
		end
	end
	scrollYlist = imgui.List()
	just.pop()

	love.graphics.translate(list_w, 0)

	if not selected_cfl then
		return
	end

	local path = selected_cfl.path
	just.indent(8)
	just.text("Status: " .. (mountModel.status[path] or "unknown"))
	just.indent(8)
	just.text("Real path: ")
	just.indent(8)
	imgui.url("open dir", path, path)
	-- just.sameline()
	-- if imgui.TextButton("remove dir", "Remove", 200, _h) then
	-- 	for i = 1, #items do
	-- 		if items[i] == selectedItem then
	-- 			table.remove(items, i)
	-- 			selectedItem = nil
	-- 			break
	-- 		end
	-- 	end
	-- end

	local cache_text = get_cache_text(self)
	if imgui.button("cache_button", cache_text) then
		self.game.selectController:updateCacheLocation(selected_cfl.id)
	end

	imgui.text("chartfile_sets: " .. location_info.chartfile_sets)
	imgui.text(("chartfiles: %s/%s"):format(
		location_info.hashed_chartfiles,
		location_info.chartfiles
	))
end

function section_draw.metadata(self)
	local cacheStatus = self.game.cacheModel.cacheStatus
	imgui.text("chartmetas: " .. cacheStatus.chartmetas)
	imgui.text("chartdiffs: " .. cacheStatus.chartdiffs)
	if imgui.button("cacheStatus update", "update") then
		cacheStatus:update()
	end
end

return modal
