local output = vim.env.NVIM_PARITY_OUTPUT
if not output or output == "" then error("NVIM_PARITY_OUTPUT must name the output JSON file") end

vim.defer_fn(function()
  local parser_ok, parser = pcall(vim.treesitter.get_parser, 0)
  local parser_available = parser_ok and parser ~= nil
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(clients, client.name)
  end
  table.sort(clients)

  local commands = {}
  for _, command in ipairs({
    "Jupytext",
    "MarkdownPreview",
    "RStart",
    "RSendLine",
    "VenvSelect",
  }) do
    commands[command] = vim.fn.exists(":" .. command) > 0
  end

  local result = {
    commands = commands,
    filetype = vim.bo.filetype,
    lspClients = clients,
    messages = vim.api.nvim_exec2("messages", { output = true }).output,
    parser = parser_available and parser:lang() or nil,
    parserError = parser_available and nil or tostring(parser),
    r = {
      executable = vim.fn.executable("R") == 1,
      enterMapping = vim.fn.maparg("<Enter>", "n") ~= "",
      module = pcall(require, "r"),
    },
  }
  vim.fn.writefile({ vim.json.encode(result) }, output)
  vim.cmd("qa!")
end, 7000)
