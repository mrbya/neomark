local M = {}

M.links_ns_id = vim.api.nvim_create_namespace("markdown_links")
M.check_ns_id = vim.api.nvim_create_namespace("markdown_checkboxes")

-- Clear rendered links
function M.clear_links_rendering()
  vim.api.nvim_buf_clear_namespace(0, M.links_ns_id, 0, -1)
end

function M.clear_checkboxes_rendering()
   vim.api.nvim_buf_clear_namespace(0, M.check_ns_id, 0, -1)
end

-- Render links in the buffer
function M.render_links()
    vim.api.nvim_buf_set_option(0, 'conceallevel', 0)
    M.clear_links_rendering()

    for i = 1, vim.api.nvim_buf_line_count(0) do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if line then
            local start, stop, text, link = line:find("%[(.+)%]%((.+)%)")
            if start and stop then
                vim.api.nvim_buf_set_option(0, 'conceallevel', 2)
                vim.api.nvim_buf_set_extmark(0, M.links_ns_id, i - 1, start - 1, {
                    virt_text = { { text } },
                    virt_text_pos = "overlay",
                    conceal = "␀",
                    end_col = stop - 1,
                })
            end
        end
    end
end

function M.render_checkboxes()
    vim.api.nvim_buf_set_option(0, 'conceallevel', 0)
    M.clear_checkboxes_rendering()

    for i = 1, vim.api.nvim_buf_line_count(0) do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if line then
            local start, stop, status = line:find("-%s%[(.)%]")
            if start and stop then

                local mark = ' '
                print(start..', '..stop..', '..status)
                if status == 'x' then
                    mark = ''
                elseif status == '/' then
                    mark = ''
                elseif status == 'f' then
                    mark = ''
                end

                vim.api.nvim_buf_set_option(0, 'conceallevel', 2)
                vim.api.nvim_buf_set_extmark(0, M.check_ns_id, i - 1, start - 1, {
                    virt_text = { { ' [' }, { mark }, { ']' } },
                    virt_text_pos = "overlay",
                    conceal = "␀",
                    end_col = stop - 1,
                })
            end
        end
    end
end

function M.load()
    vim.api.nvim_clear_autocmds({pattern = "*.md"})
    -- Run rendering on Markdown filetype
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
        pattern = "*.md",
        callback = function()
            if vim.fn.mode() == "n" or vim.fn.mode() == "v" then
                M.render_checkboxes()
            end
            M.clear_links_rendering()
            M.clear_checkboxes_rendering()
        end,
    })

    -- Disable link rendering on mode change
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        pattern = "*.md",
        callback = function()
            vim.api.nvim_buf_set_option(0, 'conceallevel', 0)
            M.clear_links_rendering()
            M.clear_checkboxes_rendering()
        end,
    })
end

return M

