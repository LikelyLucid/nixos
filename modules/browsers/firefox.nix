{ ... }:
{
  homeManager.modules.firefox =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ firefox ];
    };
}
