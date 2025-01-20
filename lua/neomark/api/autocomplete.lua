--- @module "neomark.api.autocomplete"
---
--- Neomark API submodule providing autocomplete for numbered lists and bullet point lists
local Autocomplete = {}

--- @class neomark.api.autocomplete.state
---
--- Table to store buffer states for autocompletion
---
--- @field current_buffer integer Active buffer index
--- @field buffer_len integer[] Table containing lengths of open buffers
---
Autocomplete.state = {
    current_buffer = 0,
    buffer_len = {},
}

--- @enum neomark.api.autocomplete.supported
---
--- Supported autocomplete elements
---
Autocomplete.supported = {
    'bullet_point_list',
    'numbered_list',
}

--- @class neomark.api.autocomplete.config
---
--- Table to hold autocomplete api config
---
Autocomplete.config = {}

--- Function to load neomark autocomplete API
--- 
--- @param config neomark.config Neomark config
---
function Autocomplete.load(config)
    local disable = {}

    for _, element in ipairs(config.disable) do
        disable[element] = true
    end

    Autocomplete.config = {}
    for _, element in ipairs(Autocomplete.supported) do
        if not disable[element] then
            table.insert(Autocomplete.config, element)
        end
    end
end

-- (Re)Initializes buffer state on buffer entry
--
function Autocomplete.init()
    Autocomplete.state.current_buffer = vim.api.nvim_get_current_buf()
    Autocomplete.state.buffer_len[Autocomplete.state.current_buffer] = vim.api.nvim_buf_line_count(0)
end

--- Updates active buffer length state
---
--- @param len integer Active buffer length
---
function Autocomplete.set_buffer_len(len)
    Autocomplete.state.buffer_len[Autocomplete.state.current_buffer] = len
end

--- Returns active buffer length
---
--- @return integer Active buffer length
---
function Autocomplete.get_buffer_len()
    return Autocomplete.state.buffer_len[Autocomplete.state.current_buffer]
end

--- @class neomark.api.autocomplete.completer
---
--- Autocomplete API class providing autocompletion
--- for a specific element
---
--- @field pattern string List item prefix pattern
--- @field dynamic boolean Signifies whether the list is dynamic
--- @field value_processor function value processing callback

--- @type table<string, neomark.api.autocomplete.completer>
---
--- Supported element completers
---
Autocomplete.completers = {
    bullet_point_list = {
        pattern = '-',
        dynamic = false,
        value_processor = function(value)
            return value
        end
    },

    numbered_list = {
        pattern = '%d+%.',
        dynamic = true,
        value_processor = function(value)
            local _, _, val = value:find('(%d+)')
            return tostring(val + 1) .. '.'
        end
    }
}

--- Handle autocompletion based on the provided line and completer
--- 
--- @param line string Buffer line contents
--- @param line_idx integer Line index
--- @param completer neomark.api.autocomplete.completer Element completer
---
function Autocomplete.complete(line, line_idx, completer)
    local start, stop, prefix, value = line:find('^(%s*)(' .. completer.pattern .. ')%s+%S')
    if start and stop and value then
        value = completer.value_processor(value)
        vim.api.nvim_buf_set_lines(0, line_idx, line_idx + 1, false, { prefix .. value .. " " })
        vim.api.nvim_win_set_cursor(0, { line_idx + 1, prefix:len() + value:len() + 1 })

        if (not completer.dynamic or line_idx + 1 >= Autocomplete.get_buffer_len()) then
            return
        end

        local tidx = line_idx
        local tline, item
        repeat
            tline = vim.api.nvim_buf_get_lines(0, tidx + 1, tidx + 2, false)[1]
            if tline then
                start, stop, item = tline:find('^(%s*' .. completer.pattern .. '%s*)')
            else
                break
            end
            if start and stop and item then
                value = completer.value_processor(value)
                local newitem = item:gsub(completer.pattern, value, 1)
                tline = tline:gsub(item, newitem, 1)
                vim.api.nvim_buf_set_lines(0, tidx + 1, tidx + 2, true, { tline })
                tidx = tidx + 1
            end
        until not tline or not item
    else
        start, stop, value = line:find('^%s*(' .. completer.pattern .. ')%s*$')
        if start and stop and value then
            vim.api.nvim_buf_set_lines(0, line_idx - 1 , line_idx, false, {})

            if completer.dynamic or line_idx + 1 >= Autocomplete.get_buffer_len() then
                local tidx = line_idx
                local tline, item, tprefix, tsuffix
                repeat
                    tline = vim.api.nvim_buf_get_lines(0, tidx, tidx + 1, false)[1]
                    if tline then
                        start, stop, item, tprefix, tsuffix = tline:find('^((%s*)' .. completer.pattern .. '(%s*))')
                    else
                        break
                    end
                    if start and stop and item then
                        local newline = tline:gsub(item, tprefix .. value .. tsuffix, 1)
                        vim.api.nvim_buf_set_lines(0, tidx, tidx + 1, true, { newline })
                        value = completer.value_processor(value)
                        tidx = tidx + 1
                    end
                until not item
            end
        end
    end
end

--- Process autocomplete for the current line
---
function Autocomplete.process_line()
    local cursor = vim.api.nvim_win_get_cursor(0);
    local line_idx = cursor[1] - 1;

    if line_idx > 1 then
        local line = vim.api.nvim_buf_get_lines(0, line_idx - 1, line_idx, false)[1]
        if line and line ~= "" then
            for _, completer in pairs(Autocomplete.config) do
                Autocomplete.complete(line, line_idx, Autocomplete.completers[completer])
            end
        end
    end
end

return Autocomplete
