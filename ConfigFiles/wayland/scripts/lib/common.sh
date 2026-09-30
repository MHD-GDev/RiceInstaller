#!/usr/bin/env bash
# ┌─ COMMON ─┐
#
# Shared helpers for the wayland scripts.
#
# Sourced, never executed. Every script that needs it does:
#
#     _lib=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
#     . "$_lib/lib/common.sh"
#
# so the whole scripts/ directory stays relocatable and keeps working when the
# rice is installed somewhere other than ~/.config/wayland.
#
# This file only defines variables and functions. It deliberately does not
# touch `set` options, traps, or the current directory, so sourcing it cannot
# change how a calling script behaves.

# Where this library and the scripts/ directory live.
COMMON_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WAYLAND_SCRIPTS_DIR="$(dirname -- "$COMMON_LIB_DIR")"

# Config root. Env-overridable so the rice can be installed elsewhere.
WAYLAND_DIR="${WAYLAND_DIR:-$HOME/.config/wayland}"

WAYLAND_THEMES_DIR="$WAYLAND_SCRIPTS_DIR/rofi-themes"
RICE_STATE_FILE="$WAYLAND_DIR/.current_rice"
WALLPAPER_STATE_FILE="$WAYLAND_DIR/.current_wallpaper"
RANDOM_TOGGLE_FILE="$WAYLAND_DIR/.random_wall_toggle"

# Fallback rice when no state file exists yet. Same value the scripts shipped
# with before, so first-run behaviour is unchanged.
DEFAULT_RICE="${DEFAULT_RICE:-Bubble}"

# ── notifications ───────────────────────────────────────────────────────────
# notify <summary> <body> [urgency]
# Kept dependency-free, and never allowed to write to stdout: several callers
# capture stdout from a pipeline, and a chatty notify-send would corrupt it.
# Set NOTIFY_DEBUG=1 to allow stderr output for debugging.
notify() {
    local summary="${1-}" body="${2-}" urgency="${3-}"
    command -v notify-send >/dev/null 2>&1 || return 0
    if [[ -n ${NOTIFY_DEBUG:-} ]]; then
        if [[ -n $urgency ]]; then
            notify-send "$summary" "$body" -u "$urgency" || true
        else
            notify-send "$summary" "$body" || true
        fi
    else
        if [[ -n $urgency ]]; then
            notify-send "$summary" "$body" -u "$urgency" >/dev/null 2>&1 || true
        else
            notify-send "$summary" "$body" >/dev/null 2>&1 || true
        fi
    fi
}

# rofi_error <message> - the rofi-native way these scripts report problems
# (identical wording to the old inline `rofi -e` calls).
rofi_error() {
    command -v rofi >/dev/null 2>&1 || {
        printf '%s\n' "${1-}" >&2
        return 0
    }
    rofi -e "${1-}" || true
}

# require_cmd <cmd>...
# Same notification text the rice has always used for missing packages.
require_cmd() {
    local app missing=()
    for app in "$@"; do
        command -v "$app" >/dev/null 2>&1 || missing+=("$app")
    done
    if ((${#missing[@]})); then
        notify "Missing package" "Please install ${missing[*]}" critical
        return 1
    fi
    return 0
}

# ── rice state ──────────────────────────────────────────────────────────────
# current_rice: print the active rice, falling back to $DEFAULT_RICE.
current_rice() {
    local rice=""
    if [[ -r $RICE_STATE_FILE ]]; then
        IFS= read -r rice <"$RICE_STATE_FILE" || rice=""
    fi
    printf '%s\n' "${rice:-$DEFAULT_RICE}"
}

# valid_rice <name>: true when the name is a real directory under rices/.
valid_rice() {
    local name="${1-}"
    [[ -n $name && $name != */* && $name != .* ]] || return 1
    [[ -d "$WAYLAND_DIR/rices/$name" ]]
}

# ── wallpapers ──────────────────────────────────────────────────────────────
# wallpaper_path: print the wallpaper currently applied, if any.
wallpaper_path() {
    local path=""
    [[ -r $WALLPAPER_STATE_FILE ]] && IFS= read -r path <"$WALLPAPER_STATE_FILE"
    printf '%s\n' "$path"
}

# write_line <file> <line>: write a single line atomically.
write_line() {
    local file="$1" line="${2-}"
    [[ -n $file ]] || return 1
    mkdir -p -- "$(dirname -- "$file")" 2>/dev/null || true
    local tmp="$file.$$.tmp"
    printf '%s\n' "$line" >"$tmp" && mv -f -- "$tmp" "$file"
}

# ── services ────────────────────────────────────────────────────────────────
# service_running <name>
service_running() {
    pgrep -x "${1-}" >/dev/null 2>&1
}

# stop_service <name> [signal]: exact-name match, then wait for it to go away.
stop_service() {
    local name="${1-}" signal="${2-TERM}" waited=0
    service_running "$name" || return 0
    pkill -x "$signal" "$name" 2>/dev/null || true
    while service_running "$name" && ((waited < 30)); do
        sleep 0.1
        waited=$((waited + 1))
    done
    return 0
}

# service_reload <name>: ask a running service to re-read its config.
service_reload() {
    local name="${1-}"
    service_running "$name" || return 0
    pkill -USR1 -x "$name" 2>/dev/null || true
    return 0
}

# ── rofi ────────────────────────────────────────────────────────────────────
# No rofi keybinding flags anywhere. Every menu uses rofi's own default
# navigation: arrows to move, Return to accept, Escape to cancel. The themes in
# rofi-themes/ carry no key-nav block, and the scripts pass no -kb-* flags, so
# nothing here restates the bindings and the menus cannot drift apart.

# rofi_icon_size: pixels for a 1080p-ish menu icon, matching the rice's
# historical formula (width * 17 / 96).
#
# The old `xrandr | awk ... | cut ...` chain broke on any output where the
# resolution field is not literally "1920x1080" - Hyprland/other compositors
# append flags such as "primary", which made the arithmetic fail and killed
# the whole script. Parse it in shell and fall back to a sane width instead.
rofi_icon_size() {
    local width="" line field
    if command -v xrandr >/dev/null 2>&1; then
        while IFS= read -r line; do
            [[ $line == *" connected"* ]] || continue
            # fields: <name> connected [primary] <W>x<H>+<X>+<Y> ...
            for field in $line; do
                if [[ $field =~ ^[0-9]+x[0-9]+ ]]; then
                    width="${field%%x*}"
                    break 2
                fi
            done
        done < <(xrandr 2>/dev/null || true)
    fi
    [[ $width =~ ^[0-9]+$ ]] || width=1920
    printf '%s' "$((width * 17 / 96))"
}

# rofi_theme_override <size>: the -theme-str rofi themes expect for icons.
rofi_theme_override() {
    printf 'element-icon { size: %spx; }' "${1:-340}"
}

# ── symlinks ────────────────────────────────────────────────────────────────
# link_config <source> <dest>
# Point <dest> at <source>. An existing real file or directory is moved aside
# to <dest>.replaced instead of being deleted, so hand made configs are never
# lost. Prints a one line note on stderr when it moves something.
link_config() {
    local source="$1" dest="$2"
    local label="${LINK_CONFIG_LABEL:-link_config}"
    if [[ ! -e $source ]]; then
        # A rice that has not been filled in yet must not abort the whole apply.
        printf '%s: %s missing, leaving %s alone\n' "$label" "$source" "$dest" >&2
        return 0
    fi
    # readlink -f on both sides: a symlink that already resolves to the same
    # file is left completely alone, however it was reached.
    if [[ -L $dest && $(readlink -f -- "$dest") == "$(readlink -f -- "$source")" ]]; then
        return 0
    fi
    mkdir -p -- "$(dirname -- "$dest")" || return 1
    if [[ -e $dest && ! -L $dest ]]; then
        local backup="$dest.replaced"
        rm -rf -- "$backup"
        if ! mv -T -- "$dest" "$backup" 2>/dev/null; then
            rm -rf -- "$dest"
            backup=""
        fi
        printf '%s: moved the old %s to %s\n' "$label" "$dest" "${backup:-/dev/null}" >&2
    fi
    ln -sfnT -- "$source" "$dest"
}
