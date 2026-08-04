{ ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      ############################################
      # TAILSCALE
      ############################################
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
        extraSetFlags = [
          "--ssh"
          "--operator=lucid"
        ];
        useRoutingFeatures = "client";
      };
    };

  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      tailscale_route_menu = pkgs.writeShellApplication {
        name = "tailscale-route-menu";
        runtimeInputs = with pkgs; [
          jq
          libnotify
          rofi
          tailscale
        ];
        text = ''
          current_exit=$(tailscale status --json --peers=false | jq -r '.ExitNodeStatus.ID // empty')
          if [[ -n "$current_exit" ]]; then
            selected=1
          else
            selected=0
          fi

          choice=$(
            printf '%s\n' \
              '󰖂  Direct connection' \
              '󰒍  lucidsserver exit node' |
              rofi -dmenu -p 'Tailscale route' -selected-row "$selected"
          ) || exit 0

          case "$choice" in
            *'Direct connection')
              tailscale set --exit-node=
              label='Direct connection'
              ;;
            *'lucidsserver exit node')
              tailscale set --exit-node=lucidsserver
              label='lucidsserver exit node'
              ;;
            *) exit 0 ;;
          esac

          notify-send -a Tailscale -i network-vpn "Tailscale route" "$label"
        '';
      };
    in
    {
      home.packages = [ tailscale_route_menu ];
    };
}
