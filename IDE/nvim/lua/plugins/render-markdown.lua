return {
	"MeanderingProgrammer/render-markdown.nvim",
	config = function()
		require("render-markdown").setup({
			completions = { lsp = { enabled = true } },
		})
	end,
}
