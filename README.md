# MHD RiceInstaller

A collection of 13 desktop rices for Hyprland, brought together with an automated installer. Set up a complete desktop environment, switch between themes, or create your own.

<p align="center">
  <img width="480" alt="RiceInstaller preview" src="https://github.com/user-attachments/assets/b859cd3c-fa34-4fd1-9944-304beb5a2f80" />
</p>

<p align="center">
  <strong>13 Rices · Hyprland · Wayland · Automated Setup</strong>
</p>

---

## Overview

RiceInstaller brings together a collection of desktop configurations, scripts, and tools designed to work as one environment.

- **Desktop environment** — Hyprland, Kitty, Waybar, Mako, Rofi, and Fastfetch.
- **13 desktop themes** — Switch between different visual styles at runtime.
- **Unified theming** — Theme colors carry through to Kitty, Rofi, Waybar, tmux, and Neovim, with optional automatic rice-color syncing for detected Obsidian vaults.
- **Neovim IDE** — A configured development environment with LSP support and rice-aware colors.
- **Zsh setup** — Syntax highlighting, autosuggestions, history substring search, and Starship.
- **Utility scripts** — Wallpaper management, audio switching, keyboard layouts, cheatsheets, and power controls.
- **Rice creator** — Generate a new rice from the terminal using `create_rice`.
- **Automated installation** — Set up the environment and optionally install additional themes and tools.

Obsidian vaults automatically match the active rice whenever you switch themes.

## Desktop Gallery

Each preview shows a different desktop configuration. Select a theme that suits your taste and switch between them whenever you want.

| Bubble | Rainbow |
|:---:|:---:|
| <img width="480" alt="Bubble" src="https://github.com/user-attachments/assets/4d1536c4-4a18-42a2-ac51-6d404e59279e" /> | <img width="480" alt="Rainbow" src="https://github.com/user-attachments/assets/29eb7298-d57e-4c70-8175-121e1723698c" /> |

| Frutiger | WinXP |
|:---:|:---:|
| <img width="480" alt="Frutiger" src="https://github.com/user-attachments/assets/815bb4a2-840d-4856-a96c-3d33804b0a40" /> | <img width="480" alt="WinXP" src="https://github.com/user-attachments/assets/ac5554f2-26a2-4279-9047-148ec2ca959f" /> |

| Cream | Mono |
|:---:|:---:|
| <img width="480" alt="Cream" src="https://github.com/user-attachments/assets/8bd76f9a-9319-4af5-aa26-f4d0f425b46e" /> | <img width="480" alt="Mono" src="https://github.com/user-attachments/assets/2d32c7d3-74ca-4188-8efd-5d94bd38ddac" /> |

| Solarized | Yellowpunk |
|:---:|:---:|
| <img width="480" alt="Solarized" src="https://github.com/user-attachments/assets/b3906f83-2123-448c-88cc-75e081abcf9b" /> | <img width="480" alt="Yellowpunk" src="https://github.com/user-attachments/assets/82402292-3e6e-4172-b46e-8ce80708fff3" /> |

| Redpunk | y2k |
|:---:|:---:|
| <img width="480" alt="Redpunk" src="https://github.com/user-attachments/assets/0399a260-e42e-4e24-82d2-dfb9745d47b6" /> | <img width="480" alt="y2k" src="https://github.com/user-attachments/assets/dafbcac6-05ea-4f64-b5cb-c6ba5365cc96" /> |

Three additional themes are included without preview recordings:

- H3cker
- Gentoo
- mhd_rice
- Arasaka

They can also be selected through `rice-selector`.

---

## Installation

### Requirements

- **Arch Linux or an Arch-based distribution** — The installer detects Arch-based systems through `/etc/os-release`. It bootstraps `paru` for AUR packages and `pacutils` for safer official-repository transactions. On other distributions, it skips automatic package installation and reports what needs to be installed manually.
- **Hyprland with Lua configuration support** — This project uses `hyprland.lua` rather than the traditional `hyprland.conf`. Your Hyprland build must support Lua configuration.
- **Rofi** — Required by the menus.
- **ImageMagick** — Used by wallpaper thumbnails.
- **Nerd Font** — Required for icons. MesloLGM is included in `fonts/`, but other Nerd Fonts can be used.

### Quick Setup

Clone the repository and launch the installer:

```bash
git clone https://github.com/MHD-GDev/RiceInstaller.git
cd RiceInstaller
chmod +x RiceInstaller.sh
./RiceInstaller.sh
```

The installer can be launched from any working directory.

The installer opens a recovery-aware terminal menu. It records each completed step under `~/.local/state/riceinstaller/`, so you can close it, fix a problem, launch it again, and resume without repeating successful steps. You can also review progress, retry a failed step, or start a fresh installation. The menu uses `gum` when available and has a built-in fallback, so `gum` is optional.

Before replacing existing configuration, the installer keeps timestamped backups. Its shared symlink helper never deletes an older `.replaced` backup; if that name is already occupied, it creates a timestamped backup instead.

Package installation is planned in batches rather than one package at a time. RiceInstaller checks whether each requested package is already installed or satisfied by an installed provider, separates official repository packages from AUR and custom-repository packages, and checks conflicts from both sides of the package metadata. Official repository transactions use `pactrans` with conservative policies: a conflicting package is automatically removed only when the incoming package provides it, and official `Replaces` declarations are honored. AUR and custom-repository packages are never given blanket removal permission. Ambiguous optional packages are skipped and recorded in `~/missing_apps.txt` instead of deleting a package that may belong to the existing rice. Core packages still fail the step if an unsafe conflict prevents installation. Package transactions retain their normal approval prompt; RiceInstaller does not use blanket `--noconfirm` or `--overwrite` to force removals.

