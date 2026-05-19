#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Development Environment Verification
# Checks everything is installed and working after NixOS rebuild.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

Info="\e[36m"; Success="\e[32m"; Warning="\e[33m"; Error="\e[31m"; Reset="\e[0m"

echo -e "${Info}╔══════════════════════════════════════════════════════╗${Reset}"
echo -e "${Info}║     Dev Environment Verification                     ║${Reset}"
echo -e "${Info}╚══════════════════════════════════════════════════════╝${Reset}"
echo ""

# ─── 1. Verify all Nix-installed tools ───────────────────────────────────────
echo -e "${Info}◆ Verifying installed tools...${Reset}"

TOOLS=(
  "pi:pi --version"
  "node:node --version"
  "bun:bun --version"
  "go:go version"
  "python3:python3 --version"
  "uv:uv --version"
  "git:git --version"
  "bat:bat --version"
  "eza:eza --version"
  "fd:fd --version"
  "just:just --version"
  "yq:yq --version"
  "httpie:http --version"
  "btop:btop --version"
  "tmux:tmux -V"
  "delta:delta --version"
  "dog:dog --version"
  "duf:duf --version"
  "dust:dust --version"
  "procs:procs --version"
  "fastfetch:fastfetch --version"
  "opencode:opencode --version"
)

FAILED=0
for tool in "${TOOLS[@]}"; do
  name="${tool%%:*}"
  cmd="${tool##*:}"
  if command -v "${cmd%% *}" &>/dev/null; then
    echo -e "  ${Success}✓${Reset} $name"
  else
    echo -e "  ${Warning}⚠${Reset} $name (not found)"
    FAILED=$((FAILED + 1))
  fi
done

if [ $FAILED -gt 0 ]; then
  echo ""
  echo -e "${Warning}  $FAILED tool(s) missing. Run: sudo nixos-rebuild switch --flake ~/nixos${Reset}"
fi

# ─── 2. Verify Ollama passthrough (WSL only) ─────────────────────────────────
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo -e "${Info}◆ Checking Ollama passthrough to Windows...${Reset}"
  if [ -n "$OLLAMA_HOST" ]; then
    echo -e "  ${Success}✓${Reset} OLLAMA_HOST=$OLLAMA_HOST"
    if curl -s "$OLLAMA_HOST/api/tags" &>/dev/null; then
      echo -e "  ${Success}✓${Reset} Ollama reachable (Ollama Cloud on Windows)"
    else
      echo -e "  ${Warning}⚠${Reset} Ollama not reachable — is Ollama Cloud running on Windows?"
      echo "    Run in PowerShell: [System.Environment]::SetEnvironmentVariable('OLLAMA_HOST','0.0.0.0','User')"
      echo "    Then restart Ollama"
    fi
  else
    echo -e "  ${Warning}⚠${Reset} OLLAMA_HOST not set — restart shell or check ~/nixos/home.nix"
  fi
fi

# ─── 3. Verify Docker ────────────────────────────────────────────────────────
echo ""
echo -e "${Info}◆ Checking Docker...${Reset}"
if docker info &>/dev/null; then
  echo -e "  ${Success}✓${Reset} Docker is running"
else
  echo -e "  ${Warning}⚠${Reset} Docker not running — start with: sudo systemctl start docker"
fi

# ─── 4. Summary ──────────────────────────────────────────────────────────────
echo ""
echo -e "${Success}╔══════════════════════════════════════════════════════╗${Reset}"
echo -e "${Success}║     Dev Environment Ready!                           ║${Reset}"
echo -e "${Success}╚══════════════════════════════════════════════════════╝${Reset}"
echo ""
echo -e "  ${Info}Quick start:${Reset}"
echo "  ─────────────────────────────────────────────"
echo "  pi              ${Info}Start the pi coding agent${Reset}"
echo "  aider           ${Info}AI pair programming${Reset}"
echo "  just            ${Info}Run project commands${Reset}"
echo "  bat, eza, fd    ${Info}Enhanced CLI tools${Reset}"
echo "  http            ${Info}Human-friendly HTTP client${Reset}"
echo "  btop            ${Info}System monitor${Reset}"
echo ""
echo -e "  ${Info}Rebuild after config changes:${Reset}"
echo "  sudo nixos-rebuild switch --flake ~/nixos#wsl"
echo ""
