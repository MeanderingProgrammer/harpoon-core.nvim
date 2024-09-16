---@class harpoon.core.File
local M = {}

---@param file_path string
---@return string
function M.read(file_path)
    local file = assert(io.open(file_path, 'r'))
    local content = file:read('*all')
    file:close()
    return content
end

---@param file_path string
---@param content string
function M.write(file_path, content)
    local file = assert(io.open(file_path, 'w'))
    file:write(content)
    file:close()
end

return M
