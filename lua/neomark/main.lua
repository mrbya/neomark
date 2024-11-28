local M = {}

M.ns_id = vim.api.nvim_create_namespace("markdown_render")

-- Render links in the buffer
function M.render_links()
    vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)

    for i = 1, vim.api.nvim_buf_line_count(0) do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if line then
            local start, stop, text, link = line:find("%[(.-)%]%((.-)%)")
            if start and stop then
                vim.api.nvim_buf_set_option(0, 'conceallevel', 2)
                vim.api.nvim_buf_set_extmark(0, M.ns_id, i - 1, start - 1, {
                    virt_text = { {' '}, { text }, {' '} },
                    virt_text_pos = "overlay",
                    conceal = "␀",
                    end_col = stop - 1,
                })
            end
        end
    end
end

-- Clear rendered links
function M.clear_rendering()
  vim.api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
end

-- Load the plugin
function M.load()
  -- Run rendering on Markdown filetype
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
    pattern = "*.md",
    callback = function()
        vim.api.nvim_buf_set_option(0, 'conceallevel', 2)
        if vim.fn.mode() == "n" or vim.fn.mode() == "v" then
            M.render_links()
        end
    end,
  })

  -- Toggle rendering on mode change
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        pattern = "*.md",
        callback = function()
            vim.api.nvim_buf_set_option(0, 'conceallevel', 0)
            M.clear_rendering()
        end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        pattern = "*.md",
        callback = function()
            M.clear_rendering()
        end,
    })
end

return M

