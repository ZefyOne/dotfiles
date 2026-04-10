-- 设置行号
vim.opt.number = true

-- 启用语法高亮
vim.cmd("syntax enable")
vim.cmd("syntax on")

-- 缩进设置
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.cmd("filetype indent on")

-- Tab 相关选项
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.softtabstop = 4

-- 键位映射
vim.keymap.set("i", "<C-f>", "<Right>", { noremap = true })
vim.keymap.set("i", "<C-b>", "<Left>", { noremap = true })
vim.keymap.set("i", "{", "{}<Left>", { noremap = true })

-- 颜色主题
vim.cmd.colorscheme("habamax")
