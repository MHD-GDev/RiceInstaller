--     __  __                 __                __
--    / / / /_  ______  _____/ /___ _____  ____/ /
--   / /_/ / / / / __ \/ ___/ / __ `/ __ \/ __  /
--  / __  / /_/ / /_/ / /  / / /_/ / / / / /_/ /
-- /_/ /_/\__, / .___/_/  /_/\__,_/_/ /_/\__,_/
--       /____/_/

---@module 'hl'

-- AUTHOR = MHD
-- WIKI = https://wiki.hyprland.org/Configuring

-- GPU for Hyprland rendering
-- env = AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1 

-- Custom exec-once here


-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("hypridle -c ~/.config/hypr/hypridle.conf > /dev/null 2>&1")
	hl.exec_cmd("mako > /dev/null 2>&1")
	hl.exec_cmd("~/.config/wayland/scripts/mako-logging > /dev/null 2>&1")
	hl.exec_cmd("/usr/libexec/polkit-gnome-authentication-agent-1 > /dev/null 2>&1")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP > /dev/null 2>&1")
	hl.exec_cmd("~/.config/wayland/scripts/rice-init > /dev/null 2>&1")
	hl.exec_cmd("fcitx5 > /dev/null 2>&1")
end)

-- Variables
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XCURSOR_SIZE", 28)

-- Variables for nvidia drivers
--hl.env("LIBVA_DRIVER_NAME","nvidia")
--hl.env("__GLX_VENDOR_LIBRARY_NAME","nvidia")
--hl.env("ELECTRON_OZONE_PLATFORM_HINT","auto")


-- Monitors (examples)
-- monitor = name, resolution, position, scale, transform (rotation), transfom(num)

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- styles
source = "~/.config/wayland/hypr/borders.lua"

hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = -1,
		vrr = 2,
	},
})

hl.config({
	debug = {
		vfr = true,
	},
})

hl.config({
	cursor = {
		sync_gsettings_theme = true,
		-- make all gtk themes work with gsettings
		no_break_fs_vrr = 2,
		-- 1= on, 2= auto, 0= off, helps with VRR in games
		min_refresh_rate = 24,
		-- min refresh rate for cursor movement for VRR in games
		inactive_timeout = 0,
		-- hide cursor when it's inactive (in seconds)
        
		-- default_monitor = "DP-1", -- Add your monitor
        
		-- the name of the monitor for cursor to show up at startup
		enable_hyprcursor = true,
		-- enables hyprcursor
		hide_on_key_press = true,
		-- hides the cursor when a key being pressed on keyboard
	},
})

hl.config({
	animations = {
		-- SET enabled = false if you want to disable animations.
		enabled = true,
	},
})

-- OpenGL
hl.config({
	opengl = {
		nvidia_anti_flicker = true,
	},
})

hl.config({
	input = {
		kb_layout = "us",
		repeat_rate = 30,
		repeat_delay = 200,
		touchpad = {
			natural_scroll = false,
			disable_while_typing = false,
			clickfinger_behavior = true,
			tap_to_click = true,
			drag_lock = false,
		},
	},
})

hl.config({
	decoration = {
		blur = {
			enabled = false,
			size = 8,
			passes = 2,
			-- More passes = smoother blur
			vibrancy = 0.15,
			-- Adds a subtle glow (optional)
			ignore_opacity = true,
		},
		-- Shadow settings 
		shadow = {
			enabled = true,
			range = 10,
			render_power = 4,
			color = "rgba(1a1a1aee)",
			offset = "4 4",
		},
	},
})

-- Rendering
hl.config({
	render = {
		direct_scanout = 2,
		-- if your game is in fullscreen this can help you, you can also put it at 2 to make it auto for detecting games and stuff
	},
})


--     __ __           __    _           ___
--    / //_/__  __  __/ /_  (_)___  ____/ (_)___  ____ ______
--   / ,< / _ \/ / / / __ \/ / __ \/ __  / / __ \/ __ `/ ___/
--  / /| /  __/ /_/ / /_/ / / / / / /_/ / / / / / / /_/ (__  )
-- /_/ |_\___/\__, /_.___/_/_/ /_/\__,_/_/_/ /_/\__, /____/
--           /____/                            /____/

--###########################
-- ----- Applications ----- #
--###########################

-- ----- Cheatsheet ----- #
hl.bind("SUPER + ALT + c", hl.dsp.exec_cmd("~/.config/wayland/scripts/cheatsheet"))

-- ----- Main Apps ----- #

-- Terminal
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty --config ~/.config/wayland/kitty/kitty.conf"))

-- Rofi menu
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/wayland/scripts/rofi-themes/dmenu.rasi"))

