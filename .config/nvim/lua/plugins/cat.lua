return {
  {
    -- 主题
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false, -- 启动时立即加载
    priority = 1000, -- 确保在其他插件之前加载
    opts = {
      flavour = "frappe", -- 默认风格
      transparent_background = false, -- 是否透明背景
      integrations = {
        telescope = true,
        mason = true,
        treesitter = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
    end,
  },
}
