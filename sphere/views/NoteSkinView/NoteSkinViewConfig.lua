
local screen = {
	w = 1920,
	h = 1080
}

local NoteSkinList = {
	class = "NoteSkinListView",
	screen = screen,
	x = 733,
	y = 144,
	w = 454,
	h = 792,
	rows = 11,
	name = {
		x = 44,
		y = 16,
		w = 1920,
		h = 31,
		align = "left",
		fontSize = 24,
		fontFamily = "Noto Sans",
		addedColor = {1, 1, 1, 0.5}
	},
	point = {
		x = 22,
		y = 36,
		r = 7
	}
}

local NoteSkinScrollBar = {
	class = "ScrollBarView",
	screen = screen,
	list = NoteSkinList,
	x = 1187,
	y = 144,
	w = 16,
	h = 792,
	rows = 11,
	backgroundColor = {1, 1, 1, 0.33},
	color = {1, 1, 1, 0.66}
}

local Background = {
	class = "BackgroundView",
	screen = screen,
	x = 0,
	y = 0,
	w = 1920,
	h = 1080,
	parallax = 0.01,
	dim = 0.5
}

local Rectangle = {
	class = "RectangleView",
	screen = screen,
	rectangles = {
		{
			color = {1, 1, 1, 1},
			mode = "fill",
			lineStyle = "smooth",
			lineWidth = 1,
			x = 733,
			y = 504,
			w = 4,
			h = 72,
			rx = 0,
			ry = 0
		}
	}
}

local BottomScreenMenu = {
	class = "ScreenMenuView",
	screen = screen,
	x = 279,
	y = 991,
	w = 227,
	h = 89,
	rows = 1,
	columns = 1,
	text = {
		x = 0,
		y = 26,
		w = 227,
		h = 36,
		align = "center",
		fontSize = 24,
		fontFamily = "Noto Sans"
	},
	screens = {
		{
			{
				name = "Select",
				displayName = "back"
			}
		}
	}
}

local NoteSkinViewConfig = {
	Background,
	BottomScreenMenu,
	NoteSkinList,
	NoteSkinScrollBar,
	Rectangle
}

return NoteSkinViewConfig
