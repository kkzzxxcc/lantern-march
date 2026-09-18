# Current continuation — 2026-09-18

Web re-export completed: local build/web release 0d67ff167e3ab7dd from a2d93b8, Godot 4.6 stable single-thread release. Existing PWA regressions 6/6 and generated-output HTTP/byte checks 16/16 passed. No browser/gameplay test or public deployment. Build output is Git-ignored and exists only in this checkout; see review_artifacts/web_export_2026-09-18.md for commands and fingerprints. NEXT remains browser refresh/reopen persistence QA on this new release; browser access is prohibited by current channel policy. Core architecture unchanged; no native work.

# Current continuation — 2026-09-16

Canonical Git remote is now origin https://github.com/kkzzxxcc/lantern-march.git; original nyamNyamm2 remote is upstream. Earlier no-remote/build-included statements below describe the Windows migration ZIP, not this Git checkout.

PWA finalizer now hashes all fresh index assets plus HTML/manifest and worker-policy version, namespaces caches by registration scope, and serves the active release shell during updates. Legacy unscoped caches are preserved to avoid deleting another deployment's cache. Run `node --test tools/web-release.test.mjs`: 6/6 Node fixture/VM tests passed, not browser or gameplay tests. No new Web export or public URL. See review_artifacts/web_pwa_2026-09-16.md. Browser QA remains first priority; no native work.

# Project Goal

Continue Lantern March / 등불의 전선, a playable original lane-battle game. Do not recreate the project. This repository is sufficient; no Codex conversation or private tool cache is required.

# Current Architecture

Boot routes seven scenes. Data, Save, Audio are the only autoloads. BattleManager orchestrates production physics; UnitBase/HeroController/BossUnit implement actors; registry uses x-axis spatial buckets, projectiles use64 preallocated slots. JSON is authoritative. Programmatic UI avoids duplicating keyboard and touch logic.

# Engine / Version

Godot4.6 stable (89cea1439), GDScript, GL Compatibility. No C#, no third-party plugins. Node.js20+ for Web launcher and template tools. Windows PowerShell5.1+ for scripts.

# Current Milestone

Web-first MVP. Android/iOS: Deferred - intentionally not part of current Web milestone. Two outputs: playable Web ZIP and full review/handoff ZIP. No authenticated Git remote/hosting configured.

# Completed Features

Hero movement/aura, six allies, eight enemies, two bosses, three skills, ten equipment pieces, ten stages, rewards/upgrades/equipment/settings/local saves, touch InputMap, Main Scene E2E, Web release. Save mutation rollback and rear support positioning were fixed in this milestone.

# Deferred Features

Android SDK/APK/device tests; macOS/Xcode/iOS/TestFlight. Cloud accounts, purchases, multiplayer outside current scope.

# Known Issues

No observed unresolved critical/major gameplay error. Actual phone safe-area/multitouch, audible listening, PWA install/update lifecycle and sustained browser render FPS remain verification gaps. Placeholder art/audio are intentional. Windows certificate-store diagnostic is an environment exception in logs. Browser IndexedDB flush is async: do not claim FileAccess success guarantees survival of instant process termination. Public hosting not configured.

# Important Design Decisions

See DECISIONS.md. Shared GDScript/InputMap preserves future mobile portability. Single-thread Web avoids COOP/COEP hosting requirements. Content-hashed Web assets prevent mixed update versions. Save transactions rollback rather than falsely confirming permanent purchases/rewards. Rear support movement is independent of whether a target currently needs healing.

# Core File Locations

systems/battle_manager.gd; core/unit/unit_base.gd; core/hero/hero_controller.gd; core/aura/hero_aura.gd; core/combat/combat_registry.gd; core/combat/projectile_pool.gd; systems/save_manager.gd; ui/action_button.gd; data/. Exact functions and test mapping: PROJECT_AUDIT.md and review_artifacts/function_index.md.

# How To Run

Windows: double-click PLAY_LANTERN_MARCH.bat (Node20+). It serves build/web at http://127.0.0.1:8060/ and opens a browser. Do not open HTML through file://. Keep server window open; Enter stops it. Or open project.godot with Godot4.6 and press F5. Controls A/D/arrows,1–6,J/K/L,Escape; touch buttons use same actions.

