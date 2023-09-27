local mark = require('harpoon-core.mark')
local ui = require('harpoon-core.ui')

local M = {}
local context = {}

local function set_open_keymap(key, command)
    vim.keymap.set('n', key, function()
        local filename = vim.api.nvim_get_current_line()
        ui.open(filename, command)
    end, { buffer = true, noremap = true, silent = true })
end

local group = vim.api.nvim_create_augroup('HarpoonCore', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'harpoon-core',
    group = group,
    callback = function()
        set_open_keymap('<cr>', nil)
        set_open_keymap('<C-v>', 'vs')
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
