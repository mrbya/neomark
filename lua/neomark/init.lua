--- Global plugin state init
_G.neomark = {
    state = {},
}

--- @module "neomark"
---
--- Entry point of the plugin
---
local neomark = {
    autocommands = require('neomark.autocommands'),
    api          = require('neomark.api'),
    config       = require('neomark.config'),
    commands     = require('neomark.commands'),
    keymaps      = require('neomark.keymaps'),
    snippets     = require('neomark.snippets'),
}

--- Parse user config and load Neomark API
---
--- @param opts neomark.config Neomark config
---
function neomark.setup(opts)
    neomark.config = vim.tbl_deep_extend('force', neomark.config, opts or {})

    neomark.api.load(neomark.config)
    neomark.autocommands.load(neomark.config)
    neomark.commands.load(neomark.config)
    neomark.keymaps.load(neomark.config)
    neomark.snippets.load(neomark.config)
end

return neomark
