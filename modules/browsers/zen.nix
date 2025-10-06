{ zenBrowser, ... }:
{
  imports = [ zenBrowser.homeModules.default ];
  programs.zen-browser.enable = true;
}
