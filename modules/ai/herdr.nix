{ config, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

  nixos.modules.common.nixpkgs.overlays = [
    (final: _prev: {
      herdr = config.flake.packages.${final.stdenv.hostPlatform.system}.herdr;
    })
  ];

  homeManager.modules.common =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.herdr ];

      xdg.configFile."herdr/config.toml" = {
        force = true;
        text = ''
          onboarding = false

          [ui]
          show_agent_labels_on_pane_borders = true
          agent_panel_sort = "spaces"

          [ui.toast]
          delivery = "system"

          [experimental]
          kitty_graphics = true
          pane_history = true
        '';
      };

    };
}
