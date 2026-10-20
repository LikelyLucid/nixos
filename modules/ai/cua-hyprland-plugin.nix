{ inputs, ... }:
{
  homeManager.modules.desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hyprland = osConfig.programs.hyprland.package;
      cua_plugin = hyprland.stdenv.mkDerivation {
        pname = "cua-hyprland-plugin";
        version = "0.1.0";
        src = "${inputs.cua-driver}/libs/cua-driver/hyprland-plugin";
        nativeBuildInputs = [
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.python3
        ];
        buildInputs = [ hyprland ] ++ hyprland.buildInputs;
        cmakeFlags = [
          "-DCUA_HYPRLAND_INPUT=ON"
          "-DCUA_HYPRLAND_INPUT_TRACE=OFF"
          "-DCUA_HYPRLAND_TEST_INPUT=OFF"
          "-DCUA_HYPRLAND_EXPECTED_VERSION=${hyprland.version}"
          "-DBUILD_TESTING=ON"
        ];
        doCheck = true;
        CUA_HYPRLAND_REQUIRE_XKBCOMMON = "1";
        passthru.hyprlandPackage = hyprland;
        meta = {
          description = "CUA isolated agent seats built for the configured Hyprland ABI";
          homepage = "https://github.com/trycua/cua/tree/main/libs/cua-driver/hyprland-plugin";
          license = lib.licenses.mit;
          platforms = lib.platforms.linux;
        };
      };
    in
    {
      home.packages = [ cua_plugin ];
      xdg.configFile."hypr/hyprland.lua".text = lib.mkAfter ''

        -- Built with this compositor's headers and compiler. Rebuild together.
        hl.plugin.load("${cua_plugin}/lib/cua/hyprland/cua-hyprland-plugin.so")
        hl.config({ plugin = { cua = { enabled = true } } })
      '';
    };
}
