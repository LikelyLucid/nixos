{ inputs, ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      # Correct the pinned upstream recipe before buildRustPackage consumes cargoLock.
      nixpkgs.overlays = [
        (_final: prev: {
          hex = inputs.hex.packages.${prev.stdenv.hostPlatform.system}.hex.override {
            rustPlatform = prev.rustPlatform // {
              buildRustPackage =
                args:
                prev.rustPlatform.buildRustPackage (
                  final_attrs:
                  let
                    package_attrs = args final_attrs;
                  in
                  package_attrs
                  // {
                    cargoLock = package_attrs.cargoLock // {
                      outputHashes = package_attrs.cargoLock.outputHashes // {
                        # procwatch and rune come from the same pinned Git revision.
                        "procwatch-0.1.0" = package_attrs.cargoLock.outputHashes."rune-0.0.1";
                      };
                    };
                  }
                );
            };
          };
        })
      ];
      imports = [ inputs.hex.nixosModules.hex ];
      programs.hex = {
        enable = true;
        package = pkgs.hex;
      };
    };

  homeManager.modules.desktop =
    { lib, pkgs, ... }:
    let
      hex_hyprland_hotkey = "CTRL + SHIFT + SPACE";
      hex_hyprland_label =
        builtins.replaceStrings [ "CTRL" "SHIFT" ] [ "Ctrl" "Shift" ]
          hex_hyprland_hotkey;
    in
    {
      imports = [ inputs.hex.homeManagerModules.hex ];
      programs.hex = {
        enable = true;
        autostart = true;
        package = pkgs.hex;
      };

      # Keep the shortcut alongside Hex; mkAfter appends it to the generated
      # Hyprland Lua configuration without hard-coding it in that feature.
      xdg.configFile."hypr/hyprland.lua".text = lib.mkAfter ''
        hl.bind(${builtins.toJSON hex_hyprland_hotkey}, hl.dsp.global("hex:dictation"))
      '';

      home.file.".config/hypr/keybinds.txt".text = lib.mkAfter ''

        DICTATION:
          ${hex_hyprland_label}  hold to dictate; release to transcribe
      '';
    };
}
