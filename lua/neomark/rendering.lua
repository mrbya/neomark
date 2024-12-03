local R = {}

R.elements = {
    'checkboxes',
    'links',
    'inline',
    'h1',
    'h2',
}

R.element = {
    namespaces = {},
    types = {
        checkbox = 0,
        link = 1
    }
}

function R.create_interactable(line, start, stop, istart, len, type)
    return { line = line, start = start, stop = stop, istart = istart, len = len, type = type }
end

R.renderers = {
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

            vim.api.nvim_buf_set_extmark(0, R.element.namespaces['checkboxes'], i - 1, start - 1, {
                virt_text = { { prefix .. '[', "WarningMsg" }, { mark, hl }, { ']', "WarningMsg" } },
                virt_text_pos = "overlay",
                conceal = "␀",
                end_col = stop - 5 - preflen,
                priority = 1,
            })

            return R.create_interactable(i - 1, start, stop, start + preflen + 2, 1, R.element.types.checkbox)
        end
    end,

    links = function(i, line)
        local search_start = 0
        for _ in line:gmatch("%[(.[^%]]-)%]%(.-%)") do
            local start, stop, alt = line:find("%[(.[^%]]-)%]%(.-%)", search_start)
            if start and stop then
                search_start = stop
                return R.create_interactable(i - 1, start, stop, start, alt:len(), R.element.types.link)
            end
        end
    end,

    inline = function(i, line)
        local search_start = 0
        for _ in line:gmatch("%*%*.-%*%*") do
            local start, stop, text = line:find("%*%*(.-)%*%*", search_start)
            if start and stop then
                search_start = stop
                vim.api.nvim_buf_set_extmark(0, R.element.namespaces['inline'], i - 1, start - 1, {
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
                vim.api.nvim_buf_set_extmark(0, R.element.namespaces['inline'], i - 1, start - 1, {
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
                vim.api.nvim_buf_set_extmark(0, R.element.namespaces['inline'], i - 1, start - 1, {
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
            vim.api.nvim_buf_set_extmark(0, R.element.namespaces['h1'], i - 1, start - 1, {
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
            vim.api.nvim_buf_set_extmark(0, R.element.namespaces['h2'], i - 1, start - 1, {
                virt_text = { { '## ' .. text .. ' ##', 'Title' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop,
                priority = 1,
            })
        end
    end
}

return R
