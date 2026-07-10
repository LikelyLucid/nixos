{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ onlyoffice-desktopeditors ];
    };
}
