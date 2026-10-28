{ config, ... }:
{
  nixos.modules.agent-server =
    { pkgs, lib, ... }:
    {
      networking.hostName = lib.mkDefault "agent-server";
      networking.useDHCP = lib.mkDefault true;
      networking.firewall = {
        enable = true;
        interfaces.tailscale0.allowedTCPPorts = [ 22 ];
      };

      services.openssh = {
        enable = true;
        openFirewall = false;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      services.tailscale = {
        enable = true;
        openFirewall = true;
        extraSetFlags = [
          "--ssh"
          "--operator=lucid"
        ];
      };

      users.users.lucid = {
        extraGroups = [ "wheel" ];
        linger = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMru94PRn+dtPr0mFbgZ3NHpVQpUNQrRemTMk6QUqeBJ lucid@artsxps-2026-07-14"
        ];
      };
      # Set a local password with passwd during installation for console/sudo recovery.
      environment.systemPackages = with pkgs; [
        curl
        git
        htop
        pciutils
        wget
      ];
      # T3 SSH setup and service install download generic Linux Node runtimes.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          openssl
          libsecret
        ];
      };
      systemd.sleep.settings.Sleep = {
        AllowSuspend = "no";
        AllowHibernation = "no";
      };
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        IdleAction = "ignore";
      };
      services.fstrim.enable = true;
      zramSwap.enable = true;
      system.stateVersion = "26.05";
      home-manager.users.lucid.imports = [ config.homeManager.modules.agent-server ];
    };

  nixos.configurations.agent-server.modules = [
    config.nixos.modules.common
    config.nixos.modules.agent-server
  ];
}
