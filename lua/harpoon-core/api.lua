local Marks = require('harpoon-core.mark')
local Ui = require('harpoon-core.ui')

---@class harpoon.core.Api
local M = {}

M.add_file = Marks.add_file
M.rm_file = Marks.rm_file
M.toggle_quick_menu = Ui.toggle_quick_menu
M.nav_file = Ui.nav_file
M.nav_next = Ui.nav_next
M.nav_prev = Ui.nav_prev

return M
