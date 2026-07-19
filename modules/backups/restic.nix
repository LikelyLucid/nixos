{ ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.restic ];

      services.restic.backups.home = {
        initialize = true;
        inhibitsSleep = true;
        repositoryFile = "/etc/restic/repository";
        passwordFile = "/run/secrets/restic-password";
        paths = [ "/home/lucid" ];
        exclude = [
          "/home/lucid/.cache"
          "/home/lucid/.local/share/Trash"
          "/home/lucid/.npm"
          "/home/lucid/.cargo/registry"
          "/home/lucid/.rustup"
          "/home/lucid/.bun/install/cache"
          "**/node_modules"
          "**/__pycache__"
          "**/.direnv"
        ];
        extraBackupArgs = [ "--exclude-caches" ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 3"
        ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };

      # Keep the dormant scaffold from producing failed units before an
      # off-device repository and its sops-managed password are provisioned.
      systemd.services.restic-backups-home.unitConfig.ConditionPathExists = [
        "/etc/restic/repository"
        "/run/secrets/restic-password"
      ];
    };
}
