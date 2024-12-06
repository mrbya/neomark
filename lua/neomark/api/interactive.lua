--- @module "neomark.api.interactive"
---
--- Neomark API submodule providing features to interact with markdown elements such as checkboxes and links
---
local I = {}

--- @class neomark.api.interactive.state
---
--- Tables to store buffer states.
---
--- @field current_buffer integer Active buffer index
--- @field elements table<neomark.api.element | any> Table of buffer-mapped arrays of interactive elements
--- @field current_element integer[] Table of buffer-mapped interac element indicies
--- @field interactive_mode boolean[] Table of buffer-mapped interactive mode states
---
I.state = {
    current_buffer = 0,
    elements = {},
    current_element = {},
    interactive_mode = {}
}

--- Neomark API interactive submodule initialization function
---
--- (Re)Initializes buffer stat on buffer entry.
---
function I.init()
    I.state.current_buffer = vim.api.nvim_get_current_buf()
    I.state.elements[I.state.current_buffer] = I.state.elements[I.state.current_buffer] or {}
    I.state.current_element[I.state.current_buffer] = I.state.current_element[I.state.current_buffer] or 0
    I.state.interactive_mode[I.state.current_buffer] = I.state.interactive_mode[I.state.current_buffer] or false
end

--- Set interactive mode for the current buffer
---
--- @param mode boolean Interactive mode setting.
---
function I.set_interactive_mode(mode)
    I.state.interactive_mode[I.state.current_buffer] = mode
end

--- Retrieve interactive mode state of the active buffer
---
--- @return boolean Interactive mode state of the active buffer
---
function I.get_interactive_mode()
    return I.state.interactive_mode[I.state.current_buffer] or false
end

--- Retrieve array of interactive elements of the active buffer
---
--- @return neomark.api.element[] array of interactive elements of the active buffer
---
function I.get_elements()
    return I.state.elements[I.state.current_buffer]
end

--- Clear interactive elements array of the active buffer
function I.clear()
    I.state.elements[I.state.current_buffer] = {}
end

--- Add an interactive element to the state of the active buffer
---
--- @param element neomark.api.element Element to be added
---
function I.add_element(element)
    I.state.elements[I.state.current_buffer] = I.state.elements[I.state.current_buffer] or {}
    table.insert(I.state.elements[I.state.current_buffer], element)
end

--- Get current element index of the active buffer.
---
--- @return integer Index of the vurrent element
---
function I.get_current_element_idx()
    return I.state.current_element[I.state.current_buffer]
end

--- Set current element index of the active buffer
---
--- @param idx integer Current element index to be set
---
function I.set_current_element_idx(idx)
    I.state.current_element[I.state.current_buffer] = idx
end

--- Find an return interactive element closest to the cursor in the active buffer
---
--- @return neomark.api.element | nil Found element
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

--- Find and return next element relative to current element state
---
--- @return neomark.api.element | nil Found element
---
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


--- Find and return previous element relative to current element state
---
--- @return neomark.api.element | nil Found element
---
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

--- Find and return the 1st element on the closest next line containing interactive elements
---
--- @return neomark.api.element | nil Found element
---
function I.get_next_line_element()
    local elements = I.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local idx = I.get_current_element_idx()
    local line = elements[idx].line

    for i = idx, #elements do
        if elements[i] and elements[i].line ~= line then
            I.set_current_element_idx(i)
            return elements[i]
        end
    end

    for i = 1, idx do
        if elements[i] and elements[i].line ~= line then
            I.set_current_element_idx(i)
            return elements[i]
        end
    end

    return nil
end

--- Find and return the 1st element on the closest previous line containing interactive elements
---
--- @return neomark.api.element | nil Found element
---
function I.get_previous_line_element()
    local elements = I.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local idx = I.get_current_element_idx()
    local line = elements[idx].line

    for i = idx, 0, -1 do
        if elements[i] and elements[i].line ~= line then
            line = elements[i].line
            for j = i, 1, -1 do
                if elements[j] and elements[j].line ~= line then
                    I.set_current_element_idx(j + 1)
                    return elements[j + 1]
                end
            end
            I.set_current_element_idx(i)
            return elements[i]
        end
    end

    for i = #elements, idx, -1 do
        if elements[i] and elements[i].line ~= line then
            line = elements[i].line
            for j = i, 1, -1 do
                if elements[j] and elements[j].line ~= line then
                    I.set_current_element_idx(j + 1)
                    return elements[j + 1]
                end
            end
            I.set_current_element_idx(i)
            return elements[i]
        end
    end

    return nil
end

--- @class neomark.api.interactive.interact_callbacks
---
--- Table of element interaction callbacks
I.interact_callbacks = {
    --- Togglex checkbox.
    ---
    --- @param line_idx integer Line index
    --- @param estart integer Element start column index
    --- @param line string Line contents
    ---
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

    --- Open link
    ---
    --- Opens file in a new buffer if pointing to a file
    --- If http/s link opens uses xdg-open to open the link in a browser
    --- 
    --- @param _ any
    --- @param estart integer Element start column index
    --- @param line string Line contents
    ---
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

--- Interact with the nth interactive element form the buffer state
---
--- @param element_idx integer Buffer state element index
---a custom type 
function I.interact_action(element_idx)
    local element = I.get_elements()[element_idx]
    if not element or element == {} then
        return
    end

    I.interact_callbacks[element.type](
        element.line,
        element.start,
        vim.api.nvim_buf_get_lines(0, element.line, element.line + 1, false)[1]
    )
end

--- @class neomark.api.interactive.movement
---
--- Table of cursor movement directions and callbacks
I.movement = {
    --- @enum neomark.api.interactive.movement.direction
    ---
    --- Cursor movement directions
    directions = {
        'forward',
        'backward',
        'up',
        'down',
    },

    --- @type table<string, function>
    ---
    --- Cursor movement callbacks
    callbacks = {
        forward = I.get_next_element,
        backward = I.get_previous_element,
        up = I.get_previous_line_element,
        down = I.get_next_line_element,
    }
}

--- Move cursor between interactive elements
---
--- @param direction neomark.api.interactive.movement.direction | string Movement direction
---
function I.move_cursor(direction)
    local e = I.movement.callbacks[direction]()
    if e then
        vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })
    end
end

--- Enter interactive mode
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

--- Exit interactive mode
function I.exit()
    if I.get_interactive_mode() then
        print(' ')
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, true, true), 'n', true)
    end
    I.set_interactive_mode(false)
end

--- Cursor movement command
---
--- @param direction neomark.api.interactive.movement.direction | string Direction to move cursor in
--- @param accelerator neomark.config.keymap Keymap accelerator
---
function I.move(direction, accelerator)
    if I.get_interactive_mode() then
        I.move_cursor(direction)
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

--- Command to interact with an element
---
--- @param accelerator neomark.config.keymap Keymap accelerator
---
function I.interact(accelerator)
    if I.get_interactive_mode() then
        I.interact_action(I.get_current_element_idx())
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

return I
