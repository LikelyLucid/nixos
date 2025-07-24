{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rstudioWrapper
    R
  ];
}
