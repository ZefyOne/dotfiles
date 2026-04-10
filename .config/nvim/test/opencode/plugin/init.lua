local M = require('custom.opencode.opencode')

vim.keymap.set('n', '<space>k', function()
  M.toggle_client()
end, {
  silent = true,
  desc = 'OpenCode: toggle client',
})

-- Auto-start server on Neovim launch
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    M.maybe_start_server()
  end,
})

-- Cleanup on Neovim exit
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    M._cleanup()
  end,
})
