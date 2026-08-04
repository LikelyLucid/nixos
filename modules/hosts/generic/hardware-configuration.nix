{ ... }:
{
  # Replace these placeholder values with generated hardware configuration
  # before deploying the generic host.
  nixos.modules.generic = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };
}
