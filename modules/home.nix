{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    let
      home_dir = "/home/lucid";
    in
    {
      ############################################
      # USER DETAILS
      ############################################
      home.username = "lucid";
      home.homeDirectory = home_dir;

      ############################################
      # SOPS
      ############################################
      sops.defaultSopsFile = ../secrets/secrets.yaml;

      ############################################
      # HOME PACKAGES
      # Organised by category for easy maintenance
      ############################################
      home.packages = with pkgs; [
        ########################################
        # RUNTIME ENVIRONMENTS
        ########################################
        nodejs # JavaScript runtime (includes Corepack shims)
        pnpm # Content-addressed dependency store shared across worktrees
        bun # Fast all-in-one JS/TS runtime
        go # Go programming language
        python3 # Python runtime
        uv # Fast Python package manager

        ########################################
        # AI / AGENT DEVELOPMENT TOOLS
        ########################################
        pi-coding-agent # pi coding agent (from lukasl-dev/pi.nix overlay)
        opencode # Terminal UI for LLMs

        ########################################
        # ENHANCED CLI TOOLS
        ########################################
        choose # Human-friendly field selection for command pipelines
        entr # Minimal file watcher for shell pipelines
        fd # `find` replacement that's fast and intuitive
        just # Command runner — like make but modern
        yq # YAML/JSON/XML processor (like jq for everything)
        jq # JSON processor
        ripgrep # `grep` replacement — fast recursive search
        sd # Simpler command-line search and replace
        hyperfine # Command benchmarking tool
        watchexec # Rerun commands when files change
        trash-cli # Safe terminal trash instead of permanent rm
        tealdeer # Fast tldr command examples
        file
        tree
        rsync
        lsof
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
      };

      ############################################
      # DIRENV (auto-load nix shells per project)
      ############################################
      programs.direnv = {
        enable = true;
        config.global = {
          hide_env_diff = true;
          load_dotenv = true;
          strict_env = true;
          warn_timeout = "30s";
        };
        nix-direnv.enable = true;
        silent = true;
        stdlib = ''
          # Auto-load R project shells — create .envrc in R project dirs:
          #   echo 'use flake' > .envrc
          #   direnv allow
          # Then flake.nix in that dir should use pkgs.rWrapper + pkgs.rPackages
        '';
      };

      ############################################
      # STATE VERSION
      ############################################
      home.stateVersion = "25.05";
    };
}
