--- @module "neomark"
---
--- Entry point of the plugin
---
local neomark = require('neomark.api')
local config  = neomark.config

--- Parse user config and load Neomark API
---
--- @param opts neomark.api.config User config
---
function neomark.setup(opts)
    config = vim.tbl_deep_extend('force', config, opts or {})

    neomark.api.load(config)
    neomark.autocommands.load(config)
    neomark.keymaps.load(config)
end

return neomark
