#!/usr/bin/env bash
# Persistent installation state. One marker file per successful step avoids
# fragile JSON parsing and makes each state transition atomic.
RI_STATE_DIR="${RI_STATE_DIR:-$HOME/.local/state/riceinstaller}"
RI_STEPS_DIR="$RI_STATE_DIR/steps"
RI_HISTORY_DIR="$RI_STATE_DIR/history"
RI_SELECTIONS="$RI_STATE_DIR/selections.env"
RI_ACTIVE_STEP=""
RI_FAILED_STEP=""
ri_state_init() {
    mkdir -p "$RI_STEPS_DIR" "$RI_HISTORY_DIR"
    chmod 700 "$RI_STATE_DIR" "$RI_STEPS_DIR" "$RI_HISTORY_DIR" 2>/dev/null || true
    [[ -f $RI_SELECTIONS ]] && { # trusted file created by this user
        # shellcheck disable=SC1090
        source "$RI_SELECTIONS"
    }
    return 0
}
ri_save_selections() {
    local tmp="$RI_SELECTIONS.tmp.$$"
    {
        printf 'BUILD_TYPE=%q\n' "${BUILD_TYPE:-}"
        printf 'SDDM_THEME_WANTED=%q\n' "${SDDM_THEME_WANTED:-no}"
        printf 'LLAMA_BUILT=%q\n' "${LLAMA_BUILT:-no}"
        printf 'GPU_CHOICE=%q\n' "${GPU_CHOICE:-}"
        printf 'BRANCH_CHOICE=%q\n' "${BRANCH_CHOICE:-}"
        printf 'VSCODE_CHOICE=%q\n' "${VSCODE_CHOICE:-}"
    } >"$tmp"
    chmod 600 "$tmp"
    mv -f "$tmp" "$RI_SELECTIONS"
}
ri_step_done() { [[ -f "$RI_STEPS_DIR/$1.done" ]]; }
ri_mark_done() {
    local step="$1" tmp="$RI_STEPS_DIR/$1.done.tmp.$$"
    printf 'completed=%s\n' "$(date --iso-8601=seconds)" >"$tmp"
    mv -f "$tmp" "$RI_STEPS_DIR/$1.done"
    rm -f "$RI_STEPS_DIR/$1.failed"
}
ri_mark_failed() {
    local step="$1" message="$2" tmp="$RI_STEPS_DIR/$1.failed.tmp.$$"
    printf 'failed=%s\nmessage=%q\n' "$(date --iso-8601=seconds)" "$message" >"$tmp"
    mv -f "$tmp" "$RI_STEPS_DIR/$1.failed"
    RI_FAILED_STEP="$step"
}
ri_record_exit() {
    local status=$?
    if [[ -n ${RI_ACTIVE_STEP:-} && $status -ne 0 ]]; then
        ri_mark_failed "$RI_ACTIVE_STEP" "Installer exited with status $status"
        printf '%s\t%s\t%s\n' "$(date --iso-8601=seconds)" "$RI_ACTIVE_STEP" "failed:$status" >>"$RI_HISTORY_DIR/events.log"
    fi
    return "$status"
}
ri_clear_progress() {
    rm -f "$RI_STEPS_DIR"/*.done "$RI_STEPS_DIR"/*.failed
    rm -f "$RI_SELECTIONS"
    BUILD_TYPE=""
    SDDM_THEME_WANTED="no"
    LLAMA_BUILT="no"
    GPU_CHOICE=""
    BRANCH_CHOICE=""
    VSCODE_CHOICE=""
}
ri_show_progress() {
    local step
    printf '\nInstallation progress:\n'
    for step in "$@"; do
        if ri_step_done "$step"; then
            printf '  [✓] %s\n' "$step"
        elif [[ -f "$RI_STEPS_DIR/$step.failed" ]]; then
            printf '  [!] %s (failed)\n' "$step"
        else
            printf '  [ ] %s\n' "$step"
        fi
    done
}
ri_backup_snapshot() {
    local target="$1" stamp dest
    stamp="$(date +%Y%m%d-%H%M%S)"
    dest="$HOME/.local/share/RiceInstaller/backups/$stamp"
    mkdir -p "$dest"
    printf '%s\n' "$target" >"$dest/backup-scope.txt"
    if [[ -e $target || -L $target ]]; then
        cp -a --no-dereference "$target" "$dest/"
    fi
    printf '%s\n' "$dest"
}
