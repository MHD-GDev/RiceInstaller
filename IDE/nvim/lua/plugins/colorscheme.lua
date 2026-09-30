return {
    "catppuccin/nvim",
    config = function()
        -- Function to read colors from a file
        local function read_rice_colors()
            local colors_file = vim.fn.expand("~/.config/nvim/rice_colors.lua")
            if vim.fn.filereadable(colors_file) == 1 then
                local ok, colors = pcall(dofile, colors_file)
                if ok and colors then
                    return colors
                end
            end
            -- Fallback to default colors
            return {
                yellow = "#fe640b",
                peach = "#ffac23", 
                green = "#1d9f50",
                red = "#cc342b",
                sky = "#81a7ff",
                pink = "#a36ac7",
                blue = "#3971ed",
                mauve = "#ea76cb",
                overlay2 = "#8b8c8b",
                text = "#c5c8c6",
                lavender = "#b7bfda"
            }
        end

        require("catppuccin").setup({
            flavour = "mocha",
            transparent_background = true,
            show_end_of_buffer = false,
            term_colors = true,
            dim_inactive = {
                enabled = false,
            },
            no_italic = false,
            no_bold = false,
            no_underline = false,
            styles = {
                comments = { "italic" },
                conditionals = { "italic" },
            },
            color_overrides = {
                mocha = read_rice_colors()
            },
            default_integrations = true,
            integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                notify = true,
            },
        })
        
        vim.cmd([[colorscheme catppuccin]])
        
        -- Auto-reload when colors file changes
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = vim.fn.expand("~/.config/nvim/rice_colors.lua"),
            callback = function()
                vim.cmd("source " .. vim.fn.expand("~/.config/nvim/lua/plugins/colorscheme.lua"))
                vim.cmd("colorscheme catppuccin")
            end,
        })
    end
}
