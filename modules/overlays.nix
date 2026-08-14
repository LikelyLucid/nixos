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

          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (_python_final: python_prev: {
              nanoemoji = python_prev.nanoemoji.overrideAttrs {
                src = prev.fetchFromGitHub {
                  owner = "googlefonts";
                  repo = "nanoemoji";
                  rev = "refs/tags/v0.16.0";
                  hash = "sha256-FysyKC01XBnRiur5RR9fcsTxQqE8x0JJHSoe3q6JtKc=";
                };
              };
            })
          ];

          beeper =
            let
              pname = "beeper";
              version = "4.2.1004";
              src = prev.fetchurl {
                url = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-x86_64.AppImage";
                hash = "sha256-JmeD/gVBdj6Tb7Y9L43V2WoFgw3y9q1xiIjF723JmuQ=";
              };
              patchedSrc = prev.runCommand "${pname}-${version}-appimage-patched" { } ''
                cp ${src} $out
                chmod u+w $out
                printf '\x41\x49\x02' | dd of=$out bs=1 seek=8 conv=notrunc
              '';
              appimageContents = prev.appimageTools.extract {
                inherit pname version;
                src = patchedSrc;
              };
            in
            prev.appimageTools.wrapAppImage rec {
              inherit pname version;
              src = appimageContents;
              nativeBuildInputs = [ prev.copyDesktopItems ];
              desktopItem = prev.makeDesktopItem {
                name = "beeper";
                desktopName = "Beeper";
                exec = "${pname} %u";
                icon = "beepertexts.png";
                type = "Application";
                terminal = false;
                comment = "The ultimate messaging app";
                categories = [
                  "Network"
                  "Chat"
                ];
                mimeTypes = [ "x-scheme-handler/beeper" ];
              };
              extraInstallCommands = ''
                mkdir -p $out/share/applications
                cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
                cp -r ${appimageContents}/usr/share/icons $out/share
              '';
            };

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
            version = "0.4.0";

            src = prev.fetchFromGitHub {
              owner = "agent-sh";
              repo = "computer-use-linux";
              rev = "510a49a458dca550318bb7f6220163e0bd66c29b";
              hash = "sha256-yYCLmmyIIrIHUzBHOjul00BI3VwLRuDq8vRyzSBa0kM=";
            };

            cargoHash = "sha256-WEdEbXjbFcVHBhTM0SmiGX8x1k6y6uS+ly5RKMtOwMA=";
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
