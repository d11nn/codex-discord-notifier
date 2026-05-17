# Release Checklist

1. Run local checks:

   ```bash
   make test
   make smoke
   ```

2. Confirm no webhook URLs or local env files are tracked:

   ```bash
   git grep -n "discord.com/api/webhooks" -- ':!env.example'
   ```

3. Merge to `main` with Conventional Commits.

   CI creates the next semantic version tag automatically after tests pass:

   - `feat:` creates a minor release.
   - `fix:`, `docs:`, `ci:`, `test:`, `refactor:`, and `chore:` create a patch release.
   - `!` or `BREAKING CHANGE:` creates a major release.

4. Create GitHub release notes covering:

   - install path
   - configuration changes
   - behavior changes
   - known compatibility notes for Codex Desktop log schema
