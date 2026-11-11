local map = vim.keymap.set

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable macro recording.
map("n", "q", "<Nop>", { desc = "Disable macro recording" })

-- General
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<C-a>", "ggVG", { desc = "Select all" })
map("n", "nf", "<cmd>tabedit<Space>", { desc = "Open file in new tab" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Navigate left" })
map("n", "<C-l>", "<C-w>l", { desc = "Navigate right" })

-- Centered page navigation
map("n", "<C-j>", "<C-d>zz", { desc = "Scroll down" })
map("n", "<C-k>", "<C-u>zz", { desc = "Scroll up" })

-- Window splitting
map("n", "<leader>sh", "<cmd>split<CR><C-w>w", { desc = "Split horizontally" })
map("n", "<leader>sv", "<cmd>vsplit<CR><C-w>w", { desc = "Split vertically" })
map("n", "<leader>th", "<C-w>t<C-w>H", { desc = "Arrange splits horizontally" })
map("n", "<leader>tv", "<C-w>t<C-w>K", { desc = "Arrange splits vertically" })

-- Window resizing
map("n", "<C-Up>", "<cmd>resize -1<CR>", { desc = "Decrease window height" })
map("n", "<C-Down>", "<cmd>resize +1<CR>", { desc = "Increase window height" })
map("n", "<C-Left>", "<cmd>vertical resize -1<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +1<CR>", { desc = "Increase window width" })

-- Barbar
map("n", "<Tab>", "<cmd>BufferNext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>BufferPrevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>x", "<cmd>BufferClose<CR>", { desc = "Close buffer" })
map("n", "<A-p>", "<cmd>BufferPin<CR>", { desc = "Pin buffer" })

-- Comments
map({ "n", "v" }, "<leader>cc", "<cmd>CommentToggle<CR>", {
	desc = "Toggle comment",
})

-- Visual indentation
map("v", "<Tab>", ">gv", { desc = "Indent selection", silent = true })
map("v", "<S-Tab>", "<gv", { desc = "Unindent selection", silent = true })

-- Insert-mode cursor movement
map("i", "<C-h>", "<Left>", { desc = "Move left", silent = true })
map("i", "<C-j>", "<Down>", { desc = "Move down", silent = true })
map("i", "<C-k>", "<Up>", { desc = "Move up", silent = true })
map("i", "<C-l>", "<Right>", { desc = "Move right", silent = true })

-- Telescope
map("n", "<leader>tf", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>tg", "<cmd>Telescope live_grep<CR>", { desc = "Search project text" })
map("n", "<leader>to", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>tb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })

-- Spectre
map("n", "<leader>sw", function()
	require("spectre").open_visual({ select_word = true })
end, { desc = "Search current word" })

map("v", "<leader>sw", function()
	require("spectre").open_visual()
end, { desc = "Search selection" })

map("n", "<leader>sp", function()
	require("spectre").open_file_search({ select_word = true })
end, { desc = "Search current file" })
