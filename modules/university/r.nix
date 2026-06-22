{ pkgs, ... }:
let
  r_workspace_packages = with pkgs.rPackages; [
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
  rstudio_with_workspace_packages = pkgs.rstudioWrapper.override {
    packages = r_workspace_packages;
  };
in {
  ############################################
  # R WORKSTATION
  ############################################
  home.packages = with pkgs; [
    rstudio_with_workspace_packages
    R                 # R CLI for R language server and scripting
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_SCALE_FACTOR = "1";
  };
}
