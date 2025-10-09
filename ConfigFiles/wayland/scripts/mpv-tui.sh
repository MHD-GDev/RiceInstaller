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

# Terminal dimensions
TERM_WIDTH=$(tput cols)
TERM_HEIGHT=$(tput lines)

# Function to draw a horizontal line
draw_line() {
    local char="${1:--}"
    local width="${2:-$TERM_WIDTH}"

    ((width > 0)) || width=1
    printf -v line "%*s" "$width" ""
    echo "${line// /$char}"
    echo
}

# Function to center text
center_text() {
    local text="$1"
    local width="${2:-$TERM_WIDTH}"
    local text_len=${#text}

    # Clamp width to at least text length
    ((width < text_len)) && width=$text_len

    local padding=$(((width - text_len) / 2))
    local right=$((width - text_len - padding))

    printf "%*s%s%*s\n" "$padding" "" "$text" "$right" ""
}

search_and_play() {
    echo -n "${MAGENTA}Search query: ${RESET}"
    read -r query

    # Normalize query once (lowercase)
    local q="${query,,}"

    # Bail early on empty query
    if [[ -z $q ]]; then
        echo "${RED}Empty query!${RESET}"
        sleep 1
        clear
        return
    fi

    # Collect matches
    local matches=()
    for file in "${MEDIA_FILES[@]}"; do
        local base="${file##*/}" # faster than basename
        if [[ "${base,,}" == *"$q"* ]]; then
            matches+=("$file")
        fi
    done

    # Handle results
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

normalize_music_filenames() {
    local current_dir="$HOME/Downloads/Telegram Desktop"
    echo "${BLUE}Normalizing music filenames...${RESET}"

    # Stopwords as an associative array for O(1) lookup
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

        # Normalize: lowercase, strip digits, replace non-letters with underscores
        local newname
        newname=$(sed -E 's/[[:upper:]]/\L&/g; s/[0-9]//g; s/[^a-z]+/_/g; s/_+/_/g; s/^_|_$//g' <<<"$name")

        # Token filtering
        local filtered=""
        for token in ${newname//_/ }; do
            # Skip short tokens and stopwords
            if ((${#token} <= 2)) || [[ ${stopwords[$token]} ]]; then
                continue
            fi
            filtered+="${token}_"
        done

        # Remove trailing underscore or fallback
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

cleanup_orphan_covers() {
    local cover_dir="$HOME/Pictures/CoverArts"
    echo "${BLUE}Cleaning up orphaned cover arts...${RESET}"

    mkdir -p "$cover_dir"

    # Build a set of valid base names from MEDIA_FILES
    declare -A valid=()
    for file in "${MEDIA_FILES[@]}"; do
        local name="${file##*/}" # strip path
        name="${name%.*}"        # strip extension
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

# Function to create a box around text
draw_box() {
    local text="$1"
    local color="${2:-$MAGENTA}"
    local text_length=${#text}
    local box_width=$((text_length + 4))

    # Centering
    local padding=$(((TERM_WIDTH - box_width) / 2))
    ((padding < 0)) && padding=0

    printf "%*s" "$padding" ""
    echo "${color}╭$(repeat $((box_width - 2)) -)╮${RESET}"

    printf "%*s" "$padding" ""
    echo "${color}│${RESET} ${BOLD}$text${RESET} ${color}│${RESET}"

    printf "%*s" "$padding" ""
    echo "${color}╰$(repeat $((box_width - 2)) -)╯${RESET}"
}

# Repeat a character N times
repeat() {
    local count="$1"
    local char="$2"
    printf "%*s" "$count" "" | tr ' ' "$char"
}

# Function to display the header
show_header() {
    # Recompute terminal size each time
    TERM_WIDTH=$(tput cols)
    TERM_HEIGHT=$(tput lines)

    clear
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

show_file_browser() {
    local current_dir="$HOME/Downloads/Telegram Desktop"

    # Collect media files
    local -a media_files=()
    while IFS= read -r file; do
        [[ -f $file ]] && media_files+=("$file")
    done < <(find "$current_dir" -maxdepth 1 -type f \
        \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) 2>/dev/null)

    MEDIA_FILES=("${media_files[@]}")
    local total=${#MEDIA_FILES[@]}
    ((total == 0)) && {
        echo "${RED}No media files found${RESET}"
        sleep 2
        return
    }

    local index=0
    local window_size=$((TERM_HEIGHT - 12))
    ((window_size < 5)) && window_size=5
    local offset=0
    local last_key=""

    tput civis # hide cursor
    tput clear
    show_header

    draw_window() {
        TERM_WIDTH=$(tput cols)
        TERM_HEIGHT=$(tput lines)

        local end=$((offset + window_size - 1))
        ((end >= total)) && end=$((total - 1))

        tput cup 5 0
        for ((i = offset; i <= end; i++)); do
            local base=${MEDIA_FILES[i]##*/}
            if ((i == index)); then
                printf "%s\n" "$(center_text " ${REVERSE}${BOLD}> $base${RESET}")"
            else
                printf "%s\n" "$(center_text "   $base")"
            fi
        done
        for ((i = end + 1; i < offset + window_size; i++)); do
            printf "%s\n" "$(center_text "")"
        done
        printf '\n'

        echo "${DIM}Total: $total${RESET}"
        echo "${BOLD}${BLUE}Usage:${RESET} j/k=nav, Enter=play, /=search, u=update covers, r=rename, c=cleanup, s=search&play, q=quit"

        # Clear everything below the cursor to avoid duplicates
        tput ed
    }

    draw_window

    while true; do
        IFS= read -rsn1 key
        case "$key" in
        j)
            ((index < total - 1)) && ((index++))
            ((index >= offset + window_size)) && ((offset++))
            draw_window
            ;;
        k)
            ((index > 0)) && ((index--))
            ((index < offset)) && ((offset--))
            draw_window
            ;;
        g) # check for gg
            if [[ $last_key == "g" ]]; then
                index=0
                offset=0
                draw_window
                last_key=""
                continue
            fi
            ;;
        G) # jump to bottom
            index=$((total - 1))
            offset=$((total > window_size ? total - window_size : 0))
            draw_window
            ;;
        /) # search
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
            break
            ;;
        q) break ;;
        esac
        last_key="$key"
    done

    tput cnorm # restore cursor
}

show_covers() {
    local covers_dir="$HOME/Pictures/CoverArts"
    local lock_file="$covers_dir/.lock"

    # Ensure directory exists
    if [[ ! -d $covers_dir ]]; then
        if ! mkdir -p "$covers_dir"; then
            echo "${RED}Error: Unable to create directory $covers_dir!${RESET}"
            return 1
        fi
    fi

    # Prevent concurrent runs
    if [[ -f $lock_file ]]; then
        echo "${YELLOW}Cover art downloading is already in progress, skipping...${RESET}"
        return
    fi

    # Create lock and ensure cleanup on exit
    if ! touch "$lock_file"; then
        echo "${RED}Error: Unable to create lock file $lock_file!${RESET}"
        return 1
    fi
    rm -f "$lock_file"

    # Collect covers
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

    # Display each cover (or however display_cover is defined)
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

    # Skip if marked as no cover
    if [[ -f $nocover_path ]]; then
        echo "${YELLOW}Skipping $music_name (previously marked as no cover)${RESET}"
        return 1
    fi

    # Already exists?
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

    # --- Try iTunes ---
    cover_url=$(curl -fsS "https://itunes.apple.com/search?term=${query// /+}&entity=album&limit=1" |
        jq -r '.results[0].artworkUrl100' 2>/dev/null |
        sed 's/100x100bb/600x600bb/')

    # --- Fallback 1: Deezer ---
    if [[ -z $cover_url || $cover_url == "null" ]]; then
        cover_url=$(curl -fsS "https://api.deezer.com/search/album?q=${query// /%20}" |
            jq -r '.data[0].cover_xl' 2>/dev/null)
    fi

    # --- Fallback 2: Google Images ---
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

    # --- If still nothing ---
    if [[ -z $cover_url || $cover_url == "null" ]]; then
        echo "${RED}No cover art found online for $music_name.${RESET}"
        echo -e "Please add it manually as ${cover_dir}/${base_name}.{jpg/png}\nNote: cover art should be at least 600x600px"
        # Mark as no cover to skip next time
        : >"$nocover_path"
        return 1
    fi

    echo "${GREEN}Downloading cover art...${RESET}"
    if ! curl -fsSL "$cover_url" -o "$cover_path"; then
        echo "${RED}Failed to download cover art from $cover_url${RESET}"
        : >"$nocover_path"
        return 1
    fi

    # Post-process if ImageMagick is available
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
    # Success: remove any stale nocover marker
    [[ -f $nocover_path ]] && rm -f "$nocover_path"
}

normalize_cover() {
    local cover_path="$1"

    # Prefer "magick" if available, else fallback to legacy commands
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

    # Get dimensions safely
    local dims
    dims=$($identify_cmd -format "%wx%h" "$cover_path" 2>/dev/null) || {
        echo "${RED}Error: unable to read image $cover_path${RESET}"
        return 1
    }

    if [[ "$dims" != "600x600" ]]; then
        echo "${YELLOW}Normalizing $cover_path ($dims → 600x600)...${RESET}"
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
    else
        echo "${GREEN}$cover_path is already normalized (600x600).${RESET}"
    fi
}

update_covers() {
    local cover_dir="$HOME/Pictures/CoverArts"
    mkdir -p "$cover_dir"

    echo "${BLUE}Updating cover arts...${RESET}"
    local total=${#MEDIA_FILES[@]}
    local count=0

    for file in "${MEDIA_FILES[@]}"; do
        ((count++))
        local music_name=${file##*/}
        local base_name="${music_name%.*}"
        local cover_jpg="$cover_dir/${base_name}.jpg"
        local cover_png="$cover_dir/${base_name}.png"

        echo "${DIM}[$count/$total] Processing $music_name...${RESET}"

        if [[ -f $cover_jpg ]]; then
            normalize_cover "$cover_jpg"
        elif [[ -f $cover_png ]]; then
            normalize_cover "$cover_png"
        else
            echo "${YELLOW}No cover for $music_name, downloading...${RESET}"
            if download_cover "$file"; then
                # normalize whatever was downloaded
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
    read -n 1 -s
}

# Display cover art
display_cover() {
    local cover="$1"

    # Sanity check
    [[ -f $cover ]] || {
        echo "${RED}Cover not found: $cover${RESET}"
        return 1
    }

    # Prefer Kitty's icat if available
    if [[ $TERM == "xterm-kitty" || -n $KITTY_WINDOW_ID ]] && command -v kitty &>/dev/null; then
        kitty +kitten icat --align center "$cover" && return
    fi

    # Try chafa
    if command -v chafa &>/dev/null; then
        chafa --fill=block --symbols=block "$cover" && return
    fi

    # Try ascii-image-converter
    if command -v ascii-image-converter &>/dev/null; then
        ascii-image-converter -C "$cover" && return
    fi

    # Try viu (another common terminal image viewer)
    if command -v viu &>/dev/null; then
        viu -w "$((TERM_WIDTH / 2))" "$cover" && return
    fi

    # If nothing worked
    echo "${RED}No supported image viewer found!${RESET}"
    echo "${YELLOW}Tip: install chafa, ascii-image-converter, or viu for terminal cover art.${RESET}"
}

# Open a persistent connection to mpv IPC
open_mpv_ipc() {
    local socket="/tmp/mpv-socket"
    exec {MPV_FD}<> >(socat - "$socket")
}

# Close the persistent connection
close_mpv_ipc() {
    exec {MPV_FD}>&-
}

# Send a command to mpv
mpv_cmd() {
    local cmd="$1"
    printf '%s\n' "$cmd" >&$MPV_FD
}

# Example usage inside play loop
play_file() {
    local file="$1"
    local socket="/tmp/mpv-socket"

    # Clean up any old socket
    [ -e "$socket" ] && rm -f "$socket"

    # Download cover before playback
    download_cover "$file"
    CURRENT_TITLE="${file##*/}"
    show_header

    # Launch mpv in background with IPC
    mpv --quiet --no-terminal --osd-level=0 \
        --input-ipc-server="$socket" \
        "$file" &
    local mpv_pid=$!

    # Give mpv a moment to start and check if it’s alive
    sleep 0.2
    if ! kill -0 "$mpv_pid" 2>/dev/null; then
        echo "${RED}Error: mpv failed to start for $file${RESET}"
        return 1
    fi

    # Print static controls once
    echo
    echo "${BOLD}${YELLOW}Controls:${RESET}"
    echo "  ${BLUE}[p]${RESET} pause/resume"
    echo "  ${BLUE}[l]${RESET} fast forward 10s"
    echo "  ${BLUE}[h]${RESET} backward 10s"
    echo "  ${BLUE}[L]${RESET} toggle loop"
    echo "  ${BLUE}[+]${RESET} volume up"
    echo "  ${BLUE}[-]${RESET} volume down"
    echo "  ${BLUE}[q]${RESET} stop and return to menu"

    # Control loop
    while kill -0 "$mpv_pid" 2>/dev/null; do
        read -rsn1 key
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
        +)
            printf '{ "command": ["add", "volume", 5] }\n' | socat - "$socket" >/dev/null
            show_header
            echo "${GREEN}Volume +5${RESET}"
            ;;
        -)
            printf '{ "command": ["add", "volume", -5] }\n' | socat - "$socket" >/dev/null
            show_header
            echo "${GREEN}Volume -5${RESET}"
            ;;
        q)
            printf '{ "command": ["quit"] }\n' | socat - "$socket" >/dev/null
            break
            ;;
        esac
    done

    wait "$mpv_pid" 2>/dev/null
    echo "${DIM}Returning to menu...${RESET}"
    sleep 1
}

# Function to browse and select files
browse_files() {
    local current_dir="${1:-$HOME/Downloads/Telegram Desktop}"

    # Collect media files
    local -a media_files=()
    while IFS= read -r file; do
        [[ -f $file ]] && media_files+=("$file")
    done < <(find "$current_dir" -maxdepth 1 -type f \
        \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) 2>/dev/null)

    MEDIA_FILES=("${media_files[@]}")
    local total=${#MEDIA_FILES[@]}
    ((total == 0)) && {
        echo "${RED}No media files found${RESET}"
        sleep 2
        return
    }

    local index=0
    local window_size=$((TERM_HEIGHT - 12))
    ((window_size < 5)) && window_size=5
    local offset=0
    local last_key=""

    tput civis
    tput clear
    show_header
    printf '\n'

    draw_window() {
        # Recompute terminal size each time
        TERM_WIDTH=$(tput cols)
        TERM_HEIGHT=$(tput lines)

        local end=$((offset + window_size - 1))
        ((end >= total)) && end=$((total - 1))

        tput cup 5 0
        for ((i = offset; i <= end; i++)); do
            local base=${MEDIA_FILES[i]##*/}
            if ((i == index)); then
                printf "%s\n" "$(center_text " ${REVERSE}${BOLD}> $base${RESET}")"
            else
                printf "%s\n" "$(center_text "   $base")"
            fi
        done
        for ((i = end + 1; i < offset + window_size; i++)); do
            printf "%s\n" "$(center_text "")"
        done
        printf '\n'

        # Status line
        echo "${DIM}${YELLOW}Total: $total${RESET}"

        # Usage line (all in one line)
        echo "${BOLD}${BLUE}Usage:${RESET} j/k=nav, Enter=play, /=search, u=update covers, r=rename, c=cleanup, s=search&play, q=quit"
        
        tput ed
    }

    draw_window

    local socket="/tmp/mpv-socket"
    local mpv_pid=""

    while true; do
        IFS= read -rsn1 key
        case "$key" in
        j)
            ((index < total - 1)) && ((index++))
            ((index >= offset + window_size)) && ((offset++))
            draw_window
            ;;
        k)
            ((index > 0)) && ((index--))
            ((index < offset)) && ((offset--))
            draw_window
            ;;
        g) if [[ $last_key == "g" ]]; then
            index=0
            offset=0
            draw_window
            last_key=""
            continue
        fi ;;
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
        "") # Enter: play file
            local file="${MEDIA_FILES[index]}"
            [ -e "$socket" ] && rm -f "$socket"
            download_cover "$file"
            CURRENT_TITLE="${file##*/}"
            show_header
            mpv --quiet --no-terminal --osd-level=0 \
                --input-ipc-server="$socket" \
                "$file" &
            mpv_pid=$!
            ;;
        q) # quit playback or quit browser
            if [[ -n $mpv_pid ]] && kill -0 $mpv_pid 2>/dev/null; then
                printf '{ "command": ["quit"] }\n' | socat - "$socket" >/dev/null
                kill -9 "$mpv_pid" 2>/dev/null
                wait $mpv_pid 2>/dev/null
                mpv_pid=""
                clear
                draw_window
            else
                clear
                break
            fi ;;
        p) [[ -n $mpv_pid ]] && printf '{ "command": ["cycle", "pause"] }\n' | socat - "$socket" >/dev/null ;;
        h) [[ -n $mpv_pid ]] && printf '{ "command": ["seek", -10] }\n' | socat - "$socket" >/dev/null ;;
        l) [[ -n $mpv_pid ]] && printf '{ "command": ["seek", 10] }\n' | socat - "$socket" >/dev/null ;;
        L) if [[ -n $mpv_pid ]]; then
            current=$(printf '{ "command": ["get_property", "loop-file"] }\n' | socat - "$socket" | jq -r '.data // "no"')
            if [[ $current == "inf" || $current == "yes" || $current == "true" ]]; then
                printf '{ "command": ["set_property", "loop-file", "no"] }\n' | socat - "$socket" >/dev/null
            else
                printf '{ "command": ["set_property", "loop-file", "inf"] }\n' | socat - "$socket" >/dev/null
            fi
        fi ;;
        u)
            update_covers
            draw_window
            ;;
        r)
            normalize_music_filenames
            draw_window
            ;;
        c)
            cleanup_orphan_covers
            draw_window
            ;;
        s)
            search_and_play
            draw_window
            ;;
        esac
        last_key="$key"
    done

    tput cnorm
}

