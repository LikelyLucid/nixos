{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    let
      yazi_open_nvim = pkgs.writeShellApplication {
        name = "yazi-open-nvim";
        runtimeInputs = with pkgs; [
          neovim
          tmux
        ];
        text = ''
          if [[ -n ''${TMUX:-} ]]; then
            tmux new-window -c "$PWD" -n nvim -- nvim "$@"
          else
            exec nvim "$@"
          fi
        '';
      };
    in
    {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "yazi";

        extraPackages = with pkgs; [
          bat
          eza
          glow
          mediainfo
          ouch
          udisks2
          util-linux
          wl-clipboard
        ];

        plugins = with pkgs.yaziPlugins; {
          full-border = {
            package = full-border;
            setup = true;
          };
          git = {
            package = git;
            setup = true;
            settings.order = 1500;
          };
          projects = {
            package = projects;
            setup = true;
            settings.notify.enable = true;
          };
          inherit
            mediainfo
            mount
            ouch
            piper
            smart-enter
            smart-filter
            smart-paste
            toggle-pane
            ;
        };

        settings = {
          mgr = {
            ratio = [
              1
              3
              4
            ];
            sort_by = "natural";
            sort_sensitive = false;
            sort_reverse = false;
            sort_dir_first = true;
            linemode = "size";
            show_hidden = false;
            show_symlink = true;
            scrolloff = 5;
          };

          preview = {
            wrap = "no";
            tab_size = 2;
            max_width = 1800;
            max_height = 1800;
            image_delay = 0;
            image_filter = "lanczos3";
            image_quality = 85;
          };

          opener.edit = [
            {
              run = "${yazi_open_nvim}/bin/yazi-open-nvim %s";
              desc = "Open in Neovim";
              block = true;
              for = "unix";
            }
          ];

          opener.extract = [
            {
              run = ''ouch d -y "$@"'';
              desc = "Extract here with ouch";
              for = "unix";
            }
          ];

          tasks.image_alloc = 1073741824;

          plugin = {
            prepend_fetchers = [
              {
                url = "*";
                run = "git";
                group = "git";
              }
              {
                url = "*/";
                run = "git";
                group = "git";
              }
            ];
            prepend_preloaders = [
              {
                mime = "{audio,video}/*";
                run = "mediainfo";
              }
            ];
            prepend_previewers = [
              {
                url = "*.md";
                run = ''piper -- CLICOLOR_FORCE=1 glow -w="$w" -s=dark "$1"'';
              }
              {
                url = "*.csv";
                run = ''piper -- bat --plain --color=always "$1"'';
              }
              {
                mime = "{audio,video}/*";
                run = "mediainfo";
              }
              {
                mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
                run = "ouch --show-file-icons";
              }
            ];
          };
        };

        keymap.mgr.prepend_keymap = [
          {
            on = "!";
            run = ''shell "$SHELL" --block'';
            desc = "Open a shell here";
            for = "unix";
          }
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Enter directory or open file";
          }
          {
            on = "p";
            run = "plugin smart-paste";
            desc = "Paste into hovered directory or CWD";
          }
          {
            on = "F";
            run = "plugin smart-filter";
            desc = "Smart filter";
          }
          {
            on = "T";
            run = "plugin toggle-pane max-preview";
            desc = "Maximize or restore preview";
          }
          {
            on = "C";
            run = "plugin ouch";
            desc = "Compress selected files";
          }
          {
            on = "M";
            run = "plugin mount";
            desc = "Manage mounted drives";
          }
          {
            on = "y";
            run = [
              ''shell -- if [ -n "$WAYLAND_DISPLAY" ]; then for path in %s; do printf "file://%s\\n" "$path"; done | wl-copy -t text/uri-list; fi''
              "yank"
            ];
            desc = "Yank and copy file URIs";
          }
          {
            on = [
              "g"
              "s"
            ];
            run = "plugin projects save";
            desc = "Save current project";
          }
          {
            on = [
              "g"
              "p"
            ];
            run = "plugin projects load";
            desc = "Load a project";
          }
          {
            on = [
              "g"
              "P"
            ];
            run = "plugin projects load_last";
            desc = "Load the last project";
          }
          {
            on = [
              "g"
              "r"
            ];
            run = ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
            desc = "Go to Git repository root";
          }
          {
            on = [
              "g"
              "D"
            ];
            run = "cd ~/Documents";
            desc = "Go to Documents";
          }
          {
            on = [
              "g"
              "n"
            ];
            run = "cd ~/nixos";
            desc = "Go to NixOS configuration";
          }
          {
            on = [
              "g"
              "o"
            ];
            run = "cd ~/dotfiles";
            desc = "Go to dotfiles";
          }
          {
            on = [
              "g"
              "v"
            ];
            run = "cd ~/Documents/Vault";
            desc = "Go to Obsidian vault";
          }
          {
            on = "<C-w>";
            run = "shell -- ~/.local/bin/set-wallpaper %h";
            desc = "Set hovered image as wallpaper";
            for = "unix";
          }
          {
            on = "<F3>";
            run = "plugin mediainfo -- toggle-metadata";
            desc = "Toggle media metadata";
          }
          {
            on = "<F4>";
            run = "plugin mediainfo -- toggle-preview";
            desc = "Toggle media preview";
          }
        ];

        keymap.input.prepend_keymap = [
          {
            on = "<Esc>";
            run = "close";
            desc = "Cancel input";
          }
        ];
      };

      programs.zsh.shellAliases.y = "yazi";
    };
}
