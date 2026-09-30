-- terminal.lua
-- Minimal floating terminal at bottom quarter of screen with <C-/> toggle

local M = {}

-- Helper: start a terminal job
local function jobstart(cmd, opts)
	opts = opts or {}
	local fn = vim.fn.jobstart
	if vim.fn.termopen then
		opts.term = nil
		fn = vim.fn.termopen
	end
	return fn(cmd, vim.tbl_isempty(opts) and vim.empty_dict() or opts)
end

-- Open a terminal window
function M.open(cmd)
	local buf = vim.api.nvim_create_buf(false, true)

	-- bottom quarter floating terminal
	local width = vim.o.columns
	local height = math.floor(vim.o.lines / 4)
	local row = vim.o.lines - height
	local col = 0

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "single",
	})

	vim.api.nvim_buf_set_option(buf, "filetype", "simple_terminal")

	-- start terminal job
	vim.api.nvim_buf_call(buf, function()
		jobstart(cmd or vim.o.shell, { term = true })
	end)

	vim.cmd("startinsert")
end

-- Toggle: if terminal exists, close it; otherwise open
function M.toggle(cmd)
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		local b = vim.api.nvim_win_get_buf(w)
		if vim.bo[b].filetype == "simple_terminal" then
			vim.api.nvim_win_close(w, true)
			return
		end
	end
	M.open(cmd)
end

-- Keybinding: Ctrl+/ toggles the terminal
vim.keymap.set("n", "<C-/>", function()
	M.toggle()
end, { desc = "Toggle bottom-quarter terminal" })

return M
