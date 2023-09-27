local mark = require('harpoon-core.mark')
local popup = require('plenary.popup')

local M = {}
local bufnr = nil
local window_id = nil

M.open = function(filename, command)
    if command ~= nil then
        vim.cmd(command)
    end
    vim.cmd('e ' .. mark.absolute(filename))
end

M.nav_next = function()
    --TODO
end

M.nav_prev = function()
    --TODO
end

M.nav_file = function(index)
    local filename = mark.get_filename(index)
    if filename ~= nil then
        M.open(filename, nil)
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
    local _, window = popup.create(bufnr, {
        title = 'Harpoon',
        col = center_pad(vim.o.columns, width),
        minwidth = width,
        line = center_pad(vim.o.lines, height),
        minheight = height,
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
    })
    window_id = window.win_id
end

M.close = function()
    if window_id ~= nil then
        vim.api.nvim_win_close(window_id, true)
        bufnr = nil
        window_id = nil
    end
end

local function save_project()
    if bufnr == nil then
        return
    end
    mark.clear()
    local filenames = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    for _, filename in pairs(filenames) do
        mark.add_file(mark.absolute(filename))
    end
end

M.toggle_quick_menu = function()
    if bufnr ~= nil or window_id ~= nil then
        M.close()
        return
    end

    create_window()
    if bufnr == nil or window_id == nil then
        return
    end

    local filenames = mark.get_filenames()
    vim.api.nvim_buf_set_name(bufnr, 'harpoon-menu')
    vim.api.nvim_buf_set_lines(bufnr, 0, #filenames, false, filenames)

    vim.api.nvim_win_set_option(window_id, 'number', true)
    -- This a bit of spaghetti that we use to configure keymaps to do specific
    -- things on harpoon-core files, these can be found in init.lua
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'harpoon-core')
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'delete')
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'acwrite')

    local close_command = '<cmd>lua require("harpoon-core.ui").close()<cr>'
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', close_command, {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<esc>', close_command, {})

    vim.api.nvim_create_autocmd('BufModifiedSet', {
        buffer = bufnr,
        callback = function()
            vim.api.nvim_buf_set_option(bufnr, 'modified', false)
        end,
    })
    vim.api.nvim_create_autocmd('BufLeave', { buffer = bufnr, nested = true, callback = M.close })
    -- TODO add additional cases where we want to save
    vim.api.nvim_create_autocmd('BufWriteCmd', { buffer = bufnr, callback = save_project })
end

return M
