return {
	"terrortylor/nvim-comment",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim_comment").setup({ create_mappings = false, comment_empty = false })
	end,
}
