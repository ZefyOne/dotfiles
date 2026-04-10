-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- 写作模式
require("mode.novel").setup()

-- 自动保存文件，光标静止后五分钟
require("tools.auto_save")

-- 主题
-- vim.o.termguicolors = true
-- vim.g.PaperColor_Theme_Options = {
--   theme = {
--     default = {
--       override = {
--         color00 = '#bcdbbb',  -- WPS护眼绿背景
--       }
--     }
--   }
-- }
-- vim.cmd.colorscheme("tokyonight-moon")

local currentTime = os.time()
local hour = tonumber(os.date("%H", currentTime))
if hour >= 18 then
  vim.cmd.colorscheme("tokyonight-moon")
else
  vim.cmd.colorscheme("everforest")
end
