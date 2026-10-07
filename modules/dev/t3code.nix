{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      pname = "t3code";
      # Run scripts/update-t3code.sh to refresh the pinned nightly release.
      version = "0.0.46-nightly.20261007.2787";
      src = pkgs.fetchurl {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
        hash = "sha256-g4NPvH725US5SFM5ManAp47vsGo0+nqvIbCw4xrM4s8=";
      };
      appimage_contents = pkgs.appimageTools.extract { inherit pname version src; };
      t3code = pkgs.appimageTools.wrapType2 {
        inherit pname version src;
        extraInstallCommands = ''
          install -Dm644 ${appimage_contents}/t3code.desktop $out/share/applications/t3code.desktop
          substituteInPlace $out/share/applications/t3code.desktop \
            --replace-fail "Exec=AppRun" "Exec=t3code"
          cp -r ${appimage_contents}/usr/share/icons $out/share
        '';
      };
    in
    {
      home.packages = [ t3code ];
    };
}
