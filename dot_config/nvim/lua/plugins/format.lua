return {
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")

			-- Resolve prettier config from the file's directory, not from cwd —
			-- so monorepos with per-package prettier configs format correctly.
			conform.formatters.prettier = {
				prepend_args = function(_, ctx)
					local config_files = {
						".prettierrc",
						".prettierrc.json",
						".prettierrc.yml",
						".prettierrc.yaml",
						".prettierrc.json5",
						".prettierrc.js",
						".prettierrc.cjs",
						".prettierrc.mjs",
						".prettierrc.toml",
						"prettier.config.js",
						"prettier.config.cjs",
						"prettier.config.mjs",
					}
					local config_path = vim.fs.find(config_files, {
						upward = true,
						type = "file",
						path = vim.fs.dirname(ctx.filename),
					})[1]
					if config_path then
						return { "--config", config_path }
					end
					return {}
				end,
			}

			conform.setup({
				formatters_by_ft = {
					python = { "ruff_format" },
					go = { "gofmt" },
					rust = { "rustfmt" },
					javascript = { "prettier" },
					javascriptreact = { "prettier" },
					typescript = { "prettier" },
					typescriptreact = { "prettier" },
					json = { "prettier" },
					terraform = { "terraform_fmt" },
					lua = { "stylua" },
				},
				format_on_save = {
					timeout_ms = 2000,
					lsp_fallback = true,
				},
			})
		end,
	},

	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("Lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function() lint.try_lint() end,
			})
		end,
	},
}
