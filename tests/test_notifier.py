#!/usr/bin/env python3
import json
import pathlib
import runpy
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
notifier = runpy.run_path(str(ROOT / "bin/codex-discord-notifier"))


def test_uuid7_ms():
    value = "019e372f-9041-72e2-96f6-ece09d4157af"
    assert notifier["uuid7_ms"](value) == int("019e372f9041", 16)


def test_startup_guard_uses_completion_time():
    assert notifier["completed_before_startup"](1_000, 2_000)
    assert not notifier["completed_before_startup"](2_000, 2_000)
    assert not notifier["completed_before_startup"](3_000, 2_000)
    assert not notifier["completed_before_startup"](1_000, None)


def test_stale_turn_event():
    latest = {"thread-a": (20, "turn-new")}
    assert notifier["stale_turn_event"](10, "thread-a", "turn-old", latest)
    assert not notifier["stale_turn_event"](20, "thread-a", "turn-new", latest)
    assert not notifier["stale_turn_event"](10, "thread-b", "turn-old", latest)
    assert not notifier["stale_turn_event"](10, "thread-a", None, latest)


def test_waiting_detection():
    assert notifier["looks_waiting_for_user"]("Please confirm: did you receive the notification?")
    assert notifier["looks_waiting_for_user"]("Question: choose one.")
    assert not notifier["looks_waiting_for_user"]("Deployment completed successfully.")


def test_rollout_task_complete_is_turn_scoped():
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as f:
        path = pathlib.Path(f.name)
        f.write(
            json.dumps(
                {
                    "type": "event_msg",
                    "payload": {
                        "type": "task_complete",
                        "turn_id": "turn-a",
                        "last_agent_message": "old message?",
                    },
                }
            )
            + "\n"
        )
        f.write(
            json.dumps(
                {
                    "type": "event_msg",
                    "payload": {
                        "type": "task_complete",
                        "turn_id": "turn-b",
                        "last_agent_message": "current message?",
                    },
                }
            )
            + "\n"
        )

    try:
        assert notifier["final_message_from_rollout"](str(path), "turn-a") == "old message?"
        assert notifier["final_message_from_rollout"](str(path), "turn-b") == "current message?"
        assert notifier["final_message_from_rollout"](str(path), "missing") == ""
    finally:
        path.unlink(missing_ok=True)


def test_payload_disables_mentions():
    payload = notifier["build_payload"](
        {
            "kind": "turn_waiting",
            "status": "waiting_for_user",
            "thread_id": "thread",
            "turn_id": "turn",
            "title": "test",
            "cwd": "/tmp",
            "model": "test",
            "duration_seconds": 3,
            "finished_at": 1,
            "assistant_excerpt": "@everyone should not ping",
        },
        "host",
    )
    assert payload["allowed_mentions"] == {"parse": []}
    assert payload["embeds"][0]["title"] == "Codex is waiting for you"


if __name__ == "__main__":
    test_uuid7_ms()
    test_waiting_detection()
    test_rollout_task_complete_is_turn_scoped()
    test_payload_disables_mentions()
    print("tests passed")
