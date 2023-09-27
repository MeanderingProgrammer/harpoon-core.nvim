local harpoon = require('harpoon-core')
local mark = require('harpoon-core.mark')
local popup = require('plenary.popup')

local M = {}
local bufnr = nil
local window_id = nil

local function open(filename, command)
    if command ~= nil then
        vim.cmd(command)
    end
    vim.cmd('e ' .. mark.absolute(filename))
end

local function set_open_keymap(key, command)
    vim.keymap.set('n', key, function()
        local filename = vim.api.nvim_get_current_line()
        open(filename, command)
    end, { buffer = true, noremap = true, silent = true })
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'harpoon-core',
    group = vim.api.nvim_create_augroup('HarpoonCore', { clear = true }),
    callback = function()
        set_open_keymap('<cr>', nil)
        set_open_keymap('<C-v>', 'vs')
        set_open_keymap('<C-x>', 'sp')
        set_open_keymap('<C-t>', 'tabnew')
    end,
})

M.nav_file = function(index)
    local filename = mark.get_filename(index)
    if filename ~= nil then
        open(filename, nil)
    end
end

M.nav_next = function()
    local current_index = mark.current_index()
    if current_index == nil or current_index == mark.length() then
        M.nav_file(1)
    else
        M.nav_file(current_index + 1)
    end
end

M.nav_prev = function()
    local current_index = mark.current_index()
    if current_index == nil or current_index == 1 then
        M.nav_file(mark.length())
    else
        M.nav_file(current_index - 1)
    end
end

local function center_pad(outer, inner)
    local extra = outer - inner
    return math.floor(extra / 2)
end

local function create_window()
    local width = 60
    local height = 10
    bufnr = vim.api.nvim_create_buf(false, false)
    local hl_groups = harpoon.get_opts().highlight_groups
    local _, window = popup.create(bufnr, {
        title = 'Harpoon',
        highlight = hl_groups.window,
        col = center_pad(vim.o.columns, width),
        minwidth = width,
        line = center_pad(vim.o.lines, height),
        minheight = height,
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
    })
    vim.api.nvim_win_set_option(window.border.win_id, 'winhl', 'Normal:' .. hl_groups.border)
    window_id = window.win_id
end

local function save_project()
    if bufnr ~= nil then
        mark.clear()
        local filenames = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        for _, filename in pairs(filenames) do
            mark.add_file(mark.absolute(filename))
        end
    end
end

M.save_close = function()
    if window_id ~= nil then
        save_project()
        vim.api.nvim_win_close(window_id, true)
        bufnr = nil
        window_id = nil
    end
end

M.toggle_quick_menu = function()
    if bufnr ~= nil or window_id ~= nil then
        M.save_close()
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
    -- things on harpoon-core files, these can be found at the top of this file
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'harpoon-core')
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'delete')
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'acwrite')

    local close_command = '<cmd>lua require("harpoon-core.ui").save_close()<cr>'
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', close_command, {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', close_command, {})

    vim.api.nvim_create_autocmd('BufModifiedSet', {
        buffer = bufnr,
        callback = function()
            vim.api.nvim_buf_set_option(bufnr, 'modified', false)
        end,
    })
    vim.api.nvim_create_autocmd('BufLeave', { buffer = bufnr, nested = true, callback = M.save_close })
    vim.api.nvim_create_autocmd('BufWriteCmd', { buffer = bufnr, callback = save_project })
end

return M