-- Rice Selector
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("~/.config/wayland/scripts/rice-selector"))

-- Wallpaper Selector
hl.bind("SUPER + ALT + w", hl.dsp.exec_cmd("~/.config/wayland/scripts/wallpaper-selector"))

-- Script Selector
hl.bind("SUPER + ALT + a", hl.dsp.exec_cmd("~/.config/wayland/scripts/script-selector"))

-- ----- Common Apps ----- #

-- Browser
hl.bind("SHIFT + ALT + b", hl.dsp.exec_cmd("portable-firefox-launcher"))

-- AI Websites
hl.bind("SHIFT + ALT + i", hl.dsp.exec_cmd("~/.config/wayland/scripts/web-ai-selector"))

-- Telegram App
hl.bind("SHIFT + ALT + t", hl.dsp.exec_cmd("Telegram"))

-- Nvim
hl.bind("SHIFT + ALT + v", hl.dsp.exec_cmd("kitty -c ~/.config/wayland/kitty/kitty.conf -e nvim"))

-- Random Wallpaper
hl.bind("SUPER + ALT + q", hl.dsp.exec_cmd("~/.config/wayland/scripts/random-wallpaper toggle"))

-- Color Picker
hl.bind(
	"SUPER + ALT + p",
	hl.dsp.exec_cmd("hyprpicker -a -l | awk '{print $1}' | xargs -I {} sh -c 'notify-send \"Color: {}\"'")
)

-- ----- System Utilities ----- #

-- Screenshot with slurp
hl.bind(
	"SUPER + ALT + s",
	hl.dsp.exec_cmd(
		'grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M).png && wl-copy < ~/Pictures/screenshot_$(date +%Y%m%d_%H%M).png && notify-send "Screenshot" "Screenshot saved"'
	)
)

-- Toggle Waybar
hl.bind("SUPER + b", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- Brightness controls (using Brightnessctl)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(
		'brightnessctl set 5%- && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:brightness "Brightness" "$(($(brightnessctl get) * 100 / $(brightnessctl max)))%" -h int:value:"$(($(brightnessctl get) * 100 / $(brightnessctl max)))"'
	)
)

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(
		'brightnessctl set 5%+ && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:brightness "Brightness" "$(($(brightnessctl get) * 100 / $(brightnessctl max)))%" -h int:value:"$(($(brightnessctl get) * 100 / $(brightnessctl max)))"'
	)
)

-- Volume controls (install pipewire/wireplumber)

-- binde = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')%" -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')"

hl.bind(
	"CTRL + SUPER + equal",
	hl.dsp.exec_cmd(
		'wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk \'{print $2 * 100}\')%" -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk \'{print $2 * 100}\')"'
	)
)

-- binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')%" -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')"

hl.bind(
	"CTRL + SUPER + minus",
	hl.dsp.exec_cmd(
		'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk \'{print $2 * 100}\')%" -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk \'{print $2 * 100}\')"'
	)
)

-- bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && (wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "Muted" -h int:value:0 || notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "Unmuted" -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')")

hl.bind(
	"CTRL + SUPER + 0",
	hl.dsp.exec_cmd(
		'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && (wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "Muted" -h int:value:0 || notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:volume "Volume" "Unmuted" -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk \'{print $2 * 100}\')")'
	)
)

-- keyboard backlight
hl.bind(
	"XF86KbdBrightnessDown",
	hl.dsp.exec_cmd(
		'brightnessctl -d asus::kbd_backlight set 5%- && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:kbdlight "Keyboard Backlight" "$(($(brightnessctl -d asus::kbd_backlight get) * 100 / $(brightnessctl -d asus::kbd_backlight max)))%" -h int:value:"$(($(brightnessctl -d asus::kbd_backlight get) * 100 / $(brightnessctl -d asus::kbd_backlight max)))"'
	)
)

hl.bind(
	"XF86KbdBrightnessUp",
	hl.dsp.exec_cmd(
		'brightnessctl -d asus::kbd_backlight set 5%+ && notify-send -c ~/.config/wayland/mako/config.ini -h string:x-canonical-private-synchronous:kbdlight "Keyboard Backlight" "$(($(brightnessctl -d asus::kbd_backlight get) * 100 / $(brightnessctl -d asus::kbd_backlight max)))%" -h int:value:"$(($(brightnessctl -d asus::kbd_backlight get) * 100 / $(brightnessctl -d asus::kbd_backlight max)))"'
	)
)

--################################
-- ----- Window Management ----- #
--################################

-- Close/Kill window
hl.bind("SUPER + q", hl.dsp.window.close())

-- Reload Hyprland
hl.bind(
	"SUPER + ALT + r",
	hl.dsp.exec_cmd(
		'hyprctl reload && ~/.config/wayland/scripts/rice-selector init && notify-send -c ~/.config/wayland/mako/config.ini "Hyprland" "Configuration reloaded"'
	)
)

-- Window states
hl.bind(
	"SUPER + t",
	function()
		local win = hl.get_active_window()
		local will_float = win and not win.floating
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		if will_float then
			local mon = (win and win.monitor) or hl.get_active_monitor()
			if mon then
				hl.dispatch(hl.dsp.window.resize({ x = math.floor(mon.width / 2), y = math.floor(mon.height / 2) }))
				hl.dispatch(hl.dsp.window.center())
			end
		end
	end
)

-- Window Fullscreen
hl.bind("SUPER + f", hl.dsp.window.fullscreen())

-- Focus movement
hl.bind("SUPER + h", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + l", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + k", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + j", hl.dsp.focus({ direction = "down" }))

-- Move window
hl.bind("SUPER + SHIFT + h", hl.dsp.window.swap({ direction = "left" }))
hl.bind("SUPER + SHIFT + l", hl.dsp.window.swap({ direction = "right" }))
hl.bind("SUPER + SHIFT + k", hl.dsp.window.swap({ direction = "up" }))
hl.bind("SUPER + SHIFT + j", hl.dsp.window.swap({ direction = "down" }))

-- Workspace navigation
hl.bind("SUPER + CTRL + h", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + l", hl.dsp.focus({ workspace = "r+1" }))

-- Move Node to workspace
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))

-- Move Node to workspace manually
hl.bind("SUPER + SHIFT + CTRL + h", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + SHIFT + CTRL + l", hl.dsp.window.move({ workspace = "r+1" }))

-- Switch workspace
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = 6 }))

