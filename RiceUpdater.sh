#!/usr/bin/env bash
# RiceUpdater - backup-first, per-file updater for an installed RiceInstaller.
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/tui.sh"
source "$SCRIPT_DIR/lib/state.sh"
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
die() { printf '%s[error]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
[[ $(id -u) -ne 0 ]] || die "Run this updater as your normal user, not root."
command -v git >/dev/null 2>&1 || die "git is required."
git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "RiceInstaller directory is not a Git checkout."
# Do not silently follow top-level symlinks into unrelated configuration
# trees. File-level symlinks are handled as explicit per-file conflicts below.
for managed_path in     "$HOME/.config"     "$HOME/.config/wayland"     "$HOME/.config/hypr"     "$HOME/.config/nvim"     "$HOME/.config/Code"     "$HOME/.config/fcitx5"     "$HOME/.local/share"     "$HOME/.local/share/fonts"; do
    [[ ! -L $managed_path ]] || die "$managed_path is a symlink. Resolve it before running the updater; no files were changed."
done
ri_state_init
ri_banner
printf 'This updater backs up installed configuration before migration.\n'
printf 'Customized files are never silently overwritten.\n\n'

branch="$(git -C "$SCRIPT_DIR" branch --show-current)"
[[ -n $branch ]] || die "Could not determine the current Git branch."
[[ -z $(git -C "$SCRIPT_DIR" status --porcelain) ]] || {
    git -C "$SCRIPT_DIR" status --short
    die "Your checkout has local changes. Commit or back them up before updating."
}
ri_confirm "Check upstream for updates on '$branch'?" || exit 0
git -C "$SCRIPT_DIR" fetch --prune origin
old_commit="$(git -C "$SCRIPT_DIR" rev-parse HEAD)"
remote_ref="origin/$branch"
git -C "$SCRIPT_DIR" show-ref --verify --quiet "refs/remotes/$remote_ref" || die "Remote branch $remote_ref was not found."
new_commit="$(git -C "$SCRIPT_DIR" rev-parse "$remote_ref")"
[[ $old_commit != "$new_commit" ]] || { printf '%sAlready up to date.%s\n' "$GREEN" "$RESET"; exit 0; }
git -C "$SCRIPT_DIR" merge-base --is-ancestor "$old_commit" "$new_commit" || die "Local and upstream branches have diverged; no files were changed."
printf 'Upstream has %s new commit(s).\n' "$(git -C "$SCRIPT_DIR" rev-list --count "$old_commit..$new_commit")"
git -C "$SCRIPT_DIR" --no-pager log --oneline "$old_commit..$new_commit"
printf '\n'
ri_confirm "Create a full backup and review configuration updates?" || exit 0

stamp="$(date +%Y%m%d-%H%M%S)-$$"
backup_root="$HOME/.local/share/RiceInstaller/backups/$stamp"
mkdir -p "$backup_root/checkout" "$backup_root/config" "$backup_root/conflicts"
chmod 700 "$backup_root"
git -C "$SCRIPT_DIR" bundle create "$backup_root/checkout/pre-update.bundle" --all
printf '%s\n' "$old_commit" >"$backup_root/checkout/previous-commit"
printf '%s\n' "$new_commit" >"$backup_root/checkout/target-commit"

for rel in .config/hypr/hyprland.lua .config/wayland .config/nvim .config/Code/User .zshrc; do
    src="$HOME/$rel"
    [[ -e $src || -L $src ]] || continue
    dest="$backup_root/config/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -a --no-dereference "$src" "$dest"
done
printf '\nBackup created: %s\n' "$backup_root"

# Identify user-created/foreign rice entries without claiming ownership or
# modifying them. The active Waybar link and runtime state files are generated
# by rice-selector, so they are intentionally excluded.
if [[ -d "$HOME/.config/wayland" ]]; then
    foreign_entries=()
    for entry in "$HOME/.config/wayland"/* "$HOME/.config/wayland"/.[!.]*; do
        [[ -e $entry || -L $entry ]] || continue
        name="${entry##*/}"
        case "$name" in
            waybar|.current_rice|.current_wallpaper|.random_wall_toggle) continue ;;
        esac
        [[ -e "$SCRIPT_DIR/ConfigFiles/wayland/$name" ]] || foreign_entries+=("$name")
    done
    if (("${#foreign_entries[@]}" > 0)); then
        printf '\n%sUnmanaged/foreign entries detected in ~/.config/wayland:%s\n' "$YELLOW" "$RESET"
        printf '  %s\n' "${foreign_entries[@]}"
        printf 'These entries will be left untouched.\n'
    fi
