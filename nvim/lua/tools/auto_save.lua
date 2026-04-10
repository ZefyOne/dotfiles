local idle_tracker = {
  last_mode = nil, -- 上次的模式
  last_pos = { 0, 0 }, -- 上次光标位置 [行, 列]
  last_time = vim.loop.now(), -- 上次变化时间戳
  timer = nil, -- 定时器对象
  timeout = 1 * 1000, -- 超时时间（5秒）
  enabled = true, -- 功能开关
  last_save_time = 0, -- 上次保存时间（避免频繁保存）
  min_save_interval = 30 * 1000, -- 最小保存间隔（30秒）
}

-- 获取当前模式
local function get_current_mode()
  local mode = vim.api.nvim_get_mode().mode
  -- 简化模式表示
  if mode:match("[vV]") then
    return "visual"
  elseif mode == "i" then
    return "insert"
  elseif mode == "c" then
    return "command"
  elseif mode == "t" then
    return "terminal"
  else
    return "normal"
  end
end

-- 检查模式和位置是否变化
local function check_idle_state()
  if not idle_tracker.enabled then
    return
  end

  local current_mode = get_current_mode()
  local current_pos = { vim.fn.line("."), vim.fn.col(".") }
  local current_time = vim.loop.now()

  -- 检查模式或位置是否变化
  local mode_changed = current_mode ~= idle_tracker.last_mode
  local pos_changed = current_pos[1] ~= idle_tracker.last_pos[1] or current_pos[2] ~= idle_tracker.last_pos[2]

  -- 如果有变化，更新记录
  if mode_changed or pos_changed then
    idle_tracker.last_mode = current_mode
    idle_tracker.last_pos = current_pos
    idle_tracker.last_time = current_time
    return
  end

  -- 检查是否超时且满足保存条件
  local time_since_change = current_time - idle_tracker.last_time
  local time_since_last_save = current_time - idle_tracker.last_save_time

  if time_since_change > idle_tracker.timeout and time_since_last_save > idle_tracker.min_save_interval then
    -- 检查文件是否被修改
    if vim.bo.modified and vim.bo.buftype == "" then -- 只保存普通缓冲区
      vim.cmd("silent write")
      idle_tracker.last_save_time = current_time
      print(string.format("自动保存: %s (模式: %s)", vim.fn.expand("%"), current_mode))
    end
  end
end

-- 初始化模式记录
idle_tracker.last_mode = get_current_mode()
idle_tracker.last_pos = { vim.fn.line("."), vim.fn.col(".") }

-- 设置定时器（每5秒检查一次）
idle_tracker.timer = vim.loop.new_timer()
idle_tracker.timer:start(0, 5000, vim.schedule_wrap(check_idle_state))

-- 在缓冲区切换时重置追踪
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*",
  callback = function()
    idle_tracker.last_mode = get_current_mode()
    idle_tracker.last_pos = { vim.fn.line("."), vim.fn.col(".") }
    idle_tracker.last_time = vim.loop.now()
  end,
})

-- 添加命令来启用/禁用功能
vim.api.nvim_create_user_command("IdleSaveToggle", function()
  idle_tracker.enabled = not idle_tracker.enabled
  print("闲置自动保存 " .. (idle_tracker.enabled and "启用" and "禁用"))
end, {})

-- 添加命令来查看当前状态
vim.api.nvim_create_user_command("IdleSaveStatus", function()
  local status = idle_tracker.enabled and "启用" or "禁用"
  local mode = get_current_mode()
  local pos = idle_tracker.last_pos
  print(string.format("闲置自动保存: %s | 当前模式: %s | 光标位置: %d,%d", status, mode, pos[1], pos[2]))
end, {})
