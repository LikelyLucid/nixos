{ config, pkgs, ... }:

{
  ############################################
  # R WORKSTATION CONFIGURATION
  ############################################

  home.packages = with pkgs;
  let
    r_workspace_packages = with rPackages; [
      tidyverse
      data_table
      janitor
      lubridate
      stringi
      readxl
      readr
      kableExtra
      knitr
      rmarkdown
      tinytex
      devtools
      renv
      usethis
      testthat
      lintr
      styler
      languageserver
      GGally
      ggthemes
      ggrepel
      patchwork
      performance
      see
      leaps
      mice
      sf
      tmap
      leaflet
      leaflet_extras
      shiny
      shinydashboard
      plotly
      codetools
    ];
    rstudio_with_workspace_packages = rstudioWrapper.override {
      packages = r_workspace_packages;
    };
  in [
    rstudio_with_workspace_packages
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_SCALE_FACTOR = "1";
  };
}
