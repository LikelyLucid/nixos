{ pkgs, ... }:
let
  obsidian-wayland = pkgs.writeShellScriptBin "obsidian" ''
    #!/bin/sh
    export OBSIDIAN_USE_WAYLAND=1
    exec ${pkgs.obsidian}/bin/obsidian -enable-features=UseOzonePlatform -ozone-platform=wayland "$@"
  '';
in
{
  home.packages = with pkgs; [ obsidian-wayland ];
}