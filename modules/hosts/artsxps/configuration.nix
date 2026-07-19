{
  config,
  inputs,
  ...
}:
{
  nixos.modules.artsxps =
    { pkgs, ... }:
    let
      apply_battery_brightness = pkgs.writeShellApplication {
        name = "apply-battery-brightness";
        runtimeInputs = [ pkgs.brightnessctl ];
        text = ''
          state_file=/run/artsxps-ac-brightness
          max_brightness=$(brightnessctl --device=intel_backlight max)
          current_brightness=$(brightnessctl --device=intel_backlight get)

          if [[ $(< /sys/class/power_supply/AC/online) == 1 ]]; then
            if [[ -r $state_file ]]; then
              saved_brightness=$(< "$state_file")
              if (( saved_brightness > 0 && saved_brightness <= max_brightness )); then
                brightnessctl --quiet --device=intel_backlight set "$saved_brightness"
              fi
              rm -f "$state_file"
            fi
          else
            battery_cap=$((max_brightness * 35 / 100))
            if (( current_brightness > battery_cap )); then
              printf '%s\n' "$current_brightness" > "$state_file"
              brightnessctl --quiet --device=intel_backlight set "$battery_cap"
            fi
          fi
        '';
      };
    in
    {
      ############################################
      # BITWARDEN SECRETS (self-hosted Vaultwarden)
      ############################################
      # bitwarden is disabled temporarily to simplify boot debugging
      bitwarden.enable = false;
      bitwarden.serverUrl = "https://vaultwarden.likelylucid.com";
      bitwarden.auth.method = "api-key";
      bitwarden.secrets = {
        tailscale-auth-key = {
          item = "Tailscale Auth Key";
          field = "password";
        };
      };

      ############################################
      # BOOTLOADER
      ############################################
      boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.grub.default = 0;

      ############################################
      # HOSTNAME & NETWORKING
      ############################################
      networking.hostName = "artsxps";
      networking.networkmanager.enable = true;
      networking.firewall = {
        allowedTCPPorts = [ 22000 ];
        allowedUDPPorts = [
          21027
          22000
        ];
      };

      hardware.bluetooth.enable = true;
      services.blueman.enable = true;

      # Disable btusb driver autosuspend so Intel AX211 doesn't drop connections
      boot.extraModprobeConfig = ''
        options btusb enable_autosuspend=N
      '';

      ############################################
      # KDE CONNECT
      ############################################
      programs.kdeconnect.enable = true;

      ############################################
      # POWER MANAGEMENT
      ############################################
      services.linux-enable-ir-emitter.enable = true;
      services.fwupd.enable = true;

      services.howdy = {
        enable = true;
        control = "sufficient";
        settings.video.dark_threshold = 100;
      };

      # Only use howdy for greetd (login screen), not sudo/polkit
      security.pam.howdy.enable = false;
      security.pam.services.greetd.howdy.enable = true;

      services.thermald.enable = true;
      # Clamshell mode: don't suspend when lid closes (use external monitor)
      services.logind.settings = {
        Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };
      };

      systemd.services.battery-display-brightness = {
        description = "Apply battery-aware display brightness";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${apply_battery_brightness}/bin/apply-battery-brightness";
        };
      };

      services.udev.extraRules = ''
        ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC", RUN+="${apply_battery_brightness}/bin/apply-battery-brightness"
      '';

      services.tlp = {
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
          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "quiet";
          PCIE_ASPM_ON_BAT = "powersupersave";
          DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
          # Prevent USB autosuspend of Bluetooth adapter — Buds2 Pro disconnect otherwise
          USB_EXCLUDE_BTUSB = "1";
        };
      };

      ############################################
      # AUDIO
      ############################################
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        # Better audio quality settings
        extraConfig.pipewire."92-high-quality" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
            ];
            "default.clock.quantum" = 1024;
            "default.clock.min-quantum" = 256;
            "default.clock.max-quantum" = 2048;
          };
        };
      };

      ############################################
      # KERNEL
      ############################################
      boot.kernelPackages = pkgs.linuxPackages_latest;

      ############################################
      # PERFORMANCE TUNING
      ############################################
      zramSwap.enable = true;

      # SSD TRIM
      services.fstrim.enable = true;

      # Spread hardware IRQs across all CPU cores
      services.irqbalance.enable = true;

      # OOM killer is already active via systemd-oomd.service
      # No NixOS module needed — it comes with systemd

      boot.kernel.sysctl = {
        # Lower swappiness = keep things in RAM longer, good for SSDs
        "vm.swappiness" = 10;
        # Keep more filesystem metadata cached
        "vm.vfs_cache_pressure" = 50;
        # Write dirty pages to disk sooner — less RAM tied up, less stutter
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        # Increase TCP buffer maxes for better network throughput
        "net.core.rmem_max" = 134217728;
        "net.core.wmem_max" = 134217728;
      };

      ############################################
      # USERS
      ############################################
      users.users.lucid.extraGroups = [
        "networkmanager"
        "wheel"
      ];

      ############################################
      # PACKAGES & PROGRAMS
      ############################################
      environment.systemPackages = with pkgs; [
        easyeffects # Audio effects/EQ (PipeWire compatible)
        ydotool # Wayland input injection (mouse/keyboard control)
        git
        gh
        htop
        lazygit
        pciutils
        pulsemixer # Terminal audio mixer
        syncthing
        wget
      ];

      ############################################
      # COMPATIBILITY UTILITIES
      ############################################
      # nix-ld: provides /lib64/ld-linux-x86-64.so.2 for prebuilt binaries like exec_bridge
      programs.nix-ld.enable = true;

      systemd.tmpfiles.rules = [
        "L /usr/bin/which - - - - ${pkgs.which}/bin/which"
      ];
      ############################################
      # FONTS
      ############################################
      fonts.packages = with pkgs; [
        jetbrains-mono
        pkgs.nerd-fonts.jetbrains-mono
      ];

      ############################################
      # STATE VERSION
      ############################################
      system.stateVersion = "25.05";
    };

  nixos.configurations.artsxps.modules = [
    inputs.nixos-hardware.nixosModules.dell-xps-15-9530
    config.nixos.modules.common
    config.nixos.modules.desktop
    config.nixos.modules.artsxps
  ];
}
