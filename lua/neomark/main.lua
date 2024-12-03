local M = {}

M.rendering = require('neomark.rendering')
M.interactive = require('neomark.interactive')

function M.init()
    M.rendering.init()
    M.interactive.init()
end

-- Create elements for all supported elements
function M.create_namespaces()
    for _, namespace in ipairs(M.rendering.elements) do
        M.rendering.element.namespaces[namespace] = vim.api.nvim_create_namespace(namespace)
    end
end

-- Clear rendering of all namespaces
function M.clear_rendering()
    for _, namespace in ipairs(M.rendering.elements) do
        vim.api.nvim_buf_clear_namespace(0, M.rendering.element.namespaces[namespace], 0, -1)
    end

    M.interactive.clear_elements()
end

-- Clear rendering elements of a single line
function M.clear_line(line)
    for _, namespace in ipairs(M.rendering.elements) do
        local marks = vim.api.nvim_buf_get_extmarks(0, M.rendering.element.namespaces[namespace], { line, 0 }, { line, -1 }, {})
        if #marks > 0 then
            for _, mark in ipairs(marks) do
                vim.api.nvim_buf_del_extmark(0, M.rendering.element.namespaces[namespace], mark[1])
            end
        end
    end
end

-- Render supported elements in a single line
function M.render_line(i)
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    if line then
        for _, renderer in ipairs(M.rendering.elements) do
            local ie = M.rendering.renderers[renderer](i, line)
            if ie then
                M.interactive.add_element(ie)
            end
        end
    end
end

-- Buffer-wide rendering of supported elements
function M.render_buf()
    for i = 1, vim.api.nvim_buf_line_count(0) do
        M.clear_line(i)
        M.render_line(i)
    end
end

function M.re_render()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    M.clear_rendering()
    M.render_buf()
    M.clear_line(line)
end

function M.render()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    M.clear_rendering()
    M.render_buf()
    vim.api.nvim_set_option_value('conceallevel', 2, { scope = 'local' })
end

function M.clear()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    M.clear_rendering()
end

-- Load neomark plugin
function M.load()
    vim.api.nvim_clear_autocmds({pattern = "*.md"})
    M.create_namespaces()

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = "*.md",
        callback = function()
            M.interactive.init()
            if vim.fn.mode() == "n" or vim.fn.mode() == "v" then
                M.render()
            end
        end
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        pattern = "*.md",
        callback = function()
            M.re_render()
        end
    })

    -- Run markdown element rendering
    vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
        pattern = "*.md",
        callback = function()
            if vim.fn.mode() == "n" or vim.fn.mode() == "v" then
                M.render()
            end
        end,
    })

    -- Disable link rendering on entering insert mode
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        pattern = "*.md",
        callback = function()
            M.clear()
        end,
    })

    vim.keymap.set('n', 'l', function()
        M.interactive.enter()
    end)

    vim.keymap.set('', '<Esc>', function()
        M.interactive.exit()
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<Right>', function()
        M.interactive.move('forward', '<Right>')
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<Left>', function()
        M.interactive.move('backward', '<Left>')
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<CR>', function()
        M.interactive.interact('<CR>')
    end, {noremap = true, silent = true})
end

return M

