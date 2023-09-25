local path = require('plenary.path')

-- Typically resolves to ~/.local/share/nvim
local user_marks_file = vim.fn.stdpath('data') .. '/harpoon-core.json'

local M = {}
local context = {}

local function read(file)
    vim.json.decode(path:new(file):read())
end

M.setup = function()
    local ok, user_marks = pcall(read, user_marks_file)
    if not ok then
        user_marks = {}
    end
    context.user_marks = user_marks
end

return M
