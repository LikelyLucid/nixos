{ ... }:
{
  homeManager.modules.agent-server =
    { lib, pkgs, ... }:
    {
      home.packages = with pkgs; [
        gh
        lazygit
        gcc
        gnumake
        pkg-config
      ];
      # Do not create desktop dotfile links on the headless host.
      xdg.configFile = lib.genAttrs [ "rofi" "waybar" "eww" "wallust" ] (_: {
        enable = false;
      });
      programs.yazi.extraPackages = lib.mkForce (
        with pkgs;
        [
          bat
          eza
          glow
          ouch
          util-linux
        ]
      );
    };
}
