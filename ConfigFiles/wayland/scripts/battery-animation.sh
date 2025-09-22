#!/bin/bash

# Get battery info
BATTERY_PATH="/sys/class/power_supply/BAT0"
CAPACITY=$(cat "$BATTERY_PATH/capacity")
STATUS=$(cat "$BATTERY_PATH/status")

# Animation frames for charging (like Polybar)
CHARGING_FRAMES=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝")
DISCHARGING_ICONS=("󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

# Get current second to determine animation frame
CURRENT_SECOND=$(date +%S)
FRAME_INDEX=$((CURRENT_SECOND % 5))

if [ "$STATUS" = "Charging" ]; then
    ICON="${CHARGING_FRAMES[$FRAME_INDEX]}"
    echo "{\"text\": \"$ICON $CAPACITY%\", \"class\": \"charging\", \"percentage\": $CAPACITY}"
elif [ "$STATUS" = "Full" ]; then
    echo "{\"text\": \"󰁹 $CAPACITY%\", \"class\": \"full\", \"percentage\": $CAPACITY}"
else
    # Calculate icon based on capacity for discharging
    ICON_INDEX=$((CAPACITY / 10))
    if [ $ICON_INDEX -gt 9 ]; then
        ICON_INDEX=9
    fi
    ICON="${DISCHARGING_ICONS[$ICON_INDEX]}"
    
    if [ $CAPACITY -le 15 ]; then
        echo "{\"text\": \"$ICON $CAPACITY%\", \"class\": \"critical\", \"percentage\": $CAPACITY}"
    elif [ $CAPACITY -le 30 ]; then
        echo "{\"text\": \"$ICON $CAPACITY%\", \"class\": \"warning\", \"percentage\": $CAPACITY}"
    else
        echo "{\"text\": \"$ICON $CAPACITY%\", \"class\": \"normal\", \"percentage\": $CAPACITY}"
    fi
fi
