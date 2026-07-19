{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      night_light_toggle = pkgs.writeShellApplication {
        name = "night-light-toggle";
        runtimeInputs = with pkgs; [
          libnotify
          systemd
        ];
        text = ''
          if systemctl --user is-active --quiet hyprsunset.service; then
            systemctl --user stop hyprsunset.service
            notify-send -a "Night Light" -i weather-clear-symbolic "Night Light" "Off"
          else
            systemctl --user start hyprsunset.service
            notify-send -a "Night Light" -i weather-clear-night-symbolic "Night Light" "On"
          fi
        '';
      };
    in
    {
      services.hyprsunset = {
        enable = true;
        settings.profile = [
          {
            time = "07:00";
            identity = true;
          }
          {
            time = "20:00";
            temperature = 4000;
          }
        ];
      };

      home.packages = [ night_light_toggle ];
    };
}
