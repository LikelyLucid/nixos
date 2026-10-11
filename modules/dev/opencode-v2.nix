{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    let
      version = "2.0.26";
      opencode = pkgs.stdenvNoCC.mkDerivation {
        pname = "opencode";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
          hash = "sha512-UIA2/1Ik8HaN54C4xp7H+OHgRfq995XUixrX+kLmFs8EPn1fAcmn3OoiN+3c3Vc3jEV/LHmj0Cy1SL6nW4wdGw==";
        };

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.gnutar
          pkgs.makeWrapper
        ];
        buildInputs = [ pkgs.stdenv.cc.cc.lib ];
        dontUnpack = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p "$out/bin" "$TMPDIR/opencode-package"
          tar -xzf "$src" -C "$TMPDIR/opencode-package"
          install -Dm755 "$TMPDIR/opencode-package/package/bin/opencode" "$out/bin/opencode"
          wrapProgram "$out/bin/opencode" \
            --prefix PATH : "${
              pkgs.lib.makeBinPath [
                pkgs.git
                pkgs.ripgrep
              ]
            }" \
            --set OPENCODE_DISABLE_AUTOUPDATE true

          runHook postInstall
        '';

        meta = {
          description = "OpenCode AI coding agent, version 2";
          homepage = "https://opencode.ai/v2/";
          license = pkgs.lib.licenses.mit;
          mainProgram = "opencode";
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      home.packages = [ opencode ];
    };
}
