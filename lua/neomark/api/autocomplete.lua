--- @module "neomark.api.autocomplete"
---
--- Neomark API submodule providing autocomplete for numbered lists and bullet point lists
local A = {}

A.state = {
    buf_lines = 0
}

local last_lines = 0

A.supported = {
    'bullet_point',
    'numbered',
}

function A.init()
    A.state.buf_lines = vim.api.nvim_buf_line_count(0);
end

A.lists = {
    types = {
        bullet_point = 'bullet_point',
        numbered = 'numbered',
    },

    completers = {
        bullet_point = {
            pattern = '-',
            value_processor = function(value)
                return value
            end
        },

        numbered = {
            pattern = '%d+%.',
            value_processor = function(value)
                -- return tostring(tonumber(value:find('%d+'))) .. '.'
                local _, _, num = value:find('%d+')
                print(value)
                if (num) then
                    print(num)
                else
                    print('nopeeee!')
                end
                return value
            end
        }
    },
}

function A.complete(line, line_idx, col, completer)
    local start, stop, prefix, value = line:find('^(%s*)(' .. completer.pattern .. ')%s%S')
    if start and stop and value then
        value = completer.value_processor(value)
        value = prefix .. value .. " "
        vim.api.nvim_buf_set_text(0, line_idx, col, line_idx, col, { value })
        vim.api.nvim_win_set_cursor(0, { line_idx + 1, col + value:len() + 1 })
    else
        start, stop =line:find('^%s*' .. completer.pattern .. '%s*$')
        if start and stop then
            vim.api.nvim_buf_set_lines(0, line_idx - 1, line_idx, false, {})
        end
    end
end

function A.process_line()
    local cursor = vim.api.nvim_win_get_cursor(0);
    local line_idx = cursor[1] - 1;
    local col = cursor[2] - 1

    if line_idx > 1 then
        local line = vim.api.nvim_buf_get_lines(0, line_idx - 1, line_idx, false)[1]
        if line and line ~= "" then
            A.complete(
                line,
                line_idx,
                col,
                A.lists.completers.numbered
            )
        end
    end
end

function A.detect_newline()
    local lines = vim.api.nvim_buf_line_count(0);

    if A.state.buf_lines > lines then
        A.process_line()
    end

    A.state.buf_lines = lines
end

function A.load()
    print("Loaded autocomplete")

    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = "*.md",
        callback = function()
            A.init()
        end
    })


    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
        pattern = "*.md",
        callback = function()
            A.detect_newline()
        end
    })

end

return A
