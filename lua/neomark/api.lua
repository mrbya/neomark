--- @module "neomark.api"
---
--- Base file for neomark api
--- Contains the top-level implementation of neomark api
---
local M = {
    rendering    = require('neomark.api.rendering'),
    interactive  = require('neomark.api.interactive'),
    autocomplete = require('neomark.api.autocomplete')
}

--- @class neomark.api.element
---
--- An interactive markdown element type
---
--- @field line integer Line index
--- @field start integer Element start column index
--- @field stop integer Element stop column index
--- @field istart integer Column index of the element interactable section
--- @field len integer Length of the element interactable section
--- @field type neomark.api.rendering.element.types Type of the interactive element
---

--- Api submodule loading function
---
--- @param config neomark.config Neomarks config table
---
function M.load_submodules(config)
    M.rendering.load(config)
    M.autocomplete.load(config)
end

--- Function to initialize buffer state
function M.buffer_init()
    M.interactive.init()
    M.autocomplete.init()
end


--- Clear elements rendering buffer-wide
function M.clear_rendering()
    M.rendering.clear()
    M.interactive.clear()
end

--- Clear elements rendering of a single line
function M.clear_line(line)
    M.rendering.clear_line(line)
end

--- Render supported elements in a single line
---
--- @param line_idx integer Index of the line to be rendered
---
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

--- Render supported elements buffer-wide
function M.render_buffer()
    for i = 1, vim.api.nvim_buf_line_count(0) do
        M.clear_line(i)
        M.render_line(i)
    end
end

--- Clear a single line @ cursor position and re-render the rest
function M.render_cursor()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    M.clear_rendering()
    M.render_buffer()
    M.clear_line(line)
end

--- Handle rendering in the current buffer.
function M.render()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    M.clear_rendering()
    M.render_buffer()
    vim.api.nvim_set_option_value('conceallevel', 2, { scope = 'local' })
end

--- Handle clearing of rendering
function M.clear()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    M.clear_rendering()
end

--- Update buffer length for autocomplete
function M.update_buffer_len()
    M.autocomplete.set_buffer_len(vim.api.nvim_buf_line_count(0))
end

--- Handle autocompletion
function M.process_autocomplete()
    local len = vim.api.nvim_buf_line_count(0)
    if len > M.autocomplete.get_buffer_len() then
        M.autocomplete.process_line()
    end
    M.autocomplete.set_buffer_len(len)
end

--- Load neomark api.
function M.load(config)
    vim.api.nvim_clear_autocmds({pattern = config.filetypes})
    M.load_submodules(config)
end

return M

