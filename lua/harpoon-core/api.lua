local marker = require('harpoon-core.mark')
local ui = require('harpoon-core.ui')

---@class harpoon.core.Api
local M = {}

M.add_file = marker.add_file
M.rm_file = marker.rm_file
M.toggle_quick_menu = ui.toggle_quick_menu
M.nav_file = ui.nav_file
M.nav_next = ui.nav_next
M.nav_prev = ui.nav_prev

return M
