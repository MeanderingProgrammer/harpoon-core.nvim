local harpoon = require('harpoon-core')
local mark = require('harpoon-core.mark')
local popup = require('plenary.popup')

local M = {}
local bufnr = nil
local window_id = nil

local function save_project()
    if bufnr ~= nil then
        local filenames = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        mark.set_project(filenames)
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
    for _, tabpage in pairs(vim.api.nvim_list_tabpages()) do
        for _, tabpage_window_id in pairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
            local tabpage_bufnr = vim.api.nvim_win_get_buf(tabpage_window_id)
            if vim.fn.bufname(tabpage_bufnr) == filename then
                return tabpage_window_id
            end
        end
    end
    return nil
end

function M.open(filename, command)
    save_close()
    local existing_window_id = nil
    if harpoon.get_opts().use_existing then
        existing_window_id = get_existing(filename)
    end
    if existing_window_id ~= nil then
        vim.api.nvim_set_current_win(existing_window_id)
    else
        if command ~= nil then
            vim.cmd(command)
        end
        vim.cmd('e ' .. filename)
    end
end

function M.nav_file(index)
    local filename = mark.get_filename(index)
    if filename ~= nil then
        M.open(filename, nil)
    end
end

function M.nav_next()
    local current_index = mark.current_index()
    if current_index == nil or current_index == mark.length() then
        M.nav_file(1)
    else
        M.nav_file(current_index + 1)
    end
end

function M.nav_prev()
    local current_index = mark.current_index()
    if current_index == nil or current_index == 1 then
        M.nav_file(mark.length())
    else
        M.nav_file(current_index - 1)
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

function M.toggle_quick_menu()
    if bufnr ~= nil or window_id ~= nil then
        save_close()
        return
    end

    -- This must happen before we create the window, otherwise the current buffer
    -- ends up being the harpoon window
    local current_index = mark.current_index()

    create_window()
    if bufnr == nil or window_id == nil then
        return
    end

    local filenames = mark.get_filenames()
    vim.api.nvim_buf_set_name(bufnr, 'harpoon-menu')
    vim.api.nvim_buf_set_lines(bufnr, 0, #filenames, false, filenames)

    -- Move cursor to current file if it exists, cursor is already on first
    -- line so movement needs to be offset by 1
    if current_index ~= nil then
        vim.cmd('+' .. current_index - 1)
    end

    vim.api.nvim_win_set_option(window_id, 'number', true)
    -- This a bit of spaghetti that we use to configure keymaps to do specific
    -- things on harpoon-core files, these can be found in plugin/harpoon-core.lua
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'harpoon-core')
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'delete')
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'acwrite')

    vim.keymap.set('n', 'q', save_close, { buffer = bufnr })
    vim.keymap.set('n', '<esc>', save_close, { buffer = bufnr })

    local function set_unmodified()
        vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    end
    vim.api.nvim_create_autocmd('BufModifiedSet', { buffer = bufnr, callback = set_unmodified })
    vim.api.nvim_create_autocmd('BufLeave', { buffer = bufnr, nested = true, callback = save_close })
    vim.api.nvim_create_autocmd('BufWriteCmd', { buffer = bufnr, callback = save_project })
end

return M
