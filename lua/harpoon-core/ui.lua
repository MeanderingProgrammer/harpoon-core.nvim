local mark = require('harpoon-core.mark')
local popup = require('plenary.popup')

local M = {}
local bufnr = nil
local window_id = nil

local function get_or_create_buffer(file_name)
    if vim.fn.bufexists(file_name) ~= 0 then
        return vim.fn.bufnr(file_name)
    else
        return vim.fn.bufadd(file_name)
    end
end

M.nav_file = function(index)
    local file_name = mark.get_file_name(index)
    if file_name == nil then
        return
    end
    local file_bufnr = get_or_create_buffer(file_name)
    vim.api.nvim_set_current_buf(file_bufnr)
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

M.toggle_quick_menu = function()
    if bufnr ~= nil or window_id ~= nil then
        M.close()
        return
    end

    create_window()
    if bufnr == nil or window_id == nil then
        return
    end

    local contents = mark.get_files()
    vim.api.nvim_buf_set_name(bufnr, 'harpoon-menu')
    vim.api.nvim_buf_set_lines(bufnr, 0, #contents, false, contents)

    vim.api.nvim_win_set_option(window_id, 'number', true)
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
    vim.api.nvim_create_autocmd('BufLeave', {
        buffer = bufnr,
        nested = true,
        callback = function()
            M.close()
        end,
    })
    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = bufnr,
        callback = function()
            -- TODO
        end,
    })
end

return M
