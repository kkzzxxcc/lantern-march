extends Node

var units: Dictionary = {}
var enemies: Dictionary = {}
var stages: Array = []
var equipment: Dictionary = {}
var skills: Array = []
var rules: Dictionary = {}
var errors: Array[String] = []

func _ready() -> void:
	units = _read("units/units.json")
	enemies = _read("enemies/enemies.json")
	stages = _read("stages/stages.json")
	equipment = _read("equipment/equipment.json")
	skills = _read("skills/skills.json")
	rules = _read("rules.json")
	validate()

func _read(path: String) -> Variant:
	var file := FileAccess.open("res://data/" + path, FileAccess.READ)
	if file == null:
		push_error("Missing data: " + path)
		return {} if not path.contains("stages") and not path.contains("skills") else []
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Invalid JSON: " + path)
		return {}
	return json.data

func roster() -> Array:
	var ids := units.keys()
	ids.sort_custom(func(a, b): return units[a].order < units[b].order)
	return ids

func validate() -> void:
	errors.clear()
	for catalog in [units, enemies]:
		for id in catalog:
			for field in ["id", "name", "hp", "attack", "defense", "attack_speed", "move_speed", "attack_range", "supply_cost", "spawn_cooldown", "role", "attack_type", "color"]:
				if not catalog[id].has(field):
					errors.append("%s missing %s" % [id, field])
	for stage in stages:
		for entry in stage.spawns:
			if not enemies.has(entry.id):
				errors.append("Unknown enemy " + entry.id)
		if stage.boss != "" and not enemies.has(stage.boss):
			errors.append("Unknown boss " + stage.boss)
	for error in errors:
		push_error(error)

