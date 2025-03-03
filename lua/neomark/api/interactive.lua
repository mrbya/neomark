--- @module "neomark.api.interactive"
---
--- Neomark API submodule providing features to interact with markdown elements such as checkboxes and links
---
local Interactive = {}

--- @class neomark.api.interactive.state
---
--- Tables to store buffer states for interactive API
---
--- @field elements table<neomark.api.element | any> Table of buffer-mapped arrays of interactive elements
--- @field current_element integer[] Table of buffer-mapped interac element indicies
--- @field interactive_mode boolean[] Table of buffer-mapped interactive mode states
---
_G.neomark.state.interactive = {
    elements = {},
    current_element = {},
    interactive_mode = {}
}

--- (Re)Initializes buffer state on buffer entry
---
function Interactive.init()
    _G.neomark.state.interactive.elements[_G.neomark.state.current_buffer] = _G.neomark.state.interactive.elements[_G.neomark.state.current_buffer] or {}
    _G.neomark.state.interactive.current_element[_G.neomark.state.current_buffer] = _G.neomark.state.interactive.current_element[_G.neomark.state.current_buffer] or 0
    _G.neomark.state.interactive.interactive_mode[_G.neomark.state.current_buffer] = _G.neomark.state.interactive.interactive_mode[_G.neomark.state.current_buffer] or false
end

--- Set interactive mode state of the current buffer
---
--- @param mode boolean Interactive mode setting
---
function Interactive.set_interactive_mode(mode)
    _G.neomark.state.interactive.interactive_mode[_G.neomark.state.current_buffer] = mode
end

--- Retrieve interactive mode state of the active buffer
---
--- @return boolean Interactive mode state of the active buffer
---
function Interactive.get_interactive_mode()
    return _G.neomark.state.interactive.interactive_mode[_G.neomark.state.current_buffer] or false
end

--- Retrieve array of interactive elements of the active buffer
---
--- @return neomark.api.element[] array of interactive elements in the active buffer
---
function Interactive.get_elements()
    return _G.neomark.state.interactive.elements[_G.neomark.state.current_buffer]
end

--- Clear interactive elements array of the active buffer
function Interactive.clear()
    _G.neomark.state.interactive.elements[_G.neomark.state.current_buffer] = {}
end

--- Add an interactive element to the state of the active buffer
---
--- @param element neomark.api.element Element to be added
---
function Interactive.add_element(element)
    _G.neomark.state.interactive.elements[_G.neomark.state.current_buffer] = _G.neomark.state.interactive.elements[_G.neomark.state.current_buffer] or {}
    table.insert(_G.neomark.state.interactive.elements[_G.neomark.state.current_buffer], element)
end

--- Get current element index of the active buffer.
---
--- @return integer Index of the vurrent element
---
function Interactive.get_current_element_idx()
    return _G.neomark.state.interactive.current_element[_G.neomark.state.current_buffer]
end

--- Set current element index of the active buffer
---
--- @param idx integer Current element index to be set
---
function Interactive.set_current_element_idx(idx)
    _G.neomark.state.interactive.current_element[_G.neomark.state.current_buffer] = idx
end

--- Find and return interactive element closest to the cursor in the active buffer
---
--- @return neomark.api.element | nil Found element
function Interactive.get_closest_element()
    local elements = Interactive.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    for i, element in ipairs(elements) do
        if element.line >= line and (element.stop > col or element.start > col) then
             Interactive.set_current_element_idx(i)
            return element
        end
    end

    Interactive.set_current_element_idx(1)
    return elements[1]
end

--- Find and return next element relative to current element state
---
--- @return neomark.api.element | nil Found element
---
function Interactive.get_next_element()
    local elements = Interactive.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local i = Interactive.get_current_element_idx()

    if i < #elements then
        Interactive.set_current_element_idx(i + 1)
        return elements[i + 1]
    else
        Interactive.set_current_element_idx(1)
        return elements[1]
    end
end


