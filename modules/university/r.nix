{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs;
  let
    RStudio-with-my-packages = rstudioWrapper.override {
      packages = with rPackages; [
        tidyverse performance readr kableExtra see
      ];
    };
  in [
    RStudio-with-my-packages
  ];
}