# Main function
main() {
    local music_dir="$HOME/Downloads/Telegram Desktop"

    # Parse arguments
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
            echo "  +/-       Volume up/down"
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

    # Dependency check
    local -a required=(mpv jq socat)
    local missing=()
    for dep in "${required[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    if ((${#missing[@]} > 0)); then
        echo "${RED}Error: Missing required dependencies: ${missing[*]}${RESET}"
        exit 1
    fi

    # Optional tools
    local -a optional=(chafa ascii-image-converter kitty viu)
    local found_opt=()
    for dep in "${optional[@]}"; do
        command -v "$dep" &>/dev/null && found_opt+=("$dep")
    done
    if ((${#found_opt[@]} == 0)); then
        echo "${YELLOW}Note: No terminal image viewer found.${RESET}"
        echo "${YELLOW}Consider installing one of these: chafa, ascii-image-converter, viu.${RESET}"
    fi

    # Start browser with chosen directory
    browse_files "$music_dir"
}

# Trap Ctrl+C for clean exit
# Define a cleanup function
cleanup() {
    tput cnorm 2>/dev/null
    rm -f /tmp/mpv-socket
    clear
    echo -e "\n${YELLOW}Goodbye!${RESET}"
    pkill -f "mpv --quiet" 2>/dev/null
    exit 0
}
trap cleanup INT TERM

# Run main function
main "$@"
