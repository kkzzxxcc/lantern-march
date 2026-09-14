# Technical Decisions

- Godot4.6 stable + GDScript, Compatibility renderer: one shared codebase, WebGL2 deployment, future native exports.
- Web first; Android/iOS native deferred deliberately. Do not install native SDKs for this milestone.
- Single-thread Web; no COOP/COEP requirement, no server/backend accounts.
- JSON-driven units/stages/skills/equipment; do not fork data by platform.
- InputMap unifies keyboard/mouse/touch actions; retain multi-touch IDs.
- Platform-independent SaveManager with v1 local JSON and rollback on failed mutations. IndexedDB uses engine synchronization; no fake synchronous browser durability claim.
- Support formation stays simple: nearby frontline rear anchor and opposing-front boundary, shared across teams.
- Web JavaScript isolated in platform/web adapter and build scripts.
- Version-hashed Web asset URLs and atomic service-worker cache install; no forced activation that interrupts existing sessions.
- Original procedural art and generated WAVs remain MVP assets; no copied game IP.
- Local launcher uses Node20+ and Windows PowerShell, binds127.0.0.1 only.
- Tests distinguish assertion count, fixture/integration and actual automatic-physics Main Scene E2E. Do not inflate counts.


# OpenClaw Migration Checkpoint — 2026-09-14

Migration checkpoint: 2026-09-14. This pass preserves existing gameplay code, tests and Web release; no new feature or native-platform work. Latest recorded automated run:24 actual cases /237 assertions /0 failures. Tests were not rerun for documentation-only migration. Latest Web release:c7fa17a690861329. Previous lantern_march_review.zip predates the latest Web milestone; this migration ZIP is the authoritative source snapshot. Final Git/bundle and archive results: review_artifacts/migration_git.txt and migration_validation.txt.

Latest Chrome observation (port8062): actual Stage1 victory,130gold reward, Stage2 unlock, CinderLv2 training(310→210gold), Sunspike equip and settings changes. Final refresh/reopen after all those changes was interrupted and is NOT VERIFIED on this release. Earlier port8061 refresh evidence applies to the earlier build. Do not claim final Web-save lifecycle complete. Actual mobile devices, audible listening, PWA installation/update lifecycle and sustained browser rendering FPS remain NOT TESTED.
