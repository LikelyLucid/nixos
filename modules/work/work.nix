{ config, lib, pkgs, ... }:
{
  ############################################
  # WORK: gcloud CLI
  ############################################
  environment.systemPackages = with pkgs; [
    google-cloud-sdk
    codex  # Codex CLI (available for standalone use)
  ];

  ############################################
  # WORK: Codex Desktop (OpenAI coding agent)
  ############################################
  programs.codexDesktopLinux = {
    enable = true;
    # cliPackage intentionally NOT set — let the Desktop manage its own CLI
    # compatibility. The nixpkgs codex CLI (0.47.0) uses different app-server
    # flags than what the Desktop (26.616.41845) expects.
    # computerUseUi.enable = true; # uncomment if you need computer use UI
    # remoteMobileControl.enable = true; # uncomment if you need mobile control
  };
}
