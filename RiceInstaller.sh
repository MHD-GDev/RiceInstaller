#!/usr/bin/env bash
#
# MHD RiceInstaller
#
# Installs the rice (Hyprland config, scripts, nvim, zsh, themes) and offers
# the optional extras: SDDM theme, GRUB theme and a local llama.cpp build.
#
# Every path in this script is resolved from SCRIPT_DIR, so it can be started
# from anywhere: `./RiceInstaller.sh`, an absolute path, or from another
# directory entirely.
#

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

# Bounded retries for the non-interactive steps. The old script wrapped every
# step in `until { ... }`, which only ever inspected the exit status of the
# *last* command in the block, so a failure in the middle was silently
# swallowed and a genuine failure (like a failed package install) re-ran the
# whole block forever.
MAX_ATTEMPTS=3

info() { printf '%s==>%s %s\n' "$CYAN" "$RESET" "$*"; }
ok() { printf '%s[ ok ]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
err() { printf '%s[fail]%s %s\n' "$RED" "$RESET" "$*" >&2; }

screen_clear() {
    [[ -t 1 ]] && command -v clear >/dev/null 2>&1 && clear || true
}

# ask <prompt> -> stores the answer in $ANSWER.
# The prompt goes to stderr on purpose: callers read $ANSWER directly instead
# of using $(ask ...), because inside a command substitution stdout is captured
# and the prompt text would end up glued to the front of the answer.
# Guards against EOF (Ctrl-D), which used to spin a `while true` menu in a
# tight loop printing "Invalid choice" with nothing to type into.
ANSWER=""
ask() {
    printf '%s' "$1" >&2
    if ! IFS= read -r ANSWER; then
        printf '\n' >&2
        err "No input. Aborting."
        exit 1
    fi
}

# ask_yes_no <question> -> returns 0 for yes, 1 for no.
ask_yes_no() {
    local reply=""
    printf '%s [y/N]: ' "$1"
    if ! IFS= read -r reply; then
        printf '\n'
        err "No input. Assuming no."
        return 1
    fi
    case "${reply,,}" in
    y | yes) return 0 ;;
    *) return 1 ;;
    esac
}

# run_step <label> <cmd...>
# Runs a command, retrying up to MAX_ATTEMPTS times with a short backoff.
run_step() {
    local label="$1"
    shift
    local attempt=1
    while true; do
        if "$@"; then
            return 0
        fi
        if ((attempt >= MAX_ATTEMPTS)); then
            err "$label failed after $attempt attempt(s). Moving on."
            return 1
        fi
        warn "$label failed (attempt $attempt/$MAX_ATTEMPTS), retrying in 2s..."
        sleep 2
        attempt=$((attempt + 1))
    done
}

die() {
    err "$*"
    exit 1
}

# ------------------------------------------------------------------ #
# Preconditions                                                       #
# ------------------------------------------------------------------ #

refuse_root() {
    if [[ $(id -u) == 0 ]]; then
        die "Do not run this script as root. Run it as your normal user; it calls sudo where it needs it."
    fi
}

require_sudo() {
    command -v sudo >/dev/null 2>&1 || die "sudo is not installed."
    sudo -n true 2>/dev/null || warn "You will be asked for your password when sudo is needed."
}

