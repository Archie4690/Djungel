-- Set space to leader
vim.g.mapleader = " "

-- Options
vim.opt.linebreak = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
vim.opt.scrolloff = 8
vim.opt.conceallevel = 2
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Auto Download lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-tree/nvim-tree.lua" },
  { "folke/zen-mode.nvim"},
  { "akinsho/bufferline.nvim" },
  { "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "markdown" },
  config = function()
    require("render-markdown").setup()
  end,
  },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function()
    require("nvim-treesitter.config").setup({
      ensure_installed = { "lua", "python", "javascript", "typescript", "json", "yaml", "bash", "markdown" },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "neovim/nvim-lspconfig" },
  { "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        { name = "Envcyclopedia", path = "~/p/c/Envcyclopedia" },
      },
    },
  },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "folke/which-key.nvim", config = function()
    require("which-key").setup()
  end },
  { "lukas-reineke/indent-blankline.nvim", config = function()
    require("ibl").setup()
  end },
  { "lewis6991/gitsigns.nvim", config = function()
    require("gitsigns").setup()
  end },
  { "nvim-lualine/lualine.nvim", config = function()
    require("lualine").setup()
  end },
  { "windwp/nvim-autopairs", config = function()
    require("nvim-autopairs").setup()
  end },
  { "NvChad/nvim-colorizer.lua", config = function()
    require("colorizer").setup()
  end },
})
local builtin = require("telescope.builtin")
require("telescope").setup({
  defaults = {
    file_ignore_patterns = { ".venv/", "node_modules/" },
    sorting_strategy = "ascending",
    layout_strategy = "center",
    layout_config = {
      center = {
        width = 0.5,
        height = 0.35,
        preview_cutoff = 0,
      },
    },
  },
  pickers = {
    find_files = {
      cwd = vim.fn.expand("~"),
      find_command = {
        "fd", "--type", "f", "--hidden",
        "--exclude", ".git",
        "--exclude", ".venv",
        "--exclude", "node_modules",
        "--exclude", ".claude",
        "--exclude", ".npm",
        "--exclude", ".local",
        "--exclude", ".cache",
        "--exclude", ".mozilla",
        "--exclude", ".cargo",
        "--exclude", ".rustup",
        "--exclude", ".ssh",
        "--exclude", ".gnupg",
        "--exclude", ".gradle",
        "--exclude", "region",
        "--exclude", "griefdefender",
      },
    },
  },
})
require("bufferline").setup()
require("nvim-tree").setup({
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    local opts = { buffer = bufnr, noremap = true, silent = true }
    api.map.on_attach.default(bufnr)
    vim.keymap.set("n", "l", function()
      api.node.open.edit()
      api.tree.focus()
    end, opts)
    vim.keymap.set("n", "h", api.node.navigate.parent_close, opts)
    vim.keymap.set("n", "<Esc>", function()
      api.node.open.edit()
      api.tree.close()
    end, opts)
  end,
})
-- LSP
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "lua_ls", "ts_ls", "jsonls", "yamlls", "bashls", "marksman" },
  automatic_enable = true,
})
local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

-- Completion
local cmp = require("cmp")
cmp.setup({
  sources = {
    { name = "nvim_lsp", max_item_count = 10 },
    { name = "buffer",   max_item_count = 5, keyword_length = 3 },
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"]     = cmp.mapping.abort(),
    ["<CR>"]      = cmp.mapping.confirm({ select = false }),
    ["<Tab>"]     = cmp.mapping.select_next_item(),
    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
  }),
  completion = { autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged } },
})

-- Run file in floating terminal
local function run_file()
  local ft = vim.bo.filetype
  local runners = {
    python     = "python3",
    javascript = "node",
    typescript = "ts-node",
    bash       = "bash",
    sh         = "bash",
    lua        = "lua",
    markdown = "glow",
  }
  local runner = runners[ft]
  if not runner then
    vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN)
    return
  end
  local ext = vim.fn.expand("%:e")
  local tmpfile = vim.fn.tempname() .. (ext ~= "" and ("." .. ext) or "")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.fn.writefile(lines, tmpfile)
  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = math.floor((vim.o.lines - height) / 2),
    col      = math.floor((vim.o.columns - width) / 2),
    style    = "minimal",
    border   = "rounded",
  })
  vim.fn.termopen(runner .. " " .. vim.fn.shellescape(tmpfile))
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n><cmd>bdelete!<CR>", { buffer = buf })
  vim.cmd("startinsert")
