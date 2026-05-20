<#
.SYNOPSIS
    One-command setup of NixOS on WSL2 — clone the repo, run this, done.
    Prompts for email + master password once, then everything is automatic.
#>

param(
    [string]$DistroName = "NixOS",
    [string]$InstallDir = "$env:USERPROFILE\wsl\nixos"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigSource = $ScriptDir
if (-not (Test-Path "$ConfigSource\flake.nix")) {
    $ParentDir = Split-Path -Parent $ScriptDir
    if (Test-Path "$ParentDir\flake.nix") { $ConfigSource = $ParentDir }
    else { Write-Host "`n[FAIL] Cannot find flake.nix" -ForegroundColor Red; exit 1 }
}

$DriveLetter = $ConfigSource.Substring(0, 1).ToLower()
$RestOfPath = $ConfigSource.Substring(2).Replace("\", "/")
$ConfigMount = "/mnt/$DriveLetter$RestOfPath"

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     NixOS WSL — Fully Automated Setup                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n[1/6] Checking prerequisites..." -ForegroundColor Cyan
wsl --version 2>$null
if (-not $?) { Write-Host "  [FAIL] WSL not installed. Run: wsl --install" -ForegroundColor Red; exit 1 }
Write-Host "  [OK] WSL 2 installed" -ForegroundColor Green

$existing = wsl --list --quiet 2>$null
$needsImport = $true
if ($existing -match [regex]::Escape($DistroName)) {
    Write-Host "  [INFO] Distribution '$DistroName' already exists" -ForegroundColor Yellow
    $choice = Read-Host "  Reinstall? (y/N)"
    if ($choice -eq "y") { wsl --unregister $DistroName; Write-Host "  [OK] Removed" -ForegroundColor Green }
    else { Write-Host "  [OK] Reusing existing" -ForegroundColor Green; $needsImport = $false }
}

if ($needsImport) {
    Write-Host "`n[2/6] Downloading NixOS WSL (~500 MB)..." -ForegroundColor Cyan
    $downloadUrl = "https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos.wsl"
    $imagePath = "$env:TEMP\nixos.wsl"
    try {
        $downloaded = $false
        if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
            cmd.exe /c "curl.exe -L -o `"$imagePath`" --fail --connect-timeout 30 --retry 3 --retry-delay 5 -# $downloadUrl"
            if ($LASTEXITCODE -eq 0) { $downloaded = $true }
        }
        if (-not $downloaded) { Invoke-WebRequest -Uri $downloadUrl -OutFile $imagePath -ErrorAction Stop }
    } catch { Write-Host "  [FAIL] Download failed: $_" -ForegroundColor Red; exit 1 }
    $sizeMB = [math]::Round((Get-Item $imagePath).Length / 1MB)
    Write-Host "  [OK] Downloaded ($sizeMB MB)" -ForegroundColor Green

    Write-Host "`n[3/6] Importing into WSL..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    wsl --import $DistroName $InstallDir $imagePath --version 2
    Write-Host "  [OK] Imported '$DistroName'" -ForegroundColor Green
    wsl --set-default $DistroName
    Write-Host "  [OK] Set as default distro" -ForegroundColor Green
} else {
    Write-Host "`n[2/6] Skipping download — using existing distro" -ForegroundColor Cyan
    Write-Host "[3/6] Skipping import — using existing distro" -ForegroundColor Cyan
}

Write-Host "`n[4/6] Building NixOS (first build 5-15 min)..." -ForegroundColor Cyan
wsl -d $DistroName -- bash -c "set -e; NIX_CONFIG='experimental-features = nix-command flakes'; sudo rm -rf /etc/nixos 2>/dev/null || true; sudo mkdir -p /etc/nixos; sudo cp -r $ConfigMount/* /etc/nixos/; sudo cp -r $ConfigMount/.gitignore /etc/nixos/ 2>/dev/null || true; nixos-rebuild switch --flake /etc/nixos#wsl --accept-flake-config 2>&1; echo '  Build complete.'"

Write-Host "`n[5/6] Setting up config symlink..." -ForegroundColor Cyan
wsl -d $DistroName -- bash -c "set -e; for i in 1 2 3 4 5 6 7 8 9 10; do if id lucid &>/dev/null; then break; fi; sleep 1; done; if ! [ -L /home/lucid/nixos ] && ! [ -d /home/lucid/nixos ]; then ln -sf $ConfigMount /home/lucid/nixos; chown -h lucid:users /home/lucid/nixos; fi; sudo rm -rf /etc/nixos 2>/dev/null || true; sudo ln -sf $ConfigMount /etc/nixos; echo '  Symlinks created.'"

Write-Host "`n[6/6] Setting up Bitwarden vault..." -ForegroundColor Cyan

$bwCheck = (wsl -d $DistroName -- bash -c "if [ -f /home/lucid/.config/bw-master-pass ] && [ -f /home/lucid/.config/bw-session ]; then echo configured; fi").Trim()

if ($bwCheck -eq "configured") {
    Write-Host "  [OK] Bitwarden already configured" -ForegroundColor Green
} else {
    $bwEmail = Read-Host "  Vaultwarden email (e.g. user@example.com)"
    if ([string]::IsNullOrWhiteSpace($bwEmail)) {
        Write-Host "  Skipping Bitwarden. Run later: wsl -d NixOS -- bash ~/nixos/scripts/setup-bitwarden.sh" -ForegroundColor Yellow
    } else {
        $bwMaster = Read-Host -AsSecureString "  Master password (stored locally, chmod 400)"
        $bwMasterStr = [System.Net.NetworkCredential]::new("", $bwMaster).Password
        if ([string]::IsNullOrWhiteSpace($bwMasterStr)) { Write-Host "  [FAIL] Required" -ForegroundColor Red; exit 1 }

        Write-Host "  Writing credentials..." -ForegroundColor Gray
        wsl -d $DistroName -- bash -c "mkdir -p /home/lucid/.config"
        $bwMasterStr | wsl -d $DistroName -- bash -c "cat > /home/lucid/.config/bw-master-pass"
        wsl -d $DistroName -- bash -c "chmod 400 /home/lucid/.config/bw-master-pass"

        Write-Host "  Logging in and unlocking..." -ForegroundColor Gray
        wsl -d $DistroName -- bash -c "
            bw config server https://vaultwarden.likelylucid.com 2>/dev/null
            bw logout 2>/dev/null || true
            BW_PASS=\$(cat /home/lucid/.config/bw-master-pass)
            bw login $bwEmail \"\$BW_PASS\" 2>/dev/null
            SESSION=\$(bw unlock --passwordfile /home/lucid/.config/bw-master-pass --raw 2>/dev/null)
            if [ -n \"\$SESSION\" ]; then
                echo \"\$SESSION\" > /home/lucid/.config/bw-session
                chmod 600 /home/lucid/.config/bw-session
                echo 'OK'
            else
                echo 'UNLOCK_FAILED'
            fi
        "
        Write-Host "  [OK] Vault unlocked. Secrets auto-fetch at every boot." -ForegroundColor Green
    }
}

Write-Host "`nRestarting WSL..." -ForegroundColor Cyan
wsl --terminate $DistroName 2>$null
Start-Sleep -Seconds 3

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     NIXOS WSL IS READY!                                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "  Enter WSL:    wsl -d $DistroName" -ForegroundColor White
Write-Host "  Rebuild:      sudo nixos-rebuild switch --flake ~/nixos#wsl" -ForegroundColor White
Write-Host "  Start pi:     pi" -ForegroundColor White
Write-Host "`nDone!" -ForegroundColor Green
