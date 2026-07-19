{ ... }:
{
  nixos.modules.artsxps =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.tlp-pd ];
      services.dbus.packages = [ pkgs.tlp-pd ];

      systemd.services.tlp-pd = {
        description = "TLP power profiles daemon";
        documentation = [ "man:tlp-pd(8)" ];
        wantedBy = [ "graphical.target" ];
        after = [
          "multi-user.target"
          "tlp.service"
        ];
        serviceConfig = {
          Type = "dbus";
          BusName = "org.freedesktop.UPower.PowerProfiles";
          ExecStart = "${pkgs.tlp-pd}/bin/tlp-pd";
          Restart = "on-failure";
        };
      };
    };

  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      power_profile_menu = pkgs.writeShellApplication {
        name = "power-profile-menu";
        runtimeInputs = with pkgs; [
          libnotify
          rofi
          tlp-pd
        ];
        text = ''
          current=$(tlpctl get 2>/dev/null || true)
          case "$current" in
            performance) selected=0 ;;
            balanced) selected=1 ;;
            power-saver) selected=2 ;;
            *) selected=1 ;;
          esac

          choice=$(
            printf '%s\n' \
              '󰓅  Performance' \
              '󰾅  Balanced' \
              '󰌪  Low Power' |
              rofi -dmenu \
                -p 'Power mode' \
                -selected-row "$selected" \
                -theme-str 'window { location: northeast; anchor: northeast; x-offset: -16px; y-offset: 46px; width: 360px; } listview { lines: 3; }'
          ) || exit 0

          case "$choice" in
            *Performance) profile=performance; label='Performance' ;;
            *Balanced) profile=balanced; label='Balanced' ;;
            *'Low Power') profile=power-saver; label='Low Power' ;;
            *) exit 0 ;;
          esac

          tlpctl set "$profile"
          notify-send -a 'Power' -i battery "Power mode" "$label"
        '';
      };

      power_profile_details = pkgs.writeShellApplication {
        name = "power-profile-details";
        runtimeInputs = with pkgs; [
          coreutils
          tlp
          zenity
        ];
        text = ''
          report=$(mktemp)
          trap 'rm -f "$report"' EXIT
          {
            tlp-stat -s
            printf '\n'
            tlp-stat -b
          } > "$report"
          zenity --text-info \
            --title='Power & Battery' \
            --width=720 \
            --height=560 \
            --font='JetBrains Mono 10' \
            --filename="$report"
        '';
      };
    in
    {
      home.packages = [
        power_profile_menu
        power_profile_details
      ];
    };
}
