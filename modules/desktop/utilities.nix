{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        baobab
        curtail
        gnome-calculator
        gnome-calendar
        gnome-clocks
        gnome-connections
        gnome-disk-utility
        gnome-font-viewer
        gnome-weather
        impression
        resources
        simple-scan
        snapshot
        switcheroo
      ];
    };
}
