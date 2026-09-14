class_name CombatRegistry
extends RefCounted

var entities: Array = []
var buckets: Dictionary = {}
var bucket_size := 200.0
var elapsed := 0.0

func register(unit) -> void:
	entities.append(unit)
	_insert(unit)

func unregister(unit) -> void:
	entities.erase(unit)
	for remaining in entities:
		if remaining.target == unit: remaining.target = null
	for bucket in buckets.values():
		bucket.erase(unit)

func _insert(unit) -> void:
	var key := int(floor(unit.position.x / bucket_size))
	if not buckets.has(key):
		buckets[key] = []
	buckets[key].append(unit)

func rebuild() -> void:
	buckets.clear()
	for unit in entities:
		if is_instance_valid(unit) and unit.alive:
			_insert(unit)

func tick(delta: float, interval: float) -> void:
	elapsed += delta
	if elapsed >= interval:
		elapsed = 0.0
		rebuild()

func nearby(x: float, radius: float, team: int) -> Array:
	var result: Array = []
	# One extra bucket covers motion between the 10 Hz index rebuilds.
	var first := int(floor((x - radius) / bucket_size)) - 1
	var last := int(floor((x + radius) / bucket_size)) + 1
	for key in range(first, last + 1):
		for unit in buckets.get(key, []):
			if is_instance_valid(unit) and unit.alive and unit.team == team and absf(unit.position.x - x) <= radius:
				result.append(unit)
	return result

func find_target(source):
	var healing: bool = source.stats.attack_type == "heal"
	var supporting: bool = source.stats.attack_type == "buff"
	var team: int = source.team if healing or supporting else 1 - source.team
	var radius: float = source.stats.attack_range + 130.0
	var best = null
	var score := INF
	for unit in nearby(source.position.x, radius, team):
		if unit == source:
			continue
		if healing and (unit.is_base or unit.hp >= unit.max_hp):
			continue
		if supporting and (unit.is_base or unit.support_time > 0):
			continue
		var distance: float = absf(unit.position.x - source.position.x)
		if distance < score:
			score = distance
			best = unit
	return best

