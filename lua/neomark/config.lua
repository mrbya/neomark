--- @module "neomark.config"

--- @class neomark.config
---
--- Configuration table for Neomark API
---
--- @field disable table Table containing disabled elements
--- @field filetypes table Table setting file patterns for which to load Neomark
--- @field keymaps table Table containing interactive mode keymaps
---
local config = {
    --- @type table<neomark.api.rendering.supported>
    ---
    --- Array containing disabled supported elements
    ---
    disable = {},

    filetypes = { '*.md' },

    --- @enum neomark.config.keymap
    ---
    --- Command keymaps
    ---
    keymaps = {
        interactive_mode_enter = '<leader>i',
        interactive_mode_exit = '<Esc>',
        forward = '<Right>',
        backward = '<Left>',
        up = '<Up>',
        down = '<Down>',
        interact = '<CR>',
        format_bold = '<leader>b',
        format_italic = '<leader>i',
        format_strikethrough = '<leader>s',
    },

    snippets = false,
}

return config
