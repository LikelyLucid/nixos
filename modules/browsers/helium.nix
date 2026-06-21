{ pkgs, ... }:
{
  ############################################
  # HELIUM BROWSER — default browser
  ############################################

  home.packages = [ pkgs.helium ];

  # Set as default browser via XDG MIME associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "helium.desktop";
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
      "x-scheme-handler/about" = "helium.desktop";
      "x-scheme-handler/unknown" = "helium.desktop";
    };
  };

  # Set BROWSER env var for terminal tools
  home.sessionVariables.BROWSER = "helium";
}
