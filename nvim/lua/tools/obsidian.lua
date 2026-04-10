local M = {}

function M.setup()
  local filepath = vim.fn.expand("%:p") -- 获取当前文件的完整路径
  if filepath == "" then
    vim.notify("No file is currently open", vim.log.levels.ERROR)
    return
  end

  -- 检查文件是否存在
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File does not exist: " .. filepath, vim.log.levels.ERROR)
    return
  end

  -- 构建Typora打开命令
  local cmd
  local app = " obsidian "
  -- local app = "typora"
  if vim.fn.has("mac") == 1 then
    cmd = "open -a" .. app .. vim.fn.shellescape(filepath)
  elseif vim.fn.has("unix") == 1 then
    cmd = app .. vim.fn.shellescape(filepath) .. " &"
  else
    vim.notify("Unsupported platform for Typora plugin", vim.log.levels.ERROR)
    return
  end

  -- 执行命令
  vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to open Typora. Make sure it is installed.", vim.log.levels.ERROR)
  end
end

return M
