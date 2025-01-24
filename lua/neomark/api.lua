--- @module "neomark.api"
---
--- Base file for neomark api
--- Contains the top-level implementation of neomark api
---
local Api = {
    rendering    = require('neomark.api.rendering'),
    interactive  = require('neomark.api.interactive'),
    autocomplete = require('neomark.api.autocomplete'),
    formatting   = require('neomark.api.formatting'),
    -- tables       = require('neomark.api.tables'),
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
function Api.load_submodules(config)
    Api.rendering.load(config)
    Api.autocomplete.load(config)
    -- Api.tables.load()
end

--- Function to initialize buffer state
function Api.buffer_init()
    Api.interactive.init()
    Api.autocomplete.init()
    Api.rendering.init()
end


--- Clear elements rendering buffer-wide
function Api.clear_rendering()
    Api.rendering.clear()
    Api.interactive.clear()
end

--- Clear elements rendering of a single line
function Api.clear_line(line)
    Api.rendering.clear_line(line)
end

--- Render supported elements in a single line
---
--- @param line_idx integer Index of the line to be rendered
---
function Api.render_line(line_idx)
    local line = vim.api.nvim_buf_get_lines(0, line_idx - 1, line_idx, false)[1]
    if line then
        local interactive_elements = Api.rendering.render_line(line_idx, line)
        if interactive_elements ~= {} then
            for _, element in ipairs(interactive_elements) do
                Api.interactive.add_element(element)
            end
        end
    end
end

--- Render supported elements buffer-wide
function Api.render_buffer()
    for i = 1, vim.api.nvim_buf_line_count(0) do
        Api.clear_line(i)
        Api.render_line(i)
    end
end

--- Clear a single line @ cursor position and re-render the rest
function Api.render_cursor()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    Api.clear_rendering()
    Api.render_buffer()
    Api.clear_line(line)
end

--- Handle rendering in the current buffer.
function Api.render()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    Api.clear_rendering()
    Api.render_buffer()
    vim.api.nvim_set_option_value('conceallevel', 2, { scope = 'local' })
end

--- Handle clearing of rendering
function Api.clear()
    vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
    Api.clear_rendering()
end

--- Update buffer length for autocomplete
function Api.update_buffer_len()
    Api.autocomplete.set_buffer_len(vim.api.nvim_buf_line_count(0))
end

--- Handle autocompletion
function Api.process_autocomplete()
    local len = vim.api.nvim_buf_line_count(0)
    if len > Api.autocomplete.get_buffer_len() then
        Api.autocomplete.process_line()
    end
    Api.autocomplete.set_buffer_len(len)
end

--- Load neomark api.
function Api.load(config)
    vim.api.nvim_clear_autocmds({pattern = config.filetypes})
    Api.load_submodules(config)
end

return Api

