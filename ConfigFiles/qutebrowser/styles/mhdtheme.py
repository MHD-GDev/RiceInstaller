mhd_colors = {
    'background': '#333333',
    'foreground': '#eceff4',
    'status_bar': '#FF8C00',
    'blue': '#5e81ac',
    'red': '#bf616a',
    'green': '#a3be8c',
    'yellow': '#ebcb8b',
    'cyan': '#8fbcbb',
    'bright_blue': '#88c0d0',
    'bright_cyan': '#81a1c1',
    'orange': '#b06770',
}

# --- Completion widget ---
c.colors.completion.category.bg = mhd_colors['background']
c.colors.completion.category.border.bottom = mhd_colors['background']
c.colors.completion.category.border.top = mhd_colors['background']
c.colors.completion.category.fg = mhd_colors['foreground']
c.colors.completion.even.bg = mhd_colors['background']
c.colors.completion.odd.bg = mhd_colors['background']
c.colors.completion.fg = mhd_colors['foreground']
c.colors.completion.item.selected.bg = mhd_colors['background']
c.colors.completion.item.selected.border.bottom = mhd_colors['background']
c.colors.completion.item.selected.border.top = mhd_colors['background']
c.colors.completion.item.selected.fg = mhd_colors['foreground']
c.colors.completion.match.fg = mhd_colors['yellow']
c.colors.completion.scrollbar.bg = mhd_colors['background']
c.colors.completion.scrollbar.fg = mhd_colors['foreground']

# --- Downloads ---
c.colors.downloads.bar.bg = mhd_colors['background']
c.colors.downloads.error.bg = mhd_colors['red']
c.colors.downloads.error.fg = mhd_colors['foreground']
c.colors.downloads.stop.bg = mhd_colors['yellow']
c.colors.downloads.system.bg = 'none'

# --- Hints ---
c.colors.hints.bg = mhd_colors['yellow']
c.colors.hints.fg = mhd_colors['background']
c.colors.hints.match.fg = mhd_colors['blue']

# --- Keyhint ---
c.colors.keyhint.bg = mhd_colors['background']
c.colors.keyhint.fg = mhd_colors['foreground']
c.colors.keyhint.suffix.fg = mhd_colors['yellow']

# --- Messages ---
c.colors.messages.error.bg = mhd_colors['red']
c.colors.messages.error.border = mhd_colors['red']
c.colors.messages.error.fg = mhd_colors['foreground']
c.colors.messages.info.bg = mhd_colors['bright_blue']
c.colors.messages.info.border = mhd_colors['bright_blue']
c.colors.messages.info.fg = mhd_colors['foreground']
c.colors.messages.warning.bg = mhd_colors['orange']
c.colors.messages.warning.border = mhd_colors['orange']
c.colors.messages.warning.fg = mhd_colors['foreground']

# --- Prompts ---
c.colors.prompts.bg = mhd_colors['background']
c.colors.prompts.border = '1px solid ' + mhd_colors['background']
c.colors.prompts.fg = mhd_colors['foreground']
c.colors.prompts.selected.bg = mhd_colors['background']

# --- Statusbar ---
c.colors.statusbar.caret.bg = mhd_colors['blue']
c.colors.statusbar.caret.fg = mhd_colors['background']
c.colors.statusbar.caret.selection.bg = mhd_colors['blue']
c.colors.statusbar.caret.selection.fg = mhd_colors['background']
c.colors.statusbar.command.bg = mhd_colors['background']
c.colors.statusbar.command.fg = mhd_colors['foreground']
c.colors.statusbar.command.private.bg = mhd_colors['background']
c.colors.statusbar.command.private.fg = mhd_colors['foreground']
c.colors.statusbar.insert.bg = mhd_colors['blue']
c.colors.statusbar.insert.fg = mhd_colors['background']
c.colors.statusbar.normal.bg = mhd_colors['status_bar']
c.colors.statusbar.normal.fg = mhd_colors['background']
c.colors.statusbar.passthrough.bg = mhd_colors['blue']
c.colors.statusbar.passthrough.fg = mhd_colors['foreground']
c.colors.statusbar.private.bg = mhd_colors['background']
c.colors.statusbar.private.fg = mhd_colors['foreground']
c.colors.statusbar.progress.bg = mhd_colors['foreground']
c.colors.statusbar.url.error.fg = mhd_colors['red']
c.colors.statusbar.url.fg = mhd_colors['foreground']
c.colors.statusbar.url.hover.fg = mhd_colors['foreground']
c.colors.statusbar.url.success.http.fg = mhd_colors['background']
c.colors.statusbar.url.success.https.fg = mhd_colors['background']
c.colors.statusbar.url.warn.fg = mhd_colors['orange']

# Tabs bar background
c.colors.tabs.bar.bg = mhd_colors['background']

# Unselected tabs
c.colors.tabs.even.bg = '#3a3a3a'
c.colors.tabs.even.fg = mhd_colors['foreground']
c.colors.tabs.odd.bg = '#3a3a3a' 
c.colors.tabs.odd.fg = mhd_colors['foreground']

# Selected (focused) tab
c.colors.tabs.selected.even.bg = '#2a2a2a'
c.colors.tabs.selected.even.fg = mhd_colors['foreground']
c.colors.tabs.selected.odd.bg = '#2a2a2a'
c.colors.tabs.selected.odd.fg = mhd_colors['foreground']

# Tab indicator
c.colors.tabs.indicator.error = mhd_colors['red']
c.colors.tabs.indicator.system = 'none'
