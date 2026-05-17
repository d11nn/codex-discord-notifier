# Codex Discord Notifier

Get a Discord notification when a local Codex turn finishes or when Codex is waiting for your answer.

This is for the common failure mode where Codex is doing real work in another window, finishes, asks a question, or waits for confirmation, and you miss it.

It is especially useful for remote Codex workflows. Codex Mobile and Codex Desktop can connect to a remote VM through Application Connection, but work that finishes on the remote VM does not necessarily trigger a local desktop/mobile notification. The same gap exists when you run Codex CLI directly on a remote VM. This notifier runs beside Codex on that machine and sends Discord notifications when the remote work needs your attention.

## What It Does

Codex Discord Notifier runs as a small user-level daemon on the same machine as Codex. It watches Codex's local SQLite/log state and sends a Discord webhook message when:

- a Codex turn runs longer than `CODEX_NOTIFY_MIN_SECONDS` and completes
- Codex asks a question or appears to be waiting for user input
- a Codex agent job reaches a terminal state

It deliberately ignores internal Codex approval/reviewer subagents such as `codex-auto-review`, so Discord does not get spammed by background policy checks.

## Why Webhooks

Discord webhooks are the right primitive for this project:

- no bot token
- no Gateway connection
- no privileged intents
- no OAuth install flow
- one HTTPS `POST` per notification

Webhooks post into a Discord channel. They do not send direct messages. If you want private notifications, create a private channel or a personal Discord server, then create the webhook there.

## Requirements

- Codex Desktop or Codex CLI state under `~/.codex`
- Python 3
- outbound HTTPS access to Discord's webhook API

No `pip install` step is required. The daemon uses only Python standard library modules, including `sqlite3`, `urllib`, `json`, `pathlib`, and `socket`.

## Quick Start

Clone and install:

```bash
git clone https://github.com/d11nn/codex-discord-notifier.git
cd codex-discord-notifier
./install.sh
```

The installer detects your OS:

- Linux: installs a systemd user service.
- macOS: installs a launchd LaunchAgent.

Create a Discord webhook:

1. Open Discord desktop or web.
2. Pick the server and channel that should receive Codex notifications.
3. Open `Edit Channel`.
4. Go to `Integrations`.
5. Open `Webhooks`.
6. Create a webhook named `Codex Finish Notifier`.
7. Copy the webhook URL.

Paste the webhook URL into the env file:

```bash
nano ~/.config/codex-discord-notifier/env
```

Set:

```bash
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
CODEX_NOTIFY_MIN_SECONDS=3
CODEX_NOTIFY_POLL_SECONDS=2
CODEX_NOTIFY_HOST="VM1"
CODEX_NOTIFY_MENTION="@here"
```

Send a test notification:

```bash
codex-discord-notifier --send-test
```

### Linux

Linux uses a systemd user service.

Check status:

```bash
systemctl --user status codex-discord-notifier.service
```

If you want the user service to keep running after SSH logout:

```bash
loginctl enable-linger "$USER"
```

### macOS

macOS uses a launchd LaunchAgent.

If `python3` is not available, install it first:

```bash
xcode-select --install
```

