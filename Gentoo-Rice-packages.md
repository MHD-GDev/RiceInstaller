# Rice Packages to download with Emerge command:

```sh
# Clipboard / Screenshot / Wayland tools
gui-apps/wl-clipboard
gui-apps/slurp
gui-apps/grim
gui-apps/swaybg
media-gfx/imagemagick
media-gfx/imv
media-gfx/maim
dev-util/hyprwayland-scanner
gui-libs/hyprland-qt-support
gui-libs/hyprland-qtutils
gui-libs/hyprutils
gui-wm/hyprland
gui-apps/hyprshot
gui-apps/hyprlock
gui-apps/hypridle

# Wayland core
dev-libs/wayland
dev-libs/plasma-wayland-protocols
dev-libs/wayland-protocols
dev-qt/qtwayland
dev-qt/qtwaylandscanner
dev-util/wayland-scanner
gui-libs/egl-wayland
kde-plasma/kwayland
kde-plasma/kwayland-integration
x11-base/xwayland
x11-misc/xwayland-run

# Terminals / Shell
x11-terms/kitty
x11-terms/kitty-shell-integration
x11-terms/kitty-terminfo
app-shells/zsh
app-shells/zsh-completions
app-shells/starship
app-misc/fzf
app-misc/tmux
sys-process/htop
sys-apps/eza
sys-apps/bat
app-misc/fastfetch

# Fonts / Cursors
media-fonts/farsi-fonts
media-fonts/liberation-fonts
media-fonts/noto-emoji
media-fonts/symbols-nerd-font
media-fonts/ttf-meslo-nerd
media-fonts/noto-sans-cjk
x11-themes/vimix-cursors

# Editors
app-editors/neovim
app-editors/vscode

# Browsers
www-client/firefox-bin

# File managers
kde-apps/dolphin
app-misc/ranger

# Networking / Sync
net-misc/curl
net-misc/rsync
net-misc/chrony
net-misc/openssh
net-fs/sshfs
net-p2p/qbittorrent
net-im/telegram-desktop

# Audio / Video
media-video/mpv
media-video/ffmpeg
media-video/pipewire
media-video/wireplumber
media-sound/pavucontrol
media-sound/pulsemixer
media-sound/mpd
media-sound/lame
media-libs/gstreamer
sys-auth/rtkit
media-sound/bluetui
net-wireless/bluez

# Polkit / Auth
acct/group/polkitd
acct-user/polkitd
gnome-extra/polkit-gnome
kde-plasma/polkit-kde-agent
sys-auth/polkit
sys-auth/polkit-qt

# Login Manager
x11-misc/sddm

# Misc utilities
dev-vcs/git
app-arch/unzip
app-arch/unrar
app-misc/cmatrix
app-misc/timeshift
app-misc/brightnessctl
app-misc/awesome-terminal-fonts
dev-lang/nodejs
dev-python/pillow
sys-apps/mako
sys-apps/socat
```

- Use flags:
```conf
USE=" webp gdk-pixbuf X wifi tray wayland xwayland wayland-compositor gbm dbus pipewire gstreamer gsettings ipc dga -gpm -pulseaudio -xorg -xv -consolekit -gnome -gnome-keyring -kde -plasma -kwallet -kcm -kdecards -semantic-desktop -dvd -a52 -dvdr -cdr"

```


