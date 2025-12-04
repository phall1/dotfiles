-- Yank to clipboard
vim.opt.clipboard = "unnamedplus"

-- Mapleader key
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Editor settings
vim.opt.number = true            -- show absolute line numbers
vim.opt.relativenumber = true    -- show relative line numbers
vim.opt.tabstop = 4              -- number of spaces tabs count for
vim.opt.shiftwidth = 4           -- size of an indent
vim.opt.expandtab = true         -- convert tabs to spaces
vim.opt.smartindent = true       -- smart autoindenting on new lines
vim.opt.wrap = false             -- disable line wrapping
vim.opt.cursorline = true        -- highlight current line
vim.opt.termguicolors = true     -- enable full RGB colors
vim.opt.signcolumn = "yes"       -- always show sign column (for git/lsp indicators)
vim.opt.scrolloff = 5            -- keep 5 lines visible above/below cursor
vim.opt.sidescrolloff = 8        -- same horizontally
vim.opt.ignorecase = true        -- case-insensitive search by default
vim.opt.smartcase = true         -- but case-sensitive if search includes uppercase
vim.opt.splitbelow = true        -- horizontal splits open below
vim.opt.splitright = true        -- vertical splits open to the right
vim.opt.updatetime = 300         -- faster updates
vim.opt.timeoutlen = 400         -- shorter key sequence timeout
vim.opt.mouse = "a"              -- enable mouse support

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
            require("neo-tree").setup({
                -- Turn off expensive git/diagnostic scans to keep folder toggles snappy
                enable_git_status = false,
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
                    side = "left",
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
            vim.keymap.set("n", "<leader>n", ":Neotree toggle<CR>", { silent = true })
        end,
    },

    -- Telescope (Command-P style fuzzy finder)
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            telescope.setup({})

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
        end,
    },

    -- Tree sitter ( syntax highligting and that)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "python", "go", "rust", "typescript", "lua", "bash", "json", "yaml", "toml", "terraform"
                },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },

    -- gitsigns!!
    {
        "lewis6991/gitsigns.nvim"
    },

    -- LSP + Autocomplete
    {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        config = function()
            -- Mason: automatic LSP installer
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "pyright",
                    "gopls",
                    "rust_analyzer",
                    "tsserver",
                    "terraformls",
                    "dockerls",
                    "lua_ls",
                },
            })

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
            local lspconfig = require("lspconfig")

            for _, server in ipairs({
                "pyright",
                "gopls",
                "rust_analyzer",
                "tsserver",
                "terraformls",
                "dockerls",
                "lua_ls",
            }) do
                lspconfig[server].setup({
                    capabilities = capabilities,
                })
            end

            -- Diagnostics style
            vim.diagnostic.config({
                virtual_text = false,
                float = { border = "rounded" },
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

            -- Keymaps for LSP actions
            local map = vim.keymap.set
            map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
            map("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
            map("n", "K", vim.lsp.buf.hover, { desc = "Hover info" })
            map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
            map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
            map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
        end,
    },

    -- Formatter (Conform)
    {
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    python = { "ruff_format" },
                    go = { "gofmt" },
                    rust = { "rustfmt" },
                    javascript = { "prettier" },
                    typescript = { "prettier" },
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
    {
        "sudo-tee/opencode.nvim",
        config = function()
            require("opencode").setup({})
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "MeanderingProgrammer/render-markdown.nvim",
                opts = {
                    anti_conceal = { enabled = false },
                    file_types = { 'markdown', 'opencode_output' },
                },
                ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
            },
            -- Optional, for file mentions and commands completion, pick only one
            'saghen/blink.cmp',
            -- 'hrsh7th/nvim-cmp',

            -- Optional, for file mentions picker, pick only one
            'folke/snacks.nvim',
            -- 'nvim-telescope/telescope.nvim',
            -- 'ibhagwan/fzf-lua',
            -- 'nvim_mini/mini.nvim',
        },
    }

})

-- Quit mapping
vim.keymap.set("n", "<leader>q", ":q<CR>", { silent = true })
-- Toggle inline Git blame
vim.keymap.set("n", "<leader>gb", function()
    require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle Git blame" })


-- Commenting!!!! <leacder>cc
-- 
vim.keymap.set('n', '<leader>cc', 'gcc', {
    remap = true,
    silent = true,
    desc = 'Toggle comment line (gcc)'
})

-- Map <leader>cc to the built-in comment toggle in Visual mode (for block commenting)
vim.keymap.set('v', '<leader>cc', 'gc', {
    remap = true,
    silent = true,
    desc = 'Toggle comment block (gc)'
})
