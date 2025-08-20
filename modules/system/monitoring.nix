############################################
# SYSTEM MONITORING MODULE
############################################

{ config, lib, pkgs, ... }:

{
  ############################################
  # SYSTEM MONITORING TOOLS
  ############################################
  
  environment.systemPackages = with pkgs; [
    # System monitoring
    btop        # Better top alternative
    iotop       # I/O monitoring
    nethogs     # Network monitoring per process
    nmon        # System performance monitor
    
    # System information
    neofetch    # System info display
    lshw        # Hardware information
    usbutils    # USB device utilities
    smartmontools # Hard drive health monitoring
    
    # Network tools
    nmap        # Network scanner
    traceroute  # Network path tracing
    tcpdump     # Network packet analyzer
  ];

  ############################################
  # SYSTEM SERVICES
  ############################################
  
  # Enable SMART monitoring for hard drives
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # Enable locate database for fast file finding
  services.locate = {
    enable = true;
    package = pkgs.mlocate;
    interval = "hourly";
  };

  # Enable fstrim for SSD maintenance
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Enable printing support (CUPS)
  services.printing.enable = true;
  
  # Auto-discover network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}