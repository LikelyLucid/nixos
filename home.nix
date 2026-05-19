{ pkgs, lib, zenBrowser, lazyvim-config, dotfiles, isWsl ? false, ... }:
let
  home_dir = "/home/lucid";
in {
  ############################################
  # MODULE IMPORTS
  ############################################
  imports =
    [
      # Always included
      ./modules/dev/developer.nix
      ./modules/dotfiles.nix
    ]
    ++ lib.optionals (!isWsl) [
      # Desktop Linux only (GUI, display servers, etc.)
      ./modules/window-manager/hyprland-config.nix
      ./modules/notes/notes.nix
      ./modules/browsers/browsers.nix
      ./modules/office/office.nix
      ./modules/university/university.nix
    ]
    ++ lib.optionals (isWsl) [
      # WSL-only home-manager config
    ];

  ############################################
  # USER DETAILS
  ############################################
  home.username = "lucid";
  home.homeDirectory = home_dir;

  ############################################
  # SOPS
  ############################################
  sops = {
    age.keyFile = if isWsl then "/var/lib/sops-nix/key.txt" else "${home_dir}/.secrets/age.agekey";
    defaultSopsFile = ./secrets/secrets.yaml;
  };

  ############################################
  # HOME PACKAGES
  # Organised by category for easy maintenance
  ############################################
  home.packages =
    with pkgs;
    [
      ########################################
      # RUNTIME ENVIRONMENTS
      ########################################
      nodejs           # JavaScript runtime
      bun              # Fast all-in-one JS/TS runtime
      go               # Go programming language
      python3          # Python runtime
      uv               # Fast Python package manager

      ########################################
      # AI / AGENT DEVELOPMENT TOOLS
      ########################################
      pi-coding-agent  # pi coding agent (from lukasl-dev/pi.nix overlay)
      aider-chat       # AI pair programming in terminal
      opencode         # Terminal UI for LLMs

      ########################################
      # ENHANCED CLI TOOLS
      ########################################
      bat              # `cat` with syntax highlighting & git integration
      eza              # Modern `ls` replacement (colours, icons, tree view)
      fd               # `find` replacement that's fast and intuitive
      delta            # Syntax-highlighted git diffs
      just             # Command runner — like make but modern
      yq               # YAML/JSON/XML processor (like jq for everything)
      jq               # JSON processor
      ripgrep          # `grep` replacement — fast recursive search
      hyperfine        # Command benchmarking tool

      ########################################
      # NETWORK TOOLS
      ########################################
      httpie           # Human-friendly curl alternative
      dogdns           # DNS lookup utility
      websocat         # WebSocket client

      ########################################
      # SYSTEM / MONITORING
      ########################################
      fastfetch        # System info
      btop             # Resource monitor
      procs            # Modern `ps` replacement
      du-dust          # `du` replacement — disk usage visualised
      duf              # `df` replacement — disk free with better output

      ########################################
      # FONTS
      ########################################
      noto-fonts
      noto-fonts-cjk-sans
    ]
    ++ lib.optionals (!isWsl) [
      # Desktop Linux GUI packages
      cava
      hyprpaper
      kitty
      pavucontrol
      rofi
      spotify-player
      wallust
      waybar
    ]
    ++ lib.optionals (isWsl) [
      # WSL-specific tooling
    ];

  ############################################
  # ZSH ALIASES for new tools
  ############################################
  programs.zsh.shellAliases = {
    # Enhanced CLI aliases
    ls = "eza --icons --group-directories-first";
    ll = "eza --icons --group-directories-first -la";
    lt = "eza --icons --group-directories-first --tree";
    cat = "bat --paging=never";
    du = "dust";
    df = "duf";
    ps = "procs";
    grep = "rg";
    top = "btop";

    # Git
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline --graph";
    gd = "git diff";
    gds = "git diff --staged";

    # AI tools
    pi = "pi";
    aider = "aider";

    # Network
    curl = "httpie";

    # WSL: quick jump to Windows home (dynamically detected)
    winhome = "cd \"$(wslpath \"$(powershell.exe -NoProfile -NonInteractive -Command Write-Output '$env:USERPROFILE' 2>/dev/null | tr -d '\\r\\n')\" 2>/dev/null || echo /mnt/c/Users)\"";
  };

  ############################################
  # KDE CONNECT (desktop only)
  ############################################
  services.kdeconnect = lib.mkIf (!isWsl) {
    enable = true;
    indicator = true;
  };

  ############################################
  # FONT CONFIGURATION
  ############################################
  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans" ];

  ############################################
  # SYNCTHING
  ############################################
  services.syncthing = {
    enable = true;
    package = pkgs.syncthing;
    guiAddress = "127.0.0.1:8384";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        lucid-server = {
          id = "6XWWGNN-R7HBLRL-CHGQSTV-BYLYWXP-YTIXXLG-EEXRZLN-2EDHEAF-JSRIDAP";
          name = "lucid-server";
        };
        bigboy = {
          id = "XHF4Y4B-QZM2XII-R7W5IG2-DXGQONP-DHPYDJH-OEGHNVR-7S6MXIL-R5LFQAY";
          name = "bigboy";
        };
      };
      folders."Vault-V2" = {
        id = "Vault-V2";
        path = "${home_dir}/Documents/Vault";
        label = "Vault-V2 - Obsidian";
        devices = [ "lucid-server" ];
        versioning = {
          type = "simple";
          params.keep = 10;
        };
      };
      gui.theme = "black";
    };
  };

  ############################################
  # WSL: Ollama passthrough + dynamic Windows home detection
  ############################################
  programs.zsh.initExtra = lib.mkIf isWsl ''
    # Point Ollama to Windows-hosted Ollama Cloud
    export OLLAMA_HOST="http://$(grep nameserver /etc/resolv.conf | awk '{print $2}'):11434"

    # Detect Windows home directory dynamically (works for any Windows username)
    if [[ -z "$WIN_HOME" ]]; then
      export WIN_HOME=$(wslpath "$(powershell.exe -NoProfile -NonInteractive -Command Write-Output '$env:USERPROFILE' 2>/dev/null | tr -d '\\r\\n')" 2>/dev/null)
    fi
  '';

  ############################################
  # STATE VERSION
  ############################################
  home.stateVersion = "23.05";
}
