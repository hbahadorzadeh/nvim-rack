if vim.g.loaded_hanger then return end
vim.g.loaded_hanger = true

vim.api.nvim_create_user_command("Hanger", function()
  require("hanger").setup()
  require("hanger").toggle()
end, { desc = "Open the Hanger toolbar" })
