local M = {}

M.rendering = require('neomark.rendering')
M.interaction = require('neomark.interaction')

-- Tables to store buffer states
M.buffers = {}
M.current_buffer = 0
M.current_element = {}

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

    M.interaction.clear_elements()
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
                M.interaction.add_element(ie)
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

function M.interactables()
    local elements = M.get_elements_table()
    for i, element in ipairs(elements) do
        print(i .. ": " .. element.line .. ', ' .. element.start .. ', ' .. element.stop .. ', ' .. element.istart .. ', ' .. element.len .. ', ' .. element.type)
    end
end

function M.buffer_init()
    M.current_buffer = vim.api.nvim_get_current_buf()
    M.buffers[M.current_buffer] = M.buffers[M.current_buffer] or {}
    vim.b.interactive_mode = vim.b.interactive_mode or false
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

function M.interactive_mode_enter()
    local e = M.get_closest_interactable()

    if e and e ~= {} then
        vim.notify('Interactive mode', vim.log.levels.INFO)
        vim.b.interactive_mode = true
        vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })
    else
        vim.notify('No interactive elements!', vim.log.levels.ERROR)
    end
end

function M.interactive_mode_exit()
    if vim.b.interactive_mode then
        print(" ")
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, true, true), 'n', true)
    end
    vim.b.interactive_mode = false
end

M.interactive_mode = {
    callbacks = {
        next = M.get_next_interactable,
        previous = M.get_prev_interactable
    }
}

function M.interactive_mode_move(direction, accelerator)
    if vim.b.interactive_mode then
        local e = M.interaction.callbacks[direction]()
        if e then
            vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })
        end
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

function M.interactive_mode_interact(accelerator)
    if vim.b.interactive_mode then
        M.interact(M.current_element)
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

-- Load neomark plugin
function M.load()
    vim.api.nvim_clear_autocmds({pattern = "*.md"})
    M.create_namespaces()

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = "*.md",
        callback = function()
            M.interaction.init()
        end
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        pattern = "*.md",
        callback = function()
            M.re_render()
        end
    })

    -- Run markdown element rendering
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
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

    vim.api.nvim_create_user_command("Interactables", M.interactables, {})

    vim.keymap.set('n', 'l', function()
        M.interactive_mode_enter()
    end)

    vim.keymap.set('', '<Esc>', function()
        M.interactive_mode_exit()
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<Right>', function()
        M.interactive_mode_move('next', '<Right>')
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<Left>', function()
        M.interactive_mode_move('previous', '<Left>')
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<CR>', function()
        M.interactive_mode_interact('<CR>')
    end, {noremap = true, silent = true})
end

return M

