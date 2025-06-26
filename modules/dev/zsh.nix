{ pkgs, ... }: {
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
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
      }
    ];

    initExtra = ''
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
      compinit
      '';
  };

  programs.starship = {
    enable = true;
  };
  programs.zoxide.enable = true;
}

