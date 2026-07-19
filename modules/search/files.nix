{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fsearch ];
    };
}
