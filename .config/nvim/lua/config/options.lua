-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- 禁用光标行高亮
opt.cursorline = false

opt.relativenumber = false -- Relative line numbers

opt.wrap = true -- 折行

opt.scrolloff = 7 -- 与下面隔7行的距离

-- 设置撤销文件存储目录（需手动创建）
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.undofile = true -- 启用持久化撤销（保存撤销历史到文件）

-- 让所有模式的光标都是块状
-- opt.guicursor = "n-v-c-i:block"

-- 设置制表符为 4 个空格
opt.expandtab = true -- 用空格代替 Tab
opt.tabstop = 2 -- 一个 Tab 显示为 4 个空格
opt.shiftwidth = 2 -- 自动缩进时使用 4 个空格
opt.softtabstop = 2 -- 退格时删除 4 个空格


-- opt.listchars:append({ space = "-" }) -- 把空格显示成别的符号
-- opt.list = true
