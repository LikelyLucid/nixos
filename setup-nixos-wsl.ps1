<#
.SYNOPSIS
    One-command setup of NixOS on WSL2 — clone the repo, run this, done.
    Fully automated: downloads WSL image, imports, rebuilds, symlinks config,
    and walks you through Vaultwarden API key setup (the only interactive step).
#>

param(
    [string]$DistroName = "NixOS",
    [string]$InstallDir = "$env:USERPROFILE\wsl\nixos"
)

$ErrorActionPreference = "Stop"

# ─── Detect config repo location (where THIS script lives, then go up one) ───
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigSource = $ScriptDir  # The repo root (contains flake.nix, hosts/, modules/, etc.)

# Verify flake.nix exists
if (-not (Test-Path "$ConfigSource\flake.nix")) {
    # Maybe the script is in a subdirectory? Try parent.
    $ParentDir = Split-Path -Parent $ScriptDir
    if (Test-Path "$ParentDir\flake.nix") {
        $ConfigSource = $ParentDir
    } else {
        Write-Host "`n[FAIL] Cannot find flake.nix. Is this script inside your NixOS config repo?" -ForegroundColor Red
        Write-Host "  Expected location: <repo-root>\setup-nixos-wsl.ps1" -ForegroundColor Yellow
        Write-Host "  Script directory:  $ScriptDir" -ForegroundColor Yellow
        exit 1
    }
}

# ─── Convert Windows path to WSL mount path ────────────────────────────
# C:\path → /mnt/c/path, D:\path → /mnt/d/path, etc.
$DriveLetter = $ConfigSource.Substring(0, 1).ToLower()
$RestOfPath = $ConfigSource.Substring(2).Replace("\", "/")
$ConfigMount = "/mnt/$DriveLetter$RestOfPath"
$FlakeRef = "$ConfigMount#wsl"

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     NixOS WSL — Fully Automated Setup                       ║" -ForegroundColor Cyan
Write-Host "║     Config: $ConfigSource" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ─── 1. Prerequisites ────────────────────────────────────────────────────────
Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Cyan

wsl --version 2>$null
if (-not $?) {
    Write-Host "  [FAIL] WSL not installed. Run: wsl --install" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] WSL 2 installed" -ForegroundColor Green

$existing = wsl --list --quiet 2>$null
$needsImport = $true
if ($existing -match [regex]::Escape($DistroName)) {
    Write-Host "  [INFO] Distribution '$DistroName' already exists" -ForegroundColor Yellow
    $choice = Read-Host "  Reinstall? (y/N)"
    if ($choice -eq "y") {
        wsl --unregister $DistroName
        Write-Host "  [OK] Removed existing '$DistroName'" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Reusing existing '$DistroName'" -ForegroundColor Green
        $needsImport = $false
    }
}

# ─── 2. Download & Import NixOS WSL ──────────────────────────────────────────
if ($needsImport) {
    Write-Host ""
    Write-Host "[2/6] Downloading NixOS WSL (~500 MB)..." -ForegroundColor Cyan
    $downloadUrl = "https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos.wsl"
    $imagePath = "$env:TEMP\nixos.wsl"
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $imagePath -ErrorAction Stop
    } catch {
        Write-Host "  [FAIL] Download failed: $_" -ForegroundColor Red
        exit 1
    }
    $sizeMB = [math]::Round((Get-Item $imagePath).Length / 1MB)
    Write-Host "  [OK] Downloaded ($sizeMB MB)" -ForegroundColor Green

    Write-Host ""
    Write-Host "[3/6] Importing into WSL..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    wsl --import $DistroName $InstallDir $imagePath --version 2
    Write-Host "  [OK] Imported '$DistroName'" -ForegroundColor Green
    wsl --set-default $DistroName
    Write-Host "  [OK] Set as default distro" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[2/6] Skipping download — using existing distro" -ForegroundColor Cyan
    Write-Host "[3/6] Skipping import — using existing distro" -ForegroundColor Cyan
}

# ─── 4. Copy config & rebuild inside WSL ─────────────────────────────────────
Write-Host ""
Write-Host "[4/6] Building NixOS (first build takes 5-15 min)..." -ForegroundColor Cyan
Write-Host "  Config source (Windows): $ConfigSource"
Write-Host "  Config mount (WSL):      $ConfigMount"
Write-Host ""

$wslBuildScript = @"
set -e
NIX_CONFIG="experimental-features = nix-command flakes"

