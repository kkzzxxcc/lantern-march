extends SceneTree
# Headless scene/integration coverage; not browser playback or listening certification.
var failures := 0
var checks := 0
var data
var save
var audio
var boot
var kit

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	run.call_deferred()

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", detail)

func korean(text: String) -> bool:
	for c in text:
		if c.unicode_at(0) >= 0xAC00 and c.unicode_at(0) <= 0xD7A3: return true
	return false

func catalog(value: Variant) -> void:
	if value is Dictionary:
		for key in value:
			if key in ["name", "description"]:
				check(korean(TranslationServer.translate(value[key])), "Korean catalog: " + value[key])
			else: catalog(value[key])
	elif value is Array:
		for entry in value: catalog(entry)

func texts(node: Node) -> String:
	var result := ""
	if node is Label or node is Button:
		result += node.text + "\n"
	if node is Control:
		result += node.tooltip_text + "\n"
	for child in node.get_children(): result += texts(child)
	return result

func run() -> void:
	kit = load("res://ui/ui_kit.gd")
	data = root.get_node("Data")
	save = root.get_node("Save")
	audio = root.get_node("Audio")
	save.save_path = "user://presentation-test.json"
	save.state = save.defaults()
	check(TranslationServer.get_locale().begins_with("ko"), "Korean default independent of host language")
	for value in [data.units,data.enemies,data.stages,data.skills,data.equipment,data.rules]: catalog(value)
	check(data.units.has("cinder") and data.skills[0].id == "sunbolt", "Internal IDs unchanged")
	var font: Font = kit.theme().default_font
	check(font.has_char("한".unicode_at(0)) and font.has_char("글".unicode_at(0)), "Bundled font has Hangul glyphs")
	TranslationServer.set_locale("en")
	check(TranslationServer.translate("Sunbolt") == "Sunbolt", "English catalog switch")
	TranslationServer.set_locale("ko")
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await scene_changed
	boot = current_scene
	for id in ["main_menu","stage_select","upgrade","equipment","settings"]:
		boot.show_screen(id)
		await process_frame
		await process_frame
		var text := texts(boot.screen)
		check(korean(text), "Korean scene " + id)
		for english in ["Lantern","KEEPER","GOLD","Train","Settings","Wickblade","Cinder","Controls"]:
			check(not text.contains(english), id + " has no untranslated " + english)
		check(boot.screen.body.get_combined_minimum_size().x <= 1224, "1280px layout fits: " + id + " " + str(boot.screen.body.get_combined_minimum_size()))
	boot.show_screen("equipment")
	boot.screen.equipment_slot = "ring_a"
	boot.screen._build()
	check(texts(boot.screen).contains("오라 범위"), "Translated dynamic equipment stats and slots")
	save.last_error = "Cannot write save file."
	boot.show_screen("main_menu")
	check(texts(boot.screen).contains("저장 파일을 작성할 수 없습니다."), "Save failure translation")
	save.last_error = ""
	check(audio.tracks.size() == 2 and audio.sounds.size() == 8, "Two BGM and eight SFX loaded")
	for id in audio.tracks:
		check(audio.tracks[id].loop_mode == AudioStreamWAV.LOOP_FORWARD and audio.tracks[id].get_length() > 10, "Looped BGM: " + id)
	check(not audio.started, "Music waits for user gesture")
	var input := InputEventKey.new()
	input.keycode = KEY_ENTER
	input.pressed = true
	audio._input(input)
	check(audio.started and audio.music.stream == audio.tracks.menu, "First keyboard gesture starts menu BGM")
	boot.start_battle(1)
	var b = boot.screen
	b.set_physics_process(false)
	await process_frame
	check(audio.music.stream == audio.tracks.battle, "Battle routing switches BGM")
	check(texts(b.hud).contains("태양탄") and texts(b.hud).contains("잿불 수호병"), "HUD shows full Korean skill/unit names")
	check(b.hud.get_child(0).get_combined_minimum_size().x <= 1280, "1280px HUD fits full Korean names: " + str(b.hud.get_child(0).get_combined_minimum_size()))
	b.hud.show_pause(true)
	check(texts(b.hud.overlay).contains("일시정지"), "Korean pause")
	b.hud._offer_upgrade(data.rules.battle_upgrades.slice(0,3))
	check(texts(b.hud.overlay).contains("축복") and not texts(b.hud.overlay).contains("Hands"), "Korean blessings")
	audio.last_played.clear()
	b.summon(0)
	check(audio.last_played.has("summon"), "Production summon SFX")
	b.hero.take_damage(10)
	check(audio.last_played.has("hit"), "Hit SFX before death")
	b.hero.heal(5)
	check(audio.last_played.has("heal"), "Actual healing SFX")
	var enemy = b.spawn_enemy("bulwark", b.hero.position.x + 120)
	b.registry.rebuild()
	b.resources.mana = 100
	b.cast_skill(0)
	check(audio.last_played.has("ranged") and audio.last_played.has("skill"), "Projectile and skill SFX")
	audio.last_played.erase("ranged")
	for slot in b.projectiles.slots: slot.active = true
	check(not b.projectiles.launch(b.hero, enemy, 1) and not audio.last_played.has("ranged"), "Saturated pool makes no false shot or SFX")
	b.projectiles.clear()
	for result in ["victory","defeat"]:
		b.status = "running"
		audio.last_played.erase(result)
		b.finish(result)
		check(audio.last_played.has(result), "Production result SFX " + result)
		check(texts(b.hud.overlay).contains("승리" if result == "victory" else "패배"), "Korean result " + result)
	b.hud._on_ended("victory", {"saved":false})
	check(texts(b.hud.overlay).contains("보상 저장 재시도"), "Korean reward-save retry")
	boot.show_screen("main_menu")
	check(audio.music.stream == audio.tracks.menu, "Return to menu restores menu BGM")
	for entry in [["Master","master"],["Music","music"],["SFX","sfx"]]:
		save.state.settings[entry[1]] = 0.25
		audio.apply_settings()
		var bus := AudioServer.get_bus_index(entry[0])
		check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)),0.25), "Volume bus " + entry[0])
		save.state.settings[entry[1]] = 0.0
		audio.apply_settings()
		check(AudioServer.is_bus_mute(bus), "Zero volume truly mutes " + entry[0])
		save.state.settings[entry[1]] = 0.6
	save.state.settings.mute = true
	audio.apply_settings()
	check(AudioServer.is_bus_mute(0), "Master mute")
	save.state.settings.mute = false
	audio.apply_settings()
	check(not AudioServer.is_bus_mute(0), "Master unmute")
	check(audio.music.playback_type == AudioServer.PLAYBACK_TYPE_STREAM and audio.voices[0].playback_type == AudioServer.PLAYBACK_TYPE_STREAM, "Web stream playback uses volume buses")
	var button: Button = kit.button("Settings", func(): pass)
	boot.screen.add_child(button)
	audio.last_played.erase("click")
	button.pressed.emit()
	check(audio.last_played.has("click"), "UI button click SFX")
	await process_frame
	var file := FileAccess.open("res://artifacts/presentation-test.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"kind":"headless scene integration; no audible/browser verification"},"\t"))
	file.close()
	print("PRESENTATION: ",checks," checks / ",failures," failures")
	boot.queue_free()
	await process_frame
	audio.shutdown()
	await create_timer(0.2).timeout
	quit(0 if failures == 0 else 1)
