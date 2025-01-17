--- @module "neomark.keymaps"
---
--- Neomark keymaps module
---
local Keymaps = {}

local commands = require('neomark.commands').commands

--- Create a keymap
---
--- @param cmd neomark.commands.command Neomark command
--- @param keymap neomark.config.keymap Neomark keymap
---
function Keymaps.create_keymap(cmd, keymap)
    if keymap and cmd then
        vim.keymap.set(
            cmd.mode,
            keymap,
            function()
                cmd.callback(keymap)
            end,
            {
                noremap = true,
                silent = true,
                desc = cmd.desc,
            }
        )
    end
end

--- Load Neomark keymaps
---
--- @param config neomark.config
---
function Keymaps.load(config)
    local keymaps = config.keymaps

    for command, keymap in pairs(keymaps) do
        Keymaps.create_keymap(commands[command], keymap)
    end
end

return Keymaps
