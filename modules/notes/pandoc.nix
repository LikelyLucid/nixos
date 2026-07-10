{ ... }:
{
  homeManager.modules.pandoc =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ pandoc ];
    };
}
