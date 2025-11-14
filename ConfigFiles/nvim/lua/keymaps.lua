local map = vim.keymap.set
vim.g.mapleader = " "

-- disables the q recording
map("n", "q", "<Nop>")

-- Save current file
map("n", "<leader>w", ":w<cr>", { desc = "Save file", remap = true })

-- Quit Neovim
map("n", "<leader>q", ":q<cr>", { desc = "Quit Neovim", remap = true })

-- clear search highlight
map("n", "<leader>h", ":nohlsearch<CR>", { desc = "clears search highlights", noremap = true })

-- ESC pressing jk
map("i", "jk", "<ESC>", { desc = "jk to esc", noremap = true })

-- Select all
map("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true })

-- New tab
map("n", "nf", ":tabedit")

-- Split window
map("n", "<leader>sh", ":split<Return><C-w>w", { desc = "splits horizontal", noremap = true })
map("n", "<leader>sv", ":vsplit<Return><C-w>w", { desc = "Split vertical", noremap = true })

-- Navigate vim panes better
map("n", "<C-k>", "<C-w>k", { desc = "Navigate up" })
map("n", "<C-j>", "<C-w>j", { desc = "Navigate down" })
map("n", "<C-h>", "<C-w>h", { desc = "Navigate left" })
map("n", "<C-l>", "<C-w>l", { desc = "Navigate right" })

-- Change 0 split windows from vertical to horizontal or vice versa
map("n", "<leader>th", "<C-w>t<C-w>H", { desc = "Change window splits to horizontal", noremap = true })
map("n", "<leader>tv", "<C-w>t<C-w>K", { desc = "Change window splits to vertical", noremap = true })

-- Resize window
map("n", "<C-Up>", ":resize -1<CR>")
map("n", "<C-Down>", ":resize +1<CR>")
map("n", "<C-Left>", ":vertical resize -1<CR>")
map("n", "<C-Right>", ":vertical resize +1<CR>")

-- Barbar
map("n", "<Tab>", ":BufferNext<CR>", { desc = "Move to next tab", noremap = true })
map("n", "<S-Tab>", ":BufferPrevious<CR>", { desc = "Move to previous tab", noremap = true })
map("n", "<leader>x", ":BufferClose<CR>", { desc = "Buffer close", noremap = true })
map("n", "<A-p>", ":BufferPin<CR>", { desc = "Pin buffer", noremap = true })

-- Comments
map({ "n", "v" }, "<leader>cc", ":CommentToggle<cr>", { desc = "CommentToggle", noremap = true })

-- add tabs to texts in visual mode
map("v", "<Tab>", ">gv", { noremap = true, silent = true })
map("v", "<S-Tab>", "<gv", { noremap = true, silent = true })

-- Move like arrow keys in insert mode
vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })

-- Neotree
map("n", "<leader>b", ":Neotree toggle<CR>", { desc = "Toggle Neotree", noremap = true })
map("n", "<leader>nb", ":Neotree buffer reveal float<CR>", { desc = "Neotree buffers reveal", noremap = true })

-- Telescope
map("n", "<leader>tf", "<cmd>Telescope find_files<cr>", { desc = "Telescope find_files", noremap = true })
map("n", "<leader>tg", "<cmd>Telescope live_grep<cr>", { desc = "Telescope live_grep", noremap = true })
map("n", "<leader>to", "<cmd>Telescope oldfiles<cr>", { desc = "Telescope oldfiles", noremap = true })
map("n", "<leader>tb", "<cmd>Telescope buffers<cr>", { desc = "Telescope buffers", noremap = true })

-- Spectre
map("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', { desc = "Toggle Spectre", noremap = true })
map(
	"n",
	"<leader>sw",
	'<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
	{ desc = "Spectre Search current word", noremap = true }
)
map(
	"v",
	"<leader>sw",
	'<esc><cmd>lua require("spectre").open_visual()<CR>',
	{ desc = "Search current word", noremap = true }
)
map(
	"n",
	"<leader>sp",
	'<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
	{ desc = "Search on current file", noremap = true }
)
