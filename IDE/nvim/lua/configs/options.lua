local opt = vim.opt

-- Numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.showtabline = 2
opt.laststatus = 3
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Editing
opt.backspace = { "indent", "eol", "start" }
opt.iskeyword:append("-")
opt.undofile = true
opt.undolevels = 10000
opt.confirm = true
opt.hidden = true

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Performance and usability
opt.updatetime = 250
opt.timeoutlen = 400
opt.mouse = "a"
opt.completeopt = { "menu", "menuone", "noselect" }

-- Compatibility
opt.swapfile = false
