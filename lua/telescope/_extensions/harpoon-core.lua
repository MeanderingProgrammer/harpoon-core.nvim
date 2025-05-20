local has, telescope = pcall(require, 'telescope')

if not has or not telescope then
    error('harpoon-core extension requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension({
    exports = {
        marks = require('harpoon-core.picker.telescope').get,
    },
})
