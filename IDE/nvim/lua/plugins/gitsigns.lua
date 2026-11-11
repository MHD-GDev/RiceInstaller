return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },

		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},

			current_line_blame = false,
		},

		keys = {
			{
				"]h",
				function()
					require("gitsigns").nav_hunk("next")
				end,
				desc = "Next Git hunk",
			},
			{
				"[h",
				function()
					require("gitsigns").nav_hunk("prev")
				end,
				desc = "Previous Git hunk",
			},
			{
				"<leader>ghs",
				function()
					require("gitsigns").stage_hunk()
				end,
				desc = "Stage Git hunk",
			},
			{
				"<leader>ghr",
				function()
					require("gitsigns").reset_hunk()
				end,
				desc = "Reset Git hunk",
			},
			{
				"<leader>ghp",
				function()
					require("gitsigns").preview_hunk()
				end,
				desc = "Preview Git hunk",
			},
			{
				"<leader>ghb",
				function()
					require("gitsigns").blame_line()
				end,
				desc = "Git blame line",
			},
		},
	},
}
