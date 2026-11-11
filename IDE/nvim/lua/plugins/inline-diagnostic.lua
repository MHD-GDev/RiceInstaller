return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,

		opts = {
			preset = "modern",

			signs = {
				left = "",
				right = "",
			},

			options = {
				multilines = {
					enabled = true,
					always_show = false,
				},
			},
		},

		config = function(_, opts)
			require("tiny-inline-diagnostic").setup(opts)

			vim.diagnostic.config({
				virtual_text = false,
			})
		end,
	},
}
