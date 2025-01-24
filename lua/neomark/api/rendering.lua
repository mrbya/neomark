--- @module "neomark.api.rendering"
---
--- Neomark API submodule providing supported markdown element rendering
---
local Rendering = {}

--- @enum neomark.api.rendering.supported
---
--- Supported markdown eleennts.
---
Rendering.supported = {
    'checkbox',
    'link',
    'inline',
    'h1',
    'h2',
    'table',
}

--- @class neomark.api.rendering.config
---
--- Table to hold rendering api config
---
Rendering.config = {}

--- @class neomark.api.rendering.namespaces
---
--- Table to hold namespace ids
---
Rendering.namespaces = {}

--- @class neomark.api.rendering.element
---
--- Table holding element types and their renderers
---
Rendering.element = {
    --- @enum neomark.api.rendering.element.types
    types = {
        checkbox = 'checkbox',
        link = 'link',
    },
}

--- @class neomark.api.rendering.table
---
--- Table to store markdown table info
---
--- @field start integer Table start line index
--- @field stop integer Table end line index
--- @field max table<integer> Array containing the maximum value legth table columns
--- @field columns table<table<string>> Array of Table line values split into columns

--- @class neomark.api.rendering.state
---
--- Table to store buffer states for rendering API
---
--- @field current_buffer integer Active buffer index
--- @field tables table<neomark.api.rendering.table> Array of md tables present in buffer
--- @field is_table boolean Helper variable for md table lookup
--- @field current_table neomark.api.rendering.table | {} Variable holding table info during table lookup
Rendering.state = {
    current_buffer = 0,
    tables = {},
    is_table = false,
    current_table = {},
}

--- Neomark rendering API submodule initialization function.
---
--- @param config neomark.config Neomark config
---
function Rendering.load(config)
    local disable = {}

    for _, element in ipairs(config.disable) do
        disable[element] = true
    end

    Rendering.config = {}
    for _, element in ipairs(Rendering.supported) do
        if not disable[element] then
            table.insert(Rendering.config, element)
        end
    end

    for _, namespace in ipairs(Rendering.config) do
        Rendering.namespaces[namespace] = vim.api.nvim_create_namespace(namespace)
    end
end

--- (Re)Initialises buffer state on buffer entry
---
function Rendering.init()
    Rendering.state.current_buffer = vim.api.nvim_get_current_buf()
    Rendering.state.tables[Rendering.state.current_buffer] = Rendering.state.tables[Rendering.state.current_buffer] or {}
end

--- Returns current buffer state tables array
--- 
--- @return table<neomark.api.rendering.table> Array tables
---
function Rendering.get_tables()
    return Rendering.state.tables[Rendering.state.current_buffer]
end

--- Adds a table into the current buffer state tables array
--- 
--- @param tab neomark.api.rendering.table Makrdown table info
---
function Rendering.add_table(tab)
    table.insert(Rendering.get_tables(), tab)
end

--- Clears current buffer state tabless array
---
function Rendering.clear_tables()
    Rendering.state.tables[Rendering.state.current_buffer] = {}
end

--- Retrieve namespace id
---
--- @param namespace string Namespace
---
--- @return integer Namespace id
---
function Rendering.get_namespace_id(namespace)
    return Rendering.namespaces[namespace]
end

--- Clear rendering of the active buffer
function Rendering.clear()
    for _, id in pairs(Rendering.namespaces) do
        vim.api.nvim_buf_clear_namespace(0, id, 0, -1)
    end
end

--- Clear rendering of a specific line of the buffer
---
--- @param line integer Line index.
---
function Rendering.clear_line(line)
    for _, id in pairs(Rendering.namespaces) do
        local marks = vim.api.nvim_buf_get_extmarks(0, id, { line, 0 }, { line, -1 }, {})
        if #marks > 0 then
            for _, mark in ipairs(marks) do
                vim.api.nvim_buf_del_extmark(0, id, mark[1])
            end
        end
    end
end

