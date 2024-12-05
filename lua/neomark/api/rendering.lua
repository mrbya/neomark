--- @module "neomark.api.rendering"
---
--- Neomark API submodule providing supported markdown element rendering.
---
local R = {}

--- @enum neomark.api.rendering.supported
---
--- Supported markdown eleennts.
R.supported = {
    'checkbox',
    'link',
    'inline',
    'h1',
    'h2',
}

--- @class neomark.api.rendering.config
---
--- Table to hold rendering api config.
R.config = {}

--- @class neomark.api.rendering.namespaces
---
--- Table to hold namespace ids.
R.namespaces = {}

--- @class neomark.api.rendering.element
---
--- Table providing element types and renderers.
R.element = {
    --- @enum neomark.api.rendering.element.types
    types = {
        checkbox = 'checkbox',
        link = 'link'
    },
}

--- Neomark API rendering submodule initialization function.
---
--- @param config neomark.config Neomark config.
---
function R.init(config)
    local disable = {}

    for _, element in ipairs(config.disable) do
        disable[element] = true
    end

    R.config = {}
    for _, element in ipairs(R.supported) do
        if not disable[element] then
            table.insert(R.config, element)
        end
    end

    for _, namespace in ipairs(R.config) do
        R.namespaces[namespace] = vim.api.nvim_create_namespace(namespace)
    end
end

--- Retrieve namespace id.
---
--- @param namespace string Namespace
---
--- @return integer Namespace id
---
function R.get_namespace_id(namespace)
    return R.namespaces[namespace]
end

--- Clear rendering of the active buffer.
function R.clear()
    for _, id in pairs(R.namespaces) do
        vim.api.nvim_buf_clear_namespace(0, id, 0, -1)
    end
end

--- Clear rendering of a specific line of the buffer.
---
--- @param line integer Line index.
---
function R.clear_line(line)
    for _, id in pairs(R.namespaces) do
        local marks = vim.api.nvim_buf_get_extmarks(0, id, { line, 0 }, { line, -1 }, {})
        if #marks > 0 then
            for _, mark in ipairs(marks) do
                vim.api.nvim_buf_del_extmark(0, id, mark[1])
            end
        end
    end
end

--- Construct interactive element table.
---
--- @param line integer Line index
--- @param start integer Element start column
--- @param stop integer Element stop column
--- @param istart integer Element interactive section start column
--- @param type neomark.api.rendering.element.types Interactive element type
---
--- @return neomark.api.element Constructed nteractive element
---
function R.create_interactive_element(line, start, stop, istart, len, type)
    return {
        line = line,
        start = start,
        stop = stop,
        istart = istart,
        len = len,
        type = type
    }
end

--- @type table<string, function>
R.element.renderers = {
    checkbox = function(i, line)
        local start, stop, prefix, status = line:find('-?(%d*%.?)%s%[(.)%]')
        if start and stop then

            local mark = ' '
            local hl = ""
            if status == 'x' then
                mark = ''
                hl = 'String'
            elseif status == '/' then
                mark = ''
                hl = 'Tag'
            elseif status == 'f' then
                mark = ''
                hl = 'WarningMsg'
            end

            local preflen = 0
            if prefix ~= nil and prefix ~= "" then
                preflen = string.len(prefix) - 1
                prefix = prefix .. ' '
            else
                prefix = '  '
            end

            vim.api.nvim_buf_set_extmark(0, R.get_namespace_id('checkbox'), i - 1, start - 1, {
                virt_text = { { prefix .. '[', 'WarningMsg' }, { mark, hl }, { ']', 'WarningMsg' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop - 5 - preflen,
                priority = 1,
            })

            return R.create_interactive_element(
                i - 1,
                start,
                stop,
                start + preflen + 2,
                1,
                R.element.types.checkbox
            )
        end
    end,

    link = function(i, line)
        local search_start = 0
        for _ in line:gmatch('%[(.[^%]]-)%]%(.-%)') do
            local start, stop, alt = line:find('%[(.[^%]]-)%]%(.-%)', search_start)
            if start and stop then
                search_start = stop
                return R.create_interactive_element(
                    i - 1,
                    start,
                    stop,
                    start,
                    alt:len(),
                    R.element.types.link
                )
            end
        end
    end,

    inline = function(i, line)
        local search_start = 0
        for _ in line:gmatch('%*%*.-%*%*') do
            local start, stop, text = line:find('%*%*(.-)%*%*', search_start)
            if start and stop then
                search_start = stop
                vim.api.nvim_buf_set_extmark(0, R.get_namespace_id('inline'), i - 1, start - 1, {
                    virt_text = { { text, 'Bold' }, {'\0'} },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                    conceal = '␀',
                    end_col = stop - 1,
                    priority = 2,
                })
                line = line:gsub('%*%*', '␀␀', 2)
            end
        end

        search_start = 0
        for _ in line:gmatch('%*.-%*') do
            local start, stop, text = line:find('%*(.-)%*', search_start)
            if start and stop then
                search_start = stop
                text = text:gsub('␀', '')
                vim.api.nvim_buf_set_extmark(0, R.get_namespace_id('inline'), i - 1, start - 1, {
                    virt_text = { { text, 'Italic' }, {'\0'} },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                    conceal = '␀',
                    end_col = stop - 1,
                    priority = 2,
                })
                line = line:gsub('%*', '␀', 2)
            end
        end

        search_start = 0
        for _ in line:gmatch('~.-~') do
            local start, stop, text = line:find('~(.-)~', search_start)
            if start and stop then
                search_start = stop
                text = text:gsub('␀', '')
                vim.api.nvim_buf_set_extmark(0, R.get_namespace_id('inline'), i - 1, start - 1, {
                    virt_text = { { text, '@markup.strikethrough' }, {'\0'} },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                    conceal = '␀',
                    end_col = stop - 2,
                    priority = 1,
                })
                line = line:gsub('%*', '␀', 2)
            end
        end
    end,

    h1 = function(i, line)
        local start, stop, text = line:find('^%s*#%s(.+)')
        if start and stop then
            vim.api.nvim_buf_set_extmark(0, R.get_namespace_id('h1'), i - 1, start - 1, {
                virt_text = { { '# ' .. text .. ' #', 'St_NormalMode' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop,
                priority = 1,
            })
        end
    end,

    h2 = function(i, line)
        local start, stop, text = line:find('^%s*##%s(.+)')
        if start and stop then
            vim.api.nvim_buf_set_extmark(0, R.get_namespace_id('h2'), i - 1, start - 1, {
                virt_text = { { '## ' .. text .. ' ##', 'Title' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop,
                priority = 1,
            })
        end
    end
}

--- Render a specific line of the active buffer.
---
--- @param line_idx integer Line index
--- @param line string Line contents
---
--- @return table Array of rendered interactive elements
function R.render_line(line_idx, line)
    local interactive_elements = {}
    for _, renderer in ipairs(R.config) do
        local ie = R.element.renderers[renderer](line_idx, line)
        if ie then
            table.insert(interactive_elements, ie)
        end
    end

    return interactive_elements
end

return R
