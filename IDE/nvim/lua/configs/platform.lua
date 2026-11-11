local M = {}

M.is_windows = vim.fn.has("win32") == 1
M.is_linux = vim.fn.has("linux") == 1
M.is_macos = vim.fn.has("mac") == 1
M.is_termux = M.is_linux and (
	vim.env.TERMUX_VERSION ~= nil
	or vim.env.PREFIX == "/data/data/com.termux/files/usr"
)

M.is_desktop_linux = M.is_linux and not M.is_termux

return M
