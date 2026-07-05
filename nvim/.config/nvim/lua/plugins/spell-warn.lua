return {
  {
    'ravibrock/spellwarn.nvim',
    event = 'VeryLazy',
    opts = {
      severity = {
        spellbad = 'WARN',
        spellcap = 'HINT',
        spelllocal = 'HINT',
        spellrare = 'INFO',
      },
      ft_default = true,
      -- SWAP TO THE LUA ITERATOR ENGINE FOR CODE BUFFERS
      ft_config = {
        default = 'iter', -- Use tree-sitter aware lua iterator
        lazy = false,
        mason = false,
      },
    },
    config = function(_, opts)
      vim.opt.spelllang = 'en_us'
      vim.opt.spell = true
      require('spellwarn').setup(opts)
    end,
  },
}
