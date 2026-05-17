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

3. Tag the release:

   ```bash
   git tag -a v0.1.0 -m "v0.1.0"
   git push origin v0.1.0
   ```

4. Create GitHub release notes covering:

   - install path
   - configuration changes
   - behavior changes
   - known compatibility notes for Codex Desktop log schema
