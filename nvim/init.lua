-- NeoVim Configuration with LazyVim
-- Bootstrap lazy.nvim and load configuration

-- Set leader key before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Bootstrap lazy.nvim
require("config.lazy")
