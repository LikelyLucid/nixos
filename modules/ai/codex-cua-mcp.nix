{ ... }:
{
  homeManager.modules.desktop =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      home.activation.codexCuaDriverMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${osConfig.programs.codexDesktopLinux.cliPackage}/bin/codex mcp add cua-driver \
          --env CUA_DRIVER_RS_ENABLE_WAYLAND=1 -- \
          ${pkgs.cua-driver}/bin/cua-driver mcp \
          --socket ${lib.escapeShellArg "${config.home.homeDirectory}/.cache/cua-driver/cua-driver.sock"}
      '';
    };
}
