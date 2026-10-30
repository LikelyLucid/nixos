{ config, ... }:
{
  nixos.modules.artslaptop =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      boot.initrd.availableKernelModules = [
        "thunderbolt"
        "vmd"
      ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.loader.systemd-boot.configurationLimit = 10;
      fileSystems."/".device = "/dev/disk/by-uuid/026ebb9c-4b9c-4970-98a0-af1842db24a5";
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/CABC-5A57";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      services = {
        fwupd.enable = true;
        irqbalance.enable = true;
        thermald.enable = true;
      };
      networking = {
        hostName = "artslaptop";
        useDHCP = false;
        # Preserve the existing Wi-Fi profile and its credentials on the host.
        networkmanager.enable = true;
      };
      users.users.lucid.extraGroups = [ "networkmanager" ];
    };

  nixos.configurations.artslaptop.modules = [
    config.nixos.modules.common
    config.nixos.modules.agent-server
    config.nixos.modules.artslaptop
  ];
}
