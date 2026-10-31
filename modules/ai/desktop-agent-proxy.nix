{ inputs, ... }:
{
  nixos.modules.artsxps =
    { pkgs, lib, ... }:
    {
      # Desktop and PATH use the same unwrapped native Codex executable/config.
      programs.codexDesktopLinux.cliPackage =
        lib.mkForce
          inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      sops.secrets = {
        agent-proxy-api-key = {
          sopsFile = ../../secrets/agent-server.yaml;
          key = "cli-proxy-api-key";
          owner = "lucid";
          mode = "0400";
          restartUnits = [ "agent-proxy-config.service" ];
        };
        agent-proxy-base-url = {
          sopsFile = ../../secrets/agent-server.yaml;
          key = "cli-proxy-base-url";
          owner = "lucid";
          mode = "0400";
          restartUnits = [ "agent-proxy-config.service" ];
        };
      };
    };
}
