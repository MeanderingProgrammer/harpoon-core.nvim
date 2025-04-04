local file = require('harpoon-core.file')

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

---@class harpoon.core.Mark
---@field filename string
---@field cursor { [1]: integer, [2]: integer }
---@field index? integer

---@class harpoon.core.Marker
---@field private mark_branch boolean
---@field private file_path string
---@field private projects table<string, { marks: harpoon.core.Mark[] }>
local M = {}

---@param config harpoon.core.Config
function M.setup(config)
    M.mark_branch = config.mark_branch
    -- Typically resolves to ~/.local/share/nvim/harpoon-core.json
    M.file_path = vim.fn.stdpath('data') .. '/harpoon-core.json'
    M.projects = M.read_projects()
end

---@private
---@return table<string, { marks: harpoon.core.Mark[] }>
function M.read_projects()
    local ok, projects = pcall(function()
        local content = file.read(M.file_path)
        return vim.json.decode(content)
    end)
    return ok and projects or {}
end

---@return harpoon.core.Mark[]
function M.get_marks()
    local project = M.project()
    if M.projects[project] == nil then
        -- No need to save the initial empty value, so no file write
        M.projects[project] = { marks = {} }
    end
    return M.projects[project].marks
end

---@private
---@return string
function M.root()
    return vim.fn.getcwd()
end

---@private
---@return string
function M.project()
    local branch = nil
    if M.mark_branch then
        branch = vim.trim(vim.fn.system({ 'git', 'branch', '--show-current' }))
    end
    return M.root() .. (branch == nil and '' or '-' .. branch)
end

---@return integer?, harpoon.core.Mark?
function M.get_by_filename(filename)
    for i, mark in ipairs(M.get_marks()) do
        if mark.filename == filename then
            return i, mark
        end
    end
    return nil, nil
end

---@param filename? string
---@return string?
function M.relative(filename)
    if filename == nil then
        filename = vim.api.nvim_buf_get_name(0)
    end
    if vim.fn.filereadable(filename) == 0 then
        return nil
    end
    local root = M.root()
    if filename:sub(1, #root) == root then
        -- Ignore file separator after root
        return filename:sub(#root + 2)
    else
        return filename
    end
end

function M.save()
    local project, projects = M.project(), M.read_projects()
    local new_marks = { marks = M.get_marks() }
    if not vim.deep_equal(projects[project], new_marks) then
        projects[project] = new_marks
        local serialized = vim.fn.json_encode(projects)
        file.write(M.file_path, serialized)
    end
end

---@param filenames string[]
function M.set_project(filenames)
    local marks = {}
    for _, full_filename in ipairs(filenames) do
        local filename = M.relative(full_filename)
        if filename ~= nil then
            local _, mark = M.get_by_filename(filename)
            mark = mark ~= nil and mark or { filename = filename }
            marks[#marks + 1] = mark
        end
    end
    M.projects[M.project()] = { marks = marks }
    M.save()
end

---@param filename? string
function M.add_file(filename)
    filename = M.relative(filename)
    local index, _ = M.get_by_filename(filename)
    if filename ~= nil and index == nil then
        local marks = M.get_marks()
        marks[#marks + 1] = {
            filename = filename,
            cursor = vim.api.nvim_win_get_cursor(0),
        }
        M.save()
    end
end

---@param filename? string
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
