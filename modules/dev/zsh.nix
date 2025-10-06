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
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
      }
    ];
    initContent = ''
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
      compinit
      bindkey '^L' clear-screen
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        IFS= read -r cwd < "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
        rm -f -- "$tmp"
      }
    '';
    shellAliases = {
      nixos = "git add . && git commit && nh os switch .";
      gc = "git commit";
      spt = "spotify_player";
    };
  };

  ############################################
  # PROMPT & HISTORY
  ############################################
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.atuin.enable = true;
}
