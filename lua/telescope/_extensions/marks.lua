local marker = require('harpoon-core.mark')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local entry_display = require('telescope.pickers.entry_display')
local conf = require('telescope.config').values

local function prepare_results(marks)
    local result = {}
    for i, mark in pairs(marks) do
        table.insert(result, {
            index = i,
            filename = mark.filename,
            row = mark.cursor[1],
            col = mark.cursor[2],
        })
    end
    return result
end

local function generate_finder()
    return finders.new_table({
        results = prepare_results(marker.get_marks()),
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
                lnum = entry.row,
                col = entry.col,
            }
        end,
    })
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
                -- map('i', '<c-d>', delete_harpoon_mark)
                -- map('n', '<c-d>', delete_harpoon_mark)
                -- map('i', '<c-p>', move_mark_up)
                -- map('n', '<c-p>', move_mark_up)
                -- map('i', '<c-n>', move_mark_down)
                -- map('n', '<c-n>', move_mark_down)
                return true
            end,
        })
        :find()
end
