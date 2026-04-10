local M = {}

local last_line, last_col = vim.fn.line("."), vim.fn.col(".")
--- 检测光标是否移动，移动则返回 true
---@return boolean
local function is_cursor_moved()
  local current_line, current_col = vim.fn.line("."), vim.fn.col(".")
  if current_line ~= last_line or current_col ~= last_col then
    last_line, last_col = current_line, current_col
    return true
  end
  return false
end

function M.setup()
  vim.keymap.set("i", "<C-n>", "<Down>")
  vim.keymap.set("i", "<C-p>", "<Up>")
  local name = vim.fn.expand("%:e")
  if name == "md" or name == "txt" or name == "nov" then
    -- 设置缩进，这样只显示一条缩进线
    vim.opt.shiftwidth = 4 -- Size of an indent
    -- vim.cmd.colorscheme("peachpuff")

    -- 获取原有配置避免覆盖
    local current_config = require("lualine").get_config()
    -- 深度合并配置
    local new_config = vim.tbl_deep_extend("force", current_config, {
      sections = {
        lualine_x = {
          "location",
        },
        lualine_y = {
          {
            function()
              local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
              local num = require("tools.get_buffer_length").setup(content)

              if vim.fn.mode():find("^[vV]") then -- 匹配所有可视模式
                -- 获取选区起始位置（进入可视模式时的位置）
                local start_pos = vim.fn.getpos("v")
                -- 获取当前光标位置
                local end_pos = vim.fn.getpos(".")

                -- 确保起始行 <= 结束行
                local start_line = math.min(start_pos[2], end_pos[2])
                local end_line = math.max(start_pos[2], end_pos[2])

                -- 获取选区内容
                local contentNew = table.concat(vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false), "")
                local numNew = require("tools.get_buffer_length").setup(contentNew)

                return "字数: " .. numNew .. "/" .. num
              else
                return "字数: " .. num
              end
            end,
            -- 添加缓存优化（每 5 秒刷新一次）
            cache = { interval = 5000 },
          },
        },
      },
    })
    require("lualine").setup(new_config)
  end
end

return M
