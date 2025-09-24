return {
    -- Custom Parameters (with defaults)
    {
        "MHD-GDev/LlamaGen.nvim",
        dependencies = {
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            require("llamagen").setup({
                quit_map = "q",
                retry_map = "<c-r>",
                accept_map = "<c-cr>",
                host = "localhost",
                port = "1123",
                display_mode = "float",
                show_prompt = true,
                show_model = false,
                no_auto_close = false,
                json_response = true,
                result_filetype = "markdown",
                debug = false,
            })

            -- Key mappings
            vim.keymap.set({ "n", "v" }, "<leader>]", ":Llamagen<CR>")
            vim.keymap.set("n", "<leader>gc", "<CMD>Llamagen Chat<CR>", { noremap = true })
            vim.keymap.set("n", "<leader>gg", "<CMD>Llamagen Generate<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>gD", ":'<,'>Llamagen Document_Code<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>gx", ":'<,'>Llamagen Explain_Code<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>gC", ":'<,'>Llamagen Change_Code<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>ge", ":'<,'>Llamagen Enhance_Code<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>gR", ":'<,'>Llamagen Review_Code<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>gs", ":'<,'>Llamagen Summarize<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>ga", ":'<,'>Llamagen Ask<CR>", { noremap = true })
            vim.keymap.set("v", "<leader>gF", ":'<,'>Llamagen Fix_Code<CR>", { noremap = true })
            vim.keymap.set("n", "<leader>gl", "<CMD>GenLoadModel<CR>", { noremap = true })
            vim.keymap.set("n", "<leader>gu", "<CMD>GenUnloadModel<CR>", { noremap = true })
        end,
    },
}
