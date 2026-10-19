{ inputs, ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = [ inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.t3code-nightly ];
    };
}
