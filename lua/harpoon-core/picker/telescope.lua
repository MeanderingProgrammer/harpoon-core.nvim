local Marks = require('harpoon-core.mark')

---@class harpoon.core.telescope.Config
---@field confirm boolean
---@field picker harpoon.core.picker.Config

---@class harpoon.core.Telescope
---@field private config harpoon.core.telescope.Config
local M = {}

---@param config harpoon.core.telescope.Config
function M.setup(config)
    M.config = config
end

function M.get(opts)
    local config = require('telescope.config')
    local pickers = require('telescope.pickers')

    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = 'Harpoon',
            finder = M.finder(),
            sorter = config.values.generic_sorter(opts),
            previewer = config.values.grep_previewer(opts),
            attach_mappings = function(_, map)
                map({ 'i', 'n' }, M.config.picker.delete, M.delete)
                map({ 'i', 'n' }, M.config.picker.move_down, M.move_down)
                map({ 'i', 'n' }, M.config.picker.move_up, M.move_up)
                return true
            end,
        })
        :find()
end

---@private
---@param buf integer
function M.delete(buf)
    if not M.confirm() then
        vim.print('Did not delete mark')
        return
    end
    local mark = M.selected()
    Marks.rm_file(mark.filename)
    M.refresh(buf)
end

---@private
---@return boolean
function M.confirm()
    if not M.config.confirm then
        return true
    end
    local response = vim.fn.input('Delete current mark? [y/n]: ')
    return #response > 0 and response:lower():sub(1, 1) == 'y'
end

---@private
---@param buf integer
function M.move_down(buf)
    local row = Marks.move(M.selected(), -1)
    if row then
        M.refresh(buf)
    end
end

---@private
---@param buf integer
function M.move_up(buf)
    local row = Marks.move(M.selected(), 1)
    if row then
        M.refresh(buf)
    end
end

---@return harpoon.core.Mark
function M.selected()
    local state = require('telescope.actions.state')
    return state.get_selected_entry().value
end

---@private
---@param buf integer
function M.refresh(buf)
    local state = require('telescope.actions.state')
    local picker = state.get_current_picker(buf)
    picker:refresh(M.finder(), { reset_prompt = true })
end

---@private
function M.finder()
    local finders = require('telescope.finders')
    local entry_display = require('telescope.pickers.entry_display')

    local displayer = entry_display.create({
        separator = ' - ',
        items = {
            { width = 2 },
            { width = 50 },
            { remaining = true },
        },
    })

    return finders.new_table({
        results = M.get_results(),
        ---@param mark harpoon.core.Mark
        ---@return any
        entry_maker = function(mark)
            local cursor = mark.cursor or {}
            return {
                value = mark,
                ordinal = mark.filename,
                filename = mark.filename,
                lnum = cursor[1],
                col = cursor[2],
                display = function()
                    return displayer({
                        tostring(mark.index),
                        mark.filename,
                    })
                end,
            }
        end,
    })
end

---@private
---@return harpoon.core.Mark[]
function M.get_results()
    local result = {} ---@type harpoon.core.Mark[]
    for i, mark in ipairs(Marks.get()) do
        mark.index = i
        result[#result + 1] = mark
    end
    return result
end

return M
