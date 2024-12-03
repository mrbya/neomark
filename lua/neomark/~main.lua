local M = {}

M.rendering = require('neomark.rendering')
M.interactive_mode = require('neomark.interactive_mode')

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

-- Get elements table for the current buffer
function M.get_elements_table()
    return M.buffers[M.current_buffer]
end

-- Clear rendering of all namespaces
function M.clear_rendering()
    for _, namespace in ipairs(M.rendering.elements) do
        vim.api.nvim_buf_clear_namespace(0, M.rendering.element.namespaces[namespace], 0, -1)
    end

    M.buffers[M.current_buffer] = {}
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

-- Add interactable element to the element table of the current buffer
function M.add_interactable(element)
    M.buffers[M.current_buffer] = M.buffers[M.current_buffer] or {}
    table.insert(M.buffers[M.current_buffer], element)
end

-- Get the next interactable element closest to the cursor
function M.get_closest_interactable()
    local elements = M.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    for i, element in ipairs(elements) do
        if element.line >= line and (element.stop > col or element.start > col) then
            M.current_element = i
            return element
        end
    end

    M.current_element = 1
    return elements[1]
end

-- Return the next interactable element
function M.get_next_interactable()
    local elements = M.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local i = M.current_element

    if i < #elements then
        M.current_element = i + 1
        return elements[i + 1]
    else
        M.current_element = 1
        return elements[1]
    end
end

-- Raturn the previous interactable element
function M.get_prev_interactable()
    local elements = M.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local i = M.current_element

    if i > 1 then
        M.current_element = i - 1
        return elements[i - 1]
    else
        M.current_element = #elements
        return elements[#elements]
    end
end

-- Function to interact with an interactable element
function M.interact(element)
    local elements = M.get_elements_table()
    element = elements[element]
    local type = element.type
    local i = element.line
    local estart = element.start
    local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
    if type == 0 then
        local start, stop, status = line:find("%[(.)%]", estart)
        if start and stop then
            if status == "x" then
                status = " "
            else
                status = "x"
            end

            vim.api.nvim_buf_set_text(0, i, start - 1, i, stop, { '[' .. status .. ']' })
        end
    elseif type == 1 then
        local start, stop, link = line:find("%[.-%]%((.-)%)", estart)
        if start and stop then
            local prefix = link:find("https?://")
            if prefix then
                vim.fn.system('xdg-open' .. vim.fn.shellescape(link))
            else
                vim.api.nvim_command('edit ' .. link)
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
                M.add_interactable(ie)
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
        local e = M.interactive_mode.callbacks[direction]()
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
            M.buffer_init()
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

