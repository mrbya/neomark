--- @module "neomark.commands"
---
--- Neomark commands module
---
local Commands = {}

local api = require("neomark.api")

--- @class neomark.commands.command
---
--- Neomark command
---
--- @field name string Command name
--- @field desc string Command description
--- @field mode string Neovim mode
--- @field callback function Command callback

--- @type table<neomark.commands.command>
---
--- Neomark commands
---
Commands.commands = {
    interactive_mode_enter = {
        name = 'Nmie',
        desc = 'Enter interactive mode',
        mode = 'n',
        callback = function(_)
            api.interactive.enter()
        end,
    },

    interactive_mode_exit = {
        name = 'Nmix',
        desc = 'Exit interactive mode',
        mode = 'n',
        callback = function(_)
            api.interactive.exit()
        end,
    },

    forward = {
        name = 'Nmif',
        desc = 'Next interactive element',
        mode = 'n',
        callback = function(keymap)
            api.interactive.move('forward', keymap)
        end,
    },

    backward = {
        name = 'Nmib',
        desc = 'Previous interactive element',
        mode = 'n',
        callback = function(keymap)
            api.interactive.move('backward', keymap)
        end,
    },

    up = {
        name = 'Nmiu',
        desc = 'Next interactive element up a line/lines',
        mode = 'n',
        callback = function(keymap)
            api.interactive.move('up', keymap)
        end,
    },

    down = {
        name = 'Nmid',
        desc = 'Next interactive element down a line/lines',
        mode = 'n',
        callback = function(keymap)
            api.interactive.move('down', keymap)
        end,
    },

    interact = {
        name = 'Nmii',
        desc = 'Interact with the selected interactive element',
        mode = 'n',
        callback = function(keymap)
            api.interactive.interact(keymap)
        end,
    },

    format_bold = {
        name = 'Nmfb',
        desc = 'Format selection to bold',
        mode = 'v',
        callback = function(_)
            api.formatting.format(api.formatting.formats.bold)
        end,
    },

    format_italic = {
        name = 'Nmfi',
        desc = 'Format selection to italic',
        mode = 'v',
        callback = function(_)
            api.formatting.format(api.formatting.formats.italic)
        end,
    },

    format_strikethrough = {
        name = 'Nmfb',
        desc = 'Format selection to bold',
        mode = 'v',
        callback = function(_)
            api.formatting.format(api.formatting.formats.strikethrough)
        end,
    },
}

--- Create a user command
---
--- @param cmd neomark.commands.command Neomark command
--- @param args any Optional command callback arguments
---
function Commands.create_command(cmd, args)
    if cmd then
        vim.api.nvim_create_user_command(
            cmd.name,
            function ()
                cmd.callback(args)
            end,
            {
                desc = cmd.desc,
                force = true
            }
        )
    end
end

--- Loads Neomark commands
---
--- @param config neomark.config Neomark config
---
function Commands.load(config)
    local keymaps = config.keymaps

    for command, keymap in pairs(keymaps) do
        Commands.create_command(Commands.commands[command], keymap)
    end
end

return Commands
