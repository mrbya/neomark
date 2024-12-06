--- @module "neomark.config"

--- @class neomark.config
---
--- Configuration table for Naomark API.
---
--- @field disable table Table containing disabled elements
--- @field filetypes table Table setting file patterns to use Neomark with
--- @field keymaps table Table containing interactive mode keymaps
---
local config = {
    --- @table neomark.api.rendering.supported
    ---
    --- Table containing settings to disable specific element rendering
    disable = {},

    filetypes = { '*.md' },

    --- @enum neomark.api.config.keymaps
    ---
    --- Command keymaps
    keymaps = {
        interactive_mode = '<leader>i',
        forward = '<Right>',
        backward = '<Left>',
        up = '<Up>',
        down = '<Down>',
        interact = '<CR>'
    },
}

return config
