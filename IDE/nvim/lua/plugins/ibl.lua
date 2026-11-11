return {
	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPre", "BufNewFile" },
		main = "ibl",

		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},

			scope = {
				enabled = true,
				show_start = true,
				show_end = false,
			},

			exclude = {
				filetypes = {
					"help",
					"alpha",
					"neo-tree",
					"dashboard",
				},
			},
		},
	},
}