end

-- Keybinds
vim.keymap.set('v', 'j', 'gj')
vim.keymap.set('v', 'k', 'gk')
vim.keymap.set('v', 'gj', 'j')
vim.keymap.set('v', 'gk', 'k')
vim.keymap.set('n', 'gj', 'j')
vim.keymap.set('n', 'gk', 'k')
vim.keymap.set({"n", "v", "o"}, "H", "^", { desc = "Start of line" })
vim.keymap.set({"n", "v", "o"}, "L", "$", { desc = "End of line" })
vim.keymap.set("n", "j", "v:count > 5 ? 'jzz' : 'gj'", { expr = true })
vim.keymap.set("n", "k", "v:count > 5 ? 'kzz' : 'gk'", { expr = true })
vim.keymap.set("n", "}", "}zz", { desc = "Next paragraph centred" })
vim.keymap.set("n", "{", "{zz", { desc = "Prev paragraph centred" })
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { desc = "Go to definition" })
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    require("bufferline").go_to(i, true)
  end, { desc = "Buffer " .. i })
end
vim.keymap.set("i", "jk", "<Esc>", {})
vim.keymap.set("n", ";", ":", {})
vim.keymap.set("n", "<space><space>", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader><Right>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader><Left>", ":BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "<leader><Down>", ":bdelete<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>h", vim.diagnostic.open_float, { desc = "Show diagnostic" })
vim.keymap.set("n", "<leader><CR>", run_file, { desc = "Run file" })
vim.keymap.set("n", "<leader><Esc>", ":nohlsearch<CR>", { desc = "Clear highlights" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save" })
vim.keymap.set("n", "<leader><Delete>", ":q!<CR>", { desc = "Force quit" })
local function make_wrapper(open, close)
  return function()
    vim.cmd('normal! "zy')
    local text = vim.fn.getreg('z')
    if text:sub(1, #open) == open and text:sub(-#close) == close then
      vim.fn.setreg('z', text:sub(#open + 1, -(#close + 1)))
    else
      vim.fn.setreg('z', open .. text .. close)
    end
    vim.cmd('normal! gv"zp')
    vim.cmd('normal! `[v`]')
  end
end
vim.keymap.set("v", "(", make_wrapper("(", ")"), { desc = "Toggle () wrap" })
vim.keymap.set("v", "{", make_wrapper("{", "}"), { desc = "Toggle {} wrap" })
vim.keymap.set("v", "[", make_wrapper("[", "]"), { desc = "Toggle [] wrap" })
vim.keymap.set("v", '"', make_wrapper('"', '"'),  { desc = 'Toggle "" wrap' })
vim.keymap.set("v", "'", make_wrapper("'", "'"),  { desc = "Toggle '' wrap" })
vim.keymap.set("n", "<leader>q", function()
  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = math.floor((vim.o.lines - height) / 2),
    col      = math.floor((vim.o.columns - width) / 2),
    style    = "minimal",
    border   = "rounded",
  })
  vim.fn.termopen(vim.o.shell, { cwd = vim.fn.getcwd() })
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n><cmd>bdelete!<CR>", { buffer = buf })
  vim.cmd("startinsert")
end, { desc = "Open terminal" })
vim.cmd("command! W w")
vim.cmd("command! Q q")
vim.cmd("command! WQ wq")
vim.cmd("command! Wq wq")
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function() io.write("\027[2 q") end
})
vim.api.nvim_create_autocmd("FocusLost", {
  callback = function() io.write("\027[1 q") end
})

-- Misc Changes
vim.opt.clipboard = "unnamedplus"
vim.cmd.colorscheme("retrobox")

