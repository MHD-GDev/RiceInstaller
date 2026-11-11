return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo" },

	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({
					async = true,
					lsp_format = "fallback",
				})
			end,
			desc = "Format current file",
		},
	},

	opts = {
		-- Only use installed formatters.
		notify_on_error = true,
		notify_no_formatters = false,

		format_on_save = false,

		formatters_by_ft = {
			lua = { "stylua" },

			bash = { "beautysh" },
			sh = { "beautysh" },
			zsh = { "beautysh" },

			c = { "clang-format" },
			cpp = { "clang-format" },
			objc = { "clang-format" },
			objcpp = { "clang-format" },

			python = { "isort", "black" },

			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },

			html = { "prettier" },
			css = { "prettier" },
			scss = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			markdown_inline = { "prettier" },
			xml = { "prettier" },

			go = { "gofmt" },
			rust = { "rustfmt" },
			toml = { "taplo" },

			sql = { "sql_formatter" },
			graphql = { "prettier" },
		},
	},
}
