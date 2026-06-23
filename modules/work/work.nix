{
  config,
  lib,
  pkgs,
  codex-cli-nix,
  ...
}:
let
  codexCli = codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  ############################################
  # WORK: gcloud CLI
  ############################################
  environment.systemPackages = with pkgs; [
    codexCli # Codex CLI (v0.141.0, compatible with Desktop's app-server flags)
  ];

  ############################################
  # WORK: Codex Desktop (OpenAI coding agent)
  ############################################
  programs.codexDesktopLinux = {
    enable = true;
    # Uses community codex-cli-nix (v0.141.0) which supports --analytics-default-enabled
    cliPackage = codexCli;
    # computerUseUi.enable = true; # uncomment if you need computer use UI
    # remoteMobileControl.enable = true; # uncomment if you need mobile control
  };
}
