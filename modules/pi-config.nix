{ config, lib, pi-config, isWsl ? false, ... }:
let
  mk_link = config.lib.file.mkOutOfStoreSymlink;
in {
  # Symlink pi-config files to ~/.pi/agent/
  # Pi auto-discovers extensions under ~/.pi/agent/extensions/
  home.file = {
    ".pi/agent/AGENTS.md".source = mk_link "${pi-config}/AGENTS.md";
    ".pi/agent/settings.json".source = mk_link "${pi-config}/settings.json";
    ".pi/agent/README.md".source = mk_link "${pi-config}/README.md";
    ".pi/agent/extensions/pi-ollama-cloud".source = mk_link "${pi-config}/extensions/pi-ollama-cloud";
  };
}
