return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			spec = {
				{ "<leader>g", group = "Git" },
				{ "<leader>x", group = "Trouble" },
				{ "<leader>t", group = "Toggle" },
				{ "<leader>a", group = "AI / Claude" },
			},
		},
	},

	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = { focus = true },
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix (Trouble)" },
		},
	},

	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{ "<leader>n", "<cmd>Neotree toggle<cr>", desc = "File explorer" },
		},
		config = function()
			local neo_tree = require("neo-tree")
			neo_tree.setup({
				enable_git_status = true,
				enable_diagnostics = false,
				filesystem = {
					filtered_items = {
						hide_dotfiles = false,
						hide_gitignored = true,
					},
					follow_current_file = { enabled = true },
					use_libuv_file_watcher = true,
					window = {
						mappings = {
							["o"] = { "open", nowait = true },
							["<space>"] = { "toggle_node", nowait = true },
						},
					},
				},
				window = {
					width = 35,
					side = "right",
					mapping_options = { noremap = true, nowait = true },
					mappings = {
						["o"] = { "open", nowait = true },
						["<space>"] = { "toggle_node", nowait = true },
						["<cr>"] = "noop",
					},
				},
			})

			-- Toggle: cheap escape hatch for slow `git status` in huge repos.
			local git_status_async_default = neo_tree.ensure_config().git_status_async
			vim.keymap.set("n", "<leader>tg", function()
				local config = neo_tree.ensure_config()
				config.enable_git_status = not config.enable_git_status
				local manager = require("neo-tree.sources.manager")
				manager._for_each_state("filesystem", function(state)
					state.enable_git_status = config.enable_git_status
					if not config.enable_git_status then
						state.git_status_lookup = nil
						state.git_ignored = {}
					end
				end)
				if config.enable_git_status then
					config.git_status_async = git_status_async_default
					manager.refresh("filesystem")
				else
					config.git_status_async = false
					manager.redraw("filesystem")
				end
			end, { desc = "Toggle Neo-tree git status", silent = true })
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<C-p>", function() require("telescope.builtin").find_files() end, desc = "Find files" },
			{ "<leader>p", function() require("telescope.builtin").find_files() end, desc = "Find files" },
			{ "<leader>f", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
			{ "<leader>?", function() require("telescope.builtin").keymaps() end, desc = "Search keymaps" },
			{ "<leader>L", "<cmd>Lazy<cr>", desc = "Lazy plugin manager" },
			{ "<leader>gs", function() require("telescope.builtin").git_status() end, desc = "Git status" },
			{ "<leader>gc", function() require("telescope.builtin").git_commits() end, desc = "Git commits" },
			{ "<leader>dd", function() require("telescope.builtin").diagnostics() end, desc = "Diagnostics" },
		},
		opts = {
			pickers = {
				find_files = { hidden = true },
			},
		},
	},
}
