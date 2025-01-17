--- @module "neomark.autocommands"
---
--- Neomark module holding its autocommands
---
local Autocommands = {}

local api = require('neomark.api')

--- Function to load autocommands
---
--- @param config neomark.config
---
function Autocommands.load(config)
    -- Initialize/re-initialize buffer state on buffer entry 
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = config.filetypes,
        callback = function()
            api.buffer_init()
            if vim.fn.mode() == 'n' or vim.fn.mode() == 'v' then
                api.render()
            end
        end
    })

    -- Clear Handle cursor movement events
    vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
        pattern = config.filetypes,
        callback = function()
            api.render_cursor()
            api.update_buffer_len()
        end
    })

    -- Run markdown element rendering on text change
    vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
        pattern = config.filetypes,
        callback = function()
            if vim.fn.mode() == 'n' or vim.fn.mode() == 'v' then
                api.render()
            end
        end,
    })

    -- Process autocomplete on text change in insert mode
    vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
        pattern = config.filetypes,
        callback = function()
            api.process_autocomplete()
        end,
    })

    -- Disable link rendering on entering insert mode
    vim.api.nvim_create_autocmd({ 'InsertEnter' }, {
        pattern = config.filetypes,
        callback = function()
            api.clear()
        end,
    })
end

return Autocommands
