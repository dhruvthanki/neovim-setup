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
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })
