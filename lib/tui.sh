#!/usr/bin/env bash
# Shared terminal UI. Uses gum when available, with a dependency-free fallback.
ri_banner() {
    printf '\n\033[1;36m  MHD RICEINSTALLER\033[0m\n'
    printf '\033[90m  Hyprland · Wayland · Recovery-aware setup\033[0m\n\n'
}
ri_choose() {
    local prompt="$1"; shift
    if command -v gum >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
        gum choose --header "$prompt" "$@"
        return
    fi
    local options=("$@") i answer
    printf '%s\n' "$prompt" >&2
    for i in "${!options[@]}"; do printf '  %d) %s\n' "$((i+1))" "${options[$i]}" >&2; done
    while :; do
        printf '> ' >&2
        IFS= read -r answer || return 1
        if [[ $answer =~ ^[0-9]+$ ]] && ((answer>=1 && answer<=${#options[@]})); then
            printf '%s\n' "${options[$((answer-1))]}"
            return 0
        fi
        printf 'Choose a number from 1 to %d.\n' "${#options[@]}" >&2
    done
}
ri_confirm() {
    local prompt="$1" answer
    if command -v gum >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
        gum confirm "$prompt"
        return
    fi
    printf '%s [y/N] ' "$prompt" >&2
    IFS= read -r answer || return 1
    [[ ${answer,,} == y || ${answer,,} == yes ]]
}
ri_pause() {
    [[ -t 0 ]] || return 0
    printf '\nPress Enter to continue...'
    IFS= read -r _ || true
}
