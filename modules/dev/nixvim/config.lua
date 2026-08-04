local M = {}

local function root()
  local markers = { ".git", "flake.nix", "pyproject.toml", "Cargo.toml", "DESCRIPTION" }
  local found = vim.fs.find(markers, { upward = true, path = vim.api.nvim_buf_get_name(0) })[1]
  return found and vim.fs.dirname(found) or vim.uv.cwd()
end

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function diagnostic_jump(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count * vim.v.count1,
      float = true,
      severity = severity and vim.diagnostic.severity[severity] or nil,
    })
  end
end

local function setup_keymaps()
  map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true })
  map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true })
  map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
  map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
  map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
  map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
  map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
  map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
  map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
  map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
  map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
  map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
  map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
  map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
  map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
  map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
  map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
  map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
  map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
  map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
  map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
  map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })
  map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
  map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
  map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
  map({ "i", "n", "s" }, "<C-b>", "<C-b>", { desc = "Scroll Backward" })
  map({ "i", "n", "s" }, "<C-f>", "<C-f>", { desc = "Scroll Forward" })
  map({ "i", "n", "s" }, "<C-s>", vim.lsp.buf.signature_help, { desc = "vim.lsp.buf.signature_help()" })

  map({ "n", "x" }, "<leader>a", "", { desc = "+ai" })
  map({ "n", "x" }, "<leader>aa", function() require("CopilotChat").toggle() end, { desc = "Toggle (CopilotChat)" })
  map({ "n", "x" }, "<leader>ax", function() require("CopilotChat").reset() end, { desc = "Clear (CopilotChat)" })
  map({ "n", "x" }, "<leader>ap", function() require("CopilotChat").select_prompt() end, { desc = "Prompt Actions (CopilotChat)" })
  map({ "n", "x" }, "<leader>aq", function()
    vim.ui.input({ prompt = "Quick Chat: " }, function(input)
      if input and input ~= "" then require("CopilotChat").ask(input) end
    end)
  end, { desc = "Quick Chat (CopilotChat)" })

  map({ "n", "x" }, "<leader>r", "", { desc = "+refactor" })
  map({ "n", "x" }, "<leader>rs", function() return require("refactoring").select_refactor() end, { desc = "Select Refactor" })
  map({ "n", "x" }, "<leader>ri", function() return require("refactoring").inline_var() end, { desc = "Inline Variable", expr = true })
  map("n", "<leader>rP", function() return require("refactoring.debug").print_loc({ output_location = "below" }) end, { desc = "Debug Print Location", expr = true })
  map({ "n", "x" }, "<leader>rp", function() return require("refactoring.debug").print_var({ output_location = "below" }) .. "iw" end, { desc = "Debug Print Variable", expr = true })
  map("n", "<leader>rc", function() return require("refactoring.debug").cleanup({ restore_view = true }) .. "ag" end, { desc = "Debug Cleanup", expr = true })
  map({ "n", "x" }, "<leader>rf", function() return require("refactoring").extract_func() end, { desc = "Extract Function", expr = true })
  map({ "n", "x" }, "<leader>rF", function() return require("refactoring").extract_func_to_file() end, { desc = "Extract Function To File", expr = true })
  map({ "n", "x" }, "<leader>rx", function() return require("refactoring").extract_var() end, { desc = "Extract Variable", expr = true })

  map({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank Text" })
  map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put Text After Cursor" })
  map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put Text Before Cursor" })
  map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put Text After Selection" })
  map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put Text Before Selection" })
  map("n", "[y", "<Plug>(YankyCycleForward)", { desc = "Cycle Forward Through Yank History" })
  map("n", "]y", "<Plug>(YankyCycleBackward)", { desc = "Cycle Backward Through Yank History" })
  map("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
  map("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
  map("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
  map("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
  map("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)", { desc = "Put and Indent Right" })
  map("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", { desc = "Put and Indent Left" })
  map("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", { desc = "Put Before and Indent Right" })
  map("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", { desc = "Put Before and Indent Left" })
  map("n", "=p", "<Plug>(YankyPutAfterFilter)", { desc = "Put After Applying a Filter" })
  map("n", "=P", "<Plug>(YankyPutBeforeFilter)", { desc = "Put Before Applying a Filter" })
  map({ "n", "x" }, "<leader>p", function() require("telescope").extensions.yank_history.yank_history({}) end, { desc = "Open Yank History" })

  map({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
  map({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
  map({ "x", "o" }, "an", function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      require("vim.treesitter._select").select_parent(vim.v.count1)
    else
      vim.lsp.buf.selection_range(vim.v.count1)
    end
  end, { desc = "Select parent (outer) node" })
  map({ "x", "o" }, "in", function()
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      require("vim.treesitter._select").select_child(vim.v.count1)
    else
      vim.lsp.buf.selection_range(-vim.v.count1)
    end
  end, { desc = "Select child (inner) node" })
  map("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })
  map({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })

  map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Toggle Pin" })
  map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", { desc = "Delete Non-Pinned Buffers" })
  map("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", { desc = "Delete Buffers to the Right" })
  map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", { desc = "Delete Buffers to the Left" })
  map("n", "<leader>bj", "<cmd>BufferLinePick<cr>", { desc = "Pick Buffer" })
  map("n", "[B", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer prev" })
  map("n", "]B", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer next" })
  map("n", "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, { desc = "Format" })
  map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
  map("n", "]d", diagnostic_jump(1), { desc = "Jump to the next diagnostic in the current buffer" })
  map("n", "[d", diagnostic_jump(-1), { desc = "Jump to the previous diagnostic in the current buffer" })
  map("n", "]e", diagnostic_jump(1, "ERROR"), { desc = "Next Error" })
  map("n", "[e", diagnostic_jump(-1, "ERROR"), { desc = "Prev Error" })
  map("n", "]w", diagnostic_jump(1, "WARN"), { desc = "Next Warning" })
  map("n", "[w", diagnostic_jump(-1, "WARN"), { desc = "Prev Warning" })
  map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
  map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
  map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
  map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
  map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
  map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
  map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
  map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
  map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
  map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

  local telescope = require("telescope.builtin")
  map("n", "<leader><space>", function() telescope.find_files({ cwd = root() }) end, { desc = "Find Files (Root Dir)" })
  map("n", "<leader>,", function() telescope.buffers({ sort_mru = true, sort_lastused = true }) end, { desc = "Switch Buffer" })
  map("n", "<leader>/", function() telescope.live_grep({ cwd = root() }) end, { desc = "Grep (Root Dir)" })
  map("n", "<leader>:", telescope.command_history, { desc = "Command History" })
  map("n", "<leader>ff", function() telescope.find_files({ cwd = root() }) end, { desc = "Find Files (Root Dir)" })
  map("n", "<leader>fF", telescope.find_files, { desc = "Find Files (cwd)" })
  map("n", "<leader>fg", telescope.git_files, { desc = "Find Files (git-files)" })
  map("n", "<leader>fr", telescope.oldfiles, { desc = "Recent" })
  map("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
  map("n", "<leader>fB", telescope.buffers, { desc = "Buffers (all)" })
  map("n", "<leader>fR", function() telescope.oldfiles({ cwd = vim.uv.cwd() }) end, { desc = "Recent (cwd)" })
  map("n", "<leader>fc", function() telescope.find_files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Find Config File" })
  map("n", "<leader>sg", function() telescope.live_grep({ cwd = root() }) end, { desc = "Grep (Root Dir)" })
  map("n", "<leader>sG", telescope.live_grep, { desc = "Grep (cwd)" })
  map("n", "<leader>sw", function() telescope.grep_string({ cwd = root() }) end, { desc = "Word (Root Dir)" })
  map("n", "<leader>sW", telescope.grep_string, { desc = "Word (cwd)" })
  map("n", "<leader>sh", telescope.help_tags, { desc = "Help Pages" })
  map("n", "<leader>sk", telescope.keymaps, { desc = "Key Maps" })
  map("n", "<leader>sd", telescope.diagnostics, { desc = "Diagnostics" })
  map("n", "<leader>sD", function() telescope.diagnostics({ bufnr = 0 }) end, { desc = "Buffer Diagnostics" })
  map("n", '<leader>s"', telescope.registers, { desc = "Registers" })
  map("n", "<leader>s/", telescope.search_history, { desc = "Search History" })
  map("n", "<leader>sa", telescope.autocommands, { desc = "Auto Commands" })
  map("n", "<leader>sb", telescope.current_buffer_fuzzy_find, { desc = "Buffer Lines" })
  map("n", "<leader>sc", telescope.command_history, { desc = "Command History" })
  map("n", "<leader>sC", telescope.commands, { desc = "Commands" })
  map("n", "<leader>sH", telescope.highlights, { desc = "Search Highlight Groups" })
  map("n", "<leader>sj", telescope.jumplist, { desc = "Jumplist" })
  map("n", "<leader>sl", telescope.loclist, { desc = "Location List" })
  map("n", "<leader>sM", telescope.man_pages, { desc = "Man Pages" })
  map("n", "<leader>sm", telescope.marks, { desc = "Jump to Mark" })
  map("n", "<leader>so", telescope.vim_options, { desc = "Options" })
  map("n", "<leader>sR", telescope.resume, { desc = "Resume" })
  map("n", "<leader>sq", telescope.quickfix, { desc = "Quickfix List" })
  map("n", "<leader>uC", telescope.colorscheme, { desc = "Colorscheme with Preview" })
  map("x", "<leader>sw", function() telescope.grep_string({ cwd = root() }) end, { desc = "Selection (Root Dir)" })
  map("x", "<leader>sW", telescope.grep_string, { desc = "Selection (cwd)" })
  map("n", "<leader>ss", telescope.lsp_document_symbols, { desc = "Goto Symbol" })
  map("n", "<leader>sS", telescope.lsp_dynamic_workspace_symbols, { desc = "Goto Symbol (Workspace)" })
  map("n", "<leader>gc", telescope.git_commits, { desc = "Commits" })
  map("n", "<leader>gl", telescope.git_commits, { desc = "Commits" })
  map("n", "<leader>gs", telescope.git_status, { desc = "Status" })
  map("n", "<leader>gS", telescope.git_stash, { desc = "Git Stash" })
  map("n", "<leader>e", function() require("neo-tree.command").execute({ toggle = true, dir = root() }) end, { desc = "Explorer NeoTree (Root Dir)" })
  map("n", "<leader>E", function() require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() }) end, { desc = "Explorer NeoTree (cwd)" })
  map("n", "<leader>fe", function() require("neo-tree.command").execute({ toggle = true, dir = root() }) end, { desc = "Explorer NeoTree (Root Dir)" })
  map("n", "<leader>fE", function() require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() }) end, { desc = "Explorer NeoTree (cwd)" })
  map("n", "<leader>ge", function() require("neo-tree.command").execute({ source = "git_status", toggle = true }) end, { desc = "Git Explorer" })
  map("n", "<leader>be", function() require("neo-tree.command").execute({ source = "buffers", toggle = true }) end, { desc = "Buffer Explorer" })
  map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
  map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
  map("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
  map("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/... (Trouble)" })
  map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
  map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
  map("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todo (Trouble)" })
  map("n", "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", { desc = "Todo/Fix/Fixme (Trouble)" })
  map("n", "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", { desc = "Todo/Fix/Fixme" })
  map("n", "<leader>st", "<cmd>TodoTelescope<cr>", { desc = "Todo" })
  map({ "n", "x" }, "<leader>sr", function() require("grug-far").open() end, { desc = "Search and Replace" })
  map("n", "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select VirtualEnv" })
  map("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session" })
  map("n", "<leader>qS", function() require("persistence").select() end, { desc = "Select Session" })
  map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
  map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })
  map("n", "<leader>ft", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "Terminal (Root Dir)" })
  map("n", "<leader>fT", function() Snacks.terminal() end, { desc = "Terminal (cwd)" })
  map({ "n", "t" }, "<c-/>", function() Snacks.terminal.focus(nil, { cwd = root() }) end, { desc = "Terminal (Root Dir)" })

  map("c", "<C-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })
  map("c", "<S-CR>", function() require("noice").redirect(vim.fn.getcmdline()) end, { desc = "Redirect Cmdline" })
  map({ "n", "x", "o" }, "<C-Space>", function()
    require("flash").treesitter({ actions = { ["<C-Space>"] = "next", ["<BS>"] = "prev" } })
  end, { desc = "Treesitter Incremental Selection" })
  map("n", "<leader>?", function() require("which-key").show({ global = false }) end, { desc = "Buffer Keymaps (which-key)" })
  map("n", "<C-W> ", function() require("which-key").show({ keys = "<C-W>", loop = true }) end, { desc = "Window Hydra Mode (which-key)" })
  map("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer" })
  map("n", "<leader>S", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer" })
  map("n", "<leader>dps", function() Snacks.profiler.scratch() end, { desc = "Profiler Scratch Buffer" })
  map("n", "<leader>n", function() Snacks.notifier.show_history() end, { desc = "Notification History" })
  map("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss All Notifications" })
  map("n", "<leader>sn", "", { desc = "+noice" })
  map("n", "<leader>snl", function() require("noice").cmd("last") end, { desc = "Noice Last Message" })
  map("n", "<leader>snh", function() require("noice").cmd("history") end, { desc = "Noice History" })
  map("n", "<leader>sna", function() require("noice").cmd("all") end, { desc = "Noice All" })
  map("n", "<leader>snd", function() require("noice").cmd("dismiss") end, { desc = "Dismiss All" })
  map("n", "<leader>snt", function() require("noice").cmd("pick") end, { desc = "Noice Picker (Telescope/FzfLua)" })
  map({ "n", "x" }, "<leader>cF", function() require("conform").format({ formatters = { "injected" } }) end, { desc = "Format Injected Langs" })
  map("n", "[t", function() require("todo-comments.jump").prev() end, { desc = "Previous Todo Comment" })
  map("n", "]t", function() require("todo-comments.jump").next() end, { desc = "Next Todo Comment" })
  map("n", "[q", function() vim.cmd("cprev") end, { desc = "Previous Trouble/Quickfix Item" })
  map("n", "]q", function() vim.cmd("cnext") end, { desc = "Next Trouble/Quickfix Item" })

  Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
  Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
  Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
  Snacks.toggle.diagnostics():map("<leader>ud")
  Snacks.toggle.line_number():map("<leader>ul")
  Snacks.toggle.inlay_hints():map("<leader>uh")
  Snacks.toggle.zoom():map("<leader>wm")
  Snacks.toggle.zen():map("<leader>uz")
end

local function setup_autocmds()
  local function augroup(name)
    return vim.api.nvim_create_augroup("lucid_" .. name, { clear = true })
  end

  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = augroup("checktime"),
    callback = function()
      if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
    end,
  })
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function() (vim.hl or vim.highlight).on_yank() end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = augroup("resize_splits"),
    callback = function()
      local tab = vim.fn.tabpagenr()
      vim.cmd("tabdo wincmd =")
      vim.cmd("tabnext " .. tab)
    end,
  })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup("last_loc"),
    callback = function(event)
      local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
      local lines = vim.api.nvim_buf_line_count(event.buf)
      if mark[1] > 0 and mark[1] <= lines and vim.bo[event.buf].filetype ~= "gitcommit" then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup("wrap_spell"),
    pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup("json_conceal"),
    pattern = { "json", "jsonc", "json5" },
    callback = function() vim.opt_local.conceallevel = 0 end,
  })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup("auto_create_dir"),
    callback = function(event)
      if not event.match:match("^%w%w+:[\\/][\\/]") then
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
      end
    end,
  })
