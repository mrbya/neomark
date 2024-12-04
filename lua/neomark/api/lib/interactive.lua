local I = {}

I.state = {
    current_buffer = 0,
    elements = {},
    current_element = {},
    interactive_mode = {}
}

function I.init()
    I.state.current_buffer = vim.api.nvim_get_current_buf()
    I.state.elements[I.state.current_buffer] = I.state.elements[I.state.current_buffer] or {}
    I.state.current_element[I.state.current_buffer] = I.state.current_element[I.state.current_buffer] or 0
    I.state.interactive_mode[I.state.current_buffer] = I.state.interactive_mode[I.state.current_buffer] or false
end

function I.set_interactive_mode(mode)
    I.state.interactive_mode[I.state.current_buffer] = mode
end

function I.get_interactive_mode()
    return I.state.interactive_mode[I.state.current_buffer] or false
end

function I.get_elements()
    return I.state.elements[I.state.current_buffer]
end

function I.clear()
    I.state.elements[I.state.current_buffer] = {}
end

function I.add_element(element)
    I.state.elements[I.state.current_buffer] = I.state.elements[I.state.current_buffer] or {}
    table.insert(I.state.elements[I.state.current_buffer], element)
end

function I.get_current_element_idx()
    return I.state.current_element[I.state.current_buffer]
end

function I.set_current_element_idx(idx)
    I.state.current_element[I.state.current_buffer] = idx
end

function I.get_closest_element()
    local elements = I.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    for i, element in ipairs(elements) do
        if element.line >= line and (element.stop > col or element.start > col) then
             I.set_current_element_idx(i)
            return element
        end
    end

    I.set_current_element_idx(1)
    return elements[1]
end

function I.get_next_element()
    local elements = I.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local i = I.get_current_element_idx()

    if i < #elements then
        I.set_current_element_idx(i + 1)
        return elements[i + 1]
    else
        I.set_current_element_idx(1)
        return elements[1]
    end
end

function I.get_previous_element()
    local elements = I.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local i = I.get_current_element_idx()

    if i > 1 then
        I.set_current_element_idx(i - 1)
        return elements[i - 1]
    else
        I.set_current_element_idx(#elements)
        return elements[#elements]
    end
end

I.interact_callbacks = {
    checkbox = function(line_idx, estart, line)
        local start, stop, status = line:find('%[(.)%]', estart)
        if start and stop then
            if status == 'x' then
                status = ' '
            else
                status = 'x'
            end

            vim.api.nvim_buf_set_text(0, line_idx, start - 1, line_idx, stop, { '[' .. status .. ']' })
        end
    end,

    link = function(_, estart, line)
        local start, stop, link = line:find('%[.-%]%((.-)%)', estart)
        if start and stop then
            local prefix = link:find('https?:%/%/')
            if prefix then
                vim.fn.system('xdg-open ' .. vim.fn.shellescape(link))
            else
                vim.api.nvim_command('edit ' .. link)
            end
        end
    end
}

function I.interact_action(element_idx)
    local element = I.get_elements()[element_idx]
    if not element or element == {} then
        return
    end

    I.interact_callbacks[element.type](
        element.line,
        element.estart,
        vim.api.nvim_buf_get_lines(0, element.line, element.line + 1, false)[1]
    )
end

I.move_callbacks = {
    forward = I.get_next_element,
    backward = I.get_previous_element,
}

function I.move_cursor(direction)
    local e = I.move_callbacks[direction]()
    if e then
        vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })
    end
end

function I.enter()
    local e = I.get_closest_element()

    if e and e ~= {} then
        vim.notify('Interactive mode', vim.log.levels.INFO)
        I.set_interactive_mode(true)
        vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })
    else
        vim.notify('No interactive elements!', vim.log.levels.ERROR)
    end
end

function I.exit()
    if I.get_interactive_mode() then
        print(' ')
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, true, true), 'n', true)
    end
    I.set_interactive_mode(false)
end

function I.move(direction, accelerator)
    if I.state.interactive_mode[I.state.current_buffer] then
        I.move_cursor(direction)
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

function I.interact(accelerator)
    if I.state.interactive_mode[I.state.current_buffer] then
        I.interact_action(I.get_current_element_idx())
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

return I
