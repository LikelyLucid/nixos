{ ... }:
{
  homeManager.modules.desktop =
    { lib, pkgs, ... }:
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
      helium_browser = pkgs.writeShellScriptBin "agent-browser-helium" ''
        exec ${pkgs.python3}/bin/python3 ${./agent-browser/helium.py} \
          ${pkgs.helium}/bin/helium "$@"
      '';
      agent_browser = pkgs.writeShellScriptBin "agent-browser" ''
        export AGENT_BROWSER_EXECUTABLE_PATH="''${AGENT_BROWSER_EXECUTABLE_PATH:-${helium_browser}/bin/agent-browser-helium}"
        exec ${pkgs.python3}/bin/python3 ${./agent-browser/session.py} \
          ${agent_browser_unwrapped}/bin/agent-browser "$@"
      '';
      dashboard = pkgs.writeShellScriptBin "agent-browser-dashboard" ''
        ${pkgs.systemd}/bin/systemctl --user start agent-browser-dashboard.service
        exec ${pkgs.xdg-utils}/bin/xdg-open http://localhost:4848
      '';
      skill = {
        source = ./agent-browser/SKILL.md;
        force = true;
      };
    in
    {
      home.packages = [
        agent_browser
        dashboard
      ];
      home.file = {
        ".agents/skills/agent-browser/SKILL.md" = skill;
        ".claude/skills/agent-browser/SKILL.md" = skill;
        ".config/opencode/skills/agent-browser/SKILL.md" = skill;
        ".pi/agent/skills/agent-browser/SKILL.md" = skill;
      };
      systemd.user.services.agent-browser-dashboard = {
        Unit = {
          Description = "Agent browser dashboard";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "forking";
          PIDFile = "%t/agent-browser/dashboard.pid";
          Environment = "AGENT_BROWSER_EXECUTABLE_PATH=${helium_browser}/bin/agent-browser-helium";
          ExecStart = "${agent_browser_unwrapped}/bin/agent-browser dashboard start";
          ExecStop = "${agent_browser_unwrapped}/bin/agent-browser dashboard stop";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
      xdg.desktopEntries.agent-browser-dashboard = {
        name = "Agent Browser Dashboard";
        genericName = "Watch and control agent browsers";
        exec = "${dashboard}/bin/agent-browser-dashboard";
        icon = "web-browser";
        terminal = false;
        categories = [
          "Development"
          "Network"
        ];
      };
    };
}
