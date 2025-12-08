return {
	"theprimeagen/harpoon",
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local harpoon = require("harpoon").setup({})

		vim.keymap.set("n", "<leader>aa", function()
			harpoon:list():add()
		end, { desc = "Tag for Harpoon" })
		vim.keymap.set("n", "<leader>ah", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Harpoon Menu" })
	end,
}
