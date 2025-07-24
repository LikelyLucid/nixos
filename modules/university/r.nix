{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rstudioWrapper
    (rWrapper.override {
      packages = with rPackages; [
        tidyverse
        ggplot2
      ];
    })
  ];
}