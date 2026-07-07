{
  config,
  lib,
  pkgs,
  ...
}:
{
  ############################################
  # YDOTOOLD — Wayland input injection support
  # NixOS-level: udev rules, user groups, env
  # The ydotoold daemon runs as a user service
  # managed by home-manager (agent.nix)
  ############################################

  # Load the uinput kernel module at boot (required for /dev/uinput)
  hardware.uinput.enable = true;

  # User needs access to /dev/uinput for input injection
  users.users.lucid.extraGroups = [
    "input"
    "uinput"
  ];
}
