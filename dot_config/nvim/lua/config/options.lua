-- Leader keys must be set before lazy.nvim loads.
vim.g.mapleader = ","
vim.g.maplocalleader = ","

local opt = vim.opt

opt.clipboard = "unnamedplus"
opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 5
opt.sidescrolloff = 8
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.updatetime = 300
opt.timeoutlen = 400
opt.mouse = "a"

-- rustup picks toolchain from rust-toolchain.toml per project
vim.env.RUSTUP_TOOLCHAIN = nil

-- ~/.local/bin on PATH (GUI launches may miss shell PATH)
do
	local local_bin = vim.fn.expand("~/.local/bin")
	if not vim.env.PATH:find(local_bin, 1, true) then
		vim.env.PATH = local_bin .. ":" .. vim.env.PATH
	end
end

vim.cmd("colorscheme blackwater-rust")
