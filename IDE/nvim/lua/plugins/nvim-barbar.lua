return {
	{
		"romgrk/barbar.nvim",
		event = "VeryLazy",

		init = function()
			vim.g.barbar_auto_setup = false
		end,

		opts = {
			animation = false,
			auto_hide = 0,

			sidebar_filetypes = {
				["neo-tree"] = {
					event = "BufWipeout",
				},
			},

			icons = {
				filetype = {
					custom_colors = false,
					enabled = true,
				},

				pinned = {
					button = "",
					filename = true,
				},
			},
		},
	},
}
