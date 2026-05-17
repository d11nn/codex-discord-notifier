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

require_python() {
  if command -v python3 >/dev/null 2>&1; then
    return
  fi

  echo "Error: python3 is required but was not found." >&2
  echo >&2
  echo "Install Python 3, then re-run ./install.sh:" >&2
  echo "  Debian/Ubuntu: sudo apt-get install python3" >&2
  echo "  Fedora:        sudo dnf install python3" >&2
  echo "  Arch:          sudo pacman -S python" >&2
  echo "  macOS:         xcode-select --install, or install Python from https://www.python.org/" >&2
  echo >&2
  echo "No pip packages are required. SQLite, HTTPS, JSON, and path handling use Python's standard library." >&2
  exit 1
}

install_common_files() {
  mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$STATE_DIR"
  install -m 0755 bin/codex-discord-notifier "$BIN_DIR/codex-discord-notifier"
  if [ ! -f "$CONFIG_DIR/env" ]; then
    install -m 0600 env.example "$CONFIG_DIR/env"
  fi
}

install_linux() {
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: Linux install requires systemd and systemctl." >&2
    echo "Manual install is still possible: run $BIN_DIR/codex-discord-notifier under your preferred supervisor." >&2
    exit 1
  fi

  mkdir -p "$SYSTEMD_USER_DIR"
  install -m 0644 systemd/$SERVICE_NAME "$SYSTEMD_USER_DIR/$SERVICE_NAME"

  systemctl --user daemon-reload
  systemctl --user enable --now "$SERVICE_NAME"
}

install_macos() {
  mkdir -p "$LAUNCHD_USER_DIR"
  sed "s#/Users/YOUR_USER#$HOME#g" "launchd/$PLIST_NAME" > "$LAUNCHD_USER_DIR/$PLIST_NAME"

  launchctl unload "$LAUNCHD_USER_DIR/$PLIST_NAME" >/dev/null 2>&1 || true
  launchctl load "$LAUNCHD_USER_DIR/$PLIST_NAME"
  launchctl start com.d11nn.codex-discord-notifier >/dev/null 2>&1 || true
}

print_next_steps() {
  local platform="$1"

  echo "Installed Codex Discord Notifier for $platform."
  echo
  echo "Configure Discord Webhook URL:"
  echo "  1. In Discord, open the target channel."
  echo "  2. Go to Edit Channel -> Integrations -> Webhooks."
  echo "  3. Create a webhook and copy its URL."
  echo "  4. Paste it into:"
  echo "       $CONFIG_DIR/env"
  echo
  echo "Example env:"
  echo "  DISCORD_WEBHOOK_URL=\"https://discord.com/api/webhooks/...\""
  echo "  CODEX_NOTIFY_MIN_SECONDS=3"
  echo "  CODEX_NOTIFY_POLL_SECONDS=2"
  echo "  CODEX_NOTIFY_HOST=\"$(hostname)\""
  echo "  CODEX_NOTIFY_MENTION=\"@here\""
  echo
  echo "Tip: Webhooks post to a channel, not a DM. Use a private channel if you want personal notifications."
  echo "Tip: The default @here mention is intended for a private channel. Set CODEX_NOTIFY_MENTION=\"\" to disable pings."
  echo
  echo "Test:"
  echo "  $BIN_DIR/codex-discord-notifier --send-test"

  if [ "$platform" = "Linux" ]; then
    echo
    echo "Status:"
    echo "  systemctl --user status $SERVICE_NAME"
    echo
    echo "Optional for SSH hosts:"
    echo "  loginctl enable-linger \"\$USER\""
  else
    echo
    echo "Status/logs:"
    echo "  launchctl list | grep com.d11nn.codex-discord-notifier"
    echo "  tail -f /tmp/codex-discord-notifier.out.log /tmp/codex-discord-notifier.err.log"
  fi
}

require_python
install_common_files

case "$(uname -s)" in
  Linux)
    install_linux
    print_next_steps "Linux"
    ;;
  Darwin)
    install_macos
    print_next_steps "macOS"
    ;;
  *)
    echo "Error: unsupported OS: $(uname -s)" >&2
    echo "Supported installers: Linux with systemd, macOS with launchd." >&2
    exit 1
    ;;
esac
