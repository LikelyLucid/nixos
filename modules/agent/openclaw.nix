{ config, lib, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
  stateDir = "${homeDir}/.openclaw";
  workspaceDir = "${stateDir}/workspace";
  openclawVersion = "2026.6.9";

  # Base config (Nix-managed, token injected at runtime)
  openclawConfig = builtins.toJSON {
    gateway = {
      mode = "local";
    };
    models = {
      providers = {
        opencode-go = {
          api = "openai-completions";
          baseUrl = "https://opencode.ai/zen/go/v1";
          apiKey = {
            source = "env";
            provider = "default";
            id = "OPENCODE_API_KEY";
          };
          models = [
            { id = "mimo-v2.5"; name = "MiMo V2.5"; }
            { id = "glm-5.2"; name = "GLM 5.2"; }
            { id = "kimi-k2.7"; name = "Kimi K2.7"; }
            { id = "deepseek-v4-pro"; name = "DeepSeek V4 Pro"; }
          ];
        };
      };
    };
    agents = {
      defaults = {
        model = "opencode-go/mimo-v2.5";
        workspace = workspaceDir;
      };
    };
    browser = {
      enabled = true;
      defaultProfile = "helium";
      profiles = {
        helium = {
          driver = "existing-session";
          attachOnly = true;
          userDataDir = "~/.config/net.imput.helium";
          color = "#7C3AED";
        };
        openclaw = {
          cdpPort = 18800;
          color = "#FF4500";
        };
      };
    };
    plugins = {
      enabled = true;
      load = {
        paths = [ "${workspaceDir}/plugins/computer-control" ];
      };
      entries = {
        computer-control = {
          enabled = true;
        };
      };
    };
  };

  # Build runtime config with token merged in
  mkOpenclawConfig = pkgs.writeShellScript "mk-openclaw-config" ''
    set -euo pipefail
    baseConfig="${stateDir}/openclaw.json"
    runtimeConfig="${stateDir}/openclaw.runtime.json"
    tokenFile="${config.sops.secrets.openclaw-gateway-token.path}"

    if [ -f "$tokenFile" ]; then
      token="$(${pkgs.coreutils}/bin/cat "$tokenFile" | ${pkgs.coreutils}/bin/tr -d '\n')"
      ${pkgs.jq}/bin/jq --arg token "$token" \
        '.gateway.auth = {"mode":"token","token":$token}' \
        "$baseConfig" > "$runtimeConfig.tmp"
      ${pkgs.coreutils}/bin/mv "$runtimeConfig.tmp" "$runtimeConfig"
    else
      ${pkgs.coreutils}/bin/cp "$baseConfig" "$runtimeConfig"
    fi

    echo "$runtimeConfig"
  '';

  openclawWrapper = pkgs.writeShellScriptBin "openclaw-gateway-launch" ''
    set -euo pipefail
    export HOME="${homeDir}"
    export OPENCLAW_STATE_DIR="${stateDir}"

    # Merge token into runtime config
    export OPENCLAW_CONFIG_PATH="$(${mkOpenclawConfig})"

    if [ -f "${config.sops.secrets.opencode-api-key.path}" ]; then
      export OPENCODE_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.opencode-api-key.path})"
    fi

    exec ${pkgs.nodejs}/bin/node ${stateDir}/node_modules/openclaw/openclaw.mjs "$@"
  '';
