{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs;
  let
    RStudio-with-my-packages = rstudioWrapper.override {
      packages = with rPackages; [
        tidyverse # ggplot2 is part of tidyverse
      ];
    };
  in [
    RStudio-with-my-packages
  ];
}