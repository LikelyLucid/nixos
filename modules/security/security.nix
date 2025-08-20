############################################
# SECURITY CONFIGURATION MODULE
############################################

{ config, lib, pkgs, ... }:

{
  ############################################
  # FIREWALL CONFIGURATION
  ############################################
  
  # Enable the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      8384  # Syncthing GUI
    ];
    allowedUDPPorts = [ 
      22000 # Syncthing
    ];
    
    # Allow ping
    allowPing = true;
    
    # Log refused connections
    logRefusedConnections = false; # Disable to reduce log noise
  };

  ############################################
  # SYSTEM SECURITY
  ############################################
  
  # Disable sudo password for wheel group (optional, comment out for more security)
  # security.sudo.wheelNeedsPassword = false;
  
  # Enable polkit for privilege escalation
  security.polkit.enable = true;
  
  # AppArmor security framework
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  ############################################
  # AUTOMATIC UPDATES & MAINTENANCE  
  ############################################
  
  # Enable automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Optimize nix store automatically
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ]; # Run at 3:45 AM daily
  };

  # Automatically upgrade system packages
  system.autoUpgrade = {
    enable = false; # Disable for manual control, enable if you want auto-updates
    dates = "04:40";
    flake = "/home/lucid/nixos";
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
  };
}