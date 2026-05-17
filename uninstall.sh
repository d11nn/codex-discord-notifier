#!/usr/bin/env bash
set -euo pipefail

systemctl --user disable --now codex-discord-notifier.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/codex-discord-notifier.service"
rm -f "$HOME/bin/codex-discord-notifier"
systemctl --user daemon-reload 2>/dev/null || true

echo "Removed Codex Discord Notifier binary and systemd user service."
echo "Config and state are preserved under ~/.config/codex-discord-notifier and ~/.local/state/codex-discord-notifier."
