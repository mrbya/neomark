--- @module "neomark.api.formatting"
---
--- Neomark API submodule providing text formatting
---
local F = {}

--- @class neomark.api.formatting.format
---
--- Formatting API class providing format info
---
--- @field prefix string Format prefix
--- @field suffix string Format suffix
---

--- @type table<string, neomark.api.formatting.format>
---
--- Supported formats
---
F.formats = {
    bold = {
        prefix = '**',
        suffix = '**',
    },

    italic = {
        prefix = '*',
        suffix = '*',
    },

    strikethrough = {
        prefix = '~',
        suffix = '~',
    }
}

--- Formats selection
--- 
--- @param format neomark.api.formatting.format Format info for selection formatting
---
function F.format(format)
    local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'x', false)

    local start = vim.fn.getpos("'<")
    local stop = vim.fn.getpos("'>")

    local start_line = start[2] - 1
    local start_col = start[3] - 1

    local end_line = stop[2] - 1
    local end_col = stop[3] - 1

    if start_line == end_line then
        if start_col ~= end_col then
            vim.api.nvim_buf_set_text(0, start_line, start_col, start_line, start_col, { format.prefix })
            vim.api.nvim_buf_set_text(0, end_line, end_col + 2, end_line, end_col + 2, { format.suffix })
        end
    else
        vim.notify('Multilinr formatting not supported!', vim.log.levels.ERROR)
    end
end

return F
