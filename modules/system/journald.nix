{ ... }:
{
  nixos.modules.common.services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=1month
  '';
}
