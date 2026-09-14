# Lantern March — OpenClaw Migration

## Project root

Original Windows workspace: C:/Users/user/Documents/ChatGPT/Paladog. After extraction, the directory containing project.godot is the project root. Paths in source are portable res:// and user://; the original absolute path is not required.

## Godot version

Godot4.6.stable.official.89cea1439; GDScript, GL Compatibility, single-thread Web export. Node.js20+ for Web tooling/launcher and Windows PowerShell5.1+ for provided scripts. Engine binaries/templates and .tools cache are deliberately excluded. Rebuild downloads official templates when needed.

## Current milestone and implementation

Web-first MVP. Android/iOS Native deferred intentionally. Six companions, eight enemies, two bosses, three hero skills, five weapons/five rings, ten stages; hero/aura/combat/resources, growth/equipment/settings/local saves. Original procedural art and generated WAV placeholders. Latest release c7fa17a690861329 is included under build/web; source snapshot is authoritative, not older standalone review ZIPs.

## Current test state

Latest recorded run:24 actual cases,237 assertions,0 failures.11 focused integration cases,10 focused audit cases,1 Main Scene E2E(two processes),1 separate save probe(two processes),1 runtime boss case. Stage1/2 E2E uses natural automatic physics. Boss5/10 runtime has an explicitly declared progression entry fixture; combat is unmodified. Full10-stage integration is separate. Raw results in review_artifacts/logs and artifacts for current workspace, with included review evidence in this ZIP. No gameplay tests rerun for this documentation-only migration. Packaging validation is separate and does not increase case counts.

## Last completed work

Save mutation rollback and failure reporting/retry; support-unit rear positioning shared across teams; Web safe-area adapter; content-hashed Web assets and atomic service-worker cache install; one-file Windows launcher; final recorded regression run and Web play ZIP extraction/server check. Chrome actual Stage1 victory→reward→train→equip→settings was observed. Final refresh/reopen after those changes was NOT completed. This migration preserves that truthful stopping point.

## Next work

Read AGENTS.md and its ordered onboarding list. Finish final-release Web refresh/reopen persistence, PWA install/update lifecycle, audible audio and real-device touch/safe-area checks. Sustained Chrome rendering FPS and human balance playtests remain. Do not restart development or begin Android/iOS implicitly.

## Run

Windows: extract ZIP and double-click PLAY_LANTERN_MARCH.bat. Requires installed Node.js20+; opens http://127.0.0.1:8060/. Keep launcher window open; Enter stops server. Do not open index.html through file://. Alternatively Godot Import project.godot, F5. Controls:A/D/arrows,1–6,J/K/L,Escape; mouse/touch buttons.

## Test

powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Godot "C:/path/Godot_v4.6-stable_win64_console.exe"

Tests isolate APPDATA under .tools/userdata and write artifacts/. Preserve existing JSON v1 migration tests. Windows certificate-store diagnostic is explicitly excepted; do not conceal other failures.

## Web build

powershell -ExecutionPolicy Bypass -File tools/export-web.ps1 -Godot "C:/path/Godot_v4.6-stable_win64_console.exe"

Requires Node/network for official templates if absent. Output build/web; finalize-web.mjs hashes assets and creates PWA cache metadata. Export afresh before finalization. Deploy complete directory atomically and keep older hashed assets available for active clients. No public host or authenticated Git remote configured.

## Architecture to preserve

Boot routing; Data/Save/Audio autoloads; BattleManager physics orchestration; UnitBase/HeroController/BossUnit; spatial registry;64-slot projectile pool; non-stacking aura; data-driven JSON. InputMap shared by keyboard and touch. SaveManager platform-independent transaction API. Web-specific JavaScript only platform/web adapter/build scripts. Preserve rollback on failed upgrade/equip/reward, support rear position and target death cleanup.

## Known issues and verification gaps

Migration checkpoint: 2026-09-14. This pass preserves existing gameplay code, tests and Web release; no new feature or native-platform work. Latest recorded automated run:24 actual cases /237 assertions /0 failures. Tests were not rerun for documentation-only migration. Latest Web release:c7fa17a690861329. Previous lantern_march_review.zip predates the latest Web milestone; this migration ZIP is the authoritative source snapshot. Final Git/bundle and archive results: review_artifacts/migration_git.txt and migration_validation.txt.

Latest Chrome observation (port8062): actual Stage1 victory,130gold reward, Stage2 unlock, CinderLv2 training(310→210gold), Sunspike equip and settings changes. Final refresh/reopen after all those changes was interrupted and is NOT VERIFIED on this release. Earlier port8061 refresh evidence applies to the earlier build. Do not claim final Web-save lifecycle complete. Actual mobile devices, audible listening, PWA installation/update lifecycle and sustained browser rendering FPS remain NOT TESTED.

Native builds are deferred, not migration failures. Future browser storage flush remains asynchronous; FileAccess success alone does not guarantee survival of instant browser termination. Placeholder sound/art, UI root Boot name dependency and Dictionary-based data are known tradeoffs. No credentials are required to inspect or run existing source.

## Git history restoration

If bundled, lantern_march_git.bundle contains all repository refs/history at the migration checkpoint. Its actual verification result and commit are in review_artifacts/migration_git.txt.

~~~powershell
git bundle verify lantern_march_git.bundle
git clone lantern_march_git.bundle LanternMarch
~~~

The bundle clone contains committed source and evidence. build/web and generated migration reports are intentionally not Git-tracked; the extracted ZIP already contains them. To retain those outputs without copying files, work directly in the extracted ZIP root, or initialize its history with:

~~~powershell
git init
git fetch ./lantern_march_git.bundle refs/heads/master:refs/heads/master
git symbolic-ref HEAD refs/heads/master
git reset --mixed HEAD
~~~

The original branch is master; verify bundle refs in migration_git.txt before adapting these commands. reset --mixed updates the index only and preserves extracted working files. No Codex attachment, private profile or conversation is required. If no bundle could be created, direct source copy still supports migration; consult the recorded reason.
