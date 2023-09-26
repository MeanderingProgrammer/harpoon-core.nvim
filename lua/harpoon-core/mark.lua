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

local function project()
    return vim.loop.cwd()
end

local function get_or_set_marks()
    if context.projects[project()] == nil then
        context.projects[project()] = { marks = {} }
    end
    return context.projects[project()].marks
end

M.get_files = function()
    local marks = get_or_set_marks()
    local files = {}
    for i = 1, #marks do
        table.insert(files, marks[i].file_name)
    end
    return files
end

M.absolute = function(file_name)
    return path:new(project()):joinpath(file_name).filename
end

local function relative_file_name(file_name)
    if file_name == nil then
        file_name = vim.api.nvim_buf_get_name(0)
    end
    if vim.fn.filereadable(file_name) == 1 then
        return path:new(file_name):make_relative(project())
    else
        return nil
    end
end

local function file_index(marks, file_name)
    for i = 1, #marks do
        if marks[i].file_name == file_name then
            return i
        end
    end
    return nil
end

local function save()
    local projects = vim.fn.json_encode(context.projects)
    path:new(user_projects_file):write(projects, 'w')
end

M.clear = function()
    context.projects[project()] = { marks = {} }
    save()
end

M.add_file = function(file_name)
    file_name = relative_file_name(file_name)
    local marks = get_or_set_marks()
    local index = file_index(marks, file_name)
    if file_name ~= nil and index == nil then
        table.insert(marks, { file_name = file_name })
        save()
    end
end

M.rm_file = function(file_name)
    file_name = relative_file_name(file_name)
    local marks = get_or_set_marks()
    local index = file_index(marks, file_name)
    if file_name ~= nil and index ~= nil then
        table.remove(marks, index)
        save()
    end
end

M.get_file_name = function(index)
    local marks = get_or_set_marks()
    if #marks > 0 and index <= #marks then
        return M.absolute(marks[index].file_name)
    else
        return nil
    end
end

return M
