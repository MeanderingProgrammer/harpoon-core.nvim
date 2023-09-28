local M = {}
local context = {}

function M.setup(opts)
    opts = opts or {}
    local default_opts = {
        highlight_groups = {
            window = 'HarpoonWindow',
            border = 'HarpoonBorder',
        },
    }
    context.opts = vim.tbl_deep_extend('force', default_opts, opts)
end

function M.get_opts()
    return context.opts
end

return M
