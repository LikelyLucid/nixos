{ ... }:
{
  nixos.modules.artsxps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      juicefs = pkgs.stdenvNoCC.mkDerivation {
        pname = "juicefs";
        version = "1.4.0";

        src = pkgs.fetchurl {
          url = "https://github.com/juicedata/juicefs/releases/download/v1.4.0/juicefs-1.4.0-linux-amd64.tar.gz";
          hash = "sha256-be3XMEh+fawbEcWAFoKolpLy5rl4kLr3rJQ0B1ALhas=";
        };

        dontUnpack = true;
        installPhase = ''
          runHook preInstall

          tar -xzf "$src"
          install -Dm755 juicefs "$out/bin/juicefs"
          ln -s juicefs "$out/bin/mount.juicefs"

          runHook postInstall
        '';

        meta = {
          description = "Distributed POSIX file system built on top of Redis and S3";
          homepage = "https://www.juicefs.com/";
          license = lib.licenses.asl20;
          mainProgram = "juicefs";
          platforms = [ "x86_64-linux" ];
        };
      };

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
