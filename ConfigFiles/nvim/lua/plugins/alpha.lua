return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Banner
        local banner = {

            "███╗   ██╗███████╗ ██████╗ ",
            "████╗  ██║██╔════╝██╔═══██╗",
            "██╔██╗ ██║█████╗  ██║   ██║",
            "██║╚██╗██║██╔══╝  ██║   ██║",
            "██║ ╚████║███████╗╚██████╔╝",
            "╚═╝  ╚═══╝╚══════╝ ╚═════╝ ",
            "                           ",
            "███╗   ███╗██╗  ██╗██████╗ ",
            "████╗ ████║██║  ██║██╔══██╗",
            "██╔████╔██║███████║██║  ██║",
            "██║╚██╔╝██║██╔══██║██║  ██║",
            "██║ ╚═╝ ██║██║  ██║██████╔╝",
            "╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ",
        }
        dashboard.section.header.val = banner

        -- Menu
        dashboard.section.buttons.val = {
            dashboard.button("e", "󰈔 New file", ":ene <BAR> startinsert<CR>"),
            dashboard.button("r", "󱔗 Recent files", ":Telescope oldfiles<CR>"),
            dashboard.button("i", "󰒲 Lazy Manager", ":Lazy<CR>"),
            dashboard.button("m", " Mason Manager", ":Mason<CR>"),
            dashboard.button("f", "󰱼 Find file", ":Telescope find_files<CR>"),
            dashboard.button("g", "󰺮 Find text", ":Telescope live_grep <CR>"),
            dashboard.button("q", " Quit", ":qa<CR>"),
        }

        -- Footer
        local function footer()
            local version = vim.version()
            local pluginCount = vim.fn.len(vim.fn.globpath(vim.fn.stdpath("data") .. "/lazy", "*", 0, 1))
            local print_version = "v" .. version.major .. "." .. version.minor .. "." .. version.patch
            local date = os.date("%d.%m.%Y")
            --local datetime = os.date '%d.%m.%Y %H:%M'
            return " " .. print_version .. "   " .. pluginCount .. "   " .. date
        end

        dashboard.section.footer.val = footer()

        -- Colors
        -- defined in color theme (after/plugin/neosolarized.rc.lua)
        for _, button in ipairs(dashboard.section.buttons.val) do
            button.opts.hl = "AlphaButtons"
            button.opts.hl_shortcut = "AlphaShortcut"
        end
        dashboard.section.header.opts.hl = "AlphaHeader"
        dashboard.section.buttons.opts.hl = "AlphaButtons"
        dashboard.section.footer.opts.hl = "AlphaFooter"

        -- Resize the alpha based on terminal size
        -- Setup
        alpha.setup(dashboard.config)
        local function resize_dashboard()
            local width = vim.o.columns
            local height = vim.o.lines
            local max_header_lines = math.floor(height * 0.4)
            local max_buttons_per_row = math.floor(width / 20)
            local header_layout = {}
            for i = 1, #banner do
                table.insert(header_layout, { type = "text", val = banner[i], opts = { position = "center" } })
                if i % max_header_lines == 0 then
                    table.insert(header_layout, { type = "padding", val = 1 })
                end
            end
            dashboard.section.header.opts.layout = header_layout

            -- Adjust the button layout
            local button_layout = {}
            local buttons_per_row = 0
            for i = 1, #dashboard.section.buttons.val do
                table.insert(button_layout, dashboard.section.buttons.val[i])
                buttons_per_row = buttons_per_row + 1
                if buttons_per_row >= max_buttons_per_row then
                    table.insert(button_layout, { type = "padding", val = 1 })
                    buttons_per_row = 0
                end
            end
            dashboard.section.buttons.opts.layout = {
                { type = "group", val = button_layout, opts = { inline = true } },
            }

            -- Force a re-render of the dashboard
            alpha.redraw()
        end

        -- Call the resize function when the terminal size changes
        vim.cmd([[autocmd VimResized * lua require('alpha').resize_dashboard()]])

        -- Call the resize function initially
        resize_dashboard()
    end,
}
