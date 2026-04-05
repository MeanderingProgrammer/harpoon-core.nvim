if vim.g.loaded_harpoon_core then
    return
end
vim.g.loaded_harpoon_core = true

vim.api.nvim_create_autocmd({ 'BufLeave', 'VimLeave' }, {
    group = vim.api.nvim_create_augroup('HarpoonCore', {}),
    callback = function()
        require('harpoon-core.mark').update_cursor()
    end,
})
