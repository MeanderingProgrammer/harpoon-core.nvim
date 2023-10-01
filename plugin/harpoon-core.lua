local marker = require('harpoon-core.mark')

vim.api.nvim_create_autocmd({ 'BufLeave', 'VimLeave' }, {
    group = vim.api.nvim_create_augroup('HarpoonCore', { clear = true }),
    callback = marker.update_cursor,
})
