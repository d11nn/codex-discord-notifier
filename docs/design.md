# Design Notes

Codex Discord Notifier watches durable local Codex state instead of trying to hook terminal output.

## Data Sources

- `~/.codex/logs_2.sqlite`: response completion and websocket event logs
- `~/.codex/state_5.sqlite`: thread metadata, agent jobs, rollout paths
- rollout JSONL: turn-scoped `task_complete.last_agent_message`

## Why Polling Is Safe

Polling reads persistent SQLite rows using `id > last_log_id`. If the daemon polls every two seconds, it does not miss an event just because the event happened between polls.

## Turn Completion

A user-visible turn is considered notifyable when:

1. a `response.completed` event exists
2. the thread is not an internal Codex reviewer/subagent
3. the turn started after daemon startup
4. the turn is over the minimum duration or the final message appears to wait for user input

## Rollout Fallback

When websocket final-message ordering is inconsistent, the daemon reads the thread rollout JSONL and uses the same `turn_id` to find `task_complete.last_agent_message`.

It must not simply use the thread's latest final message, because long threads can otherwise attach an old final answer to a newer completion event.