--- Find and return previous element relative to current element state
---
--- @return neomark.api.element | nil Found element
---
function Interactive.get_previous_element()
    local elements = Interactive.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local i = Interactive.get_current_element_idx()

    if i > 1 then
        Interactive.set_current_element_idx(i - 1)
        return elements[i - 1]
    else
        Interactive.set_current_element_idx(#elements)
        return elements[#elements]
    end
end

--- Find and return the 1st element on the closest next line containing interactive elements
---
--- @return neomark.api.element | nil Found element
---
function Interactive.get_next_line_element()
    local elements = Interactive.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local idx = Interactive.get_current_element_idx()
    local line = elements[idx].line

    for i = idx, #elements do
        if elements[i] and elements[i].line ~= line then
            Interactive.set_current_element_idx(i)
            return elements[i]
        end
    end

    for i = 1, idx do
        if elements[i] and elements[i].line ~= line then
            Interactive.set_current_element_idx(i)
            return elements[i]
        end
    end

    return nil
end

--- Find and return the 1st element on the closest previous line containing interactive elements
---
--- @return neomark.api.element | nil Found element
---
function Interactive.get_previous_line_element()
    local elements = Interactive.get_elements()

    if not elements or elements == {} then
        return nil
    end

    local idx = Interactive.get_current_element_idx()
    local line = elements[idx].line

    for i = idx, 0, -1 do
        if elements[i] and elements[i].line ~= line then
            line = elements[i].line
            for j = i, 1, -1 do
                if elements[j] and elements[j].line ~= line then
                    Interactive.set_current_element_idx(j + 1)
                    return elements[j + 1]
                end
            end
            Interactive.set_current_element_idx(i)
            return elements[i]
        end
    end

    for i = #elements, idx, -1 do
        if elements[i] and elements[i].line ~= line then
            line = elements[i].line
            for j = i, 1, -1 do
                if elements[j] and elements[j].line ~= line then
                    Interactive.set_current_element_idx(j + 1)
                    return elements[j + 1]
                end
            end
            Interactive.set_current_element_idx(i)
            return elements[i]
        end
    end

    return nil
end

--- @class neomark.api.interactive.interact_callbacks
---
--- Table of element interaction callbacks
Interactive.interact_callbacks = {
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
    --- Optionally moves cursor if a specific section is linked
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
            if not prefix then
                prefix = link:find('www.')
            end
            if prefix then
                vim.fn.system('xdg-open ' .. vim.fn.shellescape(link))
            else
                local newBuffer = false

                -- look for section suffix
                local _, _, suffix, section = link:find('.+(%#(%S+)%s*)$')
                if suffix then
                    newBuffer = true
                else
                    _, _, section = link:find('^%s*%#(%S+)$')
                end

                -- open linked file (if need be) and move cursor to the corresponding section
                if section then
                    if newBuffer then
                        link:gsub(suffix, "")
                        vim.api.nvim_command('edit ' .. link)
                    end
                    -- move cursor
                    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                    for idx, tline in ipairs(lines) do
                        tline = tline:gsub('%s', '-')

                        local col = tline:find('^#+%-*' .. section)
                        if col then
                            vim.api.nvim_win_set_cursor(0, {idx, col + 1})
                            Interactive.set_interactive_mode(false)
                            return
                        end
                    end
                else
                    vim.api.nvim_command('edit ' .. link)
                end
            end
        end
    end
}

--- Interact with the nth interactive element form the buffer state
---
--- @param element_idx integer Buffer state interactive element index
---
function Interactive.interact_action(element_idx)
    local element = Interactive.get_elements()[element_idx]
    if not element or element == {} then
        return
    end

    Interactive.interact_callbacks[element.type](
        element.line,
        element.start,
        vim.api.nvim_buf_get_lines(0, element.line, element.line + 1, false)[1]
    )
end

--- @class neomark.api.interactive.movement
---
--- Table of cursor movement directions and their callbacks
Interactive.movement = {
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
        forward = Interactive.get_next_element,
        backward = Interactive.get_previous_element,
        up = Interactive.get_previous_line_element,
        down = Interactive.get_next_line_element,
    }
}

--- Move cursor between interactive elements
---
--- @param direction neomark.api.interactive.movement.direction | string Movement direction
---
function Interactive.move_cursor(direction)
    local e = Interactive.movement.callbacks[direction]()
    if e then
        vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })
    end
end

--- Enter interactive mode
function Interactive.enter()
    local e = Interactive.get_closest_element()

    if e and e ~= {} then
        Interactive.set_interactive_mode(true)
        vim.api.nvim_win_set_cursor(0, { e.line + 1, e.istart })

        vim.notify('Interactive mode - enter', vim.log.levels.INFO)
        vim.api.nvim_echo({ { 'Interactive mode' } }, false, {})
    else
        vim.notify('No interactive elements!', vim.log.levels.ERROR)
    end
end

--- Exit interactive mode
function Interactive.exit()
    Interactive.set_interactive_mode(false)

    if Interactive.get_interactive_mode() then
        vim.notify('Interactive mode - exit', vim.log.levels.INFO)
        vim.api.nvim_echo({}, false, {})
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, true, true), 'n', true)
    end
end

--- Cursor movement command
---
--- @param direction neomark.api.interactive.movement.direction | string Direction to move cursor in
--- @param accelerator neomark.config.keymap Keymap accelerator
---
function Interactive.move(direction, accelerator)
    if Interactive.get_interactive_mode() then
        Interactive.move_cursor(direction)
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

--- Command to interact with an element
---
--- @param accelerator neomark.config.keymap Keymap accelerator
---
function Interactive.interact(accelerator)
    if Interactive.get_interactive_mode() then
        Interactive.interact_action(Interactive.get_current_element_idx())
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(accelerator, true, true, true), 'n', true)
    end
end

return Interactive
