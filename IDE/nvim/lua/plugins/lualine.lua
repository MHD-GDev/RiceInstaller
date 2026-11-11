return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",

	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},

	config = function()
		local platform = require("configs.platform")
		local rice = require("configs.rice")

		local function setup_lualine()
			local palette = {}

			local ok, catppuccin_palette = pcall(function()
				return require("catppuccin.palettes").get_palette("mocha")
			end)

			if ok and type(catppuccin_palette) == "table" then
				palette = catppuccin_palette
			end

			if platform.is_desktop_linux then
				local rice_colors = rice.get_colors()

				if type(rice_colors) == "table" then
					palette = vim.tbl_deep_extend(
						"force",
						{},
						palette,
						rice_colors
					)
				end
			end

			local colors = {
				blue = palette.blue or "#89b4fa",
				cyan = palette.teal or "#94e2d5",
				black = palette.base or "#1e1e2e",
				white = palette.text or "#cdd6f4",
				red = palette.red or "#f38ba8",
				violet = palette.mauve or "#cba6f7",
				grey = palette.surface1 or "#45475a",
				green = palette.green or "#a6e3a1",
				yellow = palette.yellow or "#f9e2af",
			}

			local theme = {
				normal = {
					a = { fg = colors.black, bg = colors.violet },
					b = { fg = colors.white, bg = colors.grey },
					c = { fg = colors.white },
				},
				insert = {
					a = { fg = colors.black, bg = colors.blue },
				},
				visual = {
					a = { fg = colors.black, bg = colors.cyan },
				},
				replace = {
					a = { fg = colors.black, bg = colors.red },
				},
				command = {
					a = { fg = colors.black, bg = colors.yellow },
				},
				inactive = {
					a = { fg = colors.white, bg = colors.black },
					b = { fg = colors.white, bg = colors.black },
					c = { fg = colors.white },
				},
			}

			require("lualine").setup({
				options = {
					theme = theme,
					globalstatus = true,

					disabled_filetypes = {
						statusline = {
							"alpha",
							"dashboard",
							"neo-tree",
						},
					},

					component_separators = "",

					section_separators = {
						left = "",
						right = "",
					},
				},

				sections = {
					lualine_a = {
						{
							"mode",
							separator = { left = "" },
							right_padding = 2,
						},
					},

					lualine_b = {
						{
							"filename",
							file_status = true,
							path = 1,
							symbols = {
								modified = " ●",
								readonly = " ",
								unnamed = "[No Name]",
							},
						},
						"branch",
						"diff",
					},

					lualine_c = {
						"diagnostics",
						"%=",
					},

					lualine_x = {
						"encoding",
						"fileformat",
					},

					lualine_y = {
						"filetype",
						"progress",
					},

					lualine_z = {
						{
							"location",
							separator = { right = "" },
							left_padding = 2,
						},
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

				extensions = {
					"neo-tree",
				},
			})
		end

		if platform.is_desktop_linux then
			rice.register("lualine", setup_lualine)
		else
			setup_lualine()
		end
	end,
}
