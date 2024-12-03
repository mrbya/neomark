local I = {}

-- Tables to store buffer states
local state = {
    current_buffer = 0,
    elements = {},
    current_element = {},
}

function I.get_elements_table()
    return state.elements[state.current_buffer]
end

function I.clear_elements_table()
    state.elements[state.current_buffer] = {}
end

function I.add_element(element)
    state.elements[state.current_buffer] = state.elements[state.current_buffer] or {}
    table.insert(state.elements[state.current_buffer], element)
end

function I.get_closest_element()
    local elements = I.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    for i, element in ipairs(elements) do
        if element.line >= line and (element.stop > col or element.start > col) then
            state.current_element = i
            return element
        end
    end

    state.current_element = 1
    return elements[1]
end

function I.get_next_element()
    local elements = I.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local i = state.current_element

    if i < #elements then
        state.current_element = i + 1
        return elements[i + 1]
    else
        state.current_element = 1
        return elements[1]
    end
end

return I
