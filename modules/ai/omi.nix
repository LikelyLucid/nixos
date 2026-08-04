{
  config,
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      electron = pkgs.electron_39.overrideAttrs (_old: {
        meta.knownVulnerabilities = [ ];
      });
      omi = pkgs.stdenv.mkDerivation (final_attrs: {
        pname = "omi";
        version = "1.0.16-unstable-2026-07-26";
        src = inputs.omi + "/desktop/windows";

        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (final_attrs) pname version src;
          pnpm = pkgs.pnpm_10;
          fetcherVersion = 3;
          hash = "sha256-f5rLVRDoX1UHUymrJTAID6HkpRKBUT6+ee1IJd4vdWE=";
        };

        nativeBuildInputs = with pkgs; [
          copyDesktopItems
          makeWrapper
          nodejs_22
          pkg-config
          pnpmConfigHook
          pnpm_10
          python3
        ];

        buildPhase = ''
          runHook preBuild

          cp .env.example .env
          python3 - <<'PY'
          from pathlib import Path

          path = Path("src/main/index.ts")
          source = path.read_text()
          old = "minHeight: 600,\n    show: false,"
          new = "minHeight: 600,\n    show: true,"
          if source.count(old) != 1:
              raise SystemExit("could not identify Omi's main BrowserWindow")
          path.write_text(source.replace(old, new))
          PY
          export npm_config_nodedir=${electron.headers}
          pnpm rebuild better-sqlite3

          rm -rf node_modules/electron/dist
          ln -s ${electron}/libexec/electron node_modules/electron/dist
          printf electron > node_modules/electron/path.txt
          pnpm exec electron-vite build
          node scripts/bundle-pimono-extension.mjs

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/share/omi $out/share/icons/hicolor/256x256/apps
          cp -r out resources node_modules package.json $out/share/omi/
          install -Dm644 resources/icon.png $out/share/icons/hicolor/256x256/apps/omi.png

          makeWrapper ${pkgs.lib.getExe' electron "electron"} $out/bin/omi \
            --add-flags $out/share/omi \
            --add-flags --disable-gpu \
            --run 'if [[ -z ''${OMI_OZONE+x} ]]; then if [[ ''${XDG_SESSION_TYPE-} == wayland && -n ''${WAYLAND_DISPLAY-} ]]; then export OMI_OZONE=wayland; else export OMI_OZONE=x11; fi; fi' \
            --prefix PATH : ${
              pkgs.lib.makeBinPath [
                pkgs.tesseract
                pkgs.xprop
              ]
            }

          runHook postInstall
        '';

        desktopItems = [
          (pkgs.makeDesktopItem {
            name = "omi";
            desktopName = "Omi";
            comment = "AI that sees your screen, listens, and remembers";
            exec = "omi";
            icon = "omi";
            categories = [ "Utility" ];
          })
        ];

        meta = {
          description = "AI assistant that listens, remembers, and understands your screen";
          homepage = "https://github.com/BasedHardware/Omi";
          license = pkgs.lib.licenses.mit;
          mainProgram = "omi";
          platforms = [ "x86_64-linux" ];
        };
      });
    in
    {
      packages.omi = omi;
      apps.omi = {
        type = "app";
        program = "${omi}/bin/omi";
        meta.description = "Run the Omi desktop application";
      };
    };

  nixos.modules.common.nixpkgs.overlays = [
    (final: _prev: {
      omi = config.flake.packages.${final.stdenv.hostPlatform.system}.omi;
    })
  ];
}