-- Last window/workspace
hl.bind("SUPER + grave", hl.dsp.focus({ last = true }))

-- Resize windows
hl.bind("SUPER + ALT + h", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + ALT + l", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + ALT + k", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
hl.bind("SUPER + ALT + j", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

-- Changes the transparency of the current window
hl.bind(
	"CTRL + ALT + equal",
	function()
		hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 1.0 } })
	end
)

hl.bind(
	"CTRL + ALT + minus",
	function()
		hl.config({ decoration = { active_opacity = 0.85, inactive_opacity = 0.85 } })
	end
)

-- Moving Floating Windows
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Toggle minimize/restore current window
hl.bind("CTRL + ALT + h", hl.dsp.exec_cmd("~/.config/wayland/scripts/minimize-toggle"))

-- Toggle blur
hl.bind("CTRL + ALT + 0", function()
	hl.config({ decoration = { blur = { enabled = not hl.get_config("decoration.blur.enabled") } } })
end)

-- Keyboard Language menu
hl.bind("SUPER + ALT + space", hl.dsp.exec_cmd("~/.config/wayland/scripts/keyboard-layout"))

-- Workspace assignments

-- workspace = 1, monitor:DP-1, default:true
-- workspace = 2, monitor:DP-1
-- workspace = 3, monitor:DP-1
-- workspace = 4, monitor:DP-1
-- workspace = 5, monitor:DP-1
-- workspace = 6, monitor:eDP-1, default:true
-- workspace = 7, monitor:DP-1
-- workspace = 8, monitor:DP-1
-- workspace = 9, monitor:DP-1
-- workspace = 10, monitor:DP-1

-- es-de big picture (steamdeck-button R2) (steamdeck related)
hl.bind("code:122", hl.dsp.exec_cmd("/bin/ES-DE_x64_SteamDeck.AppImage"))

hl.bind("code:123", hl.dsp.exec_cmd("hyprctl -j clients| jq -r '.[].pid'| xargs kill -9"))


--     _____           _       __
--   / ___/__________(_)___  / /______
--   \__ \/ ___/ ___/ / __ \/ __/ ___/
--  ___/ / /__/ /  / / /_/ / /_(__  )
-- /____/\___/_/  /_/ .___/\__/____/
--                 /_/
-- Custom Scripts here

-- Glass Magnifier Zoom
local MAX_ZOOM = 3
local MIN_ZOOM = 1
local ZOOM_TOGGLE_FACTOR = 5

---@param offset number
---@return nil
local function zoom(offset)
    local current = hl.get_config("cursor.zoom_factor")
    if offset ~= nil then
        current = current + offset
    elseif current ~= MIN_ZOOM then
        current = MIN_ZOOM
    else
        current = ZOOM_TOGGLE_FACTOR
    end
    current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
    hl.config({ cursor = { zoom_factor = current } })
end

hl.bind("SUPER + Z", zoom)
hl.bind("SUPER + KP_ADD", function()
    zoom(0.5)
end)

