return {
	-- Mason package manager
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {},
	},

	-- Native Neovim LSP configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },

		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
		},

		config = function()
			local capabilities =
				require("cmp_nvim_lsp").default_capabilities()

			-- Only enable servers whose executables are available.
			local servers = {
				bashls = "bash-language-server",
				cssls = "vscode-css-language-server",
				lua_ls = "lua-language-server",
				clangd = "clangd",
				marksman = "marksman",
			}

			for server, executable in pairs(servers) do
				if vim.fn.executable(executable) == 1 then
					local config = {
						capabilities = capabilities,
					}

					if server == "clangd" then
						config.filetypes = {
							"c",
							"cpp",
							"objc",
							"objcpp",
							"cuda",
						}
					end

					vim.lsp.config(server, config)
					vim.lsp.enable(server)
				end
			end

			-- Godot
			vim.lsp.config("gdscript", {
				capabilities = capabilities,
			})
			vim.lsp.enable("gdscript")

			-- Buffer-local LSP keymaps
			local group = vim.api.nvim_create_augroup(
				"UserLspKeymaps",
				{ clear = true }
			)

			vim.api.nvim_create_autocmd("LspAttach", {
				group = group,

				callback = function(event)
					local buf = event.buf

					vim.keymap.set("n", "K", vim.lsp.buf.hover, {
						buffer = buf,
						desc = "LSP: Hover documentation",
					})

					vim.keymap.set("n", "<leader>cd",
						vim.lsp.buf.definition, {
							buffer = buf,
							desc = "LSP: Go to definition",
						}
					)

					vim.keymap.set("n", "<leader>cr",
						vim.lsp.buf.references, {
							buffer = buf,
							desc = "LSP: Find references",
						}
					)

					vim.keymap.set("n", "<leader>ca",
						vim.lsp.buf.code_action, {
							buffer = buf,
							desc = "LSP: Code action",
						}
					)
				end,
			})
		end,
	},
}
