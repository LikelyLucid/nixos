{ inputs, ... }:
{
  homeManager.modules.desktop = {
    imports = [ inputs.zenBrowser.homeModules.default ];
    programs.zen-browser.enable = true;
  };
}