--- Construct interactive element table
---
--- @param line integer Line index
--- @param start integer Element start column
--- @param stop integer Element stop column
--- @param istart integer Element interactive section start column
--- @param type neomark.api.rendering.element.types Interactive element type
---
--- @return neomark.api.element Constructed nteractive element
---
function Rendering.create_interactive_element(line, start, stop, istart, len, type)
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
---
--- Supported element renderers
---
Rendering.element.renderers = {
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

            vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('checkbox'), i - 1, start - 1, {
                virt_text = { { prefix .. '[', 'WarningMsg' }, { mark, hl }, { ']', 'WarningMsg' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop - 5 - preflen,
                priority = 1,
            })

            return {Rendering.create_interactive_element(
                i - 1,
                start,
                stop,
                start + preflen + 2,
                1,
                Rendering.element.types.checkbox
            )}
        end
    end,

    link = function(i, line)
        local search_start = 0
        local links = {}
        for _ in line:gmatch('%[(.[^%]]-)%]%(.-%)') do
            local start, stop, alt = line:find('%[(.[^%]]-)%]%(.-%)', search_start)
            if start and stop then
                search_start = stop
                table.insert(
                    links,
                    Rendering.create_interactive_element(
                        i - 1,
                        start,
                        stop,
                        start,
                        alt:len(),
                        Rendering.element.types.link
                    )
                )
            end
        end

        return links
    end,

    inline = function(i, line)
        local search_start = 0
        for _ in line:gmatch('%*%*.-%*%*') do
            local start, stop, text = line:find('%*%*(.-)%*%*', search_start)
            if start and stop then
                search_start = stop
                vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('inline'), i - 1, start - 1, {
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
                vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('inline'), i - 1, start - 1, {
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
                vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('inline'), i - 1, start - 1, {
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
            vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('h1'), i - 1, start - 1, {
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
            vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('h2'), i - 1, start - 1, {
                virt_text = { { '## ' .. text .. ' ##', 'Title' } },
                virt_text_pos = 'overlay',
                conceal = '␀',
                end_col = stop,
                priority = 1,
            })
        end
    end,

    table = function(i, line)
        Rendering.find_tables(i, line)

        if i >= vim.api.nvim_buf_line_count(0) then
            Rendering.render_tables()
        end
    end
}

--- Recalculates max column lengths during md table lookup
---
--- @param tab neomark.api.rendering.table Table to update max column lens for
--- @param values table<string> Array of collumn values to calculate new lenghts for
---
function Rendering.recalculate_column_lens(tab, values)
    tab.columns = tab.columns or {}
    table.insert(tab.columns, values)

    tab.max = tab.max or {}
    tab.max = tab.max or {}
    for i, col in ipairs(values) do
        local clen = col:len()
        if not tab.max[i] then
            tab.max[i] = clen
        elseif tab.max[i] < clen then
            tab.max[i] = clen
        end
    end
end

--- Markdown table lookup
--- 
--- Called as a renderer during line rendering
---
--- @param i integer Line index
--- @param line string Line contents
---
function Rendering.find_tables(i, line)
    local separators = 0;
    Rendering.state.current_table = Rendering.state.current_table or {}

    for _ in line:gmatch('|') do
        separators = separators + 1
    end

    if separators > 1 then
        if not Rendering.state.is_table then
            Rendering.state.current_table.start = i - 1
        end

        Rendering.state.is_table = true

        local pattern = '|(.-'
        for _ = 2, separators - 1 do
            pattern = pattern .. ')|(.-'
        end
        pattern = pattern .. ')|'

        local columns = { line:find(pattern) }
        table.move(columns, 3, #columns, 1, columns)
        table.remove(columns, #columns)
        table.remove(columns, #columns)

        Rendering.recalculate_column_lens(Rendering.state.current_table, columns)
    else
        Rendering.state.is_table = false
        if Rendering.state.current_table ~= {} and Rendering.state.current_table.start then
            Rendering.state.current_table.stop = i - 2
            Rendering.add_table(Rendering.state.current_table)
        end

        Rendering.state.current_table = {}
    end
end

--- Table holding symbols for table formatting
---
local piping = {
    corners = {
        top_left = '┌',
        top_right = '┐',
        bottom_left = '└',
        bottom_right = '┘',
    },

    edges = {
        top = '─',
        left = '│',
        mid = '│',
        right = '│',
        bottom = '─',
    },

    vertices = {
        top = '┬',
        left = '├',
        mid = '┼',
        right = '┤',
        bottom = '┴',
    },

    padding = {
        empty = ' ',
        edge = '─',
    }
}

--- Renders md table from table info
---
--- @param tab neomark.api.rendering.table
---
function Rendering.render_table(tab)
    local top = piping.corners.top_left
    local bottom = piping.corners.bottom_left
    local line_len = 0
    for _, len in ipairs(tab.max) do
        line_len = line_len + len + 1
    end
    line_len = line_len + #tab.max + 1

    for i = 1, #tab.max do
        for _ = 0, tab.max[i] do
            top = top .. piping.edges.top
            bottom = bottom .. piping.edges.bottom
        end

        if i == #tab.max then
            top = top .. piping.corners.top_right
            bottom = bottom .. piping.corners.bottom_right
        else
            top = top .. piping.vertices.top
            bottom = bottom .. piping.vertices.bottom
        end
    end

    vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('table'), tab.start, 0, {
        virt_lines = { { { top } } },
        virt_lines_above = true,
        virt_text_pos = 'inline',
        end_col = 0,
        end_line = tab.start,
        conceal = '',
        priority = 1,
    })

    for line_idx, columns in ipairs(tab.columns) do
        local start = 1
        local stop = start

        local lpipe = piping.edges.left
        local pipe = piping.edges.mid
        local rpipe = piping.edges.right
        local padding = piping.padding.empty
        if line_idx == 2 then
            lpipe = piping.vertices.left
            pipe = piping.vertices.mid
            rpipe = piping.vertices.right
            padding = piping.padding.edge
        end

        vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('table'), tab.start + line_idx - 1, 0, {
            virt_text = { { lpipe } },
            virt_text_pos = 'inline',
            end_col = 1,
            conceal = '',
            priority = 1,
        })

        local offset = 0
        for idx, value in ipairs(columns) do
            if (line_idx == 2) then
                local extra_padding = ''
                for _ = 1, value:len() do
                    extra_padding = extra_padding .. padding
                end
                vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('table'), tab.start + line_idx - 1, stop + offset, {
                    virt_text = { { extra_padding } },
                    virt_text_pos = 'overlay',
                    end_col = stop + offset,
                    conceal = '',
                    priority = 1,
                })
                offset = 1
            end

            stop = start + value:len()
            local col_text = ''
            for _ = value:len(), tab.max[idx] do
                col_text = col_text .. padding
            end

            local count = math.floor(select(2, value:gsub('`', '')) / 2)

            for _ = 1, count do
                col_text = col_text .. padding .. padding
            end

            vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('table'), tab.start + line_idx - 1, stop, {
                virt_text = { { col_text } },
                virt_text_pos = 'inline',
                end_col = stop,
                conceal = '',
                priority = 1,
            })

            local endpipe = pipe
            if idx == #columns then
                endpipe = rpipe
            end

            vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('table'), tab.start + line_idx - 1, stop, {
                virt_text = { { endpipe } },
                virt_text_pos = 'inline',
                end_col = stop + 1,
                conceal = '',
                priority = 1,
            })

            start = stop + 1
        end
    end

        vim.api.nvim_buf_set_extmark(0, Rendering.get_namespace_id('table'), tab.stop + 1, 0, {
        virt_lines = { { { bottom } } },
        virt_lines_above = true,
        virt_text_pos = 'inline',
        end_col = 0,
        end_line = tab.start,
        conceal = '',
        priority = 1,
    })
end

--- Renders all tables for the current buffer state
---
function Rendering.render_tables()
    for _, tab in ipairs(Rendering.get_tables()) do
        Rendering.render_table(tab)
    end
    Rendering.clear_tables()
end

--- Render a specific line of the active buffer.
---
--- @param line_idx integer Line index
--- @param line string Line contents
---
--- @return table Array of rendered interactive elements
---
function Rendering.render_line(line_idx, line)
    local interactive_elements = {}
    for _, renderer in ipairs(Rendering.config) do
        local ies = Rendering.element.renderers[renderer](line_idx, line)
        if ies and ies ~= {} then
            for _, element in ipairs(ies) do
                table.insert(interactive_elements, element)
            end
        end
    end

    return interactive_elements
end

return Rendering
