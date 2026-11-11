return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},

		keys = {
			{
				"<leader>j",
				function()
					require("flash").jump()
				end,
				desc = "Flash Jump",
			},
			{
				"<leader>J",
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
		},
	},
}
