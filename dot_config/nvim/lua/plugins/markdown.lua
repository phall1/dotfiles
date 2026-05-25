return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		ft = { "markdown", "opencode_output" },
		opts = {
			anti_conceal = { enabled = false },
			file_types = { "markdown", "opencode_output" },
			heading = {
				enabled = true,
				sign = true,
				icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
			},
			code = {
				enabled = true,
				sign = true,
				style = "full",
				border = "thin",
			},
			bullet = {
				enabled = true,
				icons = { "●", "○", "◆", "◇" },
			},
			checkbox = {
				enabled = true,
				unchecked = { icon = "☐ " },
				checked = { icon = "☑ " },
			},
			quote = { enabled = true },
			pipe_table = { enabled = true, style = "full" },
			link = { enabled = true },
		},
	},
}
