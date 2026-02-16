-- Twenty — soft aesthetic neovim theme

local M = {}

M.colors = {
    bg = "#1e1e22",
    fg = "#b8b8c8",
    selection = "#3e3e48",
    comment = "#68687a",
    cursor = "#dcccc6",

    black = "#111115",
    bg_dark = "#181820",
    bg_light = "#2e2e36",
    gray = "#555562",
    light_gray = "#9090a0",

    red = "#e08a9e",
    green = "#95d194",
    yellow = "#e4cfa0",
    yellow_dim = "#dbbfbf",
    blue = "#7da4e4",
    magenta = "#b89aad",
    cyan = "#86cfc3",
    orange = "#e2a17c",
    sand = "#d4b88c",

    none = "NONE"
}

function M.setup()
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end

    vim.o.background = "dark"
    vim.o.termguicolors = true
    vim.g.colors_name = "twenty"

    local c = M.colors

    local groups = {
        -- Editor UI
        Normal = { fg = c.fg, bg = c.bg },
        SignColumn = { fg = c.fg, bg = c.bg },
        MsgArea = { fg = c.fg, bg = c.bg },
        ModeMsg = { fg = c.yellow, style = "bold" },
        MsgSeparator = { fg = c.selection, bg = c.bg },
        SpellBad = { fg = c.red, style = "undercurl" },
        SpellCap = { fg = c.yellow, style = "undercurl" },
        SpellLocal = { fg = c.cyan, style = "undercurl" },
        Pmenu = { fg = c.fg, bg = c.bg_dark },
        PmenuSel = { fg = c.bg_dark, bg = c.yellow, style = "bold" },
        PmenuSbar = { bg = c.selection },
        PmenuThumb = { bg = c.comment },
        TabLine = { fg = c.comment, bg = c.bg_dark },
        TabLineSel = { fg = c.bg, bg = c.fg, style = "bold" },
        TabLineFill = { bg = c.bg },
        CursorColumn = { bg = c.bg_light },
        CursorLine = { bg = c.bg_light },
        ColorColumn = { bg = c.bg_light },
        Cursor = { fg = c.bg, bg = c.cursor },
        LineNr = { fg = c.gray },
        CursorLineNr = { fg = c.fg, style = "bold" },
        VertSplit = { fg = c.selection, bg = c.bg },
        WinSeparator = { fg = c.selection, bg = c.bg },
        StatusLine = { fg = c.fg, bg = c.selection },
        StatusLineNC = { fg = c.comment, bg = c.bg_dark },
        Visual = { fg = c.fg, bg = c.selection },
        Search = { fg = c.bg, bg = c.yellow },
        IncSearch = { fg = c.bg, bg = c.orange },
        MatchParen = { fg = c.yellow, style = "bold,underline" },

        -- Syntax
        Comment = { fg = c.comment, style = "italic" },
        Constant = { fg = c.yellow },
        String = { fg = c.green },
        Character = { fg = c.green },
        Number = { fg = c.yellow },
        Boolean = { fg = c.cyan, style = "bold" },
        Float = { fg = c.yellow },
        Identifier = { fg = c.fg },
        Function = { fg = c.cyan },
        Statement = { fg = c.orange },
        Conditional = { fg = c.orange },
        Repeat = { fg = c.orange },
        Label = { fg = c.cyan },
        Operator = { fg = c.gray },
        Keyword = { fg = c.orange },
        Exception = { fg = c.red, style = "bold" },
        PreProc = { fg = c.magenta },
        Include = { fg = c.magenta },
        Define = { fg = c.magenta },
        Macro = { fg = c.magenta },
        Type = { fg = c.blue },
        StorageClass = { fg = c.orange },
        Structure = { fg = c.blue },
        Typedef = { fg = c.blue },
        Special = { fg = c.yellow_dim },
        SpecialChar = { fg = c.yellow_dim },
        Tag = { fg = c.yellow_dim },
        Delimiter = { fg = c.gray },
        SpecialComment = { fg = c.comment, style = "bold" },
        Debug = { fg = c.red },
        Underlined = { style = "underline" },
        Error = { fg = c.red, style = "bold" },
        Todo = { fg = c.bg, bg = c.yellow, style = "bold" },

        -- Treesitter / LSP
        ["@variable"] = { fg = c.fg },
        ["@variable.builtin"] = { fg = c.cyan },
        ["@variable.parameter"] = { fg = c.fg, style = "italic" },
        ["@function"] = { fg = c.cyan },
        ["@function.builtin"] = { fg = c.cyan, style = "bold" },
        ["@function.call"] = { fg = c.cyan },
        ["@function.method"] = { fg = c.cyan },
        ["@function.method.call"] = { fg = c.cyan },
        ["@constant"] = { fg = c.yellow },
        ["@constant.builtin"] = { fg = c.yellow, style = "bold" },
        ["@keyword"] = { fg = c.orange },
        ["@keyword.function"] = { fg = c.orange },
        ["@keyword.operator"] = { fg = c.orange },
        ["@keyword.return"] = { fg = c.orange },
        ["@keyword.conditional"] = { fg = c.orange },
        ["@keyword.repeat"] = { fg = c.orange },
        ["@keyword.import"] = { fg = c.magenta },
        ["@type"] = { fg = c.blue },
        ["@type.builtin"] = { fg = c.blue, style = "bold" },
        ["@type.qualifier"] = { fg = c.orange },
        ["@constructor"] = { fg = c.blue },
        ["@property"] = { fg = c.yellow_dim },
        ["@field"] = { fg = c.yellow_dim },
        ["@parameter"] = { fg = c.fg, style = "italic" },
        ["@attribute"] = { fg = c.magenta },
        ["@attribute.builtin"] = { fg = c.magenta },
        ["@operator"] = { fg = c.gray },
        ["@punctuation"] = { fg = c.gray },
        ["@punctuation.bracket"] = { fg = c.gray },
        ["@punctuation.delimiter"] = { fg = c.gray },
        ["@string"] = { fg = c.green },
        ["@string.escape"] = { fg = c.yellow_dim },
        ["@number"] = { fg = c.yellow },
        ["@boolean"] = { fg = c.cyan, style = "bold" },
        ["@module"] = { fg = c.fg },
        ["@namespace"] = { fg = c.fg },

        -- Gitsigns
        GitSignsAdd = { fg = c.green },
        GitSignsChange = { fg = c.blue },
        GitSignsDelete = { fg = c.red },

        -- Telescope
        TelescopeBorder = { fg = c.gray },
        TelescopePromptBorder = { fg = c.gray },
        TelescopeResultsBorder = { fg = c.gray },
        TelescopePreviewBorder = { fg = c.gray },
        TelescopeMatching = { fg = c.yellow, style = "bold" },
        TelescopeSelection = { fg = c.fg, bg = c.selection },

        -- Floating windows
        NormalFloat = { fg = c.fg, bg = c.bg_light },
        FloatBorder = { fg = c.gray, bg = c.bg_light },

        -- Directory
        Directory = { fg = c.sand },

        -- Neo-tree
        NeoTreeDirectoryIcon = { fg = c.sand },
        NeoTreeDirectoryName = { fg = c.sand },
        NeoTreeFileName = { fg = c.fg },
        NeoTreeIndentMarker = { fg = c.gray },
        NeoTreeRootName = { fg = c.sand, style = "bold" },
        NeoTreeGitAdded = { fg = c.green },
        NeoTreeGitModified = { fg = c.yellow },
        NeoTreeGitDeleted = { fg = c.red },
        NeoTreeGitUntracked = { fg = c.comment },
    }

    for group, highlight in pairs(groups) do
        local style = highlight.style and "gui=" .. highlight.style or "gui=NONE"
        local fg = highlight.fg and "guifg=" .. highlight.fg or "guifg=NONE"
        local bg = highlight.bg and "guibg=" .. highlight.bg or "guibg=NONE"
        local sp = highlight.sp and "guisp=" .. highlight.sp or ""
        vim.cmd(string.format("highlight %s %s %s %s %s", group, style, fg, bg, sp))
    end
end

-- Allow :colorscheme twenty to work
M.setup()

return M
