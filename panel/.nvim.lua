require('flutter-tools').setup_project({
    {
        name = 'Panel',
        device = 'macos',
    },
    {
        name = 'WidgetBook',
        device = 'macos',
        cwd = vim.fs.joinpath(vim.fn.getcwd(), 'widgetbook'),
    }
})
