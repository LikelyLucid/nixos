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
          eval "$(starship init zsh)"
          eval "$(zoxide init zsh)"
          compinit
          bindkey '^L' clear-screen
        '';
        shellAliases = {
          nixos = "git add . && git commit && nh os switch .";
          spt = "ncspot";
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
