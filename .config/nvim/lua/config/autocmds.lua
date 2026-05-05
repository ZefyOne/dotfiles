-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.nov", "*.md", "*.txt" }, -- 直接匹配 .nov 后缀
  callback = function()
    vim.opt_local.spell = false -- 禁用拼写检查，这样不会标红
  end,
})

-- 监听模式变化，刚切换就触发。
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    local current_mode = vim.fn.mode()
    local ft = vim.bo.filetype

    if current_mode == "i" then
      -- 只有特定文件类型才切中文
      if ft == "markdown" or ft == "text" then
        vim.fn.system("fcitx5-remote -s rime")
      end
      -- 其他文件进入 i 模式什么都不做
    elseif current_mode == "n" then
      -- 所有文件回 n 模式都切英文
      vim.fn.system("fcitx5-remote -s keyboard-us")
    end
  end,
})

-- custom
local uc = vim.api.nvim_create_user_command

-- 打开Yazi
uc("Yazi", function()
  require("tools.open_yazi").yazi("edit")
  vim.cmd("normal! a")
end, {})

-- 打开Obsidian
uc("Obsidian", require("tools.obsidian").setup, {})
-- custom function
