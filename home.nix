{ config, pkgs, zenBrowser, lazyvim-config, dotfiles, ... }:

{
  imports = [
    ./modules/window-manager/hyprland-config.nix
    ./modules/dev/developer.nix
    ./modules/notes/notes.nix
    ./modules/browsers/browsers.nix
    ./modules/dotfiles.nix
  ];

  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  home.packages = with pkgs; [
    hyprpaper
    waybar
    kitty
    rofi-wayland
    cava
    wallust
    spotify-player
    fastfetch
  ];

 services.syncthing = {
  enable         = true;
  package        = pkgs.syncthing;
  guiAddress     = "127.0.0.1:8384";

  # Keep any manually-added peers/folders if you like,
  # or have Home-Manager wipe them on restart:
  overrideDevices = true;    # delete any peer not in settings.devices
  overrideFolders = true;    # delete any folder not in settings.folders

  settings = {
    # define all your peers here
    devices = {
      lucid-server = {
        id   = "6XWWGNN-R7HBLRL-CHGQSTV-BYLYWXP-YTIXXLG-EEXRZLN-2EDHEAF-JSRIDAP";
        name = "lucid-server";
        # optionally:
        # addresses = [ "tcp://your.server.ip:22000" ];
        # autoAcceptFolders = true;
      };
      bigboy = {
        id   = "XHF4Y4B-QZM2XII-R7W5IG2-DXGQONP-DHPYDJH-OEGHNVR-7S6MXIL-R5LFQAY";
        name = "bigboy";
      };
    };

    # define all your shared folders here
    folders = {
      # Must match exactly the Folder ID the server is advertising:
      "Vault-V2" = {
        id      = "Vault-V2";
        path    = "${config.home.homeDirectory}/Documents/Vault";
        label   = "Vault-V2 - Obsidian";    # optional, just to match your GUI label
        devices = [ "lucid-server" ];
        versioning = {
          type   = "simple";
          params = { keep = 10; };
        };
      };
    };
    # any other top-level settings you want…
    options = {
      # listenAddresses = [ "default" ];
      # minHomeDiskFree = { unit = "%"; value = 1; };
    };
    gui = { theme = "black"; };
  };
};
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ./secrets/secrets.yaml;
  };

  home.stateVersion = "23.05";
}
