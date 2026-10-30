{ getSystem, ... }:
{
  nixos.modules.agent-server =
    { pkgs, lib, ... }:
    let
      t3_server = (getSystem pkgs.stdenv.hostPlatform.system).packages.t3-server;
    in
    {
      environment.systemPackages = [ t3_server ];
      systemd.services.t3-server = {
        description = "T3 Code headless coding server";
        wantedBy = [ "multi-user.target" ];
        wants = [
          "network-online.target"
          "tailscaled.service"
          "tailscaled-autoconnect.service"
        ];
        after = [
          "network-online.target"
          "tailscaled.service"
          "home-manager-lucid.service"
          "tailscaled-autoconnect.service"
        ];
        environment = {
          HOME = "/home/lucid";
          PATH = lib.mkForce "/etc/profiles/per-user/lucid/bin:/home/lucid/.nix-profile/bin:/run/current-system/sw/bin";
        };
        serviceConfig = {
          User = "lucid";
          WorkingDirectory = "/home/lucid";
          ExecStart = "${t3_server}/bin/t3 serve --host 127.0.0.1 --port 3773 --tailscale-serve";
          Restart = "always";
          RestartSec = "15s";
          UMask = "0077";
        };
      };
    };
}
