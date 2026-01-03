-- Twenty Neovim Theme
-- A minimal, industrial theme based on the Twenty Brand Guide.
-- With a hint of hacker aesthetic.

local M = {}

M.colors = {
    bg = "#151718",
    fg = "#D4D4D0",
    selection = "#252829",
    comment = "#626e6e",
    cursor = "#00FF9F",

    -- Derived Palette
    black = "#000000",
    bg_dark = "#0e1010",
    bg_light = "#1e2021",
    gray = "#525e5e",
    light_gray = "#9ca8a8",

    red = "#E05A55", -- Errors, exceptions
    green = "#7DD88A", -- Strings - brighter for clarity
    yellow = "#F0E6A0", -- Constants, numbers
    yellow_dim = "#C9BC7A", -- Properties, special chars
    blue = "#6BB8C4", -- Types - brighter, more distinct
    magenta = "#C49AC0", -- Less saturated
    cyan = "#5AD4CB", -- Builtins, labels
    orange = "#D9A76A", -- Keywords - warm, distinct from text

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
        Visual = { bg = c.selection },
        Search = { fg = c.bg, bg = c.yellow },
        IncSearch = { fg = c.bg, bg = c.green },
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
        TelescopeBorder = { fg = c.selection },
        TelescopePromptBorder = { fg = c.selection },
        TelescopeResultsBorder = { fg = c.selection },
        TelescopePreviewBorder = { fg = c.selection },
        TelescopeMatching = { fg = c.yellow, style = "bold" },
        TelescopeSelection = { bg = c.selection },
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
