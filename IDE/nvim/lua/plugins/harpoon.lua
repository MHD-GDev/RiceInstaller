return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",

		dependencies = {
			"nvim-lua/plenary.nvim",
		},

		opts = {
			settings = {
				save_on_toggle = true,
				save_on_change = true,
				sync_on_ui_close = true,
			},
		},

		keys = {
			{
				"<leader>aa",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon: Add file",
			},

			{
				"<leader>ah",
				function()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon: Open menu",
			},

			{
				"<leader>1",
				function()
					require("harpoon"):list():select(1)
				end,
				desc = "Harpoon: File 1",
			},

			{
				"<leader>2",
				function()
					require("harpoon"):list():select(2)
				end,
				desc = "Harpoon: File 2",
			},

			{
				"<leader>3",
				function()
					require("harpoon"):list():select(3)
				end,
				desc = "Harpoon: File 3",
			},

			{
				"<leader>4",
				function()
					require("harpoon"):list():select(4)
				end,
				desc = "Harpoon: File 4",
			},
		},
	},
}
