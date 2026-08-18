{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      pname = "t3code";
      version = "0.0.33";
      src = pkgs.fetchurl {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
        hash = "sha256-QVyGSPQ8PSLVcvJ/LFD9yMMQ6n/N6VN7kD4eLxyHdaE=";
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
