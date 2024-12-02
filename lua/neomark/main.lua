local M = {}

-- Tables to store buffer states
M.buffers = {}
M.current_buffer = {}

-- Extmark elements for different makrdown elements
M.elements = {
    'checkboxes',
    'links',
    'inline',
    'h1',
    'h2',
}

-- Create elements for all supported elements
function M.create_namespaces()
    for _, namespace in ipairs(M.elements) do
        M.elements[namespace] = vim.api.nvim_create_namespace(namespace)
    end
end

function M.get_elements_table()
    return M.buffers[M.current_buffer]
end

-- Clear rendering of all namespaces
function M.clear_rendering()
    for _, namespace in ipairs(M.elements) do
        vim.api.nvim_buf_clear_namespace(0, M.elements[namespace], 0, -1)
    end

    M.buffers[M.current_buffer] = {}
end

-- Clear rendering elements of a single line
function M.clear_line(line)
    for _, namespace in ipairs(M.elements) do
        local marks = vim.api.nvim_buf_get_extmarks(0, M.elements[namespace], { line, 0 }, { line, -1 }, {})
        if #marks > 0 then
            for _, mark in ipairs(marks) do
                vim.api.nvim_buf_del_extmark(0, M.elements[namespace], mark[1])
            end
        end
    end
end

function M.add_interactable(line, start, stop, istart, ilen, type)
    M.buffers[M.current_buffer][line] = M.buffers[M.current_buffer][line] or {}
    table.insert(M.buffers[M.current_buffer][line], {start = start, stop = stop, istart = istart, ilen = ilen, type = type})
end

function M.get_next_interactable()
    local elements = M.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    if elements[line] and elements[line] ~= {} then
        for _, element in ipairs(elements[line]) do
            if col < element.start then
                return { line, element }
            end
        end
    end

    ::wraparound::

    for i = line + 1, vim.api.nvim_buf_line_count(0) do
        if elements[i] and elements[i] ~= {} then
            for _, element in ipairs(elements[i]) do
                if element ~= nil and element ~= {} then
                    return { i, element }
                end
            end
        end
    end

    line = 0
    goto wraparound
end

function M.get_prev_interactable()
    local elements = M.get_elements_table()

    if not elements or elements == {} then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    if elements[line] and elements[line] ~= {} then
        for _, element in ipairs(elements[line]) do
            if col > element.stop then
                return { line, element }
            end
        end
    end

    if line == 0 then
        line = #elements
    else
        line = line - 1
    end

    ::wraparound::

    for i = line, 0, -1 do
        for j = #elements[i], 1, -1 do
            if elements[j] and elements[j] ~= {} then
                if elements[i][j] and elements[i][j] ~= {} then
                    return { line, elements[i][j] }
                end
            end
        end
    end

    line = #elements
    goto wraparound
end

