#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME}"
BIN_DIR="$PREFIX/bin"
CONFIG_DIR="$HOME/.config/codex-discord-notifier"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_USER_DIR" "$HOME/.local/state/codex-discord-notifier"

install -m 0755 bin/codex-discord-notifier "$BIN_DIR/codex-discord-notifier"
install -m 0644 systemd/codex-discord-notifier.service "$SYSTEMD_USER_DIR/codex-discord-notifier.service"

if [ ! -f "$CONFIG_DIR/env" ]; then
  install -m 0600 env.example "$CONFIG_DIR/env"
fi

echo "Installed Codex Discord Notifier."
echo
echo "Next steps:"
echo "  1. Edit $CONFIG_DIR/env"
echo "  2. Paste your Discord webhook URL into DISCORD_WEBHOOK_URL"
echo "  3. Run: systemctl --user daemon-reload"
echo "  4. Run: systemctl --user enable --now codex-discord-notifier.service"

