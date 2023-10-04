local marker = require('harpoon-core.mark')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local entry_display = require('telescope.pickers.entry_display')

local function get_results()
    local result = {}
    for i, mark in pairs(marker.get_marks()) do
        mark.index = i
        table.insert(result, mark)
    end
    return result
end

local function generate_finder()
    return finders.new_table({
        results = get_results(),
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

local function reset_picker(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_finder(), { reset_prompt = true })
end

local function delete(prompt_bufnr)
    local confirmation = vim.fn.input(string.format('Delete current mark? [y/n]: '))
    if string.len(confirmation) == 0 or string.sub(string.lower(confirmation), 0, 1) ~= 'y' then
        print(string.format('Did not delete mark'))
        return
    end
    local entry = action_state.get_selected_entry()
    marker.rm_file(entry.filename)
    reset_picker(prompt_bufnr)
end

local function move_up(prompt_bufnr)
    local index = action_state.get_selected_entry().index
    if index == marker.length() then
        return
    end
    local marks = marker.get_marks()
    local mark = table.remove(marks, index)
    table.insert(marks, index + 1, mark)
    marker.save()
    reset_picker(prompt_bufnr)
end

local function move_down(prompt_bufnr)
    local index = action_state.get_selected_entry().index
    if index == 1 then
        return
    end
    local marks = marker.get_marks()
    local mark = table.remove(marks, index)
    table.insert(marks, index - 1, mark)
    marker.save()
    reset_picker(prompt_bufnr)
end

return function(opts)
    opts = opts or {}
    pickers
        .new(opts, {
            prompt_title = 'Harpoon',
            finder = generate_finder(),
            sorter = conf.generic_sorter(opts),
            previewer = conf.grep_previewer(opts),
            attach_mappings = function(_, map)
                map('i', '<c-d>', delete)
                map('n', '<c-d>', delete)
                map('i', '<c-p>', move_up)
                map('n', '<c-p>', move_up)
                map('i', '<c-n>', move_down)
                map('n', '<c-n>', move_down)
                return true
            end,
        })
        :find()
end