If that does not provide Python 3 on your macOS version, install Python from [python.org](https://www.python.org/downloads/macos/).

Check status:

```bash
launchctl list | grep com.d11nn.codex-discord-notifier
```

View logs:

```bash
tail -f /tmp/codex-discord-notifier.out.log /tmp/codex-discord-notifier.err.log
```

If your Codex directory is not `~/.codex`, set it explicitly in `~/.config/codex-discord-notifier/env`:

```bash
CODEX_NOTIFY_CODEX_DIR="$HOME/.codex"
```

### Uninstall

```bash
./uninstall.sh
```

### Windows

Windows is not yet a verified target. The Python daemon itself is portable, but production support still needs validation for:

- Codex Desktop's Windows state directory layout
- service installation strategy, such as Task Scheduler or NSSM
- path handling for rollout JSONL files

Pull requests for Windows support are welcome, but the current documented production paths are Linux and macOS.

## Test It

Send two synthetic test notifications:

```bash
codex-discord-notifier --send-test
```

Preview the payload without touching Discord:

```bash
codex-discord-notifier --send-test --dry-run
```

Run one polling pass without sending Discord messages:

```bash
codex-discord-notifier --once --dry-run
```

Initialize state to the current Codex log position:

```bash
codex-discord-notifier --init-state
```

This prevents old events from being sent after a fresh install.

## Configuration

The notifier reads:

```bash
~/.config/codex-discord-notifier/env
```

Supported settings:

| Variable | Default | Meaning |
| --- | --- | --- |
| `DISCORD_WEBHOOK_URL` | required | Discord channel webhook URL. Treat it as a secret. |
| `CODEX_NOTIFY_MIN_SECONDS` | `3` | Notify completed turns/jobs that ran at least this long. |
| `CODEX_NOTIFY_POLL_SECONDS` | `2` | Poll interval for local Codex SQLite/log state. |
| `CODEX_NOTIFY_HOST` | hostname | Display name in Discord notification fields. |
| `CODEX_NOTIFY_MENTION` | `@here` | Plain message mention. Use `@here` in a private channel, `<@USER_ID>` for one user, `<@&ROLE_ID>` for a role, or empty string to disable pings. |
| `CODEX_NOTIFY_CODEX_DIR` | `~/.codex` | Codex state directory. |
| `CODEX_NOTIFY_STATE_PATH` | `~/.local/state/codex-discord-notifier/state.json` | Notifier state file. |
| `CODEX_NOTIFY_DRY_RUN` | unset | Set to `1` to print payloads instead of sending. |

## Notification Semantics

The daemon sends two main notification classes.

### Completed Turn

Sent as `Codex job finished`.

This fires when a user-facing Codex turn completes and ran for at least `CODEX_NOTIFY_MIN_SECONDS`.

### Waiting For User

Sent as `Codex is waiting for you`.

This fires when the final assistant message looks like it needs your input. Examples include messages containing:

- `?`
- `please provide`
- `please confirm`
- `do you want`
- `Question:`

Waiting notifications bypass the duration threshold because even a short question can leave Codex blocked until you answer.

## How It Works

Codex stores local state under `~/.codex`. This daemon reads:

- `~/.codex/logs_2.sqlite`
- `~/.codex/state_5.sqlite`
- rollout JSONL paths referenced by Codex thread metadata

It tracks the last processed log id in:

```bash
~/.local/state/codex-discord-notifier/state.json
```

Polling is safe because the daemon processes durable log rows using `id > last_log_id`. A 2-second poll interval does not miss events; if an event is written to SQLite, a later poll can still read it.

The daemon also records its startup time and ignores Codex turns that started before the daemon started. This prevents service restarts from sending notifications for half-finished old turns.

## Security

Treat your Discord webhook URL as a credential.

Do:

- store it only in `~/.config/codex-discord-notifier/env`
- keep that env file mode private
- use a private Discord channel if your Codex work may include sensitive repo names or paths

Do not:

- commit your webhook URL
- paste the webhook URL into public issues or PRs
- include full Codex output in Discord notifications

The notifier sends `CODEX_NOTIFY_MENTION` in the plain message content. By default this is `@here`, which works well when the webhook posts into a private channel that only you use.

Discord webhooks cannot automatically mention the webhook creator. If you need an exact user mention instead of `@here`, set `CODEX_NOTIFY_MENTION="<@USER_ID>"`.

The notifier also sets `allowed_mentions` narrowly. Assistant text inside the embed cannot create surprise pings.

When `CODEX_NOTIFY_MENTION="@here"`, the payload uses:

```json
{"content": "@here", "allowed_mentions": {"parse": ["everyone"]}}
```

Set `CODEX_NOTIFY_MENTION=""` to disable all pings:

```json
{"allowed_mentions": {"parse": []}}
```

## Operations

View Linux status:

```bash
systemctl --user status codex-discord-notifier.service
```

View Linux logs:

```bash
journalctl --user -u codex-discord-notifier.service -f
```

Restart Linux service after editing config:

```bash
systemctl --user restart codex-discord-notifier.service
```

View macOS status:

```bash
launchctl list | grep com.d11nn.codex-discord-notifier
```

View macOS logs:

```bash
tail -f /tmp/codex-discord-notifier.out.log /tmp/codex-discord-notifier.err.log
```

Restart macOS agent after editing config:

```bash
launchctl unload ~/Library/LaunchAgents/com.d11nn.codex-discord-notifier.plist
launchctl load ~/Library/LaunchAgents/com.d11nn.codex-discord-notifier.plist
launchctl start com.d11nn.codex-discord-notifier
```

Uninstall the binary and service:

```bash
./uninstall.sh
```

The uninstall script preserves config and state so you do not lose your webhook or deduplication history.

## Production Notes

This project is intentionally dependency-free: it uses Python 3 standard library modules only.

Production behavior built in:

- read-only SQLite access
- durable deduplication with a local state file
- service restart guard for half-finished turns
- exclusion for internal Codex reviewer/subagent threads
- Discord mention suppression
- webhook retry on transient network failure/rate limit
- dry-run and test modes

## License

Apache License 2.0. See [LICENSE](LICENSE).
