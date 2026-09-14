extends Node

signal changed
signal save_failed(message: String)
const VERSION := 1
var save_path := "user://progress.json"
var state: Dictionary = {}
var last_error := ""
var future_version := false

func _ready() -> void:
	load_game()

func defaults() -> Dictionary:
	return {"save_version": VERSION, "gold": 180, "hero_level": 1, "hero_exp": 0, "unit_levels": {}, "owned_equipment": ["wickblade", "trail_ring"], "equipped": {"weapon": "wickblade", "ring_a": "trail_ring", "ring_b": ""}, "unlocked_stage": 1, "cleared": [], "settings": {"master": 0.8, "music": 0.45, "sfx": 0.7, "mute": false}}

func load_game() -> bool:
	state = defaults()
	future_version = false
	last_error = ""
	if not FileAccess.file_exists(save_path):
		changed.emit()
		return true
	var loaded: Variant = _read_save(save_path)
	if loaded == null:
		loaded = _read_save(save_path + ".bak")
		last_error = "Recovered backup after invalid save." if loaded != null else "Save could not be read. Using a new journey."
	if loaded == null:
		changed.emit()
		return false
	if int(loaded.get("save_version", 0)) > VERSION:
		future_version = true
		last_error = "This save needs a newer game. Saving is disabled."
		changed.emit()
		return false
	loaded = migrate(loaded)
	for key in state:
		if loaded.has(key) and typeof(loaded[key]) == typeof(state[key]):
			state[key] = loaded[key]
		elif loaded.has(key) and (state[key] is int) and (loaded[key] is float or loaded[key] is int):
			state[key] = int(loaded[key])
	state.gold = clampi(int(state.gold), 0, 99999999)
	state.hero_level = clampi(int(state.hero_level), 1, 100)
	state.hero_exp = maxi(0, int(state.hero_exp))
	state.unlocked_stage = clampi(int(state.unlocked_stage), 1, maxi(1, Data.stages.size()))
	for id in state.unit_levels.keys():
		if not Data.units.has(id) or not (state.unit_levels[id] is float or state.unit_levels[id] is int):
			state.unit_levels.erase(id)
		else:
			state.unit_levels[id] = clampi(int(state.unit_levels[id]), 1, 100)
	state.owned_equipment = state.owned_equipment.filter(func(id): return id is String and Data.equipment.has(id))
	var valid_equipped: Dictionary = defaults().equipped
	var used: Array = []
	for slot in valid_equipped:
		var id = state.equipped.get(slot, "")
		if id is String and state.owned_equipment.has(id) and Data.equipment.has(id) and not used.has(id) and Data.equipment[id].slot == ("weapon" if slot == "weapon" else "ring"):
			valid_equipped[slot] = id
			used.append(id)
		else:
			valid_equipped[slot] = ""
	state.equipped = valid_equipped
	var settings: Dictionary = defaults().settings
	for key in ["master", "music", "sfx"]:
		var value = state.settings.get(key, settings[key])
		if value is float or value is int:
			settings[key] = clampf(float(value), 0.0, 1.0)
	settings.mute = state.settings.get("mute", false) == true
	state.settings = settings
	state.cleared = state.cleared.filter(func(id): return (id is float or id is int) and id >= 1 and id <= Data.stages.size()).map(func(id): return int(id))
	changed.emit()
	return true

func _read_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	var data = parser.data
	if not data is Dictionary:
		return null
	var version = data.get("save_version", 0)
	if not (version is int or version is float) or float(version) < 0:
		return null
	return data

func migrate(data: Dictionary) -> Dictionary:
	# v0 prototype used stage_progress instead of unlocked_stage.
	if int(data.get("save_version", 0)) == 0:
		data["unlocked_stage"] = data.get("stage_progress", 1)
	data["save_version"] = VERSION
	return data

func save_game() -> bool:
	if future_version:
		return _fail("This save needs a newer game. Saving is disabled.")
	var temp := save_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot write save file.")
	file.store_string(JSON.stringify(state, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _fail("Save write failed.")
	if FileAccess.file_exists(save_path) and _read_save(save_path) != null:
		var backup_error := DirAccess.copy_absolute(save_path, save_path + ".bak")
		if backup_error != OK:
			return _fail("Cannot create save backup.")
	var result := DirAccess.rename_absolute(temp, save_path)
	if result != OK:
		return _fail("Cannot replace save file.")
	last_error = ""
	changed.emit()
	return true

func _fail(message: String) -> bool:
	last_error = message
	save_failed.emit(message)
	return false

func reward_stage(stage: Dictionary) -> Dictionary:
	var before := state.duplicate(true)
	var first: bool = not state.cleared.has(int(stage.id))
	var gold := int(stage.reward.gold) if first else int(stage.reward.gold * 0.4)
	state.gold += gold
	state.hero_exp += int(stage.reward.exp)
	while state.hero_exp >= state.hero_level * 80 and state.hero_level < 100:
		state.hero_exp -= state.hero_level * 80
		state.hero_level += 1
	if first:
		state.cleared.append(int(stage.id))
	state.unlocked_stage = mini(Data.stages.size(), maxi(state.unlocked_stage, int(stage.id) + 1))
	var drop: String = stage.reward.get("equipment", "") if first else ""
	if drop != "" and not state.owned_equipment.has(drop):
		state.owned_equipment.append(drop)
	if not _commit(before):
		return {"saved": false, "gold": 0, "exp": 0, "equipment": "", "first": first}
	return {"saved": true, "gold": gold, "exp": stage.reward.exp, "equipment": drop, "first": first}

func upgrade_unit(id: String) -> bool:
	var level := int(state.unit_levels.get(id, 1))
	if not Data.units.has(id) or level >= 100 or state.gold < level * 100:
		return false
	var before := state.duplicate(true)
	state.gold -= level * 100
	state.unit_levels[id] = level + 1
	return _commit(before)

func equip(slot: String, id: String) -> bool:
	if not state.equipped.has(slot) or not state.owned_equipment.has(id) or not Data.equipment.has(id):
		return false
	if Data.equipment[id].slot != ("weapon" if slot == "weapon" else "ring"):
		return false
	var before := state.duplicate(true)
	for other in state.equipped:
		if state.equipped[other] == id:
			state.equipped[other] = ""
	state.equipped[slot] = id
	return _commit(before)

func equipment_modifiers() -> Dictionary:
	var mods: Dictionary = {}
	for id in state.equipped.values():
		if Data.equipment.has(id):
			for stat in Data.equipment[id].stats:
				mods[stat] = float(mods.get(stat, 0.0)) + float(Data.equipment[id].stats[stat])
	return mods




# Mutations are atomic from the caller's perspective: failed disk writes roll back.
func _commit(before: Dictionary) -> bool:
	if save_game(): return true
	state = before
	changed.emit()
	return false

func set_setting(key: String, value: Variant) -> bool:
	if not state.settings.has(key): return false
	var before := state.duplicate(true)
	state.settings[key] = value
	return _commit(before)