echo "  Copying config from Windows..."
rm -rf /etc/nixos 2>/dev/null || true
cp -r $ConfigMount/* /etc/nixos/
cp $ConfigMount/.gitignore /etc/nixos/ 2>/dev/null || true

echo "  Building system (checking binary cache first)..."
nixos-rebuild switch --flake /etc/nixos#wsl --accept-flake-config 2>&1

echo ""
echo "  [OK] Build complete. Creating config symlink in lucid's home..."
"@

wsl -d $DistroName -- bash -c "$wslBuildScript" 2>&1

# ─── 5. Create symlink so future rebuilds reference Windows files ────────────
Write-Host ""
Write-Host "[5/6] Setting up persistent config symlink..." -ForegroundColor Cyan

$wslSymlinkScript = @"
set -e
# Wait for lucid user to exist
for i in 1 2 3 4 5 6 7 8 9 10; do
    if id lucid &>/dev/null; then break; fi
    sleep 1
done

LUCID_HOME="/home/lucid"

# Create symlink: ~/nixos -> the Windows-mounted repo
if [ -L "\$LUCID_HOME/nixos" ] || [ -d "\$LUCID_HOME/nixos" ]; then
    echo "  ~/nixos already exists, skipping symlink"
else
    ln -sf $ConfigMount "\$LUCID_HOME/nixos"
    chown -h lucid:users "\$LUCID_HOME/nixos"
    echo "  [OK] Symlink created: ~/nixos -> $ConfigMount"
fi

# Also create /etc/nixos symlink for good measure
rm -rf /etc/nixos 2>/dev/null || true
ln -sf $ConfigMount /etc/nixos
echo "  [OK] Symlink created: /etc/nixos -> $ConfigMount"
"@

wsl -d $DistroName -- bash -c "$wslSymlinkScript" 2>&1

# ─── 6. Bitwarden API key setup (only interactive step) ─────────────────────
Write-Host ""
Write-Host "[6/6] Setting up Vaultwarden secrets..." -ForegroundColor Cyan

$wslBitwardenSetup = @'
set -e
# Try to find bitwarden-cli via nix profile or system packages
BW_CMD=""
for candidate in bw /run/current-system/sw/bin/bw /etc/profiles/per-user/lucid/bin/bw; do
    if command -v "$candidate" &>/dev/null; then
        BW_CMD="$candidate"
        break
    fi
done

if [ -z "$BW_CMD" ]; then
    # Launch nix shell if bw not available yet
    echo "  Bitwarden CLI not in PATH, launching temporary nix shell..."
    exec nix shell nixpkgs#bitwarden-cli --command bash "$HOME/nixos/scripts/setup-bitwarden.sh"
else
    bash "$HOME/nixos/scripts/setup-bitwarden.sh"
fi
'@

# Check if Bitwarden is already configured
$wslCheckBw = @'
if [ -f "/home/lucid/.config/bw-client-id" ] && [ -f "/home/lucid/.config/bw-client-secret" ]; then
    if [ -n "$(cat /home/lucid/.config/bw-client-id 2>/dev/null)" ]; then
        echo "configured"
    fi
fi
'@

$bwStatus = wsl -d $DistroName -- bash -c "$wslCheckBw" 2>$null
if ($bwStatus -eq "configured") {
    Write-Host "  [OK] Vaultwarden already configured" -ForegroundColor Green
    Write-Host "  To reconfigure, delete ~/.config/bw-client-{id,secret} inside WSL." -ForegroundColor Yellow
} else {
    Write-Host "  You need to set up your Vaultwarden API key (one-time, never expires)." -ForegroundColor Yellow
    Write-Host "  This is the only interactive step." -ForegroundColor Yellow
    Write-Host "  Press Enter to start, or 's' to skip and do it later." -ForegroundColor Yellow
    $choice = Read-Host "  [Enter=start, s=skip]"
    if ($choice -ne "s") {
        wsl -d $DistroName -- bash -c "$wslBitwardenSetup" 2>&1
    } else {
        Write-Host "  Skipped. Run later: wsl -d NixOS -- bash ~/nixos/scripts/setup-bitwarden.sh" -ForegroundColor Yellow
    }
}

# ─── Restart WSL to apply ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "Restarting WSL..." -ForegroundColor Cyan
wsl --terminate $DistroName 2>$null
Start-Sleep -Seconds 3

# ─── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     NIXOS WSL IS READY!                                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Enter WSL:" -ForegroundColor White
Write-Host "    wsl -d $DistroName"
Write-Host ""
Write-Host "  Your config repo is at:" -ForegroundColor White
Write-Host "    ~/nixos  →  $ConfigMount"
Write-Host ""
Write-Host "  Rebuild after editing (from inside WSL):" -ForegroundColor White
Write-Host "    sudo nixos-rebuild switch --flake ~/nixos#wsl"
Write-Host ""
Write-Host "  Start pi coding agent:" -ForegroundColor White
Write-Host "    pi"
Write-Host ""
Write-Host "  Edit config on Windows:" -ForegroundColor White
Write-Host "    cd $ConfigSource"
Write-Host "    code ."
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
