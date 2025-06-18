{ pkgs, zenBrowser, ... }:
{
  imports = [
    ./firefox.nix
    ./zen.nix
  ];
}
