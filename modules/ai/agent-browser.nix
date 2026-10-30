{ getSystem, ... }:
{
  homeManager.modules.desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      agent_browser_unwrapped =
        (getSystem pkgs.stdenv.hostPlatform.system).packages.agent-browser-unwrapped;
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
        pkgs.chromium
        dashboard
      ];
      home.activation.codexAgentBrowserMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${osConfig.programs.codexDesktopLinux.cliPackage}/bin/codex mcp add agent-browser -- \
          ${agent_browser}/bin/agent-browser mcp --tools all
      '';
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
