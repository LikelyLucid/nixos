{ getSystem, ... }:
{
  nixos.modules.agent-server =
    { pkgs, lib, ... }:
    let
      t3_server = (getSystem pkgs.stdenv.hostPlatform.system).packages.t3-server;
      bootstrap = pkgs.writeShellApplication {
        name = "bootstrap-t3-service";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.systemd
        ];
        text = builtins.readFile ../../scripts/bootstrap-t3-service.sh;
      };
      t3_command = pkgs.writeShellScriptBin "t3" ''
        if [ -x "$HOME/.local/bin/t3" ]; then
          exec "$HOME/.local/bin/t3" "$@"
        fi
        exec ${t3_server}/bin/t3 "$@"
      '';
    in
    {
      environment.systemPackages = [ (lib.hiPrio t3_command) ];
      systemd.services.t3-server = {
        description = "Install and enable T3 Code's updatable user service";
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
          PATH = lib.mkForce "/home/lucid/.local/bin:/etc/profiles/per-user/lucid/bin:/home/lucid/.nix-profile/bin:/run/current-system/sw/bin";
          T3_BOOTSTRAP_CLI = "${t3_server}/bin/t3";
          T3_BOOTSTRAP_VERSION = t3_server.version;
        };
        serviceConfig = {
          User = "lucid";
          WorkingDirectory = "/home/lucid";
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "15min";
          ExecStart = "${bootstrap}/bin/bootstrap-t3-service";
          Restart = "on-failure";
          RestartSec = "15s";
          UMask = "0077";
        };
      };
    };

  homeManager.modules.agent-server = {
    # A drop-in leaves the main unit writable by `t3 update` / `service install`.
    xdg.configFile."systemd/user/t3code.service.d/10-agent-server.conf".text = ''
      [Service]
      Environment="PATH=/home/lucid/.local/bin:/etc/profiles/per-user/lucid/bin:/home/lucid/.nix-profile/bin:/run/current-system/sw/bin"
      Environment=T3CODE_MODE=web
      Environment=T3CODE_HOST=127.0.0.1
      Environment=T3CODE_PORT=3773
      Environment=T3CODE_TAILSCALE_SERVE=true
      UMask=0077
    '';
  };

}
