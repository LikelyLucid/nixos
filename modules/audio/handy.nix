{ inputs, ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      imports = [ inputs.handy.nixosModules.default ];

      programs.handy = {
        enable = true;
        package = inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.handy;
      };

      users.users.lucid.extraGroups = [ "input" ];
    };
}
