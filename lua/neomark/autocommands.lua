--- @module "neomark.autocommands"
---
--- Neomark module holding its autocommands
---
local A = {}

local api = require('neomark.api')

--- Function to load autocommands
---
--- @param config neomark.config
---
function A.load(config)
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = config.filetypes,
        callback = function()
            api.buffer_init()
            if vim.fn.mode() == 'n' or vim.fn.mode() == 'v' then
                api.render()
            end
        end
    })

    -- Clear cursor line and re-render
    vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
        pattern = config.filetypes,
        callback = function()
            api.render_cursor()
        end
    })

    -- Run markdown element rendering
    vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
        pattern = config.filetypes,
        callback = function()
            if vim.fn.mode() == 'n' or vim.fn.mode() == 'v' then
                api.render()
            end
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

return A
