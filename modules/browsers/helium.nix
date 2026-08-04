{ ... }:
{
  homeManager.modules.desktop =
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

      # Enable remote debugging for Hermes browser CDP connection
      xdg.desktopEntries.helium = {
        name = "Helium";
        genericName = "Web Browser";
        categories = [
          "Network"
          "WebBrowser"
        ];
        exec = "helium --remote-debugging-port=9222 %U";
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
        terminal = false;
        type = "Application";
      };

      # Set BROWSER env var for terminal tools
      home.sessionVariables.BROWSER = "helium";
    };
}
