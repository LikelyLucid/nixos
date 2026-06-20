{ config, lib, pkgs, ... }:
{
  ############################################
  # WORK: gcloud CLI
  ############################################
  environment.systemPackages = with pkgs; [
    google-cloud-sdk
  ];
}
