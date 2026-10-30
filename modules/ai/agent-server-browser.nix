{ getSystem, ... }:
{
  homeManager.modules.agent-server =
    { pkgs, ... }:
    let
      inherit (getSystem pkgs.stdenv.hostPlatform.system) packages;
      skill = {
        source = "${packages.agent-browser-unwrapped}/skills/agent-browser/SKILL.md";
      };
    in
    {
      home.packages = [
        packages.agent-browser-headless
        pkgs.chromium
      ];
      home.file = {
        ".agents/skills/agent-browser/SKILL.md" = skill;
        ".claude/skills/agent-browser/SKILL.md" = skill;
        ".config/opencode/skills/agent-browser/SKILL.md" = skill;
        ".local/state/agent-proxy/pi/skills/agent-browser/SKILL.md" = skill;
      };
    };
}
