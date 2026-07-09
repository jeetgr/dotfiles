require 'core.options'
require 'core.keymaps'

require 'config.lazy'

vim.cmd.colorscheme 'catppuccin-nvim'

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
  end,
})
