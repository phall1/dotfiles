-- Yank to clipboard
vim.opt.clipboard = "unnamedplus"

-- Ensure user-local binaries are on PATH (GUI launches may miss shell PATH)
do
	local local_bin = vim.fn.expand("~/.local/bin")
	if not vim.env.PATH:find(local_bin, 1, true) then
		vim.env.PATH = local_bin .. ":" .. vim.env.PATH
	end
end

-- Ensure project-local node binaries are on PATH (formatters like prettier)
local function add_node_bin_to_path()
	local buf_path = vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		return
	end

	local node_bin = vim.fs.find("node_modules/.bin", {
		upward = true,
		type = "directory",
		path = vim.fs.dirname(buf_path),
	})[1]

	if node_bin and not vim.env.PATH:find(node_bin, 1, true) then
		vim.env.PATH = node_bin .. ":" .. vim.env.PATH
	end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufReadPost" }, {
	pattern = {
		"*.ts",
		"*.tsx",
		"*.js",
		"*.jsx",
		"*.json",
		"*.md",
		"*.css",
		"*.scss",
		"*.yml",
		"*.yaml",
	},
	callback = add_node_bin_to_path,
})

-- Unset RUSTUP_TOOLCHAIN so rustup can use rust-toolchain.toml per-project
vim.env.RUSTUP_TOOLCHAIN = nil

-- Mapleader key
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Editor settings
vim.opt.number = true -- show absolute line numbers
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.tabstop = 4 -- number of spaces tabs count for
vim.opt.shiftwidth = 4 -- size of an indent
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.smartindent = true -- smart autoindenting on new lines
vim.opt.wrap = false -- disable line wrapping
vim.opt.cursorline = true -- highlight current line
vim.opt.termguicolors = true -- enable full RGB colors
vim.opt.signcolumn = "yes" -- always show sign column (for git/lsp indicators)
vim.opt.scrolloff = 5 -- keep 5 lines visible above/below cursor
vim.opt.sidescrolloff = 8 -- same horizontally
vim.opt.ignorecase = true -- case-insensitive search by default
vim.opt.smartcase = true -- but case-sensitive if search includes uppercase
vim.opt.splitbelow = true -- horizontal splits open below
vim.opt.splitright = true -- vertical splits open to the right
vim.opt.updatetime = 300 -- faster updates
vim.opt.timeoutlen = 400 -- shorter key sequence timeout
vim.opt.mouse = "a" -- enable mouse support

-- Colorscheme
vim.cmd("colorscheme twenty")

-- Lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
	-- Trouble: project-wide diagnostics panel
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			focus = true,
		},
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix (Trouble)" },
		},
	},

	-- Neo-tree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local neo_tree = require("neo-tree")
			neo_tree.setup({
				-- Git status is enabled, but you can toggle it off for performance
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
						-- Override the default "o = order_by" prefix which waits for timeoutlen
						mappings = {
							["o"] = { "open", nowait = true },
							["<space>"] = { "toggle_node", nowait = true },
						},
					},
				},
				window = {
					width = 35,
					side = "right",
					mapping_options = {
						noremap = true,
						nowait = true,
					},
					mappings = {
						["o"] = { "open", nowait = true },
						["<space>"] = { "toggle_node", nowait = true },
						["<cr>"] = "noop",
					},
				},
			})

			local git_status_async_default = neo_tree.ensure_config().git_status_async
			local function toggle_neotree_git_status()
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
			end
			vim.keymap.set("n", "<leader>n", ":Neotree toggle<CR>", { silent = true })
			vim.keymap.set("n", "<leader>tg", toggle_neotree_git_status, {
				desc = "Toggle Neo-tree git status",
				silent = true,
			})
		end,
	},

	-- Telescope (Command-P style fuzzy finder)
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			telescope.setup({
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			})

			-- files / grep
			vim.keymap.set("n", "<C-p>", builtin.find_files, { silent = true })
			vim.keymap.set("n", "<leader>p", builtin.find_files, { silent = true })
			vim.keymap.set("n", "<leader>f", builtin.live_grep, { silent = true })

			-- git pickers
			vim.keymap.set("n", "<leader>gs", builtin.git_status, {
				silent = true,
				desc = "Git status (staged/unstaged)",
			})
			vim.keymap.set("n", "<leader>gc", builtin.git_commits, {
				silent = true,
				desc = "Git commits",
			})
			vim.keymap.set("n", "<leader>dd", builtin.diagnostics, {
				silent = true,
				desc = "Diagnostics (Telescope)",
			})
		end,
	},

	-- Tree sitter ( syntax highligting and that)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
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
		end,
	},

	-- Git signs + inline blame on cursor line
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			-- Shows commit info as virtual text for the current line
			current_line_blame = true,
			current_line_blame_opts = {
				delay = 200,
				virt_text_pos = "eol",
				ignore_whitespace = true,
			},
			current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",
		},
	},

	-- `:Git blame` split view (similar to old :Gblame)
	{ "tpope/vim-fugitive" },

	-- Octo: GitHub issues & PRs from Neovim
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

	-- LSP + Autocomplete
	{
		"mrcjkb/rustaceanvim",
		version = "^5", -- Recommended
		lazy = false, -- This plugin is already lazy
		config = function()
			vim.g.rustaceanvim = {
				-- Plugin configuration
				tools = {},
				-- LSP configuration
				server = {
					-- Use rustup run to pick the correct toolchain for the workspace
					cmd = function()
						local cargo_toml = vim.fs.find("Cargo.toml", {
							upward = true,
							type = "file",
							path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
						})[1]
						if cargo_toml then
							local workspace_root = vim.fs.dirname(cargo_toml)
							-- Let rustup auto-detect the toolchain from rust-toolchain.toml
							-- or fallback to the active toolchain for this workspace
							return { "rustup", "run", "--install", "rust-analyzer" }
						end
						-- Fallback to default rust-analyzer
						return { "rust-analyzer" }
					end,
					on_attach = function(client, bufnr)
						-- You can add Rust-specific keymaps here if you want
						-- For now, the global LSP keymaps will still work because
						-- rustaceanvim attaches to the buffer like any other LSP.
					end,
					default_settings = {
						-- rust-analyzer language server configuration
						["rust-analyzer"] = {
							checkOnSave = true,
							check = {
								command = "clippy",
							},
						},
					},
				},
			}
		end,
	},

	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
			"hrsh7th/nvim-cmp",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			-- Mason: automatic LSP installer
			require("mason").setup()
			-- mason-lspconfig setup moved below to share capabilities

			-- nvim-cmp: completion setup
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})

			-- Attach LSP servers
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local uv = vim.uv or vim.loop
			local function setup_lua_ls()
				local settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
							path = {
								"lua/?.lua",
								"lua/?/init.lua",
							},
						},
						diagnostics = { globals = { "vim" } },
						workspace = {
							checkThirdParty = false,
							library = { vim.env.VIMRUNTIME },
						},
						telemetry = { enable = false },
					},
				}

				local on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if
							path ~= vim.fn.stdpath("config")
							and (uv.fs_stat(path .. "/.luarc.json") or uv.fs_stat(path .. "/.luarc.jsonc"))
						then
							return
						end
					end

					client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, settings.Lua)
				end

				if vim.lsp.config and vim.lsp.enable then
					vim.lsp.config("lua_ls", {
						capabilities = capabilities,
						on_init = on_init,
						settings = settings,
					})
					vim.lsp.enable("lua_ls")
					return
				end

				local lspconfig = require("lspconfig")
				lspconfig.lua_ls.setup({
					capabilities = capabilities,
					on_init = on_init,
					settings = settings,
				})
			end

			require("mason-lspconfig").setup({
				ensure_installed = {
					"gopls",
					"ts_ls",
					"terraformls",
					"dockerls",
					"lua_ls",
				},
			})

			local default_servers = {
				"gopls",
				"ts_ls",
				"terraformls",
				"dockerls",
			}
			if vim.lsp.config and vim.lsp.enable then
				for _, server_name in ipairs(default_servers) do
					vim.lsp.config(server_name, {
						capabilities = capabilities,
					})
					vim.lsp.enable(server_name)
				end
				setup_lua_ls()
			else
				local lspconfig = require("lspconfig")
				for _, server_name in ipairs(default_servers) do
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end
				setup_lua_ls()
			end

			-- Python LSP: ty (replaces pyright)
			if vim.lsp.config and vim.lsp.enable then
				-- Optional: Only required if you need to update the language server settings
				vim.lsp.config("ty", {
					capabilities = capabilities,
					cmd = { "ty", "server" },
					filetypes = { "python" },
					root_markers = { ".venv", "pyproject.toml", "uv.lock", "setup.py", "setup.cfg", "requirements.txt" },
					settings = {
						ty = {
							-- ty language server settings go here
						},
					},
				})

				-- Required: Enable the language server
				vim.lsp.enable("ty")
			end

			-- Diagnostics style (modern vim.diagnostic.config API)
			vim.diagnostic.config({
				signs = {
					text = {
						[1] = "✘", -- ERROR
						[2] = "▲", -- WARN
						[3] = "»", -- INFO
						[4] = "⚑", -- HINT
					},
				},
				virtual_text = {
					prefix = "●",
				},
				float = { border = "rounded" },
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			-- Enable inlay hints globally (Neovim 0.10+)
			vim.lsp.inlay_hint.enable(true)

			-- Keymaps for LSP actions
			local map = vim.keymap.set
			map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			map("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
			map("n", "K", vim.lsp.buf.hover, { desc = "Hover info" })
			map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
			map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
			map("n", "<leader>ne", vim.diagnostic.goto_next, { desc = "Next error" })
			map("n", "<leader>pe", vim.diagnostic.goto_prev, { desc = "Previous error" })
			map("n", "<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, { desc = "Toggle inlay hints" })
		end,
	},

	-- Formatter (Conform)
	{
		"stevearc/conform.nvim",
		config = function()
			local conform = require("conform")

			-- Custom prettier that finds config relative to the file being formatted
			conform.formatters.prettier = {
				prepend_args = function(self, ctx)
					-- Search upward from the file for a prettier config
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
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
	{
		"dustinblackman/oatmeal.nvim",
		cmd = { "Oatmeal" },
		keys = {
			{ "<leader>om", mode = "n", desc = "Start Oatmeal session" },
		},
		opts = {
			backend = "ollama",
			model = "codellama:latest",
		},
	},
	-- =========================================================================
	-- MARKDOWN EDITING SUITE
	-- =========================================================================

	-- render-markdown.nvim: In-buffer rendering (conceals ugly syntax)
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

	-- image.nvim: Render images IN-TERMINAL (Ghostty/Kitty protocol)
	{
		"3rd/image.nvim",
		ft = { "markdown" },
		opts = {
			backend = "kitty", -- Ghostty uses Kitty protocol
			processor = "magick_cli", -- Use ImageMagick CLI
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					filetypes = { "markdown" },
				},
			},
			max_width = 100,
			max_height = 12,
			max_height_window_percentage = 50,
			max_width_window_percentage = nil,
			window_overlap_clear_enabled = true,
			window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
		},
	},

	-- vim-table-mode: Auto-align tables as you type
	{
		"dhruvasagar/vim-table-mode",
		ft = { "markdown" },
		init = function()
			vim.g.table_mode_corner = "|"
		end,
		keys = {
			{ "<leader>tm", "<cmd>TableModeToggle<cr>", desc = "Toggle Table Mode" },
		},
	},

	-- mkdnflow.nvim: Link navigation and list management
	{
		"jakewvincent/mkdnflow.nvim",
		ft = { "markdown" },
		opts = {
			modules = {
				bib = false,
				buffers = true,
				conceal = false, -- render-markdown handles this
				cursor = true,
				folds = false,
				links = true,
				lists = true,
				maps = true,
				paths = true,
				tables = false, -- vim-table-mode handles this
				yaml = false,
			},
			links = {
				style = "markdown",
				transform_explicit = false,
			},
			lists = {
				indent_new_list_items = true,
			},
			mappings = {
				MkdnEnter = { { "n", "v" }, "<CR>" },
				MkdnTab = false,
				MkdnSTab = false,
				MkdnNextLink = { "n", "<Tab>" },
				MkdnPrevLink = { "n", "<S-Tab>" },
				MkdnNextHeading = { "n", "]]" },
				MkdnPrevHeading = { "n", "[[" },
				MkdnGoBack = { "n", "<BS>" },
				MkdnGoForward = { "n", "<Del>" },
				MkdnFollowLink = false, -- using <CR> instead
				MkdnDestroyLink = { "n", "<M-CR>" },
				MkdnToggleToDo = { { "n", "v" }, "<C-Space>" },
				MkdnNewListItem = false,
				MkdnNewListItemBelowInsert = { "n", "o" },
				MkdnNewListItemAboveInsert = { "n", "O" },
				MkdnExtendList = false,
				MkdnUpdateNumbering = { "n", "<leader>nn" },
				MkdnTableNextCell = { "i", "<Tab>" },
				MkdnTablePrevCell = { "i", "<S-Tab>" },
				MkdnTableNextRow = false,
				MkdnTablePrevRow = { "i", "<M-CR>" },
				MkdnTableNewRowBelow = { "n", "<leader>ir" },
				MkdnTableNewRowAbove = { "n", "<leader>iR" },
				MkdnTableNewColAfter = { "n", "<leader>ic" },
				MkdnTableNewColBefore = { "n", "<leader>iC" },
				MkdnFoldSection = { "n", "<leader>mf" },
				MkdnUnfoldSection = { "n", "<leader>mF" },
			},
		},
	},

	-- =========================================================================
	-- END MARKDOWN SUITE
	-- =========================================================================

	-- {
	-- 	"sudo-tee/opencode.nvim",
	-- 	config = function()
	-- 		require("opencode").setup({})
	-- 	end,
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"MeanderingProgrammer/render-markdown.nvim", -- now a top-level plugin
	-- 		-- Optional, for file mentions and commands completion, pick only one
	-- 		-- 'saghen/blink.cmp',
	-- 		"hrsh7th/nvim-cmp",
	--
	-- 		-- Optional, for file mentions picker, pick only one
	-- 		"folke/snacks.nvim",
	-- 		-- 'nvim-telescope/telescope.nvim',
	-- 		-- 'ibhagwan/fzf-lua',
	-- 		-- 'nvim_mini/mini.nvim',
	-- 	},
	-- },
	-- =========================================================================
	-- Minimap
	-- =========================================================================
	{
		"wfxr/minimap.vim",
	},

	{
		"NickvanDyke/opencode.nvim",
		dependencies = {
			-- Recommended for `ask()` and `select()`.
			-- Required for `snacks` provider.
			---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
			{ "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
		},
		config = function()
			---@type opencode.Opts
			vim.g.opencode_opts = {
				-- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
			}

			-- Required for `opts.events.reload`.
			vim.o.autoread = true

			-- Recommended/example keymaps.
			vim.keymap.set({ "n", "x" }, "<C-a>", function()
				require("opencode").ask("@this: ", { submit = true })
			end, { desc = "Ask opencode" })
			vim.keymap.set({ "n", "x" }, "<C-x>", function()
				require("opencode").select()
			end, { desc = "Execute opencode action…" })
			vim.keymap.set({ "n", "t" }, "<leader>oo", function()
				require("opencode").toggle()
			end, { desc = "Toggle opencode" })

			vim.keymap.set({ "n", "x" }, "go", function()
				return require("opencode").operator("@this ")
			end, { expr = true, desc = "Add range to opencode" })
			vim.keymap.set("n", "goo", function()
				return require("opencode").operator("@this ") .. "_"
			end, { expr = true, desc = "Add line to opencode" })

			vim.keymap.set("n", "<S-C-u>", function()
				require("opencode").command("session.half.page.up")
			end, { desc = "opencode half page up" })
			vim.keymap.set("n", "<S-C-d>", function()
				require("opencode").command("session.half.page.down")
			end, { desc = "opencode half page down" })

			-- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o".
			vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
			vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })
		end,
	},
})

