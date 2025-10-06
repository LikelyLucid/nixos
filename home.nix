{ pkgs, zenBrowser, lazyvim-config, dotfiles, ... }:
let
  home_dir = "/home/lucid";
in {
  ############################################
  # MODULE IMPORTS
  ############################################
  imports = [
    ./modules/window-manager/hyprland-config.nix
    ./modules/dev/developer.nix
    ./modules/notes/notes.nix
    ./modules/browsers/browsers.nix
    ./modules/dotfiles.nix
    ./modules/office/office.nix
    ./modules/university/university.nix
  ];

  ############################################
  # USER DETAILS
  ############################################
  home.username = "lucid";
  home.homeDirectory = home_dir;

  ############################################
  # SESSION VARIABLES
  ############################################
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${home_dir}/.secrets/age.agekey";
    OZONE_PLATFORM = "wayland";
  };

  ############################################
  # HOME PACKAGES
  ############################################
  home.packages = with pkgs; [
    cava
    codex
    fastfetch
    hyprpaper
    kitty
    noto-fonts
    noto-fonts-cjk-sans
    pavucontrol
    python3
    rofi
    spotify-player
    wallust
    waybar
  ];

  ############################################
  # FONT CONFIGURATION
  ############################################
  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans" ];

  ############################################
  # SYNCTHING
  ############################################
  services.syncthing = {
    enable = true;
    package = pkgs.syncthing;
    guiAddress = "127.0.0.1:8384";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        lucid-server = {
          id = "6XWWGNN-R7HBLRL-CHGQSTV-BYLYWXP-YTIXXLG-EEXRZLN-2EDHEAF-JSRIDAP";
          name = "lucid-server";
        };
        bigboy = {
          id = "XHF4Y4B-QZM2XII-R7W5IG2-DXGQONP-DHPYDJH-OEGHNVR-7S6MXIL-R5LFQAY";
          name = "bigboy";
        };
      };
      folders."Vault-V2" = {
        id = "Vault-V2";
        path = "${home_dir}/Documents/Vault";
        label = "Vault-V2 - Obsidian";
        devices = [ "lucid-server" ];
        versioning = {
          type = "simple";
          params.keep = 10;
        };
      };
      gui.theme = "black";
    };
  };

  ############################################
  # STATE VERSION
  ############################################
  home.stateVersion = "23.05";
}
