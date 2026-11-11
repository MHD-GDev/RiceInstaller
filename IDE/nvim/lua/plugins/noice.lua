return {
	{
		"folke/noice.nvim",
		event = "VeryLazy",

		dependencies = {
			"MunifTanjim/nui.nvim",
		},

		opts = {
			notify = {
				-- Let Snacks handle vim.notify.
				enabled = false,
			},

			messages = {
				enabled = true,
				view = "mini",
				view_error = "mini",
				view_warn = "mini",
				view_history = "messages",
				view_search = "virtualtext",
			},

			popupmenu = {
				enabled = true,
				backend = "nui",
			},

			lsp = {
				progress = {
					enabled = true,
				},

				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},

			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = true,
			},
		},
	},
}