-- Git blame helpers
vim.api.nvim_create_user_command("BlameOn", function()
	require("gitsigns").toggle_current_line_blame(true)
end, {})
vim.api.nvim_create_user_command("BlameOff", function()
	require("gitsigns").toggle_current_line_blame(false)
end, {})
vim.api.nvim_create_user_command("BlameToggle", function()
	require("gitsigns").toggle_current_line_blame()
end, {})

-- Fugitive-style blame split (left-side blame like old :Gblame)
vim.cmd("command! -nargs=* Gblame Git blame --date=short --abbrev=8 <args>")

-- Quit mapping
vim.keymap.set("n", "<leader>q", ":q<CR>", { silent = true })
-- Save mapping
vim.keymap.set("n", "<leader>w", ":w<CR>", { silent = true })
-- Split shortcuts
vim.keymap.set("n", "<leader>h", ":split<CR>", { silent = true })
vim.keymap.set("n", "<leader>v", ":vsplit<CR>", { silent = true })
-- Toggle inline Git blame
vim.keymap.set("n", "<leader>gb", function()
	require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle Git blame" })

-- Commenting!!!! <leader>cc
--
vim.keymap.set("n", "<leader>cc", "gcc", {
	remap = true,
	silent = true,
	desc = "Toggle comment line (gcc)",
})

-- Map <leader>cc to the built-in comment toggle in Visual mode (for block commenting)
vim.keymap.set("v", "<leader>cc", "gc", {
	remap = true,
	silent = true,
	desc = "Toggle comment block (gc)",
})
