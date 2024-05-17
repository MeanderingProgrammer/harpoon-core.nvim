local state = require('harpoon-core.state')

local M = {}

---@class harpoon.core.UserMenuSettings
---@field public width? integer
---@field public height? integer

---@class harpoon.core.UserHighlightGroups
---@field public window string
---@field public border string

---@class harpoon.core.UserConfig
---@field public use_existing? boolean
---@field public default_action? string
---@field public mark_branch? boolean
---@field public use_cursor? boolean
---@field public menu? harpoon.core.UserMenuSettings
---@field public highlight_groups? harpoon.core.UserHighlightGroups

---@param opts? harpoon.core.UserConfig
function M.setup(opts)
    ---@type harpoon.core.Config
    local default_config = {
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
    state.config = vim.tbl_deep_extend('force', default_config, opts or {})
end

return M
