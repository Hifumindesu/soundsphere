local icons = {}

local path = "resources/icons/"

icons.arrow_downward = path .. "ic_arrow_downward_white_48dp.png"
icons.arrow_forward = path .. "ic_arrow_forward_white_48dp.png"
icons.arrow_upward = path .. "ic_arrow_upward_white_48dp.png"
icons.autorenew = path .. "ic_autorenew_white_48dp.png"
icons.block = path .. "ic_block_white_48dp.png"
icons.check_box_outline_blank = path .. "ic_check_box_outline_blank_white_24dp.png"
icons.check_box = path .. "ic_check_box_white_24dp.png"
icons.clear = path .. "ic_clear_white_48dp.png"
icons.create_new_folder = path .. "ic_create_new_folder_white_48dp.png"
icons.create = path .. "ic_create_white_48dp.png"
icons.done = path .. "ic_done_white_48dp.png"
icons.folder_open = path .. "ic_folder_open_white_48dp.png"
icons.fullscreen_exit = path .. "ic_fullscreen_exit_white_48dp.png"
icons.fullscreen = path .. "ic_fullscreen_white_48dp.png"
icons.home = path .. "ic_home_white_48dp.png"
icons.indeterminate_check_box = path .. "ic_indeterminate_check_box_white_24dp.png"
icons.info_outline = path .. "ic_info_outline_white_48dp.png"
icons.keyboard_arrow_down = path .. "ic_keyboard_arrow_down_white_48dp.png"
icons.keyboard_arrow_left = path .. "ic_keyboard_arrow_left_white_48dp.png"
icons.keyboard_arrow_right = path .. "ic_keyboard_arrow_right_white_48dp.png"
icons.keyboard_arrow_up = path .. "ic_keyboard_arrow_up_white_48dp.png"
icons.menu = path .. "ic_menu_white_48dp.png"
icons.more_horiz = path .. "ic_more_horiz_white_48dp.png"
icons.more_vert = path .. "ic_more_vert_white_48dp.png"
icons.radio_button_checked = path .. "ic_radio_button_checked_white_24dp.png"
icons.radio_button_unchecked = path .. "ic_radio_button_unchecked_white_24dp.png"
icons.refresh = path .. "ic_refresh_white_48dp.png"
icons.remove = path .. "ic_remove_white_48dp.png"
icons.settings = path .. "ic_settings_white_48dp.png"
icons.star_border = path .. "ic_star_border_white_48dp.png"
icons.star_half = path .. "ic_star_half_white_48dp.png"
icons.star = path .. "ic_star_white_48dp.png"
icons.add = path .. "ic_add_white_48dp.png"
icons.apps = path .. "ic_apps_white_48dp.png"
icons.arrow_back = path .. "ic_arrow_back_white_48dp.png"

local images = {}
setmetatable(icons, {__call = function(t, name)
	if not images[name] then
		images[name] = love.graphics.newImage(icons[name])
	end
	return images[name]
end})

return icons
