return {
	-- Custom Parameters (with defaults)
	{
		"MHD-GDev/genlms.nvim",
		dependencies = {
			"nvim-lualine/lualine.nvim",
		},
		config = function()
			require("genlms").setup({
				quit_map = "q",
				retry_map = "<c-r>",
				accept_map = "<c-cr>",
				host = "localhost",
				port = "1123",
				display_mode = "split",
				show_prompt = true,
				show_model = false,
				no_auto_close = false,
				json_response = true,
				result_filetype = "markdown",
				debug = false,
			})

			-- Key mappings
			vim.keymap.set({ "n", "v" }, "<leader>]", ":Genlms<CR>")
			vim.keymap.set("n", "<leader>gc", "<CMD>Genlms Chat<CR>", { noremap = true })
			vim.keymap.set("n", "<leader>gg", "<CMD>Genlms Generate<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>gD", ":'<,'>Genlms Document_Code<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>gx", ":'<,'>Genlms Explain_Code<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>gC", ":'<,'>Genlms Change_Code<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>ge", ":'<,'>Genlms Enhance_Code<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>gR", ":'<,'>Genlms Review_Code<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>gs", ":'<,'>Genlms Summarize<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>ga", ":'<,'>Genlms Ask<CR>", { noremap = true })
			vim.keymap.set("v", "<leader>gF", ":'<,'>Genlms Fix_Code<CR>", { noremap = true })
			vim.keymap.set("n", "<leader>gl", "<CMD>GenLoadModel<CR>", { noremap = true })
			vim.keymap.set("n", "<leader>gu", "<CMD>GenUnloadModel<CR>", { noremap = true })
		end,
	},
}
