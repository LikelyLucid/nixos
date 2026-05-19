{ config, lib, pi-config, isWsl ? false, ... }:
let
  mk_link = config.lib.file.mkOutOfStoreSymlink;
in {
  # Symlink pi-config files to ~/.pi/agent/
  # This makes pi auto-discover the configuration
  home.file = {
    ".pi/agent/AGENTS.md".source = mk_link "${pi-config}/AGENTS.md";
    ".pi/agent/settings.json".source = mk_link "${pi-config}/settings.json";
    ".pi/agent/README.md".source = mk_link "${pi-config}/README.md";
  };
}
