# Codex Discord Notifier

Get a Discord notification when a local Codex turn finishes or when Codex is waiting for your answer.

This is for the common failure mode where Codex is doing real work in another window, finishes, asks a question, or waits for confirmation, and you miss it.

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

## Quick Start

Clone and install:

```bash
git clone https://github.com/d11nn/codex-discord-notifier.git
cd codex-discord-notifier
./install.sh
```

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
```

Start the notifier:

```bash
systemctl --user daemon-reload
systemctl --user enable --now codex-discord-notifier.service
systemctl --user status codex-discord-notifier.service
```

If you want the user service to keep running after SSH logout:

```bash
loginctl enable-linger "$USER"
```

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
- `？`
- `請提供`
- `請確認`
- `是否允許`
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

The notifier sets:

```json
{"allowed_mentions": {"parse": []}}
```

This prevents accidental `@everyone` or user mention pings from assistant text.

## Operations

View status:

```bash
systemctl --user status codex-discord-notifier.service
```

View logs:

```bash
journalctl --user -u codex-discord-notifier.service -f
```

Restart after editing config:

```bash
systemctl --user restart codex-discord-notifier.service
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

