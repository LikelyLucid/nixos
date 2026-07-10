{ ... }:
{
  nixos.modules.common =
    { ... }:

    {
      ############################################
      # BINARY CACHES
      ############################################
      nix.settings = {
        substituters = [
          "https://pi.cachix.org"
          "https://codex-cli.cachix.org"
          "https://codex-desktop-linux.cachix.org"
          "https://nix-community.cachix.org"
          "https://cache.garnix.io"
          "https://cache.thalheim.io"
        ];

        trusted-public-keys = [
          "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
          "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
          "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
        ];
      };
    };
}