require_repo_layout() {
    local missing=()
    local f
    for f in \
        "ConfigFiles" \
        ".zshrc" \
        "profile" \
        "plugins" \
        "fonts" \
        "IDE" \
        "arch-rice-wayland-packs.txt" \
        "LlamaUI-vMHD.html"; do
        [[ -e "$SCRIPT_DIR/$f" ]] || missing+=("$f")
    done
    ((${#missing[@]} == 0)) ||
        die "Incomplete checkout, missing from $SCRIPT_DIR: ${missing[*]}"
}

require_wayland_session() {
    if ! hyprctl version >/dev/null 2>&1; then
        warn "Hyprland does not seem to be running, so config reloads will be skipped."
        warn "Log into your Hyprland session and re-run if something looks stale."
        return 0
    fi

    # This rice ships hyprland.lua, which needs a Hyprland that reads lua
    # configuration. Rather than hardcode a version number that goes stale,
    # detect the capability: `hyprctl repl` and `hyprctl eval` only exist on
    # builds with lua config support.
    if ! hyprctl --help 2>&1 | grep -qE '^[[:space:]]*(repl|eval)'; then
        warn "Your Hyprland ($(hyprland_version)) has no lua configuration support."
        warn "This rice ships hyprland.lua, which that version cannot load."
        warn "Update Hyprland, or expect the compositor to fall back to its defaults."
    fi
}

hyprland_version() {
    hyprctl version 2>/dev/null |
        head -1 |
        awk '{print $2}'
}

# Surface config parse errors after a reload. This is what catches a config
# written for a newer Hyprland than the one running: the syntax is simply
# ignored or rejected, and the window manager silently comes up wrong.
report_config_errors() {
    local errors=""
    errors="$(hyprctl configerrors 2>/dev/null | grep -v '^[[:space:]]*$' || true)"
    if [[ -n $errors ]]; then
        warn "Hyprland reported config problems:"
        printf '%s\n' "$errors" | head -20 | sed 's/^/    /' >&2
        warn "Check 'hyprctl configerrors' for the full list."
    fi
}

reload_hyprland() {
    if hyprctl reload >/dev/null 2>&1; then
        ok "Hyprland configuration reloaded."
        report_config_errors
    else
        warn "Could not reload Hyprland (it may not be running right now)."
    fi
}

# Arch and derivatives (EndeavourOS, CachyOS, Garuda, ...) all report
# ID=arch or ID_LIKE containing "arch" in /etc/os-release.
is_arch_like() {
    [[ -r /etc/os-release ]] || return 1
    local id="" id_like=""
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
    if [[ $id == arch ]]; then
        return 0
    fi
    if [[ " $id_like " == *" arch "* ]]; then
        return 0
    fi
    return 1
}

os_name() {
    [[ -r /etc/os-release ]] || return 0
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s' "${PRETTY_NAME:-${NAME:-unknown}}"
}

# ------------------------------------------------------------------ #
# Prompts                                                             #
# ------------------------------------------------------------------ #

show_banner() {
    printf '%s' "$MAGENTA"
    cat <<'EOF'
        ███╗   ███╗██╗  ██╗██████╗
        ████╗ ████║██║  ██║██╔══██╗
        ██╔████╔██║███████║██║  ██║
        ██║╚██╔╝██║██╔══██║██║  ██║
        ██║ ╚═╝ ██║██║  ██║██████╔╝
        ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝

        MHD rice installer script
EOF
    printf '%s' "$RESET"
    sleep 1
}

show_notice() {
    printf '%sNOTICE:%s This script will modify your %sNeovim (nvim), VSCode and Hyprland%s configuration.\n' \
        "$RED" "$RESET" "$CYAN" "$RESET"
    printf '%sExisting configs are backed up, not deleted.%s\n' "$GREEN" "$RESET"
    printf '%sTip:%s Do not want something? Answer "no" at the matching prompt, or comment it out.\n' "$YELLOW" "$RESET"
    printf '\n'
    if ! ask_yes_no "Do you want to continue?"; then
        info "Installation aborted by user."
        exit 0
    fi
    screen_clear
}

choose_build_type() {
    while true; do
        printf '%sChoose your build type:%s\n' "$YELLOW" "$RESET"
        printf '1) Gaming\n2) Programming\n3) Both\n4) None\n' >&2
        ask 'Enter choice [1-4]: '
        case "$ANSWER" in
        1) BUILD_TYPE="gaming" ;;
        2) BUILD_TYPE="programming" ;;
        3) BUILD_TYPE="both" ;;
        4) BUILD_TYPE="none" ;;
        *)
            err "Invalid choice. Try again."
            continue
            ;;
        esac
        break
    done
    ok "Build type set to: $BUILD_TYPE"
    sleep 1
    screen_clear
}

# ------------------------------------------------------------------ #
# Install steps                                                       #
# ------------------------------------------------------------------ #

create_user_dirs() {
    info "Creating user directories..."
    mkdir -p "$HOME"/{Downloads,Documents,Pictures,Videos,Music,Desktop,Templates,MyNotes}
    case "$BUILD_TYPE" in
    gaming) mkdir -p "$HOME"/{Games,Emulations,Comics,Manga} ;;
    programming) mkdir -p "$HOME/Projects" ;;
    both) mkdir -p "$HOME"/{Projects,Games,Emulations,Comics,Manga} ;;
    none) ;;
    esac
    ok "User directories created."
    sleep 1
    screen_clear
}

