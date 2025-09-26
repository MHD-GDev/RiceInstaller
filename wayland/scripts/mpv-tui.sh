#!/bin/bash

# TUI interface for mpv

# Color definitions using tput for terminal compatibility
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly DIM=$(tput dim)
readonly RESET=$(tput sgr0)

# Unicode characters for better visual appeal
readonly PLAY_ICON="▶"
readonly PAUSE_ICON="⏸"
readonly STOP_ICON="⏹"
readonly MUSIC_ICON="♪"
readonly VIDEO_ICON="🎬"
readonly FOLDER_ICON="📁"

# Terminal dimensions
TERM_WIDTH=$(tput cols)
TERM_HEIGHT=$(tput lines)

# Function to draw a horizontal line
draw_line() {
    local char="${1:--}"
    local width="${2:-$TERM_WIDTH}"
    printf "%*s\n" "$width" | tr ' ' "$char"
}

# Function to center text
center_text() {
    local text="$1"
    local width="${2:-$TERM_WIDTH}"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" "$padding" "" "$text"
}

# Function to create a box around text
draw_box() {
    local text="$1"
    local color="${2:-$MAGENTA}"
    local text_length=${#text}
    local box_width=$((text_length + 4))
    local padding=$(( (TERM_WIDTH/2 - box_width) / 2 ))
    
    printf "%*s" "$padding" ""
    echo "${color}╭$(printf '%*s' $((box_width-2)) | tr ' ' '-')╮${RESET}"
    printf "%*s" "$padding" ""
    echo "${color}│${RESET} ${BOLD}$text${RESET} ${color}│${RESET}"
    printf "%*s" "$padding" ""
    echo "${color}╰$(printf '%*s' $((box_width-2)) | tr ' ' '-')╯${RESET}"
}

# Function to display the header
show_header() {
    clear
    echo "${BOLD}${YELLOW}"
    center_text "╔══════════════════════════════════════╗"
    center_text "║           MPV TUI Player             ║"
    center_text "╚══════════════════════════════════════╝"
    echo "${RESET}"
    echo
}

# Function to show file browser
show_file_browser() {
    local current_dir="$HOME/Downloads/Telegram Desktop"
    show_header
    
    center_text "$(draw_line "-" $(($TERM_WIDTH/2)))"
    
    echo
    center_text "${BOLD}${BLUE}Media Files:${RESET}"
    echo
    
    # List media files with numbers
    declare -a media_files
    while IFS= read -r file; do
        media_files+=("$file")
    done < <(find "$current_dir" -maxdepth 1 -type f \( \
        -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o \
        -iname "*.ogg" -o -iname "*.m4a" \) 2>/dev/null)
    
    for i in "${!media_files[@]}"; do
        local file="${media_files[$i]}"
        local basename_file=$(basename "$file")
        center_text "  ${BLUE}[$((i+1))]${RESET} ${MUSIC_ICON} $basename_file" $(($TERM_WIDTH/2))
    done    
    echo
    center_text "$(draw_line "-" $(($TERM_WIDTH/2)))"
    
    # Store media files array globally
    MEDIA_FILES=("${media_files[@]}")
}
# Function to show playback controls
show_controls() {
    echo
    echo "${BOLD}${MAGENTA}Controls:${RESET}"
    echo "  ${BLUE}Space${RESET}     - Play/Pause"
    echo "  ${BLUE}q${RESET}         - Quit"
    echo "  ${BLUE}←/→${RESET}       - Seek -/+ 10s"
    echo "  ${BLUE}m${RESET}         - Mute"
    echo "  ${BLUE}L${RESET}         - Inf Loop"
    echo
}

# Function to play file with mpv
play_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "${RED}Error: File not found!${RESET}"
        return 1
    fi
    
    show_header
    
    # Display now playing info
    draw_box "$(basename "$file")" "$MAGENTA"
    echo
    
    show_controls
    
    # Launch mpv with direct arguments
    
    mpv \
        --osd-level=1 \
        --osd-duration=2000 \
        --osd-status-msg='${time-pos} / ${duration} (${percent-pos}%) Vol: ${volume}%' \
        --osd-playing-msg='Playing: ${filename}' \
        --term-osd-bar=yes \
        --msg-color=yes \
        --term-osd-bar-chars='[━━ ]' \
        --term-status-msg='Time: ${time-pos}/${duration} (${percent-pos}%) Vol: ${volume}% Speed: ${speed}x' \
        --autofit=85% \
        "$file"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo
        echo "${BLUE}✓ Playback completed${RESET}"
    else
        echo
        echo "${RED}✗ Playback interrupted${RESET}"
    fi
    
    echo
    echo "${DIM}Press any key to continue...${RESET}"
    read -n 1 -s
}

# Function to browse and select files
browse_files() {
    local current_dir="$HOME/Downloads/Telegram Desktop"
    
    while true; do
        show_file_browser
        echo
        echo "${BOLD}${YELLOW}Options:${RESET}"
        echo "  ${BLUE}Enter number${RESET} to play music"
        echo "  ${BLUE}q${RESET} to quit"
        echo
        echo -n "${MAGENTA}Choice: ${RESET}"
        read -r choice
        
        case "$choice" in
            "q"|"quit")
                echo
                echo "${BLUE}Thanks for using MPV TUI! ${MUSIC_ICON}${RESET}"
                exit 0
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le "${#MEDIA_FILES[@]}" ]; then
                    play_file "${MEDIA_FILES[$((choice-1))]}"
                else
                    echo "${RED}Invalid selection!${RESET}"
                    sleep 2
                fi
                ;;
        esac
    done
}

# Main function
main() {
    # Check if mpv is installed
    if ! command -v mpv &> /dev/null; then
        echo "${RED}Error: mpv is not installed!${RESET}"
        echo "Please install mpv first:"
        echo "  ${MAGENTA}sudo pacman -S mpv${RESET}   #󰣇 Arch Linux"
        echo "  ${MAGENTA}sudo emerge --av mpv${RESET}   #󰣨 Gentoo"
        exit 1
    fi
    
    browse_files
}

# Trap Ctrl+C for clean exit
trap 'echo -e "\n${YELLOW}Goodbye!${RESET}"; exit 0' INT

# Run main function
main "$@"
