local path = require('plenary.path')

-- Typically resolves to ~/.local/share/nvim
local user_projects_file = vim.fn.stdpath('data') .. '/harpoon-core.json'

local M = {}
local context = {}

local function read(file)
    vim.json.decode(path:new(file):read())
end

M.setup = function()
    local ok, projects = pcall(read, user_projects_file)
    if not ok then
        projects = {}
    end
    context.projects = projects
end

local function project_key()
    return vim.loop.cwd()
end

local function relative(buf_name)
    return path:new(buf_name):make_relative(project_key())
end

local function contains(marks, file_name)
    for i = 1, #marks do
        if marks[i].file_name == file_name then
            return true
        end
    end
    return false
end

local function save()
    local projects = vim.fn.json_encode(context.projects)
    path:new(user_projects_file):write(projects, 'w')
end

M.add_file = function()
    if context.projects[project_key()] == nil then
        context.projects[project_key()] = { marks = {} }
    end
    local marks = context.projects[project_key()].marks
    local file_name = relative(vim.api.nvim_buf_get_name(0))
    if not contains(marks, file_name) then
        table.insert(marks, { file_name = file_name })
        save()
    end
end

return M
