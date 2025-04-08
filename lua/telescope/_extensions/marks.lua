local action_state = require('telescope.actions.state')
local marker = require('harpoon-core.mark')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local state = require('harpoon-core.state')

---@class harpoon.core.telescope.Extension
local M = {}

---@private
---@param buf integer
function M.delete(buf)
    if not M.confirm_delete() then
        print('Did not delete mark')
        return
    end
    local entry = action_state.get_selected_entry()
    marker.rm_file(entry.filename)
    M.refresh_picker(buf)
end

---@private
---@return boolean
function M.confirm_delete()
    if not state.config.delete_confirmation then
        return true
    end
    local response = vim.fn.input('Delete current mark? [y/n]: ')
    return #response > 0 and string.sub(string.lower(response), 0, 1) == 'y'
end

---@private
---@param buf integer
function M.move_up(buf)
    local marks = marker.get_marks()
    local index = action_state.get_selected_entry().index
    if index ~= #marks then
        local mark = table.remove(marks, index)
        table.insert(marks, index + 1, mark)
        marker.save()
        M.refresh_picker(buf)
    end
end

---@private
---@param buf integer
function M.move_down(buf)
    local marks = marker.get_marks()
    local index = action_state.get_selected_entry().index
    if index ~= 1 then
        local mark = table.remove(marks, index)
        table.insert(marks, index - 1, mark)
        marker.save()
        M.refresh_picker(buf)
    end
end

---@private
---@param buf integer
function M.refresh_picker(buf)
    local picker = action_state.get_current_picker(buf)
    picker:refresh(M.generate_finder(), { reset_prompt = true })
end

---@private
function M.generate_finder()
    return finders.new_table({
        results = M.get_results(),
        entry_maker = function(entry)
            local displayer = entry_display.create({
                separator = ' - ',
                items = {
                    { width = 2 },
                    { width = 50 },
                    { remaining = true },
                },
            })
            local function make_display()
                return displayer({
                    tostring(entry.index),
                    entry.filename,
                })
            end
            return {
                value = entry,
                ordinal = entry.filename,
                display = make_display,
                filename = entry.filename,
                lnum = entry.cursor[1],
                col = entry.cursor[2],
            }
        end,
    })
end

---@private
---@return harpoon.core.Mark[]
function M.get_results()
    local result = {}
    for i, mark in ipairs(marker.get_marks()) do
        mark.index = i
        result[#result + 1] = mark
    end
    return result
end

return function(opts)
    opts = opts or {}
    pickers
        .new(opts, {
            prompt_title = 'Harpoon',
            finder = M.generate_finder(),
            sorter = conf.generic_sorter(opts),
            previewer = conf.grep_previewer(opts),
            attach_mappings = function(_, map)
                map('i', '<c-d>', M.delete)
                map('n', '<c-d>', M.delete)
                map('i', '<c-p>', M.move_up)
                map('n', '<c-p>', M.move_up)
                map('i', '<c-n>', M.move_down)
                map('n', '<c-n>', M.move_down)
                return true
            end,
        })
        :find()
end