The Fcitx5 input-method stack, Dolphin/Poppler, and other conflict-prone extras are handled as optional groups. An existing Fcitx v4 stack or legacy Poppler Qt bindings are preserved rather than forcibly replaced. For audio, an existing `pipewire-media-session` is preserved; WirePlumber is installed only when no PipeWire session manager is already present.

The NVIDIA option uses Arch's current open kernel-module driver for Turing-and-newer GPUs. It selects the standard prebuilt module for the regular Arch kernel and DKMS plus matching headers when supported alternate Arch kernels are installed. Legacy pre-Turing NVIDIA cards need a legacy driver path and are not covered by this automatic option. CUDA and Intel oneAPI compute toolkits are not installed as graphics-driver dependencies. Gaming, gamedev, and Steam Deck branches enable Arch's `multilib` repository only when their package lists require 32-bit packages. The installer backs up `/etc/pacman.conf` before changing it and performs a full `pacman -Syu` after enabling the repository.

### Installation Options

During setup, you will be asked to choose:

| Option | Description |
|---|---|
| **Build type** | Gaming, programming, both, or neither. Controls additional packages and VSCode configuration. |
| **GPU** | NVIDIA (Turing+), Intel, AMD, hybrid, or skip. Selects the matching driver and later adds 32-bit userspace for gaming branches. |
| **Branch** | Optional package groups for gamedev, gaming, programming, or Steam Deck. |
| **Extras** | Optional SDDM theme, GRUB theme, and a local llama.cpp build. |

### Resume or Update

Launch the installer again to resume an interrupted setup:

```bash
./RiceInstaller.sh
```

To update an existing checkout and migrate changed configuration files:

```bash
./RiceUpdater.sh
```

The updater requires a clean Git checkout and a reachable `origin` remote. It fetches the current branch, checks that the update is a fast-forward, and creates a timestamped backup under `~/.local/share/RiceInstaller/backups/` before migrating files. Files that still match the previous upstream version can be updated automatically. Customized files are shown individually, with a choice to keep the current version or replace it. Runtime state (such as the selected rice and wallpaper) is preserved, foreign/unmanaged entries are reported but left untouched, and upstream file deletions are not applied to the user's home directory. After the rice update, you may separately opt into a full `paru -Syu` (or `pacman -Syu`) package update; it is never run silently. If migration is interrupted, run the updater again; files already migrated to the new upstream version are detected.

### Manual Setup

If you prefer to configure the environment yourself:

1. Copy the contents of `ConfigFiles/` into `~/.config/`.
2. Copy `.zshrc` into your home directory.
3. Install the required packages:

   ```bash
   sudo pacman -Syu
   mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' arch-rice-wayland-packs.txt)
   paru -S --needed "${packages[@]}"
   mapfile -t optional_packages < <(grep -vE '^[[:space:]]*(#|$)' arch-rice-wayland-optional-packs.txt)
   paru -S --needed "${optional_packages[@]}"
   paru -S --needed dolphin poppler
   paru -S --needed fcitx5 fcitx5-qt fcitx5-gtk fcitx5-mozc fcitx5-chinese-addons
   ```

   If Fcitx v4 is already installed, skip the final Fcitx5 command; the installer preserves the existing input method rather than forcing a migration. If `poppler-qt3` or `poppler-qt4` is installed, skip the Dolphin/Poppler command to preserve those legacy applications.

4. Install the appropriate driver packages for your GPU. If you select a gaming, gamedev, or Steam Deck package list, enable `[multilib]` in `/etc/pacman.conf` and run `sudo pacman -Syu` before installing its 32-bit packages.
5. If you use the supplied Zsh configuration, copy the contents of `plugins/` into `/usr/share/zsh/plugins/`.
6. Restart Hyprland or log out and back in.

---

## Useful Commands

The included scripts make common desktop tasks accessible directly from the terminal.

| Command | Purpose |
|---|---|
| `rice-selector` | Change the active desktop theme. |
| `wallpaper-selector` | Choose a wallpaper for the current rice. |
| `create_rice` | Create a new rice configuration. |
| `./RiceUpdater.sh` | Back up and safely migrate changed rice files from upstream. |
| `power-menu` | Lock, log out, reboot, or shut down. |

### Default Shortcuts

| Shortcut | Action |
|---|---|
| `ALT + SPACE` | Open the rice selector. |
| `SUPER + ALT + W` | Open the wallpaper selector. |

### Optional Local AI Models

If you choose to build llama.cpp during installation, place your models in:

```text
~/.local/share/AI-Models
```

---

## Developer Checks

Run the package-planner tests without installing, upgrading, or removing any real packages:

```bash
bash tests/package-planner.sh
```

The test suite mocks pacman, paru, and pactrans to verify provider detection, official replacements, AUR/custom conflict preservation, reverse conflicts, and unknown-package handling.

## Troubleshooting

### Hyprland configuration errors

A configuration written for a newer Hyprland version may be rejected or silently ignored by an older build.

After installation, or following a Hyprland update, run:

```bash
hyprctl configerrors
```

The installer also checks the configuration after reloading it and reports any errors it finds.

---

## Acknowledgments

- [OliveThePuffin](https://github.com/OliveThePuffin/yorha-grub-theme) — GRUB theme.
- [stepanzubkov](https://github.com/stepanzubkov/where-is-my-sddm-theme) — SDDM theme.

## License

This project is licensed under the **GPL-3.0** license. See [LICENCE](LICENCE) for details.

The vendored Zsh plugins in `plugins/` retain their respective authors' MIT licenses.
