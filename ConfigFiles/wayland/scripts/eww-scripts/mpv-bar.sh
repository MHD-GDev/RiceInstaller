#!/bin/bash

readonly SOCKET="/tmp/mpv-socket"
readonly MUSIC_DIR="$HOME/Downloads/Telegram Desktop"
readonly EXTENSIONS="mp3 flac wav ogg m4a"
readonly PLAYER_FLAGS=(--quiet --no-terminal --no-video --audio-display=no --force-window=no --image-display-duration=0)

# Check if mpv is already running with IPC
is_mpv_running() {
    [[ -S $SOCKET ]] && socat - "$SOCKET" <<<'{ "command": ["get_property", "filename"] }' &>/dev/null
}

# Launch mpv with IPC if not running
start_mpv() {
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$MUSIC_DIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) -print0)

    ((${#files[@]} == 0)) && {
        notify-send "MPV Notify" "No music files found in $MUSIC_DIR"
        exit 1
    }

    mpv "${PLAYER_FLAGS[@]}" \
        --input-ipc-server="$SOCKET" \
        "${files[0]}" &
    sleep 0.5
}

# Send current track notification
notify_current_track() {
    local title
    title=$(socat - "$SOCKET" <<<'{ "command": ["get_property", "media-title"] }' | jq -r '.data')
    notify-send "Now Playing" "$title"
}

# Control commands
send_cmd() {
    local cmd="$1"
    socat - "$SOCKET" <<<"$cmd" &>/dev/null
}

# Main logic
case "$1" in
--pause)
    is_mpv_running && send_cmd '{ "command": ["cycle", "pause"] }' && notify-send "MPV" "Toggled pause"
    ;;
--next)
    is_mpv_running && send_cmd '{ "command": ["playlist-next"] }' && notify_current_track
    ;;
--prev)
    is_mpv_running && send_cmd '{ "command": ["playlist-prev"] }' && notify_current_track
    ;;
--stop)
    is_mpv_running && send_cmd '{ "command": ["quit"] }' && notify-send "MPV" "Stopped playback"
    ;;
*)
    if is_mpv_running; then
        notify_current_track
    else
        start_mpv
        notify_current_track
    fi
    ;;
esac
