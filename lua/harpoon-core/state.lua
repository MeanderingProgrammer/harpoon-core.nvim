---@class MenuSettings
---@field public width integer
---@field public height integer

---@class HighlightGroups
---@field public window string
---@field public border string

---@class Config
---@field public use_existing boolean
---@field public default_action? string
---@field public mark_branch boolean
---@field public use_cursor boolean
---@field public menu MenuSettings
---@field public highlight_groups HighlightGroups

---@class State
---@field config Config
local state = {}
return state