end

local function setup_r()
  vim.g.rout_follow_colorscheme = true
  require("r").setup({
    R_args = { "--quiet", "--no-save" },
    hook = {
      on_filetype = function()
        map("n", "<Enter>", "<Plug>RDSendLine", { buffer = true })
        map("x", "<Enter>", "<Plug>RSendSelection", { buffer = true })
      end,
    },
    pdfviewer = "",
  })
  require("r.pdf.generic").open = vim.ui.open
end

local plugin_manifest = {
  "CopilotChat.nvim", "R.nvim", "SchemaStore.nvim", "async.nvim", "blink-copilot", "blink.cmp",
  "bufferline.nvim", "catppuccin", "conform.nvim", "copilot.lua", "crates.nvim", "dressing.nvim",
  "flash.nvim", "friendly-snippets", "gitsigns.nvim", "grug-far.nvim", "jupytext.nvim", "lazydev.nvim",
  "lualine.nvim", "markdown-preview.nvim", "mini.ai", "mini.icons", "mini.pairs", "neo-tree.nvim",
  "noice.nvim", "nui.nvim", "nvim-lint", "nvim-lspconfig", "nvim-treesitter",
  "nvim-treesitter-textobjects", "nvim-ts-autotag", "persistence.nvim", "plenary.nvim", "refactoring.nvim",
  "render-markdown.nvim", "rustaceanvim", "snacks.nvim", "telescope.nvim", "todo-comments.nvim",
  "tokyonight.nvim", "trouble.nvim", "ts-comments.nvim", "uv.nvim", "venv-selector.nvim", "which-key.nvim",
  "yanky.nvim",
}

vim.g.nixvim_plugin_manifest = plugin_manifest
vim.g.snacks_animate = false
vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_auto_close = 1

setup_autocmds()
setup_keymaps()
require("uv").setup()
setup_r()

return M
