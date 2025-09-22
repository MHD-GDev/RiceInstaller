return {
    'mbbill/undotree',
    config = function ()
        vim.o.undofile = true
    end,
    vim.keymap.set('n', 'U', ':UndotreeToggle<CR>', { noremap = true })
}
