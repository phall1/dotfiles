return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- Pin to `master`: `main` is the in-progress rewrite that removed
		-- `nvim-treesitter.configs` and the `ensure_installed`/`highlight` API.
		branch = "master",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"python",
					"go",
					"rust",
					"javascript",
					"typescript",
					"tsx",
					"lua",
					"bash",
					"json",
					"yaml",
					"toml",
					"terraform",
					"markdown",
					"markdown_inline",
					"mermaid",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})

			-- nvim-treesitter's markdown injection query uses a directive that
			-- breaks on Neovim 0.12.x. Override with the runtime's built-in
			-- injection query until upstream catches up.
			vim.treesitter.query.set(
				"markdown",
				"injections",
				[[
(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
]]
			)
		end,
	},
}
