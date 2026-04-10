local my_source = {}

function my_source.new()
  return setmetatable({}, { __index = my_source })
end

function my_source:complete(params, callback)
  local key = params.context.cursor_before_line:sub(params.offset) -- 获取输入字符
  local items = {}

  -- 模拟五笔码表查询
  local wubi_map = {
    ds = "别",
    mn = "你",
    wj = "好", -- 字母组合映射
  }

  if wubi_map[key] then
    items = { { label = wubi_map[key], kind = 1 } } -- 生成补全项
  end

  callback(items) -- 返回结果
end
return my_source
