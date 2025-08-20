############################################
# PERFORMANCE OPTIMIZATION MODULE
############################################

{ config, lib, pkgs, ... }:

{
  ############################################
  # BOOT OPTIMIZATION
  ############################################
  
  # Optimize boot process
  boot = {
    # Reduce systemd timeout
    systemd = {
      services = {
        # Reduce network wait time
        "systemd-networkd-wait-online".serviceConfig.TimeoutStartSec = 10;
      };
    };
    
    # Load modules early for better boot performance
    initrd = {
      verbose = false;
      systemd.enable = true;
    };
    
    # Kernel parameters for performance
    kernelParams = [
      "quiet"           # Reduce boot noise
      "splash"          # Show splash screen
      "mitigations=off" # Disable CPU mitigations for performance (less secure but faster)
    ];
  };

  ############################################
  # SYSTEM PERFORMANCE
  ############################################
  
  # Enable zram swap for better memory management
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # Optimize I/O scheduler for SSD
  services.udev.extraRules = ''
    # Set I/O scheduler to none for NVMe drives (they have their own queue management)
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    # Set I/O scheduler to mq-deadline for SATA SSDs
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
  '';

  # Enable transparent hugepages for performance
  boot.kernel.sysctl = {
    # Memory management
    "vm.swappiness" = 10;                    # Reduce swapping
    "vm.dirty_ratio" = 15;                   # Dirty pages ratio
    "vm.dirty_background_ratio" = 5;         # Background dirty pages
    "vm.vfs_cache_pressure" = 50;           # VFS cache pressure
    
    # Network performance
    "net.core.default_qdisc" = "fq";        # Fair queueing scheduler
    "net.ipv4.tcp_congestion_control" = "bbr"; # BBR congestion control
    
    # File system performance
    "fs.file-max" = 2097152;                # Max open files
  };

  ############################################
  # CPU FREQUENCY SCALING
  ############################################
  
  # Enable CPU frequency scaling
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
  };

  # Advanced CPU power management
  services.power-profiles-daemon.enable = false; # Conflicts with TLP
  
  ############################################
  # HARDWARE ACCELERATION
  ############################################
  
  # Enable hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Intel GPU support
  boot.kernelModules = [ "i915" ];
  environment.variables = {
    VDPAU_DRIVER = "va_gl";
  };
}