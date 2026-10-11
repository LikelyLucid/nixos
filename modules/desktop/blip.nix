{ inputs, ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      blip_package = inputs.blip.packages.${pkgs.stdenv.hostPlatform.system}.default;
      blip_launcher = pkgs.writeShellScript "blip" ''
        # Blip's Skiko renderer crashes with WLToolkit. Keep XWayland and
        # render at the focused output's scale instead of assuming 1x.
        if [[ -z ''${BLIP_UI_SCALE+x} && -n ''${WAYLAND_DISPLAY:-} && -n ''${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
          monitor_scale=$(${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null |
            ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .scale' 2>/dev/null) || monitor_scale=
          if [[ $monitor_scale =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            export BLIP_UI_SCALE="$monitor_scale"
          fi
        fi
        exec ${blip_package}/bin/blip "$@"
      '';
      blip_scaled = pkgs.symlinkJoin {
        name = "blip-scaled-${blip_package.version}";
        paths = [ blip_package ];
        postBuild = ''
          rm "$out/bin/blip"
          ln -s ${blip_launcher} "$out/bin/blip"
        '';
      };
    in
    {
      home.packages = [ blip_scaled ];
    };
}