fi
if [[ -d "$HOME/.config/wayland/rices" ]]; then
    for rice_dir in "$HOME/.config/wayland/rices"/*; do
        [[ -d $rice_dir ]] || continue
        rice_name="${rice_dir##*/}"
        if [[ ! -d "$SCRIPT_DIR/ConfigFiles/wayland/rices/$rice_name" ]]; then
            printf '%sForeign/custom rice preserved: %s%s\n' "$YELLOW" "$rice_name" "$RESET"
        fi
    done
fi

# Map repository paths to their installed locations. We intentionally do not
# remove files deleted upstream: user-created files are not ours to delete.
map_destination() {
    local rel="$1"
    case "$rel" in
        ConfigFiles/*) printf '%s/.config/%s' "$HOME" "${rel#ConfigFiles/}" ;;
        IDE/nvim/*) printf '%s/.config/nvim/%s' "$HOME" "${rel#IDE/nvim/}" ;;
        IDE/User/*) printf '%s/.config/Code/User/%s' "$HOME" "${rel#IDE/User/}" ;;
        .zshrc) printf '%s/.zshrc' "$HOME" ;;
        profile) printf '%s/.config/fcitx5/profile' "$HOME" ;;
        fonts/*) printf '%s/.local/share/fonts/%s' "$HOME" "${rel#fonts/}" ;;
        *) return 1 ;;
    esac
}
is_runtime_state() {
    case "$1" in
        ConfigFiles/wayland/.current_rice|ConfigFiles/wayland/.current_wallpaper|ConfigFiles/wayland/.random_wall_toggle|ConfigFiles/wayland/zsh/.histfile*|ConfigFiles/wayland/zsh/zcompdump*) return 0 ;;
        *) return 1 ;;
    esac
}
install_upstream_file() {
    local source="$1" dest="$2" mode="$3" tmp
    mkdir -p "$(dirname "$dest")"
    tmp="$dest.riceinstaller-update.$$"
    case "$mode" in
        120000)
            ln -s -- "$(cat "$source")" "$tmp"
            ;;
        100755)
            install -m 755 -- "$source" "$tmp"
            ;;
        *)
            install -m 644 -- "$source" "$tmp"
            ;;
    esac
    mv -fT -- "$tmp" "$dest"
}
mapfile -t changed_files < <(git -C "$SCRIPT_DIR" diff --name-only --diff-filter=ACMRT "$old_commit" "$new_commit" -- ConfigFiles IDE .zshrc profile fonts)
migrated=0 kept=0 skipped=0
for rel in "${changed_files[@]}"; do
    [[ -n $rel ]] || continue
    if is_runtime_state "$rel"; then
        printf 'Keeping runtime state: %s\n' "$rel"
        ((skipped+=1))
        continue
    fi
    dest="$(map_destination "$rel")" || { printf 'No automatic install mapping for %s; leaving it alone.\n' "$rel"; ((skipped+=1)); continue; }
    if git -C "$SCRIPT_DIR" cat-file -e "$new_commit:$rel" 2>/dev/null; then :; else
        printf 'Upstream removed %s; preserving your installed copy.\n' "$rel"
        ((skipped+=1))
        continue
    fi
    tmpdir="$(mktemp -d)"
    new_file="$tmpdir/new"
    old_file="$tmpdir/old"
    new_mode="$(git -C "$SCRIPT_DIR" ls-tree "$new_commit" -- "$rel" | awk '{print $1}')"
    git -C "$SCRIPT_DIR" show "$new_commit:$rel" >"$new_file"
    if git -C "$SCRIPT_DIR" cat-file -e "$old_commit:$rel" 2>/dev/null; then
        git -C "$SCRIPT_DIR" show "$old_commit:$rel" >"$old_file"
        have_old=yes
    else
        have_old=no
    fi

    if [[ ! -e $dest && ! -L $dest ]]; then
        install_upstream_file "$new_file" "$dest" "$new_mode"
        printf '%s[added]%s %s\n' "$GREEN" "$RESET" "$dest"
        ((migrated+=1))
        rm -rf "$tmpdir"
        continue
    fi
    # Already migrated in a previous interrupted run.
    if [[ $new_mode == 120000 && -L $dest && $(readlink -- "$dest") == "$(cat "$new_file")" ]]; then
        rm -rf "$tmpdir"
        continue
    fi
    if [[ $new_mode != 120000 && -f $dest && ! -L $dest ]] && cmp -s "$new_file" "$dest"; then
        rm -rf "$tmpdir"
        continue
    fi
    # Safe automatic migration only when installed content still matches the
    # previous upstream version exactly. Symlinks are treated as customized.
    if [[ $have_old == yes && -f $dest && ! -L $dest ]] && cmp -s "$old_file" "$dest"; then
        install_upstream_file "$new_file" "$dest" "$new_mode"
        printf '%s[updated]%s %s (unchanged from previous default)\n' "$GREEN" "$RESET" "$dest"
        ((migrated+=1))
        rm -rf "$tmpdir"
        continue
    fi

    printf '\n%sCustomized file detected:%s %s\n' "$YELLOW" "$RESET" "$dest"
    if [[ $have_old == yes && -f $dest && ! -L $dest ]]; then
        printf '\n--- Your current changes compared with previous upstream ---\n'
        diff -u "$old_file" "$dest" || true
        printf '\n--- New upstream version compared with previous upstream ---\n'
        diff -u "$old_file" "$new_file" || true
    else
        printf 'This file is a symlink, directory, or has no previous upstream version.\n'
    fi
    while :; do
        action="$(ri_choose "How should this file be handled?" "Keep my current file" "Replace with upstream version")" || action="Keep my current file"
        case "$action" in
            "Keep my current file") ((kept+=1)); break ;;
            "Replace with upstream version")
                if [[ -d $dest && ! -L $dest ]]; then
                    printf 'Destination is a directory; refusing to replace it as a file.\n'
                    ((skipped+=1))
                    break
                fi
                if [[ -e $dest || -L $dest ]]; then
                    conflict_backup="$backup_root/conflicts/$rel"
                    mkdir -p "$(dirname "$conflict_backup")"
                    cp -a --no-dereference "$dest" "$conflict_backup"
                    rm -f -- "$dest"
                fi
                install_upstream_file "$new_file" "$dest" "$new_mode"
                printf '%s[replaced]%s %s (original preserved in backup)\n' "$GREEN" "$RESET" "$dest"
                ((migrated+=1))
                break
                ;;
        esac
    done
    rm -rf "$tmpdir"
done

# The checkout is advanced only after file migration completes. If interrupted
# before this point, running the updater again safely skips already migrated
# files and resumes the remaining prompts.
git -C "$SCRIPT_DIR" merge --ff-only "$remote_ref"

# Package updates are a separate opt-in action. A system package transaction
# cannot be reliably rolled back by restoring dotfiles, so never run it silently.
if command -v paru >/dev/null 2>&1; then
    if ri_confirm "Also update installed Arch and AUR packages with paru -Syu?"; then
        if paru -Syu --needed --noconfirm; then
            printf '%sPackage update completed.%s\n' "$GREEN" "$RESET"
        else
            printf '%sPackage update failed; the rice files and checkout remain updated.%s\n' "$YELLOW" "$RESET"
        fi
    fi
elif command -v pacman >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    if ri_confirm "Also update installed Arch packages with pacman -Syu?"; then
        if sudo pacman -Syu --needed --noconfirm; then
            printf '%sPackage update completed.%s\n' "$GREEN" "$RESET"
        else
            printf '%sPackage update failed; the rice files and checkout remain updated.%s\n' "$YELLOW" "$RESET"
        fi
    fi
fi

printf '\n%sUpdater finished.%s\n' "$GREEN" "$RESET"
printf 'Migrated: %d | Kept: %d | Skipped: %d\n' "$migrated" "$kept" "$skipped"
printf 'Backup: %s\n' "$backup_root"
printf '%s\t%s\t%s\n' "$(date --iso-8601=seconds)" "updater" "updated:$old_commit..$new_commit" >>"$RI_HISTORY_DIR/events.log"
