return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	cmd = "Neotree",

	keys = {
		{
			"<leader>b",
			"<cmd>Neotree toggle<CR>",
			desc = "Toggle file explorer",
		},
		{
			"<leader>nb",
			"<cmd>Neotree buffers reveal float<CR>",
			desc = "Show buffers in explorer",
		},
	},

	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},

	opts = {
		close_if_last_window = false,
		popup_border_style = "rounded",
		enable_git_status = true,
		enable_diagnostics = true,

		source_selector = {
			winbar = false,
			statusline = false,
		},

		filesystem = {
			follow_current_file = {
				enabled = false,
			},

			use_libuv_file_watcher = true,

			filtered_items = {
				visible = true,
				show_hidden_count = true,
				hide_dotfiles = false,
				hide_gitignored = true,

				hide_by_name = {},
				never_show = {},
			},

			window = {
				width = 32,
			},
		},
	},

	config = function(_, opts)
		require("neo-tree").setup(opts)
	end,
}
