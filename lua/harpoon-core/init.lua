local mark = require('harpoon-core.mark')

local M = {}
local context = {}

local group = vim.api.nvim_create_augroup('HarpoonCore', { clear = true })

--vim.api.nvim_create_autocmd({ 'BufLeave, VimLeave' }, {
--    group = group,
--    callback = function()
--        require('harpoon-core.mark').store_offset()
--    end,
--})

local function set_open_keymap(key, command)
    vim.keymap.set('n', key, function()
        vim.cmd(command)
        local line = vim.api.nvim_get_current_line()
        vim.cmd('e ' .. vim.fn.getcwd() .. '/' .. line)
    end, { buffer = true, noremap = true, silent = true })
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'harpoon-core',
    group = group,
    callback = function()
        set_open_keymap('<C-V>', 'vs')
        set_open_keymap('<C-x>', 'sp')
        set_open_keymap('<C-t>', 'tabnew')
    end,
})

M.setup = function(opts)
    opts = opts or {}
    context.opts = opts
    mark.setup()
end

return M
