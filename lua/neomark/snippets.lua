--- @module "neomark.snippets"
---
--- Neomark snippets module
---
local Snippets = {}

--- Tables tohold plugin dependencies
local luasnip = {}
local telescope = {}

--- Pcalls to chekc dependency availability
local ls_available, _ = pcall(require, 'luasnip')
local tel_available, _ = pcall(require, 'telescope.builtin')
Snippets.available = ls_available and tel_available

--- Load dependencies
if Snippets.available then
    luasnip = require('luasnip')
    luasnip.events = require('luasnip.util.events')

    telescope = {
        builtin = require('telescope.builtin'),
        actions = require('telescope.actions'),
        state   = require('telescope.actions.state')
    }
end

--- Pick and place file callback for snippets
---
--- @param node table Snippet node tha callback is hanged on
---
function Snippets.picknplace(node)
    if node:get_text()[1] ~= 'url' then
        return
    end
    telescope.builtin.find_files({
        prompt_title = 'Select a file to link',
        cwd = vim.fn.getcwd(),
        attach_mappings = function(prompt_bufnr, map)
            local function on_select()
                local entry = telescope.state.get_selected_entry()

                if not entry then
                telescope.actions.close(prompt_bufnr)
                  return
                end

                telescope.actions.close(prompt_bufnr)

                local path = entry.filename
                node:set_text({path})

                local cursor = vim.api.nvim_win_get_cursor(0)
                local line_idx = cursor[1]
                local col = cursor[2]

                vim.api.nvim_win_set_cursor(0, { line_idx, col + path:len() + 1 })
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), "n", true)
            end

            map('i', '<CR>', on_select)
            map('n', '<CR>', on_select)

            return true
        end,
    })
end

--- Load neomark snippets
---
--- @param config neomark.config Neomark config
---
function Snippets.load(config)
    if Snippets.available and config.snippets then
        luasnip.add_snippets("markdown", {
            luasnip.snippet("neolink", {
                luasnip.text_node("["),
                luasnip.insert_node(1, 'text'),
                luasnip.text_node("]("),
                luasnip.insert_node(2, 'url', {
                    node_callbacks = {
                        [luasnip.events.leave] = function(node)
                            Snippets.picknplace(node)
                        end
                    }
                }),
                luasnip.text_node(") ")
            })
        })

        luasnip.add_snippets("markdown", {
            luasnip.snippet("neoimg", {
                luasnip.text_node("!["),
                luasnip.insert_node(1, 'text'),
                luasnip.text_node("]("),
                luasnip.insert_node(2, 'url', {
                    node_callbacks = {
                        [luasnip.events.leave] = function(node)
                            Snippets.picknplace(node)
                        end
                    }
                }),
                luasnip.text_node(") ")
            })
        })
    end
end

return Snippets
