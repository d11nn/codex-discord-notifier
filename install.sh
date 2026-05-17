#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME}"
BIN_DIR="$PREFIX/bin"
CONFIG_DIR="$HOME/.config/codex-discord-notifier"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

if ! command -v python3 >/dev/null 2>&1; then
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
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_USER_DIR" "$HOME/.local/state/codex-discord-notifier"

install -m 0755 bin/codex-discord-notifier "$BIN_DIR/codex-discord-notifier"
install -m 0644 systemd/codex-discord-notifier.service "$SYSTEMD_USER_DIR/codex-discord-notifier.service"

if [ ! -f "$CONFIG_DIR/env" ]; then
  install -m 0600 env.example "$CONFIG_DIR/env"
fi

echo "Installed Codex Discord Notifier."
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
echo
echo "Tip: Webhooks post to a channel, not a DM. Use a private channel if you want personal notifications."
echo
echo "Next steps:"
echo "  1. Edit $CONFIG_DIR/env"
echo "  2. Run: systemctl --user daemon-reload"
echo "  3. Run: systemctl --user enable --now codex-discord-notifier.service"
echo "  4. Test: $BIN_DIR/codex-discord-notifier --send-test"
