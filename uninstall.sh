#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME}"
BIN_DIR="$PREFIX/bin"
CONFIG_DIR="$HOME/.config/codex-discord-notifier"
STATE_DIR="$HOME/.local/state/codex-discord-notifier"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
LAUNCHD_USER_DIR="$HOME/Library/LaunchAgents"
SERVICE_NAME="codex-discord-notifier.service"
PLIST_NAME="com.d11nn.codex-discord-notifier.plist"

uninstall_linux() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$SYSTEMD_USER_DIR/$SERVICE_NAME"
    systemctl --user daemon-reload 2>/dev/null || true
  else
    rm -f "$SYSTEMD_USER_DIR/$SERVICE_NAME"
  fi
}

uninstall_macos() {
  if command -v launchctl >/dev/null 2>&1; then
    launchctl unload "$LAUNCHD_USER_DIR/$PLIST_NAME" >/dev/null 2>&1 || true
  fi
  rm -f "$LAUNCHD_USER_DIR/$PLIST_NAME"
}

case "$(uname -s)" in
  Linux)
    uninstall_linux
    platform="Linux"
    ;;
  Darwin)
    uninstall_macos
    platform="macOS"
    ;;
  *)
    echo "Error: unsupported OS: $(uname -s)" >&2
    echo "Supported uninstallers: Linux with systemd, macOS with launchd." >&2
    exit 1
    ;;
esac

rm -f "$BIN_DIR/codex-discord-notifier"

echo "Removed Codex Discord Notifier binary and $platform service."
echo "Config and state are preserved:"
echo "  $CONFIG_DIR"
echo "  $STATE_DIR"
