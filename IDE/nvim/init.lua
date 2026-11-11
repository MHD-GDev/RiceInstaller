-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	if vim.fn.executable("git") ~= 1 then
		error("Git is required to bootstrap lazy.nvim.")
	end

	local result = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})

	if vim.v.shell_error ~= 0 or not vim.uv.fs_stat(lazypath) then
		error("Failed to install lazy.nvim:\n" .. result)
	end
end

vim.opt.rtp:prepend(lazypath)

-- Core configuration
require("configs.platform")
require("configs.options")
require("configs.keymaps")
require("configs.autocmds")

-- Custom floating terminal
require("terminal")

-- Dynamic Linux rice colors
require("configs.rice").start()

-- Plugin manager
require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},

	defaults = {
		lazy = false,
	},

	checker = {
		enabled = false,
	},

	-- No plugins currently require LuaRocks.
	rocks = {
		enabled = false,
	},
})
