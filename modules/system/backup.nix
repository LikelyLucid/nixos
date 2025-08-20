############################################
# BACKUP CONFIGURATION MODULE
############################################

{ config, lib, pkgs, ... }:

{
  ############################################
  # SYSTEM BACKUP TOOLS
  ############################################
  
  environment.systemPackages = with pkgs; [
    # Backup tools
    rsync           # File synchronization
    rclone          # Cloud storage sync
    borgbackup      # Deduplicating backup
    restic          # Modern backup tool
    
    # Archive tools
    zip
    unzip
    p7zip
    tar
  ];

  ############################################
  # AUTOMATED BACKUPS (OPTIONAL)
  ############################################
  
  # Example systemd service for automated backups
  # Uncomment and configure as needed
  
  # systemd.services.backup-home = {
  #   description = "Backup user home directory";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "lucid";
  #     ExecStart = "${pkgs.rsync}/bin/rsync -av --delete /home/lucid/ /backup/home/";
  #   };
  # };
  
  # systemd.timers.backup-home = {
  #   description = "Run home backup daily";
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #   };
  #   wantedBy = [ "timers.target" ];
  # };

  ############################################
  # SNAPSHOT MANAGEMENT
  ############################################
  
  # Enable Btrfs snapshots if using Btrfs filesystem
  # services.snapper = {
  #   configs = {
  #     home = {
  #       SUBVOLUME = "/home";
  #       ALLOW_GROUPS = [ "wheel" ];
  #       TIMELINE_CREATE = true;
  #       TIMELINE_CLEANUP = true;
  #     };
  #   };
  # };
}