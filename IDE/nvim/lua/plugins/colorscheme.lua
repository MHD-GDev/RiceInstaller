return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,

	config = function()
		local platform = require("configs.platform")
		local rice = require("configs.rice")
		local catppuccin = require("catppuccin")

		local function setup_colors()
			local overrides = {}

			if platform.is_desktop_linux then
				overrides.mocha = rice.get_colors() or {}
			end

			catppuccin.setup({
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

				color_overrides = overrides,
				default_integrations = true,

				integrations = {
					cmp = true,
					gitsigns = true,
					neo_tree = true,
					treesitter = true,
					notify = true,
				},
			})

			vim.cmd.colorscheme("catppuccin")
		end

		setup_colors()

		if platform.is_desktop_linux then
			rice.register("catppuccin", setup_colors)
		end
	end,
}
