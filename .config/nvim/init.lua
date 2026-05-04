-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- 写作模式
require("mode.novel").setup()

-- 自动保存文件，光标静止后五分钟
require("tools.auto_save")

-- 护眼主题
-- require("theme.EyeProtection")

vim.cmd.colorscheme("tokyonight-moon")
