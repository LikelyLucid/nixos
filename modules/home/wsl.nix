{ ... }:
{
  homeManager.modules.wsl = {
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    programs.zsh = {
      shellAliases.winhome = ''cd "$(wslpath "$(powershell.exe -NoProfile -NonInteractive -Command Write-Output '$env:USERPROFILE' 2>/dev/null | tr -d '\r\n')" 2>/dev/null || echo /mnt/c/Users)"'';

      initContent = ''
        # Detect Windows home directory dynamically (works for any Windows username)
        if [[ -z "$WIN_HOME" ]]; then
          export WIN_HOME=$(wslpath "$(powershell.exe -NoProfile -NonInteractive -Command Write-Output '$env:USERPROFILE' 2>/dev/null | tr -d '\r\n')" 2>/dev/null)
        fi
      '';
    };
  };
}
