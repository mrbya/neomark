--- @module "neomark.api.formatting"
---
--- Neomark API submodule providing text formatting
---
local Formatting = {}

--- @class neomark.api.formatting.format
---
--- Formatting API class providing format info
---
--- @field prefix string Format prefix
--- @field prefix_pattern string Format prefix regex pattern
--- @field suffix string Format suffix
--- @field suffix_pattern string Format suffix regex pattern
---

--- @type table<string, neomark.api.formatting.format>
---
--- Supported formats
---
Formatting.formats = {
    bold = {
        prefix = '**',
        prefix_pattern = '%*%*',
        suffix = '**',
        suffix_pattern = '%*%*',
    },

    italic = {
        prefix = '*',
        prefix_pattern = '%*',
        suffix = '*',
        suffix_pattern = '%*',
    },

    strikethrough = {
        prefix = '~',
        prefix_pattern = '~',
        suffix = '~',
        suffix_pattern = '~',
    }
}

--- Clears section formatting
---
--- @param format neomark.api.formatting.format Format info
---
function Formatting.clear_format(format)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_idx = cursor[1] - 1
    local col = cursor[2] - 1

    local line = vim.api.nvim_buf_get_lines(0, line_idx, line_idx + 1, false)[1]
    if line then
        local pre = line:sub(1, col)
        local post = line:sub(col)
        local start_pre, stop_pre, prefix = pre:find('(' .. format.prefix_pattern .. ')')
        local start_post, stop_post, suffix = post:find('(' .. format.suffix_pattern .. ')')

        if start_pre and stop_pre and prefix and start_post and stop_post and suffix then
            vim.api.nvim_buf_set_text(
                0,
                line_idx,
                start_pre - 1,
                line_idx,
                start_pre + prefix:len() - 1,
                { '' }
            )
            vim.api.nvim_buf_set_text(
                0,
                line_idx,
                col + start_post - prefix:len() - 2,
                line_idx, col + start_post + suffix:len() - prefix:len() - 2,
                { '' }
            )
            return true
        end
    end

    return false
end

--- Formats selection
--- 
--- @param format neomark.api.formatting.format Format info
---
function Formatting.format(format)
    local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'x', false)

    if Formatting.clear_format(format) then
        return
    end

    local start = vim.fn.getpos("'<")
    local stop = vim.fn.getpos("'>")

    local start_line = start[2] - 1
    local start_col = start[3] - 1
    local end_line = stop[2] - 1
    local end_col = stop[3] - 1

    if start_line == end_line then
        if start_col ~= end_col then
            vim.api.nvim_buf_set_text(
                0,
                start_line,
                start_col,
                start_line,
                start_col,
                { format.prefix }
            )
            vim.api.nvim_buf_set_text(
                0,
                end_line,
                end_col + format.suffix:len() + 1,
                end_line,
                end_col + format.suffix:len() + 1,
                { format.suffix }
            )
        end
    else
        vim.notify('Multiline formatting not supported!', vim.log.levels.ERROR)
    end
end

return Formatting
