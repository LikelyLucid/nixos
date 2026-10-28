{ ... }:
{
  # Installation template only. Replace with this machine's generated hardware
  # settings, keeping them inside the deferred module below.
  nixos.modules.agent-server = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "xhci_pci"
      "usb_storage"
      "sd_mod"
    ];
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };
}
