{
  config,
  inputs,
  ...
}:
{
  nixos.modules.wsl =
    { pkgs, ... }:
    {
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
      # HOSTNAME & NETWORKING
      ############################################
      networking.hostName = "nixos-wsl";

      ############################################
      # USERS
      ############################################
      users.users.lucid.extraGroups = [
        "wheel"
        "docker"
      ];

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
      environment.systemPackages = with pkgs; [
        curl
        git
        gh
        htop
        lazygit
        wget
        docker-compose
      ];

      ############################################
      # GIT AUTH - gh CLI as the GitHub credential helper
      ############################################
      # gh persists creds in ~/.config/gh (survives rebuilds); one system
      # gitconfig line makes `git push` work after `gh auth login`.
      environment.etc.gitconfig.text = ''
        [credential "https://github.com"]
          helper = !gh auth git-credential
      '';

      ############################################
      # STATE VERSION
      ############################################
      system.stateVersion = "25.05";

    };

  nixos.configurations.nixos-wsl.modules = [
    inputs.nixos-wsl.nixosModules.wsl
    config.nixos.modules.common
    config.nixos.modules.wsl
  ];
}
