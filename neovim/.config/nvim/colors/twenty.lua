-- Twenty Neovim Theme
-- A minimal, industrial theme based on the Twenty Brand Guide.
-- With a hint of hacker aesthetic.

local M = {}

M.colors = {
    bg = "#252a2b", -- Slightly darker, more terminal-like
    fg = "#EEEEE5", -- Brand White
    selection = "#3F3F34", -- Brand Dark Neutral (for selections)
    comment = "#6A7A7A", -- Slightly cooler, more terminal-like
    cursor = "#00FF9F", -- Hacker green cursor

    -- Derived Palette
    black = "#000000", -- True black for contrast elements
    bg_dark = "#1E2223", -- Slightly darker for UI contrast
    bg_light = "#353a3b", -- Lighter bg for highlights
    gray = "#5A6A6D", -- Cooler gray
    light_gray = "#9A9990", -- Brighter neutral for keywords

    red = "#E05A55", -- Slightly more vivid
    green = "#5FD068", -- Terminal green with olive undertone
    yellow = "#F7F5DA", -- Brand Gold
    yellow_dim = "#D4D090", -- Softer gold with phosphor hint
    blue = "#5A9EA8", -- Cooler, more electric
    magenta = "#D9A8D0", -- Cyberpunk magenta hint
    cyan = "#4ECDC4", -- Terminal cyan - hacker classic

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
        Boolean = { fg = c.yellow, style = "bold" },
        Float = { fg = c.yellow },
        Identifier = { fg = c.fg },
        Function = { fg = c.fg, style = "bold" },
        Statement = { fg = c.light_gray, style = "bold" }, -- Keywords are subtle/industrial
        Conditional = { fg = c.light_gray, style = "bold" },
        Repeat = { fg = c.light_gray, style = "bold" },
        Label = { fg = c.cyan },
        Operator = { fg = c.comment },
        Keyword = { fg = c.light_gray, style = "bold" },
        Exception = { fg = c.red },
        PreProc = { fg = c.blue },
        Include = { fg = c.blue },
        Define = { fg = c.blue },
        Macro = { fg = c.blue },
        Type = { fg = c.blue },
        StorageClass = { fg = c.blue },
        Structure = { fg = c.blue },
        Typedef = { fg = c.blue },
        Special = { fg = c.yellow_dim },
        SpecialChar = { fg = c.yellow_dim },
        Tag = { fg = c.yellow_dim },
        Delimiter = { fg = c.comment },
        SpecialComment = { fg = c.comment },
        Debug = { fg = c.red },
        Underlined = { style = "underline" },
        Error = { fg = c.red, style = "bold" },
        Todo = { fg = c.bg, bg = c.yellow, style = "bold" },

        -- Treesitter / LSP
        ["@variable"] = { fg = c.fg },
        ["@variable.builtin"] = { fg = c.yellow_dim },
        ["@function.builtin"] = { fg = c.cyan },
        ["@constant.builtin"] = { fg = c.yellow },
        ["@keyword.function"] = { fg = c.light_gray, style = "bold" },
        ["@type.builtin"] = { fg = c.blue },
        ["@constructor"] = { fg = c.fg, style = "bold" },
        ["@property"] = { fg = c.yellow_dim },
        ["@method"] = { fg = c.fg, style = "bold" },
        ["@parameter"] = { fg = c.fg, style = "italic" },

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
