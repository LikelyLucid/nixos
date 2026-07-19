{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      services.network-manager-applet.enable = true;
      services.blueman-applet.enable = true;
      services.hyprpolkitagent.enable = true;
      services.cliphist.enable = true;

      systemd.user.services.hyprland-canvas = {
        Unit = {
          Description = "Hyprland infinite canvas daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.hyprland-canvas}/bin/canvasd";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
