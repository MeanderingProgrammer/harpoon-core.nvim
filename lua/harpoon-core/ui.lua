local harpoon = require('harpoon-core')
local marker = require('harpoon-core.mark')
local popup = require('plenary.popup')

local M = {}
local bufnr = nil
local window_id = nil

local function save_project()
    if bufnr ~= nil then
        local filenames = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        marker.set_project(filenames)
    end
end

local function save_close()
    if window_id ~= nil then
        save_project()
        vim.api.nvim_win_close(window_id, true)
        bufnr = nil
        window_id = nil
    end
end

local function get_existing(filename)
    -- bufwinid is limited in scope to current tab, otherwise it would be perfect
    for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
        for _, tabpage_window_id in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
            local tabpage_bufnr = vim.api.nvim_win_get_buf(tabpage_window_id)
            local tabpage_filename = vim.fn.bufname(tabpage_bufnr)
            local tabpage_relative_filename = marker.relative(tabpage_filename)
            if tabpage_relative_filename == filename then
                return tabpage_window_id
            end
        end
    end
    return nil
end

local function open(mark, command)
    if mark == nil then
        return
    end
    save_close()

    if command == nil then
        command = harpoon.get_opts().default_action
    end

    local existing_window_id = nil
    if harpoon.get_opts().use_existing then
        existing_window_id = get_existing(mark.filename)
    end

    if existing_window_id ~= nil then
        vim.api.nvim_set_current_win(existing_window_id)
    else
        if command ~= nil then
            vim.cmd(command)
        end
        vim.cmd.edit(mark.filename)
        if harpoon.get_opts().use_cursor and mark.cursor ~= nil then
            vim.api.nvim_win_set_cursor(0, mark.cursor)
        end
    end
end

function M.nav_file(index)
    local mark = marker.get_by_index(index)
    open(mark, nil)
end

function M.nav_next()
    local index, _ = marker.current()
    if index == nil or index == marker.length() then
        M.nav_file(1)
    else
        M.nav_file(index + 1)
    end
end

function M.nav_prev()
    local index, _ = marker.current()
    if index == nil or index == 1 then
        M.nav_file(marker.length())
    else
        M.nav_file(index - 1)
    end
end

local function create_window()
    local width = harpoon.get_opts().menu.width
    local height = harpoon.get_opts().menu.height
    bufnr = vim.api.nvim_create_buf(false, false)
    local hl_groups = harpoon.get_opts().highlight_groups
    local _, window = popup.create(bufnr, {
        title = 'Harpoon',
        highlight = hl_groups.window,
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        line = math.floor((vim.o.lines - height) / 2),
        minheight = height,
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
    })
    vim.api.nvim_win_set_option(window.border.win_id, 'winhl', 'Normal:' .. hl_groups.border)
    window_id = window.win_id
end

local function nmap(key, callback)
    vim.keymap.set('n', key, callback, { buffer = bufnr, noremap = true, silent = true })
end

function M.toggle_quick_menu()
    if bufnr ~= nil or window_id ~= nil then
        save_close()
        return
    end

    -- This must happen before we create the window, otherwise the current buffer
    -- ends up being the harpoon window
    local index, _ = marker.current()

    create_window()
    if bufnr == nil or window_id == nil then
        return
    end

    local filenames = {}
    for _, mark in ipairs(marker.get_marks()) do
        table.insert(filenames, mark.filename)
    end
    vim.api.nvim_buf_set_name(bufnr, 'harpoon-menu')
    vim.api.nvim_buf_set_lines(bufnr, 0, #filenames, false, filenames)

    -- Move cursor to current file if it exists, cursor is already on first
    -- line so movement needs to be offset by 1
    if index ~= nil then
        vim.cmd('+' .. index - 1)
    end

    vim.api.nvim_win_set_option(window_id, 'number', true)
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'delete')
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'acwrite')

    nmap('q', save_close)
    nmap('<esc>', save_close)

    local function open_current_file(command)
        return function()
            local filename = vim.api.nvim_get_current_line()
            local _, mark = marker.get_by_filename(filename)
            open(mark, command)
        end
    end
    nmap('<cr>', open_current_file(nil))
    nmap('<C-v>', open_current_file('vs'))
    nmap('<C-x>', open_current_file('sp'))
    nmap('<C-t>', open_current_file('tabnew'))

    local function set_unmodified()
        vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    end
    vim.api.nvim_create_autocmd('BufModifiedSet', { buffer = bufnr, callback = set_unmodified })
    vim.api.nvim_create_autocmd('BufWriteCmd', { buffer = bufnr, callback = save_project })
    vim.api.nvim_create_autocmd('BufLeave', { buffer = bufnr, nested = true, callback = save_close })
end

return M
