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
- **Unified theming** — Theme colors carry through to Kitty, Rofi, Waybar, tmux, and Neovim.
- **Neovim IDE** — A configured development environment with LSP support and rice-aware colors.
- **Zsh setup** — Syntax highlighting, autosuggestions, history substring search, and Starship.
- **Utility scripts** — Wallpaper management, audio switching, keyboard layouts, cheatsheets, and power controls.
- **Rice creator** — Generate a new rice from the terminal using `create_rice`.
- **Automated installation** — Set up the environment and optionally install additional themes and tools.

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

- **Arch Linux or an Arch-based distribution** — The installer detects Arch-based systems through `/etc/os-release` and uses `paru` for package installation. On other distributions, it skips automatic package installation and reports what needs to be installed manually.
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

It is designed to be safe to run again. It retries failed steps, keeps backups rather than blindly replacing existing files, and creates timestamped backups of `~/.config/hypr` and your Bash dotfiles.

### Installation Options

During setup, you will be asked to choose:

| Option | Description |
|---|---|
| **Build type** | Gaming, programming, both, or neither. Controls additional packages and VSCode configuration. |
| **GPU** | Nvidia, Intel, AMD, hybrid, or skip. Selects the corresponding driver and compute packages. |
| **Branch** | Optional package groups for gamedev, gaming, programming, or Steam Deck. |
| **Extras** | Optional SDDM theme, GRUB theme, and a local llama.cpp build. |

### Manual Setup

If you prefer to configure the environment yourself:

1. Copy the contents of `ConfigFiles/` into `~/.config/`.
2. Copy `.zshrc` into your home directory.
3. Install the required packages:

   ```bash
   paru -Syu --needed --noconfirm
   paru -S --needed --noconfirm $(cat arch-rice-wayland-packs.txt)
   ```

4. Install the appropriate driver packages for your GPU.
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
