# ConfigFiles

Everything in this directory is copied into the user's `~/.config` by
`RiceInstaller.sh` to build the rice. The installer skips this directory's own
`README.md`, so it does not end up in `~/.config`.

## Layout

### gtk-3.0/, gtkrc

GTK appearance settings.

### hypr/

- `hyprland.lua` - the compositor configuration
- `shaders/` - GLSL shaders

The rice targets a Hyprland release with lua configuration support, so the
config is lua rather than the older `hyprland.conf` format.

Note that `hyprland.lua` does `dofile()` on
`~/.config/wayland/hypr/borders.lua`. That file is a symlink into the active
rice, created by `rice-selector` on the first login, so borders follow the
theme.

### wayland/

The bulk of the rice:

- `fastfetch/` - system info, including a small `3dfetch/` build
- `hypr/` - the per-rice `borders.lua` symlink target
- `kitty/`, `mako/`, `waybar` - per-rice symlink targets, created by
  `rice-selector`; the directories ship empty on purpose
- `rices/` - one directory per rice, each with `hypr/`, `kitty/`, `mako/`,
  `rofi/`, `waybar/` and `walls/`
- `scripts/` - the utility scripts and `lib/common.sh`, which every script
  sources for its shared helpers
- `scripts/rofi-themes/` - menu themes; each one imports `shared-colors.rasi`,
  which `rice-selector` re-points at the active rice
- `tmux/`, `zsh/` - terminal multiplexer and shell configuration
- `.current_rice` - the rice a fresh install boots into

### Where the Neovim config lives

Neovim's config is **not** in this directory. It ships in `IDE/nvim` and is
installed to `~/.config/nvim`. VSCode's settings are in `IDE/User`.

### Locking and idle

This rice does not ship `hyprlock` or `hypridle` configuration, and neither is
in the package list. `power-menu` locks with `swaylock`, which is included. If
you install `hyprlock` yourself, `power-menu` will use it instead.