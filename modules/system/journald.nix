{ ... }:
{
  nixos.modules.common.services.journald.settings.Journal = {
    SystemMaxUse = "1G";
    MaxRetentionSec = "1month";
  };
}
