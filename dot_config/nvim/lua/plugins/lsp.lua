return {
	{
		"mrcjkb/rustaceanvim",
		version = "^5",
		lazy = false,
		config = function()
			vim.g.rustaceanvim = {
				tools = {},
				server = {
					-- rustup picks the workspace toolchain from rust-toolchain.toml
					cmd = function()
						local cargo_toml = vim.fs.find("Cargo.toml", {
							upward = true,
							type = "file",
							path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
						})[1]
						if cargo_toml then
							return { "rustup", "run", "--install", "rust-analyzer" }
						end
						return { "rust-analyzer" }
					end,
					default_settings = {
						["rust-analyzer"] = {
							checkOnSave = true,
							check = { command = "clippy" },
						},
					},
				},
			}
		end,
	},

	{
		"williamboman/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
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
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"gopls",
					"ts_ls",
					"terraformls",
					"dockerls",
					"lua_ls",
				},
			})

			local cmp = require("cmp")
			local luasnip = require("luasnip")
			cmp.setup({
				snippet = {
					expand = function(args) luasnip.lsp_expand(args.body) end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local uv = vim.uv or vim.loop

			-- lua_ls: special-cased so the nvim config dir picks up `vim` globals
			-- and the runtime library, but project luarc.json wins if present.
			local lua_settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
						path = { "lua/?.lua", "lua/?/init.lua" },
					},
					diagnostics = { globals = { "vim" } },
					workspace = {
						checkThirdParty = false,
						library = { vim.env.VIMRUNTIME },
					},
					telemetry = { enable = false },
				},
			}
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if
							path ~= vim.fn.stdpath("config")
							and (uv.fs_stat(path .. "/.luarc.json") or uv.fs_stat(path .. "/.luarc.jsonc"))
						then
							return
						end
					end
					client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, lua_settings.Lua)
				end,
				settings = lua_settings,
			})
			vim.lsp.enable("lua_ls")

			for _, server in ipairs({ "gopls", "ts_ls", "terraformls", "dockerls" }) do
				vim.lsp.config(server, { capabilities = capabilities })
				vim.lsp.enable(server)
			end

			-- ty: Astral's Python LSP (replaces pyright)
			vim.lsp.config("ty", {
				capabilities = capabilities,
				cmd = { "ty", "server" },
				filetypes = { "python" },
				root_markers = { ".venv", "pyproject.toml", "uv.lock", "setup.py", "setup.cfg", "requirements.txt" },
				settings = { ty = {} },
			})
			vim.lsp.enable("ty")

			vim.diagnostic.config({
				signs = {
					text = {
						[1] = "✘",
						[2] = "▲",
						[3] = "»",
						[4] = "⚑",
					},
				},
				virtual_text = { prefix = "●" },
				float = { border = "rounded" },
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			vim.lsp.inlay_hint.enable(true)

			local map = vim.keymap.set
			map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			map("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
			map("n", "K", vim.lsp.buf.hover, { desc = "Hover info" })
			map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
			map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
			map("n", "<leader>ne", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
			map("n", "<leader>pe", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
			map("n", "<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, { desc = "Toggle inlay hints" })
		end,
	},
}