ensure_paru() {
    command -v paru >/dev/null 2>&1 && return 0
    info "paru not found, building it from the AUR..."
    command -v git >/dev/null 2>&1 || die "git is required to build paru but is not installed."
    # Clone into SCRIPT_DIR and build in place with makepkg --dir, instead of
    # cd'ing into the clone. The old `cd paru && ... || false; cd ..` walked
    # out of the repository whenever paru/ already existed, breaking every
    # later step that uses a relative path.
    if [[ ! -d "$SCRIPT_DIR/paru/.git" ]]; then
        run_step "cloning paru" git clone --depth 1 https://aur.archlinux.org/paru.git "$SCRIPT_DIR/paru" ||
            die "Could not clone paru."
    fi
    run_step "installing paru" makepkg -Csi --noconfirm --dir "$SCRIPT_DIR/paru" ||
        die "Could not install paru."
    command -v paru >/dev/null 2>&1 || die "paru still not on PATH after install."
}

# install_packs <file>
# `--needed` keeps a re-run cheap and makes the script idempotent.
install_packs() {
    local file="$SCRIPT_DIR/$1"
    [[ -f "$file" ]] || {
        warn "Missing $1, skipping."
        return 1
    }
    # shellcheck disable=SC2046 # deliberate word splitting: one package per line
    run_step "installing packages from $1" paru -S --needed --noconfirm $(<"$file")
}

install_packages() {
    if ! is_arch_like; then
        warn "$(os_name) is not an Arch-based distribution, so the package step is skipped."
        warn "Install the packages yourself:"
        warn "  paru -Syu --needed --noconfirm \$(cat arch-rice-wayland-packs.txt)"
        warn "Everything else in this script still works."
        return 0
    fi

    info "Installing required packages on $(os_name)..."
    command -v pacman >/dev/null 2>&1 || die "pacman not found on an Arch-based system?"

    run_step "system upgrade" sudo pacman -Syu --noconfirm || warn "System upgrade reported problems."
    run_step "installing git" sudo pacman -S --needed --noconfirm git ||
        die "git is required to continue."
    ensure_paru

    install_packs arch-rice-wayland-packs.txt
    sleep 1
    screen_clear

    install_gpu_packages
    install_branch_packages
    sleep 1
    screen_clear
}

install_gpu_packages() {
    info "Selecting your GPU..."
    printf '1) Nvidia\n2) Intel\n3) AMD\n4) Hybrid (AMD & Nvidia)\n5) Skip\n' >&2
    ask 'Enter choice [1-5]: '
    case "$ANSWER" in
    1) install_packs_list "nvidia-cg-toolkit nvidia nvidia-utils cuda-tools cuda" ;;
    2)
        install_packs_list "vulkan-intel intel-oneapi-basekit"
        if [[ -f /opt/intel/oneapi/setvars.sh ]]; then
            # shellcheck disable=SC1091
            source /opt/intel/oneapi/setvars.sh
            ok "Intel oneAPI environment initialized."
        else
            warn "/opt/intel/oneapi/setvars.sh not found, oneAPI environment not initialized."
        fi
        ;;
    3) install_packs_list "amdsmi amdvlk radeontop radeontool" ;;
    4) install_packs_list "amdsmi amdvlk radeontop radeontool nvidia-cg-toolkit nvidia nvidia-utils cuda-tools cuda" ;;
    5)
        info "Skipping GPU packages."
        return 0
        ;;
    *) die "Invalid GPU choice." ;;
    esac
}

# install_packs_list "<space separated packages>"
install_packs_list() {
    # shellcheck disable=SC2086 # deliberate: $1 is a package list
    run_step "installing GPU packages" paru -S --needed --noconfirm $1
}

