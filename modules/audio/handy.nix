{ inputs, ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    let
      handy_package = inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.handy;
      handy_cargo_deps = pkgs.rustPlatform.fetchCargoVendor {
        pname = "handy";
        version = "0.9.6";
        src = inputs.handy;
        cargoRoot = "src-tauri";
        hash = "sha256-Jy1mtpWaG9Rid7F9QpGUIOnOlc9jigFT4ffnB07cb24=";
      };
    in
    {
      imports = [ inputs.handy.nixosModules.default ];

      programs.handy = {
        enable = true;
        package = handy_package.overrideAttrs (old: {
          cargoDeps = handy_cargo_deps;
          postPatch =
            builtins.replaceStrings
              [
                "$cargoDepsCopy/libappindicator-sys-*/src/lib.rs"
                "$cargoDepsCopy/ferrous-opencc-0.2.3/build.rs"
              ]
              [
                "$cargoDepsCopy/source-registry-0/libappindicator-sys-0.9.0/src/lib.rs"
                "$cargoDepsCopy/source-registry-0/ferrous-opencc-0.2.3/build.rs"
              ]
              old.postPatch;
        });
      };

      users.users.lucid.extraGroups = [ "input" ];
    };
}
