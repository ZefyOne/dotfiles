-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.nov", "*.md" }, -- 直接匹配 .nov 后缀
  callback = function()
    vim.opt_local.spell = false -- 禁用拼写检查
  end,
})

-- custom
local uc = vim.api.nvim_create_user_command

-- 打开Yazi
uc("Yazi", function()
  require("tools.open_yazi").yazi("edit")
  vim.cmd("normal! a")
end, {})

-- 打开Typora
uc("Obsidian", require("tools.obsidian").setup, {})
-- custom function
