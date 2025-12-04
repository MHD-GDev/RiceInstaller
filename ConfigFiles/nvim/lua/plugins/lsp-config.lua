return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			ensure_installed = {},
			auto_install = true,
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- new API
			vim.lsp.config("bashls", { capabilities = capabilities })
			vim.lsp.config("cssls", { capabilities = capabilities })
			vim.lsp.config("lua_ls", { capabilities = capabilities })
			vim.lsp.config("clangd", { capabilities = capabilities })
			vim.lsp.config("marksman", { capabilities = capabilities })

			-- keymaps
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "Code Definitions" })
			vim.keymap.set("n", "<leader>cr", vim.lsp.buf.references, { desc = "Code References" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
		end,
	},
}
