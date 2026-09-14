# NOW

- No known blocking Web gameplay bug remains in the tested scope. Investigate any new report with a reproduction before adding content.

# NEXT

- Complete refresh/reopen verification on release c7fa17a690861329 after reward, training, equipment and settings changes; the previous run stopped before final reload.

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
