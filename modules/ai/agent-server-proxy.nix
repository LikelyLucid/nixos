{
  inputs,
  getSystem,
  config,
  ...
}:
{
  nixos.modules.agent-proxy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      codex = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      opencode = (getSystem pkgs.stdenv.hostPlatform.system).packages.opencode-v2;
      python = pkgs.python3.withPackages (p: [
        p.json5
        p.tomlkit
      ]);
      is_server = config.networking.hostName != "artsxps";
      spec = pkgs.writeText "agent-proxy-config.json" (
        builtins.toJSON {
          home = config.users.users.lucid.home;
          key_file = config.sops.secrets.agent-proxy-api-key.path;
          url_file = config.sops.secrets.agent-proxy-base-url.path;
          cat_executable = "${pkgs.coreutils}/bin/cat";
          codex_version = lib.getVersion codex;
          opencode_executable = lib.getExe opencode;
          pi_models_seed = "/home/lucid/pi-config/models.json";
          pi_settings_seed = "/home/lucid/pi-config/settings.json";
          mcp_servers = lib.optionalAttrs is_server {
            cua = {
              command = "${(getSystem pkgs.stdenv.hostPlatform.system).packages.cua}/bin/cua";
              args = [ "mcp" ];
            };
            agent-browser = {
              command = "${(getSystem pkgs.stdenv.hostPlatform.system).packages.agent-browser-headless}/bin/agent-browser";
              args = [
                "mcp"
                "--tools"
                "all"
              ];
            };
          };
        }
      );
    in
    {
      # Native executables only. Credentials are read by each client's native auth
      # mechanism, not inherited from a shell, T3 service, or launch wrapper.
      home-manager.users.lucid = { lib, ... }: {
        home.activation.removeLegacyProxyProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          profile="${config.users.users.lucid.home}/.local/state/nix/profiles/profile"
          if [ -e "$profile" ] && ${pkgs.nix}/bin/nix profile list --profile "$profile" --json | \
            ${pkgs.jq}/bin/jq -e '.elements["opencode-cliproxy-chat"] != null' >/dev/null; then
            run ${pkgs.nix}/bin/nix profile remove --profile "$profile" opencode-cliproxy-chat
          fi
        '';
        home.packages = [
          codex
          opencode
          pkgs.pi-coding-agent
          pkgs.claude-code
        ];
        # Runtime reconciliation owns this writable file. Other Pi files remain
        # linked to pi-config; a first migration seeds models from that checkout.
        home.file.".pi/agent/models.json".enable = lib.mkForce false;
      };

      systemd.services.agent-proxy-config = {
        description = "Reconcile native AI agent config from SOPS proxy settings";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        requires = [ "home-manager-lucid.service" ];
        after = [
          "network-online.target"
          "sops-nix.service"
          "home-manager-lucid.service"
        ];
        startLimitIntervalSec = 300;
        startLimitBurst = 3;
        serviceConfig = {
          Type = "oneshot";
          User = "lucid";
          WorkingDirectory = config.users.users.lucid.home;
          ExecStart = "${python}/bin/python3 ${../../scripts/agent_proxy_config.py} --spec ${spec}";
          UMask = "0077";
          Restart = "on-failure";
          RestartSec = "30s";
          TimeoutStartSec = "5min";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ config.users.users.lucid.home ];
        };
        environment.HOME = config.users.users.lucid.home;
      };
      systemd.timers.agent-proxy-config = {
        description = "Refresh Pi/OpenCode proxy model metadata independently of app startup";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitInactiveSec = "15min";
          RandomizedDelaySec = "30s";
        };
      };
    };

  nixos.modules.artsxps.imports = [ config.nixos.modules.agent-proxy ];
  nixos.modules.agent-server.imports = [ config.nixos.modules.agent-proxy ];

  perSystem =
    { pkgs, ... }:
    let
      python = pkgs.python3.withPackages (p: [
        p.json5
        p.tomlkit
      ]);
    in
    {
      checks.agent-proxy-config = pkgs.runCommand "agent-proxy-config-tests" { } ''
        export PYTHONDONTWRITEBYTECODE=1
        export AGENT_PROXY_CONFIG_SCRIPT=${../../scripts/agent_proxy_config.py}
        ${python}/bin/python3 ${../../tests/test_agent_proxy_config.py}
        touch "$out"
      '';
    };
}
