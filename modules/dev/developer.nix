{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.tuicr ];

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
            diff.colorMoved = "default";
            fetch.prune = true;
            merge.conflictStyle = "zdiff3";
            pull.rebase = true;
            rerere.enabled = true;
          };
        };

        delta = {
          enable = true;
          enableGitIntegration = true;
        };

        bat.enable = true;

        eza = {
          enable = true;
          icons = "auto";
          extraOptions = [ "--group-directories-first" ];
        };

        fzf = {
          enable = true;
          enableZshIntegration = true;
          defaultCommand = "fd --type f --hidden --follow --exclude .git";
          fileWidget.command = "fd --type f --hidden --follow --exclude .git";
          changeDirWidget.command = "fd --type d --hidden --follow --exclude .git";
          historyWidget.command = "";
        };
      };
    };
}
