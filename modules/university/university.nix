{ config, pkgs, ... }:

{
  imports = [
    ./r.nix
    ./zotero.nix
  ];
}
