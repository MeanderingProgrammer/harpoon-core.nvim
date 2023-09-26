local mark = require('harpoon-core.mark')

local M = {}

local function get_or_create_buffer(file_name)
    if vim.fn.bufexists(file_name) ~= 0 then
        return vim.fn.bufnr(file_name)
    else
        return vim.fn.bufadd(file_name)
    end
end

M.nav_file = function(index)
    local file_name = mark.get_file_name(index)
    if file_name == nil then
        return
    end
    local bufnr = get_or_create_buffer(file_name)
    vim.api.nvim_set_current_buf(bufnr)
end

M.toggle_quick_menu = function()
    -- TODO
end

return M
