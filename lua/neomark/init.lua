local neomark = require('neomark.api')
local config  = neomark.config

function neomark.setup(opts)
    config = vim.tbl_deep_extend('force', config, opts or {})

    neomark.api.load(config)
    neomark.autocommands.load(config)
    neomark.keymaps.load(config)
end

return neomark
