{ pkgs, ... }:
{
  imports = [
    ./neovim.nix
    ./tmux.nix
    ./zsh.nix
  ];

  ############################################
  # GIT CONFIGURATION
  ############################################
  programs.git = {
    enable = true;
    userName = "LikelyLucid";
    userEmail = "micoolplays@gmail.com";

    extraConfig = {
      core.editor = "nvim";
      pull.rebase = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  ############################################
  # DEVELOPMENT TOOLS
  ############################################
  home.packages = with pkgs; [
    # Build tools
    gnumake
    cmake
    pkg-config
    
    # Language servers and tools
    lua-language-server
    nixd              # Nix language server
    nil               # Another Nix language server
    
    # Code formatters
    nixpkgs-fmt       # Nix formatter
    prettier          # Web formatter
    
    # Version control
    diff-so-fancy     # Better git diff
    delta             # Better git diff (alternative)
    
    # Container tools
    docker-compose
    
    # Network tools for development
    curl
    jq                # JSON processor
    yq                # YAML processor
  ];

  ############################################
  # DEVELOPMENT ENVIRONMENT
  ############################################
  home.sessionVariables = {
    # Development environment variables
    NIXPKGS_ALLOW_UNFREE = "1";
  };
}

