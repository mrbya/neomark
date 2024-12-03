local neomark = {}
neomark.api = require("neomark.main")

function neomark.setup(opts)
    neomark.api.load()
end

return neomark
