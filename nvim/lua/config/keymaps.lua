-- Keymaps are automatically loaded on the VeryLazy event, after LazyVim's defaults:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Only keymaps that differ from or add to LazyVim's defaults belong here.

local map = vim.keymap.set

-- Windows
map("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
map("n", "<leader>w-", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>w|", "<C-W>v", { desc = "Split window right", remap = true })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Keep search results centered (overrides LazyVim's n/N)
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Paste without losing register content
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Terminal mappings
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

-- <C-hjkl> moves between nvim windows; at the edge of nvim's layout, hand off to the
-- Rex pane in that direction (only when running inside Rex). Set vim.g.rex_bin to
-- override the `rex` executable.
local rex_directions = { h = "left", j = "down", k = "up", l = "right" }
for key, direction in pairs(rex_directions) do
  map({ "n", "t" }, "<C-" .. key .. ">", function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. key)
    local session = vim.env.REX_SESSION
    if vim.api.nvim_get_current_win() == win and session and session ~= "" then
      vim.system({ vim.g.rex_bin or "rex", "focus", direction, "-s", session })
    end
  end, { desc = "Go to " .. direction .. " window / Rex pane" })
end
