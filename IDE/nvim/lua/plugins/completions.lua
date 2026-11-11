return {
	-- LSP completion capabilities
	{
		"hrsh7th/cmp-nvim-lsp",
		lazy = true,
	},

	-- Snippet engine
	{
		"L3MON4D3/LuaSnip",
		lazy = true,

		dependencies = {
			"rafamadriz/friendly-snippets",
		},

		build = function(plugin)
			local make = vim.fn.exepath("make")

			-- JavaScript regex support is optional.
			if make == "" then
				return
			end

			vim.fn.system({
				make,
				"-C",
				plugin.dir,
				"install_jsregexp",
			})

			if vim.v.shell_error ~= 0 then
				vim.notify(
					"LuaSnip: optional jsregexp build failed",
					vim.log.levels.WARN
				)
			end
		end,

		opts = {
			history = true,
			delete_check_events = "TextChanged",
		},

		config = function(_, opts)
			require("luasnip").setup(opts)
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Completion engine
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",

		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},

		opts = function()
			local cmp = require("cmp")

			return {
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},

				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},

				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({
						select = true,
					}),
				}),

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
				}),
			}
		end,
	},
}
