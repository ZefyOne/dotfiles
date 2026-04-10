return {
  "folke/flash.nvim",
  opts = function()
    -- 取消 Normal/Visual/Operator-pending 模式下的 s 键
    vim.keymap.del({ "n", "x", "o" }, "s")
    -- 把s的功能换成x
    vim.keymap.set({ "n", "x", "o" }, "x", function()
      require("flash").jump()
    end)
  end,
}
