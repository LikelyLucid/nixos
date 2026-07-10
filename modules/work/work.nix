{ inputs, ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    let
      codex_cli = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      imports = [ inputs.codex-desktop-linux.nixosModules.default ];

      ############################################
      # WORK: CODEX CLI
      ############################################
      environment.systemPackages = [ codex_cli ];

      ############################################
      # WORK: CODEX DESKTOP
      ############################################
      programs.codexDesktopLinux = {
        enable = true;
        cliPackage = codex_cli;
        # computerUseUi.enable = true; # uncomment if you need computer use UI
        # remoteMobileControl.enable = true; # uncomment if you need mobile control
      };
    };
}
