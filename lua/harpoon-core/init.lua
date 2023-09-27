local M = {}
local context = {}

M.setup = function(opts)
    opts = opts or {}
    local default_opts = {
        highlight_groups = {
            window = 'HarpoonWindow',
            border = 'HarpoonBorder',
        },
    }
    context.opts = vim.tbl_deep_extend('force', default_opts, opts)
end

M.get_opts = function()
    return context.opts
end

return M
