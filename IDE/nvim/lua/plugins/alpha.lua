return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	init = false,

	opts = function()
		local dashboard = require("alpha.themes.dashboard")

		dashboard.section.header.val = {
			"███╗   ███╗██╗  ██╗██████╗ ",
			"████╗ ████║██║  ██║██╔══██╗",
			"██╔████╔██║███████║██║  ██║",
			"██║╚██╔╝██║██╔══██║██║  ██║",
			"██║ ╚═╝ ██║██║  ██║██████╔╝",
			"╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ",
		}

		dashboard.section.buttons.val = {
			dashboard.button("e", "󰈔 New file", "<cmd>ene<CR>"),
			dashboard.button("r", "󱔗 Recent files", "<cmd>Telescope oldfiles<CR>"),
			dashboard.button("i", "󰒲 Lazy Manager", "<cmd>Lazy<CR>"),
			dashboard.button("m", "󰍉 Mason Manager", "<cmd>Mason<CR>"),
			dashboard.button("f", "󰱼 Find file", "<cmd>Telescope find_files<CR>"),
			dashboard.button("g", "󰺮 Find text", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("q", "󰅚 Quit", "<cmd>qa<CR>"),
		}

		local version = vim.version()
		local nvim_version = string.format(
			"v%d.%d.%d",
			version.major,
			version.minor,
			version.patch
		)

		local plugin_count = require("lazy").stats().count
		local date = os.date("%d.%m.%Y")

		dashboard.section.footer.val = string.format(
			" %s   %d   %s",
			nvim_version,
			plugin_count,
			date
		)

		for _, button in ipairs(dashboard.section.buttons.val) do
			button.opts.hl = "AlphaButtons"
			button.opts.hl_shortcut = "AlphaShortcut"
		end

		dashboard.section.header.opts.hl = "AlphaHeader"
		dashboard.section.buttons.opts.hl = "AlphaButtons"
		dashboard.section.footer.opts.hl = "AlphaFooter"

		return dashboard
	end,

	config = function(_, dashboard)
		require("alpha").setup(dashboard.opts)
	end,
}
