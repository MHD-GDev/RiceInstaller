#!/usr/bin/env bash

# Detect init system
init=$(basename "$(ps -p 1 -o comm=)")
case "$init" in
    systemd)
        poweroff="systemctl poweroff"
        reboot="systemctl reboot"
        suspend="loginctl suspend"
        hibernate="loginctl hibernate"
        logout="hyprctl dispatch exit"
        lock=$(command -v hyprlock || command -v swaylock || echo "loginctl lock-session")
        ;;
    openrc | runit | sysvinit)
        poweroff="shutdown -h now"
        reboot="shutdown -r now"
        suspend="zzz"
        hibernate="ZZZ"
        logout="loginctl terminate-user $USER"
        lock="loginctl lock-session"
        ;;
    rc | init | bsd*)
        poweroff="halt"
        reboot="reboot"
        suspend="zzz"
        hibernate="ZZZ"
        logout="loginctl terminate-user $USER"
        lock="lock"
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
    Lock)      eval "$lock" ;;
    Logout)    eval "$logout" ;;
    Suspend)   eval "$suspend" ;;
    Hibernate) eval "$hibernate" ;;
    Reboot)    eval "$reboot" ;;
    Shutdown)  eval "$poweroff" ;;
    *) exit 0 ;;
esac

