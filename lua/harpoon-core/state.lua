---@class harpoon.core.MenuSettings
---@field public width integer
---@field public height integer

---@class harpoon.core.Config
---@field public use_existing boolean
---@field public default_action? string
---@field public mark_branch boolean
---@field public use_cursor boolean
---@field public menu harpoon.core.MenuSettings
---@field public delete_confirmation boolean

---@class harpoon.core.State
---@field config harpoon.core.Config
local M = {}

---@param default_config harpoon.core.Config
---@param user_config harpoon.core.UserConfig
function M.setup(default_config, user_config)
    M.config = vim.tbl_deep_extend('force', default_config, user_config)
end

return M
