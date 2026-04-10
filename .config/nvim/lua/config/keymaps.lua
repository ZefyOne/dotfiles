-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap.set

-- n模式 --
-- keymap("n", "<C-h>", "^")
-- keymap("n", "<C-l>", "$")


-- i模式 --
-- move
keymap("i", "<C-a>", "<esc>^i")
keymap("i", "<C-e>", "<esc>$a")
keymap("i", "<C-f>", "<Right>")
keymap("i", "<C-b>", "<Left>")
keymap("i", "<C-l>", "<Right><Backspace>")

keymap("i", "<C-s>", "<esc><cmd>w<cr>a")

-- 操作符


-- Yazi
keymap("n", "<leader>e", function()
  vim.cmd("Yazi")
end, { desc = "打开yazi" })
keymap("t", "<leader>e", "q")
keymap("t", "<esc>", "<C-\\><C-n>")

-- 写文
keymap("n", "<leader>ta", "<cmd>%s/\\.\\./\\r\\r▲/g|%s/\\./\\r\\r/g|noh<CR>", { desc="格式化整个集纲为正文" })
keymap("n", "<leader>to", "<cmd>s/ /./g|noh<CR>", { desc="一个空格换成点" })
keymap("n", "<leader>tn1", "jdjkdiwkko<CR>1-1<CR><CR>日/内<CR><CR>场景：<ESC>po<ESC>", { desc="开头替换" })
keymap("n", "<leader>tn2", "jdjkdiwkko<CR>1-2<CR><CR>日/内<CR><CR>场景：<ESC>po<ESC>", { desc="开头替换" })
keymap("n", "<leader>tw1", "jdjkdiwkko<CR>1-1<CR><CR>日/外<CR><CR>场景：<ESC>po<ESC>", { desc="开头替换" })
keymap("n", "<leader>tw2", "jdjkdiwkko<CR>1-2<CR><CR>日/外<CR><CR>场景：<ESC>po<ESC>", { desc="开头替换" })

keymap("n", ",e", "ce（）<ESC>P", { desc="加括号" })
-- keymap("v", "<leader>", "<cmd>s/\\%V.*\\%V./（&）/|noh<CR><ESC>") --与上一个功能相同，但开销更大
keymap("n", ",w", "df）", { desc="删括号" })




