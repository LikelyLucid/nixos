{ ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
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
    in
    {
      devShells.r = pkgs.mkShell {
        packages = [
          rstudio_with_workspace_packages
          pkgs.R
        ];

        QT_QPA_PLATFORM = "wayland";
        QT_SCALE_FACTOR = "1";
      };
    };
}
