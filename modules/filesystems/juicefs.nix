{ ... }:
{
  nixos.modules.artsxps =
    {
      config,
      pkgs,
      ...
    }:
    let
      juicefs = pkgs.juicefs.overrideAttrs (_: {
        version = "1.4.0";

        src = pkgs.fetchFromGitHub {
          owner = "juicedata";
          repo = "juicefs";
          rev = "v1.4.0";
          hash = "sha256-H9NUEzhMd+EdfJXbww0k9aOv3oTbUoGddWrQl72raDQ=";
        };

        vendorHash = "sha256-JoWsoUFbP2v9g2RUBp5wK/TdguWcYPwhH8hqatzyBew=";

        # Fix the /dev/fuse descriptor leak that deadlocks on Linux 7.1.3.
        postPatch = ''
          substituteInPlace pkg/fuse/device_linux.go \
            --replace-fail 'os.Open("/dev/fuse")' 'os.Stat("/dev/fuse")'
        '';

        ldflags = [
          "-s"
          "-w"
          "-X github.com/juicedata/juicefs/pkg/version.version=1.4.0"
        ];
      });

      mount_juicefs = pkgs.writeShellApplication {
        name = "mount-juicefs";
        text = ''
          META_PASSWORD="$(<${config.sops.secrets.juicefs-meta-password.path})"
          export META_PASSWORD
          exec ${juicefs}/bin/juicefs mount \
            redis://redis.likelylucid.com:6379/2 \
            /mnt/juicefs \
            --cache-dir /var/cache/juicefs \
            -o allow_other
        '';
      };

      prepare_juicefs = pkgs.writeShellApplication {
        name = "prepare-juicefs";
        runtimeInputs = [ pkgs.util-linux ];
        text = ''
          if findmnt --mountpoint /mnt/juicefs >/dev/null; then
            umount --lazy /mnt/juicefs
          fi
          ${pkgs.coreutils}/bin/ln -sfn ${pkgs.fuse}/bin/fusermount /bin/fusermount
        '';
      };

      unmount_juicefs = pkgs.writeShellApplication {
        name = "unmount-juicefs";
        runtimeInputs = [
          pkgs.fuse
          pkgs.util-linux
        ];
        text = ''
          if findmnt --mountpoint /mnt/juicefs >/dev/null; then
            if ! ${juicefs}/bin/juicefs umount --force /mnt/juicefs; then
              umount --lazy /mnt/juicefs || true
            fi
          fi
        '';
      };
    in
    {
      environment.systemPackages = [
        juicefs
        pkgs.fuse
      ];

      programs.fuse.userAllowOther = true;

      sops.secrets.juicefs-meta-password = {
        mode = "0400";
        restartUnits = [ "juicefs.service" ];
      };

      systemd.tmpfiles.rules = [ "d /mnt/juicefs 0755 root root -" ];

      systemd.services.juicefs = {
        description = "JuiceFS mount";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStartPre = "${prepare_juicefs}/bin/prepare-juicefs";
          ExecStart = "${mount_juicefs}/bin/mount-juicefs";
          ExecStop = "${unmount_juicefs}/bin/unmount-juicefs";
          ExecStopPost = "${unmount_juicefs}/bin/unmount-juicefs";
          CacheDirectory = "juicefs";
          CacheDirectoryMode = "0700";
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 15;
        };
      };
    };
}
