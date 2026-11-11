return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
		lazy = true,
	},

	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",

		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},

		opts = function()
			local themes = require("telescope.themes")

			return {
				defaults = {
					prompt_prefix = "   ",
					selection_caret = " ",
					path_display = { "truncate" },
					sorting_strategy = "ascending",

					layout_config = {
						prompt_position = "top",
					},
				},

				extensions = {
					["ui-select"] = themes.get_dropdown({}),
				},
			}
		end,

		config = function(_, opts)
			local telescope = require("telescope")

			telescope.setup(opts)

			pcall(telescope.load_extension, "ui-select")
		end,
	},
}
