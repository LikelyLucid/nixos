{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.hunk ];

      programs = {
        ############################################
        # GIT CONFIG
        ############################################
        git = {
          enable = true;
          settings = {
            user.name = "LikelyLucid";
            user.email = "micoolplays@gmail.com";
            core.editor = "nvim";
            diff = {
              algorithm = "histogram";
              colorMoved = "default";
            };
            fetch = {
              prune = true;
              pruneTags = true;
            };
            init.defaultBranch = "main";
            merge.conflictStyle = "zdiff3";
            pull.rebase = true;
            push.autoSetupRemote = true;
            rebase.autoStash = true;
            rerere.enabled = true;
          };
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
          options = {
            line-numbers = true;
            navigate = true;
            side-by-side = false;
          };
        };

        bat = {
          enable = true;
          config = {
            paging = "never";
            style = "numbers,changes,header";
          };
        };

        eza = {
          enable = true;
          git = true;
          icons = "auto";
          extraOptions = [
            "--group-directories-first"
            "--header"
          ];
        };

        fzf = {
          enable = true;
          enableZshIntegration = true;
          defaultCommand = "fd --type f --hidden --follow --exclude .git";
          defaultOptions = [
            "--border"
            "--cycle"
            "--height=60%"
            "--info=inline"
            "--layout=reverse"
            "--preview-window=right,60%,border-left"
          ];
          fileWidget = {
            command = "fd --type f --hidden --follow --exclude .git";
            options = [ "--preview 'bat --color=always --style=numbers --line-range=:300 {}'" ];
          };
          changeDirWidget = {
            command = "fd --type d --hidden --follow --exclude .git";
            options = [ "--preview 'eza --tree --level=2 --icons --color=always {}'" ];
          };
          # Atuin owns Ctrl-R and provides the richer history search.
          historyWidget.command = "";
        };
      };
    };
}
