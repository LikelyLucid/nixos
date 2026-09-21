{
  config,
  inputs,
  lib,
  ...
}:
{
  nixos.modules.artslaptop =
    {
      config,
      modulesPath,
      pkgs,
      ...
    }:
    let
      disk = "/dev/disk/by-id/nvme-Micron_2210_MTFDHBA512QFD_21262FDEB212";
    in
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      ############################################
      # BOOT & STORAGE
      ############################################
      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "vmd"
          "nvme"
        ];
        kernelModules = [ "kvm-intel" ];
        kernelPackages = pkgs.linuxPackages_latest;
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot = {
            enable = true;
            configurationLimit = 10;
          };
        };
        extraModprobeConfig = ''
          options btusb enable_autosuspend=N
        '';
        kernel.sysctl = {
          "vm.swappiness" = 100;
          "vm.page-cluster" = 0;
          "vm.vfs_cache_pressure" = 50;
          "vm.dirty_ratio" = 10;
          "vm.dirty_background_ratio" = 5;
          "net.core.rmem_max" = 134217728;
          "net.core.wmem_max" = 134217728;
        };
      };

      disko.devices.disk.system = {
        type = "disk";
        device = disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      ############################################
      # HARDWARE
      ############################################
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware = {
        bluetooth.enable = true;
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
      services = {
        blueman.enable = true;
        fstrim.enable = true;
        fwupd.enable = true;
        irqbalance.enable = true;
        thermald.enable = true;
        logind.settings.Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
        tlp = {
          enable = true;
          settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
            CPU_MIN_PERF_ON_AC = 0;
            CPU_MAX_PERF_ON_AC = 100;
            CPU_MIN_PERF_ON_BAT = 0;
            CPU_MAX_PERF_ON_BAT = 60;
            CPU_BOOST_ON_AC = 1;
            CPU_BOOST_ON_BAT = 0;
            CPU_HWP_DYN_BOOST_ON_AC = 1;
            CPU_HWP_DYN_BOOST_ON_BAT = 0;
            PCIE_ASPM_ON_BAT = "powersupersave";
            DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
            USB_EXCLUDE_BTUSB = "1";
          };
        };
      };
      security.rtkit.enable = true;
      zramSwap.enable = true;
      systemd.oomd.enableUserSlices = true;

      ############################################
      # NETWORKING & ACCESS
      ############################################
      networking = {
        hostName = "artslaptop";
        networkmanager.enable = true;
        firewall = {
          allowedTCPPorts = [ 22000 ];
          allowedUDPPorts = [
            21027
            22000
          ];
        };
      };
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
      programs.kdeconnect.enable = true;

      ############################################
      # USER
      ############################################
      users.users.lucid = {
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        hashedPasswordFile = "/etc/nixos/secrets/lucid-password-hash";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMru94PRn+dtPr0mFbgZ3NHpVQpUNQrRemTMk6QUqeBJ lucid@artsxps-2026-07-14"
        ];
      };

      ############################################
      # PACKAGES & PROGRAMS
      ############################################
      environment.systemPackages = with pkgs; [
        easyeffects
        gh
        git
        htop
        lazygit
        pciutils
        pulsemixer
        syncthing
        wget
        ydotool
      ];
      programs.nix-ld.enable = true;
      systemd.tmpfiles.rules = [
        "d /etc/nixos/secrets 0700 root root -"
        "L /usr/bin/which - - - - ${pkgs.which}/bin/which"
      ];
      fonts.packages = with pkgs; [
        jetbrains-mono
        nerd-fonts.jetbrains-mono
      ];

      system.stateVersion = "26.05";
    };

  nixos.configurations.artslaptop.modules = [
    inputs.disko.nixosModules.disko
    config.nixos.modules.common
    config.nixos.modules.desktop
    config.nixos.modules.artslaptop
  ];
}
