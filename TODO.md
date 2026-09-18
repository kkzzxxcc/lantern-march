# NOW

- 2026-09-18: Web re-export completed from a2d93b8 with Godot 4.6 stable; local release 0d67ff167e3ab7dd. PWA regressions 6/6 and actual-output HTTP/byte checks 16/16 passed. No browser QA or deployment. Evidence: review_artifacts/web_export_2026-09-18.md.

- 2026-09-16: PWA release hashing, registration-scoped cache cleanup and active-release navigation fixed; Node regression tests 6/6 passed. Web re-export completed 2026-09-18 (see 2026-09-18 entry); browser lifecycle QA remains pending. Evidence: review_artifacts/web_pwa_2026-09-16.md.

- No known blocking Web gameplay bug remains in the tested scope. Investigate any new report with a reproduction before adding content.

# NEXT

- Complete refresh/reopen verification on current release 0d67ff167e3ab7dd after reward, training, equipment and settings changes. Historical c7fa17a690861329 observations stopped before final reload and do not verify this new build.

- Actual phone-browser multi-touch, notch safe-area and lifecycle tests.
- PWA install/update lifecycle on HTTPS and browser restart after saving; preserve hashed asset consistency.
- Audible BGM/SFX and volume/mute listening check; sustained Chrome render-FPS profiling with50 entities.
- Human Stage1–10 balance sessions including single-unit strategy comparisons.

# LATER

- Android APK and device verification.
- iOS native export and device verification; TestFlight.

# OPTIONAL

- Art and sound upgrades, additional content, localization.
- Cloud save only with explicit scope/credentials; preserve local migration.


# OpenClaw Migration Checkpoint — 2026-09-14

Migration checkpoint: 2026-09-14. This pass preserves existing gameplay code, tests and Web release; no new feature or native-platform work. Latest recorded automated run:24 actual cases /237 assertions /0 failures. Tests were not rerun for documentation-only migration. Latest Web release:c7fa17a690861329. Previous lantern_march_review.zip predates the latest Web milestone; this migration ZIP is the authoritative source snapshot. Final Git/bundle and archive results: review_artifacts/migration_git.txt and migration_validation.txt.

Latest Chrome observation (port8062): actual Stage1 victory,130gold reward, Stage2 unlock, CinderLv2 training(310→210gold), Sunspike equip and settings changes. Final refresh/reopen after all those changes was interrupted and is NOT VERIFIED on this release. Earlier port8061 refresh evidence applies to the earlier build. Do not claim final Web-save lifecycle complete. Actual mobile devices, audible listening, PWA installation/update lifecycle and sustained browser rendering FPS remain NOT TESTED.
