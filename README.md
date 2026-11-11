# MHD RiceInstaller

A collection of rice configurations for a Hyprland desktop, plus an automated
installer that sets the whole thing up in one command.

- Demo:
<img width="480" height="270" alt="Rice" src="https://github.com/user-attachments/assets/b859cd3c-fa34-4fd1-9944-304beb5a2f80" />



## Features

- **Complete Wayland setup**: Hyprland, Kitty, Mako, Waybar, Rofi menus, Fastfetch and more
- **13 rices**: switch themes at runtime, colours follow into Kitty, Rofi, Waybar, tmux and Neovim
- **Productivity scripts**: audio switcher, cheatsheets, keyboard layouts, power menu, wallpaper and rice selection
- **Neovim IDE**: fully configured, with LSP support and a per-rice colour scheme
- **Zsh shell**: syntax highlighting, autosuggestions, history substring search, Starship prompt
- **Rice creator**: build your own rice from the terminal with the `create_rice` command
- **Automated installer**: one-command setup, including optional SDDM theme, GRUB theme and a local llama.cpp build

---

| Bubble | Rainbow |
|--------|---------|
| <img width="1919" height="1078" alt="Bubble" src="https://github.com/user-attachments/assets/4d1536c4-4a18-42a2-ac51-6d404e59279e" /> | <img width="1919" height="1079" alt="Rainbow" src="https://github.com/user-attachments/assets/29eb7298-d57e-4c70-8175-121e1723698c" /> |

| Frutiger | WinXP |
|----------|-------|
| <img width="1918" height="1079" alt="Frutiger" src="https://github.com/user-attachments/assets/815bb4a2-840d-4856-a96c-3d33804b0a40" /> | <img width="1918" height="1079" alt="WinXP" src="https://github.com/user-attachments/assets/ac5554f2-26a2-4279-9047-148ec2ca959f" /> |

| Cream | Mono |
|-------|------|
| <img width="1918" height="1080" alt="Cream" src="https://github.com/user-attachments/assets/8bd76f9a-9319-4af5-aa26-f4d0f425b46e" /> | <img width="1913" height="1074" alt="Mono" src="https://github.com/user-attachments/assets/2d32c7d3-74ca-4188-8efd-5d94bd38ddac" /> |

| Solarized | Yellowpunk |
|-----------|-------------|
| <img width="1917" height="1079" alt="Solarized" src="https://github.com/user-attachments/assets/b3906f83-2123-448c-88cc-75e081abcf9b" /> | <img width="1920" height="1079" alt="Yellowpunk" src="https://github.com/user-attachments/assets/82402292-3e6e-4172-b46e-8ce80708fff3" /> |

| Redpunk | y2k |
|---------|-----|
| <img width="1919" height="1080" alt="Redpunk" src="https://github.com/user-attachments/assets/0399a260-e42e-4e24-82d2-dfb9745d47b6" /> | <img width="1918" height="1080" alt="y2k" src="https://github.com/user-attachments/assets/dafbcac6-05ea-4f64-b5cb-c6ba5365cc96" />
 |

Three more rices ship without a demo recording: **H3cker**, **Gentoo** and
**mhd_rice**. Pick any of them with `rice-selector`.

## Requirements

- **Arch Linux or a derivative** (EndeavourOS, CachyOS, Garuda, ...). The
  installer detects these through `/etc/os-release` and installs packages with
  `paru`. It also runs on other distributions, but skips the package step and
  tells you what to install.
- **Hyprland with lua configuration support.** The rice ships `hyprland.lua`
  rather than the older `hyprland.conf`, so it needs a Hyprland build that
  reads lua config. The installer checks for this and warns you if the running
  version cannot load it.
- `rofi` and ImageMagick are required by the menus and wallpaper thumbnails.
- A Nerd Font for the icons. `fonts/` ships MesloLGM, which is the closest
  match; any Nerd Font works.

### If Hyprland misbehaves after installing

Config written for a newer Hyprland than the one running is quietly ignored or
rejected, which leaves the window manager half-configured with no obvious
error. After installing, or after a Hyprland update, check:

```sh
hyprctl configerrors
```

The installer runs this for you after it reloads the config and prints
anything it finds.

## Installation

```sh
git clone https://github.com/MHD-GDev/RiceInstaller.git
cd RiceInstaller
chmod +x RiceInstaller.sh
./RiceInstaller.sh
```

The script can be started from any directory, and re-running it is safe: it
retries what failed, keeps backups instead of deleting anything, and creates
timestamped backups of `~/.config/hypr` and of your bash dotfiles.

During the install it asks what to set up:

- **Build type** - gaming, programming, both or neither. This picks which extra
  packages to install and whether VSCode is configured.
- **GPU** - Nvidia, Intel, AMD, hybrid, or skip. The matching driver and
  compute packages are installed.
- **Branch** - optional extra package groups for gamedev, gaming, programming
  or Steam Deck.
- **Extras** - the SDDM login theme, the GRUB theme, and a llama.cpp build for
  local LLMs.

## Manual installation

1. Copy `ConfigFiles` into your `.config` directory.
2. Copy `.zshrc` into your home directory.
3. Install the packages:

   ```sh
   paru -Syu --needed --noconfirm
   paru -S --needed --noconfirm $(cat arch-rice-wayland-packs.txt)
   ```

   Remember to install the driver packages for your GPU as well.

4. If you want the zsh plugins that `.zshrc` sources, copy the contents of
   `plugins/` to `/usr/share/zsh/plugins/`.
5. Restart Hyprland, or log out and back in.

## After installing

- `rice-selector` switches the whole theme. `ALT + SPACE` opens it.
- `wallpaper-selector` picks a wallpaper for the current rice
  (`SUPER + ALT + W`).
- `create_rice` scaffolds a new rice you can edit yourself.
- `power-menu` locks, logs out, reboots or shuts down.
- Your AI models, if you built llama.cpp, go in `~/.local/share/AI-Models`.

## Acknowledgments

- [OliveThePuffin](https://github.com/OliveThePuffin/yorha-grub-theme) for the GRUB theme.
- [stepanzubkov](https://github.com/stepanzubkov/where-is-my-sddm-theme) for the SDDM theme.

## License

GPLv3, see [LICENCE](LICENCE). The vendored zsh plugins under `plugins/` are
MIT licensed by their respective authors.
