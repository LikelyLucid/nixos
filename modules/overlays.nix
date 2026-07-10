{ inputs, ... }:
{
  nixos.modules.common = {
    nixpkgs.overlays = [
      inputs.pi.overlays.default
      (
        _final: prev:
        let
          py_pkgs = prev.python3Packages;
        in
        {
          helium = inputs.helium-browser.packages.${prev.stdenv.hostPlatform.system}.helium;
          beeper = inputs.beeper.packages.${prev.stdenv.hostPlatform.system}.default;

          hyprland-canvas = py_pkgs.buildPythonPackage {
            pname = "hyprland-canvas";
            version = "1.0.1";
            src = inputs.hyprland-canvas;
            format = "pyproject";
            nativeBuildInputs = [ py_pkgs.hatchling ];
            propagatedBuildInputs = [ py_pkgs.pyyaml ];
            doCheck = false;
          };

          cua-driver = prev.stdenv.mkDerivation {
            pname = "cua-driver";
            version = "0.6.8";
            src = prev.fetchurl {
              url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v0.6.8/cua-driver-rs-0.6.8-linux-x86_64-binary.tar.gz";
              hash = "sha256-3ohcatgrXhDtAhO+RkLdp0tZIpkK1gAutbxIHV2JwFs=";
            };
            nativeBuildInputs = [ prev.autoPatchelfHook ];
            buildInputs = [
              prev.stdenv.cc.cc.lib
              prev.libx11
              prev.libxi
            ];
            dontUnpack = true;
            installPhase = ''
              tar -xzf $src
              install -m755 -D cua-driver $out/bin/cua-driver
            '';
          };
        }
      )
    ];
  };
}
