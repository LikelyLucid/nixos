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

      ############################################
      # BOOTLOADER
      ############################################
      boot.loader.systemd-boot.enable = false;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.timeout = 8;
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = false;
        default = 0;
        configurationLimit = 10;
        # Keep NixOS first, Windows second, and the native generations submenu
        # last. Do not rename generations: their dates/versions aid recovery.
        extraEntriesBeforeNixOS = false;
        useOSProber = false;
        extraEntries = ''
          menuentry "Windows" --class windows --id windows {
            insmod part_gpt
            insmod fat
            insmod chain
            search --no-floppy --fs-uuid --set=root 2EE8-4266
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
          submenu "Firmware & power" --class submenu --id firmware-power {
            menuentry "BIOS / UEFI settings" --id firmware-settings {
              insmod efifwsetup
              fwsetup
            }
            menuentry "Restart" --id restart {
              reboot
            }
            menuentry "Shut down" --id shutdown {
              halt
            }
          }
        '';
        gfxmodeEfi = "1920x1200,1920x1080,1280x800,1024x768,auto";
        splashImage = null;
        # Snapshot of the desktop's Wallust palette. Boot must not depend on
        # mutable home-directory files or the Windows partition being mounted.
        theme = pkgs.runCommand "lucid-grub-theme" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          mkdir -p "$out"
          ${pkgs.grub2}/bin/grub-mkfont \
            -n "JetBrains Mono" -s 24 \
            -o "$out/jetbrains-mono-24.pf2" \
            ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf
          # Use the pinned copy of the desktop wallpaper, darkened for contrast.
          magick ${inputs.dotfiles}/media/wallpapers/wallpaper.jpg \
            -resize '1920x1200^' -gravity center -extent 1920x1200 \
            -fill '#00000b' -colorize 60 "$out/background.png"
          for part in c n s e w nw ne sw se; do
            magick -size 8x8 xc:'#182034' "$out/selected_$part.png"
          done
          cp ${pkgs.writeText "lucid-grub-theme.txt" ''
            desktop-image: "background.png"
            desktop-image-scale-method: "crop"
            desktop-color: "#00000b"
            title-text: ""
            message-font: "JetBrains Mono Regular 24"
            message-color: "#dfe9f6"
            message-bg-color: "#00000b"
            terminal-font: "JetBrains Mono Regular 24"
            + label {
              left = 10%
              top = 18%
              width = 80%
              height = 40
              text = "LUCID / BOOT"
              font = "JetBrains Mono Regular 24"
              color = "#7f91cd"
            }
            + label {
              left = 10%
              top = 26%
              width = 80%
              height = 35
              text = "Choose your operating system"
              font = "JetBrains Mono Regular 24"
              color = "#dfe9f6"
            }
            + boot_menu {
              left = 10%
              top = 36%
              width = 80%
              height = 40%
              item_font = "JetBrains Mono Regular 24"
              selected_item_font = "JetBrains Mono Regular 24"
              item_color = "#8c97a3"
              selected_item_color = "#dfe9f6"
              item_height = 54
              item_padding = 12
              item_spacing = 8
              icon_width = 0
              icon_height = 0
              selected_item_pixmap_style = "selected_*.png"
              scrollbar = false
            }
            + label {
              left = 10%
              top = 82%
              width = 80%
              height = 35
              text = "Enter: boot / open    Esc: back    Arrows: select"
              font = "JetBrains Mono Regular 24"
              color = "#8c97a3"
            }
            + label {
              id = "__timeout__"
              left = 10%
              top = 89%
              width = 80%
              height = 35
              text = "Starting NixOS in %d seconds"
              font = "JetBrains Mono Regular 24"
              color = "#7f91cd"
            }
          ''} "$out/theme.txt"
        '';
      };

      ############################################
      # HOSTNAME & NETWORKING
      ############################################
      networking.hostName = "artsxps";
      networking.networkmanager.enable = true;
      networking.networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeShellScript "home-remote-access-dispatcher" ''
            case "$2:$CONNECTION_ID" in
              up:C4\ Remote\ Receiver|up:C4\ Remote\ Receiver\ 5g)
                ${pkgs.systemd}/bin/systemctl start home-remote-access.service
                ;;
              down:C4\ Remote\ Receiver|down:C4\ Remote\ Receiver\ 5g)
                ${pkgs.systemd}/bin/systemctl stop home-remote-access.service
                ;;
            esac
          '';
        }
      ];
      networking.firewall = {
        allowedTCPPorts = [
          22
          22000
        ];
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
      services.fwupd.enable = true;

      services.thermald.enable = true;
      # Suspend normally away from home; the NetworkManager dispatcher inhibits
      # suspend and lid-close sleep while connected to the home Wi-Fi.
      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandleLidSwitchDocked = "suspend";
        IdleAction = "suspend";
        IdleActionSec = "30min";
      };
      systemd.services.home-remote-access = {
        description = "Keep artsxps reachable on the home network";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle:sleep:handle-lid-switch --why=Home-Wi-Fi-remote-access --who=artsxps ${pkgs.coreutils}/bin/sleep infinity";
          Restart = "on-failure";
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
        wireplumber.extraConfig."disable-oppo-audio-autoconnect"."monitor.bluez.rules" = [
          {
            matches = [
              { "device.name" = "bluez_card.9C_FB_77_8A_67_D0"; }
            ];
            actions.update-props."bluez5.auto-connect" = [ ];
          }
        ];
      };

      ############################################
      # KERNEL
      ############################################

      ############################################
      # PERFORMANCE TUNING
      ############################################
      zramSwap.enable = true;
      systemd.oomd.enableUserSlices = true;

      # SSD TRIM
      services.fstrim.enable = true;

      # Spread hardware IRQs across all CPU cores
      services.irqbalance.enable = true;

      # OOM killer is already active via systemd-oomd.service
      # No NixOS module needed — it comes with systemd

      boot.kernel.sysctl = {
        # Prefer compressed-RAM swap over reclaiming hot filesystem cache.
        "vm.swappiness" = 100;
        "vm.page-cluster" = 0;
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
