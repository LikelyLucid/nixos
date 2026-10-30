{ inputs, ... }:
{
  nixos.modules.desktop = {
    imports = [ inputs.hex.nixosModules.hex ];
    programs.hex.enable = true;
  };

  homeManager.modules.desktop =
    { lib, ... }:
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
