return {
	{
		"mbbill/undotree",

		keys = {
			{
				"U",
				"<cmd>UndotreeToggle<CR>",
				desc = "Toggle Undo Tree",
			},
		},

		init = function()
			vim.opt.undofile = true

			local undo_dir = vim.fn.stdpath("state") .. "/undo"

			vim.opt.undodir = undo_dir
			vim.fn.mkdir(undo_dir, "p")
		end,
	},
}
