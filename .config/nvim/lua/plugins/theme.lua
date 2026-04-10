return {
  -- 其他插件...
  {
    "sainnhe/everforest",
    priority = 1000, -- 确保这个插件在其他插件之前加载
    config = function()
      -- vim.g.everforest_style = "light"
      -- vim.g.everforest_background = "soft"
      -- vim.g.everforest_enable_italic = true
      vim.g.everforest_background = "soft" -- 可选值: 'hard', 'medium', 'soft'
      vim.opt.background = "light"
    end,
  },
  -- 其他插件...
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "NLKNguyen/papercolor-theme",
  },
}
