#!/bin/bash

# TUI interface for mpv

# --- Colors and styles ---
readonly RED=$(tput setaf 1)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly WHITE=$(tput setaf 7)
readonly BOLD=$(tput bold)
readonly DIM=$(tput dim)
readonly RESET=$(tput sgr0)

# --- Globals ---
TERM_WIDTH=$(tput cols)
TERM_HEIGHT=$(tput lines)
SHOW_FOOTER=0
declare -a LAST_DRAWN_LINES=()
REDRAW_INTERVAL=0.016 # ~60fps
LAST_REDRAW_TIME=0

should_redraw() {
    local now
    now=$(date +%s.%3N)
    awk "BEGIN {exit !($now - $LAST_REDRAW_TIME >= $REDRAW_INTERVAL)}"
}

# --- Layout helpers ---
draw_line() {
    local char="${1:--}"
    local width="${2:-$TERM_WIDTH}"
    ((width > 0)) || width=1
    printf -v line "%*s" "$width" ""
    echo "${line// /$char}"
    echo
}

center_text() {
    local text="$1"
    local width="${2:-$TERM_WIDTH}"
    local text_len=${#text}
    ((width < text_len)) && width=$text_len
    local padding=$(((width - text_len) / 2))
    local right=$((width - text_len - padding))
    printf "%*s%s%*s\n" "$padding" "" "$text" "$right" ""
}

draw_box() {
    local text="$1"
    local color="${2:-$MAGENTA}"
    local text_length=${#text}
    local box_width=$((text_length + 4))

    local padding=$(((TERM_WIDTH - box_width) / 2))
    ((padding < 0)) && padding=0

    printf "%*s" "$padding" ""
    echo "${color}╭$(repeat $((box_width - 2)) -)╮${RESET}"

    printf "%*s" "$padding" ""
    echo "${color}│${RESET} ${BOLD}$text${RESET} ${color}│${RESET}"

    printf "%*s" "$padding" ""
    echo "${color}╰$(repeat $((box_width - 2)) -)╯${RESET}"
}

repeat() {
    local count="$1"
    local char="$2"
    printf "%*s" "$count" "" | tr ' ' "$char"
}

# --- Header ---
show_header() {
    TERM_WIDTH=$(tput cols)
    TERM_HEIGHT=$(tput lines)

    clear
    LAST_DRAWN_LINES=()
    echo "${BOLD}${YELLOW}"
    draw_box "MPV TUI" "$YELLOW"
    echo "${RESET}"
    printf '\n'

    if [[ $MEDIA_COVER_PATH && -f $MEDIA_COVER_PATH ]]; then
        display_cover "$MEDIA_COVER_PATH"
        printf '\n'
    fi

    if [[ $CURRENT_TITLE ]]; then
        center_text "${BOLD}${MAGENTA}$CURRENT_TITLE${RESET}"
        printf '\n'
    fi
}

# --- Data helpers ---
collect_media_files() {
    local dir="$1"
    mapfile -t MEDIA_FILES < <(find "$dir" -maxdepth 1 -type f \
        \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) 2>/dev/null)
}

# --- Unified window draw (fixes duplication) ---
draw_window() {
    TERM_WIDTH=$(tput cols)
    TERM_HEIGHT=$(tput lines)

    local end=$((offset + window_size - 1))
    ((end >= total)) && end=$((total - 1))

    local new_lines=()

    for ((i = offset; i <= end; i++)); do
        local base=${MEDIA_FILES[i]##*/}
        if ((i == index)); then
            new_lines+=("$(center_text " ${REVERSE}${BOLD}> $base${RESET}")")
        else
            new_lines+=("$(center_text "   $base")")
        fi
    done

    for ((i = end + 1; i < offset + window_size; i++)); do
        new_lines+=("$(center_text "")")
    done

    # Compare and redraw only changed lines
    for ((i = 0; i < ${#new_lines[@]}; i++)); do
        if [[ "${new_lines[i]}" != "${LAST_DRAWN_LINES[i]}" ]]; then
            tput cup $((5 + i)) 0
            tput el
            echo -ne "${new_lines[i]}"
        fi
    done

    LAST_DRAWN_LINES=("${new_lines[@]}")

    # Footer (always redraw)
    if ((SHOW_FOOTER)); then
        tput cup $((5 + window_size + 1)) 0
        tput el
        echo "${DIM}${YELLOW}Total: $total${RESET}"
        echo "${BOLD}${BLUE}Usage:${RESET} j/k=nav, Enter=play, /=search, u=update covers, r=rename, c=cleanup, s=search&play, q=quit"
    fi
}

# --- Search and play ---
search_and_play() {
    echo -n "${MAGENTA}Search query: ${RESET}"
    read -r query

    local q="${query,,}"
    if [[ -z $q ]]; then
        echo "${RED}Empty query!${RESET}"
        sleep 1
        clear
        return
    fi

    local matches=()
    for file in "${MEDIA_FILES[@]}"; do
        local base="${file##*/}"
        [[ "${base,,}" == *"$q"* ]] && matches+=("$file")
    done

    case ${#matches[@]} in
    0)
        echo "${RED}No matches found for '$query'${RESET}"
        sleep 2
        clear
        ;;
    1)
        play_file "${matches[0]}"
        ;;
    *)
        echo "${YELLOW}Multiple matches found:${RESET}"
        for i in "${!matches[@]}"; do
            printf "  ${BLUE}[%d]${RESET} %s\n" $((i + 1)) "${matches[i]##*/}"
        done
        echo -n "${MAGENTA}Choose number: ${RESET}"
        read -r choice
        if [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#matches[@]})); then
            play_file "${matches[choice - 1]}"
        else
            echo "${RED}Invalid selection!${RESET}"
            sleep 2
            clear
        fi
        ;;
    esac
}

# --- Filename normalization ---
normalize_music_filenames() {
    local current_dir="$HOME/Downloads/Telegram Desktop"
    echo "${BLUE}Normalizing music filenames...${RESET}"

    declare -A stopwords=(
        [medium]=1 [audio]=1 [music]=1 [track]=1 [song]=1
        [stereo]=1 [mono]=1 [official]=1 [video]=1 [only]=1
    )

    shopt -s nullglob
    for file in "$current_dir"/*.{mp3,flac,wav,ogg,m4a}; do
        [[ -e $file ]] || continue

        local dir=${file%/*}
        local base=${file##*/}
        local ext=${base##*.}
        local name=${base%.*}

        local newname
        newname=$(sed -E 's/[[:upper:]]/\L&/g; s/[0-9]//g; s/[^a-z]+/_/g; s/_+/_/g; s/^_|_$//g' <<<"$name")

        local filtered=""
        for token in ${newname//_/ }; do
            if ((${#token} <= 2)) || [[ ${stopwords[$token]} ]]; then
                continue
            fi
            filtered+="${token}_"
        done

        filtered=${filtered%_}
        [[ -z $filtered ]] && filtered=$newname

        local newfile="$dir/$filtered.$ext"
        if [[ $file != "$newfile" ]]; then
            echo "Renaming: $base → ${newfile##*/}"
            mv -n -- "$file" "$newfile"
        fi
    done
    shopt -u nullglob
}

# --- Cover maintenance ---
cleanup_orphan_covers() {
    local cover_dir="$HOME/Pictures/CoverArts"
    echo "${BLUE}Cleaning up orphaned cover arts...${RESET}"

    mkdir -p "$cover_dir"

    declare -A valid=()
    for file in "${MEDIA_FILES[@]}"; do
        local name="${file##*/}"
        name="${name%.*}"
        valid["$name"]=1
    done

    shopt -s nullglob
    for img in "$cover_dir"/*.{jpg,png,svg,jpeg}; do
        local name="${img##*/}"
        name="${name%.*}"
        if ! [[ -v valid[$name] ]]; then
            echo "Deleting orphan cover: ${img##*/}"
            rm -f -- "$img"
        fi
    done
    shopt -u nullglob
}

show_covers() {
    local covers_dir="$HOME/Pictures/CoverArts"
    local lock_file="$covers_dir/.lock"

    if [[ ! -d $covers_dir ]]; then
        if ! mkdir -p "$covers_dir"; then
            echo "${RED}Error: Unable to create directory $covers_dir!${RESET}"
            return 1
        fi
    fi

    if [[ -f $lock_file ]]; then
        echo "${YELLOW}Cover art downloading is already in progress, skipping...${RESET}"
        return
    fi

    if ! touch "$lock_file"; then
        echo "${RED}Error: Unable to create lock file $lock_file!${RESET}"
        return 1
    fi
    rm -f "$lock_file"

    local covers=()
    shopt -s nullglob
    for img in "$covers_dir"/*.{jpg,png}; do
        covers+=("$img")
    done
    shopt -u nullglob

    if ((${#covers[@]} == 0)); then
        echo "${YELLOW}No cover arts found in $covers_dir${RESET}"
        return
    fi

    for cover in "${covers[@]}"; do
        display_cover "$cover"
        printf '\n'
    done
}

download_cover() {
    local file="$1"
    local music_name=${file##*/}
    local base_name="${music_name%.*}"
    local cover_dir="$HOME/Pictures/CoverArts"
    local cover_path="$cover_dir/${base_name}.jpg"
    local nocover_path="$cover_dir/${base_name}.nocover"

    mkdir -p "$cover_dir" || {
        echo "${RED}Error: Unable to create $cover_dir${RESET}"
        return 1
    }

    if [[ -f $nocover_path ]]; then
        echo "${YELLOW}Skipping $music_name (previously marked as no cover)${RESET}"
        return 1
    fi

    if [[ -f $cover_path ]]; then
        MEDIA_COVER_PATH="$cover_path"
        return 0
    elif [[ -f $cover_dir/${base_name}.png ]]; then
        MEDIA_COVER_PATH="$cover_dir/${base_name}.png"
        return 0
    fi

    local query="$base_name"
    local cover_url=""

    echo "${YELLOW}Searching cover art for: $query${RESET}"

    cover_url=$(curl -fsS "https://itunes.apple.com/search?term=${query// /+}&entity=album&limit=1" |
        jq -r '.results[0].artworkUrl100' 2>/dev/null |
        sed 's/100x100bb/600x600bb/')

    if [[ -z $cover_url || $cover_url == "null" ]]; then
        cover_url=$(curl -fsS "https://api.deezer.com/search/album?q=${query// /%20}" |
            jq -r '.data[0].cover_xl' 2>/dev/null)
    fi

    if [[ -z $cover_url || $cover_url == "null" ]]; then
        local thumb_url
        thumb_url=$(curl -fsS "https://www.google.com/search?tbm=isch&q=${query// /+}" |
            grep -o 'https://encrypted-tbn0.gstatic.com/images?q=tbn[^"]*' |
            head -n1)
        if [[ -n $thumb_url ]]; then
            local hi_url
            hi_url=$(sed -E 's/([?&])w=[0-9]+/\1w=600/; s/([?&])h=[0-9]+/\1h=600/' <<<"$thumb_url")
            cover_url=${hi_url:-$thumb_url}
        fi
    fi

    if [[ -z $cover_url || $cover_url == "null" ]]; then
        echo "${RED}No cover art found online for $music_name.${RESET}"
        echo -e "Please add it manually as ${cover_dir}/${base_name}.{jpg/png}\nNote: cover art should be at least 600x600px"
        : >"$nocover_path"
        return 1
    fi

    echo "${GREEN}Downloading cover art...${RESET}"
    if ! curl -fsSL "$cover_url" -o "$cover_path"; then
        echo "${RED}Failed to download cover art from $cover_url${RESET}"
        : >"$nocover_path"
        return 1
    fi

    if command -v magick &>/dev/null; then
        magick "$cover_path" \
            -resize 600x600^ \
            -gravity center -extent 600x600 \
            -sharpen 0x1.0 \
            "$cover_path"
    else
        echo "${YELLOW}Tip: install ImageMagick to upscale and sharpen low‑res covers automatically.${RESET}"
    fi

    MEDIA_COVER_PATH="$cover_path"
    [[ -f $nocover_path ]] && rm -f "$nocover_path"
}

normalize_cover() {
    local cover_path="$1"

    local identify_cmd convert_cmd
    if command -v magick &>/dev/null; then
        identify_cmd="magick identify"
        convert_cmd="magick convert"
    elif command -v identify &>/dev/null && command -v convert &>/dev/null; then
        identify_cmd="identify"
        convert_cmd="convert"
    else
        echo "${YELLOW}Tip: install ImageMagick to normalize covers automatically.${RESET}"
        return 1
    fi

    local dims
    dims=$($identify_cmd -format "%wx%h" "$cover_path" 2>/dev/null) || {
        echo "${RED}Error: unable to read image $cover_path${RESET}"
        return 1
    }

    if [[ "$dims" != "600x600" ]]; then
        local tmp="${cover_path}.tmp"
        if $convert_cmd "$cover_path" \
            -resize 600x600^ \
            -gravity center -extent 600x600 \
            -sharpen 0x1.0 \
            "$tmp"; then
            mv -f "$tmp" "$cover_path"
        else
            echo "${RED}Error: failed to process $cover_path${RESET}"
            rm -f "$tmp"
            return 1
        fi
    fi
}

update_covers() {
    local cover_dir="$HOME/Pictures/CoverArts"
    mkdir -p "$cover_dir"

    echo "${BLUE}Updating cover arts...${RESET}"
    local total=${#MEDIA_FILES[@]}

    for file in "${MEDIA_FILES[@]}"; do
        local music_name=${file##*/}
        local base_name="${music_name%.*}"
        local cover_jpg="$cover_dir/${base_name}.jpg"
        local cover_png="$cover_dir/${base_name}.png"

        if [[ -f $cover_jpg ]]; then
            normalize_cover "$cover_jpg"
        elif [[ -f $cover_png ]]; then
            normalize_cover "$cover_png"
        else
            echo "${YELLOW}No cover for $music_name, downloading...${RESET}"
            if download_cover "$file"; then
                [[ -f $cover_jpg ]] && normalize_cover "$cover_jpg"
                [[ -f $cover_png ]] && normalize_cover "$cover_png"
            else
                echo "${RED}Failed to get cover for $music_name${RESET}"
            fi
        fi
    done

    echo
    echo "${GREEN}Cover art update complete.${RESET}"
    echo "${DIM}Press any key to continue...${RESET}"
    read -r -n 1 -s
    clear
}

# --- Cover display ---
display_cover() {
    local cover="$1"
    [[ -f $cover ]] || {
        echo "${RED}Cover not found: $cover${RESET}"
        return 1
    }

    local viewer=""
    if [[ $TERM == "xterm-kitty" || -n $KITTY_WINDOW_ID ]] && command -v kitty &>/dev/null; then
        viewer="kitty"
    elif command -v chafa &>/dev/null; then
        viewer="chafa"
    elif command -v ascii-image-converter &>/dev/null; then
        viewer="ascii-image-converter"
    elif command -v viu &>/dev/null; then
        viewer="viu"
    fi

    if [[ $viewer == "kitty" ]]; then
        kitty +kitten icat --align center "$cover"
    else
        local output
        output=$($viewer "$cover" 2>/dev/null)
        while IFS= read -r line; do
            center_text "$line"
        done <<<"$output"
    fi
}

# --- MPV IPC (reserved for future persistence) ---
open_mpv_ipc() {
    local socket="/tmp/mpv-socket"
    exec {MPV_FD}<> >(socat - "$socket")
}

close_mpv_ipc() {
    exec {MPV_FD}>&-
}

mpv_cmd() {
    local cmd="$1"
    printf '%s\n' "$cmd" >&$MPV_FD
}

# --- Playback ---
play_file() {
    local file="$1"
    local socket="/tmp/mpv-socket"

    [ -e "$socket" ] && rm -f "$socket"

    download_cover "$file"
    CURRENT_TITLE="${file##*/}"
    show_header

    mpv --quiet --no-terminal --osd-level=0 \
        --no-video --audio-display=no \
        --input-ipc-server="$socket" \
        "$file" &
    local mpv_pid=$!

    sleep 0.2
    if ! kill -0 "$mpv_pid" 2>/dev/null; then
        echo "${RED}Error: mpv failed to start for $file${RESET}"
        return 1
    fi

    echo
    echo "${BOLD}${YELLOW}Controls:${RESET}"
    echo "  ${BLUE}[p]${RESET} pause/resume"
    echo "  ${BLUE}[l]${RESET} fast forward 10s"
    echo "  ${BLUE}[h]${RESET} backward 10s"
    echo "  ${BLUE}[L]${RESET} toggle loop"
    echo "  ${BLUE}[q]${RESET} stop and return to menu"

    while kill -0 "$mpv_pid" 2>/dev/null; do
        read -rsn1 key
        while read -rsn1 -t 0.001 extra; do :; done
        case "$key" in
        p)
            printf '{ "command": ["cycle", "pause"] }\n' | socat - "$socket" >/dev/null
            state=$(printf '{ "command": ["get_property", "pause"] }\n' | socat - "$socket" | jq -r '.data')
            show_header
            if [[ $state == "true" ]]; then
                echo "${YELLOW}Paused${RESET}"
            else
                echo "${GREEN}Playing${RESET}"
            fi
            ;;
        h)
            printf '{ "command": ["seek", -10] }\n' | socat - "$socket" >/dev/null
            show_header
            echo "${BLUE}<< Skipped back 10s${RESET}"
            ;;
        l)
            printf '{ "command": ["seek", 10] }\n' | socat - "$socket" >/dev/null
            show_header
            echo "${BLUE}>> Skipped forward 10s${RESET}"
            ;;
        L)
            current=$(printf '{ "command": ["get_property", "loop-file"] }\n' | socat - "$socket" | jq -r '.data // "no"')
            if [[ $current == "inf" || $current == "yes" || $current == "true" ]]; then
                printf '{ "command": ["set_property", "loop-file", "no"] }\n' | socat - "$socket" >/dev/null
                show_header
                echo "${YELLOW}Loop: Disabled${RESET}"
            else
                printf '{ "command": ["set_property", "loop-file", "inf"] }\n' | socat - "$socket" >/dev/null
                show_header
                echo "${GREEN}Loop: Inf${RESET}"
            fi
            ;;
        q)
            printf '{ "command": ["quit"] }\n' | socat - "$socket" >/dev/null
            MEDIA_COVER_PATH=""
            break
            ;;
        esac
    done

    wait "$mpv_pid" 2>/dev/null
    echo "${DIM}Returning to menu...${RESET}"
    sleep 0.4
}

# --- Browser ---
browse_files() {
    local current_dir="${1:-$HOME/Downloads/Telegram Desktop}"

    collect_media_files "$current_dir"
    local total=${#MEDIA_FILES[@]}
    ((total == 0)) && {
        echo "${RED}No media files found${RESET}"
        sleep 2
        return
    }

    index=0
    window_size=$((TERM_HEIGHT - 12))
    ((window_size < 5)) && window_size=5
    offset=0
    local last_key=""

    tput civis
    tput clear
    show_header
    printf '\n'

    SHOW_FOOTER=1
    draw_window

    while true; do
        IFS= read -rsn1 key
        while read -rsn1 -t 0.001 extra; do :; done
        case "$key" in
        j)
            ((index < total - 1)) && ((index++))
            ((index >= offset + window_size)) && ((offset++))
            if should_redraw; then
                draw_window
                LAST_REDRAW_TIME=$(date +%s.%3N)
            fi
            ;;
        k)
            ((index > 0)) && ((index--))
            ((index < offset)) && ((offset--))
            if should_redraw; then
                draw_window
                LAST_REDRAW_TIME=$(date +%s.%3N)
            fi
            ;;
        g)
            if [[ $last_key == "g" ]]; then
                index=0
                offset=0
                draw_window
                last_key=""
                continue
            fi
            ;;
        G)
            index=$((total - 1))
            offset=$((total > window_size ? total - window_size : 0))
            draw_window
            ;;
        /)
            tput cnorm
            tput cup $((TERM_HEIGHT - 2)) 0
            echo -n "${MAGENTA}/ ${RESET}"
            read -r query
            tput civis
            if [[ -n $query ]]; then
                local q="${query,,}"
                for ((i = 0; i < total; i++)); do
                    local base=${MEDIA_FILES[i]##*/}
                    if [[ ${base,,} == *"$q"* ]]; then
                        index=$i
                        offset=$((i < window_size ? 0 : i - window_size / 2))
                        ((offset < 0)) && offset=0
                        draw_window
                        break
                    fi
                done
            fi
            ;;
        "")
            play_file "${MEDIA_FILES[index]}"
            clear
            show_header
            draw_window
            ;;
        u)
            update_covers
            show_header
            draw_window
            ;;
        r)
            normalize_music_filenames
            show_header
            draw_window
            ;;
        c)
            cleanup_orphan_covers
            show_header
            draw_window
            ;;
        s)
            search_and_play
            show_header
            draw_window
            ;;
        q) break ;;
        esac
        last_key="$key"
    done

    tput cnorm
    clear
}

