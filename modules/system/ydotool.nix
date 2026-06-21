{ config, lib, pkgs, ... }:
{
  ############################################
  # YDOTOOLD — Wayland input injection support
  # NixOS-level: udev rules, user groups, env
  # The ydotoold daemon runs as a user service
  # managed by home-manager (agent.nix)
  ############################################

  # User needs access to /dev/uinput for input injection
  users.users.lucid.extraGroups = [ "input" ];

  # udev rule: grant group 'input' access to /dev/uinput
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';
}
