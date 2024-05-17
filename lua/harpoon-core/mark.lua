local git = require('harpoon-core.git')
local path = require('plenary.path')
local state = require('harpoon-core.state')

-- Typically resolves to ~/.local/share/nvim/harpoon-core.json
local user_projects_file = vim.fn.stdpath('data') .. '/harpoon-core.json'

--[[
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

---@param file string
---@return table
local function read_json(file)
    ---@diagnostic disable-next-line: return-type-mismatch
    return vim.json.decode(path:new(file):read())
end

---@param projects_file string
---@return table
local function read_projects(projects_file)
    local ok, projects = pcall(read_json, projects_file)
    if ok then
        return projects
    else
        return {}
    end
end

---@class harpoon.core.Mark
---@field filename string
---@field cursor { [1]: integer, [2]: integer }
---@field index integer?

---@class harpoon.core.Context
---@field projects table<string, { marks: harpoon.core.Mark[] }>
local context = {
    projects = read_projects(user_projects_file),
}

---@return string
local function root()
    return vim.fn.getcwd()
end

---@return string
local function project()
    local branch = nil
    if state.config.mark_branch then
        branch = git.branch()
    end
    if branch == nil then
        return root()
    else
        return root() .. '-' .. branch
    end
end

local M = {}

---@return harpoon.core.Mark[]
function M.get_marks()
    local project_name = project()
    if context.projects[project_name] == nil then
        -- No need to save the initial empty value, so no file write
        context.projects[project_name] = { marks = {} }
    end
    return context.projects[project_name].marks
end

---@return integer
function M.length()
    return #M.get_marks()
end

---@return integer?
---@return harpoon.core.Mark?
function M.get_by_filename(filename)
    for i, mark in ipairs(M.get_marks()) do
        if mark.filename == filename then
            return i, mark
        end
    end
    return nil, nil
end

---@return harpoon.core.Mark?
function M.get_by_index(index)
    local marks = M.get_marks()
    if #marks > 0 and index <= #marks then
        return marks[index]
    else
        return nil
    end
end

---@param filename string?
---@return string?
function M.relative(filename)
    if filename == nil then
        filename = vim.api.nvim_buf_get_name(0)
    end
    if vim.fn.filereadable(filename) == 1 then
        return path:new(filename):make_relative(root())
    else
        return nil
    end
end

function M.save()
    local current_projects = read_projects(user_projects_file)
    local new_marks = { marks = M.get_marks() }
    if not vim.deep_equal(current_projects[project()], new_marks) then
        current_projects[project()] = new_marks
        local projects_json = vim.fn.json_encode(current_projects)
        path:new(user_projects_file):write(projects_json, 'w')
    end
end

---@param filenames string[]
function M.set_project(filenames)
    local new_marks = {}
    for _, filename in ipairs(filenames) do
        local relative_filename = M.relative(filename)
        if relative_filename ~= nil then
            local _, mark = M.get_by_filename(relative_filename)
            if mark ~= nil then
                table.insert(new_marks, mark)
            else
                table.insert(new_marks, { filename = relative_filename })
            end
        end
    end
    context.projects[project()] = { marks = new_marks }
    M.save()
end

---@param filename string?
function M.add_file(filename)
    filename = M.relative(filename)
    local index, _ = M.get_by_filename(filename)
    if filename ~= nil and index == nil then
        table.insert(M.get_marks(), {
            filename = filename,
            cursor = vim.api.nvim_win_get_cursor(0),
        })
        M.save()
    end
end

---@param filename string?
function M.rm_file(filename)
    filename = M.relative(filename)
    local index = M.get_by_filename(filename)
    if filename ~= nil and index ~= nil then
        table.remove(M.get_marks(), index)
        M.save()
    end
end

---@return integer?
function M.current()
    local filename = M.relative(nil)
    return M.get_by_filename(filename)
end

function M.update_cursor()
    local filename = M.relative(nil)
    local _, mark = M.get_by_filename(filename)
    if mark ~= nil then
        mark.cursor = vim.api.nvim_win_get_cursor(0)
        M.save()
    end
end

return M
