return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				bash = { "beautysh" },
				sh = { "beautysh" },
				css = { "prettier" },
				markdown = { "prettier" },
				python = { "black", "isort" },
				cpp = { "clang-format" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timout_ms = 1000,
			},
		})
	end,
}
