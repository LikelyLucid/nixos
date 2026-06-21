{ lib, pkgs, ... }:
let
  setupAgentWorkspace = pkgs.writeShellScript "setup-agent-workspace" ''
    set -euo pipefail

    # Wait for Hyprland socket to be available
    for i in $(seq 1 30); do
      if ${pkgs.hyprland}/bin/hyprctl instances >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    # Configure workspace 10 as persistent "agent"
    ${pkgs.hyprland}/bin/hyprctl keyword workspace "10, name:agent, persistent:true" >/dev/null 2>&1 || true

    # Rename workspace to "agent" if it already exists
    ${pkgs.hyprland}/bin/hyprctl dispatch renameworkspace 10 agent >/dev/null 2>&1 || true

    # Keybind: SUPER + backtick -> workspace 10
    ${pkgs.hyprland}/bin/hyprctl keyword bind "SUPER, backtick, workspace, 10" >/dev/null 2>&1 || true
    ${pkgs.hyprland}/bin/hyprctl keyword bind "SUPER SHIFT, backtick, movetoworkspace, 10" >/dev/null 2>&1 || true

    # Launch agent terminal on workspace 10 if not already present
    if ! ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.workspace.id == 10 and .title == "agent-shell")' >/dev/null 2>&1; then
      ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace 10 silent] ghostty --title=agent-shell" >/dev/null 2>&1 || true
    fi
  '';
in
{
  ############################################
  # HYPRLAND WORKSPACE 10 — AGENT SPACE
  # Configured at runtime via hyprctl so we don't need to edit hyprland.conf
  ############################################

  home.file.".config/systemd/user/agent-workspace.service".text = ''
    [Unit]
    Description=Setup agent workspace 10
    After=default.target

    [Service]
    Type=oneshot
    ExecStart=${setupAgentWorkspace}
    RemainAfterExit=true

    [Install]
    WantedBy=default.target
  '';

  systemd.user.startServices = true;
}
