-- For JS/TS-ish buffers, add the nearest node_modules/.bin to PATH so formatters
-- like `prettier` resolve to the project's local install.
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

vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"markdown",
		"css",
		"scss",
		"yaml",
	},
	callback = add_node_bin_to_path,
})
