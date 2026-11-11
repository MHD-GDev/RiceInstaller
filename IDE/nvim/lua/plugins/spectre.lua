return {
	{
		"nvim-pack/nvim-spectre",
		event = "VeryLazy",

		dependencies = {
			"nvim-lua/plenary.nvim",
		},

		keys = {
			{
				"<leader>S",
				"<cmd>Spectre<CR>",
				desc = "Search and replace",
			},
		},

		opts = {},
	},
}
