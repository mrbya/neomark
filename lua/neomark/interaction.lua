local I = {}

function I.init()
    vim.b.elements = {}
    vim.b.current_element = 0
    vim.b.interactive_mode = false
end

function I.set_interactive_mode(mode)
    vim.b.interactive_mode = mode
end

function I.get_interactive_mode()
    return vim.b.interactive_mode or false
end

function I.get_elements()
    return vim.b.elements
end

function I.clear_elements()
    vim.b.elements = {}
end

function I.add_element(element)
    vim.b.elements = vim.b.elements or {}
    table.insert(vim.b.elements, element)
end

function I.get_current_element_idx()
    return vim.b.current_element
end

function I.set_current_element_idx(idx)
    vim.b.current_element = idx
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
        local start, stop, status = line:find("%[(.)%]", estart)
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
}

function I.interact(element_idx)
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

return I
