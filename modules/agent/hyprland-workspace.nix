{ lib, pkgs, ... }:
let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  jq = "${pkgs.jq}/bin/jq";

  setupAgentWorkspace = pkgs.writeShellScript "setup-agent-workspace" ''
    set -euo pipefail

    # Wait for Hyprland socket to be available
    for i in $(seq 1 30); do
      if ${hyprctl} instances >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    # Configure workspace 10 as persistent (Hyprland 0.55+ Lua API)
    ${hyprctl} eval 'return hl.workspace_rule({ workspace = "10", persistent = true })' >/dev/null 2>&1 || true

    # Focus workspace 10 (creates it if it doesn't exist)
    ${hyprctl} dispatch 'hl.dsp.focus({ workspace = 10 })' >/dev/null 2>&1 || true

    # Rename workspace to "agent"
    ${hyprctl} dispatch 'hl.dsp.workspace.rename({ workspace = "10", name = "agent" })' >/dev/null 2>&1 || true

    # Keybind: SUPER + grave (backtick) -> workspace 10
    ${hyprctl} eval 'return hl.bind("SUPER+grave", hl.dsp.focus({ workspace = 10 }))' >/dev/null 2>&1 || true
    ${hyprctl} eval 'return hl.bind("SUPER+SHIFT+grave", hl.dsp.window.move({ workspace = 10 }))' >/dev/null 2>&1 || true

    # Launch agent terminal on workspace 10 if not already present
    if ! ${hyprctl} clients -j | ${jq} -e '.[] | select(.workspace.id == 10 and .title == "agent-shell")' >/dev/null 2>&1; then
      ${hyprctl} eval 'return hl.exec_cmd("ghostty --title=agent-shell", { workspace = "10" })' >/dev/null 2>&1 || true
    fi
  '';
in
{
  ############################################
  # HYPRLAND WORKSPACE 10 — AGENT SPACE
  # Configured at runtime via hyprctl so we don't need to edit hyprland.conf
  ############################################

  systemd.user.services.agent-workspace = {
    Unit = {
      Description = "Setup agent workspace 10";
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${setupAgentWorkspace}";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
