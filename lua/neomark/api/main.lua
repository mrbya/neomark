local M = {}

M.rendering   = require('neomark.api.lib.rendering')
M.interactive = require('neomark.api.lib.interactive')

function M.init(config)
    M.rendering.init(config)
end

function M.buffer_init()
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
    M.rendering.clear()
    M.interactive.clear()
end

-- Clear rendering elements of a single line
function M.clear_line(line)
    M.rendering.clear_line(line)
end

-- Render supported elements in a single line
function M.render_line(line_idx)
    local line = vim.api.nvim_buf_get_lines(0, line_idx - 1, line_idx, false)[1]
    if line then
        local interactive_elements = M.rendering.render_line(line_idx, line)
        if interactive_elements ~= {} then
            for _, element in ipairs(interactive_elements) do
                M.interactive.add_element(element)
            end
        end
    end
end

-- Buffer-wide rendering of supported elements
function M.render_buffer()
    for i = 1, vim.api.nvim_buf_line_count(0) do
        M.clear_line(i)
        M.render_line(i)
    end
end

function M.render_cursor()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    M.clear_rendering()
    M.render_buffer()
    M.clear_line(line)
end

function M.render()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    M.clear_rendering()
    M.render_buffer()
    vim.api.nvim_set_option_value('conceallevel', 2, { scope = 'local' })
end

function M.clear()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    M.clear_rendering()
end

-- Load neomark plugin
function M.load(config)
    vim.api.nvim_clear_autocmds({pattern = '*.md'})
    M.init(config)
end

return M

