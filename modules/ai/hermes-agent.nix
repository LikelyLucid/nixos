{ inputs, ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      home.packages = [ inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
}
