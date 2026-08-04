{ ... }:
{
  nixos.modules.desktop = {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };

  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        libsecret
        seahorse
      ];
    };
}
