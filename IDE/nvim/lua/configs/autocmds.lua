local group = vim.api.nvim_create_augroup("UserAutocmds", {
	clear = true,
})

-- Native Treesitter highlighting for parsers bundled with Neovim.
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = {
		"c",
		"diff",
		"lua",
		"markdown",
		"query",
		"vim",
		"vimdoc",
	},
	callback = function(event)
		pcall(vim.treesitter.start, event.buf)
	end,
})

-- Highlight yanked text briefly.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

-- Return to the last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function(event)
		local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(event.buf)

		if mark[1] > 0 and mark[1] <= line_count then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Remove trailing whitespace before saving.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	callback = function(event)
		local buf = event.buf

		if vim.bo[buf].modifiable and not vim.bo[buf].binary then
			vim.api.nvim_buf_call(buf, function()
				local view = vim.fn.winsaveview()
				vim.cmd([[%s/\s\+$//e]])
				vim.fn.winrestview(view)
			end)
		end
	end,
})

-- Automatically resize splits when the terminal window changes.
vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- Close certain temporary windows with q.
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = {
		"help",
		"checkhealth",
		"lspinfo",
		"qf",
		"man",
		"notify",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false

		vim.keymap.set("n", "q", "<cmd>close<CR>", {
			buffer = event.buf,
			silent = true,
			desc = "Close temporary window",
		})
	end,
})
