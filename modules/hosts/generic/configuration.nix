{ config, ... }:
{
  nixos.modules.generic =
    { pkgs, ... }:
    {
      ############################################
      # HOSTNAME & NETWORKING
      ############################################
      networking.hostName = "nixos";
      networking.networkmanager.enable = true;

      ############################################
      # USERS
      ############################################
      users.users.lucid.extraGroups = [ "wheel" ];

      ############################################
      # REMOTE ACCESS
      ############################################
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      ############################################
      # BASIC PACKAGES
      ############################################
      environment.systemPackages = with pkgs; [
        curl
        git
        htop
        pciutils
        unzip
        wget
        zip
      ];

      ############################################
      # STATE VERSION
      ############################################
      system.stateVersion = "25.05";
    };

  nixos.configurations.generic.modules = [
    config.nixos.modules.common
    config.nixos.modules.generic
  ];
}
