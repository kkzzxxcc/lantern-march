# HTTPS deployment preparation — 2026-09-18

Fallback authorized because current channel policy prohibits browser execution. Prepared GitHub Pages upload material for current release `0d67ff167e3ab7dd`; no deployment, browser execution, game changes or native work.

## Direct checks

- All 16 current release files matched the SHA256 and byte counts recorded in `web_export_2026-09-18.md`; release asset allowlist matched exactly.
- Hosting ZIP: 19 allowlisted entries; ZIP CRC check and all byte comparisons passed.
- ZIP actually extracted into `build/pages-check-0d67ff167e3ab7dd`; independent `shasum -a 256 -c` check passed 19/19.
- ZIP: `build/lantern-march-pages-0d67ff167e3ab7dd.zip`, 9,855,335 bytes; SHA256 `cf45e79eb4e5a55544de1363bd8ee1ae900d223b8082dbfcc29a477acf3fd7e8`.
- Manifest scope, id and start_url are relative, consistent with a project-path deployment. Actual hosted behavior remains unverified.
- Pages API returned 404; gh-pages remote branch lookup returned no branch. No remote hosting mutation performed.

Only related packaging checks were run. Historical PWA tests and HTTP checks were not rerun or counted as new tests. Reward/training/equipment/settings persistence after refresh/restart is NOT RUN. No verified public playable URL exists from this task.

See `WEB_DEPLOYMENT.md` for next deployment steps and the exact pending browser QA protocol. The binary ZIP remains local/Git-ignored; the runbook, evidence and payload checksums are committed.
