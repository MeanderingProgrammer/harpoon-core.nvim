---@class harpoon.core.Store
---@field private path string
local Store = {}
Store.__index = Store

---@param path string
---@return harpoon.core.Store
function Store.new(path)
    local self = setmetatable({}, Store)
    self.path = path
    return self
end

---@return harpoon.core.Projects
function Store:read()
    local ok, result = pcall(function()
        local file = assert(io.open(self.path, 'r'))
        local text = file:read('*all')
        file:close()
        return vim.json.decode(text)
    end)
    return ok and result or {}
end

---@param data harpoon.core.Projects
function Store:write(data)
    local file = assert(io.open(self.path, 'w'))
    file:write(vim.fn.json_encode(data))
    file:close()
end

return Store
