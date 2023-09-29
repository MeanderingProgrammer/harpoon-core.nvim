local ui = require('harpoon-core.ui')

local function open_keymap(key, command)
    vim.keymap.set('n', key, function()
        local filename = vim.api.nvim_get_current_line()
        ui.open(filename, command)
    end, { buffer = true, noremap = true, silent = true })
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'harpoon-core',
    group = vim.api.nvim_create_augroup('HarpoonCore', { clear = true }),
    callback = function()
        open_keymap('<cr>', nil)
        open_keymap('<C-v>', 'vs')
        open_keymap('<C-x>', 'sp')
        open_keymap('<C-t>', 'tabnew')
    end,
})
