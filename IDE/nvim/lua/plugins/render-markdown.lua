return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },

		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},

		opts = {
			completions = {
				lsp = {
					enabled = false,
				},
			},

			heading = {
				sign = true,
				width = "full",
			},

			code = {
				sign = true,
				width = "block",
				border = "thin",
			},

			anti_conceal = {
				enabled = true,
			},
		},
	},
}
