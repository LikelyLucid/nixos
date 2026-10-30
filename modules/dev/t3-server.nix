{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      packages.t3-server = inputs.t3code.packages.${system}.t3-cli;
    };
}
