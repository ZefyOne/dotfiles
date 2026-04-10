local api = vim.api
local win = {}

-- 根据opts的值，决定返回值。通常返回NW
-- 正高度 → 锚点在上方（N），负高度 → 锚点在下方（S）
-- 正宽度 → 锚点在左侧（W），负宽度 → 锚点在右侧（E）
---@param opts table
---@return string anchor
local function make_floating_popup_anchor(opts)
  local anchor = ""

  anchor = anchor .. (opts.height >= 0 and "N" or "S")
  anchor = anchor .. (opts.width >= 0 and "W" or "E")

  return anchor or "NW"
end

---set folating window's size
---@param opts table
---@param ui table {height: integer, width:integer}
---@return integer width
---@return integer height
local function make_floating_popup_size(opts, ui)
  -- math.abs返回参数的绝对值
  opts.width, opts.height = math.abs(opts.width), math.abs(opts.height)

  -- math.floor()向下取整
  opts.width = opts.width < 1 and math.floor(ui.width * opts.width + 0.5) or opts.width
  opts.height = opts.height < 1 and math.floor(ui.height * opts.height + 0.5) or opts.height

  -- math.min()返回几个参数中的最小值
  opts.height, opts.width = math.min(opts.height, ui.height), math.min(opts.width, ui.width)

  return opts.width, opts.height
end

-- 返回行列的值
---get windows position
---@param opts table {row: char|integer, col: char|integer}
---@param ui table {height: integer, width:integer}
---@return integer row
---@return integer col
local function get_position(opts, ui)
  local row, col

  -- 设置行row的值，如果它是number类型，直接赋值，c表示在中间
  if type(opts.row) == "number" then
    row = opts.row
  elseif opts.row == "c" then
    row = math.floor((ui.height - opts.height) / 2 - 1) -- 修改窗口的高度，1变成0.5高度降低
  elseif opts.row == "t" then
    row = 0
  elseif opts.row == "b" then
    row = ui.height - 1
  end

  -- 设置列col的值
  if type(opts.col) == "number" then
    col = opts.col
  elseif opts.col == "c" then
    col = math.floor((ui.width - opts.width) / 2 + 0.5)
  elseif opts.col == "l" then
    col = 0
  elseif opts.col == "r" then
    col = ui.width
  end

  return row, col
end

---float window's config
---@param opts table
---@return table
local function make_floating_popup_options(opts)
  -- nvim_list_uis()用于获取当前附加到 Neovim 实例的所有 ​UI（用户界面）​ 的信息。
  -- 它返回一个包含 UI 配置的列表，每个 UI 通常对应一个终端或 GUI 客户端窗口
  local ui = api.nvim_list_uis()[1]
  local anchor = opts.anchor or make_floating_popup_anchor(opts)
  opts.width, opts.height = make_floating_popup_size(opts, ui)
  local row, col = get_position(opts, ui)

  return {
    anchor = anchor,
    bufpos = opts.relative == "win" and opts.bufpos or nil,
    row = row,
    col = col,
    focusable = opts.focusable or true,
    relative = opts.relative or "cursor",
    style = "minimal",
    width = opts.width,
    height = opts.height,
    border = opts.border or "rounded",
    title = opts.title or "",
    title_pos = opts.title_pos or "center",
    zindex = opts.zindex or 50,
    noautocmd = opts.noautocmd or false,
  }
end

---default window's config
---@return table
local function default()
  return {
    style = "minimal",
    border = "rounded",
    noautocmd = false,
  }
end

local obj = {}
obj.__index = obj

---set bufopt
---@param name string|table
---@param value any
---@return table
function obj:bufopt(name, value)
  if type(name) == "table" then
    for key, val in pairs(name) do
      api.nvim_set_option_value(key, val, { buf = self.bufnr })
    end
  else
    api.nvim_set_option_value(name, value, { buf = self.bufnr })
  end
  return self
end

---get window's information
---@return integer bunnr
---@return integer winid
function obj:wininfo()
  return self.bufnr, self.winid
end

---creat float window
---@param float_opt table
---@param enter boolean
---@param force boolean
---@return table
function win:new_float(float_opt, enter, force)
  enter = enter or false

  -- buffer reuse
  self.bufnr = float_opt.bufnr or api.nvim_create_buf(false, false)
  float_opt.bufnr = nil
  float_opt = force and make_floating_popup_options(float_opt) or vim.tbl_extend("force", default(), float_opt)
  self.winid = api.nvim_open_win(self.bufnr, enter, float_opt)
  return setmetatable(win, obj)
end

return win
