#!/usr/bin/env bash

# Detect init system
init=$(basename "$(ps -p 1 -o comm=)")

# Path to current wallpaper file
current_wallpaper_file="$HOME/.config/wayland/.current_wallpaper"

# Helper: build swaylock command dynamically
get_swaylock_cmd() {
    if [[ -f "$current_wallpaper_file" ]]; then
        local wp
        wp=$(cat "$current_wallpaper_file")
        echo "swaylock -i \"$wp\" --effect-blur 8x8"
    else
        echo "swaylock --effect-blur 10x10"
    fi
}

case "$init" in
systemd)
    poweroff="systemctl poweroff"
    reboot="systemctl reboot"
    suspend="loginctl suspend"
    hibernate="loginctl hibernate"
    logout="hyprctl dispatch exit"

    if command -v hyprlock >/dev/null 2>&1; then
        lock="hyprlock"
    elif command -v swaylock >/dev/null 2>&1; then
        lock=$(get_swaylock_cmd)
    else
        lock="loginctl lock-session"
    fi
    ;;
openrc | runit | sysvinit)
    poweroff="shutdown -h now"
    reboot="shutdown -r now"
    suspend="zzz"
    hibernate="ZZZ"
    logout="loginctl terminate-user $USER"

    if command -v swaylock >/dev/null 2>&1; then
        lock=$(get_swaylock_cmd)
    else
        lock="loginctl lock-session"
    fi
    ;;
rc | init | bsd*)
    poweroff="halt"
    reboot="reboot"
    suspend="zzz"
    hibernate="ZZZ"
    logout="loginctl terminate-user $USER"

    if command -v swaylock >/dev/null 2>&1; then
        lock=$(get_swaylock_cmd)
    else
        lock="lock"
    fi
    ;;
*)
    notify-send "Unknown init system: $init"
    exit 1
    ;;
esac

# Menu options with Nerd Font icons
options=" Lock\n Logout\n Suspend\n Hibernate\n Reboot\n Shutdown"

# Launch Rofi as dmenu with horizontal layout theme
choice=$(echo -e "$options" | rofi -dmenu -theme ~/.config/wayland/scripts/rofi-themes/power-menu.rasi -p "Power Menu")

# Match only the label (strip icon)
label=$(echo "$choice" | awk '{print $2}')

# Execute selected action
case "$label" in
Lock) eval "$lock" ;;
Logout) eval "$logout" ;;
Suspend) eval "$suspend" ;;
Hibernate) eval "$hibernate" ;;
Reboot) eval "$reboot" ;;
Shutdown) eval "$poweroff" ;;
*) exit 0 ;;
esac