# --- Main ---
main() {
    local music_dir="$HOME/Downloads/Telegram Desktop"

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help)
            echo "MPV TUI Player"
            echo
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  -h, --help        Show this help message and exit"
            echo "  -d, --dir <path>  Set music directory (default: $music_dir)"
            echo
            echo "Keybindings inside browser:"
            echo "  j/k       Move down/up"
            echo "  gg / G    Jump to top/bottom"
            echo "  /         Search"
            echo "  Enter     Play selected file"
            echo "  p/h/l/L   Playback controls (pause, seek, loop)"
            echo "  q         Quit playback or exit"
            exit 0
            ;;
        -d | --dir)
            shift
            if [[ -n $1 ]]; then
                music_dir="$1"
            else
                echo "${RED}Error: --dir requires a path${RESET}"
                exit 1
            fi
            ;;
        *)
            echo "${RED}Unknown option: $1${RESET}"
            echo "Try '$0 --help' for usage."
            exit 1
            ;;
        esac
        shift
    done

    local -a required=(mpv jq socat)
    local missing=()
    for dep in "${required[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    if ((${#missing[@]} > 0)); then
        echo "${RED}Error: Missing required dependencies: ${missing[*]}${RESET}"
        exit 1
    fi

    local -a optional=(chafa ascii-image-converter kitty viu)
    local found_opt=()
    for dep in "${optional[@]}"; do
        command -v "$dep" &>/dev/null && found_opt+=("$dep")
    done
    if ((${#found_opt[@]} == 0)); then
        echo "${YELLOW}Note: No terminal image viewer found.${RESET}"
        echo "${YELLOW}Consider installing one of these: chafa, ascii-image-converter, viu.${RESET}"
    fi

    browse_files "$music_dir"
}

# --- Cleanup & traps ---
cleanup() {
    tput cnorm 2>/dev/null
    rm -f /tmp/mpv-socket
    clear
    echo -e "\n${YELLOW}Goodbye!${RESET}"
    pkill -f "mpv --quiet" 2>/dev/null
    exit 0
}
trap cleanup INT TERM

main "$@"
