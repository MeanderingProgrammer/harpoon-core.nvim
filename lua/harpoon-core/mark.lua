local harpoon = require('harpoon-core')
local git = require('harpoon-core.git')
local path = require('plenary.path')

-- Typically resolves to ~/.local/share/nvim
local user_projects_file = vim.fn.stdpath('data') .. '/harpoon-core.json'

local M = {}

local function read_json(file)
    return vim.json.decode(path:new(file):read())
end

local function read_projects(projects_file)
    local ok, projects = pcall(read_json, projects_file)
    if not ok then
        projects = {}
    end
    return projects
end

local context = {
    projects = read_projects(user_projects_file),
}

local function root()
    return vim.loop.cwd()
end

local function project()
    local branch = nil
    if harpoon.get_opts().mark_branch then
        branch = git.branch()
    end
    if branch == nil then
        return root()
    else
        return root() .. '-' .. branch
    end
end

local function get_marks()
    if context.projects[project()] == nil then
        -- No need to save the initial empty value, so no file write
        context.projects[project()] = { marks = {} }
    end
    return context.projects[project()].marks
end

function M.length()
    return #get_marks()
end

function M.get_filenames()
    local filenames = {}
    for _, mark in pairs(get_marks()) do
        table.insert(filenames, mark.filename)
    end
    return filenames
end

function M.absolute(filename)
    return path:new(root()):joinpath(filename).filename
end

local function relative_filename(filename)
    if filename == nil then
        filename = vim.api.nvim_buf_get_name(0)
    end
    if vim.fn.filereadable(filename) == 1 then
        return path:new(filename):make_relative(root())
    else
        return nil
    end
end

local function filename_index(target_filename)
    for i, filename in pairs(M.get_filenames()) do
        if filename == target_filename then
            return i
        end
    end
    return nil
end

local function save()
    local current_projects = read_projects(user_projects_file)
    current_projects[project()] = { marks = get_marks() }
    local projects_json = vim.fn.json_encode(current_projects)
    path:new(user_projects_file):write(projects_json, 'w')
end

function M.clear()
    context.projects[project()] = { marks = {} }
    save()
end

function M.add_file(filename)
    filename = relative_filename(filename)
    local index = filename_index(filename)
    if filename ~= nil and index == nil then
        local marks = get_marks()
        table.insert(marks, { filename = filename })
        save()
    end
end

function M.rm_file(filename)
    filename = relative_filename(filename)
    local index = filename_index(filename)
    if filename ~= nil and index ~= nil then
        local marks = get_marks()
        table.remove(marks, index)
        save()
    end
end

function M.current_index()
    local filename = relative_filename(nil)
    return filename_index(filename)
end

function M.get_filename(index)
    local filenames = M.get_filenames()
    if #filenames > 0 and index <= #filenames then
        return filenames[index]
    else
        return nil
    end
end

return M
