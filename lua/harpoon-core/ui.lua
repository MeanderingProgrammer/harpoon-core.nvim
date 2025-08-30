local Icons = require('harpoon-core.icons')
local Marks = require('harpoon-core.mark')

---@class harpoon.core.ui.Config
---@field use_existing boolean
---@field default_action? string
---@field use_cursor boolean
---@field menu harpoon.core.menu.Config

---@class harpoon.core.Ui
---@field private config harpoon.core.ui.Config
local M = {}

---@private
M.ns = vim.api.nvim_create_namespace('HarpoonCore')

---@private
---@type integer?
M.buf = nil

---@private
---@type integer?
M.win = nil

---@param config harpoon.core.ui.Config
function M.setup(config)
    M.config = config
    vim.api.nvim_set_decoration_provider(M.ns, {
        on_win = function(_, win, buf)
            if not M.buf or not M.win or M.buf ~= buf or M.win ~= win then
                return false
            end
            if not M.config.menu.icons then
                return false
            end
            vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
        end,
        on_line = function(_, _, buf, row)
            local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
            if line and #line > 0 then
                local icon, highlight = Icons.get(line)
                if icon and highlight then
                    -- ephemeral marks do not support inline
                    vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
                        virt_text = { { icon .. ' ', highlight } },
                        virt_text_pos = 'inline',
                    })
                end
            end
        end,
    })
end

function M.nav_next()
    local marks = Marks.get()
    local index = Marks.index()
    if not index or index == #marks then
        M.nav_file(1)
    else
        M.nav_file(index + 1)
    end
end

function M.nav_prev()
    local marks = Marks.get()
    local index = Marks.index()
    if not index or index == 1 then
        M.nav_file(#marks)
    else
        M.nav_file(index - 1)
    end
end

---@param index integer
function M.nav_file(index)
    local marks = Marks.get()
    if #marks > 0 and index <= #marks then
        M.open(marks[index], nil)
    end
end

function M.toggle_quick_menu()
    if M.buf or M.win then
        M.save_close()
        return
    end

    -- must happen before we create the window to get correct current buffer
    local index = Marks.index()
    local marks = Marks.get()

    M.buf = vim.api.nvim_create_buf(false, false)

    local rows = vim.o.lines
    local height = M.config.menu.height
    height = height > 1 and height or math.floor(rows * height + 0.5)

    local cols = vim.o.columns
    local width = M.config.menu.width
    width = width > 1 and width or math.floor(cols * width + 0.5)

    M.win = vim.api.nvim_open_win(M.buf, true, {
        title = ' Harpoon ',
        title_pos = 'center',
        border = 'rounded',
        relative = 'editor',
        height = height,
        width = width,
        row = math.floor((rows - height) / 2),
        col = math.floor((cols - width) / 2),
    })

    if not M.buf or not M.win then
        return
    end

    vim.api.nvim_buf_set_name(M.buf, 'harpoon-menu')

    local lines = {} ---@type string[]
    for _, mark in ipairs(marks) do
        lines[#lines + 1] = mark.filename
    end
    vim.api.nvim_buf_set_lines(M.buf, 0, #lines, false, lines)

    -- move cursor to current file if it exists, cursor is already on first
    -- line so movement needs to be offset by 1
    if index then
        vim.cmd('+' .. index - 1)
    end

    ---@type vim.api.keyset.option
    local buf_opts = { buf = M.buf }
    vim.api.nvim_set_option_value('bufhidden', 'delete', buf_opts)
    vim.api.nvim_set_option_value('buftype', 'acwrite', buf_opts)

    ---@type vim.api.keyset.option
    local win_opts = { scope = 'local', win = M.win }
    vim.api.nvim_set_option_value('spell', false, win_opts)

    ---@type vim.keymap.set.Opts
    local key_opts = { buffer = M.buf, noremap = true, silent = true }
    vim.keymap.set('n', 'q', M.keymap('save'), key_opts)
    vim.keymap.set('n', '<esc>', M.keymap('save'), key_opts)
    vim.keymap.set('n', '<cr>', M.keymap('open'), key_opts)
    vim.keymap.set('n', '<C-v>', M.keymap('open', 'vs'), key_opts)
    vim.keymap.set('n', '<C-x>', M.keymap('open', 'sp'), key_opts)
    vim.keymap.set('n', '<C-t>', M.keymap('open', 'tabnew'), key_opts)

    vim.api.nvim_create_autocmd('BufModifiedSet', {
        buffer = M.buf,
        callback = function()
            vim.api.nvim_set_option_value('modified', false, buf_opts)
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
---@param kind 'save'|'open'
---@param command? string
---@return fun()
function M.keymap(kind, command)
    return function()
        if kind == 'save' then
            M.save_close()
        elseif kind == 'open' then
            local filename = vim.api.nvim_get_current_line()
            local mark = Marks.with_filename(filename, 'mark')
            M.open(mark, command)
        end
    end
end

---@private
---@param mark? harpoon.core.Mark
---@param command? string
function M.open(mark, command)
    if mark == nil then
        return
    end
    M.save_close()

    local wins = M.get_existing(mark)

    -- Don't do anything if the mark is the current window
    if vim.tbl_contains(wins, vim.api.nvim_get_current_win()) then
        return
    end

    -- Set first window found as current if use_existing is set
    if M.config.use_existing and #wins > 0 then
        vim.api.nvim_set_current_win(wins[1])
        return
    end

    command = command or M.config.default_action
    if command ~= nil then
        vim.cmd(command)
    end

    vim.cmd.edit(mark.filename)
    if M.config.use_cursor and mark.cursor ~= nil then
        vim.api.nvim_win_set_cursor(0, mark.cursor)
    end
end

---@private
function M.save_close()
    if M.win then
        M.save_project()
        vim.api.nvim_win_close(M.win, true)
        M.buf = nil
        M.win = nil
    end
end

---@private
function M.save_project()
    if M.buf then
        Marks.set(vim.api.nvim_buf_get_lines(M.buf, 0, -1, false))
    end
end

---@private
---@param mark harpoon.core.Mark
---@return integer[]
function M.get_existing(mark)
    -- bufwinid is limited in scope to current tab, otherwise it would be perfect
    local result = {} ---@type integer[]
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            local buf = vim.api.nvim_win_get_buf(win)
            local file = vim.fn.bufname(buf)
            if Marks.filename(file) == mark.filename then
                result[#result + 1] = win
            end
        end
    end
    return result
end

return M
