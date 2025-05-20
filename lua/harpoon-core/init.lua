---@class harpoon.core.Init: harpoon.core.Api
local M = {}

---@class harpoon.core.UserConfig
---@field mark_branch? boolean
---@field use_existing? boolean
---@field default_action? string
---@field use_cursor? boolean
---@field menu? harpoon.core.menu.UserConfig
---@field delete_confirmation? boolean
---@field picker? harpoon.core.picker.UserConfig

---@class harpoon.core.menu.UserConfig
---@field width? integer
---@field height? integer

---@class harpoon.core.picker.UserConfig
---@field delete? string
---@field move_down? string
---@field move_up? string

---@private
---@type harpoon.core.Config
M.default = {
    mark_branch = false,
    -- Use the previous cursor position of marked files when opened
    -- Make existing window active rather than creating a new window
    use_existing = true,
    -- Default action when opening a mark, defaults to current window
    -- Example: 'vs' will open in new vertical split, 'tabnew' will open in new tab
    default_action = nil,
    -- Set marks specific to each git branch inside git repository
    use_cursor = true,
    -- Settings for popup window
    menu = { width = 60, height = 10 },
    -- Controls confirmation when deleting mark in telescope
    delete_confirmation = true,
    -- Controls keymaps for various telescope actions
    picker = {
        delete = '<c-d>',
        move_down = '<c-n>',
        move_up = '<c-p>',
    },
}

---@param opts? harpoon.core.UserConfig
function M.setup(opts)
    local config = vim.tbl_deep_extend('force', M.default, opts or {})
    require('harpoon-core.mark').setup({
        branch = config.mark_branch,
    })
    require('harpoon-core.ui').setup({
        use_existing = config.use_existing,
        default_action = config.default_action,
        use_cursor = config.use_cursor,
        menu = config.menu,
    })
    require('harpoon-core.picker.telescope').setup({
        confirm = config.delete_confirmation,
        picker = config.picker,
    })
end

return setmetatable(M, {
    __index = function(_, key)
        -- Allows API methods to be accessed from top level
        return require('harpoon-core.api')[key]
    end,
})
