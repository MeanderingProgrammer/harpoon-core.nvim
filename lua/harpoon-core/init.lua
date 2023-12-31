local M = {}
local context = {}

function M.setup(opts)
    opts = opts or {}
    local default_opts = {
        -- Make existing window active rather than creating a new window
        use_existing = true,
        -- Default action when opening a mark, defaults to current window
        -- Example: 'vs' will open in new vertical split, 'tabnew' will open in new tab
        default_action = nil,
        -- Set marks specific to each git branch inside git repository
        mark_branch = false,
        -- Use the previous cursor position of marked files when opened
        use_cursor = true,
        -- Settings for popup window
        menu = {
            width = 60,
            height = 10,
        },
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
