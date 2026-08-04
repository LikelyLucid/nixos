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
      programs.zoxide.enable = true;
      programs.atuin.enable = true;
    };
}
