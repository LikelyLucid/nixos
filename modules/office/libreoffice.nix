{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      onlyoffice_accelerated = pkgs.onlyoffice-desktopeditors.override {
        buildFHSEnv =
          args:
          pkgs.buildFHSEnv (
            args
            // {
              targetPkgs = pkgs': (args.targetPkgs pkgs') ++ [ pkgs.libglvnd ];
            }
          );
      };
      onlyoffice_scaled = pkgs.symlinkJoin {
        name = "onlyoffice-desktopeditors-scaled";
        paths = [ onlyoffice_accelerated ];
        postBuild = ''
          rm $out/bin/onlyoffice-desktopeditors
          cat > $out/bin/onlyoffice-desktopeditors <<EOF
          #!${pkgs.runtimeShell}
          monitor=\$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r .monitor)
          scale=\$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r --arg monitor "\$monitor" '.[] | select(.name == \$monitor) | .scale')
          exec ${onlyoffice_accelerated}/bin/onlyoffice-desktopeditors \
            --force-scale="\''${scale:-1}" "\$@"
          EOF
          chmod +x $out/bin/onlyoffice-desktopeditors

          rm -rf $out/share/applications
          cp -r ${onlyoffice_accelerated}/share/applications $out/share/applications
          substituteInPlace $out/share/applications/onlyoffice-desktopeditors.desktop \
            --replace-fail ${onlyoffice_accelerated}/bin/onlyoffice-desktopeditors \
            $out/bin/onlyoffice-desktopeditors
        '';
      };
    in
    {
      home.packages = [ onlyoffice_scaled ];
    };
}
