{ inputs, getSystem, ... }:
{
  homeManager.modules.agent-server =
    { pkgs, lib, ... }:
    let
      proxy_script = ../../scripts/agent_proxy.py;
      proxy_command =
        name: command:
        pkgs.writeShellScriptBin name ''
          export CLI_PROXY_API_KEY_FILE=/run/secrets/agent-proxy-api-key
          export CLI_PROXY_BASE_URL_FILE=/run/secrets/agent-proxy-base-url
          export AGENT_CUA_COMMAND=${(getSystem pkgs.stdenv.hostPlatform.system).packages.cua}/bin/cua
          exec ${pkgs.python3}/bin/python3 ${proxy_script} ${command} "$@"
        '';
      agent_wrapper = name: package: lib.hiPrio (proxy_command name "${name} ${lib.getExe package}");
    in
    {
      home.packages = [
        (agent_wrapper "codex" inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default)
        (agent_wrapper "claude" pkgs.claude-code)
        (agent_wrapper "opencode" (getSystem pkgs.stdenv.hostPlatform.system).packages.opencode-v2)
        (agent_wrapper "pi" pkgs.pi-coding-agent)
        (proxy_command "agent-models-refresh" "refresh")
      ];

      systemd.user.services.agent-models-refresh = {
        Unit.Description = "Discover CLI proxy models for coding agents";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.python3}/bin/python3 ${proxy_script} refresh";
          UMask = "0077";
          Environment = [
            "CLI_PROXY_API_KEY_FILE=/run/secrets/agent-proxy-api-key"
            "CLI_PROXY_BASE_URL_FILE=/run/secrets/agent-proxy-base-url"
          ];
        };
      };
      systemd.user.timers.agent-models-refresh = {
        Unit.Description = "Refresh the CLI proxy model catalog";
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "15min";
          RandomizedDelaySec = "30s";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
