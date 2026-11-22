local config_home = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h")
vim.cmd.source(config_home .. "/vim/shared.vim")
