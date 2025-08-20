#!/usr/bin/env bash

############################################
# NIXOS CONFIGURATION VALIDATOR
############################################

set -euo pipefail

echo "🔧 NixOS Configuration Validator"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK") echo -e "${GREEN}✓${NC} $message" ;;
        "WARN") echo -e "${YELLOW}⚠${NC} $message" ;;
        "ERROR") echo -e "${RED}✗${NC} $message" ;;
        "INFO") echo -e "${BLUE}ℹ${NC} $message" ;;
    esac
}

# Check if we're in a NixOS configuration directory
if [[ ! -f "flake.nix" ]]; then
    print_status "ERROR" "No flake.nix found. Run this script from the NixOS configuration directory."
    exit 1
fi

print_status "INFO" "Validating NixOS configuration..."

# Check flake syntax
echo ""
echo "📋 Checking flake syntax..."
if nix flake check --no-build 2>/dev/null; then
    print_status "OK" "Flake syntax is valid"
else
    print_status "ERROR" "Flake syntax errors detected"
    echo "Run 'nix flake check' for details"
fi

# Check for common issues
echo ""
echo "🔍 Checking for common configuration issues..."

# Check for proper imports
if grep -r "imports.*=.*\[" hosts/*/configuration.nix > /dev/null; then
    print_status "OK" "Configuration files have proper import statements"
else
    print_status "WARN" "Some configuration files may be missing import statements"
fi

# Check for consistent indentation
echo ""
echo "📏 Checking code style..."

inconsistent_files=()
while IFS= read -r -d '' file; do
    if [[ "$file" == *.nix ]]; then
        # Check for tabs (should use spaces)
        if grep -q $'\t' "$file"; then
            inconsistent_files+=("$file")
        fi
    fi
done < <(find . -name "*.nix" -print0)

if [[ ${#inconsistent_files[@]} -eq 0 ]]; then
    print_status "OK" "All .nix files use consistent indentation (spaces)"
else
    print_status "WARN" "Files with tab characters found (should use 2 spaces):"
    for file in "${inconsistent_files[@]}"; do
        echo "    - $file"
    done
fi

# Check for module organization
echo ""
echo "📁 Checking module organization..."

if [[ -d "modules" ]]; then
    print_status "OK" "Modules directory exists"
    
    # Check for README in modules
    if [[ -f "modules/README.md" ]]; then
        print_status "OK" "Module documentation found"
    else
        print_status "WARN" "Consider adding modules/README.md for documentation"
    fi
else
    print_status "WARN" "No modules directory found - consider organizing configuration into modules"
fi

# Check for security configurations
echo ""
echo "🔐 Checking security configurations..."

security_checks=0
if grep -r "networking.firewall.enable.*=.*true" . > /dev/null; then
    print_status "OK" "Firewall is enabled"
    ((security_checks++))
else
    print_status "WARN" "Firewall not explicitly enabled"
fi

if grep -r "security.apparmor.enable.*=.*true" . > /dev/null; then
    print_status "OK" "AppArmor security framework enabled"
    ((security_checks++))
else
    print_status "WARN" "Consider enabling AppArmor for additional security"
fi

if grep -r "nix.gc.automatic.*=.*true" . > /dev/null; then
    print_status "OK" "Automatic garbage collection enabled"
    ((security_checks++))
else
    print_status "WARN" "Consider enabling automatic garbage collection"
fi

# Performance checks
echo ""
echo "⚡ Checking performance optimizations..."

perf_checks=0
if grep -r "services.tlp.enable.*=.*true" . > /dev/null; then
    print_status "OK" "TLP power management enabled"
    ((perf_checks++))
else
    print_status "WARN" "Consider enabling TLP for better battery management"
fi

if grep -r "zramSwap.enable.*=.*true" . > /dev/null; then
    print_status "OK" "zram swap enabled for better memory management"
    ((perf_checks++))
else
    print_status "INFO" "Consider enabling zram swap for better performance"
fi

# Summary
echo ""
echo "📊 Validation Summary"
echo "===================="

total_files=$(find . -name "*.nix" | wc -l)
print_status "INFO" "Total .nix files: $total_files"
print_status "INFO" "Security features enabled: $security_checks/3"
print_status "INFO" "Performance features enabled: $perf_checks/2"

if [[ ${#inconsistent_files[@]} -eq 0 && $security_checks -ge 2 && $perf_checks -ge 1 ]]; then
    echo ""
    print_status "OK" "Configuration looks good! 🎉"
    exit 0
else
    echo ""
    print_status "WARN" "Configuration has room for improvement. Check warnings above."
    exit 1
fi