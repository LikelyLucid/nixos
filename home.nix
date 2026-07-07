{
  pkgs,
  lib,
  zenBrowser,
  lazyvim-config,
  dotfiles,
  pi-config,
  hyprland-canvas-pkg,
  isWsl ? false,
  ...
}:
let
  home_dir = "/home/lucid";
in
{
  ############################################
  # MODULE IMPORTS
  ############################################
  imports = [
    # Always included
    ./modules/dev/developer.nix
    ./modules/dotfiles.nix
    ./modules/pi-config.nix
  ]
  ++ lib.optionals (!isWsl) [
    # Desktop Linux only (GUI, display servers, etc.)
    ./modules/window-manager/hyprland-config.nix
    ./modules/notes/notes.nix
    ./modules/browsers/browsers.nix
    ./modules/office/office.nix
    ./modules/university/university.nix
    ./modules/agent/agent.nix
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
  # NEMO FILE MANAGER (riced with wallust)
  ############################################
  dconf.settings = lib.mkIf (!isWsl) {
    "org/nemo/preferences" = {
      default-folder-viewer = "icon-view";
      show-location-entry = true;
      enable-delete = true;
      date-format = "locale";
    };
    "org/nemo/icon-view" = {
      default-zoom-level = "standard";
    };
    "org/nemo/window-state" = {
      start-with-sidebar = true;
      geometry = "1200x800+100+100";
    };
  };

  # Nemo as default file manager; terminal Neovim for text-like files.
  xdg.desktopEntries.nvim = lib.mkIf (!isWsl) {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "ghostty -e nvim %F";
    terminal = false;
    mimeType = [
      "application/json"
      "application/toml"
      "application/x-shellscript"
      "application/x-yaml"
      "text/markdown"
      "text/plain"
      "text/x-markdown"
      "text/x-c"
      "text/x-c++"
      "text/x-go"
      "text/x-lua"
      "text/x-nix"
      "text/x-python"
      "text/x-rust"
    ];
    categories = [
      "Development"
      "TextEditor"
    ];
  };

  xdg.mimeApps = lib.mkIf (!isWsl) {
    enable = true;
    defaultApplications = {
      "inode/directory" = "nemo.desktop";

      "application/json" = "nvim.desktop";
      "application/toml" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";
      "application/x-yaml" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "text/plain" = "nvim.desktop";
      "text/x-markdown" = "nvim.desktop";
      "text/x-c" = "nvim.desktop";
      "text/x-c++" = "nvim.desktop";
      "text/x-go" = "nvim.desktop";
      "text/x-lua" = "nvim.desktop";
      "text/x-nix" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "text/x-rust" = "nvim.desktop";

      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
      "application/zstd" = "org.gnome.FileRoller.desktop";
      "application/zip" = "org.gnome.FileRoller.desktop";
    };
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
      nodejs # JavaScript runtime
      bun # Fast all-in-one JS/TS runtime
      go # Go programming language
      python3 # Python runtime
      uv # Fast Python package manager

      ########################################
      # AI / AGENT DEVELOPMENT TOOLS
      ########################################
      pi-coding-agent # pi coding agent (from lukasl-dev/pi.nix overlay)
      aider-chat # AI pair programming in terminal
      opencode # Terminal UI for LLMs
      cua-driver # Computer-Use Agent driver (prebuilt from trycua/cua)
      (writeShellScriptBin "cua-x11" ''
        if [ "$#" -eq 0 ]; then
          echo "usage: cua-x11 <command> [args...]" >&2
          exit 2
        fi

        unset WAYLAND_DISPLAY
        export GDK_BACKEND=x11
        export QT_QPA_PLATFORM=xcb
        export SDL_VIDEODRIVER=x11
        export CLUTTER_BACKEND=x11
        export MOZ_ENABLE_WAYLAND=0
        export NIXOS_OZONE_WL=0
        export ELECTRON_OZONE_PLATFORM_HINT=x11
        export OZONE_PLATFORM=x11

        exec "$@"
      '') # Launch apps under XWayland so cua-driver can target them

      ########################################
      # ENHANCED CLI TOOLS
      ########################################
      bat # `cat` with syntax highlighting & git integration
      eza # Modern `ls` replacement (colours, icons, tree view)
      fd # `find` replacement that's fast and intuitive
      delta # Syntax-highlighted git diffs
      just # Command runner — like make but modern
      yq # YAML/JSON/XML processor (like jq for everything)
      jq # JSON processor
      ripgrep # `grep` replacement — fast recursive search
      hyperfine # Command benchmarking tool
      trash-cli # Safe terminal trash instead of permanent rm
      tealdeer # Fast tldr command examples
      file
      tree
      rsync
      lsof
      usbutils
      strace
      zip
      unzip
      p7zip

      ########################################
      # NIX TOOLING
      ########################################
      nixd # Nix language server
      cachix # Binary cache helper
      nixfmt # Nix formatter
      statix # Nix linter
      deadnix # Finds unused Nix code

      ########################################
      # NETWORK TOOLS
      ########################################
      httpie # Human-friendly curl alternative
      doggo # DNS lookup utility
      websocat # WebSocket client
      openssh # ssh/sftp/scp client tools
      sshfs # KDE Connect remote filesystem mounts
      whois

      ########################################
      # SYSTEM / MONITORING
      ########################################
      fastfetch # System info
      btop # Resource monitor
      procs # Modern `ps` replacement
      dust # `du` replacement — disk usage visualised
      duf # `df` replacement — disk free with better output

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
      (nemo-with-extensions.override {
        extensions = [
          nemo-preview
          nemo-seahorse
        ];
      })
      file-roller
      libnotify
      pavucontrol
      rofi
      (pkgs.ncspot.overrideAttrs (old: {
        cargoDeps = pkgs.runCommand "ncspot-vendor-librespot-cdn-fallback" { } ''
                    cp -R ${old.cargoDeps} $out
                    chmod -R u+w $out
                    file="$out/source-registry-0/librespot-audio-0.8.0/src/fetch/mod.rs"
                    substituteInPlace "$file" \
                      --replace-fail 'Ok(r) => {
                              response_streamer_url = Some((r, streamer, url));
                              break;
                          }
                          Err(e) => warn!("Fetching {url} failed with error {e:?}, trying next"),' 'Ok(r) if r.status() == StatusCode::PARTIAL_CONTENT => {
                              response_streamer_url = Some((r, streamer, url));
                              break;
                          }
                          Ok(r) => warn!(
                              "Fetching {url} returned {} (expected 206 Partial Content), trying next",
                              r.status()
                          ),
                          Err(e) => warn!("Fetching {url} failed with error {e:?}, trying next"),'
                    substituteInPlace "$file" \
                      --replace-fail '
                  let code = response.status();
                  if code != StatusCode::PARTIAL_CONTENT {
                      debug!("Opening audio file expected partial content but got: {code}");
                      return Err(AudioFileError::StatusCode(code).into());
                  }
          ' ""
        '';
      }))
      swaynotificationcenter
      wallust
      waybar
      hyprland-canvas-pkg
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

  xdg.configFile."kdeconnect/4f91b463981d4e788fe49fb277df446e/kdeconnect_share/config" =
    lib.mkIf (!isWsl)
      {
        force = true;
        text = ''
          [General]
          incoming_path=${home_dir}/Desktop
        '';
      };

  ############################################
  # TAILSCALE SYSTRAY (desktop only)
  ############################################
  services.tailscale-systray = lib.mkIf (!isWsl) {
    enable = true;
    theme = "dark:nobg";
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
  # GHOSTTY TERMINAL (with wallust colors)
  ############################################
  home.file.".config/ghostty/config" = lib.mkIf (!isWsl) {
    text = ''
      # Font
      font-family = JetBrains Mono Nerd Font
      font-size = 12

      # Window
      background-opacity = 0.9
      window-padding-x = 10
      window-padding-y = 10

      # Clipboard
      clipboard-read = allow
      clipboard-write = allow

      # Shell integration
      shell-integration = zsh

      # Wallust colors (auto-generated from wallpaper)
      config-file = /home/lucid/.config/ghostty/colors.conf
    '';
  };

  # Note: wallust templates/config come from dotfiles
  # Add ghostty template to your dotfiles wallust/templates/ folder manually

  ############################################
  # DIRENV (auto-load nix shells per project)
  ############################################
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      # Auto-load R project shells — create .envrc in R project dirs:
      #   echo 'use flake' > .envrc
      #   direnv allow
      # Then flake.nix in that dir should use pkgs.rWrapper + pkgs.rPackages
    '';
  };

  ############################################
  # SWAYNC (notification center)
  ############################################
  xdg.configFile."swaync/config.json" = {
    text = ''
      {
        "$schema": "/etc/xdg/swaync/config.json",
        "positionX": "right",
        "positionY": "top",
        "layer": "overlay",
        "control-center-margin-top": 10,
        "control-center-margin-right": 10,
        "control-center-margin-bottom": 10,
        "control-center-margin-left": 0,
        "notification-2fa-action": true,
        "notification-inline-replies": true,
        "notification-window-width": 420,
        "notification-window-height": -1,
        "timeout": 5,
        "timeout-low": 3,
        "timeout-critical": 0,
        "fit-to-screen": true,
        "keyboard-shortcuts": true,
        "image-radius": 12
      }
    '';
  };

  home.file.".local/bin/notify-send" = lib.mkIf (!isWsl) {
    source = "${pkgs.libnotify}/bin/notify-send";
    executable = true;
  };

  systemd.user.services.swaync = lib.mkIf (!isWsl) {
    Unit = {
      Description = "Swaync notification daemon";
      Documentation = [ "https://github.com/ErikReider/SwayNotificationCenter" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      Restart = "on-failure";
    };
  };

  # Swaync CSS is generated by wallust: ~/.config/swaync/style.css
  # Run 'wallust run' after rebuild to apply colors

  ############################################
  # WSL: dynamic Windows home detection
  ############################################
  programs.zsh.initExtra = lib.mkIf isWsl ''
    # Detect Windows home directory dynamically (works for any Windows username)
    if [[ -z "$WIN_HOME" ]]; then
      export WIN_HOME=$(wslpath "$(powershell.exe -NoProfile -NonInteractive -Command Write-Output '$env:USERPROFILE' 2>/dev/null | tr -d '\\r\\n')" 2>/dev/null)
    fi
  '';

  ############################################
  # STATE VERSION
  ############################################
  home.stateVersion = "25.05";
}
