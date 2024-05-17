---@class harpoon.core.MenuSettings
---@field public width integer
---@field public height integer

---@class harpoon.core.HighlightGroups
---@field public window string
---@field public border string

---@class harpoon.core.Config
---@field public use_existing boolean
---@field public default_action? string
---@field public mark_branch boolean
---@field public use_cursor boolean
---@field public menu harpoon.core.MenuSettings
---@field public highlight_groups harpoon.core.HighlightGroups

---@class harpoon.core.State
---@field config harpoon.core.Config
local state = {}
return state
