# Called as lucid by the NixOS bootstrap unit after Home Manager activation.
set -euo pipefail
XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export T3CODE_HOME="$HOME/.t3"
export T3CODE_INSTALL_BIN_DIR="$HOME/.local/bin"

systemctl --user daemon-reload
if [[ ! -f "$HOME/.config/systemd/user/t3code.service" ]]; then
  # Install a T3-owned unit first. Its updater can then coordinate replacement
  # of both the runtime and the running service without writing to /nix/store.
  "$T3_BOOTSTRAP_CLI" service install
  mkdir -p "$HOME/.local/bin"
  if [[ ! -e "$HOME/.local/bin/t3" && ! -L "$HOME/.local/bin/t3" ]]; then
    ln -s "$T3CODE_HOME/runtime/versions/$T3_BOOTSTRAP_VERSION/t3" "$HOME/.local/bin/t3"
  fi
else
  systemctl --user restart t3code.service
fi
# Retry an interrupted first update even when service installation succeeded.
bootstrap_marker="$T3CODE_HOME/runtime/.nixos-service-bootstrapped"
if [[ ! -f "$bootstrap_marker" ]]; then
  "$T3_BOOTSTRAP_CLI" update --channel stable --yes
  touch "$bootstrap_marker"
fi
systemctl --user enable --now t3code.service
