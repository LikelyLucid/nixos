{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      prime_agent = pkgs.buildNpmPackage {
        pname = "prime-agent";
        version = "0.7.0";
        src = ./prime-agent;

        npmDepsHash = "sha256-JjC9XNkKfGZm6sGwSvSrYi8aUgYkbEjtgBKgVjtGAsE=";
        npmDepsFetcherVersion = 2;
        npmInstallFlags = [ "--ignore-scripts" ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        dontNpmBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin $out/lib/prime-agent
          cp -r node_modules $out/lib/prime-agent/

          makeWrapper ${pkgs.lib.getExe pkgs.nodejs_22} $out/bin/prime-agent \
            --add-flags $out/lib/prime-agent/node_modules/prime-agent/dist/bundle/cli.js \
            --set PI_PACKAGE_DIR $out/lib/prime-agent/node_modules/prime-agent \
            --prefix PATH : ${
              pkgs.lib.makeBinPath [
                pkgs.fd
                pkgs.ripgrep
                pkgs.uv
              ]
            }

          runHook postInstall
        '';

        meta = {
          description = "Self-improving coding and research agent with a persistent Python environment";
          homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
          license = pkgs.lib.licenses.mit;
          mainProgram = "prime-agent";
          platforms = pkgs.lib.platforms.linux;
        };
      };
    in
    {
      packages.prime-agent = prime_agent;
      apps.prime-agent = {
        type = "app";
        program = "${prime_agent}/bin/prime-agent";
        meta.description = "Run Prime Agent";
      };
    };
}
