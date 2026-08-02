local config = {}

-- Variables
config.vars = {
	img = os.getenv("HOME") .. "/.config/hypr/hyprlock/assets",
	widget = os.getenv("HOME") .. "/.config/hypr/hyprlock",

	colors = {
		background = "rgba(0,0,0,0)",
		foreground = "rgba(255,255,255,1.0)",
		foreground_alt = "rgba(255,255,255,0.3)",
		fail = "rgba(221,8,8,0.8)",
	},

	fonts = {
		main = "Meslo LG M",
		alt = "Meslo LG M",
		jp = "NotoSansCJK-VF Bold",
	},
}

config.general = {
	disable_loading_bar = true,
	hide_cursor = true,
	ignore_empty_input = true,
	immediate_render = true,
}

config.background = {
	monitor = "",
	path = "/home/mhd/.config/wayland/rices/FrutigerAero/walls/tropical_underwater.png",
	blur_passes = 2,
	blur_size = 5,
	contrast = 0.8916,
	brightness = 0.8172,
	vibrancy = 0.1696,
	vibrancy_darkness = 0.0,
}

config.elements = {

	{
		type = "shape",
		size = { 1300, 2 },
		color = "$foreground",
		rounding = -1,
		position = { 0, 270 },
		halign = "center",
		valign = "center",
	},

	{
		type = "image",
		path = "$img/arrow.png",
		size = 30,
		position = { 150, 100 },
		halign = "left",
		valign = "bottom",
	},

	{
		type = "image",
		path = "$img/star-circle.png",
		size = 53,
		position = { 14, -220 },
		halign = "left",
		valign = "center",
	},

	{
		type = "image",
		path = "$img/logo.png",
		size = 50,
		position = { 0, 40 },
		halign = "center",
		valign = "bottom",
		zindex = -1,
	},

	{
		type = "image",
		path = "$img/smiley.png",
		size = 27,
		position = { 29, 55 },
		halign = "left",
		valign = "center",
		zindex = 1,
	},

	{
		type = "image",
		path = "$img/globe.png",
		size = 23,
		position = { 31, 85 },
		halign = "left",
		valign = "center",
	},

	{
		type = "shape",
		size = { 140, 1 },
		color = "$foreground",
		rounding = -1,
		position = { 150, 51 },
		halign = "left",
		valign = "bottom",
	},

	{
		type = "shape",
		size = { 140, 1 },
		color = "$foreground",
		rounding = -1,
		position = { 150, 26 },
		halign = "left",
		valign = "bottom",
	},

	{
		type = "shape",
		size = { 60, 32 },
		color = "$background",
		border_color = "$foreground",
		border_size = 1,
		rounding = -1,
		position = { -35, -22 },
		halign = "right",
		valign = "top",
	},
}

config.labels = {

	{
		text = 'cmd[update:1000] echo "<b><big> $(date +\\"%I\\") </big></b>"',
		font = "$main",
		size = 80,
		color = "$foreground",
		position = { 7, -22 },
		halign = "left",
		valign = "top",
	},

	{
		text = 'cmd[update:1000] echo "<b><big> $(date +\\"%M\\") </big></b>"',
		font = "$main",
		size = 80,
		color = "$foreground",
		position = { 7, -123 },
		halign = "left",
		valign = "top",
	},

	{
		text = 'cmd[update:1000] echo "$(date +\\"%a %B %d\\")"',
		font = "$main",
		size = 50,
		color = "$foreground",
		rotate = 90,
		position = { -20, -125 },
		halign = "right",
		valign = "top",
	},

	{
		text = "MHD",
		font = "$alt",
		size = 14,
		color = "$foreground",
		position = { -950, 52 },
		halign = "right",
		valign = "bottom",
	},

	{
		text = "WAKE",
		font = "$alt",
		size = 10,
		color = "$foreground",
		position = { 200, 252 },
		halign = "left",
		valign = "center",
	},

	{
		text = "UP",
		font = "$alt",
		size = 10,
		color = "$foreground",
		position = { 0, 252 },
		halign = "center",
		valign = "center",
	},

	{
		text = "SAMURAI",
		font = "$alt",
		size = 10,
		color = "$foreground",
		position = { -200, 252 },
		halign = "right",
		valign = "center",
	},

	{
		text = "NEOHYPER",
		font = "$alt",
		size = 9,
		color = "$foreground",
		position = { -35, 25 },
		halign = "right",
		valign = "bottom",
	},

	{
		text = "キッコウエイメイ",
		font = "$jp",
		size = 16,
		color = "$foreground",
		position = { 0, 250 },
		halign = "center",
		valign = "bottom",
	},

	{
		text = "Nothing is impossible. The word itself says 'I'm possible'",
		font = "Meslo LG M",
		size = 8,
		color = "$foreground",
		position = { 0, 130 },
		halign = "center",
		valign = "bottom",
	},

	{
		text = "Some people want it to happen, some wish it would happen, others make it happen.",
		font = "Meslo LG M",
		size = 8,
		color = "$foreground",
		position = { 0, 115 },
		halign = "center",
		valign = "bottom",
	},
}

config.avatar = {
	path = "$img/yoshimitsu.webp",
	size = 110,
	rounding = 6,
	border_color = "$foreground_alt",
	border_size = 0,
	position = { 30, 25 },
	halign = "left",
	valign = "bottom",
}

config.input = {
	size = { 80, 25 },
	rounding = 3,
	outline_thickness = 0,

	inner_color = "$background",
	outer_color = "$background",
	check_color = "$background",

	dots_size = 4,
	dots_spacing = 0.3,
	dots_center = true,
	dots_rounding = -1,

	font_family = "$alt",
	font_color = "$foreground",

	placeholder_text = "PASSWORD",
	fail_text = "WRONG PASSWORD <b>($ATTEMPTS)</b>",

	position = { -928, 21 },
	halign = "right",
	valign = "bottom",
}

return config
