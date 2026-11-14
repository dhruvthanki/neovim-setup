-- Autocmds are automatically loaded on the VeryLazy event, after LazyVim's defaults:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Only autocmds that differ from or add to LazyVim's defaults belong here.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Transparent background support
-- Set to true to enable transparent background
local transparent_background = false

if transparent_background then
  autocmd("ColorScheme", {
    group = augroup("transparent_bg", { clear = true }),
    callback = function()
      local hl_groups = {
        "Normal",
        "NormalNC",
        "NormalFloat",
        "SignColumn",
        "EndOfBuffer",
        "NeoTreeNormal",
        "NeoTreeNormalNC",
        "NeoTreeEndOfBuffer",
      }
      for _, group in ipairs(hl_groups) do
        vim.api.nvim_set_hl(0, group, { bg = "NONE" })
      end
    end,
  })
end

-- Disable line numbers in terminal
autocmd("TermOpen", {
  group = augroup("terminal_settings", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Check if we need to reload the file when it changed
-- Extended events (beyond LazyVim's) for better auto-reload with the Claude Code workflow
autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = augroup("checktime", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})
