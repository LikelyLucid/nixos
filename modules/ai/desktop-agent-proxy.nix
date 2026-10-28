{ inputs, getSystem, ... }:
{
  nixos.modules.artsxps = { pkgs, lib, ... }: {
    # The desktop app starts cliPackage directly rather than looking up PATH.
    programs.codexDesktopLinux.cliPackage = lib.mkForce (
      pkgs.writeShellScriptBin "codex" ''
        export CLI_PROXY_API_KEY_FILE=/run/secrets/agent-proxy-api-key
        export CLI_PROXY_BASE_URL_FILE=/run/secrets/agent-proxy-base-url
        export CLI_PROXY_KEEP_AGENT_CONFIG=1
        exec ${pkgs.python3}/bin/python3 ${../../scripts/agent_proxy.py} codex ${
          lib.getExe inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        } "$@"
      ''
    );
    sops.secrets = {
      agent-proxy-api-key = {
        sopsFile = ../../secrets/agent-server.yaml;
        key = "cli-proxy-api-key";
        owner = "lucid";
        mode = "0400";
      };
      agent-proxy-base-url = {
        sopsFile = ../../secrets/agent-server.yaml;
        key = "cli-proxy-base-url";
        owner = "lucid";
        mode = "0400";
      };
    };
  };

  homeManager.modules.desktop =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    lib.mkIf (osConfig.networking.hostName == "artsxps") (
      let
        proxy_command =
          name: command:
          pkgs.writeShellScriptBin name ''
            export CLI_PROXY_API_KEY_FILE=/run/secrets/agent-proxy-api-key
            export CLI_PROXY_BASE_URL_FILE=/run/secrets/agent-proxy-base-url
            export CLI_PROXY_KEEP_AGENT_CONFIG=1
            exec ${pkgs.python3}/bin/python3 ${../../scripts/agent_proxy.py} ${command} "$@"
          '';
        agent_wrapper = name: package: lib.hiPrio (proxy_command name "${name} ${lib.getExe package}");
      in
      {
        home.packages = [
          (agent_wrapper "codex" inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default)
          (agent_wrapper "opencode" (getSystem pkgs.stdenv.hostPlatform.system).packages.opencode-v2)
          (agent_wrapper "pi" pkgs.pi-coding-agent)
          (proxy_command "agent-models-refresh" "refresh")
        ];
      }
    );
}
