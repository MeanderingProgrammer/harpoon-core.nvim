local marker = require('harpoon-core.mark')

---@class harpoon.core.Ui
---@field private use_existing boolean
---@field private default_action? string
---@field private use_cursor boolean
---@field private width integer
---@field private height integer
---@field private buf? integer
---@field private win? integer
local M = {}

---@param config harpoon.core.Config
function M.setup(config)
    M.use_existing = config.use_existing
    M.default_action = config.default_action
    M.use_cursor = config.use_cursor
    M.width = config.menu.width
    M.height = config.menu.height
    M.buf = nil
    M.win = nil
end

function M.nav_next()
    local marks, index = marker.get_marks(), marker.current()
    if index == nil or index == #marks then
        M.nav_file(1)
    else
        M.nav_file(index + 1)
    end
end

function M.nav_prev()
    local marks, index = marker.get_marks(), marker.current()
    if index == nil or index == 1 then
        M.nav_file(#marks)
    else
        M.nav_file(index - 1)
    end
end

---@param index integer
function M.nav_file(index)
    local marks = marker.get_marks()
    if #marks > 0 and index <= #marks then
        M.open(marks[index], nil)
    end
end

function M.toggle_quick_menu()
    if M.buf ~= nil or M.win ~= nil then
        M.save_close()
        return
    end

    -- This must happen before we create the window, otherwise the current buffer
    -- ends up being the harpoon window
    local index = marker.current()

    local filenames = {}
    for _, mark in ipairs(marker.get_marks()) do
        filenames[#filenames + 1] = mark.filename
    end

    M.buf = vim.api.nvim_create_buf(false, false)
    M.win = vim.api.nvim_open_win(M.buf, true, {
        title = ' Harpoon ',
        title_pos = 'center',
        border = 'rounded',
        relative = 'editor',
        height = M.height,
        width = M.width,
        row = math.floor((vim.o.lines - M.height) / 2),
        col = math.floor((vim.o.columns - M.width) / 2),
    })
    if M.buf == nil or M.win == nil then
        return
    end

    vim.api.nvim_buf_set_name(M.buf, 'harpoon-menu')
    vim.api.nvim_buf_set_lines(M.buf, 0, #filenames, false, filenames)

    -- Move cursor to current file if it exists, cursor is already on first
    -- line so movement needs to be offset by 1
    if index ~= nil then
        vim.cmd('+' .. index - 1)
    end

    vim.api.nvim_set_option_value('bufhidden', 'delete', { buf = M.buf })
    vim.api.nvim_set_option_value('buftype', 'acwrite', { buf = M.buf })

    M.buf_map('q', 'save', nil)
    M.buf_map('<esc>', 'save', nil)
    M.buf_map('<cr>', 'open', nil)
    M.buf_map('<C-v>', 'open', 'vs')
    M.buf_map('<C-x>', 'open', 'sp')
    M.buf_map('<C-t>', 'open', 'tabnew')

    vim.api.nvim_create_autocmd('BufModifiedSet', {
        buffer = M.buf,
        callback = function()
            vim.api.nvim_set_option_value('modified', false, { buf = M.buf })
        end,
    })
    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = M.buf,
        callback = M.save_project,
    })
    vim.api.nvim_create_autocmd('BufLeave', {
        buffer = M.buf,
        nested = true,
        callback = M.save_close,
    })
end

---@private
---@param lhs string
---@param variant 'save'|'open'
---@param command? string
function M.buf_map(lhs, variant, command)
    vim.keymap.set('n', lhs, function()
        if variant == 'save' then
            M.save_close()
        elseif variant == 'open' then
            local filename = vim.api.nvim_get_current_line()
            local _, mark = marker.get_by_filename(filename)
            M.open(mark, command)
        end
    end, { buffer = M.buf, noremap = true, silent = true })
end

---@private
---@param mark? harpoon.core.Mark
---@param command? string
function M.open(mark, command)
    if mark == nil then
        return
    end
    M.save_close()

    local windows = M.get_existing(mark)

    -- Don't do anything if the mark is the current window
    if vim.tbl_contains(windows, vim.api.nvim_get_current_win()) then
        return
    end

    -- Set first window found as current if use_existing is set
    if M.use_existing and #windows > 0 then
        vim.api.nvim_set_current_win(windows[1])
        return
    end

    command = command or M.default_action
    if command ~= nil then
        vim.cmd(command)
    end

    vim.cmd.edit(mark.filename)
    if M.use_cursor and mark.cursor ~= nil then
        vim.api.nvim_win_set_cursor(0, mark.cursor)
    end
end

---@private
function M.save_close()
    if M.win ~= nil then
        M.save_project()
        vim.api.nvim_win_close(M.win, true)
        M.buf = nil
        M.win = nil
    end
end

---@private
function M.save_project()
    if M.buf ~= nil then
        local filenames = vim.api.nvim_buf_get_lines(M.buf, 0, -1, true)
        marker.set_project(filenames)
    end
end

---@private
---@param mark harpoon.core.Mark
---@return integer[]
function M.get_existing(mark)
    -- bufwinid is limited in scope to current tab, otherwise it would be perfect
    local result = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            local buf = vim.api.nvim_win_get_buf(win)
            local filename = vim.fn.bufname(buf)
            if marker.relative(filename) == mark.filename then
                result[#result + 1] = win
            end
        end
    end
    return result
end

return M
