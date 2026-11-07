{ inputs, ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      # Keep Zotero and its ESR 140 dependency on the compatibility snapshot.
      zotero_pkgs = inputs.nixpkgs-zotero.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [ zotero_pkgs.zotero ];
    };
}
