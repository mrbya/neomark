return {
    check = function()
        vim.health.start('neomark')
        local treesitter = pcall(require, 'nvim-treesitter')
        if treesitter then
            vim.health.ok('Treesitter installed.')
            local parser = pcall(vim.treesitter.language.get_lang, 'markdown')
            if parser then
                vim.health.ok('Treesitter markdown parser installed.')
            else
                vim.health.warn('Treesitter: markdown parser required for concealment and some syntax highlighting features')
            end
        else
            vim.health.warn('Treesitter required for concealment and some syntax highlighting features')
        end

        local neomark = require('neomark')
        if neomark and neomark.config.snippets then
            local luasnip = pcall(require, 'luasnip')
            if luasnip then
                vim.health.ok('LuaSnip installed.')
            else
                vim.health.warn('LuaSnip required for pick and place snippets!')
            end

            local telescope = pcall(require, 'telescope.builtin')
            if telescope then
                vim.health.ok('Telescope installed.')
            else
                vim.health.warn('Telescope required for pick and place snippets!')
            end
        else
            vim.health.warn('Pick and place snippets disabled.')
        end
    end
}
