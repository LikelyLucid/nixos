{ ... }:
{
  nixos.modules.desktop.services.gnome.gnome-keyring.enable = true;

  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        libsecret
        seahorse
      ];
    };
}
