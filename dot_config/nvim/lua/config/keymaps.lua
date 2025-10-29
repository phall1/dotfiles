local map = vim.keymap.set

map("n", "<leader>q", ":q<CR>", { silent = true, desc = "Quit" })
map("n", "<leader>w", ":w<CR>", { silent = true, desc = "Save" })
map("n", "<leader>h", ":split<CR>", { silent = true, desc = "Split horizontal" })
map("n", "<leader>v", ":vsplit<CR>", { silent = true, desc = "Split vertical" })

-- Comment toggle uses the built-in `gc` operator.
map("n", "<leader>cc", "gcc", { remap = true, silent = true, desc = "Toggle comment line" })
map("v", "<leader>cc", "gc", { remap = true, silent = true, desc = "Toggle comment block" })
