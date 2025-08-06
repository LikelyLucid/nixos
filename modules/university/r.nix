{ config, pkgs, ... }:

{
  home.packages = with pkgs;
  let
    RStudio-with-my-packages = rstudioWrapper.override {
      packages = with rPackages; [
        tidyverse performance readr kableExtra see readxl stringi GGally
      ];
    };
  in [
    RStudio-with-my-packages
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_SCALE_FACTOR = "1";
  };
}
