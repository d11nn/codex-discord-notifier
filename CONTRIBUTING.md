# Contributing

Contributions are welcome.

Please keep the project focused:

- Linux user-level Codex notification workflows
- Discord webhook delivery
- low dependency footprint
- safe handling of secrets and mentions
- clear install and recovery paths

Before submitting changes:

```bash
make test
make smoke
```

Use Conventional Commits for commit messages:

- `feat: add a user-visible capability`
- `fix: correct broken behavior`
- `docs: update documentation`
- `ci: update automation`
- `chore: maintain repository metadata`

The CI workflow uses these messages to choose the next semantic version tag on `main`.

Do not add a runtime dependency unless it removes a real production risk.
