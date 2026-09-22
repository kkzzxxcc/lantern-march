# Audio provenance — 2026-09-22

All game audio is directly synthesized for Lantern March by the repository's
`tools/generate-audio.cjs`, using Node.js built-ins, mathematical oscillators,
a deterministic noise generator and newly authored note sequences.
No downloaded recordings, external samples, third-party compositions or
generative service output are used. There are no third-party audio license,
attribution, royalty or subscription requirements.

Regenerate from repository root: `node tools/generate-audio.cjs`.

- menu.wav: original eight-bar 88 BPM menu theme.
- battle.wav: original eight-bar 124 BPM battle theme with rhythmic percussion.
- click.wav: UI confirmation.
- summon.wav: companion arrival.
- hit.wav: damage impact (not just death).
- ranged.wav: successful projectile launch; pool rejection makes no sound.
- skill.wav: offensive spell.
- heal.wav: actual healing and healing skill.
- victory.wav / defeat.wav: result cues.

Output: mono, 22,050 Hz, signed 16-bit PCM WAV. BGM uses Godot WAV loop points;
short attack/release envelopes limit discontinuities. Eight reusable SFX
players and a per-event 60 ms limiter bound combat audio load. STREAM playback
routes Web audio through Master/Music/SFX buses. Zero volume and mute silence
the respective buses; gameplay and save semantics are unchanged.

march.wav is the prior original procedural placeholder, retained for historical
compatibility but no longer loaded by AudioManager.

Automatic signal/PCM checks are not a substitute for human listening on mobile
browsers. First real touch/click/key interaction starts music due to Web autoplay
restrictions.
