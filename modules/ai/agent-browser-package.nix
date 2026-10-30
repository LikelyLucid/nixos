{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      version = "0.39.1";
      agent_browser_unwrapped = pkgs.stdenvNoCC.mkDerivation {
        pname = "agent-browser-unwrapped";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/vercel-labs/agent-browser/archive/refs/tags/v${version}.tar.gz";
          hash = "sha256-G4rg/UaQgQEsLq1KpuWHAzvrQPsNbQBefOwczZR09Wc=";
        };
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/bin"
          install -m755 ${
            pkgs.fetchurl {
              url = "https://github.com/vercel-labs/agent-browser/releases/download/v${version}/agent-browser-linux-x64";
              hash = "sha256-aQbToqZ7BYCZMqk9meU9ETI3PwpSphey1gMtu5VN9vw=";
            }
          } "$out/bin/agent-browser"
          cp -r skills skill-data "$out/"
          runHook postInstall
        '';
        meta = {
          description = "Browser automation CLI with its bundled dashboard and skills";
          homepage = "https://github.com/vercel-labs/agent-browser";
          license = lib.licenses.asl20;
          platforms = [ "x86_64-linux" ];
          mainProgram = "agent-browser";
        };
      };
      headless_browser = pkgs.writeShellScriptBin "agent-browser" ''
        export AGENT_BROWSER_EXECUTABLE_PATH="''${AGENT_BROWSER_EXECUTABLE_PATH:-${pkgs.chromium}/bin/chromium}"
        exec ${pkgs.python3}/bin/python3 ${./agent-browser/session.py} \
          ${agent_browser_unwrapped}/bin/agent-browser "$@"
      '';
    in
    {
      packages = {
        agent-browser-unwrapped = agent_browser_unwrapped;
        agent-browser-headless = headless_browser;
      };
    };
}
