{ config, lib, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
  stateDir = "${homeDir}/.openclaw";
  workspaceDir = "${stateDir}/workspace";
  openclawVersion = "2026.6.9";

  chromiumPath = "${pkgs.chromium}/bin/chromium";

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
      headless = true;
      noSandbox = true;
      executablePath = chromiumPath;
      defaultProfile = "openclaw";
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

  openclawWrapper = pkgs.writeShellScriptBin "openclaw-gateway-launch" ''
    set -euo pipefail
    export HOME="${homeDir}"
    export OPENCLAW_CONFIG_PATH="${stateDir}/openclaw.json"
    export OPENCLAW_STATE_DIR="${stateDir}"
    if [ -f "${config.sops.secrets.opencode-api-key.path}" ]; then
      export OPENCODE_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.opencode-api-key.path})"
    fi
    exec ${pkgs.nodejs}/bin/node ${stateDir}/node_modules/openclaw/openclaw.mjs "$@"
  '';
in
{
  ############################################
  # SOPS SECRET: OpenCode API key
  ############################################
  sops.secrets.opencode-api-key = { };

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
    ".openclaw/workspace/HEARTBEAT.md".source = ./workspace/HEARTBEAT.md;
    ".openclaw/workspace/goals.md".source = ./workspace/goals.md;
  };

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
      export OPENCLAW_CONFIG_PATH="${stateDir}/openclaw.json"
      export OPENCLAW_STATE_DIR="${stateDir}"
      if [ -f "${config.sops.secrets.opencode-api-key.path}" ]; then
        export OPENCODE_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.opencode-api-key.path})"
      fi
      exec ${pkgs.nodejs}/bin/node ${stateDir}/node_modules/openclaw/openclaw.mjs "$@"
    '';
  };

  ############################################
  # SYSTEMD USER SERVICE
  ############################################
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "OpenClaw gateway";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${openclawWrapper}/bin/openclaw-gateway-launch gateway --port 18789";
      WorkingDirectory = stateDir;
      Restart = "always";
      RestartSec = "5s";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  ############################################
  # YDOTOOLD — Wayland input injection daemon
  # Enables mouse clicks, keyboard input, scrolling
  ############################################
  systemd.user.services.ydotoold = {
    Unit = {
      Description = "ydotool daemon — Wayland input injection";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
      RestartSec = "3";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
