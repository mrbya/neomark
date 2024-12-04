--- @module "neomark.api.keymaps"
---
--- Neomark API keymaps module
---
local K = {}

local api = require('neomark.api.api')

--- Load Neomark keymaps
---
--- @param config neomark.api.config
function K.load(config)
    local keymaps = config.keymaps

    vim.keymap.set('n', keymaps.interactive_mode, function()
        api.interactive.enter()
    end)

    vim.keymap.set('', '<Esc>', function()
        api.interactive.exit()
    end, { noremap = true, silent = true })

    vim.keymap.set('n', keymaps.forward, function()
        api.interactive.move('forward', keymaps.forward)
    end, { noremap = true, silent = true })

    vim.keymap.set('n', keymaps.backward, function()
        api.interactive.move('backward', keymaps.backward)
    end, { noremap = true, silent = true })

    vim.keymap.set('n', keymaps.interact, function()
        api.interactive.interact(keymaps.interact)
    end, {noremap = true, silent = true})
end

return K
