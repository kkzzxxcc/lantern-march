# Agent onboarding — Lantern March

Before starting work, read these files in this exact order:

1. HANDOFF.md
2. DECISIONS.md
3. TODO.md
4. PROJECT_AUDIT.md
5. README_FOR_REVIEW.md

Then read OPENCLAW_MIGRATION.md for snapshot restoration and actual verification status.

## Required working principles

- Do not recreate this project from scratch. Continue the existing Lantern March repository.
- Preserve the existing architecture and shared Godot4.6/GDScript codebase.
- Maintain the Web-first milestone.
- Android/iOS Native are currently deferred; do not start native work without an explicit scope change.
- Understand existing tests before changing implementation. Distinguish assertions, fixture/integration cases and automatic-physics Main Scene E2E.
- After a functional change, run the relevant regression tests. Do not relabel unexecuted tests as passing.
- At the end of each completed work unit, leave a Git commit. Do not modify global Git identity. If Git is unavailable or blocked, preserve changes and document the limitation.
- Never report an unimplemented feature or unverified platform as completed.
- Preserve InputMap/touch, save rollback, aura non-compounding, projectile-pool lifecycle and rear support positioning. Browser JavaScript stays in platform/web and Web tooling, outside combat.
- Keep secrets, credentials, personal saves and generated internal caches out of Git and migration packages.
