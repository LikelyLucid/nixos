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

          computer-use-linux = prev.rustPlatform.buildRustPackage {
            pname = "computer-use-linux";
            version = "0.3.1-unstable-2026-07-13";

            src = prev.fetchFromGitHub {
              owner = "agent-sh";
              repo = "computer-use-linux";
              rev = "e338582b1f96024b24a8c188a2a2092239af95d5";
              hash = "sha256-q5YrSOTRa6zcmZpNxr8ZSbwMHrF0TlIxlUGS25Pm1ls=";
            };

            patches = [
              ./ai/computer-use-linux-hyprland-0.55.patch
              ./ai/computer-use-linux-schema.patch
            ];
            cargoHash = "sha256-BQqTTLdwdQLg+d1ColcR+JrtZmWBtL4Wq3eXWnipkno=";
            nativeBuildInputs = [ prev.pkg-config ];
            buildInputs = [
              prev.dbus
              prev.systemd
            ];
          };
        }
      )
    ];
  };
}
