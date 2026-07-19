{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        baobab
        gnome-calculator
        gnome-clocks
        gnome-disk-utility
        gnome-font-viewer
        resources
        simple-scan
        snapshot
      ];
    };
}
