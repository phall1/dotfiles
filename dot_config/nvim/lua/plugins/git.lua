return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			current_line_blame = true,
			current_line_blame_opts = {
				delay = 200,
				virt_text_pos = "eol",
				ignore_whitespace = true,
			},
			current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",
		},
		keys = {
			{ "<leader>gb", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle Git blame" },
		},
		config = function(_, opts)
			require("gitsigns").setup(opts)
			vim.api.nvim_create_user_command("BlameOn", function() require("gitsigns").toggle_current_line_blame(true) end, {})
			vim.api.nvim_create_user_command("BlameOff", function() require("gitsigns").toggle_current_line_blame(false) end, {})
			vim.api.nvim_create_user_command("BlameToggle", function() require("gitsigns").toggle_current_line_blame() end, {})
		end,
	},

	{
		"tpope/vim-fugitive",
		cmd = { "Git", "Gblame" },
		config = function()
			vim.cmd("command! -nargs=* Gblame Git blame --date=short --abbrev=8 <args>")
		end,
	},

	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff working changes" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },
		},
		opts = {},
	},

	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		keys = {
			{ "<leader>gn", function() require("neogit").open() end, desc = "Neogit (git UI)" },
		},
		opts = {
			integrations = { diffview = true, telescope = true },
		},
	},

	{
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		cmd = { "Octo" },
		opts = {},
	},
}
