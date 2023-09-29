local M = {}
local context = {}

function M.setup(opts)
    opts = opts or {}
    local default_opts = {
        -- Make existing window active rather than creating a new window
        use_existing = true,
        -- Set marks specific to each git branch inside git repository
        mark_branch = false,
        -- Highlight groups to use for various components
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
