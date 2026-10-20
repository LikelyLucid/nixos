{ inputs, ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      # Zotero 10 requires ESR 140; current nixpkgs incorrectly uses ESR 153.
      # Keep this compatibility snapshot local to Zotero, not the whole system.
      zotero_pkgs = inputs.nixpkgs-zotero.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [
        (pkgs.zotero.override {
          firefox-esr-153-unwrapped = zotero_pkgs.firefox-esr-140-unwrapped;
        })
      ];
    };
}
