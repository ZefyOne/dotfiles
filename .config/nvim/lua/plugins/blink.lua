return {
  "saghen/blink.cmp",
  -- enabled = false,
  opts = {
    keymap = {
      preset = "default", -- 或 'enter', 'super-tab' 等，根据你的预设来
      ["<CR>"] = { "fallback" }, -- 覆盖回车键，只使用默认行为
      ["<Tab>"] = { "accept", "fallback" }, -- 覆盖回车键，只使用默认行为
    },
  },
}
