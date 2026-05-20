{ pkgs, lib, ... }:
{
  ############################################
  # IMPORTS
  ############################################
  imports = [
    ../../modules/system/locale.nix
  ];

  ############################################
  # SOPSWARDEN (Bitwarden -> SOPS)
  ############################################
  services.sopswarden = {
    enable = true;
    secrets = {
      tailscale-auth-key = "Tailscale Auth Key";
    };
    installPackages = true;
    installSyncCommand = true;
  };

  ############################################
  # WSL
  ############################################
  wsl.enable = true;
  wsl.defaultUser = "lucid";
  wsl.wslConf.boot.systemd = true;

  # Better WSL interop - access Windows files from /mnt
  wsl.wslConf.interop.enabled = true;
  wsl.wslConf.interop.appendWindowsPath = true;

  # Automount Windows drives
  wsl.wslConf.automount.enabled = true;
  wsl.wslConf.automount.root = "/mnt";
  wsl.wslConf.automount.options = "metadata,umask=22,fmask=11";

  ############################################
  # NIX SETTINGS
  ############################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Auto-optimise store
  nix.settings.auto-optimise-store = true;

  ############################################
  # HOSTNAME & NETWORKING
  ############################################
  networking.hostName = "nixos-wsl";

  ############################################
  # USERS
  ############################################
  users.users.lucid = {
    isNormalUser = true;
    description = "Arthur Mckellar";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  ############################################
  # DOCKER (native Linux containers, great for WSL)
  ############################################
  virtualisation.docker = {
    enable = true;
    # Don't require sudo for docker commands
    enableOnBoot = true;
  };

  ############################################
  # SSH AGENT - forward from Windows
  ############################################
  programs.ssh.startAgent = true;

  ############################################
  # PACKAGES
  ############################################
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Core tools
    curl
    git
    gh
    htop
    jq
    lazygit
    tree
    unzip
    wget
    zip

    # Development essentials
    docker-compose
    file
    fzf
    ripgrep
    tmux

    # Monitoring
    btop
    dogdns
  ];

  ############################################
  # NH (Nix Helper)
  ############################################
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 5d --keep 5";
    flake = "/home/lucid/nixos";
  };

  ############################################
  # STATE VERSION
  ############################################
  system.stateVersion = "25.05";


}
