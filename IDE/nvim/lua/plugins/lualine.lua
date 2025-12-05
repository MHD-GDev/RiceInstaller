return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	config = function()
		-- Extend Lua's search path to include ~/.config/nvim
		package.path = package.path .. ";" .. vim.fn.stdpath("config") .. "/?.lua"

		-- Try to load rice_colors.lua from ~/.config/nvim
		local ok, rice_colors = pcall(require, "rice_colors")
		if not ok then
			-- Fallback colors if rice_colors.lua is missing
			rice_colors = {
				blue = "#80a0ff",
				teal = "#79dac8",
				base = "#080808",
				text = "#c6c6c6",
				red = "#ff5189",
				mauve = "#d183e8",
				surface1 = "#303030",
			}
		end

		-- Map rice colors into lualine palette
		local colors = {
			blue = rice_colors.blue,
			cyan = rice_colors.teal, -- mapped from teal
			black = rice_colors.base,
			white = rice_colors.text,
			red = rice_colors.red,
			violet = rice_colors.mauve,
			grey = rice_colors.surface1,
		}

		local bubbles_theme = {
			normal = {
				a = { fg = colors.black, bg = colors.violet },
				b = { fg = colors.white, bg = colors.grey },
				c = { fg = colors.white },
			},

			insert = { a = { fg = colors.black, bg = colors.blue } },
			visual = { a = { fg = colors.black, bg = colors.cyan } },
			replace = { a = { fg = colors.black, bg = colors.red } },

			inactive = {
				a = { fg = colors.white, bg = colors.black },
				b = { fg = colors.white, bg = colors.black },
				c = { fg = colors.white },
			},
		}

		require("lualine").setup({
			options = {
				theme = bubbles_theme,
				component_separators = "",
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
				lualine_b = { "filename", "branch" },
				lualine_c = {
					"%=", --[[ add your center components here ]]
				},
				lualine_x = {},
				lualine_y = { "filetype", "progress" },
				lualine_z = {
					{ "location", separator = { right = "" }, left_padding = 2 },
				},
			},
			inactive_sections = {
				lualine_a = { "filename" },
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = { "location" },
			},
			tabline = {},
			extensions = {},
		})
	end,
}
