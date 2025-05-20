local Store = require('harpoon-core.store')

--[[
Projects are stored in the following format:
{
  "<absolute_path_to_project><-brance_name>?": {
    "marks": [
      {
        "filename": "<relative_path_from_project_root>",
        "cursor": [ <row>, <column> ],
      },
      ...
    ]
  },
  ...
}
--]]

---@class harpoon.core.marks.Config
---@field branch boolean

---@alias harpoon.core.Projects table<string, harpoon.core.Project>

---@class harpoon.core.Project
---@field marks harpoon.core.Mark[]

---@class harpoon.core.Mark
---@field filename string
---@field cursor? harpoon.core.Cursor
---@field index? integer

---@class harpoon.core.Cursor
---@field [1] integer
---@field [2] integer

---@class harpoon.core.Marks
---@field private config harpoon.core.marks.Config
---@field private store harpoon.core.Store
---@field private projects harpoon.core.Projects
local M = {}

---@param config harpoon.core.marks.Config
function M.setup(config)
    M.config = config
    -- resolves to ~/.local/share/nvim/harpoon-core.json
    M.store = Store.new(vim.fn.stdpath('data') .. '/harpoon-core.json')
    M.projects = M.store:read()
end

---@private
---@return string
function M.root()
    return vim.fn.getcwd()
end

---@private
---@return harpoon.core.Cursor
function M.cursor()
    return vim.api.nvim_win_get_cursor(0)
end

---@private
---@return string
function M.name()
    local result = M.root()
    if M.config.branch then
        local branch = vim.fn.system({ 'git', 'branch', '--show-current' })
        result = result .. '-' .. vim.trim(branch)
    end
    return result
end

---@return harpoon.core.Mark[]
function M.get()
    local name = M.name()
    if M.projects[name] == nil then
        -- no need to save the initial empty value, so no file write
        M.projects[name] = { marks = {} }
    end
    return M.projects[name].marks
end

---@param file? string
---@return string?
function M.filename(file)
    file = file or vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(file) == 0 then
        return nil
    end
    local root = M.root()
    -- ignore path separator after root if file is in root
    -- file = a/b/c/d | root = a/b | c/d
    -- file = a/c/d   | root = a/b | a/c/d
    return vim.startswith(file, root) and file:sub(#root + 2) or file
end

---@param filename? string
---@param kind string
---@return any
---@overload fun(filename?: string, kind: 'index'): integer?
---@overload fun(filename?: string, kind: 'mark'): harpoon.core.Mark?
function M.with_filename(filename, kind)
    assert(vim.tbl_contains({ 'index', 'mark' }, kind), 'invalid kind')
    for i, mark in ipairs(M.get()) do
        if mark.filename == filename then
            return kind == 'index' and i or mark
        end
    end
    return nil
end

---@param files string[]
function M.set(files)
    local marks = {} ---@type harpoon.core.Mark[]
    for _, file in ipairs(files) do
        local filename = M.filename(file)
        if filename then
            local mark = M.with_filename(filename, 'mark')
            marks[#marks + 1] = mark or { filename = filename }
        end
    end
    M.projects[M.name()] = { marks = marks }
    M.save()
end

---@param file? string
function M.add_file(file)
    local filename = M.filename(file)
    local index = M.with_filename(filename, 'index')
    if not filename or index then
        return
    end
    local marks = M.get()
    marks[#marks + 1] = { filename = filename, cursor = M.cursor() }
    M.save()
end

---@param file? string
function M.rm_file(file)
    local filename = M.filename(file)
    local index = M.with_filename(filename, 'index')
    if not filename or not index then
        return
    end
    table.remove(M.get(), index)
    M.save()
end

---@return integer?
function M.index()
    return M.with_filename(M.filename(), 'index')
end

function M.update_cursor()
    local mark = M.with_filename(M.filename(), 'mark')
    if not mark then
        return
    end
    mark.cursor = M.cursor()
    M.save()
end

---@param mark harpoon.core.Mark
---@param delta integer
---@return integer?
function M.move(mark, delta)
    local start_index = mark.index
    if not start_index then
        return nil
    end

    local marks = M.get()
    local end_index = start_index + delta
    if end_index < 1 or end_index > #marks then
        return nil
    end

    table.remove(marks, start_index)
    table.insert(marks, end_index, mark)
    M.save()
    return end_index
end

function M.save()
    local name = M.name()
    local projects = M.store:read()
    local old = projects[name]
    local new = { marks = M.get() } ---@type harpoon.core.Project
    if not vim.deep_equal(old, new) then
        projects[name] = new
        M.store:write(projects)
    end
end

return M
