{ pkgs, ... }:
{
  home.packages = with pkgs; [ libreoffice ];
  home.sessionVariables.SAL_USE_VCLPLUGIN = "gtk3";
}