M.renderers = {
    checkboxes = function(i, line)
        local start, stop, prefix, status = line:find("-?(%d*%.?)%s%[(.)%]")
        if start and stop then

            local mark = ' '
            local hl = ""
            if status == 'x' then
                mark = ''
                hl = "String"
            elseif status == '/' then
                mark = ''
                hl = "Tag"
            elseif status == 'f' then
                mark = ''
                hl = "WarningMsg"
            end

            local preflen = 0
            if prefix ~= nil and prefix ~= "" then
                preflen = string.len(prefix) - 1
                prefix = prefix .. ' '
            else
                prefix = '  '
            end

            vim.api.nvim_buf_set_extmark(0, M.elements['checkboxes'], i - 1, start - 1, {
                virt_text = { { prefix .. '[', "WarningMsg" }, { mark, hl }, { ']', "WarningMsg" } },
                virt_text_pos = "overlay",
                conceal = "␀",
                end_col = stop - 5 - preflen,
                priority = 1,
            })

            M.add_interactable(i - 1, start, stop, start + preflen + 2, 1, 0)
        end
    end,

    links = function(i, line)
        local search_start = 0
        for _ in line:gmatch("%[(.-)%]%(.-%)") do
            local start, stop, alt = line:find("%[(.-)%]%(.-%)", search_start)
            if start and stop then
                search_start = stop

                -- vim.api.nvim_buf_set_extmark(0, M.elements['links'], i - 1, start - 1, {
                --     virt_text = { { '[', "WarningMsg" }, { alt, "Special" }, { ']\0 ', "WarningMsg" } },
                --     virt_text_pos = 'overlay',
                --     hl_mode = 'combine',
                --     conceal = " ",
                --     end_col = concealed_offset,
                --     priority = 1
                -- })

                M.add_interactable(i - 1, start, stop, start, alt:len(), 1)
            end
        end
    end,

    inline = function(i, line)
        local search_start = 0
        for _ in line:gmatch("%*%*.-%*%*") do
            local start, stop, text = line:find("%*%*(.-)%*%*", search_start)
            if start and stop then
                search_start = stop
                vim.api.nvim_buf_set_extmark(0, M.elements['inline'], i - 1, start - 1, {
                    virt_text = { { text, 'Bold' }, {'\0'} },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                    conceal = '␀',
                    end_col = stop - 1,
                    priority = 2,
                })
                line = line:gsub("%*%*", "␀␀", 2)
            end
        end

        search_start = 0
        for _ in line:gmatch("%*.-%*") do
            local start, stop, text = line:find("%*(.-)%*", search_start)
            if start and stop then
                search_start = stop
                text = text:gsub("␀", "")
                vim.api.nvim_buf_set_extmark(0, M.elements['inline'], i - 1, start - 1, {
                    virt_text = { { text, 'Italic' }, {'\0'} },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                    conceal = '␀',
                    end_col = stop - 1,
                    priority = 2,
                })
                line = line:gsub("%*", "␀", 2)
            end
        end

        search_start = 0
        for _ in line:gmatch("~.-~") do
            local start, stop, text = line:find("~(.-)~", search_start)
            if start and stop then
                search_start = stop
                text = text:gsub("␀", "")
                vim.api.nvim_buf_set_extmark(0, M.elements['inline'], i - 1, start - 1, {
                    virt_text = { { text, '@markup.strikethrough' }, {'\0'} },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                    conceal = '␀',
                    end_col = stop - 2,
                    priority = 1,
                })
                line = line:gsub("%*", "␀", 2)
            end
        end
    end,

    h1 = function(i, line)
        local start, stop, text = line:find("^%s*#%s(.+)")
        if start and stop then
            vim.api.nvim_buf_set_extmark(0, M.elements['h1'], i - 1, start - 1, {
                virt_text = { { '# ' .. text .. ' #', 'St_NormalMode' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop,
                priority = 1,
            })
        end
    end,

    h2 = function(i, line)
        local start, stop, text = line:find("^%s*##%s(.+)")
        if start and stop then
            vim.api.nvim_buf_set_extmark(0, M.elements['h2'], i - 1, start - 1, {
                virt_text = { { '## ' .. text .. ' ##', 'Title' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop,
                priority = 1,
            })
        end
    end
}

-- Render supported elements in a single line
function M.render_line(i)
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    if line then
        for _, renderer in ipairs(M.elements) do
            M.renderers[renderer](i, line)
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
    -- for i, line in pairs(M.buffers[M.current_buffer]) do
    --     print("line " .. i .. ":")
    --     for _, col in pairs(line) do
    --         if col ~= nil or col ~= {} then
    --             print("element " .. _ .. ': ' .. col.start .. ', ' .. col.stop)
    --         end
    --     end
    -- end

    local e = M.get_next_interactable()
    vim.api.nvim_win_set_cursor(0, {e[1] + 1, e[2].istart})
    -- for _, v in e do
    --     print(v)
    -- end
    -- print(e)
end

-- Load neomark plugin
function M.load()
    vim.api.nvim_clear_autocmds({pattern = "*.md"})
    M.create_namespaces()

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = "*.md",
        callback = function()
            M.current_buffer = vim.api.nvim_get_current_buf()
            M.buffers[M.current_buffer] = M.buffers[M.current_buffer] or {}
            vim.b.custom_mode = false
        end
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        pattern = "*.md",
        callback = function()
            local line = vim.api.nvim_win_get_cursor(0)[1]
            line = line - 1
            M.clear_rendering()
            M.render_buf()
            M.clear_line(line)
        end
    })

    -- Run markdown element rendering
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
        pattern = "*.md",
        callback = function()
            if vim.fn.mode() == "n" or vim.fn.mode() == "v" then
                vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
                M.render_buf()
                vim.api.nvim_set_option_value('conceallevel', 2, { scope = 'local' })
            end
        end,
    })

    -- Disable link rendering on entering insert mode
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        pattern = "*.md",
        callback = function()
            vim.api.nvim_set_option_value('conceallevel', 0, { scope = 'local' })
            M.clear_rendering()
        end,
    })

    vim.api.nvim_create_user_command("Interactables", M.interactables, {})
    vim.keymap.set('n', '<leader>l', function()
        print('Interactive mode')
        vim.b.custom_mode = true
        M.interactables()
    end)

    vim.keymap.set('', '<Esc>', function()
        if vim.b.custom_mode then
            print(" ")
        end
        vim.b.custom_mode = false
    end)

    vim.keymap.set('n', '<Right>', function()
        if vim.b.custom_mode then
            local e = M.get_next_interactable()
            vim.api.nvim_win_set_cursor(0, {e[1] + 1, e[2].istart})
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Right>', true, true, true), 'n', true)
        end
    end, { noremap = true, silent = true })

    vim.keymap.set('n', '<Left>', function()
        if vim.b.custom_mode then
            local e = M.get_prev_interactable()
            vim.api.nvim_win_set_cursor(0, {e[1] + 1, e[2].istart})
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Left>', true, true, true), 'n', true)
        end
    end, { noremap = true, silent = true })
end

return M

