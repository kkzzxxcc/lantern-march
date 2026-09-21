# Public HTTPS deployment preparation

## Live deployment — 2026-09-21

- Public URL: https://kkzzxxcc.github.io/lantern-march/
- Release: `0d67ff167e3ab7dd`; the exact prepared ZIP was deployed without rebuilding.
- GitHub Pages: `gh-pages` root, HTTPS enforced, build status `built`.
- Deployment commit: `4625ddc0d80193ae9aa6a5378a4735799c91d7fb`.
- Direct public HTTPS verification: 19/19 files returned 200 at the intended URL and matched tracked SHA256 checksums. WASM/JavaScript/manifest MIME checks passed. Static HTML/manifest/worker mixed-content scan passed.
- Evidence: `review_artifacts/web_https_2026-09-21.json`.
- No browser execution: gameplay startup, refresh/restart persistence and PWA lifecycle remain unverified. No Android/iOS work.
- Pages auto-enabled after the initial branch push; subsequent create request returned 409 already enabled. GET confirmed the intended branch/root and enforced HTTPS. No custom workflow or paid service was needed.
- Future deployments: update the existing `gh-pages` branch without rewriting history; retain prior hashed assets and publish a complete verified release. The preparation section below is historical, not the current deployment status.

## Historical preparation — 2026-09-18

Prepared, **not deployed**. Browser execution is prohibited by the current channel policy; no browser was opened and no persistence result is claimed.

- Canonical repository: https://github.com/kkzzxxcc/lantern-march
- Chosen existing free hosting: GitHub Pages for this public repository. No backend, new hosting account, paid service or native SDK is needed.
- Target URL after deployment: https://kkzzxxcc.github.io/lantern-march/ — **planned, not a verified live URL**.
- Source release: `0d67ff167e3ab7dd`, Godot 4.6 stable, single-thread. No rebuild or finalizer rerun.
- Local upload ZIP: `build/lantern-march-pages-0d67ff167e3ab7dd.zip` (9,855,335 bytes).
- ZIP SHA256: `cf45e79eb4e5a55544de1363bd8ee1ae900d223b8082dbfcc29a477acf3fd7e8`.
- Tracked payload checksums: `review_artifacts/pages-0d67ff167e3ab7dd.sha256`.
- ZIP is Git-ignored and exists only in this checkout. A fresh clone does not contain the deployable build. Preserve/transfer this exact ZIP for this release; a fresh export must be treated as a new candidate and verified separately.

The archive root contains only the 16 release files, `.nojekyll`, `THIRD_PARTY_NOTICES.md` and `GODOT_COPYRIGHT.txt`. No source tree, local saves, credentials, editor caches or launcher are included. The existing Windows play-package script includes a launcher and nested build directory; this hosting ZIP instead places `index.html` at its root. Standard ZIP and GitHub Pages are used, without a custom hosting service or dependency.

Read-only preflight: Pages API returned HTTP 404 (no accessible configured Pages site; not proof of account-wide permissions). `git ls-remote origin refs/heads/gh-pages` succeeded with no branch. No hosting settings were changed.

## Next deployment work unit (not executed)

1. Verify the ZIP SHA256 above, extract to a clean project-local directory, then run `shasum -a 256 -c` with the absolute path to the tracked payload checksum file from inside the extracted directory. Require all 19 files to pass and no unexpected files.
2. Recheck the remote Pages configuration and `gh-pages` branch. If still absent, create a separate project-local checkout and an orphan `gh-pages` branch; populate its root with the verified archive contents. Commit and push that branch without changing source `master`. Do not create a second source repository. If the branch now exists, preserve it and its previous hashed assets rather than replacing history.
3. Configure repository Settings → Pages → Deploy from a branch → `gh-pages` / root. Require HTTPS, no custom domain. Wait for the Pages deployment to succeed. This repository-level Pages setup belongs to the deployment work unit; it was not performed during preparation.
4. Verify the actual target URL over HTTPS: root, release.json, service-worker.js, manifest and every release asset must return 200 and match the tracked checksums. Require WASM `application/wasm`, usable JavaScript/manifest MIME types and no mixed content. Check the final URL stays on the intended origin/path. Single-thread export does not require COOP/COEP.
5. Browser-authorized tester must then run the protocol below. HTTP or checksum success alone does not prove that the game starts, IndexedDB saves persist, or PWA installation works.

Publish the complete directory in a single Pages deployment. On later updates, retain prior `lm-<version>.*` assets for existing clients and keep the existing service worker policy (no forced activation). Do not clear user site data or force a service-worker unregister as an update strategy. Roll back by a new deployment of the previous complete release, preserving hashed assets, never by force-pushing history. No data migration is introduced here.

GitHub Pages references: https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages and https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site . Actual availability/configuration must be checked during deployment.

## Browser persistence protocol — pending

Use the same normal browser profile and exact HTTPS origin/path throughout. Localhost saves are not expected to transfer to HTTPS. Do not use private browsing, clear site data, edit IndexedDB, inject save state or force victory. Record release.json version and browser/OS before playing. An already installed worker may serve an older release; verify the loaded asset prefix is `lm-0d67ff167e3ab7dd` too.

1. Record baseline gold, unlocked stages, unit training level, equipped items and settings. If an existing profile cannot exercise a change, use a separate normal test profile, not a destructive reset of a personal save.
2. Win Stage 1 through normal gameplay, confirm reward/save success and record resulting gold and unlock state. Train an affordable unit; record level and gold debit. Equip a different available item and record its slot/name. Change volume/mute settings and record displayed values. If unavailable, earn/unlock them normally and record the actual sequence.
3. Leave the game idle for 10 seconds after the final successful save indication (a test condition, **not a durability guarantee**). Refresh the page and revisit each screen. Compare all recorded values; gold must neither revert nor receive the reward again.
4. Close every game tab/window, exit the browser normally, reopen the same browser/profile and same URL. Compare all values again. Do not substitute a mere new tab for browser restart. Record elapsed idle time and exact close/reopen procedure.
5. Record separate outcomes for reward/gold/unlocks, training, equipment and settings under both refresh and restart. Include screenshots or observations from the authorized tester. Mark failures or unavailable cases explicitly. Instant process termination, offline/PWA installation, browser storage eviction and real-device checks are separate, unverified scenarios.

| State | After mutations | After refresh | After normal browser restart |
| --- | --- | --- | --- |
| Gold / reward / stage unlock | NOT RUN | NOT RUN | NOT RUN |
| Training level / cost | NOT RUN | NOT RUN | NOT RUN |
| Equipped item / slot | NOT RUN | NOT RUN | NOT RUN |
| Volume / mute settings | NOT RUN | NOT RUN | NOT RUN |
