{ pkgs, ... }: 
{
  ############################################
  # ZSH SHELL CONFIGURATION
  ############################################
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };

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
      # Initialize tools
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
      
      # Key bindings
      bindkey '^L' clear-screen
      bindkey '^[[1;5C' forward-word     # Ctrl+Right
      bindkey '^[[1;5D' backward-word    # Ctrl+Left
      
      # Auto-completion improvements
      compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      
      # Better directory navigation
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
    '';

    shellAliases = {
      # NixOS management
      nixos = "git add . && git commit && nh os switch .";
      nixos-update = "nix flake update && nixos";
      nixos-clean = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      
      # Git shortcuts
      gc = "git commit";
      gs = "git status";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      ga = "git add";
      
      # System shortcuts
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      spt = "spotify_player";
      
      # Navigation shortcuts
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };
  };

  ############################################
  # SHELL TOOLS
  ############################################
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$character";
      directory = {
        truncation_length = 3;
        truncate_to_repo = false;
      };
    };
  };

  programs.zoxide.enable = true;
  programs.atuin.enable = true;

  # Additional shell packages
  home.packages = with pkgs; [
    eza         # Better ls
    fd          # Better find
    bat         # Better cat
    tree        # Directory tree view
    tldr        # Simplified man pages
  ];
}

