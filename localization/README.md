# Localization

Korean is the default on every host (`locale/test="ko"` and Korean fallback).
Godot's built-in gettext PO translations are registered in project.godot; no localization plugin is needed.

- English source strings remain msgids and original JSON display fields.
- Internal IDs, role/type keys, InputMap actions and save schema remain unchanged.
- Translate dynamic names, descriptions, roles and stats at the presentation boundary.
- Translate format strings **before** interpolation. Keep every format specifier intact.
- Korean and English catalogs have matching entries.
- To offer English in a later language selector, call `TranslationServer.set_locale("en")` and rebuild the current programmatic screen. Rebuild HUD/overlay too if changed during battle. This change does not add a saved language preference.
- UIKit uses bundled Noto Sans KR, not host font fallback.
- Web shell/loading errors, offline page and manifest default to Korean in tools/finalize-web.mjs; runtime language switching does not change the external shell.
- Tests: tests/presentation_test.gd (Korean scenes/catalog/font, English catalog, audio events/settings); legacy runtime_e2e.gd explicitly selects English for its existing selectors.

Do not translate operational logs, resource paths or saved IDs.
