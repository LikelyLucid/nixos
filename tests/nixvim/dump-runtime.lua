local output = vim.env.NVIM_PARITY_OUTPUT
if not output or output == "" then
  error("NVIM_PARITY_OUTPUT must name the output JSON file")
end

local function sorted_keys(values)
  local keys = vim.tbl_keys(values)
  table.sort(keys)
  return keys
end

local function normalize(value)
  if type(value) == "table" and vim.tbl_isempty(value) then
    return nil
  end
  return value
end

vim.defer_fn(function()
  local result = {
    capabilities = {},
    colorscheme = vim.g.colors_name,
    commands = {},
    keymaps = {},
    options = {},
    parsers = {},
    plugins = {},
    version = vim.version(),
  }

  for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "t", "c" }) do
    for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
      if keymap.desc then
        table.insert(result.keymaps, {
          desc = keymap.desc,
          lhs = keymap.lhs,
          mode = mode,
          rhs = normalize(keymap.rhs),
        })
      end
    end
  end
  table.sort(result.keymaps, function(left, right)
    return (left.mode .. left.lhs .. left.desc) < (right.mode .. right.lhs .. right.desc)
  end)

  for _, name in ipairs({
    "clipboard",
    "completeopt",
    "conceallevel",
    "confirm",
    "cursorline",
    "expandtab",
    "foldexpr",
    "foldlevel",
    "foldmethod",
    "ignorecase",
    "laststatus",
    "mouse",
    "number",
    "relativenumber",
    "scrolloff",
    "shiftwidth",
    "showmode",
    "sidescrolloff",
    "signcolumn",
    "smartcase",
    "splitbelow",
    "splitright",
    "tabstop",
    "termguicolors",
    "timeoutlen",
    "undofile",
    "updatetime",
    "wrap",
  }) do
    result.options[name] = vim.o[name]
  end

  for name, command in pairs(vim.api.nvim_get_commands({ builtin = false })) do
    result.commands[name] = command.definition
  end

  local has_lazy, lazy_config = pcall(require, "lazy.core.config")
  if has_lazy then
    result.plugins = sorted_keys(lazy_config.plugins)
  elseif vim.g.nixvim_plugin_manifest then
    result.plugins = vim.deepcopy(vim.g.nixvim_plugin_manifest)
    table.sort(result.plugins)
  end

  for _, module in ipairs({
    "CopilotChat",
    "blink.cmp",
    "bufferline",
    "conform",
    "copilot",
    "crates",
    "flash",
    "gitsigns",
    "grug-far",
    "jupytext",
    "lazydev",
    "lualine",
    "neo-tree",
    "noice",
    "nvim-treesitter",
    "nvim-treesitter-textobjects",
    "persistence",
    "r",
    "refactoring",
    "render-markdown",
    "rustaceanvim",
    "schemastore",
    "snacks",
    "telescope",
    "todo-comments",
    "trouble",
    "uv",
    "venv-selector",
    "which-key",
    "yanky",
  }) do
    local ok, value = pcall(require, module)
    result.capabilities[module] = { available = ok }
    if not ok then result.capabilities[module].error = tostring(value) end
  end

  local seen_parsers = {}
  for _, parser in ipairs(vim.api.nvim_get_runtime_file("parser/*.so", true)) do
    seen_parsers[vim.fn.fnamemodify(parser, ":t:r")] = true
  end
  result.parsers = sorted_keys(seen_parsers)

  vim.fn.mkdir(vim.fn.fnamemodify(output, ":h"), "p")
  vim.fn.writefile({ vim.json.encode(result) }, output)
  vim.cmd("qa!")
end, 1500)
