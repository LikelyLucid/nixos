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

          # Beeper's current AppImage stores its AI2 marker at offset 1024,
          # while nixpkgs' appimage-exec reads it from the ELF header.
          beeper =
            let
              upstream = inputs.beeper.packages.${prev.stdenv.hostPlatform.system}.default;
              pname = upstream.pname;
              version = upstream.version;
              src = prev.runCommand "${pname}-${version}-appimage-patched" { } ''
                cp ${upstream.src} $out
                chmod u+w $out
                printf '\x41\x49\x02' | dd of=$out bs=1 seek=8 conv=notrunc
              '';
              appimageContents = prev.appimageTools.extract {
                inherit pname version src;
              };
            in
            prev.appimageTools.wrapAppImage rec {
              inherit pname version;
              src = appimageContents;
              pkgs = prev;
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
