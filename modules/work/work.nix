{ config, lib, pkgs, ... }:
{
  ############################################
  # WORK: gcloud CLI
  ############################################
  environment.systemPackages = with pkgs; [
    google-cloud-sdk
    codex  # Codex CLI (also wired into Codex Desktop via cliPackage below)
  ];

  ############################################
  # WORK: Codex Desktop + CLI (OpenAI coding agent)
  ############################################
  programs.codexDesktopLinux = {
    enable = true;
    # Wraps the launcher so CODEX_CLI_PATH always points to the nixpkgs CLI
    cliPackage = pkgs.codex;
    # computerUseUi.enable = true; # uncomment if you need computer use UI
    # remoteMobileControl.enable = true; # uncomment if you need mobile control
  };
}
