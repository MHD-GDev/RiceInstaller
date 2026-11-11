local M = {}

local terminal_buf = nil
local terminal_win = nil

local function get_terminal_size()
	local width = math.max(1, vim.o.columns - 4)
	local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight - 4) / 4))

	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, vim.o.lines - height - vim.o.cmdheight - 3),
		col = 2,
		style = "minimal",
		border = "single",
	}
end

local function create_terminal()
	terminal_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[terminal_buf].bufhidden = "hide"
	vim.bo[terminal_buf].filetype = "simple_terminal"

	local ok, job = pcall(vim.api.nvim_buf_call, terminal_buf, function()
		return vim.fn.termopen(vim.o.shell)
	end)

	if not ok or job <= 0 then
		vim.api.nvim_buf_delete(terminal_buf, { force = true })
		terminal_buf = nil

		vim.notify("Could not start terminal", vim.log.levels.ERROR)
		return false
	end

	return true
end

function M.open()
	if terminal_buf and not vim.api.nvim_buf_is_valid(terminal_buf) then
		terminal_buf = nil
	end

	if not terminal_buf and not create_terminal() then
		return
	end

	if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
		return
	end

	terminal_win = vim.api.nvim_open_win(
		terminal_buf,
		true,
		get_terminal_size()
	)

	vim.cmd("startinsert")
end

function M.close()
	if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
		vim.api.nvim_win_close(terminal_win, true)
	end

	terminal_win = nil
end

function M.toggle()
	if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
		M.close()
	else
		M.open()
	end
end

function M.resize()
	if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
		vim.api.nvim_win_set_config(terminal_win, get_terminal_size())
	end
end

vim.keymap.set("n", "<C-/>", M.toggle, {
	desc = "Toggle floating terminal",
})

vim.keymap.set("t", "<C-/>", function()
	vim.cmd("stopinsert")
	M.toggle()
end, {
	desc = "Toggle floating terminal",
})

local group = vim.api.nvim_create_augroup("FloatingTerminal", {
	clear = true,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	callback = M.resize,
})

return M
