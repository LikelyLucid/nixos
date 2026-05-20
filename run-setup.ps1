Write-Host '=========================================' -ForegroundColor Cyan
Write-Host '  NixOS WSL - Bitwarden Setup' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'The NixOS build is done! One last step:' -ForegroundColor Yellow
Write-Host 'Enter your Vaultwarden email + master password once,' -ForegroundColor Yellow
Write-Host 'and secrets will auto-fetch at every boot forever.' -ForegroundColor Yellow
Write-Host ''
& "C:\Users\micoo\nixos\setup-nixos-wsl.ps1"
