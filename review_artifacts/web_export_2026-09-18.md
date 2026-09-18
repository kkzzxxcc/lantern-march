# Web re-export — 2026-09-18

## Scope

One TODO NOW work item: re-export the Web build after the 2026-09-16 PWA fixes. No gameplay/source changes, native build, browser automation or deployment. Canonical remote: https://github.com/kkzzxxcc/lantern-march.git. Input source commit: a2d93b81d73e8058395e76efafcf1086bf0399f8.

## Result

- Engine: Godot 4.6.stable.official.89cea1439, macOS headless editor/export only.
- Official matching single-thread Web release/debug templates fetched by existing tools/download-templates.mjs into .tools/templates.
- Engine editor state isolated with .tools/godot/_sc_; editor_data created inside that directory. No game/save execution.
- Fresh release: 0d67ff167e3ab7dd, generated locally at build/web; generated assets remain Git-ignored, not included in this commit.
- No hosted/playable public URL or deployment performed.

## Commands

Run from the project root, with the existing engine in .tools/godot/Godot.app:

~~~sh
touch .tools/godot/_sc_
node tools/download-templates.mjs
mkdir -p build/web artifacts
.tools/godot/Godot.app/Contents/MacOS/Godot --headless --path . --export-release Web --log-file artifacts/export-web-2026-09-18.log
node tools/finalize-web.mjs
node --test tools/web-release.test.mjs
~~~

Finalization requires a fresh export. Do not finalize the same output twice.

## Direct verification

- Godot Web release export: exit 0; no SCRIPT ERROR, ERROR, WARNING or Export failed diagnostics in captured stdout.
- Environment diagnostic: "cannot connect to daemon at tcp:5037: Connection refused" at editor/export shutdown. No Android build or SDK setup was requested; this is not a browser/gameplay test result.
- Existing Node fixture/VM PWA regressions: 6 tests passed, 0 failed.
- Actual generated output served with existing tools/serve.mjs on 127.0.0.1:18060. All 16 release/worker/metadata HTTP requests returned 200 and byte-for-byte matched disk. Root / returned 200. Server stopped after verification.
- WASM application/wasm and manifest application/manifest+json MIME checks passed; HTML executable/version, viewport-fit=cover and manifest icon references checked against actual assets.
- Generated output size for checked files: 38399907 bytes.
- Local detailed evidence: artifacts/export-web-2026-09-18.stdout.log, artifacts/export-web-2026-09-18.log, artifacts/web-export-2026-09-18.json (Git-ignored).

## Not verified

Browser startup/rendering, refresh/reopen IndexedDB persistence, actual PWA installation/update/offline lifecycle, mobile device input, audio and gameplay were NOT tested. Channel policy prohibits browser access. TODO NEXT persistence QA remains open; use this new release for future QA and report its evidence separately from the historical c7fa17a690861329 observations.

## Generated asset fingerprints

~~~text
70346c9c242001470691d9477c88eb84d7a7545341c5e9bfc027935e0b79bbc5  index.html  (6113 bytes)
c8aae38d63a9bb04e2e535da0938ba53f2170127d901168328f2a3bc080cefae  manifest.webmanifest  (598 bytes)
6272a95241f36ac8b7f6d418dea32f9ba1b8ced458ce0241e6dde220a6854264  lm-0d67ff167e3ab7dd.144x144.png  (4180 bytes)
a48ba1faabe8ff23173184a758300fc7e723681f29d8a02d63e34c714bc585b1  lm-0d67ff167e3ab7dd.180x180.png  (6031 bytes)
3ed77b53c381b1ce708424c211551e2393abaa5e13477758d20189b2be542589  lm-0d67ff167e3ab7dd.512x512.png  (21716 bytes)
a48ba1faabe8ff23173184a758300fc7e723681f29d8a02d63e34c714bc585b1  lm-0d67ff167e3ab7dd.apple-touch-icon.png  (6031 bytes)
be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8  lm-0d67ff167e3ab7dd.audio.position.worklet.js  (2973 bytes)
5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3  lm-0d67ff167e3ab7dd.audio.worklet.js  (7298 bytes)
3ed77b53c381b1ce708424c211551e2393abaa5e13477758d20189b2be542589  lm-0d67ff167e3ab7dd.icon.png  (21716 bytes)
e3f56ee40e6f84371053db06692cfac15e2c8659547b11c6b2dfa1996dabd981  lm-0d67ff167e3ab7dd.js  (315759 bytes)
b0a5d443e78f58717adac780bac91c1431bfa3b801c41f4707d507fb5ad2e47f  lm-0d67ff167e3ab7dd.offline.html  (971 bytes)
f0d8d9986b42b0142b7e2d9e23269295d6ac70fd97634ef7c7446920c5e94ebc  lm-0d67ff167e3ab7dd.pck  (296312 bytes)
3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e  lm-0d67ff167e3ab7dd.png  (21443 bytes)
2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137  lm-0d67ff167e3ab7dd.wasm  (37686550 bytes)
85ae87de37d6bea840f0176bdbb656306e49f1344f14ecbd2fe7dff6604e3ff9  service-worker.js  (1586 bytes)
304273350bf548a27e6a11c999cdda7266c2ee52a677e54819b2129d9080dec9  release.json  (630 bytes)
~~~
