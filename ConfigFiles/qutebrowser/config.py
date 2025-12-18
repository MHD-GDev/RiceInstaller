#Author: mhd

# disables pylint errors
c = c
config = config

# Autoloads this config on startup
config.load_autoconfig()
config.source('styles/nordtheme.py')
config.source('keys-unbind.py')

# start page ui
c.url.start_pages = ['file:///home/mhd/.config/qutebrowser/homepage.html']
c.url.default_page = 'file:///home/mhd/.config/qutebrowser/homepage.html'

# tabs
c.tabs.title.format = "{audio}{current_title}"
c.fonts.web.size.default = 20

# Search Engines
c.url.searchengines = {
    'DEFAULT' : 'https://duckduckgo.com/?q={}',
    '!yt': 'https://www.youtube.com/results?search_query={}',
}
c.completion.open_categories = ['searchengines', 'bookmarks', 'history']
c.auto_save.session = True # Saves tabs on quit

# dark mode
c.colors.webpage.preferred_color_scheme = 'dark'
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = 'never'
c.aliases['darkmode'] = "config-cycle colors.webpage.darkmode.enabled"

# Security
config.set("content.geolocation", False)

# Cosmetics
c.tabs.show = 'always'
c.tabs.position = 'top'
c.tabs.width = '7%'
c.statusbar.show = 'always'
c.statusbar.position = 'bottom'
c.content.user_stylesheets = ["~/.config/qutebrowser/styles/youtube-tweaks.css"]
c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 9, 'right': 9}
c.tabs.indicator.width = 0
c.window.transparent = False

# Fonts
c.fonts.default_family = ['Segoe UI']
c.fonts.default_size = '13pt'
c.fonts.web.family.fixed = 'monospace'
c.fonts.web.family.sans_serif = 'monospace'
c.fonts.web.family.serif = 'monospace'
c.fonts.web.family.standard = 'monospace'

# Keybindings
config.bind('o', 'cmd-set-text -s :open -t')
config.bind('cs', 'cmd-set-text -s :config-source')
config.bind('tH', 'config-cycle tabs.show always never')
config.bind('sH', 'config-cycle statusbar.show always never')
config.bind(' t', 'hint links tab')
config.bind('pp', 'open -t -- {clipboard}')
config.bind('tr', 'tab-move +')
config.bind('tl', 'tab-move -')
config.bind(' h', 'history')
config.bind(' ch', 'history-clear')
config.bind('dd', 'tab-close')
config.bind('dt', 'devtools')
config.bind('<Ctrl+U>', 'undo')
config.bind('bl', 'bookmark-list')
config.bind('ba', 'bookmark-add')
config.bind('bd', 'bookmark-del')
config.bind('ts', 'tab-select')
config.bind('<Shift + k>', 'tab-next')
config.bind('<Shift + j>', 'tab-prev')

