{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # patchelf 0.19 corrupts this release's Node SEA notes. Keep the proven
      # patcher local to this package; native dependencies use the normal hook.
      sea_patchelf = pkgs.patchelf.overrideAttrs {
        version = "0.15.2";
        src = pkgs.fetchurl {
          url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
          hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
        };
        doCheck = false;
      };
    in
    {
      packages.t3-server = pkgs.stdenv.mkDerivation {
        pname = "t3-server";
        version = "0.1.3";
        src = pkgs.fetchurl {
          url = "https://github.com/pingdotgg/t3code/releases/download/v0.1.3/t3-0.1.3-linux-x64.tar.gz";
          sha256 = "63cd0f0547eef62bb4ece27fa779bbf9e2ba8531cc68542568ba9e78838dc684";
        };
        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];
        buildInputs = [
          pkgs.stdenv.cc.cc.lib
          pkgs.openssl
          pkgs.libsecret
        ];
        dontBuild = true;
        dontStrip = true;
        dontPatchELF = true;
        dontAutoPatchelf = true;
        preFixup = ''
          autoPatchelf "$out/lib/t3/node_modules" "$out/lib/t3/resource-monitor"
          ${sea_patchelf}/bin/patchelf \
            --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} \
            --set-rpath ${
              pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.openssl
              ]
            } \
            "$out/lib/t3/t3"
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib/t3 $out/bin
          cp -r . $out/lib/t3/
          makeWrapper $out/lib/t3/t3 $out/bin/t3
          runHook postInstall
        '';
        meta = {
          description = "Standalone T3 Code server without Electron";
          homepage = "https://github.com/pingdotgg/t3code";
          license = pkgs.lib.licenses.mit;
          platforms = [ "x86_64-linux" ];
          mainProgram = "t3";
        };
      };
    };
}
