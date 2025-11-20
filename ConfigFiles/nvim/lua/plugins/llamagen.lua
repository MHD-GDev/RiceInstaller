return {
	{
		"MHD-GDev/LlamaGen.nvim",
		dependencies = {
			"nvim-lualine/lualine.nvim",
		},
		config = function()
			require("llamagen").setup({
				-- Required: Directory where your .gguf model files are stored
				model_dir = "~/.local/share/AI-Models", -- Change this to your models directory

				-- Server Configuration
				host = "localhost", -- llama-server host
				port = "1123", -- llama-server port

				-- Model Settings
				enable_rag = true, -- Enable RAG (context from past conversations)
				rag_top_k = 3, -- Number of similar exchanges to retrieve

				-- Display Settings
				display_mode = "horizontal-split", -- "float" | "horizontal-split" | "vertical-split"
				result_filetype = "markdown",
				show_prompt = false, -- Show prompt in results
				show_model = false, -- Show model name
				no_auto_close = true, -- Auto-close after operation
				hidden = false, -- Hide window (for float mode)

				-- Behavior
				debug = false, -- Enable debug output

				-- Model Generation
				body = {
					max_tokens = -1, -- -1 for unlimited
					stream = true, -- Enable streaming responses
					temperature = 0.5, -- 0-2, lower = more focused
				},

				-- Keymaps in result buffer
				quit_map = "q",
				retry_map = "<c-r>",
			})

			-- Optional: Add global keymaps
			local map = vim.keymap.set

			-- General
			map({ "n", "v" }, "<leader>]", ":Llamagen<CR>", { noremap = true, silent = true })

			-- Model Management
			map("n", "<leader>gl", ":GenLoadModel<CR>", { noremap = true, silent = true })
			map("n", "<leader>gu", ":GenUnloadModel<CR>", { noremap = true, silent = true })
			map("n", "<leader>gs", ":GenModelStatus<CR>", { noremap = true, silent = true })

			-- Chat & Generation
			map("n", "<leader>gc", ":Llamagen Chat<CR>", { noremap = true, silent = true })
			map("n", "<leader>gg", ":Llamagen Generate<CR>", { noremap = true, silent = true })

			-- Code Operations (Visual Mode)
			map("v", "<leader>gx", ":Llamagen Explain_Code<CR>", { noremap = true, silent = true })
			map("v", "<leader>gC", ":Llamagen Change_Code<CR>", { noremap = true, silent = true })
			map("v", "<leader>ge", ":Llamagen Enhance_Code<CR>", { noremap = true, silent = true })
			map("v", "<leader>gR", ":Llamagen Review_Code<CR>", { noremap = true, silent = true })
			map("v", "<leader>gD", ":Llamagen Document_Code<CR>", { noremap = true, silent = true })
			map("v", "<leader>gF", ":Llamagen Fix_Code<CR>", { noremap = true, silent = true })

			-- Text Operations (Visual Mode)
			map("v", "<leader>gs", ":Llamagen Summarize<CR>", { noremap = true, silent = true })
			map("v", "<leader>ga", ":Llamagen Ask<CR>", { noremap = true, silent = true })
		end,
	},
}
