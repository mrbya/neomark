local A = {}

local api = require('neomark.api.main')

function A.load(config)
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = config.filerypes,
        callback = function()
            api.buffer_init()
            if vim.fn.mode() == 'n' or vim.fn.mode() == 'v' then
                api.render()
            end
        end
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
        pattern = config.filerypes,
        callback = function()
            api.render_cursor()
        end
    })

    -- Run markdown element rendering
    vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
        pattern = config.filerypes,
        callback = function()
            if vim.fn.mode() == 'n' or vim.fn.mode() == 'v' then
                api.render()
            end
        end,
    })

    -- Disable link rendering on entering insert mode
    vim.api.nvim_create_autocmd({ 'InsertEnter' }, {
        pattern = config.filerypes,
        callback = function()
            api.clear()
        end,
    })
end

return A
