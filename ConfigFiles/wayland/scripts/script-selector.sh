#!/bin/bash
#
#    _____           _       __           
#   / ___/__________(_)___  / /_          
#   \__ \/ ___/ ___/ / __ \/ __/          
#  ___/ / /__/ /  / / /_/ / /_            
# /____/\___/_/ _/_/ .___/\__/            
#   / ___/___  / //_/ _____/ /_____  _____
#   \__ \/ _ \/ / _ \/ ___/ __/ __ \/ ___/
#  ___/ /  __/ /  __/ /__/ /_/ /_/ / /    
# /____/\___/_/\___/\___/\__/\____/_/     
#
# AUTHOR: MHD
#
# A rofi dmenu to select and run custom made scripts and apps
#

SCRIPTS_DIR="$HOME/.config/wayland/scripts"
THEME_PATH="$HOME/.config/wayland/scripts/rofi-themes/script-selector.rasi"

# Scripts to ignore (add script names here)
IGNORE_SCRIPTS=(
    "todo.py"
    "programmer-infos"
    "script-selector.sh"
    "minimize-toggle.sh"
    "rice-init"
    "rice-selector"
    "wallpaper-selector"
    "create_rice"
    "battery-animation.sh"
    "mpv-tui"
    "Updates"
    # Add more scripts to ignore here
)

# Check if scripts directory exists
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    rofi -e "Scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

# Check if theme file exists
if [[ ! -f "$THEME_PATH" ]]; then
    rofi -e "Theme file not found: $THEME_PATH"
    exit 1
fi

# Get list of all scripts (excluding ignored scripts and directories)
scripts=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f ! -name "*.rasi" -printf "%f\n" | sort)
for ignore in "${IGNORE_SCRIPTS[@]}"; do
    scripts=$(echo "$scripts" | grep -v "^$ignore$")
done

# Check if any scripts were found
if [[ -z "$scripts" ]]; then
    rofi -e "No scripts found in $SCRIPTS_DIR"
    exit 1
fi

# Create formatted list with executable indicators
formatted_scripts=""
while IFS= read -r script; do
    script_path="$SCRIPTS_DIR/$script"
    if [[ -x "$script_path" ]]; then
        formatted_scripts+="▶ $script\n"
    else
        formatted_scripts+="🐍 $script\n"
    fi
done <<<"$scripts"

# Show rofi menu and get user selection
selected=$(echo -e "$formatted_scripts" | rofi -dmenu -i -p "Select Script" -theme "$THEME_PATH")

# Process selection
if [[ -n "$selected" ]]; then
    # Remove the icon prefix to get the actual script name
    script_name=$(echo "$selected" | sed 's/^[▶🐍] //')
    script_path="$SCRIPTS_DIR/$script_name"

    if [[ -x "$script_path" ]]; then
        # Execute the script
        "$script_path" &
    elif [[ -f "$script_path" ]]; then
        # Try to determine how to run non-executable scripts
        if [[ "$script_name" == *.sh ]]; then
            bash "$script_path" &
        elif [[ "$script_name" == *.py ]]; then
            python3 "$script_path" &
        else
            rofi -e "Script is not executable. Please make it executable with: chmod +x $script_name"
        fi
    else
        rofi -e "Script not found: $script_name"
    fi
fi
