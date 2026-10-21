{ config, inputs, ... }:
{
  perSystem =
    { system, lib, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = package: lib.getName package == "cua-spaces";
      };
      cua_source = pkgs.fetchFromGitHub {
        owner = "trycua";
        repo = "cua";
        rev = "db87d6676d820da152291072df3715c05a0d7e62";
        hash = "sha256-Hvtr65Flu31W7bJY2u9tkKNViFZsAWrMk7SZNMMBdnY=";
      };
    in
    {
      packages = {
        cua = pkgs.stdenvNoCC.mkDerivation {
          pname = "cua";
          version = "0.4.3";
          src = pkgs.fetchurl {
            url = "https://github.com/trycua/cua/releases/download/cua-sdk-v0.4.3/cua-cli-0.4.3-linux-x64.tar.gz";
            hash = "sha256-3BFaRfBCGuOMS/iekGaMb14h+MdbPvbffshbrXq+YCk=";
          };
          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib ];
          sourceRoot = ".";
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 cua "$out/bin/cua"
            runHook postInstall
          '';
          postFixup = ''
            wrapProgram "$out/bin/cua" \
              --set-default CUA_SPACES_CLI \
                ${config.flake.packages.${system}.cua-spaces}/lib/cua-spaces/resources/native/cua
          '';
          meta = {
            description = "Cua CLI for local desktop Spaces and computer-use agents";
            homepage = "https://cua.ai/docs/cua-cli";
            license = lib.licenses.mit;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            platforms = [ "x86_64-linux" ];
            mainProgram = "cua";
          };
        };

        cua-spaces = pkgs.stdenvNoCC.mkDerivation {
          pname = "cua-spaces";
          version = "0.12.0";
          src = pkgs.fetchurl {
            url = "https://github.com/trycua/cua/releases/download/cua-spaces-v0.12.0/cua-spaces_0.12.0_amd64.deb";
            hash = "sha256-ujQff57hKIA/fTZGk/E3uHusJcm0OTE6A2G73PY4MEA=";
          };
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            dpkg
            wrapGAppsHook3
          ];
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            alsa-lib
            at-spi2-atk
            cairo
            cups
            dbus
            expat
            glib
            gtk3
            gtk4
            libdrm
            libgbm
            libGL
            libsecret
            libx11
            libxcb
            libxcomposite
            libxdamage
            libxext
            libxfixes
            libxkbcommon
            libxrandr
            libxshmfence
            nspr
            nss
            pango
            systemd
          ];
          runtimeDependencies = with pkgs; [
            libGL
            vulkan-loader
            libsecret
            libnotify
            libpulseaudio
            pipewire
          ];
          unpackPhase = "dpkg-deb --fsys-tarfile $src | tar --no-same-permissions -x";
          dontBuild = true;
          dontWrapGApps = true;
          installPhase = ''
            runHook preInstall
            mkdir -p "$out/lib" "$out/bin"
            cp -r "opt/Cua Spaces" "$out/lib/cua-spaces"
            cp -r usr/share "$out/share"
            # Upstream's .deb contains icon links without their target directory.
            for icon in 32x32.png 64x64.png 128x128.png 128x128@2x.png icon.png; do
              install -Dm644 "${cua_source}/apps/cua-spaces/src-tauri/icons/$icon" \
                "$out/share/icons/cua-spaces/src-tauri/icons/$icon"
            done
            # Nix owns updates; don't offer an updater that writes into the store.
            rm "$out/lib/cua-spaces/resources/app-update.yml"
            substituteInPlace "$out/share/applications/cua-spaces.desktop" \
              --replace-fail '"/opt/Cua Spaces/cua-spaces"' "$out/bin/cua-spaces"
            runHook postInstall
          '';
          preFixup = ''
            makeWrapper "$out/lib/cua-spaces/cua-spaces" "$out/bin/cua-spaces" \
              "''${gappsWrapperArgs[@]}" \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.polkit
                  pkgs.xdg-utils
                ]
              } \
              --add-flags --ozone-platform-hint=auto
          '';
          passthru.skills = "${cua_source}/libs/cua/skills";
          meta = {
            description = "Cua Spaces desktop app";
            homepage = "https://cua.ai/docs/spaces";
            license = lib.licenses.unfree;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            platforms = [ "x86_64-linux" ];
            mainProgram = "cua-spaces";
          };
        };
      };
    };

  nixos.modules.desktop =
    { pkgs, ... }:
    {
      # Rootless Podman's API socket is discovered by Cua automatically.
      virtualisation.podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      # Also exposes the upstream polkit confirmation actions to NixOS.
      environment.systemPackages = with config.flake.packages.${pkgs.stdenv.hostPlatform.system}; [
        cua
        cua-spaces
      ];
    };

  homeManager.modules.desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      cua_packages = config.flake.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.activation.codexCuaSpacesMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${osConfig.programs.codexDesktopLinux.cliPackage}/bin/codex mcp add cua -- \
          ${cua_packages.cua}/bin/cua mcp
      '';
      home.file = {
        ".agents/skills/cua-spaces".source = "${cua_packages.cua-spaces.skills}/cua-spaces";
        ".agents/skills/cua-sandboxes".source = "${cua_packages.cua-spaces.skills}/cua-sandboxes";
      };
      xdg.mimeApps.defaultApplications."x-scheme-handler/cua" = [ "cua-spaces.desktop" ];
    };
}
