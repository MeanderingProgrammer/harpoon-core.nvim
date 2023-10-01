local harpoon = require('harpoon-core')
local git = require('harpoon-core.git')
local path = require('plenary.path')

--[[
Path typically resolves to ~/.local/share/nvim/harpoon-core.json
Projects are stored in the following format:
{
    "<absolute_path_to_project_root><-brance_name>": {
        "marks": [
            {
                "filename": "<marked_file_relative_path_from_project_root>",
                "cursor": [ <row>, <column> ],
            },
            ...
        ]
    },
    ...
}
--]]
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

function M.get_marks()
    if context.projects[project()] == nil then
        -- No need to save the initial empty value, so no file write
        context.projects[project()] = { marks = {} }
    end
    return context.projects[project()].marks
end

function M.length()
    return #M.get_marks()
end

function M.get_by_filename(filename)
    for i, mark in pairs(M.get_marks()) do
        if mark.filename == filename then
            return i, mark
        end
    end
    return nil, nil
end

function M.get_by_index(index)
    local marks = M.get_marks()
    if #marks > 0 and index <= #marks then
        return marks[index]
    else
        return nil
    end
end

local function relative(filename)
    if filename == nil then
        filename = vim.api.nvim_buf_get_name(0)
    end
    if vim.fn.filereadable(filename) == 1 then
        return path:new(filename):make_relative(root())
    else
        return nil
    end
end

local function save()
    local current_projects = read_projects(user_projects_file)
    local new_marks = { marks = M.get_marks() }
    ---@diagnostic disable-next-line: need-check-nil
    if not vim.deep_equal(current_projects[project()], new_marks) then
        current_projects[project()] = new_marks
        local projects_json = vim.fn.json_encode(current_projects)
        path:new(user_projects_file):write(projects_json, 'w')
    end
end

function M.set_project(filenames)
    local new_marks = {}
    for _, filename in pairs(filenames) do
        filename = relative(filename)
        if filename ~= nil then
            local _, mark = M.get_by_filename(filename)
            if mark ~= nil then
                table.insert(new_marks, mark)
            else
                table.insert(new_marks, { filename = filename })
            end
        end
    end
    context.projects[project()] = { marks = new_marks }
    save()
end

function M.add_file()
    local filename = relative(nil)
    local index, _ = M.get_by_filename(filename)
    if filename ~= nil and index == nil then
        table.insert(M.get_marks(), {
            filename = filename,
            cursor = vim.api.nvim_win_get_cursor(0),
        })
        save()
    end
end

function M.rm_file()
    local filename = relative(nil)
    local index = M.get_by_filename(filename)
    if filename ~= nil and index ~= nil then
        table.remove(M.get_marks(), index)
        save()
    end
end

function M.current()
    local filename = relative(nil)
    return M.get_by_filename(filename)
end

return M