install_branch_packages() {
    info "Selecting your branch type..."
    printf '1) Gamedev\n2) Gaming\n3) Programmer\n4) Steam Deck\n5) None\n' >&2
    ask 'Enter choice [1-5]: '
    local file=""
    case "$ANSWER" in
    1) file="gamedev-branch-packs.txt" ;;
    2) file="gaming-branch-packs.txt" ;;
    3) file="Programmer-branch-packs.txt" ;;
    4) file="steamdeck-branch-packs.txt" ;;
    5)
        info "Skipping additional branch packages."
        return 0
        ;;
    *) die "Invalid branch choice." ;;
    esac
    install_packs "$file"
}

copy_configs() {
    [[ -d "$SCRIPT_DIR/ConfigFiles" ]] || die "Missing ConfigFiles directory in $SCRIPT_DIR."

    info "Copying rice directories..."

    # ~/.config does not exist at all on a minimal install, and `cp -r src/ dst/`
    # fails with "No such file or directory" rather than creating it.
    mkdir -p "$HOME/.config"

    # Back up the current Hyprland config instead of assuming a name is free.
    # `cp -a` preserves symlinks and permissions. The old `cp ~/.config/hypr
    # ~/.config/hypr.bak` was missing -r (so it always failed and skipped the
    # real copy), and on a second run it nested hypr.bak/hypr/... on top of the
    # first backup.
    if [[ -d "$HOME/.config/hypr" ]]; then
        local stamp backup
        stamp="$(date +%Y%m%d-%H%M%S)"
        backup="$HOME/.config/hypr.bak-$stamp"
        run_step "backing up ~/.config/hypr" cp -a "$HOME/.config/hypr" "$backup" ||
            warn "Could not back up ~/.config/hypr, continuing anyway."
        ok "Existing hypr config backed up to $backup"
    fi

    # Copy everything except the directory's own README.md, so it does not
    # land in ~/.config. The old script achieved this by `rm -rf`ing a tracked
    # file out of the repository, which dirtied the checkout on every run.
    local -a items=()
    local item=""
    while IFS= read -r -d '' item; do
        items+=("$item")
    done < <(find -H "$SCRIPT_DIR/ConfigFiles" -mindepth 1 -maxdepth 1 ! -name 'README.md' -print0)

    ((${#items[@]} > 0)) || die "ConfigFiles is empty."
    run_step "copying ConfigFiles to ~/.config" cp -r "${items[@]}" "$HOME/.config/" ||
        die "Could not copy the config files."

    if [[ -f "$SCRIPT_DIR/profile" ]]; then
        mkdir -p "$HOME/.config/fcitx5"
        cp -r "$SCRIPT_DIR/profile" "$HOME/.config/fcitx5/profile"
    fi

    ok "Config directories copied."
    sleep 1
    reload_hyprland
    screen_clear
}

vscode_rice() {
    info "Setting up VSCode rice..."
    # VSCode reads ~/.config/Code/User/settings.json, so IDE/User has to be
    # copied into ~/.config/Code. Copying it to ~/.config/ instead would put
    # settings.json somewhere VSCode never looks.
    mkdir -p "$HOME/.config/Code"
    if [[ -d "$SCRIPT_DIR/IDE/User" ]]; then
        cp -r "$SCRIPT_DIR/IDE/User" "$HOME/.config/Code"
    fi

    if [[ -f "$SCRIPT_DIR/IDE/User/extensions.txt" ]]; then
        if command -v code >/dev/null 2>&1; then
            # `cat | xargs` would also pass an empty argument if the file ever
            # gained a blank line, so read the file in a loop instead.
            local ext
            while IFS= read -r ext; do
                [[ -n $ext ]] || continue
                run_step "installing extension $ext" code --install-extension "$ext"
            done <"$SCRIPT_DIR/IDE/User/extensions.txt"
        else
            warn "VSCode ('code') is not on PATH, skipping extension installation."
            warn "Extensions to install are listed in IDE/User/extensions.txt."
        fi
    else
        info "No extensions.txt found, skipping extension installation."
    fi
    ok "VSCode rice setup complete."
    sleep 1
    screen_clear
}

nvim() {
    info "Setting up Neovim rice..."
    [[ -d "$SCRIPT_DIR/IDE/nvim" ]] || die "Missing IDE/nvim directory in $SCRIPT_DIR."
    cp -r "$SCRIPT_DIR/IDE/nvim" "$HOME/.config/nvim"
    ok "Neovim rice setup complete."
    sleep 1
    screen_clear
}

copy_zshrc() {
    info "Copying .zshrc into your home directory..."
    [[ -f "$SCRIPT_DIR/.zshrc" ]] || die "Missing .zshrc in $SCRIPT_DIR."
    cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

    if [[ -d "$SCRIPT_DIR/plugins" ]]; then
        # .zshrc sources /usr/share/zsh/plugins/<name>/<name>.zsh, so the
        # plugins directory has to end up at exactly that path. Create it
        # explicitly instead of letting cp -r invent it on a non-standard
        # zsh prefix, where the sources would silently fail.
        local zsh_dir="/usr/share/zsh"
        if [[ ! -d "$zsh_dir" ]]; then
            run_step "creating $zsh_dir" sudo install -d -m 755 "$zsh_dir" ||
                warn "Could not create $zsh_dir."
        fi
        if [[ -d "$zsh_dir" ]]; then
            sudo install -d -m 755 "$zsh_dir/plugins"
            local p
            for p in "$SCRIPT_DIR"/plugins/*/; do
                sudo cp -r "$p" "$zsh_dir/plugins/"
            done
            ok "zsh plugins installed to $zsh_dir/plugins"
        fi
    fi

    if [[ -d "$SCRIPT_DIR/fonts" ]]; then
        mkdir -p "$HOME/.local/share/fonts"
        cp -r "$SCRIPT_DIR/fonts/." "$HOME/.local/share/fonts/"
        command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
    fi

    # Archive the bash dotfiles instead of moving them into a stray .bash/
    # directory. The old line was `mkdir .bash && mv .bash_logout .bashrc
    # .bash_profile .bash`, which was relative to the *repo* (so it created
    # junk in the checkout), and `mv` aborts entirely if any one of the three
    # files is missing.
    local f
    local -a found=()
    for f in .bash_logout .bashrc .bash_profile; do
        [[ -e "$HOME/$f" ]] && found+=("$f")
    done
    if ((${#found[@]} > 0)); then
        local backup="$HOME/bash-dotfiles.bak-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup"
        for f in "${found[@]}"; do
            mv "$HOME/$f" "$backup/"
        done
        ok "Existing bash dotfiles moved to $backup"
    fi

    if command -v zsh >/dev/null 2>&1; then
        local zsh_path
        zsh_path="$(command -v zsh)"
        if grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
            run_step "setting your login shell to zsh" chsh -s "$zsh_path"
        else
            warn "$zsh_path is not listed in /etc/shells, leaving your login shell alone."
        fi
    else
        warn "zsh is not installed, skipping the login shell change."
    fi

    ok ".zshrc copied."
    sleep 1
    screen_clear
}

install_sddm_theme() {
    info "Installing the SDDM theme..."
    if ! ask_yes_no "Install the 'Where is my SDDM theme' SDDM theme?"; then
        info "Skipping the SDDM theme."
        SDDM_THEME_WANTED="no"
        sleep 1
        screen_clear
        return 0
    fi
    SDDM_THEME_WANTED="yes"

    command -v git >/dev/null 2>&1 || die "git is required to install the SDDM theme."
    local theme_dir="$SCRIPT_DIR/where-is-my-sddm-theme"
    if [[ ! -d "$theme_dir/.git" ]]; then
        run_step "cloning the SDDM theme" git clone --depth 1 \
            https://github.com/stepanzubkov/where-is-my-sddm-theme.git "$theme_dir" ||
            warn "Could not clone the SDDM theme."
    fi

    if [[ -d "$theme_dir/where_is_my_sddm_theme" ]]; then
        sudo install -d -m 755 /usr/share/sddm/themes
        sudo cp -r "$theme_dir/where_is_my_sddm_theme" /usr/share/sddm/themes
        if [[ -f "$SCRIPT_DIR/sddm.conf" ]]; then
            [[ -f /etc/sddm.conf ]] &&
                sudo cp -a /etc/sddm.conf "/etc/sddm.conf.bak-$(date +%Y%m%d-%H%M%S)"
            sudo cp "$SCRIPT_DIR/sddm.conf" /etc/sddm.conf
        fi
        ok "SDDM theme installed."
    else
        warn "SDDM theme files not found after cloning, skipping."
    fi
    sleep 1
    screen_clear
}

install_grub_theme() {
    info "Installing the GRUB theme..."
    if ! ask_yes_no "Install the Yorha GRUB theme?"; then
        info "Skipping the GRUB theme."
        sleep 1
        screen_clear
        return 0
    fi

    if [[ ! -d "$SCRIPT_DIR/yorha-1920x1080" ]]; then
        warn "Missing yorha-1920x1080 directory, skipping."
        return 0
    fi
    if [[ ! -f "$SCRIPT_DIR/yorha-1920x1080/theme.txt" ]]; then
        warn "Missing yorha-1920x1080/theme.txt, skipping."
        return 0
    fi
    if [[ ! -f /etc/default/grub ]]; then
        warn "/etc/default/grub does not exist (GRUB is probably not installed), skipping."
        return 0
    fi

    sudo install -d -m 755 /boot/grub/themes
    sudo cp -r "$SCRIPT_DIR/yorha-1920x1080" /boot/grub/themes
    sudo cp -a /etc/default/grub "/etc/default/grub.bak-$(date +%Y%m%d-%H%M%S)"
    sudo sed -i '/^#*GRUB_THEME=/d' /etc/default/grub
    printf '%s\n' 'GRUB_THEME="/boot/grub/themes/yorha-1920x1080/theme.txt"' |
        sudo tee -a /etc/default/grub >/dev/null
    run_step "regenerating the GRUB config" sudo grub-mkconfig -o /boot/grub/grub.cfg ||
        warn "grub-mkconfig failed. The theme is installed but not active yet."
    ok "GRUB theme installed."
    sleep 1
    screen_clear
}

build_llama() {
    info "Local LLM support..."
    if ! ask_yes_no "Build llama.cpp for local LLMs?"; then
        LLAMA_BUILT="no"
        info "Skipping llama.cpp build."
        return 0
    fi

    command -v cmake >/dev/null 2>&1 || die "cmake is required to build llama.cpp."
    command -v git >/dev/null 2>&1 || die "git is required to build llama.cpp."
    command -v make >/dev/null 2>&1 || warn "make not found, the build may fail."

    local src="$HOME/Templates/llama.cpp"
    if [[ ! -d "$src/.git" ]]; then
        run_step "cloning llama.cpp" git clone --depth 1 https://github.com/ggml-org/llama.cpp.git "$src" ||
            die "Could not clone llama.cpp."
    fi

    local choice=""
    while true; do
        printf '%sChoose build type:%s\n' "$YELLOW" "$RESET"
        printf '1) CUDA (Nvidia)\n2) CPU\n3) AMD (Vulkan)\n4) Intel (SYCL/oneAPI)\n' >&2
        ask 'Choice (1-4): '
        choice="$ANSWER"
        case "$choice" in
        1) break ;;
        2) break ;;
        3)
            install_packs_list "vulkan-extra-layers vulkan-tools vulkan-headers"
            break
            ;;
        4) break ;;
        *)
            err "Invalid choice. Try again."
            ;;
        esac
    done

    local -a flags=()
    case "$choice" in
    1) flags=(-DGGML_CUDA=ON) ;;
    2) flags=(-DBUILD_SHARED_LIBS=off) ;;
    3) flags=(-DGGML_VULKAN=ON) ;;
    4) flags=(-DGGML_SYCL=ON) ;;
    esac

    # Build with `cmake -S/-B` so nothing has to cd into the source tree. The
    # old version `cd`ed into llama.cpp and then `mv`d that very directory out
    # from under itself, and nested the copy on any re-run.
    run_step "configuring llama.cpp" cmake -S "$src" -B "$src/build" \
        -DCMAKE_BUILD_TYPE=Release "${flags[@]}" || die "llama.cpp configuration failed."
    run_step "building llama.cpp" cmake --build "$src/build" --config Release -j "$(nproc)" ||
        die "llama.cpp build failed."

    mkdir -p "$HOME/.local/bin" "$HOME/.config/AI" "$HOME/.local/share/AI-Models"
    local bin
    for bin in llama-cli llama-server; do
        if [[ -f "$src/build/bin/$bin" ]]; then
            ln -sfnT "$src/build/bin/$bin" "$HOME/.local/bin/$bin"
        else
            warn "$bin was not produced by the build, skipping."
        fi
    done

    LLAMA_BUILT="yes"
    ok "llama.cpp build complete. Source kept at $src"
    sleep 1
    screen_clear
}

add_llama_ui() {
    if [[ ${LLAMA_BUILT:-no} != "yes" ]]; then
        info "Skipping the custom UI because llama.cpp was not built."
        return 0
    fi
    info "Adding the custom llama.cpp UI..."
    # The old path was ~/Templates/RiceInstaller/LlamaUI-vMHD.html, a directory
    # nothing ever creates, so this function retried forever printing
    # "Custom UI file missing!" every two seconds. The file ships in the repo.
    if [[ -f "$SCRIPT_DIR/LlamaUI-vMHD.html" ]]; then
        mkdir -p "$HOME/.config/AI"
        cp "$SCRIPT_DIR/LlamaUI-vMHD.html" "$HOME/.config/AI/"
        ok "Custom UI added to ~/.config/AI/LlamaUI-vMHD.html"
    else
        warn "LlamaUI-vMHD.html missing from $SCRIPT_DIR, skipping."
    fi
    sleep 1
    screen_clear
}

write_notes() {
    info "Writing installation notes..."
    local notes="$HOME/Templates/IMPORTANT-README.md"
    mkdir -p "$HOME/Templates"
    # Written fresh each run. The old version appended with >> inside a retry
    # loop, so every re-run duplicated the notes and a write failure would
    # append forever.
    run_step "writing $notes" tee "$notes" >/dev/null <<'EOF'
# Read me after installing the rice

- Copy your AI models into ~/.local/share/AI-Models
- Use llama.cpp through LlamaUI-vMHD.html in your browser
- Plans and notes live in ~/MyNotes, and the `todo` command works there
EOF
    ok "Notes written to $notes"
    sleep 1
    screen_clear
}

fix_permissions() {
    info "Fixing file permissions..."
    local -a paths=()
    [[ -e "$HOME/.zshrc" ]] && paths+=("$HOME/.zshrc")
    [[ -d "$HOME/.config" ]] && paths+=("$HOME/.config")
    [[ -d "$HOME/.local" ]] && paths+=("$HOME/.local")
    ((${#paths[@]} == 0)) && return 0
    run_step "chown -R $(whoami)" sudo chown -R "$(whoami):$(whoami)" "${paths[@]}" ||
        warn "Could not adjust ownership of some paths."
    ok "Permissions updated."
    sleep 1
    screen_clear
}

finish_and_restart() {
    info "Installation finished."

    if [[ ${SDDM_THEME_WANTED:-no} != "yes" ]]; then
        printf '%sExiting without restart.%s\n' "$CYAN" "$RESET"
        exit 0
    fi

    if ! ask_yes_no "Enable SDDM and restart now?"; then
        info "Exiting without restart. Enable it yourself with: sudo systemctl enable sddm"
        exit 0
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        warn "systemctl not found, cannot enable SDDM."
        exit 0
    fi

    # Enabling a second display manager makes display-manager.service ambiguous
    # and can leave the machine unable to start a graphical session, so say so
    # and let the user fix it before the reboot.
    local current=""
    for current in sddm gdm lightdm ly xfce4-session-manager; do
        if systemctl is-enabled --quiet "$current" 2>/dev/null && [[ $current != sddm ]]; then
            warn "$current is already enabled as a display manager."
            warn "Disable it first, otherwise the restart may not give you a login screen:"
            warn "  sudo systemctl disable --now $current"
            exit 1
        fi
    done

    run_step "enabling SDDM" sudo systemctl enable sddm || die "Could not enable sddm."
    ok "SDDM enabled. Restarting..."
    sudo reboot
}

#-----------------------#
# RUN SCRIPT SECTIONS   #
#-----------------------#
refuse_root
require_sudo
require_repo_layout
require_wayland_session
show_banner
show_notice
choose_build_type
create_user_dirs
install_packages
copy_configs
if [[ $BUILD_TYPE == "programming" || $BUILD_TYPE == "both" ]]; then
    vscode_rice
fi
nvim
copy_zshrc
install_sddm_theme
install_grub_theme
build_llama
add_llama_ui
write_notes
fix_permissions
finish_and_restart