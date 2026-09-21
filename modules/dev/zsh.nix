{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      ############################################
      # ZSH
      ############################################
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        historySubstringSearch.enable = true;
        plugins = [
          {
            name = "zsh-autosuggestions";
            src = pkgs.zsh-autosuggestions;
          }
        ];
        initContent = ''
          bindkey '^L' clear-screen
        '';
        shellAliases = {
          nix-build = "nh os build /home/lucid/nixos";
          nix-switch = "nh os switch /home/lucid/nixos";
          nix-test = "nh os test /home/lucid/nixos";
          spt = "spotify_player";
        };
      };

      ############################################
      # PROMPT & HISTORY
      ############################################
      programs.starship.enable = true;
      programs.zoxide = {
        enable = true;
        options = [ "--hook=pwd" ];
      };
      home.sessionVariables = {
        _ZO_ECHO = "1";
        _ZO_EXCLUDE_DIRS = "$HOME:$HOME/.cache:$HOME/.local/share/Trash:/nix/store";
        _ZO_FZF_OPTS = "--height=60% --layout=reverse --border";
        _ZO_MAXAGE = "10000";
        _ZO_RESOLVE_SYMLINKS = "1";
      };
      programs.atuin = {
        enable = true;
        daemon.enable = true;
        forceOverwriteSettings = true;
        settings = {
          auto_sync = false;
          dialect = "uk";
          enter_accept = true;
          filter_mode = "workspace";
          filter_mode_shell_up_key_binding = "directory";
          history_filter = [
            "^export .*(_TOKEN|_KEY|_SECRET|_PASSWORD)="
            "^.*--(token|password|secret)(=| ).*"
          ];
          inline_height = 20;
          max_preview_height = 4;
          search_mode = "daemon-fuzzy";
          secrets_filter = true;
          show_preview = true;
          style = "compact";
          workspaces = true;

          ai.enabled = true;
          daemon = {
            autostart = true;
            enabled = true;
            sync_frequency = 300;
          };
          keys.scroll_exits = false;
          preview.strategy = "auto";
          search.filters = [
            "workspace"
            "directory"
            "session"
            "host"
            "global"
          ];
          stats = {
            common_prefix = [ "sudo" ];
            common_subcommands = [
              "cargo"
              "docker"
              "git"
              "nix"
              "npm"
              "pnpm"
              "systemctl"
            ];
            ignored_commands = [
              "cd"
              "clear"
              "exit"
              "ls"
            ];
          };
          sync.records = true;
        };
      };
    };
}
