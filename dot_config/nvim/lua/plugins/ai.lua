return {
	-- Official-protocol Claude Code integration. Implements the same
	-- WebSocket/MCP that Anthropic's VS Code extension uses, so Claude sees
	-- selections, opens files, and proposes diffs through the native diff view.
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		cmd = {
			"ClaudeCode",
			"ClaudeCodeFocus",
			"ClaudeCodeSend",
			"ClaudeCodeAdd",
			"ClaudeCodeTreeAdd",
			"ClaudeCodeDiffAccept",
			"ClaudeCodeDiffDeny",
			"ClaudeCodeSelectModel",
		},
		opts = {
			-- Pin the binary path: GUI launches don't always inherit shell PATH,
			-- and `claude` is a native-binary install at ~/.local/bin/claude.
			terminal_cmd = vim.fn.expand("~/.local/bin/claude"),
		},
		keys = {
			{ "<leader>a", nil, desc = "AI / Claude Code" },
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
			{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
			{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
			{
				"<leader>as",
				"<cmd>ClaudeCodeTreeAdd<cr>",
				desc = "Add file to Claude",
				ft = { "neo-tree", "NvimTree", "oil", "minifiles", "netrw" },
			},
			{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
			{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		},
		config = true,
	},
}
