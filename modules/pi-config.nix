{
  config,
  lib,
  pi-config,
  isWsl ? false,
  ...
}:
let
  cfg = "/home/lucid/pi-config";
  mk_link = config.lib.file.mkOutOfStoreSymlink;
in
{
  # Symlink pi-config files to ~/.pi/agent/
  # Pi auto-discovers extensions under ~/.pi/agent/extensions/
  # Using absolute paths so edits in ~/pi-config/ are live immediately
  home.file = {
    ".pi/agent/AGENTS.md".source = mk_link "${cfg}/AGENTS.md";
    ".pi/agent/settings.json".source = mk_link "${cfg}/settings.json";
    ".pi/agent/README.md".source = mk_link "${cfg}/README.md";
    ".pi/agent/mcp.json".source = mk_link "${cfg}/mcp.json";
    ".pi/agent/models.json".source = mk_link "${cfg}/models.json";
    ".pi/agent/extensions".source = mk_link "${cfg}/extensions";
    ".pi/agent/prompts".source = mk_link "${cfg}/prompts";
    ".pi/agent/themes/terminal-wallust.json".source = ../modules/pi-terminal-wallust-theme.json;
  };
}