# How To Test

powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Godot <absolute executable>

24 actual cases /237 assertions; failed0 in final recorded run. Case counts do not count repeated assertions, stage iterations or separate reload process twice. tests/runtime_e2e.gd loads configured Main Scene and automatic physics. -- boss runs stages5/10 with a disclosed progression entry fixture. Focused tests manually step the production simulation and must not be called runtime E2E. Test APPDATA lives under .tools/userdata, not the user's normal save directory. Evidence: review_artifacts/logs. Browser observation: browser_test.txt.

# How To Build Web

powershell -ExecutionPolicy Bypass -File tools/export-web.ps1 -Godot <absolute executable>

Downloads official4.6 threadless templates into .tools/templates via Node when absent. Finalizer hashes assets and emits PWA metadata/cache. Do not run finalizer on an already-finalized build without first exporting anew. Publish complete build/web atomically; keep previous hashed assets for existing clients. Source review packaging: tools/package-review.ps1. Play ZIP packaging: tools/package-web.ps1. ZIPs must have '/' entry paths, no backslash.

# Save Architecture

SaveManager API is platform independent. v1 JSON user://progress.json. Temp/flush/backup/rename; malformed state sanitization/v0 migration/future-version refusal. _commit restores snapshot when saving fails. reward_stage returns saved boolean; failed reward UI permits retry. Web uses Godot IndexedDB, scoped by browser origin. Changing port/domain or clearing site data changes/removes saves. Browser refresh/reopen proof must be separate from file-unit tests.

# Input Architecture

ActionButton tracks touch IDs, dispatches InputEventAction, releases on outside release/focus loss/exit. Keyboard and touch converge in InputMap/Battle input; no desktop-only combat code. UI callbacks are deferred to avoid removing scenes during input traversal.

# Web-specific Code

platform/web/web_adapter.gd: safe-area CSS bridge only. tools/finalize-web.mjs: viewport/manifest/service worker/content hashes. tools/serve.mjs and serve-web.ps1: local static server. Core combat has no Browser JavaScript. PWA installation is prepared, not certified on all devices.

# Mobile Compatibility Rules

Keep GDScript/InputMap/landscape, common Save API and platform-independent data. Isolate any future browser calls in platform/web. Do not add a Web-only dependency to Combat/Unit/Hero. Keep multitouch and safe-area behavior intact.

# Next Recommended Work

See TODO.md. Real-phone and PWA lifecycle QA before native milestones. Human balance sessions and art/audio polish next; do not add content before checking regressions.

# Do Not Break

Aura must not compound; attack rechecks alive/range; pool saturation must never deal instant damage; failed saves must not commit upgrades/rewards; support must not march through opposing lines. Preserve all six playable units, stage unlock/save v1 migration, release debug gating, hashed Web asset consistency and actual Main Scene tests.

Git had no commits, author identity or remote at migration start. The migration checkpoint uses an explicitly agent-authored identity supplied only to this Git command, without changing global configuration. Bundle restoration commands are in OPENCLAW_MIGRATION.md. Source remains usable by direct copy even without Git.


# OpenClaw Migration Checkpoint — 2026-09-14

Migration checkpoint: 2026-09-14. This pass preserves existing gameplay code, tests and Web release; no new feature or native-platform work. Latest recorded automated run:24 actual cases /237 assertions /0 failures. Tests were not rerun for documentation-only migration. Latest Web release:c7fa17a690861329. Previous lantern_march_review.zip predates the latest Web milestone; this migration ZIP is the authoritative source snapshot. Final Git/bundle and archive results: review_artifacts/migration_git.txt and migration_validation.txt.

Latest Chrome observation (port8062): actual Stage1 victory,130gold reward, Stage2 unlock, CinderLv2 training(310→210gold), Sunspike equip and settings changes. Final refresh/reopen after all those changes was interrupted and is NOT VERIFIED on this release. Earlier port8061 refresh evidence applies to the earlier build. Do not claim final Web-save lifecycle complete. Actual mobile devices, audible listening, PWA installation/update lifecycle and sustained browser rendering FPS remain NOT TESTED.
