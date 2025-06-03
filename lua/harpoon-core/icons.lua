---@class harpoon.core.Icons
local M = {}

---@param path string
---@return string?, string?
function M.get(path)
    local has_mini, mini = pcall(require, 'mini.icons')
    if has_mini and _G.MiniIcons then
        return mini.get('file', path)
    end
    local has_dev, dev = pcall(require, 'nvim-web-devicons')
    if has_dev then
        return dev.get_icon(path)
    end
    return nil, nil
end

return M
