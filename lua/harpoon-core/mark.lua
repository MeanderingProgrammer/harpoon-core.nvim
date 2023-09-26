local path = require('plenary.path')

-- Typically resolves to ~/.local/share/nvim
local user_projects_file = vim.fn.stdpath('data') .. '/harpoon-core.json'

local M = {}
local context = {}

local function read(file)
    return vim.json.decode(path:new(file):read())
end

M.setup = function()
    local ok, projects = pcall(read, user_projects_file)
    if not ok then
        projects = {}
    end
    context.projects = projects
end

M.project = function()
    return vim.loop.cwd()
end

local function get_or_set_marks()
    if context.projects[M.project()] == nil then
        context.projects[M.project()] = { marks = {} }
    end
    return context.projects[M.project()].marks
end

M.get_files = function()
    local marks = get_or_set_marks()
    local files = {}
    for i = 1, #marks do
        table.insert(files, marks[i].file_name)
    end
    return files
end

local function get_current_file()
    local file_name = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(file_name) == 1 then
        return path:new(file_name):make_relative(M.project())
    else
        return nil
    end
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
    local marks = get_or_set_marks()
    local file_name = get_current_file()
    if file_name ~= nil and not contains(marks, file_name) then
        table.insert(marks, { file_name = file_name })
        save()
    end
end

M.rm_file = function()
    -- TODO
end

M.get_file_name = function(index)
    local marks = get_or_set_marks()
    if #marks > 0 and index <= #marks then
        return M.project() .. '/' .. marks[index].file_name
    else
        return nil
    end
end

return M
