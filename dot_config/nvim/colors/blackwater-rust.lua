-- Blackwater Rust — blackened water with oxidized signal accents.

local M = {}

M.colors = {
    bg = "#071012",
    bg_dark = "#05090b",
    bg_light = "#111b1f",
    selection = "#1d3035",
    fg = "#c5d0cd",
    fg_bright = "#e6efeb",
    comment = "#60706e",
    dim = "#425250",

    black = "#081114",
    red = "#e45f57",
    green = "#7fae8b",
    yellow = "#d6a84f",
    blue = "#6f9fbd",
    magenta = "#9b8ac5",
    cyan = "#45d0bd",
    orange = "#c27a4a",
    brass = "#b99a5f",

    none = "NONE",
}

function M.setup()
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end

    vim.o.background = "dark"
    vim.o.termguicolors = true
    vim.g.colors_name = "blackwater-rust"

    local c = M.colors

    local groups = {
        -- Editor UI
        Normal = { fg = c.fg, bg = c.bg },
        NormalNC = { fg = c.fg, bg = c.bg },
        SignColumn = { fg = c.fg, bg = c.bg },
        MsgArea = { fg = c.fg, bg = c.bg },
        ModeMsg = { fg = c.yellow, style = "bold" },
        MoreMsg = { fg = c.cyan, style = "bold" },
        MsgSeparator = { fg = c.selection, bg = c.bg },
        SpellBad = { sp = c.red, style = "undercurl" },
        SpellCap = { sp = c.yellow, style = "undercurl" },
        SpellLocal = { sp = c.cyan, style = "undercurl" },
        Pmenu = { fg = c.fg, bg = c.bg_dark },
        PmenuSel = { fg = c.bg_dark, bg = c.cyan, style = "bold" },
        PmenuSbar = { bg = c.selection },
        PmenuThumb = { bg = c.comment },
        TabLine = { fg = c.comment, bg = c.bg_dark },
        TabLineSel = { fg = c.bg_dark, bg = c.fg, style = "bold" },
        TabLineFill = { bg = c.bg },
        CursorColumn = { bg = c.bg_light },
        CursorLine = { bg = c.bg_light },
        ColorColumn = { bg = c.bg_light },
        Cursor = { fg = c.bg, bg = c.cyan },
        lCursor = { fg = c.bg, bg = c.yellow },
        LineNr = { fg = c.dim },
        CursorLineNr = { fg = c.yellow, style = "bold" },
        VertSplit = { fg = c.selection, bg = c.bg },
        WinSeparator = { fg = c.selection, bg = c.bg },
        StatusLine = { fg = c.fg, bg = c.selection },
        StatusLineNC = { fg = c.comment, bg = c.bg_dark },
        Visual = { fg = c.fg, bg = c.selection },
        Search = { fg = c.bg_dark, bg = c.yellow },
        IncSearch = { fg = c.bg_dark, bg = c.orange },
        CurSearch = { fg = c.bg_dark, bg = c.orange, style = "bold" },
        MatchParen = { fg = c.yellow, style = "bold,underline" },
        Folded = { fg = c.comment, bg = c.bg_light },
        FoldColumn = { fg = c.dim, bg = c.bg },
        NonText = { fg = c.dim },
        SpecialKey = { fg = c.dim },
        Whitespace = { fg = c.dim },

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
        Label = { fg = c.brass },
        Operator = { fg = c.fg },
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
        Special = { fg = c.brass },
        SpecialChar = { fg = c.brass },
        Tag = { fg = c.brass },
        Delimiter = { fg = c.fg },
        SpecialComment = { fg = c.comment, style = "bold" },
        Debug = { fg = c.red },
        Underlined = { fg = c.blue, style = "underline" },
        Error = { fg = c.red, style = "bold" },
        Todo = { fg = c.bg_dark, bg = c.yellow, style = "bold" },

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
        ["@property"] = { fg = c.brass },
        ["@field"] = { fg = c.brass },
        ["@parameter"] = { fg = c.fg, style = "italic" },
        ["@attribute"] = { fg = c.magenta },
        ["@attribute.builtin"] = { fg = c.magenta },
        ["@operator"] = { fg = c.fg },
        ["@punctuation"] = { fg = c.fg },
        ["@punctuation.bracket"] = { fg = c.comment },
        ["@punctuation.delimiter"] = { fg = c.comment },
        ["@string"] = { fg = c.green },
        ["@string.escape"] = { fg = c.brass },
        ["@number"] = { fg = c.yellow },
        ["@boolean"] = { fg = c.cyan, style = "bold" },
        ["@module"] = { fg = c.fg },
        ["@namespace"] = { fg = c.fg },

        -- Diagnostics
        DiagnosticError = { fg = c.red },
        DiagnosticWarn = { fg = c.yellow },
        DiagnosticInfo = { fg = c.blue },
        DiagnosticHint = { fg = c.cyan },
        DiagnosticUnderlineError = { sp = c.red, style = "undercurl" },
        DiagnosticUnderlineWarn = { sp = c.yellow, style = "undercurl" },
        DiagnosticUnderlineInfo = { sp = c.blue, style = "undercurl" },
        DiagnosticUnderlineHint = { sp = c.cyan, style = "undercurl" },

        -- Gitsigns
        GitSignsAdd = { fg = c.green },
        GitSignsChange = { fg = c.yellow },
        GitSignsDelete = { fg = c.red },

        -- Telescope
        TelescopeBorder = { fg = c.dim, bg = c.bg },
        TelescopePromptBorder = { fg = c.dim, bg = c.bg_dark },
        TelescopeResultsBorder = { fg = c.dim, bg = c.bg },
        TelescopePreviewBorder = { fg = c.dim, bg = c.bg },
        TelescopePromptNormal = { fg = c.fg, bg = c.bg_dark },
        TelescopePromptPrefix = { fg = c.cyan, bg = c.bg_dark },
        TelescopeMatching = { fg = c.yellow, style = "bold" },
        TelescopeSelection = { fg = c.fg_bright, bg = c.selection },

        -- Floating windows
        NormalFloat = { fg = c.fg, bg = c.bg_light },
        FloatBorder = { fg = c.dim, bg = c.bg_light },

        -- Directory / file explorers
        Directory = { fg = c.blue },
        NeoTreeDirectoryIcon = { fg = c.blue },
        NeoTreeDirectoryName = { fg = c.blue },
        NeoTreeFileName = { fg = c.fg },
        NeoTreeIndentMarker = { fg = c.dim },
        NeoTreeRootName = { fg = c.cyan, style = "bold" },
        NeoTreeGitAdded = { fg = c.green },
        NeoTreeGitModified = { fg = c.yellow },
        NeoTreeGitDeleted = { fg = c.red },
        NeoTreeGitUntracked = { fg = c.comment },
    }

    for group, highlight in pairs(groups) do
        vim.api.nvim_set_hl(0, group, {
            fg = highlight.fg,
            bg = highlight.bg,
            sp = highlight.sp,
            bold = highlight.style and highlight.style:find("bold", 1, true) ~= nil or nil,
            italic = highlight.style and highlight.style:find("italic", 1, true) ~= nil or nil,
            underline = highlight.style and highlight.style:find("underline", 1, true) ~= nil or nil,
            undercurl = highlight.style and highlight.style:find("undercurl", 1, true) ~= nil or nil,
        })
    end
end

M.setup()

return M
