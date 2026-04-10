local M = {}

local server_job_id, client_job_id, client_bufnr, client_win
local SERVER_PORT = 8299

local function log(msg)
  vim.schedule(function()
    vim.notify('[opencode] ' .. msg, vim.log.levels.INFO)
  end)
end

local function err(msg)
  vim.schedule(function()
    vim.notify('[opencode] ERROR: ' .. msg, vim.log.levels.ERROR)
  end)
end

local function resolve_executable(name, candidates)
  if vim.fn.executable(name) == 1 then
    return name
  end
  for _, candidate in ipairs(candidates) do
    if vim.fn.filereadable(candidate) == 1 or vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

function M._get_plugin_root()
  local info = debug.getinfo(1, 'S')
  local source = info.source:sub(2)
  return vim.fn.fnamemodify(source, ':h:h:h')
end

function M.maybe_start_server()
  if server_job_id ~= nil then
    return
  end

  local server_cmd = resolve_executable('opencode', {
    M._get_plugin_root() .. '/bin/opencode',
  })
  if not server_cmd then
    err('opencode not found. Install it or ensure it is in PATH.')
    return
  end

  log('Starting opencode server on port ' .. SERVER_PORT .. '...')

  server_job_id = vim.fn.jobstart({
    server_cmd,
    'serve',
    '--port', tostring(SERVER_PORT),
  }, {
    env = {
      OPENCODE_SERVER_PASSWORD = '111',
    },
    on_stderr = function(_, data)
      if data and data[1] and data[1]:match('%S') then
        vim.schedule(function()
          vim.notify('[opencode serve] ' .. table.concat(data, '\n'), vim.log.levels.WARN)
        end)
      end
    end,
  })

  if server_job_id <= 0 then
    err('Failed to start opencode serve')
    server_job_id = nil
    return
  end

  log('OpenCode server started (job_id=' .. server_job_id .. ')')
end

local function create_client_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, 'opencode-client')
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = bufnr })
  return bufnr
end

local function ensure_client_buf()
  if client_bufnr == nil or not vim.api.nvim_buf_is_valid(client_bufnr) then
    client_bufnr = create_client_buffer()
    vim.api.nvim_buf_set_lines(client_bufnr, 0, -1, false, {
      'OpenCode Client',
      '==============',
      '',
      'Connecting to OpenCode server...',
      '',
      'Press <space>k again to hide this window.',
    })
  end
  return client_bufnr
end

local function open_floating_window()
  local bufnr = ensure_client_buf()
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.7)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' OpenCode ',
    title_pos = 'center',
  }

  client_win = vim.api.nvim_open_win(bufnr, true, win_opts)
  vim.api.nvim_set_option_value('wrap', true, { scope = 'local', win = client_win })
  vim.api.nvim_set_option_value('scrollbind', false, { scope = 'local', win = client_win })
end

local function close_floating_window()
  if client_win and vim.api.nvim_win_is_valid(client_win) then
    vim.api.nvim_win_close(client_win, true)
    client_win = nil
  end
end

local function maybe_start_client()
  if client_job_id ~= nil then
    return
  end

  local client_cmd = resolve_executable('opencode', {
    M._get_plugin_root() .. '/bin/opencode',
  })
  if not client_cmd then
    err('opencode not found. Install it or ensure it is in PATH.')
    return
  end

  log('Starting opencode client...')

  local function on_exit()
    vim.schedule(function()
      log('opencode client closed')
      client_job_id = nil
    end)
  end

  client_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(client_bufnr, 'opencode-' .. client_bufnr)

  client_win = vim.api.nvim_open_win(client_bufnr, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.85),
    height = math.floor(vim.o.lines * 0.7),
    row = math.floor((vim.o.lines - math.floor(vim.o.lines * 0.7)) / 2),
    col = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.85)) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' OpenCode ',
    title_pos = 'center',
  })

  client_job_id = vim.fn.termopen({
    client_cmd,
    'attach',
    'http://localhost:' .. SERVER_PORT,
    '-p', '111',
    '-c',
  }, {
    on_exit = on_exit,
  })

  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = client_bufnr })
  vim.cmd('startinsert')
end

function M._cleanup()
  log('Cleaning up OpenCode...')

  if client_job_id then
    vim.fn.jobstop(client_job_id)
    client_job_id = nil
  end

  close_floating_window()

  if client_bufnr and vim.api.nvim_buf_is_valid(client_bufnr) then
    vim.api.nvim_buf_delete(client_bufnr, { force = true })
    client_bufnr = nil
  end

  if server_job_id then
    vim.fn.jobstop(server_job_id)
    server_job_id = nil
  end

  log('OpenCode cleanup complete.')
end

function M.toggle_client()
  if client_job_id ~= nil then
    vim.fn.jobstop(client_job_id)
    client_job_id = nil
    if client_win and vim.api.nvim_win_is_valid(client_win) then
      vim.api.nvim_win_close(client_win, true)
      client_win = nil
    end
    log('OpenCode closed.')
    return
  end

  M.maybe_start_server()
  maybe_start_client()
end

return M