in
{
  ############################################
  # SOPS SECRETS
  ############################################
  sops.secrets.opencode-api-key = { };
  sops.secrets.openclaw-gateway-token = { };

  ############################################
  # OPENCLAW WORKSPACE FILES
  ############################################
  home.file = {
    ".openclaw/openclaw.json".text = openclawConfig;
    ".openclaw/workspace/AGENTS.md".source = ./workspace/AGENTS.md;
    ".openclaw/workspace/SOUL.md".source = ./workspace/SOUL.md;
    ".openclaw/workspace/USER.md".source = ./workspace/USER.md;
    ".openclaw/workspace/IDENTITY.md".source = ./workspace/IDENTITY.md;
    ".openclaw/workspace/TOOLS.md".source = ./workspace/TOOLS.md;
    ".openclaw/workspace/goals.md".source = ./workspace/goals.md;
  };

  ############################################
  # SEED PERSISTENT FILES (not Nix-store symlinks)
  ############################################
  home.activation.openclaw-seed-persistent-files = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run --quiet ${pkgs.coreutils}/bin/mkdir -p "${workspaceDir}/memory"

    if [ ! -f "${workspaceDir}/HEARTBEAT.md" ]; then
      run cat > "${workspaceDir}/HEARTBEAT.md" << 'EOF'
# Heartbeat Checklist

- [ ] Check `df -h /` — alert if >80%
- [ ] Check `systemctl --user --failed` — report failures
- [ ] Check `journalctl -p err --since "30 min ago"` — new errors?
- [ ] Check Tailscale status: `tailscale status`
- [ ] Update `system-state.md`
EOF
    fi

    if [ ! -f "${workspaceDir}/MEMORY.md" ]; then
      run touch "${workspaceDir}/MEMORY.md"
    fi
  '';

  ############################################
  # NPM INSTALL ACTIVATION
  ############################################
  home.activation.openclaw-install = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${stateDir}/node_modules/.bin/openclaw" ]; then
      run --quiet ${pkgs.coreutils}/bin/mkdir -p "${stateDir}"
      export PATH="${pkgs.nodejs}/bin:$PATH"
      run ${pkgs.nodejs}/bin/npm install openclaw@${openclawVersion} --prefix "${stateDir}" --no-save
    fi
  '';

  # Ensure Helium DevToolsActivePort symlink exists for Chrome MCP attach
  home.activation.openclaw-helium-symlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run --quiet ${pkgs.coreutils}/bin/mkdir -p "${homeDir}/.config/google-chrome"
    run --quiet ${pkgs.coreutils}/bin/ln -sfn "${homeDir}/.config/net.imput.helium/DevToolsActivePort" "${homeDir}/.config/google-chrome/DevToolsActivePort"
  '';

  ############################################
  # PATH: ensure ~/.local/bin is available
  ############################################
  home.sessionPath = [ "${homeDir}/.local/bin" ];

  ############################################
  # OPENCLAW CLI (on PATH)
  ############################################
  home.file.".local/bin/openclaw" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      export HOME="${homeDir}"
      export OPENCLAW_STATE_DIR="${stateDir}"

      # Merge token into runtime config
      runtimeConfig="${stateDir}/openclaw.runtime.json"
      baseConfig="${stateDir}/openclaw.json"
      tokenFile="${config.sops.secrets.openclaw-gateway-token.path}"

      if [ -f "$tokenFile" ]; then
        token="$(${pkgs.coreutils}/bin/cat "$tokenFile" | ${pkgs.coreutils}/bin/tr -d '\n')"
        ${pkgs.jq}/bin/jq --arg token "$token" \
          '.gateway.auth = {"mode":"token","token":$token}' \
          "$baseConfig" > "$runtimeConfig.tmp"
        ${pkgs.coreutils}/bin/mv "$runtimeConfig.tmp" "$runtimeConfig"
      else
        ${pkgs.coreutils}/bin/cp "$baseConfig" "$runtimeConfig"
      fi

      export OPENCLAW_CONFIG_PATH="$runtimeConfig"

      if [ -f "${config.sops.secrets.opencode-api-key.path}" ]; then
        export OPENCODE_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.opencode-api-key.path})"
      fi

      exec ${pkgs.nodejs}/bin/node ${stateDir}/node_modules/openclaw/openclaw.mjs "$@"
    '';
  };

  ############################################
  # SYSTEMD USER SERVICE
  ############################################
  home.file.".config/systemd/user/openclaw-gateway.service".text = ''
    [Unit]
    Description=OpenClaw gateway
    After=network.target sops-nix.service
    Wants=sops-nix.service

    [Service]
    Type=simple
    ExecStart=${openclawWrapper}/bin/openclaw-gateway-launch gateway --port 18789
    WorkingDirectory=${stateDir}
    Restart=always
    RestartSec=5s
    StandardOutput=journal
    StandardError=journal

    [Install]
    WantedBy=default.target
  '';

  systemd.user.startServices = true;

  ############################################
  # YDOTOOLD — Wayland input injection daemon
  ############################################
  home.file.".config/systemd/user/ydotoold.service".text = ''
    [Unit]
    Description=ydotool daemon — Wayland input injection
    After=default.target

    [Service]
    Type=simple
    ExecStart=${pkgs.ydotool}/bin/ydotoold
    Restart=on-failure
    RestartSec=3

    [Install]
    WantedBy=default.target
  '';
}
