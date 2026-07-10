{ ... }:
{
  nixos.modules.common =
    { pkgs, ... }:
    {
      ############################################
      # NIX
      ############################################
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };

      nixpkgs.config.allowUnfree = true;

      ############################################
      # USER
      ############################################
      users.users.lucid = {
        isNormalUser = true;
        description = "Arthur Mckellar";
        shell = pkgs.zsh;
      };
      users.defaultUserShell = pkgs.zsh;
      programs.zsh.enable = true;

      ############################################
      # NIX HELPER
      ############################################
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 5d --keep 5";
        flake = "/home/lucid/nixos";
      };
    };
}
