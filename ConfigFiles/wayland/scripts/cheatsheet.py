#!/usr/bin/env python3
# Hyprland Cheatsheet Window (GTK4, Dark Dashboard + ANSI Title)

import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gdk, Gio, Pango
import sys

APP_NAME = "Hypr Cheatsheet"

COLORS = {
    "bg": "#0f0f14",
    "fg": "#d8d8d8",
    "red": "#e06c75",
    "green": "#98c379",
    "blue": "#61afef",
    "magenta": "#c678dd",
    "cyan": "#56b6c2",
}

TITLE_ASCII = (
    " ██████ ██   ██ ███████  █████  ████████     ███████ ██   ██ ███████ ███████ ████████\n"
    "██      ██   ██ ██      ██   ██    ██        ██      ██   ██ ██      ██         ██   \n"
    "██      ███████ █████   ███████    ██        ███████ ███████ █████   █████      ██   \n"
    "██      ██   ██ ██      ██   ██    ██             ██ ██   ██ ██      ██         ██   \n"
    " ██████ ██   ██ ███████ ██   ██    ██        ███████ ██   ██ ███████ ███████    ██   "
)

CHEATSHEET = [
    ("General", [
        ("super + alt + c", "Cheatsheet"),
        ("super + return", "Terminal"),
        ("super + space", "Application Menu"),
        ("alt + space", "Rice Menu"),
        ("super + alt + w", "Wallpaper Menu"),
        ("super + alt + a", "Scripts Menu"),
        ("shift + alt + b", "Browser"),
        ("shift + alt + w", "Browser → WhatsApp"),
        ("shift + alt + i", "Browser → Copilot AI"),
        ("shift + alt + t", "Telegram"),
        ("shift + alt + v", "Neovim"),
        ("super + alt + s", "Screenshoter"),
        ("super + alt + p", "Audio Switcher Menu"),
        ("super + b", "Hide/Unhide Waybar"),
    ]),
    ("Window Management", [
        ("super + q", "Kill Window"),
        ("super + alt + r", "Reload Hyprland"),
        ("super + t", "Float Window"),
        ("super + f", "Fullscreen"),
    ]),
    ("Vim-like Navigation", [
        ("super + h", "Move ←"),
        ("super + l", "Move →"),
        ("super + k", "Move ↑"),
        ("super + j", "Move ↓"),
        ("super + shift + h", "Rotate ←"),
        ("super + shift + l", "Rotate →"),
        ("super + shift + k", "Rotate ↑"),
        ("super + shift + j", "Rotate ↓"),
        ("super + ctrl + h", "Workspace ←"),
        ("super + ctrl + l", "Workspace →"),
        ("super + shift + 1", "Send → WS1"),
        ("super + shift + 2", "Send → WS2"),
        ("super + shift + 3", "Send → WS3"),
        ("super + shift + 4", "Send → WS4"),
        ("super + shift + 5", "Send → WS5"),
        ("super + shift + 6", "Send → WS6"),
        ("super + shift + ctrl + h", "Send Node ← WS"),
        ("super + shift + ctrl + l", "Send Node → WS"),
        ("super + 1", "Switch → WS1"),
        ("super + 2", "Switch → WS2"),
        ("super + 3", "Switch → WS3"),
        ("super + 4", "Switch → WS4"),
        ("super + 5", "Switch → WS5"),
        ("super + 6", "Switch → WS6"),
        ("super + grave", "Last Window/WS"),
    ]),
    ("Resize & Effects", [
        ("super + alt + h", "Resize ←"),
        ("super + alt + l", "Resize →"),
        ("super + alt + k", "Resize ↑"),
        ("super + alt + j", "Resize ↓"),
        ("ctrl + alt + +", "No Opacity"),
        ("ctrl + alt + -", "Window Opacity"),
        ("super + mouseclick left", "Move Window (Mouse)"),
        ("super + alt + m", "Monitor Rotation"),
        ("ctrl + alt + h", "Hide/Unhide Window"),
        ("ctrl + alt + 0", "Toggle Blur"),
    ]),
]

class CheatsheetWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title(APP_NAME)
        self.set_default_size(1000, 700)
        self.set_decorated(False)

        provider = Gtk.CssProvider()
        provider.load_from_data(self._css().encode("utf-8"))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        outer.add_css_class("cheatsheet")
        self.set_child(outer)

        # ANSI ASCII Title
        lbl_title = Gtk.Label(label=TITLE_ASCII)
        lbl_title.add_css_class("title")
        lbl_title.set_xalign(0.5)
        lbl_title.set_wrap(False)  # prevent wrapping
        lbl_title.set_ellipsize(Pango.EllipsizeMode.NONE)  # don’t truncate
        lbl_title.set_use_markup(False)  # treat ASCII literally
        outer.append(lbl_title)

        # Scrollable content
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)
        outer.append(scroll)

        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        content.add_css_class("content")
        content.set_hexpand(True)
        content.set_vexpand(True)
        scroll.set_child(content)

        # Sections
        for section, items in CHEATSHEET:
            cat = Gtk.Label(label=section.upper())
            cat.add_css_class("category")
            cat.set_xalign(0.0)
            content.append(cat)

            for keys, desc in items:
                row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
                row.set_hexpand(True)
                row.add_css_class("keys-row")

                left = Gtk.Label(label=desc)
                left.add_css_class("keys")
                left.set_xalign(0.0)
                left.set_hexpand(True)

                right = Gtk.Label(label=keys)
                right.add_css_class("keys-alt")
                right.set_xalign(1.0)
                right.set_hexpand(False)

                row.append(left)
                row.append(right)
                content.append(row)

    def _css(self):
        c = COLORS
        return f"""
.cheatsheet {{
  background-color: {c['bg']};
  border-radius: 8px;
}}
.title {{
  font-family: "Meslo LG M", monospace;
  font-weight: 900;
  font-size: 0.7rem;
  color: {c['blue']};
  margin: 1rem;
  text-shadow: 0 0 6px {c['blue']};
}}
.content {{
  margin: 1rem 2rem;
}}
.category {{
  font-family: "Meslo LG M", monospace;
  font-weight: 700;
  font-size: 0.9rem;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin: 1rem 0 0.5rem 0;
  padding: 0.4rem 0.6rem;
  border-radius: 4px;
  background: linear-gradient(90deg, {c['magenta']}, rgba(198,120,221,0.2));
  color: #ffffff; /* ✅ readable text */
}}
.keys-row {{
  padding: 6px 0;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}}
.keys-row:hover {{
  background-color: rgba(97,175,239,0.1);
}}
.keys {{
  font-family: "Meslo LG M", monospace;
  font-size: 0.95rem;
  color: {c['fg']};
}}
.keys-alt {{
  font-family: "Meslo LG M", monospace;
  font-weight: 600;
  font-size: 0.85rem;
  color: {c['bg']};
  background-color: {c['green']};
  padding: 0.2rem 0.6rem;
  border-radius: 9999px;
}}
scrolledwindow scrollbar slider {{
  min-width: 4px;
  border-radius: 9999px;
  background-color: {c['green']};
}}
scrolledwindow scrollbar:hover slider {{
  min-width: 8px;
  background-color: {c['green']};
}}
"""

class CheatsheetApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.hypr.cheatsheet",
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.window = None

    def do_activate(self, *args, **kwargs):
        if not self.window:
            self.window = CheatsheetWindow(self)
        self.window.present()

def main():
    app = CheatsheetApp()
    app.run(sys.argv)

if __name__ == "__main__":
    main()
