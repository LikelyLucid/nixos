{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ zotero ];
    };
}
