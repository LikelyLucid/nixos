{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      configuration = inputs.nixvim.lib.evalNixvim {
        inherit system;
        modules = [
          (
            {
              config,
              pkgs,
              ...
            }:
            let
              async_nvim = pkgs.vimUtils.buildVimPlugin {
                pname = "async.nvim";
                version = "2026-03-31";
                nvimSkipModules = [ "docgen" ];
                src = pkgs.fetchFromGitHub {
                  owner = "lewis6991";
                  repo = "async.nvim";
                  rev = "e2a813be9cd143ab1181de6d8a0720e0230cd86e";
                  hash = "sha256-b7jE3tY+6nlbIFTuOxKz4w6jDw7hlyvgBYy0Jg6McAc=";
                };
              };
              r_nvim = pkgs.vimUtils.buildVimPlugin {
                pname = "R.nvim";
                version = "2026-07-13";
                src = pkgs.fetchFromGitHub {
                  owner = "R-nvim";
                  repo = "R.nvim";
                  rev = "43a8c4f1436d1563e033dd2cd4d2e5188109c9e2";
                  hash = "sha256-wd/sFanVvq0LrIKPuT4faW/aEPwW/Dw+/180NE+7Ylc=";
                };
              };
            in
            {
              nixpkgs = {
                source = inputs.nixpkgs;
                config.allowUnfreePredicate = package: (package.pname or "") == "jupytext.nvim";
              };

              viAlias = true;
              vimAlias = true;

              dependencies.rust-analyzer.enable = false;

              globals = {
                mapleader = " ";
                maplocalleader = "\\";
                mkdp_command_for_global = 1;
                mkdp_filetypes = [
                  "markdown"
                  "rmd"
                ];
              };

              opts = {
                autowrite = true;
                clipboard = "unnamedplus";
                completeopt = "menu,menuone,noselect";
                conceallevel = 2;
                confirm = true;
                cursorline = true;
                expandtab = true;
                foldlevel = 99;
                foldmethod = "indent";
                formatexpr = "v:lua.vim.lsp.formatexpr()";
                grepformat = "%f:%l:%c:%m";
                grepprg = "rg --vimgrep";
                ignorecase = true;
                laststatus = 3;
                mouse = "a";
                number = true;
                pumblend = 10;
                pumheight = 10;
                relativenumber = true;
                scrolloff = 4;
                sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds";
                shiftwidth = 2;
                showmode = false;
                sidescrolloff = 8;
                signcolumn = "yes";
                smartcase = true;
                smartindent = true;
                splitbelow = true;
                splitkeep = "screen";
                splitright = true;
                tabstop = 2;
                termguicolors = true;
                timeoutlen = 300;
                undofile = true;
                undolevels = 10000;
                updatetime = 200;
                virtualedit = "block";
                wildmode = "longest:full,full";
                winminwidth = 5;
                wrap = false;
              };

              colorscheme = "tokyonight-moon";
              colorschemes.tokyonight = {
                enable = true;
                settings = {
                  style = "moon";
                  transparent = true;
                  terminal_colors = true;
                  styles = {
                    comments.italic = true;
                    keywords.italic = false;
                    sidebars = "dark";
                    floats = "dark";
                  };
                };
              };

              plugins = {
                blink-cmp.enable = true;
                blink-copilot.enable = true;
                bufferline.enable = true;
                conform-nvim = {
                  enable = true;
                  settings = {
                    default_format_opts.lsp_format = "fallback";
                    formatters_by_ft = {
                      css = [ "prettier" ];
                      graphql = [ "prettier" ];
                      html = [ "prettier" ];
                      javascript = [ "prettier" ];
                      javascriptreact = [ "prettier" ];
                      json = [ "prettier" ];
                      jsonc = [ "prettier" ];
                      markdown = [ "prettier" ];
                      scss = [ "prettier" ];
                      typescript = [ "prettier" ];
                      typescriptreact = [ "prettier" ];
                      yaml = [ "prettier" ];
                    };
                  };
                };
                copilot-chat = {
                  enable = true;
                  settings = {
                    auto_insert_mode = true;
                    window.width = 0.4;
                  };
                };
                copilot-lua = {
                  enable = true;
                  settings = {
                    panel.enabled = false;
                    suggestion.enabled = false;
                  };
                };
                crates.enable = true;
                flash.enable = true;
                gitsigns.enable = true;
                grug-far.enable = true;
                jupytext.enable = true;
                lazydev.enable = true;
                lint.enable = true;
                lualine.enable = true;
                mini-ai.enable = true;
                mini-icons = {
                  enable = true;
                  mockDevIcons = true;
                };
                mini-pairs.enable = true;
                neo-tree.enable = true;
                noice.enable = true;
                persistence.enable = true;
                refactoring.enable = true;
                render-markdown.enable = true;
                rustaceanvim.enable = true;
                schemastore.enable = true;
                snacks = {
                  enable = true;
                  settings = {
                    animate.enabled = false;
                    bigfile.enabled = true;
                    dashboard = {
                      enabled = true;
                      width = 50;
                      preset.header = ''
                        ██╗     ██╗   ██╗ ██████╗██╗██████╗
                        ██║     ██║   ██║██╔════╝██║██╔══██╗
                        ██║     ██║   ██║██║     ██║██║  ██║
                        ██║     ██║   ██║██║     ██║██║  ██║
                        ███████╗╚██████╔╝╚██████╗██║██████╔╝
                        ╚══════╝ ╚═════╝  ╚═════╝╚═╝╚═════╝
                      '';
                      sections = [
                        { section = "header"; }
                        {
                          section = "keys";
                          gap = 1;
                          padding = 1;
                        }
                        { section = "startup"; }
                      ];
                    };
                    input.enabled = true;
                    notifier.enabled = true;
                    picker.enabled = true;
                    quickfile.enabled = true;
                    scope.enabled = true;
                    statuscolumn.enabled = true;
                    words.enabled = true;
                  };
                };
                telescope = {
                  enable = true;
                  extensions.fzf-native.enable = true;
                  settings = {
                    defaults = {
                      prompt_prefix = " ";
                      selection_caret = " ";
                    };
                    pickers.find_files.hidden = true;
                  };
                };
                todo-comments.enable = true;
                treesitter = {
                  enable = true;
                  folding.enable = false;
                  highlight.enable = true;
                  indent.enable = true;
                  languageRegister.json = [ "jsonc" ];
                  grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
                    bash
                    c
                    diff
                    git_config
                    git_rebase
                    gitattributes
                    gitcommit
                    gitignore
                    html
                    hyprlang
                    javascript
                    jsdoc
                    json
                    json5
                    lua
                    luadoc
                    luap
                    markdown
                    markdown_inline
                    ninja
                    printf
                    python
                    query
                    r
                    rasi
                    regex
                    rnoweb
                    ron
                    rst
                    rust
                    toml
                    tsx
                    typescript
                    vim
                    vimdoc
                    xml
                    yaml
                  ];
                };
                treesitter-textobjects.enable = true;
                trouble.enable = true;
                ts-autotag.enable = true;
                ts-comments.enable = true;
                venv-selector.enable = true;
                which-key.enable = true;
                yanky = {
                  enable = true;
                  enableTelescope = true;
                  settings = {
                    highlight.timer = 150;
                    system_clipboard.sync_with_ring = true;
                  };
                };

                lsp = {
                  enable = true;
                  servers = {
                    basedpyright = {
                      enable = true;
                      package = null;
                      cmd = [
                        "basedpyright-langserver"
                        "--stdio"
                      ];
                    };
                    jsonls = {
                      enable = true;
                      package = null;
                      cmd = [
                        "vscode-json-language-server"
                        "--stdio"
                      ];
                    };
                    marksman = {
                      enable = true;
                      package = null;
                      cmd = [
                        "marksman"
                        "server"
                      ];
                      rootMarkers = [ ".git" ];
                    };
                    r_language_server = {
                      enable = true;
                      package = null;
                      cmd = [
                        "R"
                        "--no-echo"
                        "-e"
                        "languageserver::run()"
                      ];
                      rootMarkers = [
                        "DESCRIPTION"
                        "NAMESPACE"
                        ".Rbuildignore"
                        ".git"
                      ];
                    };
                    ruff = {
                      enable = true;
                      package = null;
                      cmd = [
                        "ruff"
                        "server"
                      ];
                    };
                    taplo = {
                      enable = true;
                      package = null;
                      cmd = [
                        "taplo"
                        "lsp"
                        "stdio"
                      ];
                    };
                    yamlls = {
                      enable = true;
                      package = null;
                      cmd = [
                        "yaml-language-server"
                        "--stdio"
                      ];
                    };
                  };
                };
              };

              extraPlugins = with pkgs.vimPlugins; [
                async_nvim
                r_nvim
                catppuccin-nvim
                dressing-nvim
                friendly-snippets
                markdown-preview-nvim
                nui-nvim
                plenary-nvim
                uv-nvim
              ];

              extraPackages = with pkgs; [
                fd
                fzf
                git
                ripgrep
                yazi
              ];

              extraFiles = {
                "lua/lucid/config.lua".source = ./nixvim/config.lua;
                "lua/lucid/theme.lua".source = ./nixvim/theme.lua;
                "queries/lua/highlights.scm".source = ./nixvim/queries/lua/highlights.scm;
                "queries/vim/highlights.scm".source = ./nixvim/queries/vim/highlights.scm;
              };

              extraConfigLua = ''
                require("lucid.theme")
                require("lucid.config")
              '';

            }
          )
        ];
      };
      nvim_nix = pkgs.writeShellApplication {
        name = "nvim-nix";
        text = ''
          exec ${configuration.config.build.package}/bin/nvim "$@"
        '';
      };
      r_with_language_server = pkgs.rWrapper.override {
        packages = [ pkgs.rPackages.languageserver ];
      };
    in
    {
      checks.nvim = configuration.config.build.test;
      packages.nvim-nix = nvim_nix;
      packages.nvim-nix-unwrapped = configuration.config.build.package;

      devShells.nvim = pkgs.mkShell {
        packages = [ nvim_nix ];
        shellHook = ''
          echo "Pure NixVim is available as nvim-nix; the existing LazyVim remains nvim."
        '';
      };

      devShells.nvim-r = pkgs.mkShell {
        packages = [
          nvim_nix
          r_with_language_server
        ];
        shellHook = ''
          echo "Pure NixVim, R, and the R language server are available as nvim-nix and R."
        '';
      };
    };
}
