{
  config,
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      herdr_workspace_manager = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-plugin-workspace-manager";
        version = "0.6.0";
        src = inputs.herdr-workspace-manager;
        cargoLock.lockFile = inputs.herdr-workspace-manager + "/Cargo.lock";

        postInstall = ''
          install -Dm644 herdr-plugin.toml $out/herdr-plugin.toml
          substituteInPlace $out/herdr-plugin.toml \
            --replace-fail '["sh", "bin/herdr-workspace-manager"' '["bin/herdr-workspace-manager"'
        '';

        meta = {
          description = "Declarative workspace layouts for Herdr";
          homepage = "https://github.com/razajamil/herdr-plugin-workspace-manager";
          license = pkgs.lib.licenses.mit;
          mainProgram = "herdr-workspace-manager";
          platforms = pkgs.lib.platforms.unix;
        };
      };
    in
    {
      packages.herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
      packages.herdr-workspace-manager = herdr_workspace_manager;
    };

  nixos.modules.common.nixpkgs.overlays = [
    (final: _prev: {
      herdr = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr;
      herdr-workspace-manager =
        config.flake.packages.${final.stdenv.hostPlatform.system}.herdr-workspace-manager;
    })
  ];

  homeManager.modules.common =
    { lib, pkgs, ... }:
    {
      home.packages = [
        pkgs.herdr
        pkgs.herdr-workspace-manager
      ];

      home.activation.linkHerdrWorkspaceManager = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        activation_socket=/tmp/herdr-home-manager-$UID.sock
        run rm -f "$activation_socket"
        run env HERDR_SOCKET_PATH="$activation_socket" \
          ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-workspace-manager}
      '';
    };
}
