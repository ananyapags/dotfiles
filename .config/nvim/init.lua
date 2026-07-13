-- ============ Core options ============
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8
vim.opt.mouse = "a"
vim.opt.updatetime = 250
vim.opt.signcolumn = "yes"

-- ============ Bootstrap lazy.nvim ============
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============ Plugins ============
require("lazy").setup({
  -- Colorschemes
  { "navarasu/onedark.nvim", priority = 1000,
    config = function()
      require("onedark").setup({ style = "darker" })
      require("onedark").load()
    end },
  { "folke/tokyonight.nvim", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },

  { "christoomey/vim-tmux-navigator" },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Grep" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols (file)" },
      { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Symbols (repo)" },
    },
  },

  -- File tree
  { "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" } },
    config = function() require("nvim-tree").setup() end,
  },

  -- Syntax highlighting
  { "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "bash", "rust", "go", "json", "markdown", "cpp", "c" },
        highlight = { enable = true },
      })
    end,
  },

  -- Indent guides
  { "lukas-reineke/indent-blankline.nvim", main = "ibl",
    config = function()
      require("ibl").setup({ scope = { enabled = true, show_start = false } })
    end,
  },

  -- ===== LSP (new Nvim 0.11 API) =====
  { "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      { "mason-org/mason-lspconfig.nvim" },
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Install servers via Mason; mason-lspconfig auto-enables them
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "rust_analyzer", "clangd" },
      })

      local caps = require("cmp_nvim_lsp").default_capabilities()

      -- Give every server the completion capabilities
      vim.lsp.config("*", { capabilities = caps })

      -- Python: point pyright at the ACTIVE pixi/conda env's python if present
      vim.lsp.config("pyright", {
        before_init = function(_, config)
          local env = os.getenv("CONDA_PREFIX") or os.getenv("VIRTUAL_ENV")
          if env then
            config.settings = config.settings or {}
            config.settings.python = { pythonPath = env .. "/bin/python" }
          end
        end,
      })

      -- LSP keymaps (active when a server attaches to a buffer)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local b = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, b)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, b)
          vim.keymap.set("n", "K",  vim.lsp.buf.hover, b)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, b)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, b)
          vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, b)
          vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, b)
        end,
      })
    end,
  },

  -- ===== Autocomplete =====
  { "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping.select_next_item(),
          ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
})

-- Theme switcher: Space + t + c opens a live-preview theme picker
vim.keymap.set("n", "<leader>tc", "<cmd>Telescope colorscheme enable_preview=true<cr>", { desc = "Change theme" })

-- GUI-editor-style selection (Shift+arrows to select, Backspace deletes)
vim.opt.selectmode = "key"
vim.opt.keymodel   = "startsel,stopsel"
vim.opt.selection  = "exclusive"
